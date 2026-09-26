"""
Load the case CSV files into a raw schema in the DuckDB database.
"""

from pathlib import Path

import duckdb

REPO_ROOT = Path(__file__).resolve().parent.parent
DATABASE = REPO_ROOT / "telia" / "dev.duckdb"

TABLES = [
    "customers",
    "product_events",
    "campaign_interactions",
    "consent_registry",
    "consent_purpose_code",
]


def load_table(connection, table):
    """Replace raw.<table> with the contents of data/<table>.csv."""
    csv_file = REPO_ROOT / "data" / f"{table}.csv"
    connection.execute(
        f"""
        create or replace table raw.{table} as
        select * from read_csv(?, header = true, all_varchar = true)
        """,
        [str(csv_file)],
    )
    row_count, _ = connection.table(f"raw.{table}").shape
    return row_count


def main():
    with duckdb.connect(str(DATABASE)) as connection:
        connection.execute("create schema if not exists raw")

        for table in TABLES:
            row_count = load_table(connection, table)
            print(f"loaded raw.{table:<24} {row_count:>7,} rows")

    print(f"\ndatabase: {DATABASE}")


if __name__ == "__main__":
    main()
