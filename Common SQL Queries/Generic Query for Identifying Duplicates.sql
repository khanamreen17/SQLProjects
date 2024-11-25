--Generic Query for Identifying Duplicates

WITH RankedRows AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY EntityIDColumn ORDER BY TimestampColumn DESC) AS RowNum
    FROM 
        YourTable
)
SELECT 
    *,
    CASE 
        WHEN RowNum > 1 THEN 'Duplicate'
        ELSE 'Original'
    END AS RowStatus
FROM 
    RankedRows;