-- Stored Procedure
GO
CREATE OR ALTER PROCEDURE InsertNewProperty
   @NeighborhoodName VARCHAR(100),
   @PropertyTypeName VARCHAR(50),
   @MarketValue DECIMAL(18, 2),
   @AddressNumber VARCHAR(10),
   @StreetName VARCHAR(100),
   @StreetSuffix VARCHAR(10),
   @City VARCHAR(50),
   @ZipCode VARCHAR(10),
   @NumBedrooms INT,
   @NumBathrooms INT,
   @SquareFeet INT
AS
BEGIN
   -- Declare variables to store IDs
   DECLARE @NeighborhoodID INT;
   DECLARE @PropertyTypeID INT;


   -- Retrieve the NeighborhoodID based on the neighborhood name
   SET @NeighborhoodID = (SELECT NeighborhoodID FROM tblNeighborhood WHERE NeighborhoodName = @NeighborhoodName);


   -- Retrieve the PropertyTypeID based on the property type name
   SET @PropertyTypeID = (SELECT PropertyTypeID FROM tblPropertyType WHERE PropertyTypeName = @PropertyTypeName);


   -- Check if the NeighborhoodID or PropertyTypeID is NULL
   IF @NeighborhoodID IS NULL
   BEGIN
       PRINT 'Invalid NeighborhoodName provided. Please check the NeighborhoodName.';
       RETURN;
   END;


   IF @PropertyTypeID IS NULL
   BEGIN
       PRINT 'Invalid PropertyTypeName provided. Please check the PropertyTypeName.';
       RETURN;
   END;


   -- Begin the transaction
   BEGIN TRAN T;
   INSERT INTO tblProperty (
       NeighborhoodID, PropertyTypeID, MarketValue, AddressNumber,
       StreetName, StreetSuffix, City, ZipCode, NumBedrooms, NumBathrooms, SquareFeet
   )
   VALUES (
       @NeighborhoodID, @PropertyTypeID, @MarketValue, @AddressNumber,
       @StreetName, @StreetSuffix, @City, @ZipCode, @NumBedrooms, @NumBathrooms, @SquareFeet
   );


   -- Check for errors during the INSERT operation
   IF @@ERROR <> 0
   BEGIN
       ROLLBACK TRAN T;
       PRINT 'An error occurred during the property insertion. Transaction rolled back.';
       RETURN;
   END;


   -- Commit the transaction
   COMMIT TRAN T;
   PRINT 'New property inserted successfully!';
END;
GO


-- Check Constraint
-- Check's that a property's market value, rooms numbers, and square footage are non-negative, and that ZipCode is the correct format.
ALTER TABLE tblProperty
ADD CONSTRAINT CK_Property_ValidValues
CHECK (
   MarketValue > 0 AND
   NumBedrooms >= 0 AND
   NumBathrooms >= 0 AND
   SquareFeet >= 0 AND
   ZipCode LIKE '[0-9][0-9][0-9][0-9][0-9]'
);


-- Computed Column
-- Calculates a property's price per square foot
ALTER TABLE tblProperty
ADD PricePerSqFt AS (MarketValue / NULLIF(SquareFeet, 0));





-- NEXT 















-- 1) Stored Procedure: Record Property Transaction. Allows user to add new property transaction record.
GO
CREATE OR ALTER PROCEDURE RecordPropertyTransaction
    @OwnerFullName VARCHAR(100),
    @PropertyID INT,
    @PurchaseDate DATE,
    @PurchasePrice DECIMAL(18, 2),
    @SoldDate DATE = NULL, -- Can be null in case the property wasn't sold yet
    @SoldPrice DECIMAL(18, 2) = NULL-- Can be null in case the property wasn't sold yet
AS
BEGIN
    DECLARE @OwnerID INT;


    -- Get OwnerID based on owner full name
    SET @OwnerID = (SELECT OwnerID FROM tblOwner WHERE FullName = @OwnerFullName);


    -- Affirm that/if the OwnerID is found
    IF @OwnerID IS NULL
    BEGIN
        PRINT 'Invalid Owner Name. Please check the Owner Name OR Add this owner to the database before attempting to add their transaction record.'
        RETURN;
    END;


    -- Start the insertion/transaction
    BEGIN TRAN T;


    -- Insert the property transaction
    INSERT INTO tblPropertyTransactions (
        OwnerID, PropertyID, PurchaseDate, PurchasePrice, SoldDate, SoldPrice
    )
    VALUES (
        @OwnerID, @PropertyID, @PurchaseDate, @PurchasePrice, @SoldDate, @SoldPrice
    );


    -- Checks for aany errors during the operation
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRAN T;
        PRINT 'An error occurred during the insertion. Transaction rolled back. Try again.'
        RETURN;
    END;


    -- If no errors appear, we can commit the transaction
    COMMIT TRAN T;
    PRINT 'Property transaction recorded successfully!';
END;
GO


/* Constraint: Checks if the ownership end year is either greater than
or equal to the start year in tblOwnership */


ALTER TABLE tblOwnership
ADD CONSTRAINT Check_Ownership_Duration CHECK (OwnershipEndYear IS NULL OR OwnershipEndYear >= OwnershipStartYear);


-- Computed Column: Displays the Ownership Duration in Years
ALTER TABLE tblOwnership
ADD OwnershipDurationYears AS (NULLIF(OwnershipEndYear, 0) - OwnershipStartYear);









--NEXT OBJECTS


GO
CREATE OR ALTER PROCEDURE AddNewRentalDetail
    @StartDate DATE,
    @EndDate DATE = NULL,
    @RentalPrice DECIMAL(18, 2),
    @RenterID INT,
    @PropertyID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insert into tblRentalDetail
        INSERT INTO tblRentalDetail (
            StartDate, EndDate, RentalPrice, RenterID, PropertyID
        )
        VALUES (
            @StartDate, @EndDate, CAST(@RentalPrice AS VARCHAR(100)), @RenterID, @PropertyID
        );

        COMMIT TRANSACTION;
        PRINT 'Rental detail added successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'An error occurred: ' + ERROR_MESSAGE();
    END CATCH
END
GO


--CHECK CONSTRAINT
ALTER TABLE tblRentalDetail
ADD CONSTRAINT CK_RentalDetail_Valid CHECK (
    CAST(RentalPrice AS DECIMAL(18, 2)) > 0 AND 
    (EndDate IS NULL OR EndDate > StartDate)
);


--new computed column
ALTER TABLE tblDemographicInfo
ADD DiversityIndex AS (
    CAST((1.0 - (
        POWER((CAST(WhitePopulation AS FLOAT) / NULLIF(TotalPopulation, 0)), 2) +
        POWER((CAST(BlackPopulation AS FLOAT) / NULLIF(TotalPopulation, 0)), 2) +
        POWER((CAST(HispanicPopulation AS FLOAT) / NULLIF(TotalPopulation, 0)), 2) +
        POWER((CAST(AsianPopulation AS FLOAT) / NULLIF(TotalPopulation, 0)), 2)
    )) AS DECIMAL(5, 4))
);


EXEC AddNewRentalDetail
    @StartDate = '2015-07-07',
    @EndDate = '2015-08-07',
    @RentalPrice = 660043,
    @RenterID = 228,
    @PropertyID = 120;










--NEW EWNENW EWNE WENWE WENWNE W NE





