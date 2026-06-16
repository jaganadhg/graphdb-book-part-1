# Part VII: Seeing the Graph with LadybugDB Explorer

## 7.1 Why see the graph

Every query in this book so far has answered in a table. The CLI shell returns rows, and rows are the right output for a count or a list of dashboard names. But there is a class of understanding that a table actively works against. When the Part IV lineage query returned three dashboards, it told you the *answer*: it did not let you *see the shape* of the dependency that produced it. The medallion structure (raw feeding curated feeding mart, branching out to consumers) is a picture, and a list of rows is the one format guaranteed to hide a picture.

This part introduces **LadybugDB Explorer**, a browser-based tool that runs the same Cypher you already know and renders the result as an actual graph: nodes as circles, edges as arrows, the platform's structure visible at a glance. It is the tool to reach for when you are debugging a model, onboarding someone to the platform's shape, or walking a stakeholder through a blast radius, anywhere the *topology* is the point.

## 7.2 What Explorer is, and the one prerequisite

Ladybug Explorer is a small web application. It connects to a LadybugDB database, gives you a query panel and a schema panel, and renders query results three ways: as a graph, as a table, or as raw JSON.

There is one thing to know up front, stated plainly because it drives the rest of this part: **Explorer is distributed only as a container image.** It is not a `pip install` or a downloadable binary. To run it you need a container engine: either **Docker** or **Podman**. The two are nearly interchangeable for our purposes; §7.3 covers Docker, §7.4 covers the Podman differences, and §7.5 gives one script that handles either. If your environment forbids containers entirely, §7.7 gives an honest container-free alternative for visualization.

The image lives at `ghcr.io/ladybugdb/explorer:latest`. The `latest` tag tracks the stable LadybugDB release (which is what this book uses) so `latest` is correct here. There is also a `:dev` tag, but it exists only to match LadybugDB *nightly* builds; using it against a stable database produces a storage-format error. Stick with `latest`.

## 7.3 Launching Explorer against your data: Docker

The goal is to point Explorer at the `db/platform.lbug` database you built in Part III. Explorer expects the database *directory* mounted at `/database` inside the container, with an environment variable naming the file within it.

Run this from the root of your `ladybug-graph-training/` workspace:

```bash
docker run --rm -p 8000:8000 \
  -v "$(pwd)/db:/database" \
  -v "$(pwd)/data:/data" \
  -e LBUG_FILE=platform.lbug \
  -e MODE=READ_ONLY \
  ghcr.io/ladybugdb/explorer:latest
```

When the logs settle, open **http://localhost:8000**. Reading the command flag by flag, because each one matters:

| Flag | What it does |
|---|---|
| `-p 8000:8000` | Publishes Explorer's port so your browser can reach it at `localhost:8000`. |
| `-v "$(pwd)/db:/database"` | Mounts your local `db/` folder into the container. This is what makes Explorer see *your* graph rather than an empty one. |
| `-e LBUG_FILE=platform.lbug` | Names the database file inside the mounted folder. Without it, Explorer looks for a default filename and would not find yours. |
| `-v "$(pwd)/data:/data"` | Mounts your CSV folder as `/data`, so you can run `COPY` statements from inside Explorer if you want to load more. Optional. |
| `-e MODE=READ_ONLY` | Opens the database read-only. `MATCH` and all the read queries in this book still work; `CREATE`, `SET`, and `MERGE` are blocked. |
| `--rm` | Removes the container when you stop it (Ctrl+C). Explorer leaves nothing behind. |

> **Why `READ_ONLY` is the default in this book.** The platform graph is a teaching artifact you will rebuild and re-query many times. Opening it read-only in Explorer guarantees that an afternoon of exploration cannot accidentally mutate it: a stray `SET` in the query panel simply fails instead of quietly changing your data. When you genuinely want to modify the graph from Explorer, drop the flag or set `MODE=READ_WRITE`. Note one consequence of the underlying engine: a LadybugDB database is *embedded* and accepts a single writer, so if Explorer holds the database open, close any CLI session that has it open first.

## 7.4 Launching with Podman: the differences

Podman implements the same command-line interface as Docker, so the command above works almost verbatim, replacing `docker` with `podman`:

```bash
podman run --rm -p 8000:8000 \
  -v "$(pwd)/db:/database:Z" \
  -v "$(pwd)/data:/data:Z" \
  -e LBUG_FILE=platform.lbug \
  -e MODE=READ_ONLY \
  ghcr.io/ladybugdb/explorer:latest
```

Two differences are worth knowing:

The `:Z` suffix on the volume mounts. On Linux distributions that enforce SELinux (Fedora, RHEL, Rocky, and their kin, where rootless Podman is most common) the container is denied access to host directories unless they are relabelled. Appending `:Z` tells the engine to relabel the mounted folder so the container can read it. On a non-SELinux system the suffix is harmless, and `:Z` is also accepted by Docker, which is why the script in §7.5 simply always uses it with Podman.

Rootless operation. Podman typically runs without root. Publishing port 8000 is fine rootless (the restriction only affects ports below 1024), so no extra configuration is needed. The image reference is already fully qualified (`ghcr.io/...`), which also keeps Podman from prompting you to choose a registry.

## 7.5 One script for both: `scripts/explorer.sh`

Rather than remember which engine and which flags, save this script as `scripts/explorer.sh`. It resolves the workspace paths, detects whichever engine is installed, checks that the database actually exists, and launches Explorer with the right configuration. Make it executable once with `chmod +x scripts/explorer.sh`.

```bash
#!/usr/bin/env bash
# scripts/explorer.sh - launch LadybugDB Explorer against the platform graph.
#
#   ./scripts/explorer.sh                  # read-only (safe default)
#   MODE=READ_WRITE ./scripts/explorer.sh  # allow writes from Explorer
set -euo pipefail

# --- resolve workspace paths ---------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DB_DIR="${PROJECT_DIR}/db"
DATA_DIR="${PROJECT_DIR}/data"
DB_FILE="platform.lbug"
PORT="8000"
MODE="${MODE:-READ_ONLY}"          # overridable from the environment

# --- the database must exist first --------------------------------------
if [ ! -f "${DB_DIR}/${DB_FILE}" ]; then
  echo "ERROR: ${DB_DIR}/${DB_FILE} not found."
  echo "Build it first: run schema.cypher then load.cypher (Part III)."
  exit 1
fi

# --- pick a container engine --------------------------------------------
if command -v docker >/dev/null 2>&1; then
  ENGINE="docker"
  MOUNT=""                         # Docker: no relabel suffix needed
elif command -v podman >/dev/null 2>&1; then
  ENGINE="podman"
  MOUNT=":Z"                       # Podman: relabel mounts for SELinux
else
  echo "ERROR: neither docker nor podman is installed."
  echo "See Chapter 7, section 7.7 for the container-free alternative."
  exit 1
fi

echo "Engine: ${ENGINE}   Mode: ${MODE}"
echo "Opening LadybugDB Explorer at http://localhost:${PORT}"
echo "Press Ctrl+C to stop."

exec "${ENGINE}" run --rm -p "${PORT}:8000" \
  -v "${DB_DIR}:/database${MOUNT}" \
  -v "${DATA_DIR}:/data${MOUNT}" \
  -e LBUG_FILE="${DB_FILE}" \
  -e MODE="${MODE}" \
  ghcr.io/ladybugdb/explorer:latest
```

Run it with `./scripts/explorer.sh` and open the URL it prints. This is the recommended path for a team program: every engineer runs the same command regardless of which engine their machine has.

## 7.6 Running the book's queries in Explorer

Once Explorer is open at `localhost:8000`, the **Query panel** is a text box that accepts exactly the Cypher you have written throughout this book: the database behind it is your `platform.lbug`. Two things to try first.

Paste the full-downstream lineage query from Part IV:

```cypher
MATCH (:TableAsset {name: 'orders_raw'})<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l1:TableAsset)
OPTIONAL MATCH (l1)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l2:TableAsset)
WITH collect(DISTINCT l1.name) + collect(DISTINCT l2.name) AS assets
UNWIND assets AS a
MATCH (t:TableAsset {name: a})-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;
```

**Expected result** (three rows, in any order).

| dashboard |
|---|
| Sales Dashboard |
| Customer Health Dashboard |
| Executive Revenue Dashboard |

In the CLI this returned three dashboard names in a column. Here, switch between the result views: **graph**, **table**, **JSON**. The table view matches what the CLI showed you. But to *see* the lineage as a structure, run a query that returns the nodes and edges themselves rather than just names:

```cypher
MATCH path = (:System {name: 'Billing'})<-[:READS_SYSTEM]-(:Pipeline)
             -[:WRITES_TO]->(:TableAsset)<-[:READS_TABLE]-(:Pipeline)
             -[:WRITES_TO]->(:TableAsset)<-[:READS_TABLE]-(:Pipeline)
             -[:WRITES_TO]->(:TableAsset)-[:POWERS]->(:Dashboard)
RETURN path;
```

**Expected result:** one `path`. Explorer draws it as the Billing chain `Billing → payments_raw → payments_curated → revenue_daily → Executive Revenue Dashboard` (with the pipeline nodes in between). Returned as a table or JSON it is a single `path` value rather than a column of names.

Returning the `path` itself, rather than properties of it, is what gives Explorer something to draw. The graph view now shows the Billing outage's blast radius as a path from the source system all the way to the dashboard, the same answer Part V computed, but in the form a stakeholder actually absorbs. This is the moment to point a non-engineer at the screen.

A note tying back to §7.3: because the book's launch configuration is `READ_ONLY`, every `MATCH` query here works, but a `CREATE` or `SET` will be refused. That is the intended safety boundary for exploration. The **Schema panel**, separately, draws the seven node tables and their relationship types without you writing any query at all, a fast way to confirm the model loaded correctly, and a useful onboarding picture in its own right.

## 7.7 The container-free alternative

If your environment genuinely forbids containers, be clear-eyed about what is and is not possible. Explorer *itself* has no container-free distribution: there is no way to run that specific application without Docker or Podman. What you can still do is *visualize the same graph* by a different route.

The LadybugDB documentation lists third-party visualization integrations, and one of them runs entirely inside a Jupyter notebook with no container at all: the **yFiles Jupyter Graphs** integration, installed with `pip`. The approach mirrors Appendix D: query the database with the Python client, then hand the result to a notebook graph widget instead of printing it:

```python
import ladybug
# Query the platform graph with the Python client (no container involved).
db   = ladybug.Database("db/platform.lbug")
conn = ladybug.Connection(db)
result = conn.execute(
    "MATCH path = (s:System)<-[:READS_SYSTEM]-(:Pipeline)"
    "-[:WRITES_TO]->(:TableAsset)-[:POWERS]->(:Dashboard) RETURN path"
)
# Pass `result` to the yFiles Jupyter Graphs widget to render it inline.
# See the integration's own documentation for the exact widget call,
# as that API is maintained outside LadybugDB.
```

This gives you an interactive graph picture in a notebook, installed through `pip` like any other Python package. It is the honest container-free answer: not Explorer, but a real visualization path. Two lighter-weight fallbacks also exist: the LadybugDB CLI from Part II shows results as tables (container-free, but not visual), and the documentation lists desktop integrations such as G.V() for those able to install a standalone application. For exact, current setup steps on any third-party integration, consult its own documentation rather than this book, since those tools are maintained separately and version independently of LadybugDB.

## 7.8 Closing

Explorer does not teach you anything new about graphs; by Part VII there is nothing new to teach. What it changes is *bandwidth*. A dependency chain described in a table is something a stakeholder has to assemble in their head; the same chain drawn as a branching graph is something they simply see. For the recurring job this book was written around (explaining what breaks, and to whom) that difference is the whole point. Build the graph in the CLI, reason about it in Cypher, and when the moment comes to show someone the blast radius, open Explorer and let the picture do the talking.
