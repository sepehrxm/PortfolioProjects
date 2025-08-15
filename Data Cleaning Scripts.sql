-- Data Cleaning Queries for Mock Tehran Housing Data

SELECT * FROM dbo.TehranHousingData

-- Change date column format

SELECT TOP 1 SaleDate, 
	SQL_VARIANT_PROPERTY(SaleDate, 'BaseType') AS DataType
FROM dbo.TehranHousingData

ALTER TABLE dbo.TehranHousingData
ALTER COLUMN SaleDate DATE

SELECT TOP 1 SaleDate FROM dbo.TehranHousingData

-- Fill missing addresses by matching ParcelID

UPDATE t1
SET t1.PropertyAddress = t2.PropertyAddress
FROM dbo.TehranHousingData AS t1
JOIN dbo.TehranHousingData AS t2
	ON t1.ParcelID = t2.ParcelID
	AND t2.PropertyAddress IS NOT NULL
WHERE t1.PropertyAddress IS NULL

-- Extracting Address and District from PropertyAddress

ALTER TABLE dbo.TehranHousingData
ADD Address NVARCHAR(255), District NVARCHAR(255)

UPDATE dbo.TehranHousingData
SET
	Address = LTRIM(RTRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ))),
	District = LTRIM(RTRIM(REPLACE(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1,
	CHARINDEX(',', PropertyAddress, CHARINDEX(',', PropertyAddress) + 1) 
	- CHARINDEX(',', PropertyAddress) - 1), 'DISTRICT','')))

SELECT PropertyAddress, Address, District FROM TehranHousingData

-- Extracting District from OwnerAddress using PARSENAME

ALTER TABLE dbo.TehranHousingData
ADD OwnerDistrict NVARCHAR(255)

UPDATE dbo.TehranHousingData
SET OwnerDistrict = LTRIM(RTRIM(REPLACE(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), ' DISTRICT', '')))

SELECT OwnerAddress, OwnerDistrict FROM TehranHousingData

-- Change 0/1 to Yes/No in SoldAsVacant Column

ALTER TABLE dbo.TehranHousingData
ALTER COLUMN SoldAsVacant NVARCHAR(3)

UPDATE dbo.TehranHousingData
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 0 THEN 'No'
	WHEN SoldAsVacant = 1 THEN 'Yes'
	END

SELECT SoldAsVacant FROM TehranHousingData

-- Identify duplicate owners

SELECT OwnerName, COUNT(OwnerName) AS Count
FROM dbo.TehranHousingData
WHERE OwnerName IS NOT NULL
GROUP BY OWNERNAME
HAVING COUNT(*) > 1

WITH OwnerDuplicates AS(
	SELECT *,
        ROW_NUMBER() OVER (PARTITION BY OwnerName ORDER BY UniqueID) rn,
        COUNT(*) OVER (PARTITION BY OwnerName) cnt
    FROM dbo.TehranHousingData
	WHERE OwnerName IS NOT NULL
)
SELECT *
FROM OwnerDuplicates
WHERE cnt > 1

-- Delete unnecessary columns

ALTER TABLE dbo.TehranHousingData
DROP COLUMN PropertyAddress, LegalReference, Acreage, TaxDistrict, LandValue, BuildingValue, FullBath, HalfBath


SELECT * FROM TehranHousingData

