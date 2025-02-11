





/*
1. Query to Identify Neighborhoods with the Highest Ownership Turnover


Purpose:
Provides insights into which neighborhoods have properties that frequently change hands. This can reflect high investor activity, market volatility,
or popular flipping opportunities.


Results:
Identifies neighborhoods ranked by the average number of ownership changes per property, highlighting areas with the most dynamic property markets.


Implications/Recommendations:
   •   High turnover neighborhoods may warrant additional analysis to understand why properties change owners so frequently (e.g., speculation, short-term investments).
   •   Investors might focus on these neighborhoods for quick buy-and-sell strategies.
   •   Policy makers or urban planners could investigate the reasons behind frequent turnovers to ensure neighborhood stability.
*/


-- Identify average ownership turnover per neighborhood


GO
;WITH OwnershipCounts AS (
   SELECT
       p.PropertyID,
       n.NeighborhoodName,
       COUNT(ow.OwnershipID) - 1 AS OwnershipChanges
   FROM
       tblProperty p
   JOIN
       tblNeighborhood n ON p.NeighborhoodID = n.NeighborhoodID
   JOIN
       tblOwnership ow ON p.PropertyID = ow.PropertyID
   GROUP BY
       p.PropertyID, n.NeighborhoodName
   HAVING
       COUNT(ow.OwnershipID) > 1  -- Properties that changed owners at least once
)
SELECT
   NeighborhoodName,
   AVG(CAST(OwnershipChanges AS DECIMAL(18,2))) AS AvgOwnershipChanges
FROM
   OwnershipCounts
GROUP BY
   NeighborhoodName
ORDER BY
   AvgOwnershipChanges DESC;










/*
2. Stored Procedure to Get All Current Properties Owned by a Specific Owner


Purpose:
Allows the user to retrieve all properties currently owned by a specified owner, providing a tailored view of an owner’s real estate portfolio.


Results:
Returns property information (market value, property category, address) tied directly to the requested owner.


Implications/Recommendations:
   •   Useful for owners or asset managers to quickly review their holdings and assess portfolio balance.
   •   Helpful for due diligence, estate planning, or preparation for future transactions.
*/


GO
CREATE OR ALTER PROCEDURE GetPropertiesByOwner
   @OwnerFullName VARCHAR(100)
AS
BEGIN
   DECLARE @OwnerID INT;
   BEGIN TRAN CheckOwner;


   -- Attempt to find the specified owner by FullName
   SET @OwnerID = (SELECT OwnerID
                   FROM tblOwner
                   WHERE FullName = @OwnerFullName);


   -- Error Handling: Check if OwnerID is NULL
   IF @OwnerID IS NULL
   BEGIN
       PRINT 'Owner does not exist. Check the spelling of the provided OwnerName.';
       THROW 50062, 'The specified owner does not exist in the database. Transaction is terminating.', 1;
       ROLLBACK;
   END
   ELSE
   BEGIN
       -- Retrieve details of properties currently owned by the specified owner
       SELECT o.FullName AS OwnerName,
              n.NeighborhoodName,
              pt.PropertyTypeName,
              p.MarketValue,
              p.AddressNumber + ' ' + p.StreetName + ' ' + p.StreetSuffix
              + CASE WHEN p.AddressLine2 IS NOT NULL AND p.AddressLine2 <> '' THEN ', ' + p.AddressLine2 ELSE '' END
              + ', ' + p.City + ' ' + p.ZipCode AS FullAddress
       FROM tblProperty p
       JOIN tblOwnership ow ON p.PropertyID = ow.PropertyID
       JOIN tblOwner o ON ow.OwnerID = o.OwnerID
       JOIN tblNeighborhood n ON p.NeighborhoodID = n.NeighborhoodID
       JOIN tblPropertyType pt ON p.PropertyTypeID = pt.PropertyTypeID
       WHERE o.OwnerID = @OwnerID
       ORDER BY p.MarketValue DESC;


       COMMIT TRAN CheckOwner;
   END
END
GO


-- Example Execution:
EXEC GetPropertiesByOwner @OwnerFullName = 'Jerrylee Breagan';










/*
3. Query to Identify Neighborhoods with a High Percentage of Never-Rented Properties


Purpose:
Highlights neighborhoods where properties have never been leased out. This can indicate areas with
predominantly owner-occupied homes, new developments not yet on the rental market, or less interest from renters.


Results:
Shows each neighborhood’s share of properties that have never appeared in the Rental table.


Implications/Recommendations:
   •   Real estate agents can target these neighborhoods to either encourage rentals or find
   buyers preferring non-rental communities.
   •   Investors might look here for untapped rental opportunities.
   •   Urban planners can understand housing market dynamics—areas with high owner-occupancy
   vs. rental-driven neighborhoods.
*/


-- Identify neighborhoods where a significant portion of properties have never been rented




GO
WITH AllProperties AS (
   SELECT p.PropertyID, p.NeighborhoodID
   FROM tblProperty p
),
RentedProperties AS (
   SELECT DISTINCT p.PropertyID
   FROM tblProperty p
   JOIN tblRentalDetail r ON p.PropertyID = r.PropertyID
),
NeverRented AS (
   SELECT ap.PropertyID, ap.NeighborhoodID
   FROM AllProperties ap
   LEFT JOIN RentedProperties rp ON ap.PropertyID = rp.PropertyID
   WHERE rp.PropertyID IS NULL
)
SELECT n.NeighborhoodName,
      COUNT(nr.PropertyID) AS NeverRentedCount,
      (COUNT(nr.PropertyID)*1.0 / COUNT(ap.PropertyID)*1.0)*100 AS PercentageNeverRented
FROM AllProperties ap
JOIN tblNeighborhood n ON ap.NeighborhoodID = n.NeighborhoodID
LEFT JOIN NeverRented nr ON ap.PropertyID = nr.PropertyID
GROUP BY n.NeighborhoodName
ORDER BY PercentageNeverRented DESC;




--SECOND ONE












-- 1. Query to calculate the total rental income (of active rentals) for each neighborhood.
-- Orders the final result by each neighborhood's TotalRentalIncome DESC.


-- Purpose: Provides a summary of total rental income of currently active rentals, grouped by neighborhood.


-- Results: Identifies each neighborhood's rental income.


-- Implications/Recommendations:
-- Determine amount and type of investments or marketing efforts in a neighborhood depending on the income.
-- Examine neighborhoods with low rental income for potential improvement in rental property offerings.


--Only get active rentals
WITH ActiveRentals AS (
   SELECT rd.PropertyID, rd.RentalPrice, p.NeighborhoodID
   FROM tblRentalDetail rd
   JOIN tblProperty p ON rd.PropertyID = p.PropertyID
   WHERE rd.EndDate IS NULL OR rd.EndDate > GETDATE()
)
--Calculate the total rental income and return results
SELECT n.NeighborhoodName, SUM(CAST(ar.RentalPrice AS DECIMAL(18, 2))) AS TotalRentalIncome
FROM ActiveRentals ar
JOIN tblNeighborhood n ON ar.NeighborhoodID = n.NeighborhoodID
GROUP BY n.NeighborhoodName
ORDER BY TotalRentalIncome DESC


-- 2. Stored procedure to get all properties in a specified neighborhood.


-- Purpose: Retrieves information about properties located in a given neighborhood, including property type and price per square foot.


-- Results: Provides neighborhood specific property details.


-- Implications/Recommendations:
-- One could use the output to assess the distribution of property types, and their respective market values within a specific neighborhood.
GO
CREATE OR ALTER PROCEDURE GetAllPropertiesInNeighborhood
   @NeighborhoodName VARCHAR(100)
AS
DECLARE @NeighborhoodID INT
BEGIN
   BEGIN TRAN T1


   -- Retrieve NeighborhoodID based on NeighborhoodName
   SET @NeighborhoodID = (SELECT NeighborhoodID FROM tblNeighborhood WHERE NeighborhoodName = @NeighborhoodName);


   -- Error Handling: Check if NeighborhoodID is NULL
   IF @NeighborhoodID IS NULL
       BEGIN
           PRINT 'Neighborhood does not exist. Check the spelling of the provided NeighborhoodName.';
           THROW 50061, 'The specified neighborhood does not exist in the database. Transaction is terminating.', 1;
           ROLLBACK;
       END
   ELSE
       BEGIN
           -- Retrieve property details for the specified neighborhood
           SELECT n.NeighborhoodName,
               pt.PropertyTypeName,
               p.MarketValue,
               p.SquareFeet,
               p.PricePerSqFt,
               p.AddressNumber + ' ' + p.StreetName + ' ' + p.StreetSuffix AS FullAddress
           FROM tblProperty p
           JOIN tblNeighborhood n ON p.NeighborhoodID = n.NeighborhoodID
           JOIN tblPropertyType pt ON p.PropertyTypeID = pt.PropertyTypeID
           WHERE n.NeighborhoodID = @NeighborhoodID
           ORDER BY p.MarketValue DESC


           COMMIT TRAN T1;
       END
END
GO


EXEC GetPropertiesInNeighborhood @NeighborhoodName = 'Capitol Hill'


-- 3. Query to retrieve the top 5 most expensive and least expensive properties for each property type, including the neighborhood.


-- Purpose: Identifies both the highest and lowest value properties for each property type.


-- Results: Provides a comparison of high-value and low-value properties across property types and neighborhoods.


-- Implications/Recommendations:
-- Use high-value property insights for targeting premium buyers or investors.
-- Leverage low-value property insights for improving or marketing to budget-conscious buyers.


-- CTE for the top 5 most expensive properties
GO
WITH MostExpensiveProperties AS (
   SELECT pt.PropertyTypeName,
       p.PropertyID,
       n.NeighborhoodName,
       p.MarketValue,
       RANK() OVER (PARTITION BY pt.PropertyTypeID ORDER BY p.MarketValue DESC) AS PropertyRank
   FROM tblProperty p
   JOIN tblPropertyType pt ON p.PropertyTypeID = pt.PropertyTypeID
   JOIN tblNeighborhood n ON p.NeighborhoodID = n.NeighborhoodID
   WHERE p.MarketValue IS NOT NULL
),
-- CTE for the top 5 least expensive properties
LeastExpensiveProperties AS (
   SELECT pt.PropertyTypeName,
       p.PropertyID,
       n.NeighborhoodName,
       p.MarketValue,
       RANK() OVER (PARTITION BY pt.PropertyTypeID ORDER BY p.MarketValue ASC) AS PropertyRank
   FROM tblProperty p
   JOIN tblPropertyType pt ON p.PropertyTypeID = pt.PropertyTypeID
   JOIN tblNeighborhood n ON p.NeighborhoodID = n.NeighborhoodID
   WHERE p.MarketValue IS NOT NULL
)
-- Combine
SELECT 'Most Expensive' AS RankCategory,
   PropertyRank,
   PropertyTypeName,
   NeighborhoodName,
   PropertyID,
   MarketValue
FROM MostExpensiveProperties
WHERE PropertyRank <= 5


UNION ALL


SELECT 'Least Expensive' AS RankCategory,
   PropertyRank,
   PropertyTypeName,
   NeighborhoodName,
   PropertyID,
   MarketValue
FROM LeastExpensiveProperties
WHERE PropertyRank <= 5
ORDER BY PropertyTypeName, RankCategory, PropertyRank, MarketValue DESC






