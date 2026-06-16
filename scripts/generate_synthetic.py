"""
Appendix D - Synthetic data generator for the LadybugDB platform graph.

SDV scales the node property distributions; explicit medallion-aware logic
builds a referentially valid graph topology around them. Output is written
in the same CSV format as Appendix A, ready for COPY FROM.
"""
import os
import random
import numpy as np
import pandas as pd
from sdv.metadata import Metadata
from sdv.single_table import GaussianCopulaSynthesizer

# ----------------------------- Config -------------------------------------
SEED_DIR       = "data"         # the Appendix A dataset
OUT_DIR        = "data_synth"   # the expanded dataset is written here
N_TABLE_ASSETS = 40             # synthetic table assets to add to the seed
N_DASHBOARDS   = 6              # synthetic dashboards to add to the seed
RANDOM_SEED    = 42

random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# --------------------------- SDV helper ------------------------------------
def synthesize(seed_df, property_cols, n_rows):
    """Learn the property distribution of a node table and sample n_rows of it.

    Only property columns are modelled. Identifier columns (id, name) are
    excluded and regenerated downstream, since resampling unique keys would
    produce collisions.
    """
    train = seed_df[property_cols].copy()
    metadata = Metadata.detect_from_dataframe(train)
    synth = GaussianCopulaSynthesizer(metadata)
    synth.fit(train)
    return synth.sample(num_rows=n_rows).reset_index(drop=True)

# --------------------------- Load the seed --------------------------------
def load(name):
    return pd.read_csv(os.path.join(SEED_DIR, name))

systems   = load("systems.csv")
databases = load("databases.csv")
teams     = load("teams.csv")
hosts     = load("hosts.csv")
seed_tbls = load("table_assets.csv")
seed_pls  = load("pipelines.csv")
seed_dash = load("dashboards.csv")
seed_jobs = load("jobs.csv")

# ------------- Stage 1: SDV synthesizes the node populations --------------
syn_tbl_props = synthesize(seed_tbls, ["layer", "domain"], N_TABLE_ASSETS)
n_tables_total = len(seed_tbls) + N_TABLE_ASSETS
syn_pl_props   = synthesize(seed_pls, ["mode", "schedule"], n_tables_total)

# ------------- Stage 2: assemble a valid medallion topology ---------------
# Table assets: seed (kept verbatim) + synthetic.
tables = []
for _, r in seed_tbls.iterrows():
    tables.append(dict(id=r["id"], name=r["name"],
                        layer=r["layer"], domain=r["domain"]))
for i, r in syn_tbl_props.iterrows():
    tables.append(dict(id=f"tbl_s{i + 1:04d}",
                        name=f"{r['domain']}_{r['layer']}_s{i + 1}",
                        layer=r["layer"], domain=r["domain"]))

tables_by_layer = {}
for t in tables:
    tables_by_layer.setdefault(t["layer"], []).append(t)
raw_tables     = tables_by_layer.get("raw", [])
curated_tables = tables_by_layer.get("curated", [])
mart_tables    = tables_by_layer.get("mart", [])

saas_systems = systems[systems["kind"] == "SaaS"]["id"].tolist()
db_by_layer  = dict(zip(databases["layer"], databases["id"]))
STAGE_WORD   = {"raw": "ingest", "curated": "curate", "mart": "build"}

def source_system_for(domain):
    """Pick a plausible source system for an ingest pipeline."""
    pref = {"customer": "sys_crm", "order": "sys_crm",
            "payment": "sys_billing", "finance": "sys_billing"}
    cand = pref.get(domain)
    return cand if cand in saas_systems else random.choice(saas_systems)

# One writer pipeline per table; read edges depend on the table's layer.
pipelines, writes_to, reads_system, reads_table, contains = [], [], [], [], []

for idx, t in enumerate(tables):
    props = syn_pl_props.iloc[idx % len(syn_pl_props)]
    stage = STAGE_WORD.get(t["layer"], "build")
    pid = f"pl_{stage}_{idx + 1:04d}"
    pipelines.append(dict(id=pid, name=f"{stage}_{t['name']}",
                          mode=props["mode"], schedule=props["schedule"],
                          layer=t["layer"]))
    writes_to.append((pid, t["id"]))

    if t["layer"] in db_by_layer:
        contains.append((db_by_layer[t["layer"]], t["id"]))

    if t["layer"] == "raw":
        reads_system.append((pid, source_system_for(t["domain"])))
    elif t["layer"] == "curated":
        pool = [x for x in raw_tables if x["domain"] == t["domain"]] or raw_tables
        if pool:
            reads_table.append((pid, random.choice(pool)["id"]))
    else:  # mart, and any other layer, reads from curated assets
        pool = [x for x in curated_tables if x["domain"] == t["domain"]] \
            or curated_tables
        for src in random.sample(pool, k=min(2, len(pool))):
            reads_table.append((pid, src["id"]))

# Jobs: one per stage, running every pipeline in that stage.
engine = seed_jobs["engine"].iloc[0] if len(seed_jobs) else "airflow"
stage_jobs = {"raw": "job_ingest", "curated": "job_curate", "mart": "job_marts"}
jobs = [dict(id=jid, name=jid.replace("job_", "") + "_job", engine=engine)
        for jid in dict.fromkeys(stage_jobs.values())]
runs = [(stage_jobs[p["layer"]], p["id"]) for p in pipelines]

# Dashboards: seed (kept) + synthetic. Every mart table powers one dashboard.
dash_tool = seed_dash["tool"].iloc[0] if len(seed_dash) else "PowerBI"
dashboards = [dict(id=r["id"], name=r["name"], tool=r["tool"])
              for _, r in seed_dash.iterrows()]
for n in range(N_DASHBOARDS):
    dashboards.append(dict(id=f"dash_s{n + 1:03d}",
                           name=f"Synthetic Dashboard {n + 1}", tool=dash_tool))

powers = []
if mart_tables:
    for t in mart_tables:
        powers.append((t["id"], random.choice(dashboards)["id"]))
    powered = {d for _, d in powers}
    for d in dashboards:                       # guarantee each is powered
        if d["id"] not in powered:
            powers.append((random.choice(mart_tables)["id"], d["id"]))

# Ownership: teams own pipelines and dashboards, round-robin.
team_ids = teams["id"].tolist()
owns_pipeline  = [(team_ids[i % len(team_ids)], p["id"])
                  for i, p in enumerate(pipelines)]
owns_dashboard = [(team_ids[i % len(team_ids)], d["id"])
                  for i, d in enumerate(dashboards)]

# ------------------------- Write the output -------------------------------
os.makedirs(OUT_DIR, exist_ok=True)

def write(name, df):
    df.to_csv(os.path.join(OUT_DIR, name), index=False)

write("systems.csv", systems)
write("databases.csv", databases)
write("teams.csv", teams)
write("hosts.csv", hosts)
write("table_assets.csv",
      pd.DataFrame(tables)[["id", "name", "layer", "domain"]])
write("pipelines.csv",
      pd.DataFrame(pipelines)[["id", "name", "mode", "schedule"]])
write("jobs.csv", pd.DataFrame(jobs)[["id", "name", "engine"]])
write("dashboards.csv", pd.DataFrame(dashboards)[["id", "name", "tool"]])

rel_files = {
    "contains.csv": contains,         "reads_system.csv": reads_system,
    "reads_table.csv": reads_table,   "writes_to.csv": writes_to,
    "runs.csv": runs,                 "powers.csv": powers,
    "owns_pipeline.csv": owns_pipeline, "owns_dashboard.csv": owns_dashboard,
}
for fname, pairs in rel_files.items():
    write(fname, pd.DataFrame(pairs, columns=["from", "to"]))

# --------------------- Referential integrity check ------------------------
node_ids = {
    "System": set(systems["id"]),   "Database": set(databases["id"]),
    "Team": set(teams["id"]),       "TableAsset": {t["id"] for t in tables},
    "Pipeline": {p["id"] for p in pipelines},
    "Job": {j["id"] for j in jobs}, "Dashboard": {d["id"] for d in dashboards},
}
hosts_pairs = list(hosts.itertuples(index=False, name=None))
all_edges = {
    "hosts":          (hosts_pairs,    "System",     "Database"),
    "contains":       (contains,       "Database",   "TableAsset"),
    "reads_system":   (reads_system,   "Pipeline",   "System"),
    "reads_table":    (reads_table,    "Pipeline",   "TableAsset"),
    "writes_to":      (writes_to,      "Pipeline",   "TableAsset"),
    "runs":           (runs,           "Job",        "Pipeline"),
    "powers":         (powers,         "TableAsset", "Dashboard"),
    "owns_pipeline":  (owns_pipeline,  "Team",       "Pipeline"),
    "owns_dashboard": (owns_dashboard, "Team",       "Dashboard"),
}
ok = True
for name, (pairs, ftype, ttype) in all_edges.items():
    for f, t in pairs:
        if f not in node_ids[ftype] or t not in node_ids[ttype]:
            print(f"  dangling edge in {name}: {f} -> {t}")
            ok = False

# ------------------------------ Summary -----------------------------------
print(f"Wrote expanded dataset to {OUT_DIR}/")
print(f"  Systems:       {len(systems)}")
print(f"  Databases:     {len(databases)}")
print(f"  Teams:         {len(teams)}")
print(f"  TableAssets:   {len(tables)}")
print(f"  Pipelines:     {len(pipelines)}")
print(f"  Jobs:          {len(jobs)}")
print(f"  Dashboards:    {len(dashboards)}")
print(f"  Relationships: {sum(len(e[0]) for e in all_edges.values())}")
print(f"Referential integrity: {'OK' if ok else 'FAILED'}")
