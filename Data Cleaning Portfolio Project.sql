-- Create a new database called 'PortfolioProject2'
-- Connect to the 'master' database to run this snippet

/*
USE master
GO
-- Create the new database if it does not exist already
IF NOT EXISTS (
    SELECT [name]
        FROM sys.databases
        WHERE [name] = N'PortfolioProject2'
)
CREATE DATABASE PortfolioProject2
GO

*/

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject2.dbo.NashvilleHousing


UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)



-- Removing duplicates


-- Deleting unused columns
