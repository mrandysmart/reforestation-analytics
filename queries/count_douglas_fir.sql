-- Count Douglas-fir records in FIA database
-- Douglas-fir species code: 202

-- Total Douglas-fir tree records
SELECT 
    COUNT(*) as total_douglas_fir_records
FROM TREE
WHERE SPCD = 202;

-- Douglas-fir records by status (alive vs dead)
SELECT 
    CASE 
        WHEN STATUSCD = 1 THEN 'Live'
        WHEN STATUSCD = 2 THEN 'Dead'
        ELSE 'Other'
    END as status,
    COUNT(*) as count
FROM TREE
WHERE SPCD = 202
GROUP BY STATUSCD
ORDER BY count DESC;

-- Douglas-fir records by plot with status breakdown
SELECT 
    PLT_CN,
    COUNT(*) as tree_count,
    SUM(CASE WHEN STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees
FROM TREE
WHERE SPCD = 202
GROUP BY PLT_CN
ORDER BY tree_count DESC;

-- Douglas-fir mortality summary statistics
SELECT 
    COUNT(*) as total_trees,
    SUM(CASE WHEN STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_percentage
FROM TREE
WHERE SPCD = 202;
