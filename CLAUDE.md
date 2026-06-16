# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

This is a **book**, not an application: *"Graph for the Data You Already Own"* — a short enablement guide for data engineering teams on lineage, blast radius, and graph modeling using **LadybugDB** (an embedded, MIT-licensed property-graph database built on the Kùzu engine). The deliverable is prose; the code and data are a companion tutorial dataset the reader builds alongside the text.

There is no application to build, no test suite, and no git repository here. "Working in this repo" means editing book content and keeping the runnable companion artifacts consistent with what the prose claims.

## Repository layout

- `chapters/` — all book markdown: `00-preface.md`, `01-part-i.md` … `07-part-vii.md`, `08-beyond-ladybugdb.md`, the appendices `app-a.md`..`app-d.md`, then `references.md`, in reading order. `chapters/readme.md` and `chapters/toc.md` are front matter (excluded from the build). The Makefile builds from `chapters/` (see its `NAMES` list). `README.md`, `CLAUDE.md`, and `LICENSE` stay at the repo root.
- `data/` — the Appendix A tutorial dataset: node CSVs (`systems`, `databases`, `table_assets`, `pipelines`, `jobs`, `dashboards`, `teams`) and relationship CSVs (`hosts`, `contains`, `reads_system`, `reads_table`, `writes_to`, `runs`, `powers`, `owns_pipeline`, `owns_dashboard`).
- `scripts/schema.cypher` — `CREATE NODE/REL TABLE` definitions.
- `scripts/load.cypher` — `COPY ... FROM` bulk-load statements.
- `scripts/generate_synthetic.py` — Appendix D's SDV-based dataset scaler.
- `scripts/queries-part-{iii,iv,v,vi,vii}.cypher` — the example queries from each part, extracted runnable (one file per part).
- `db/` — where the built database (`db/platform.lbug`) lives. Empty until the reader builds it; the actual binary is not committed.

> **LadybugDB Cypher uses `//` (and `/* */`) for comments, not SQL-style `--`.** A `--` comment is a parser error. Use `//` in every `.cypher` file and in the book's Cypher code blocks.

## The one thing that matters most: prose and code must stay in sync

The scripts and dataset are **reproduced verbatim inside the book**, and the chapters narrate exactly what the data contains. A change in one place is a bug unless mirrored everywhere:

- `scripts/schema.cypher` is quoted in full in `chapters/03-part-iii.md` §3.5. Edit both.
- `scripts/load.cypher` is quoted in full in `chapters/03-part-iii.md` §3.6. Edit both.
- `scripts/generate_synthetic.py` is quoted in full in `chapters/app-d.md`. Edit both.
- The `explorer.sh` launch script is quoted in `chapters/07-part-vii.md` §7.5 (it is not checked in here — it's a script the reader creates).
- The `scripts/queries-part-*.cypher` files mirror the example queries in Parts III–VII. If you change a query in the prose, update the matching script file (and vice versa).
- Node/edge **counts, names, and example query results** stated in Parts III–V (and `chapters/app-a.md`, the full dataset listing) are derived from `data/`. If you change a CSV, re-verify every count, every named entity (e.g. `Snowflake`, `orders_raw`, `Billing`, `dash_sales`), and every sample query output the prose asserts.
- Schema, load, and generator share the same node/relationship vocabulary. The generator's referential-integrity check (`all_edges` map) and the schema's `FROM`/`TO` declarations must agree.

When in doubt, treat the prose as the spec and the files as its tested implementation — keep them identical.

## Modeling conventions (deliberate, documented in §3.4)

These are intentional teaching choices, not oversights — preserve them:

- **Single-pair relationship tables** (`READS_TABLE` + `READS_SYSTEM`, `OWNS_PIPELINE` + `OWNS_DASHBOARD`) rather than LadybugDB multi-pair tables, so each edge type has one unambiguous meaning and load path.
- **No reverse/`DEPENDS_ON` edges.** Cypher traverses an edge in either direction, so reverse edges are redundant state.
- All CSV columns are `STRING`; relationship CSVs use `from,to` as the first two columns (the `FROM`/`TO` primary keys), remaining columns are edge properties.

## Common tasks

Build the tutorial database from scratch (run from repo root):

```bash
lbug db/platform.lbug   # opens/creates the on-disk database, then paste or run:
                        #   schema.cypher first, then load.cypher
```

`COPY` requires `(header=true)` on every statement — header auto-detection fails for this all-`STRING` dataset and would silently load the header row as data (see §3.6).

Generate a larger synthetic dataset (Appendix D):

```bash
pip install sdv pandas numpy
python scripts/generate_synthetic.py     # writes data_synth/ from the data/ seed
```

It is **additive** (every seed node is kept verbatim) and prints a node/edge summary plus a referential-integrity result. Tune scale with the config block at the top (`N_TABLE_ASSETS`, `N_DASHBOARDS`, `RANDOM_SEED`). To load it, run `schema.cypher` against a fresh DB, then a copy of `load.cypher` repointed at `data_synth/`.

Visualize the graph (Part VII) — requires Docker or Podman:

```bash
./scripts/explorer.sh                     # read-only by default, http://localhost:8000
MODE=READ_WRITE ./scripts/explorer.sh     # allow writes from Explorer
```

LadybugDB is embedded and single-writer: close any CLI session holding `platform.lbug` before opening it in Explorer.

## Verifying changes

There is no automated test harness. To verify edits actually work, run the full path a reader would: load the schema and data into a fresh `db/platform.lbug`, then run the named queries from Parts III–V and confirm their results match what the prose states. For dataset changes, also run `generate_synthetic.py` and confirm it reports `Referential integrity: OK`.
