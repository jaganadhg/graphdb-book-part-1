// Part VII: Seeing the Graph with LadybugDB Explorer
// Example queries from the book. Run against db/platform.lbug after
// loading scripts/schema.cypher then scripts/load.cypher:
//   lbug db/platform.lbug
// then paste a query, or run this whole file.
// Full downstream lineage of orders_raw (paste into Ladybug Explorer)
MATCH (:TableAsset {name: 'orders_raw'})<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l1:TableAsset)
OPTIONAL MATCH (l1)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l2:TableAsset)
WITH collect(DISTINCT l1.name) + collect(DISTINCT l2.name) AS assets
UNWIND assets AS a
MATCH (t:TableAsset {name: a})-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;

// Billing blast radius as a path, source to dashboard (returns a path; draw in Explorer)
MATCH path = (:System {name: 'Billing'})<-[:READS_SYSTEM]-(:Pipeline)
             -[:WRITES_TO]->(:TableAsset)<-[:READS_TABLE]-(:Pipeline)
             -[:WRITES_TO]->(:TableAsset)<-[:READS_TABLE]-(:Pipeline)
             -[:WRITES_TO]->(:TableAsset)-[:POWERS]->(:Dashboard)
RETURN path;
