# Part IV: Tracing Lineage

## 4.1 Why this part exists

Graph starts to matter when the question is about **paths** rather than records. Lineage is the canonical example: it connects sources, transformations, warehouse assets, and consumers in chains of dependency. This is where the team should stop seeing the graph as "metadata stored differently" and start seeing it as a dependency model that can be traversed directly.

Introduce two mental models. **Upstream lineage** asks where an asset came from. **Downstream lineage** asks what depends on an asset. Between them they cover most real operational questions.

## 4.2 The core lesson: one hop is not enough

Our platform is layered: raw → curated → mart. A dependency chain therefore crosses *several* pipeline hops. Watch what happens when we ask a downstream question with a single hop.

```{=latex}
\begin{figure}[ht]
\centering
\resizebox{\textwidth}{!}{%
\begin{tikzpicture}
  \node[gbhead] at (0,3.5)    {Systems};
  \node[gbhead] at (3.4,3.5)  {raw};
  \node[gbhead] at (7.2,3.5)  {curated};
  \node[gbhead] at (11.0,3.5) {mart};
  \node[gbhead] at (15.2,3.5) {Dashboards};
  \node[gbentity={gbSource}{7mm}] (crm)  at (0,1)     {CRM};
  \node[gbentity={gbSource}{7mm}] (bill) at (0,-2)    {Billing};
  \node[gbentity={gbRaw}{7mm}] (cr) at (3.4,2)   {customers\_raw};
  \node[gbentity={gbRaw}{7mm}] (orr) at (3.4,0)  {orders\_raw};
  \node[gbentity={gbRaw}{7mm}] (pr) at (3.4,-2)  {payments\_raw};
  \node[gbentity={gbCurated}{7mm}] (cc) at (7.2,2)  {customers\_curated};
  \node[gbentity={gbCurated}{7mm}] (oc) at (7.2,0)  {orders\_curated};
  \node[gbentity={gbCurated}{7mm}] (pc) at (7.2,-2) {payments\_curated};
  \node[gbentity={gbMart}{7mm}] (c360) at (11.0,1)    {customer\_360};
  \node[gbentity={gbMart}{7mm}] (rev)  at (11.0,-1.4) {revenue\_daily};
  \node[gbentity={gbDash}{7mm}] (sales) at (15.2,2)    {Sales};
  \node[gbentity={gbDash}{7mm}] (ch)    at (15.2,0)    {Customer Health};
  \node[gbentity={gbDash}{7mm}] (exec)  at (15.2,-2.1) {Executive Revenue};
  \draw[gbedge] (crm)  -- (cr);
  \draw[gbedge] (crm)  -- (orr);
  \draw[gbedge] (bill) -- (pr);
  \draw[gbedge] (cr) -- (cc);
  \draw[gbedge] (orr) -- (oc);
  \draw[gbedge] (pr) -- (pc);
  \draw[gbedge] (cc) -- (c360);
  \draw[gbedge] (oc) -- (c360);
  \draw[gbedge] (oc) -- (rev);
  \draw[gbedge] (pc) -- (rev);
  \draw[gbedge] (oc) to[bend left=12] (sales);
  \draw[gbedge] (c360) -- (sales);
  \draw[gbedge] (c360) -- (ch);
  \draw[gbedge] (rev) -- (exec);
\end{tikzpicture}%
}
\caption{The platform's medallion lineage, end to end: source systems feed raw tables, which are curated and then assembled into marts that power dashboards. Note that \texttt{orders\_curated} also powers a dashboard directly. Tracing impact (Parts IV and V) means walking these edges.}
\label{fig:lineage}
\end{figure}
```

```cypher
// First attempt: dashboards one pipeline-hop downstream of orders_raw
MATCH (:TableAsset {name: 'orders_raw'})<-[:READS_TABLE]-(:Pipeline)
      -[:WRITES_TO]->(:TableAsset)-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;
```

**Expected result.**

| dashboard |
|---|
| Sales Dashboard |

This returns only the **Sales Dashboard**, because `orders_raw` is one pipeline-hop from `orders_curated`, and `orders_curated` powers Sales. But `orders_curated` also feeds the customer-360 and revenue marts further downstream. The single-hop query *silently understates the impact.* In an incident, that is a dangerous answer.

Now traverse the full chain explicitly. Each `MATCH` clause picks up where the previous one left off:

```cypher
// Full downstream lineage of orders_raw, across all layers
MATCH (:TableAsset {name: 'orders_raw'})<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l1:TableAsset)
OPTIONAL MATCH (l1)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(l2:TableAsset)
WITH collect(DISTINCT l1.name) + collect(DISTINCT l2.name) AS assets
UNWIND assets AS a
MATCH (t:TableAsset {name: a})-[:POWERS]->(d:Dashboard)
RETURN DISTINCT d.name AS dashboard;
```

**Expected result** (three rows, in any order).

| dashboard |
|---|
| Sales Dashboard |
| Customer Health Dashboard |
| Executive Revenue Dashboard |

This reaches **Sales**, **Customer Health**, and **Executive Revenue**, the true downstream footprint. The lesson lands on its own: with connected data, the depth of the answer must match the depth of the dependency, and graph traversal makes that depth explicit instead of hidden.

## 4.3 Lineage queries

**Immediate upstream of `customer_360`:**

```cypher
MATCH (p:Pipeline)-[:WRITES_TO]->(:TableAsset {name: 'customer_360'})
MATCH (p)-[:READS_TABLE]->(src:TableAsset)
RETURN p.name AS pipeline, collect(src.name) AS upstream_tables;
```

**Expected result.**

| pipeline | upstream_tables |
|---|---|
| `build_customer_360` | `[customers_curated, orders_curated]` |

**Which tables power the Sales Dashboard:**

```cypher
MATCH (t:TableAsset)-[:POWERS]->(:Dashboard {name: 'Sales Dashboard'})
RETURN t.name AS table_asset;
```

**Expected result** (two rows, in any order).

| table_asset |
|---|
| `orders_curated` |
| `customer_360` |

**Which source systems ultimately influence the Customer Health Dashboard**, a full three-layer traversal. Note how the first hop uses `READS_SYSTEM` and the inner hops use `READS_TABLE`; the single-pair design makes each step's intent unambiguous:

```cypher
MATCH (s:System)<-[:READS_SYSTEM]-(:Pipeline)
      -[:WRITES_TO]->(raw:TableAsset)
MATCH (raw)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(cur:TableAsset)
MATCH (cur)<-[:READS_TABLE]-(:Pipeline)-[:WRITES_TO]->(mart:TableAsset)
      -[:POWERS]->(:Dashboard {name: 'Customer Health Dashboard'})
RETURN DISTINCT s.name AS source_system;
```

**Expected result.**

| source_system |
|---|
| CRM |

## 4.4 The SQL comparison exercise

Do not frame this as "graph replaces SQL." Frame it as "graph reduces cognitive load for connected questions." Ask the team to sketch the full-downstream `orders_raw` query as a SQL self-join chain across the three layers. Then compare. The point is not syntax novelty: it is that the graph query *expresses the dependency path directly and stays readable*, while the join chain's intent disappears into its mechanics. Tie this back to the decision rule in Part I.

## 4.5 Validation checklist

- [ ] The team can explain the difference between upstream and downstream lineage.
- [ ] They can trace a path from a source system to a finance-facing dashboard.
- [ ] They can articulate *why* the single-hop query understated impact, and fix it.
- [ ] They can explain why the graph query is easier to reason about than the equivalent join chain here.

**Discussion prompts.** Which questions genuinely benefit from traversal, and which are still better in tabular analytics? At what path depth does the graph begin to pay for itself? Where would variable-length or recursive traversal serve better than explicit hops?
