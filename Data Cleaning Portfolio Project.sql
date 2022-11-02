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


-- Standardizing the Date Format


SELECT SaleDate, CONVERT(Date,SaleDate)
FROM PortfolioProject2.dbo.NashvilleHousing


UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- Populating propery address data

-- to check if there are null addresses

SELECT PropertyAddress
FROM PortfolioProject2.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL


SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing
ORDER BY ParcelID

-- We see that ParcelID and Porperty address is correlated. So, we can populate the address if the ParcelID is known

SELECT nash1.ParcelID, nash1.PropertyAddress, nash2.ParcelID, nash2.PropertyAddress
FROM PortfolioProject2.dbo.NashvilleHousing nash1
JOIN PortfolioProject2.dbo.NashvilleHousing nash2
    ON nash1.ParcelID = nash2.ParcelID
    AND nash1.UniqueID <> nash2.UniqueID
WHERE nash1.PropertyAddress IS NULL

-- so if nash1.ParcelID is null, we can populate with nash2.ParcelID

UPDATE nash1
SET PropertyAddress = ISNULL(nash1.PropertyAddress, nash2.PropertyAddress)
FROM PortfolioProject2.dbo.NashvilleHousing nash1
JOIN PortfolioProject2.dbo.NashvilleHousing nash2
    ON nash1.ParcelID = nash2.ParcelID
    AND nash1.UniqueID <> nash2.UniqueID

SELECT nash1.ParcelID, nash1.PropertyAddress, nash2.ParcelID, nash2.PropertyAddress, ISNULL(nash1.PropertyAddress, nash2.PropertyAddress)
FROM PortfolioProject2.dbo.NashvilleHousing nash1
JOIN PortfolioProject2.dbo.NashvilleHousing nash2
    ON nash1.ParcelID = nash2.ParcelID
    AND nash1.UniqueID <> nash2.UniqueID
WHERE nash1.PropertyAddress IS NULL

-- no null values are seen, so the ProperyAddress is populated

-- Splitting address into separate columns (Address, City, State)

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,  -- we subtract 1 since the comma at the end is unnecessary
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProject2.dbo.NashvilleHousing

-- now we can alter the table

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
ADD PropertySplitAddress Nvarchar(255)

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing 
ADD PropertySplitCity Nvarchar(255)

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Update PortfolioProject2.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing

-- now splitting the owneraddress

-- parsename uses dot, so replacing comma with dot.

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) AS State
FROM PortfolioProject2.dbo.NashvilleHousing

-- Altering the table

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

-- to view

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing

-- SoldAsVacant is not consistent since there are both Yes and Y, and No and N

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS CountSoldAsVacant
FROM PortfolioProject2.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC

-- correcting them to be consistent

SELECT SoldAsVacant,
CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END
FROM PortfolioProject2.dbo.NashvilleHousing

-- updating the data

UPDATE PortfolioProject2.dbo.NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END

-- checking again

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS CountSoldAsVacant
FROM PortfolioProject2.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC

-- Removing duplicates

SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
                ) AS row_num
FROM PortfolioProject2.dbo.NashvilleHousing
ORDER BY ParcelID

-- to see where row_num > 1 that is the duplicate rows, we can use CTE

WITH RowNumCTE AS (
    SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
                ) AS row_num
FROM PortfolioProject2.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1

-- deleting the duplicates

WITH RowNumCTE AS (
    SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
                ) AS row_num
FROM PortfolioProject2.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Deleting unused columns
-- We created new columns regarding the owneraddress, property address and sale date and they are more useful.

SELECT *
FROM PortfolioProject2.dbo.NashvilleHousing

ALTER TABLE PortfolioProject2.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
