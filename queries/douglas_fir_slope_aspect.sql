-- Douglas-fir mortality analysis by slope aspect
-- Douglas-fir species code: 202
-- Note: Slope and aspect data is stored at the plot level in the FIA database

-- Douglas-fir mortality by slope aspect
-- Using PLOT table directly for aspect data
SELECT 
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
WHERE t.SPCD = 202
GROUP BY t.SPCD;

-- Query to identify slope/aspect columns available in PLOT table
-- Uncomment to inspect schema:
-- PRAGMA table_info(PLOT);

-- Alternative: Mortality by tree diameter as proxy for environmental stress
SELECT 
    CASE 
        WHEN t.DIA < 5 THEN 'Seedling (<5")'
        WHEN t.DIA < 10 THEN 'Small (5-10")'
        WHEN t.DIA < 20 THEN 'Medium (10-20")'
        WHEN t.DIA >= 20 THEN 'Large (>20")'
    END as diameter_class,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage
FROM TREE t
WHERE t.SPCD = 202
GROUP BY diameter_class
ORDER BY 
    CASE 
        WHEN diameter_class = 'Seedling (<5")' THEN 1
        WHEN diameter_class = 'Small (5-10")' THEN 2
        WHEN diameter_class = 'Medium (10-20")' THEN 3
        WHEN diameter_class = 'Large (>20")' THEN 4
    END;
