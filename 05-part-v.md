# Part V: Blast Radius, Ownership, and Operational Risk

## 5.1 Why this part exists

A graph becomes compelling when it supports **operational decisions under change or failure.** Lineage is useful; impact analysis is where the graph starts to feel necessary. This part connects technical dependencies with ownership, so the team can answer the questions that actually matter during an incident: what is affected, who owns it, and what to check first.

## 5.2 The incident scenario

A billing extract is delayed. The team needs to determine: which pipelines read from billing, which tables go stale, which dashboards are affected, which teams own them, and the shortest clear story from source issue to business impact.

## 5.3 Impact queries

**If `payments_raw` is delayed, which dashboards are affected**, across all layers:

```cypher
MATCH (:TableAsset {name: 'payments_raw'})<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(mart:TableAsset)-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;
```

**Expected result.**

| dashboard |
|---|
| Executive Revenue Dashboard |

**Which team owns the pipeline behind the Customer Health Dashboard:**

```cypher
MATCH (team:Team)-[:OWNS_PIPELINE]->(p:Pipeline)
      -[:WRITES_TO]->(t:TableAsset)
      -[:POWERS]->(:Dashboard {name: 'Customer Health Dashboard'})
RETURN team.name AS team, p.name AS pipeline, t.name AS table_asset;
```

**Expected result.**

| team | pipeline | table_asset |
|---|---|---|
| Analytics Engineering | `build_customer_360` | `customer_360` |

**Which jobs run the pipelines that feed business dashboards:**

```cypher
MATCH (j:Job)-[:RUNS]->(p:Pipeline)-[:WRITES_TO]->(t:TableAsset)
      -[:POWERS]->(d:Dashboard)
RETURN j.name AS job, p.name AS pipeline, d.name AS dashboard
ORDER BY d.name, p.name;
```

**Expected result.**

| job | pipeline | dashboard |
|---|---|---|
| `build_marts` | `build_customer_360` | Customer Health Dashboard |
| `build_marts` | `build_revenue_daily` | Executive Revenue Dashboard |
| `build_marts` | `build_customer_360` | Sales Dashboard |
| `curate_layer` | `curate_orders` | Sales Dashboard |

**Full impact of a Billing outage, with owning teams:**

```cypher
MATCH (:System {name: 'Billing'})<-[:READS_SYSTEM]-(:Pipeline)-[:WRITES_TO]->(raw:TableAsset)
MATCH (raw)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(mart:TableAsset)-[:POWERS]->(d:Dashboard)
OPTIONAL MATCH (team:Team)-[:OWNS_DASHBOARD]->(d)
RETURN DISTINCT d.name AS dashboard, collect(DISTINCT team.name) AS owning_teams;
```

**Expected result.**

| dashboard | owning_teams |
|---|---|
| Executive Revenue Dashboard | [BI & Reporting] |

## 5.4 Quantify the blast radius

A dependency story is good for narrative. A *number* is what leadership wants in an incident review. This query reduces the Billing outage to a one-line magnitude:

```cypher
MATCH (:System {name: 'Billing'})<-[:READS_SYSTEM]-(:Pipeline)-[:WRITES_TO]->(raw:TableAsset)
MATCH (raw)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(mart:TableAsset)-[:POWERS]->(d:Dashboard)
OPTIONAL MATCH (team:Team)-[:OWNS_DASHBOARD]->(d)
RETURN count(DISTINCT d) AS dashboards_affected,
       count(DISTINCT team) AS teams_to_notify;
```

**Expected result.**

| dashboards_affected | teams_to_notify |
|---|---|
| 1 | 1 |

## 5.5 Capstone exercise

Run in pairs. Start from the source issue (*Billing is delayed*) and produce, in order: the directly dependent pipelines; the output table assets; the downstream dashboards; the owning teams. Then present the result **as a dependency story, not a result set**, and finish with the quantified blast radius.

The capstone is where the graph stops feeling like a query toy and starts feeling like an operational map. That shift, from "elegant query" to "I can run an incident with this," is the moment the model earns its place.

## 5.6 Validation checklist

- [ ] The team can identify impacted dashboards from an upstream issue, at full depth.
- [ ] They can connect technical impact to ownership.
- [ ] They can state the blast radius as a number leadership would accept.
- [ ] They can propose one extension that would make the model more useful in production.

**Discussion prompts.** Should ownership live on dashboards, pipelines, or both? Would freshness, SLA, or quality status be modeled as node properties or as separate entities? How would the model change if the team needed job-run history and incident history, not only current-state topology?

## 5.7 Closing

The goal of this book is not to make everyone a graph specialist. It is to make the team comfortable enough with graph thinking that the next time someone asks *"what breaks if this upstream asset changes?"*, the room immediately recognizes it as a connected-data problem, knows that the answer must be traced to full depth, and knows how to get it in one query instead of one hour. And, just as importantly, knows (from the decision rule in Part I) when *not* to reach for a graph at all.
