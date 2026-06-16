# Graph for the Data You Already Own

*A short book on Graph Data for Working Data Engineers, with LadybugDB.*

This repository holds the full source of the book, plus the Cypher queries, the
dataset, and the Python code it uses. You can read the rendered PDF on its own,
or clone the repo and work through the hands-on parts against a real database.

## What the book is about

One claim runs through every chapter:

> Graph is not a better database. It is a better *representation* for one class
> of question: multi-hop dependency and impact.

The book teaches that judgment alongside the mechanics, using a team's own
platform metadata (systems, pipelines, tables, dashboards, owning teams) rather
than an unrelated toy domain. It walks from the business case, through modeling
a data platform as a graph, to tracing lineage and quantifying the blast radius
of an incident, and finishes by naming the formal vocabulary and showing how the
skills carry over to other graph databases such as Neo4j.

It is written for two audiences: data leaders and executives (Part I), and the
data engineering team (all parts, ideally as a facilitated program). Total
hands-on time is roughly four to five hours.

The technology is [LadybugDB](https://docs.ladybugdb.com/), an open-source,
embedded property-graph database built on the Kùzu engine. It needs no server,
runs locally, and loads from CSV.

## Repository layout

| Path | What it holds |
|---|---|
| `chapters/` | All book markdown, in reading order (`00-preface` … `08-beyond-ladybugdb`, `app-a`..`app-d`, `references`). `readme.md` and `toc.md` are front matter, excluded from the build. |
| `data/` | The Appendix A tutorial dataset (node and relationship CSVs). `data/synthdata/` holds generated synthetic data when present. |
| `scripts/` | `schema.cypher`, `load.cypher`, the per-part example queries `queries-part-*.cypher`, and `generate_synthetic.py` (Appendix D's data scaler). |
| `assets/` | Front and back cover images. |
| `metadata.yaml`, `preamble.tex`, `cover-front.tex`, `syntax/cypher.xml` | Build configuration: Pandoc metadata, the LaTeX preamble, the cover page, and a Cypher syntax definition for highlighting. |
| `Makefile` | The book build (Pandoc to LaTeX to Tectonic). |
| `pyproject.toml`, `uv.lock` | The Python environment for `generate_synthetic.py` (managed with uv). |
| `LICENSE` | License terms (see below). |

## Building the PDF

You need [Pandoc](https://pandoc.org/) and [Tectonic](https://tectonic-typesetting.github.io/).
Tectonic fetches every LaTeX package and font it needs on first run (IBM Plex
Mono for code, TeX Gyre Pagella for the body text), so no system fonts are
required.

```bash
make pdf      # writes build/book.pdf
make tex      # stop at build/book.tex (to inspect the LaTeX)
make clean    # remove build/
```

## Working through the dataset

Install the LadybugDB CLI (`lbug`), then build the tutorial database and run the
queries:

```bash
# build the database (run schema first, then load)
lbug db/platform.lbug    # then run scripts/schema.cypher, then scripts/load.cypher

# run a part's example queries (read-only)
lbug -r db/platform.lbug < scripts/queries-part-v.cypher
```

Note: LadybugDB Cypher uses `//` (and `/* */`) for comments, not SQL-style `--`.

## Generating more data (Appendix D)

The synthetic-data generator uses SDV. With [uv](https://docs.astral.sh/uv/):

```bash
uv sync
uv run python scripts/generate_synthetic.py
```

It writes an expanded, referentially valid dataset that loads the same way as
the tutorial data.

## Author

Jaganadh Gopinadhan (Jagan), <jgopinadhan@acm.org>.

This book was prepared with assistance from generative AI tools for
brainstorming and planning, language and copy editing, and LaTeX typesetting and
build automation. The technical substance was directed and verified by the
author against the LadybugDB documentation and a working database.

## License

Dual-licensed: the text and figures under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/), and the source
code (Cypher, shell, and Python) under the MIT License. See
[`LICENSE`](LICENSE) for the full terms.
