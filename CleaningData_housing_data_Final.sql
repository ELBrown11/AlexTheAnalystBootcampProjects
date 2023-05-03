-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- 										CLEANING DATA                                                --
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- preview the data 
SELECT *
FROM BootcampDB.NashvilleHousingData nhd 
LIMIT 10;

-------------------------------------------------------------------------------------------------------
-- 							        STANDARDIZED DATE FORMAT                                         --
/*
 We want to format the date in short form because the time part of the date time doesn't provide 
 any information in this case. To this we add a column called SaleDateConverted which will contain
 the date in short form. Because I converted the data file from xlsx to csv in Google sheets it 
 change that date time to a format which dbeaver or mysql doesn't recognize therefore it's seen
 as a string. So I converted it do a date via STR_TO_DATE function.
 */
-------------------------------------------------------------------------------------------------------
-- adds new column SaleDateConverted to the table
ALTER TABLE BootcampDB.NashvilleHousingData  
ADD SaleDateConverted Date;

UPDATE BootcampDB.NashvilleHousingData  
SET SaleDateConverted = STR_TO_DATE(SaleDate , '%m/%d/%Y %H:%i:%s')


-------------------------------------------------------------------------------------------------------
-- 				                POPULATE PROPERTY ADDRESS DATA                                       --
/*
 There are certain rows where the PropertyAddress data is missing in that row but the data is in a 
 row. The ParcelID and UniqueID can be use to identify that a row is for the same property and 
 then you can use the info from one row to another to populate the missing data. 
 */
-------------------------------------------------------------------------------------------------------
-- counts how many rows have missing PropertyAddress data
SELECT COUNT(*)
From BootcampDB.NashvilleHousingData nhd 
WHERE PropertyAddress IS NULL;

-- self join to compare rows with missing data with ifnull column where that missing data would be populated
SELECT nhd.ParcelID, nhd.PropertyAddress, nhd2.ParcelID, nhd2.PropertyAddress, 
		IFNULL(nhd.PropertyAddress, nhd2.PropertyAddress)/*this function say if the first argument 
														   is empty/null replace it with the second 
														   argument*/
FROM BootcampDB.NashvilleHousingData nhd 
JOIN BootcampDB.NashvilleHousingData nhd2 
	ON nhd.ParcelID = nhd2.ParcelID 
	AND nhd.UniqueID <> nhd2.UniqueID -- same parcel id but different row 
WHERE nhd.PropertyAddress is NULL;


-- actually updating the table based on what was test in the above ^ query
UPDATE BootcampDB.NashvilleHousingData nhd
JOIN BootcampDB.NashvilleHousingData nhd2 
	ON nhd.ParcelID = nhd2.ParcelID 
	AND nhd.UniqueID <> nhd2.UniqueID
SET nhd.PropertyAddress = IFNULL(nhd.PropertyAddress, nhd2.PropertyAddress)
WHERE nhd.PropertyAddress IS NULL;

------------------------------------------------------------------------------------------------------
-- 					 BREAKING UP ADDRESS INTO COLUMNS (ADDRESS, CITY, STATE)                        --
/*
We want to break the PropertyAddress and OwnerAddress column into address city and state columns 
because in their original format they are less usuable. When broken down into seperate columns we're
able to analyze by state and city which could be useful if we want to know more about those specific
areas and not just one specific address.
*/
------------------------------------------------------------------------------------------------------
--                             SEPERATING BY PROPERTY ADDRESS                                       --
------------------------------------------------------------------------------------------------------
-- exploring ProperyAddress data
SELECT PropertyAddress
FROM BootcampDB.NashvilleHousingData nhd;

-- testing out how we seperate the address column to show address and city seperately
SELECT SUBSTR(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1) AS Address, -- everthing before the comma
	   SUBSTR(PropertyAddress, LOCATE(',', PropertyAddress)+1,LENGTH(PropertyAddress)) AS City -- after the comma
	-- looks at PropertyAddress goes to the first value until the comma
FROM BootcampDB.NashvilleHousingData nhd;


-- adds new column PropertySplitAddress to the table
ALTER TABLE BootcampDB.NashvilleHousingData  
ADD PropertySplitAddress Nvarchar(255);

-- adds new column PropertySplitCity to the table
ALTER TABLE BootcampDB.NashvilleHousingData  
ADD PropertySplitCity Nvarchar(255);

-- updating/populating columns that were just created ^
UPDATE BootcampDB.NashvilleHousingData nhd 
SET PropertySplitAddress = SUBSTR(PropertyAddress, 1, LOCATE(',', PropertyAddress)-1);

UPDATE BootcampDB.NashvilleHousingData nhd 
SET PropertySplitCity = SUBSTR(PropertyAddress, LOCATE(',', PropertyAddress)+1,LENGTH(PropertyAddress));

------------------------------------------------------------------------------------------------------
--                             SEPERATING BY OWNER ADDRESS                                       --
------------------------------------------------------------------------------------------------------
-- explore owner_address data
SELECT OwnerAddress
FROM BootcampDB.NashvilleHousingData nhd;
    -- owner address contains city and state data


-- using substring_index() to seperate address, city, state in OwnerAddress
SELECT SUBSTRING_INDEX(OwnerAddress,',', 1) as Address,
	   SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2),',',-1) as City,
	   SUBSTRING_INDEX(OwnerAddress,',', -1) as State
-- SUBSTRING_INDEX(REPLACE(OwnerAddress,',',''),' ', -2) AS State
FROM BootcampDB.NashvilleHousingData nhd;


-- adds new column OwnerAddressSplit to the table
ALTER TABLE BootcampDB.NashvilleHousingData  
ADD OwnerAddressSplit Nvarchar(255);

-- adds new column OwnerCitySplit to the table
ALTER TABLE BootcampDB.NashvilleHousingData  
ADD OwnerCitySplit Nvarchar(255);

-- adds new column OwnerStateSplit to the table
ALTER TABLE BootcampDB.NashvilleHousingData  
ADD OwnerStateSplit Nvarchar(255);

-- updating/populating columns that were just created ^
UPDATE BootcampDB.NashvilleHousingData nhd 
SET OwnerAddressSplit = SUBSTRING_INDEX(OwnerAddress,',', 1);


UPDATE BootcampDB.NashvilleHousingData nhd 
SET OwnerCitySplit = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2),',',-1);


UPDATE BootcampDB.NashvilleHousingData nhd 
SET OwnerStateSplit = SUBSTRING_INDEX(OwnerAddress,',', -1);

SELECT OwnerAddressSplit, OwnerCitySplit, OwnerStateSplit
FROM BootcampDB.NashvilleHousingData nhd;

------------------------------------------------------------------------------------------------------
--                  CHANGING Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD                        --
------------------------------------------------------------------------------------------------------

-- using distinct similar to value counts in python so see the different response/data tyeps
SELECT DISTINCT(SoldAsVacant)
FROM BootcampDB.NashvilleHousingData nhd;
 -- we see that there are 4 different responses but there should just be true, need to convert N--No, Y--Yes

-- to see how many are each repsonse there are more like value counts
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) counts
FROM BootcampDB.NashvilleHousingData nhd
GROUP BY SoldAsVacant 
ORDER BY 2 DESC;

/*After doing some exploration of the SoldAsVacant column we see that there are 4 different responses
 * but the Ns and Ys actually indicate No and Yes. Yes and No are also captured more frequently so 
 * to make this data more uniform and easy to analyze we need to chane the Ns --> No's and Ys --> Yes's.
 * We can do this via CASE WHEN which is similar to a python if statement but use it to replace the Y and
 * N data*/

-- testing the implementatio of CASE WHEN
SELECT SoldAsVacant,
	   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   		WHEN SoldAsVacant = 'N' THEN 'No'
	   		ELSE SoldAsVacant 
	   		END
FROM BootcampDB.NashvilleHousingData nhd;


-- changes values in SoldAsVacant so there are only yes and no, removing ys and ns
UPDATE BootcampDB.NashvilleHousingData nhd 
SET SoldAsVacant  =CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   		            WHEN SoldAsVacant = 'N' THEN 'No'
	   					ELSE SoldAsVacant 
	   					END

------------------------------------------------------------------------------------------------------
--                                  REMOVING DUPLICATES                                             --
------------------------------------------------------------------------------------------------------
-- using at CTE and window functions to find duplicates
-- partitioning data using row number
WITH RowNumCTE AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
    ORDER BY UniqueID
  ) row_num
  FROM BootcampDB.NashvilleHousingData nhd
)
DELETE FROM RowNumCTE
WHERE row_num > 1;

------------------------------------------------------------------------------------------------------
--                                  DELETE UNUSED COLUMNS                                           --
------------------------------------------------------------------------------------------------------
/*Some columns does provide much useful information for what you're trying to explore. In that case you 
 * can remove them from your working table so that you can focus on the columns of data that you want to
 * explore and analyze*/

-- removing OwnerAddress, PropertyAddress, TaxDistrict
ALTER TABLE BootcampDB.NashvilleHousingData 
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;

ALTER TABLE BootcampDB.NashvilleHousingData 
DROP COLUMN SaleDate;





		
