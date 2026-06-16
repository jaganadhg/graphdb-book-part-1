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
