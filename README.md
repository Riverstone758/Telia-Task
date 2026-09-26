# Data owner and engineer - CRM and Marketing

The project uses DuckDB and dbt to create the models. DuckDB was chosen as it is designed for large operations including many rows and few columns. It is also embedded with no access control, which is simple for this task. A realistic scenario would probably have a remote database that this application, among others, read from.

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

All of the `dbt` commands should be run inside the `telia` directory.

## Overview of tasks

### 1 Project setup

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

Some assumptions of the data can be found in the "Assumptions" section below.

One can also run `dbt docs generate && dbt docs serve` to get a web UI of the models and data.

### 5 Version control

This is a git repository in a public Github repository.

### 6 Presentation

Here are some notes on the last two points:

- **Limitations**: A lot more care could be done with respect to the processing and the formatting of the final reports. DuckDB is used, which is very convenient for this project, but does not scale to large and shared databases. All the code has been run locally, it is not scheduled to run on given intervals. It is also not integrated in any systems. A lot more care could have gone into exploring the data and understanding the requirements for data quality.

- **Production ready version**: A production ready version would be deployed in a managed environment instead of being run locally. It would probably be integrated in a shared database with access control. The resources used to run the models should be scaled to suit the needs and scheduled to run at suitable intervals. Tests could be run automatically and have requirements for data quality.

## Assumptions

The events in the data ended in July 2025, so "the last n days" are interpreted as being reletive to this as the last date. This is set in the variable `as_of_date`.

Ideally the phone numbers and emails should have been properly validated, as the format in the data is inconsistent. However, this requires decisions with respect to which formats to accept, so further processing was not done.

The campaign ordering of events mentioned in the task seem to be different from the data. It says that one send produces three rows, one for sent, delivered and opened. However, it seems like multiple deliveries has no send and some are only open.
