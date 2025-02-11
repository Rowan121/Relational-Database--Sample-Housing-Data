# Relational-Database--Sample-Housing-Data

Project: Creating a Relational Database using sample housing data

Description: This project involves fabricating a historical housing record data set, complete with neighborhood time series history as well as ownership history. The goal was to get as close to a real historical housing dataset as possible. The project involves creating sample data through Mockaroo, transforming >10,000 rows of data to prepare for analysis, and analyzing the data through unique SQL queries (CTEs, WINDOW functions) and objects (stored procedures, constraints, computed columns).

Sample Queries: A query to identify neighborhoods with high turnover (CTE), a query to identify neighborhoods with lots of never-rented properties (joins, subqueries), a query to identify total rental income for each neighborhood (uses CTE).

Sample Objects: A stored procedure to add a new property into the property table, a constraint ensuring that a property's market value, rooms numbers, and square footage are non-negative, and that ZipCode is the correct format, a computed column to compute a columns price per squre foot (market value/square feet).
 
See more objects and queries in the respective files!

SQL Skills Used: Data Cleaning, Data Transformation, Data Normalization, Handling Missing/Incorrect Values. 

Below is the ERD (Entity Relatoinship Diagram) for the project: 

![2:10 ApprovedModel](https://github.com/user-attachments/assets/2ac94557-a2d0-443c-a5bb-991f3cfe5ec8)
