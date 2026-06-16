# Part III: Modeling a Data Platform as a Graph

## 3.1 Why this part comes first

The first real lesson is **semantic modeling**, not query tricks. LadybugDB's schema-first approach (typed node and relationship tables with required node primary keys) makes this a disciplined modeling exercise. The objective is to get the team to see a graph as a representation of connected metadata they already understand: systems, databases, tables, pipelines, jobs, dashboards, and owning teams.

## 3.2 The business scenario

The team owns a small internal data platform. Data lands from a **CRM** system and a **Billing** system, is loaded into **raw** warehouse tables, transformed into **curated** and then **mart** assets, and consumed by business **dashboards**. When a source changes or a pipeline fails, the team needs to know what is affected and who should respond.

## 3.3 Modeling principles

Establish these rules before showing any code:

- Every node represents a **stable** business or platform entity.
- Every node table has a stable **primary key**, which LadybugDB requires.
- Every relationship answers a **real question**.
- Do not add nodes or edges because they are graph-shaped. Add them because they improve reasoning.
- Keep the initial graph **small enough to inspect manually.**

## 3.4 The entities

**Node tables:**

| Node table | Meaning |
|---|---|
| `System` | External or internal platform systems: CRM, Billing, the warehouse, BI tools. |
| `Database` | Logical data stores or layers: raw, curated, mart. |
| `TableAsset` | A data asset at table grain (not a row-level entity). |
| `Pipeline` | A logical transformation or ingestion unit. |
| `Job` | A schedulable execution unit that runs a pipeline. |
| `Dashboard` | A downstream business-facing consumer. |
| `Team` | The owning or responsible team. |

**Relationship tables:**

| Relationship | Meaning |
|---|---|
| `HOSTS` | A system hosts a database. |
| `CONTAINS` | A database contains a table asset. |
| `READS_SYSTEM` | A pipeline reads from a source system. |
| `READS_TABLE` | A pipeline reads from an upstream table asset. |
| `WRITES_TO` | A pipeline writes to a table asset. |
| `RUNS` | A job runs a pipeline. |
| `POWERS` | A table asset powers a dashboard. |
| `OWNS_PIPELINE` | A team owns a pipeline. |
| `OWNS_DASHBOARD` | A team owns a dashboard. |

```{=latex}
\begin{figure}[ht]
\centering
\resizebox{0.92\textwidth}{!}{%
\begin{tikzpicture}
  \node[gbnode] (job)  at (0,0)     {Job};
  \node[gbnode] (pipe) at (3.4,0)   {Pipeline};
  \node[gbnode] (tbl)  at (7.0,0)   {TableAsset};
  \node[gbnode] (dash) at (10.6,0)  {Dashboard};
  \node[gbnode] (sys)  at (3.4,2.4) {System};
  \node[gbnode] (db)   at (7.0,2.4) {Database};
  \node[gbnode] (team) at (1.7,-2.4){Team};
  \draw[gbedge] (job)  -- node[gblabel]{RUNS} (pipe);
  \draw[gbedge] (pipe) to[bend left=14]  node[gblabel]{WRITES\_TO} (tbl);
  \draw[gbedge] (pipe) to[bend right=14] node[gblabel,below]{READS\_TABLE} (tbl);
  \draw[gbedge] (pipe) -- node[gblabel]{READS\_SYSTEM} (sys);
  \draw[gbedge] (sys)  -- node[gblabel]{HOSTS} (db);
  \draw[gbedge] (db)   -- node[gblabel,right]{CONTAINS} (tbl);
  \draw[gbedge] (tbl)  -- node[gblabel]{POWERS} (dash);
  \draw[gbedge] (team) -- node[gblabel,left]{OWNS\_PIPELINE} (pipe);
  \draw[gbedge] (team) to[bend right=24] node[gblabel,below]{OWNS\_DASHBOARD} (dash);
\end{tikzpicture}%
}
\caption{The platform metadata model: seven node types and the nine relationship types that connect them. Every query in the book traverses some path through this shape.}
\label{fig:schema}
\end{figure}
```

> **Two deliberate modeling choices: read these to the team.**
>
> **No `DEPENDS_ON` edge.** An obvious-looking addition would be a `Dashboard → TableAsset` "depends on" edge. We do not add it. `POWERS` already encodes the table-to-dashboard link, and Cypher traverses a relationship in *either* direction, so "what powers this dashboard?" and "what does this dashboard depend on?" are the same edge read two ways. A separate reverse edge is redundant state that has to be kept consistent.
>
> **Single-pair relationship tables.** LadybugDB supports *multi-pair* relationship tables: one table that connects several different `FROM`–`TO` node-table pairs (for example, a single `READS_FROM` covering both `Pipeline → TableAsset` and `Pipeline → System`). We deliberately use **single-pair** tables instead: `READS_TABLE` and `READS_SYSTEM`, `OWNS_PIPELINE` and `OWNS_DASHBOARD`. Each relationship type then has exactly one meaning and one unambiguous load path, which keeps the schema and the import script simple. Where a query genuinely does not care which it traverses, Cypher's `:READS_TABLE|READS_SYSTEM` syntax recombines them on demand. This is the kind of tradeoff worth discussing: the multi-pair feature is real and useful, but for a teaching model, clarity wins.

## 3.5 Creating the schema

Create the schema first. This reinforces a key LadybugDB idea: the graph is explicit and typed, not inferred at query time. Save this as `scripts/schema.cypher`.

Everything in this part assumes you are working in the **on-disk** database created in §2.4. Open it from your workspace root so the schema and the data you load next persist to `db/platform.lbug`:

```bash
lbug db/platform.lbug
```

> **Recap, and a reopen tip.** A LadybugDB database is just a path on disk. Because §2.4 opened it on-disk, everything you create here is written to `db/platform.lbug` when you exit, and is still there the next time you open it.
>
> - **Returning after a break, or in a fresh terminal?** From the workspace root, reopen the database before anything else: `lbug db/platform.lbug`. Then go straight to your queries.
> - **Schema and load are one-time steps.** On a return visit, do *not* re-run `schema.cypher` or `load.cypher` — the graph is already persisted, and re-running them would error or duplicate data.
> - **`lbug` with no path is a trap.** Omitting the path opens a throwaway *in-memory* database (§2.4), so your tables appear to be missing. If a query unexpectedly returns nothing, check that you actually opened `db/platform.lbug`.
> - **One writer at a time.** The database is embedded, so close any other session — including Ladybug Explorer (Part VII) — that has it open.

```cypher
CREATE NODE TABLE System(
  id STRING, name STRING, kind STRING,
  PRIMARY KEY (id)
);

CREATE NODE TABLE Database(
  id STRING, name STRING, layer STRING,
  PRIMARY KEY (id)
);

CREATE NODE TABLE TableAsset(
  id STRING, name STRING, layer STRING, domain STRING,
  PRIMARY KEY (id)
);

CREATE NODE TABLE Pipeline(
  id STRING, name STRING, mode STRING, schedule STRING,
  PRIMARY KEY (id)
);

CREATE NODE TABLE Job(
  id STRING, name STRING, engine STRING,
  PRIMARY KEY (id)
);

CREATE NODE TABLE Dashboard(
  id STRING, name STRING, tool STRING,
  PRIMARY KEY (id)
);

CREATE NODE TABLE Team(
  id STRING, name STRING, function STRING,
  PRIMARY KEY (id)
);

CREATE REL TABLE HOSTS(FROM System TO Database);
CREATE REL TABLE CONTAINS(FROM Database TO TableAsset);
CREATE REL TABLE READS_SYSTEM(FROM Pipeline TO System);
CREATE REL TABLE READS_TABLE(FROM Pipeline TO TableAsset);
CREATE REL TABLE WRITES_TO(FROM Pipeline TO TableAsset);
CREATE REL TABLE RUNS(FROM Job TO Pipeline);
CREATE REL TABLE POWERS(FROM TableAsset TO Dashboard);
CREATE REL TABLE OWNS_PIPELINE(FROM Team TO Pipeline);
CREATE REL TABLE OWNS_DASHBOARD(FROM Team TO Dashboard);
```

## 3.6 The import workflow

LadybugDB bulk-loads CSV files with `COPY FROM`. Two rules from the documentation matter here:

1. **Copy nodes before relationships.** A relationship can only be created if both of its endpoint nodes already exist.
2. **For relationship CSVs, the first two columns are the `FROM` primary key and the `TO` primary key.** Remaining columns are relationship properties.

There is one subtlety worth teaching explicitly. Every column in this dataset is a `STRING`, and our CSV headers (`id,name,kind`, `from,to`, …) are themselves valid strings. LadybugDB's header auto-detection works by checking whether the first line *fails* to cast to the column types, but a string header never fails that test. So we **specify `(header=true)` on every `COPY` statement** rather than relying on auto-detection. Getting this wrong silently loads your header row as data.

Save this as `scripts/load.cypher`:

```cypher
COPY System     FROM "data/systems.csv"      (header=true);
COPY Database   FROM "data/databases.csv"    (header=true);
COPY TableAsset FROM "data/table_assets.csv" (header=true);
COPY Pipeline   FROM "data/pipelines.csv"    (header=true);
COPY Job        FROM "data/jobs.csv"         (header=true);
COPY Dashboard  FROM "data/dashboards.csv"   (header=true);
COPY Team       FROM "data/teams.csv"        (header=true);

COPY HOSTS          FROM "data/hosts.csv"          (header=true);
COPY CONTAINS       FROM "data/contains.csv"       (header=true);
COPY READS_SYSTEM   FROM "data/reads_system.csv"   (header=true);
COPY READS_TABLE    FROM "data/reads_table.csv"    (header=true);
COPY WRITES_TO      FROM "data/writes_to.csv"      (header=true);
COPY RUNS           FROM "data/runs.csv"           (header=true);
COPY POWERS         FROM "data/powers.csv"         (header=true);
COPY OWNS_PIPELINE  FROM "data/owns_pipeline.csv"  (header=true);
COPY OWNS_DASHBOARD FROM "data/owns_dashboard.csv" (header=true);
```

To run a script file from the shell, open the database and execute the statements: paste them in, or use your shell's script-execution command (`:help` lists it). Run `schema.cypher` first, then `load.cypher`.

## 3.7 First queries

Start with direct questions that validate the model and connect back to what the team already knows.

```cypher
// Which databases does the warehouse host?
MATCH (s:System {name: 'Snowflake'})-[:HOSTS]->(d:Database)
RETURN d.name AS database, d.layer AS layer
ORDER BY d.name;
```

**Expected result.**

| database | layer |
|---|---|
| `curated_db` | `curated` |
| `mart_db` | `mart` |
| `raw_db` | `raw` |

```cypher
// Which assets live in the raw layer?
MATCH (:Database {name: 'raw_db'})-[:CONTAINS]->(t:TableAsset)
RETURN t.name AS table_asset, t.domain AS domain
ORDER BY t.name;
```

**Expected result.**

| table_asset | domain |
|---|---|
| `customers_raw` | `customer` |
| `orders_raw` | `order` |
| `payments_raw` | `payment` |

```cypher
// Which pipeline writes which table?
MATCH (p:Pipeline)-[:WRITES_TO]->(t:TableAsset)
RETURN p.name AS pipeline, t.name AS writes_table
ORDER BY p.name, t.name;
```

**Expected result.**

| pipeline | writes_table |
|---|---|
| `build_customer_360` | `customer_360` |
| `build_revenue_daily` | `revenue_daily` |
| `curate_customers` | `customers_curated` |
| `curate_orders` | `orders_curated` |
| `curate_payments` | `payments_curated` |
| `ingest_billing` | `payments_raw` |
| `ingest_crm` | `customers_raw` |
| `ingest_crm` | `orders_raw` |

## 3.8 Validation checklist

End Part III with hard checks, not vague confidence:

- [ ] Every node table can be counted, and counts match the CSVs, e.g. `MATCH (s:System) RETURN count(s);`
- [ ] The database layers contain the expected assets.
- [ ] Every pipeline has at least one input and one output edge.
- [ ] Each dashboard has an explicit upstream path.

**Discussion prompts.** What is the *grain* of each node table? Which edges are essential and which are optional? What part of this model would be awkward to express in a purely tabular mental model?
