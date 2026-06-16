# Part II: Setting Up LadybugDB

The goal of this part is a common, validated local environment for every engineer, and enough fluency with the LadybugDB shell to be productive in Part III. Do not rush it: the fastest way to lose a room in a technical program is to let environment variance dominate the first hour.

## 2.1 What LadybugDB is

LadybugDB is an **open-source, embedded property-graph database**. A few properties make it well-suited to a disciplined team coming from SQL:

- **Embedded and serverless.** It runs inside a local process or a CLI shell, with no server to stand up, no container, no infrastructure. A database is just a path on disk.
- **Structured property-graph model.** It requires a predefined schema: node tables and relationship tables, with strongly typed properties. Node tables require a primary key; relationship tables do not. This makes graph modeling feel rigorous rather than improvised.
- **Cypher.** It is queried in Cypher, the most widely used graph query language.
- **CSV-friendly bulk loading** via `COPY FROM`, which maps cleanly onto how engineers already think about ingestion.
- **MIT-licensed**, and built on the Kùzu engine, so the design has a mature lineage.

For this book, "a database" means a local on-disk path that LadybugDB creates and manages for you.

## 2.2 System requirements

The LadybugDB CLI is a single standalone executable with no dependencies. It is pre-compiled for:

| Platform | Supported versions |
|---|---|
| macOS | 11.0 or later, universal binary (Intel and Apple Silicon) |
| Linux | x86-64 and aarch64, most modern distributions, e.g. RHEL / CentOS / Rocky / Oracle Linux 8.0+ and Ubuntu 22.04+ |
| Windows | Windows 10 and 11, x86-64 and aarch64 |

If your team also wants to script data loads in Python (optional; this book is CLI-first), the LadybugDB Python client is pre-compiled for CPython 3.7 through 3.11, with the same OS support as above.

## 2.3 Installing the LadybugDB CLI

This book uses the **command-line shell**, because it keeps the whole team on identical, copy-pasteable commands.

### macOS and Linux

The simplest path is the official install script:

```bash
curl -s https://install.ladybugdb.com | bash
```

Then confirm the shell is on your `PATH`:

```bash
lbug
```

You should land in an interactive shell prompt. Type `:help` for usage hints, and `:quit` (or `Ctrl+D`) to exit.

> **Enterprise note.** Piping a remote script into `bash` is convenient but is not always acceptable inside a corporate environment. If your security posture forbids it, use the direct-download path below instead: the GitHub release assets are individually checksummed (SHA-256), so the binary can be verified before it runs.

**Direct download alternative.** Download the current CLI release for your platform from the LadybugDB releases page (`https://github.com/LadybugDB/ladybug/releases`). The CLI assets are named `lbug_cli-<platform>`, for example `lbug_cli-linux-x86_64.tar.gz`, `lbug_cli-linux-aarch64.tar.gz`, or `lbug_cli-osx-universal.tar.gz`. Then:

```bash
tar xzf lbug_cli-*.tar.gz
./lbug
```

Use whatever the current stable release is at the time of your program rather than pinning an old version. The install script always fetches the latest; if you download directly, take the newest release tag.

### Windows

Download the current CLI release for Windows from the same releases page. Right-click the downloaded `.zip` file and choose **Extract All**. This produces a folder containing `lbug.exe`. Right-click the folder, choose **Open in Terminal**, and run:

```powershell
.\lbug.exe
```


### Optional: the Python client

Teams that prefer to drive schema creation and loading from a script (rather than the shell) can install the Python client. This book does not require it, but it is a natural production direction:

```bash
pip install ladybug
# or, with uv:
uv add ladybug
```

## 2.4 The CLI shell: what every engineer should know

A LadybugDB database is a path. The shell behaves slightly differently depending on whether you give it one.

**On-disk database (what this book uses).** Pass a path; LadybugDB creates it if it does not exist, opens it read-write, and persists everything when you exit:

```bash
lbug db/platform.lbug
```

**In-memory database.** Omit the path entirely. Useful for throwaway experiments, since nothing is persisted:

```bash
lbug
```

A few shell essentials to demonstrate live during setup:

- Every Cypher statement ends with a **semicolon** `;`. The shell waits for one before executing.
- `:help` lists the built-in shell commands, including a command to print the current database schema.
- `:clear` (or `Ctrl+L`) clears the screen.
- `Ctrl+D` exits the shell.
- The shell launches with a buffer pool of up to 80% of available memory. To cap it (say, to 4 GB on a shared laptop) start it with `lbug -d 4096 db/platform.lbug` (`-d` takes a value in megabytes).

**Optional tooling worth knowing about.** *Ladybug Explorer* is a web-based GUI for visually exploring and querying a database, covered in detail in Part VII, and useful when you want to *see* the graph during Part IV. There is also a *LadybugDB MCP server* that exposes a database as a tool for LLMs and agents. Neither is required for the early chapters, but both are worth a mention to the team.

## 2.5 Your workspace

Use the same layout on every machine. Early inconsistency in file paths is the most common way a technical session degrades into troubleshooting.

```
ladybug-graph-training/
|-- data/      # the tutorial CSV files
|-- scripts/   # schema.cypher and load.cypher
`-- db/        # the LadybugDB database, db/platform.lbug
```

## 2.6 Getting the dataset

The complete tutorial dataset (every node and relationship CSV) is listed in **Appendix A**. Before Part III, each engineer should place all of those files in their `data/` folder. The dataset is intentionally small enough to inspect by eye, but it spans three medallion layers so that dependency chains are genuinely multi-hop.

## 2.7 Definition of done

Do not begin Part III until **every** engineer can confirm all of the following:

- [ ] The LadybugDB CLI is installed and `lbug` (or `lbug.exe`) launches a shell.
- [ ] Their machine meets the documented system requirements.
- [ ] The `ladybug-graph-training/` workspace exists with `data/`, `scripts/`, and `db/`.
- [ ] An on-disk database opens: `lbug db/platform.lbug` succeeds and persists on exit.
- [ ] A trivial statement runs and returns a result, for example `RETURN 1 AS ok;`.
- [ ] Every dataset CSV from Appendix A is present in `data/`.
