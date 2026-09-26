The project uses DuckDB and dbt to create the models.

## Setup

Please create a Python virtual environment and install the requirements. With `uv`, this can be done with the following:

```bash
uv venv .venv --python==3.12
source .venv/bin/activate
uv pip install -r requirements.txt
```

The models can be loaded with the following:

```bash
python scripts/load_raw.py
```

## Overview of tasks

### 1

The project uses DuckDB and the data can be loaded with the following command:

```bash
python scripts/load_raw.py
```

The loading uses raw text so that no data is lost or changed when loading it. The processing happens in the next staging step with dbt.

### 2 Staging and aggregations

#### 2.1 Staging

The staging step mainly converts dates to a proper date format and does small processing like making email lowercase and removing whitespaces in phone numbers. A comprehensive processing would validate phone numbers with more detail. Currently some fields has two phone numbers.

This can be run with the following command:

```bash
cd telia
dbt build
```

The staging step only contains views, so nothing will be saved from this step alone.

#### 2.2 Aggregations

The output table can be viewed with the following command, after running `dbt build`:

```bash
dbt show --select int_customer_metrics --limit 10
```

### 3 Audience Segment Definitions

Two of the segments had zero customers and one of them had one.

To see the result, please run:

```bash
dbt show --limit 10 --inline "select segment_name, count(*) as customers
                     from {{ ref('mart_audience_segments') }}
                     group by 1 order by 2 desc"
```

### 4 Tests

The schemas can be found inside the respective directories inside the `models` directory.

The schemas include automated tests based on the types and expected contents in the tables.

The custom test is inside the `tests` directory. It tests if the marketing customers has given a marketing consent.

The tests can be run with `dbt test`. To run the custom test specifically, please run `dbt test --select assert_segments_require_marketing_consent`.
