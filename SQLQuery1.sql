USE Housing_Data;
GO

SELECT *
FROM Housing_Data..nashville_housing;


--
--
-- Modify sale date
--
--
SELECT Sale_Date
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD Sale_Date DATE;

UPDATE nashville_housing
SET Sale_Date = CONVERT(DATE, SaleDate);


--
--
-- Cleaning the property address data
--
--
SELECT *
FROM nashville_housing
ORDER BY ParcelID;

SELECT 
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL OR b.PropertyAddress IS NULL
ORDER BY a.PropertyAddress;

UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville_housing a
JOIN nashville_housing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]


--
--
-- Parting adress into address, city, state
--
--
SELECT PropertyAddress
FROM nashville_housing;

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS adress,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD property_address NVARCHAR(255);

UPDATE nashville_housing
SET property_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD city NVARCHAR(255);

ALTER TABLE nashville_housing
ADD property_city NVARCHAR(255);

UPDATE nashville_housing
SET property_city = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2, LEN(PropertyAddress))
FROM nashville_housing;

SELECT property_address, city
FROM nashville_housing;

SELECT OwnerAddress
FROM nashville_housing;

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD owner_address NVARCHAR(255);

UPDATE nashville_housing
SET owner_address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE nashville_housing
ADD owner_city NVARCHAR(255);

UPDATE nashville_housing
SET owner_city = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE nashville_housing
ADD owner_state NVARCHAR(255);

UPDATE nashville_housing
SET owner_state = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT *
FROM nashville_housing;


--
--
-- Change Y and N to Yes and No in "SoldAsVacant"

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashville_housing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT 
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldASVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM nashville_housing;


UPDATE nashville_housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldASVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM nashville_housing;



--
--
--Removing duplicates
--
--
WITH row_num_cte AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY UniqueID
	) AS row_num
FROM nashville_housing
)
SELECT *
FROM row_num_cte
WHERE row_num > 1;


--
--
--Deleting unused columns
--
--

SELECT *
FROM nashville_housing

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

ALTER TABLE nashville_housing
DROP COLUMN SaleDate;