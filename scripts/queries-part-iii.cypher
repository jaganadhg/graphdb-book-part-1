// Part III: Modeling a Data Platform as a Graph (section 3.7, first queries)
// Example queries from the book. Run against db/platform.lbug after
// loading scripts/schema.cypher then scripts/load.cypher:
//   lbug db/platform.lbug
// then paste a query, or run this whole file.
// Which databases does the warehouse host?
MATCH (s:System {name: 'Snowflake'})-[:HOSTS]->(d:Database)
RETURN d.name AS database, d.layer AS layer
ORDER BY d.name;

// Which assets live in the raw layer?
MATCH (:Database {name: 'raw_db'})-[:CONTAINS]->(t:TableAsset)
RETURN t.name AS table_asset, t.domain AS domain
ORDER BY t.name;

// Which pipeline writes which table?
MATCH (p:Pipeline)-[:WRITES_TO]->(t:TableAsset)
RETURN p.name AS pipeline, t.name AS writes_table
ORDER BY p.name, t.name;
