-- Douglas-fir mortality analysis by slope aspect
-- Douglas-fir species code: 202
-- Aspect values: 1=North, 2=NE, 3=East, 4=SE, 5=South, 6=SW, 7=West, 8=NW, 9=Flat

-- Douglas-fir mortality by slope aspect
SELECT 
    CASE 
        WHEN p.ASPECT = 1 THEN 'North'
        WHEN p.ASPECT = 2 THEN 'Northeast'
        WHEN p.ASPECT = 3 THEN 'East'
        WHEN p.ASPECT = 4 THEN 'Southeast'
        WHEN p.ASPECT = 5 THEN 'South'
        WHEN p.ASPECT = 6 THEN 'Southwest'
        WHEN p.ASPECT = 7 THEN 'West'
        WHEN p.ASPECT = 8 THEN 'Northwest'
        WHEN p.ASPECT = 9 THEN 'Flat'
        ELSE 'Unknown'
    END as aspect,
    p.ASPECT as aspect_code,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage,
    ROUND(AVG(p.SLOPE), 2) as avg_slope_percent
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
WHERE t.SPCD = 202
GROUP BY p.ASPECT
ORDER BY dead_trees DESC;

-- Douglas-fir mortality by slope aspect and slope steepness
SELECT 
    CASE 
        WHEN p.ASPECT = 1 THEN 'North'
        WHEN p.ASPECT = 2 THEN 'Northeast'
        WHEN p.ASPECT = 3 THEN 'East'
        WHEN p.ASPECT = 4 THEN 'Southeast'
        WHEN p.ASPECT = 5 THEN 'South'
        WHEN p.ASPECT = 6 THEN 'Southwest'
        WHEN p.ASPECT = 7 THEN 'West'
        WHEN p.ASPECT = 8 THEN 'Northwest'
        WHEN p.ASPECT = 9 THEN 'Flat'
        ELSE 'Unknown'
    END as aspect,
    CASE 
        WHEN p.SLOPE < 10 THEN '0-10%'
        WHEN p.SLOPE < 20 THEN '10-20%'
        WHEN p.SLOPE < 30 THEN '20-30%'
        WHEN p.SLOPE < 40 THEN '30-40%'
        ELSE '40%+'
    END as slope_category,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
WHERE t.SPCD = 202
GROUP BY p.ASPECT, slope_category
ORDER BY p.ASPECT, slope_category;

-- Summary: Aspect exposure groups (Heat-exposed vs Shade-exposed)
SELECT 
    CASE 
        WHEN p.ASPECT IN (5, 6, 7) THEN 'Heat-Exposed (S/SW/W)'
        WHEN p.ASPECT IN (1, 2, 8) THEN 'Cool-Exposed (N/NE/NW)'
        WHEN p.ASPECT IN (3, 4) THEN 'East-Facing'
        ELSE 'Flat'
    END as exposure_group,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
WHERE t.SPCD = 202
GROUP BY exposure_group
ORDER BY mortality_percentage DESC;
