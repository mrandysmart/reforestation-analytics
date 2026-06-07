import sqlite3
import pandas as pd
from pathlib import Path
from typing import Optional, List, Dict
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class FIADatabaseConnector:
    """
    Connect to and query FIA SQLite database for forest analysis.
    """

    def __init__(self, db_path: str):
        """
        Initialize database connection.

        Args:
            db_path: Path to the FIA SQLite database file
        """
        self.db_path = Path(db_path)
        self.connection = None
        self.cursor = None

        if not self.db_path.exists():
            raise FileNotFoundError(f"Database file not found: {db_path}")

    def connect(self) -> None:
        """Establish connection to SQLite database."""
        try:
            self.connection = sqlite3.connect(str(self.db_path))
            self.cursor = self.connection.cursor()
            logger.info(f"Connected to database: {self.db_path}")
        except sqlite3.Error as e:
            logger.error(f"Database connection error: {e}")
            raise

    def disconnect(self) -> None:
        """Close database connection."""
        if self.connection:
            self.connection.close()
            logger.info("Database connection closed")

    def get_tables(self) -> List[str]:
        """
        Retrieve list of all tables in the database.

        Returns:
            List of table names
        """
        try:
            self.cursor.execute(
                "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
            )
            tables = [row[0] for row in self.cursor.fetchall()]
            logger.info(f"Found {len(tables)} tables in database")
            return tables
        except sqlite3.Error as e:
            logger.error(f"Error retrieving tables: {e}")
            return []

    def get_table_schema(self, table_name: str) -> List[Dict]:
        """
        Get schema information for a specific table.

        Args:
            table_name: Name of the table

        Returns:
            List of column information dictionaries
        """
        try:
            self.cursor.execute(f"PRAGMA table_info({table_name})")
            columns = self.cursor.fetchall()
            schema = [
                {
                    "column": col[1],
                    "type": col[2],
                    "not_null": bool(col[3]),
                    "default": col[4],
                    "primary_key": bool(col[5]),
                }
                for col in columns
            ]
            return schema
        except sqlite3.Error as e:
            logger.error(f"Error retrieving schema for {table_name}: {e}")
            return []

    def execute_query(self, query: str) -> pd.DataFrame:
        """
        Execute a SQL query and return results as DataFrame.

        Args:
            query: SQL query string

        Returns:
            pandas DataFrame with query results
        """
        try:
            df = pd.read_sql_query(query, self.connection)
            logger.info(f"Query executed successfully, returned {len(df)} rows")
            return df
        except sqlite3.Error as e:
            logger.error(f"Query execution error: {e}")
            return pd.DataFrame()

    def count_douglas_fir(self) -> Dict:
        """
        Count Douglas-fir records and mortality statistics.

        Returns:
            Dictionary with statistics
        """
        query = """
        SELECT 
            COUNT(*) as total_trees,
            SUM(CASE WHEN STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
            SUM(CASE WHEN STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
            ROUND(100.0 * SUM(CASE WHEN STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_rate_pct
        FROM TREE
        WHERE SPCD = 202
        """
        df = self.execute_query(query)
        if not df.empty:
            return df.iloc[0].to_dict()
        return {}

    def get_mortality_by_county(self) -> pd.DataFrame:
        """
        Get Douglas-fir mortality summary by county.

        Returns:
            pandas DataFrame with county-level statistics
        """
        query = """
        SELECT 
            c.COUNTYCD as county_code,
            c.COUNTY as county_name,
            c.STABBR as state,
            COUNT(t.TRE_CN) as total_trees,
            SUM(CASE WHEN t.STATUSCD = 1 THEN 1 ELSE 0 END) as live_trees,
            SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
            ROUND(100.0 * SUM(CASE WHEN t.STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(t.TRE_CN), 2) as mortality_rate_pct,
            ROUND(AVG(t.DIA), 2) as avg_diameter,
            ROUND(AVG(t.HT), 2) as avg_height
        FROM TREE t
        JOIN PLOT p ON t.PLT_CN = p.PLT_CN
        JOIN COUNTY c ON p.COUNTYCD = c.COUNTYCD
        WHERE t.SPCD = 202
        GROUP BY c.COUNTYCD, c.COUNTY, c.STABBR
        ORDER BY mortality_rate_pct DESC, total_trees DESC
        """
        return self.execute_query(query)

    def get_mortality_by_diameter_class(self) -> pd.DataFrame:
        """
        Get Douglas-fir mortality by diameter class.

        Returns:
            pandas DataFrame with diameter class analysis
        """
        query = """
        SELECT 
            CASE 
                WHEN DIA < 5 THEN 'Seedling (<5")'
                WHEN DIA < 10 THEN 'Small (5-10")'
                WHEN DIA < 20 THEN 'Medium (10-20")'
                WHEN DIA >= 20 THEN 'Large (>20")'
            END as diameter_class,
            COUNT(*) as tree_count,
            SUM(CASE WHEN STATUSCD = 2 THEN 1 ELSE 0 END) as dead_trees,
            ROUND(100.0 * SUM(CASE WHEN STATUSCD = 2 THEN 1 ELSE 0 END) / COUNT(*), 2) as mortality_rate_pct,
            ROUND(AVG(DIA), 2) as avg_diameter,
            ROUND(AVG(HT), 2) as avg_height
        FROM TREE
        WHERE SPCD = 202
        GROUP BY diameter_class
        ORDER BY 
            CASE 
                WHEN diameter_class = 'Seedling (<5")' THEN 1
                WHEN diameter_class = 'Small (5-10")' THEN 2
                WHEN diameter_class = 'Medium (10-20")' THEN 3
                WHEN diameter_class = 'Large (>20")' THEN 4
            END
        """
        return self.execute_query(query)

    def explore_schema(self) -> None:
        """Print database schema information."""
        tables = self.get_tables()
        print(f"\n{'='*60}")
        print(f"Database Schema: {self.db_path.name}")
        print(f"{'='*60}")

        for table_name in tables:
            schema = self.get_table_schema(table_name)
            print(f"\nTable: {table_name}")
            print(f"  Columns: {len(schema)}")
            for col in schema:
                pk_indicator = " [PRIMARY KEY]" if col["primary_key"] else ""
                nn_indicator = " [NOT NULL]" if col["not_null"] else ""
                print(f"    - {col['column']}: {col['type']}{pk_indicator}{nn_indicator}")


def main():
    """Example usage of FIA database connector."""
    # Replace with your database path
    db_path = "path/to/your/FIA_database.db"

    try:
        # Initialize connector
        connector = FIADatabaseConnector(db_path)
        connector.connect()

        # Explore database schema
        connector.explore_schema()

        # Get Douglas-fir statistics
        print(f"\n{'='*60}")
        print("Douglas-fir Statistics")
        print(f"{'='*60}")
        stats = connector.count_douglas_fir()
        for key, value in stats.items():
            print(f"{key}: {value}")

        # Get county-level mortality
        print(f"\n{'='*60}")
        print("Mortality by County (Top 10)")
        print(f"{'='*60}")
        county_df = connector.get_mortality_by_county()
        print(county_df.head(10).to_string(index=False))

        # Get diameter class analysis
        print(f"\n{'='*60}")
        print("Mortality by Diameter Class")
        print(f"{'='*60}")
        diameter_df = connector.get_mortality_by_diameter_class()
        print(diameter_df.to_string(index=False))

        # Export results to CSV
        county_df.to_csv("douglas_fir_mortality_by_county.csv", index=False)
        diameter_df.to_csv("douglas_fir_mortality_by_diameter.csv", index=False)
        logger.info("Results exported to CSV files")

        connector.disconnect()

    except Exception as e:
        logger.error(f"Error: {e}")
        raise


if __name__ == "__main__":
    main()
