-- Douglas-fir mortality analysis by slope aspect
-- Douglas-fir species code: 202
-- Aspect values: 1=North, 2=NE, 3=East, 4=SE, 5=South, 6=SW, 7=West, 8=NW, 9=Flat

-- Douglas-fir mortality by slope aspect
SELECT 
    CASE 
        WHEN c.ASPECT = 1 THEN 'North'
        WHEN c.ASPECT = 2 THEN 'Northeast'
        WHEN c.ASPECT = 3 THEN 'East'
        WHEN c.ASPECT = 4 THEN 'Southeast'
        WHEN c.ASPECT = 5 THEN 'South'
        WHEN c.ASPECT = 6 THEN 'Southwest'
        WHEN c.ASPECT = 7 THEN 'West'
        WHEN c.ASPECT = 8 THEN 'Northwest'
        WHEN c.ASPECT = 9 THEN 'Flat'
        ELSE 'Unknown'
    END as aspect,
    c.ASPECT as aspect_code,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage,
    ROUND(AVG(c.SLOPE), 2) as avg_slope_percent
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN CONDITION c ON p.PLT_CN = c.PLT_CN
WHERE t.SPCD = 202 AND c.CONDID = 1
GROUP BY c.ASPECT
ORDER BY dead_trees DESC;

-- Douglas-fir mortality by slope aspect and slope steepness
SELECT 
    CASE 
        WHEN c.ASPECT = 1 THEN 'North'
        WHEN c.ASPECT = 2 THEN 'Northeast'
        WHEN c.ASPECT = 3 THEN 'East'
        WHEN c.ASPECT = 4 THEN 'Southeast'
        WHEN c.ASPECT = 5 THEN 'South'
        WHEN c.ASPECT = 6 THEN 'Southwest'
        WHEN c.ASPECT = 7 THEN 'West'
        WHEN c.ASPECT = 8 THEN 'Northwest'
        WHEN c.ASPECT = 9 THEN 'Flat'
        ELSE 'Unknown'
    END as aspect,
    CASE 
        WHEN c.SLOPE < 10 THEN '0-10%'
        WHEN c.SLOPE < 20 THEN '10-20%'
        WHEN c.SLOPE < 30 THEN '20-30%'
        WHEN c.SLOPE < 40 THEN '30-40%'
        ELSE '40%+'
    END as slope_category,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN CONDITION c ON p.PLT_CN = c.PLT_CN
WHERE t.SPCD = 202 AND c.CONDID = 1
GROUP BY c.ASPECT, slope_category
ORDER BY c.ASPECT, slope_category;

-- Summary: Aspect exposure groups (Heat-exposed vs Shade-exposed)
SELECT 
    CASE 
        WHEN c.ASPECT IN (5, 6, 7) THEN 'Heat-Exposed (S/SW/W)'
        WHEN c.ASPECT IN (1, 2, 8) THEN 'Cool-Exposed (N/NE/NW)'
        WHEN c.ASPECT IN (3, 4) THEN 'East-Facing'
        ELSE 'Flat'
    END as exposure_group,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN CONDITION c ON p.PLT_CN = c.PLT_CN
WHERE t.SPCD = 202 AND c.CONDID = 1
GROUP BY exposure_group
ORDER BY mortality_percentage DESC;
