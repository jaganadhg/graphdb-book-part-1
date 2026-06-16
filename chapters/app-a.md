# Appendix A: The complete dataset

Place every file below in `data/`. Each relationship file uses a `from,to` header of node primary keys.

## Node files

**`systems.csv`**

```
id,name,kind
sys_crm,CRM,SaaS
sys_billing,Billing,SaaS
sys_snowflake,Snowflake,Warehouse
sys_bi,PowerBI,BI
```

**`databases.csv`**

```
id,name,layer
db_raw,raw_db,raw
db_curated,curated_db,curated
db_mart,mart_db,mart
```

**`table_assets.csv`**

```
id,name,layer,domain
tbl_customers_raw,customers_raw,raw,customer
tbl_orders_raw,orders_raw,raw,order
tbl_payments_raw,payments_raw,raw,payment
tbl_customers_curated,customers_curated,curated,customer
tbl_orders_curated,orders_curated,curated,order
tbl_payments_curated,payments_curated,curated,payment
tbl_customer_360,customer_360,mart,customer
tbl_revenue_daily,revenue_daily,mart,finance
```

**`pipelines.csv`**

```
id,name,mode,schedule
pl_ingest_crm,ingest_crm,batch,hourly
pl_ingest_billing,ingest_billing,batch,daily
pl_curate_customers,curate_customers,batch,daily
pl_curate_orders,curate_orders,batch,daily
pl_curate_payments,curate_payments,batch,daily
pl_build_customer360,build_customer_360,batch,daily
pl_build_revenue,build_revenue_daily,batch,daily
```

**`jobs.csv`**

```
id,name,engine
job_morning_ingest,morning_ingest,airflow
job_curate,curate_layer,airflow
job_marts,build_marts,airflow
```

**`dashboards.csv`**

```
id,name,tool
dash_sales,Sales Dashboard,PowerBI
dash_customer_health,Customer Health Dashboard,PowerBI
dash_revenue,Executive Revenue Dashboard,PowerBI
```

**`teams.csv`**

```
id,name,function
team_data_eng,Data Engineering,engineering
team_analytics,Analytics Engineering,engineering
team_bi,BI & Reporting,analytics
```

## Relationship files

**`hosts.csv`**

```
from,to
sys_snowflake,db_raw
sys_snowflake,db_curated
sys_snowflake,db_mart
```

**`contains.csv`**

```
from,to
db_raw,tbl_customers_raw
db_raw,tbl_orders_raw
db_raw,tbl_payments_raw
db_curated,tbl_customers_curated
db_curated,tbl_orders_curated
db_curated,tbl_payments_curated
db_mart,tbl_customer_360
db_mart,tbl_revenue_daily
```

**`reads_system.csv`**

```
from,to
pl_ingest_crm,sys_crm
pl_ingest_billing,sys_billing
```

**`reads_table.csv`**

```
from,to
pl_curate_customers,tbl_customers_raw
pl_curate_orders,tbl_orders_raw
pl_curate_payments,tbl_payments_raw
pl_build_customer360,tbl_customers_curated
pl_build_customer360,tbl_orders_curated
pl_build_revenue,tbl_payments_curated
pl_build_revenue,tbl_orders_curated
```

**`writes_to.csv`**

```
from,to
pl_ingest_crm,tbl_customers_raw
pl_ingest_crm,tbl_orders_raw
pl_ingest_billing,tbl_payments_raw
pl_curate_customers,tbl_customers_curated
pl_curate_orders,tbl_orders_curated
pl_curate_payments,tbl_payments_curated
pl_build_customer360,tbl_customer_360
pl_build_revenue,tbl_revenue_daily
```

**`runs.csv`**

```
from,to
job_morning_ingest,pl_ingest_crm
job_morning_ingest,pl_ingest_billing
job_curate,pl_curate_customers
job_curate,pl_curate_orders
job_curate,pl_curate_payments
job_marts,pl_build_customer360
job_marts,pl_build_revenue
```

**`powers.csv`**

```
from,to
tbl_orders_curated,dash_sales
tbl_customer_360,dash_sales
tbl_customer_360,dash_customer_health
tbl_revenue_daily,dash_revenue
```

**`owns_pipeline.csv`**

```
from,to
team_data_eng,pl_ingest_crm
team_data_eng,pl_ingest_billing
team_analytics,pl_curate_customers
team_analytics,pl_curate_orders
team_analytics,pl_curate_payments
team_analytics,pl_build_customer360
team_analytics,pl_build_revenue
```

**`owns_dashboard.csv`**

```
from,to
team_bi,dash_sales
team_bi,dash_customer_health
team_bi,dash_revenue
```
