// Part V: Blast Radius, Ownership, and Operational Risk
// Example queries from the book. Run against db/platform.lbug after
// loading scripts/schema.cypher then scripts/load.cypher:
//   lbug db/platform.lbug
// then paste a query, or run this whole file.
// If payments_raw is delayed, which dashboards are affected (across all layers)
MATCH (:TableAsset {name: 'payments_raw'})<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(mart:TableAsset)-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;

// Which team owns the pipeline behind the Customer Health Dashboard
MATCH (team:Team)-[:OWNS_PIPELINE]->(p:Pipeline)
      -[:WRITES_TO]->(t:TableAsset)
      -[:POWERS]->(:Dashboard {name: 'Customer Health Dashboard'})
RETURN team.name AS team, p.name AS pipeline, t.name AS table_asset;

// Which jobs run the pipelines that feed business dashboards
MATCH (j:Job)-[:RUNS]->(p:Pipeline)-[:WRITES_TO]->(t:TableAsset)
      -[:POWERS]->(d:Dashboard)
RETURN j.name AS job, p.name AS pipeline, d.name AS dashboard
ORDER BY d.name, p.name;

// Full impact of a Billing outage, with owning teams
MATCH (:System {name: 'Billing'})<-[:READS_SYSTEM]-(:Pipeline)-[:WRITES_TO]->(raw:TableAsset)
MATCH (raw)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(mart:TableAsset)-[:POWERS]->(d:Dashboard)
OPTIONAL MATCH (team:Team)-[:OWNS_DASHBOARD]->(d)
RETURN DISTINCT d.name AS dashboard, collect(DISTINCT team.name) AS owning_teams;

// Quantify the blast radius of a Billing outage
MATCH (:System {name: 'Billing'})<-[:READS_SYSTEM]-(:Pipeline)-[:WRITES_TO]->(raw:TableAsset)
MATCH (raw)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(mart:TableAsset)-[:POWERS]->(d:Dashboard)
OPTIONAL MATCH (team:Team)-[:OWNS_DASHBOARD]->(d)
RETURN count(DISTINCT d) AS dashboards_affected,
       count(DISTINCT team) AS teams_to_notify;
