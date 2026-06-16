// Part VI: The Vocabulary, in Hindsight (section 6.8, existence and universality)
// Example queries from the book. Run against db/platform.lbug after
// loading scripts/schema.cypher then scripts/load.cypher:
//   lbug db/platform.lbug
// then paste a query, or run this whole file.
// Existence: pipelines that read at least one raw-layer table
MATCH (p:Pipeline)
WHERE EXISTS { MATCH (p)-[:READS_TABLE]->(t:TableAsset)
               WHERE t.layer = 'raw' }
RETURN p.name AS pipeline;

// Non-existence (orphan finder): table assets that power no dashboard
MATCH (t:TableAsset)
WHERE NOT EXISTS { MATCH (t)-[:POWERS]->(:Dashboard) }
RETURN t.name AS table_asset, t.layer AS layer;

// Non-existence narrowed: mart tables that power nothing
MATCH (t:TableAsset)
WHERE t.layer = 'mart'
  AND NOT EXISTS { MATCH (t)-[:POWERS]->(:Dashboard) }
RETURN t.name AS unpowered_mart;

// Non-existence: dashboards with no owning team
MATCH (d:Dashboard)
WHERE NOT EXISTS { MATCH (:Team)-[:OWNS_DASHBOARD]->(d) }
RETURN d.name AS dashboard;

// Universal check: every mart table should power a dashboard.
// This query searches for a violation. An empty result means the rule holds.
MATCH (t:TableAsset)
WHERE t.layer = 'mart'
  AND NOT EXISTS { MATCH (t)-[:POWERS]->(:Dashboard) }
RETURN t.name AS unpowered_mart_table;

// Universal check by counting: does every pipeline have an output edge
MATCH (p:Pipeline)
WITH count(p) AS total_pipelines
MATCH (p:Pipeline)
WHERE EXISTS { MATCH (p)-[:WRITES_TO]->(:TableAsset) }
RETURN total_pipelines,
       count(p)                       AS pipelines_with_output,
       total_pipelines = count(p)      AS every_pipeline_writes;

// Quantify over a list with ALL: pipelines whose inputs are all curated
MATCH (p:Pipeline)-[:READS_TABLE]->(t:TableAsset)
WITH p, collect(t.layer) AS input_layers
WHERE ALL(layer IN input_layers WHERE layer = 'curated')
RETURN p.name AS pipeline, input_layers;
