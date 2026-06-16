// Part IV: Tracing Lineage
// Example queries from the book. Run against db/platform.lbug after
// loading scripts/schema.cypher then scripts/load.cypher:
//   lbug db/platform.lbug
// then paste a query, or run this whole file.
// First attempt: dashboards one pipeline-hop downstream of orders_raw
MATCH (:TableAsset {name: 'orders_raw'})<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(:TableAsset)-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;

// Full downstream lineage of orders_raw, across all layers
MATCH (:TableAsset {name: 'orders_raw'})<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l1:TableAsset)
OPTIONAL MATCH (l1)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l2:TableAsset)
WITH collect(DISTINCT l1.name) + collect(DISTINCT l2.name) AS assets
UNWIND assets AS a
MATCH (t:TableAsset {name: a})-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;

// Immediate upstream of customer_360
MATCH (p:Pipeline)-[:WRITES_TO]->(:TableAsset {name: 'customer_360'})
MATCH (p)-[:READS_TABLE]->(src:TableAsset)
RETURN p.name AS pipeline, collect(src.name) AS upstream_tables;

// Which tables power the Sales Dashboard
MATCH (t:TableAsset)-[:POWERS]->(:Dashboard {name: 'Sales Dashboard'})
RETURN t.name AS table_asset;

// Which source systems ultimately influence the Customer Health Dashboard
MATCH (s:System)<-[:READS_SYSTEM]-(:Pipeline)
      -[:WRITES_TO]->(raw:TableAsset)
MATCH (raw)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(mart:TableAsset)
      -[:POWERS]->(:Dashboard {name: 'Customer Health Dashboard'})
RETURN DISTINCT s.name AS source_system;
