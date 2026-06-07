# Custom SQL Queries

This directory contains SQL query templates for custom FIA data analysis.

## Using These Queries

You can execute any query in this directory using the `FIADatabaseConnector`:

```python
from src.fia_database import FIADatabaseConnector

connector = FIADatabaseConnector()
connector.connect()

# Read query from file
with open('queries/your_query.sql', 'r') as f:
    query = f.read()

# Execute the query
results = connector.execute_query(query)
print(results)

connector.disconnect()
```

## Query Files

- `template.sql` - Template for creating custom queries

## FIA Field References

### TREE Table
- `TRE_CN`: Tree identification code (primary key)
- `PLT_CN`: Plot identification code (foreign key)
- `SPCD`: Species code (202 = Douglas-fir)
- `STATUSCD`: Tree status (1 = Live, 2 = Dead, 3 = Harvested, etc.)
- `DIA`: Diameter at breast height (DBH) in inches
- `HT`: Height in feet
- `AGEGRP`: Age group
- `TOTAGE`: Total age in years

### PLOT Table
- `PLT_CN`: Plot identification code (primary key)
- `SURVEYCD`: Survey code (foreign key)
- `COUNTYCD`: County code (foreign key)
- `ELEV`: Elevation in feet
- `ASPECT`: Aspect (0-360 degrees)
- `SLOPE`: Slope percent
- `LON_PUBLIC`: Longitude (public)
- `LAT_PUBLIC`: Latitude (public)

### SURVEY Table
- `SURVEYCD`: Survey code (primary key)
- `INVYR`: Inventory year
- `STATECD`: State code

### COUNTY Table
- `COUNTYCD`: County code (primary key)
- `COUNTYNM`: County name
- `STATECD`: State code
- `STABBR`: State abbreviation

## Common Queries

### Count trees by species
```sql
SELECT 
    SPCD,
    COUNT(*) as tree_count
FROM TREE
GROUP BY SPCD
ORDER BY tree_count DESC;
```

### Find Douglas-fir mortality by county
```sql
SELECT 
    c.COUNTYNM,
    COUNT(*) as total_trees,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_pct
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
JOIN COUNTY c ON p.COUNTYCD = c.COUNTYCD
WHERE t.SPCD = 202
GROUP BY c.COUNTYNM
ORDER BY mortality_pct DESC;
```

### Analyze by elevation
```sql
SELECT 
    CASE 
        WHEN p.ELEV < 1000 THEN 'Low (<1000 ft)'
        WHEN p.ELEV < 3000 THEN 'Medium (1000-3000 ft)'
        WHEN p.ELEV < 5000 THEN 'High (3000-5000 ft)'
        ELSE 'Very High (>5000 ft)'
    END as elevation_class,
    COUNT(*) as tree_count,
    SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
    ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_pct
FROM TREE t
JOIN PLOT p ON t.PLT_CN = p.PLT_CN
WHERE t.SPCD = 202
GROUP BY elevation_class
ORDER BY tree_count DESC;
```
