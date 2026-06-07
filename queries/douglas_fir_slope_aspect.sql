-- Douglas-fir mortality analysis by slope aspect
-- Douglas-fir species code: 202
-- Note: Slope and aspect data is stored at the plot level in the FIA database

-- Douglas-fir mortality by slope and aspect
-- Groups by slope and aspect ranges to analyze environmental impacts on mortality
SELECT 
    CASE 
        WHEN p.ASPECT < 45 OR p.ASPECT >= 315 THEN 'N (315-45°)'
        WHEN p.ASPECT < 135 THEN 'E (45-135°)'
        WHEN p.ASPECT < 225 THEN 'S (135-225°)'
        ELSE 'W (225-315°)'
    END as aspect_direction,
    CASE 
        WHEN p.SLOPE < 5 THEN 'Gentle (<5%)'
        WHEN p.SLOPE < 15 THEN 'Moderate (5-15%)'
        WHEN p.SLOPE < 30 THEN 'Steep (15-30%)'
        ELSE 'Very Steep (>30%)'
    END as slope_class,
    COUNT(t.TRE_CN) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_percentage
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
WHERE t.SPCD = 202
GROUP BY aspect_direction, slope_class
ORDER BY aspect_direction, slope_class;

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
