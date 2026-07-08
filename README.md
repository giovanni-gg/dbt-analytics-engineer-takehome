# Danish Endurance — Analytics Engineering Take-Home (dbt)

Welcome, and thanks for taking the time. This exercise mirrors a slice of real work
on our data team: turning messy raw Amazon data into clean, tested, documented models
with **dbt**.

We care far more about **how you model, test, and document** than about how many
models you produce. Clear thinking beats volume.

---

## About the data

You've been given five raw CSV extracts as dbt **seeds** (in `seeds/`). They cover
Amazon **orders** and Amazon **ad spend** across two marketplaces (UK and Germany),
plus a product master file:

| Seed | Grain | Columns |
|------|-------|---------|
| `product_master_file` | one row per product | `child_asin`, `product_name`, `product_marketing_category` |
| `amazon_orders_uk` | one row per UK order line | `order_id`, `order_time`, `market`, `child_asin`, `sales_amount` |
| `amazon_orders_de` | one row per DE order line | *(same shape as UK)* |
| `amazon_ads_uk` | one row per ad | `ad_id`, `ad_date`, `market`, `child_asin`, `ad_cost` |
| `amazon_ads_de` | one row per ad | *(same shape as UK)* |

---

## Setup (should take ~5 minutes)

You need **Python 3.9+** and **git**.

```bash
# 0. clone the project and move into its folder
git clone <repo-url>
cd dbt-analytics-engineer-takehome

# 1. create a virtual environment
python -m venv .venv

# 2. ACTIVATE it -- use the line for YOUR shell:
#    Windows PowerShell:      .\.venv\Scripts\Activate.ps1
#    Windows Command Prompt:  .venv\Scripts\activate.bat
#    macOS / Linux:           source .venv/bin/activate
#    (after this, your prompt should start with "(.venv)")

# 3. install dbt + the DuckDB adapter
pip install -r requirements.txt

# 4. load seeds, build models, and run tests -- all at once
dbt build --profiles-dir .
#    (or individually: dbt seed / dbt run / dbt test, each with --profiles-dir .)
```

DuckDB is a local embedded database — **no server, no cloud account, no credentials
required.** A `dev.duckdb` file will be created in the project folder.

> **Windows PowerShell note:** if `Activate.ps1` is blocked by an execution-policy
> error, run `Set-ExecutionPolicy -Scope Process RemoteSigned` once in the same window,
> then activate again. Or skip activation entirely and call the venv's dbt directly:
> `.\.venv\Scripts\dbt.exe build --profiles-dir .`
>
> **Tip:** `--profiles-dir .` tells dbt to use the `profiles.yml` included in this repo,
> so you don't have to touch `~/.dbt`.

---

## Inspecting your data (optional)

After a build, everything lives in the local `dev.duckdb` file. A few ways to look at it:

- **Quick peek, no extra tools:** `dbt show --select amazon_orders_uk --profiles-dir .`
  prints a model's (or seed's) first rows straight to the terminal.
- **DuckDB's built-in browser UI:** with the venv active, start an interactive Python
  session (`python`) and run:

  ```python
  import duckdb
  duckdb.connect("dev.duckdb").sql("CALL start_ui()")
  ```

  A local UI opens at **http://localhost:4213** with `dev.duckdb` attached — browse
  tables, run SQL, and view results in a grid. Keep the Python session open while you
  use it (closing it stops the server). The first launch downloads the `ui` extension,
  so you need internet once.

> **Heads-up:** DuckDB lets only one process hold the database file at a time, so
> **stop the UI before you run `dbt build` again** (and vice-versa), or you'll hit a
> lock error.

---

## Your task

Build a dbt project on top of the seeds using a **staging → core → marts** structure.
**How you build the staging and core layers is entirely up to you** — model and clean
the data however you think makes sense.

The required deliverable is **three mart models**, each at **product category × day**
granularity:

1. **Sales** — sales by product category and day.
2. **Ad spend** — ad spend by product category and day.
3. **Sales & ad spend combined** — both sales and ad spend together, by product category
   and day.

We'll evaluate the choices you make along the way — grain, naming, how you structure the
layers, and how you handle any data-quality issues you run into.

### Tests & documentation
Add tests where they add value — both:
- **generic tests** (`unique`, `not_null`, `relationships`, `accepted_values`), and
- at least one **business-logic test** (a `.sql` "singular" test in `tests/` that asserts
  something which should always be true of your data). This obviously isn't production
  data, so there's no single right answer — just pick a business rule you'd imagine is
  relevant and test for it.

Document your models and key columns in `schema.yml` files.

---

## What to submit

**Push your work to this repository** (a branch is perfect), containing:

- Your **staging, core, and mart models** — all three layers.
- The **three marts** described above.
- **Tests** — generic tests plus at least one business-logic test.
- `schema.yml` documentation for your models.
- An **`ANSWERS.md`** with a few sentences on: the data-quality issues you found, the
  modelling and join choices you made (and why), and what you'd do next with more time.

---

## Present your work

Be ready to **present what you did and walk us through the repo**. We'd mainly like to
hear your **approach** — how you structured the project, the modelling and data-quality
decisions you made and why, and how you'd think about running something like this in
production.

Do it however works best for you: prepare a few slides, or just walk us through the code
live — whatever lets you tell the story best.

Good luck — have fun with it.
