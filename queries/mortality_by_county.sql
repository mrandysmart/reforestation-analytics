-- Douglas-fir Mortality Summary by County
-- Requires joining TREE, PLOT, and COUNTY tables
-- Douglas-fir species code: 202

-- Mortality summary by county
SELECT 
    c.COUNTYCD as county_code,
    c.COUNTYNM as county_name,
    c.STATECD as state,
    COUNT(*) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_rate_pct,
    ROUND(AVG(t.DIA), 2) as avg_diameter,
    ROUND(AVG(t.HT), 2) as avg_height
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN COUNTY c ON p.COUNTYCD = c.COUNTYCD
WHERE t.SPCD = 202
GROUP BY c.COUNTYCD, c.COUNTYNM, c.STATECD
ORDER BY mortality_rate_pct DESC, total_trees DESC;

-- County-level mortality by survey year (temporal trend)
SELECT 
    c.COUNTYNM as county_name,
    c.STATECD as state,
    s.INVYR as inventory_year,
    COUNT(*) as tree_count,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_rate_pct
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN SURVEY s ON p.SURVEYCD = s.SURVEYCD
JOIN COUNTY c ON p.COUNTYCD = c.COUNTYCD
WHERE t.SPCD = 202
GROUP BY c.COUNTYNM, c.STATECD, s.INVYR
ORDER BY c.COUNTYNM, s.INVYR;

-- Top 10 counties by Douglas-fir mortality count
SELECT 
    c.COUNTYNM as county_name,
    c.STATECD as state,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    COUNT(*) as total_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_rate_pct
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN COUNTY c ON p.COUNTYCD = c.COUNTYCD
WHERE t.SPCD = 202 AND t.STATUSCD = 2
GROUP BY c.COUNTYCD, c.COUNTYNM, c.STATECD
ORDER BY dead_trees DESC
LIMIT 10;

-- County mortality summary with diameter class breakdown
SELECT 
    c.COUNTYNM as county_name,
    c.STATECD as state,
    CASE 
        WHEN t.DIA < 5 THEN 'Seedling (<5")'
        WHEN t.DIA < 10 THEN 'Small (5-10")'
        WHEN t.DIA < 20 THEN 'Medium (10-20")'
        WHEN t.DIA >= 20 THEN 'Large (>20")'
    END as diameter_class,
    COUNT(*) as tree_count,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_rate_pct
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN COUNTY c ON p.COUNTYCD = c.COUNTYCD
WHERE t.SPCD = 202
GROUP BY c.COUNTYCD, c.COUNTYNM, c.STATECD, diameter_class
ORDER BY c.COUNTYNM, 
    CASE 
        WHEN diameter_class = 'Seedling (<5")' THEN 1
        WHEN diameter_class = 'Small (5-10")' THEN 2
        WHEN diameter_class = 'Medium (10-20")' THEN 3
        WHEN diameter_class = 'Large (>20")' THEN 4
    END;
