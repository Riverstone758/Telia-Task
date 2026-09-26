# Telia Data Owner and Engineer Task

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

### 2

#### 2.1

The staging step mainly converts dates to a proper date format and does small processing like making email lowercase and removing whitespaces in phone numbers. A comprehensive processing would validate phone numbers with more detail. Currently some fields has two phone numbers.

#### 2.2

### 3
