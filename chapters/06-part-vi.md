# Part VI: The Vocabulary, in Hindsight

## 6.1 Why this chapter is last

Most database books open with definitions. This one ends with them, on purpose.

If you have worked through Parts III to V, you have already created node tables, declared relationship types, loaded a graph, and traced a five-hop path through it. You did not need the formal vocabulary to do any of that, the platform scenario carried you. So this chapter is not an introduction to ideas you lack. It is the chapter that *names* the ideas you have already been using, so you can talk about them precisely, recognize them in someone else's graph, and read the LadybugDB documentation without translation.

Think of it as the glossary you earned. Every term below is defined against something concrete you have already done.

## 6.2 The property graph model, in one picture

A property graph is built from exactly three things:

- **Nodes**: the entities. In our graph: a `Pipeline`, a `TableAsset`, a `Team`.
- **Edges**: the connections between entities, also called relationships. In our graph: a pipeline `WRITES_TO` a table.
- **Properties**: typed key-value facts attached to a node or an edge. In our graph: a `TableAsset` has a `layer` of `"raw"` and a `domain` of `"customer"`.

```{=latex}
\begin{figure}[ht]
\centering
\begin{tikzpicture}[node distance=26mm]
  \node[gbnode] (p) {Pipeline};
  \node[gbnode, right=of p] (t) {TableAsset};
  \node[gbnode, right=of t] (d) {Dashboard};
  \draw[gbedge] (p) to[bend left=35] node[gblabel]{WRITES\_TO} (t);
  \draw[gbedge] (t) to[bend left=35] node[gblabel]{POWERS} (d);
  \node[font=\scriptsize\ttfamily, text=gray!60, align=center, below=7mm of t]
    (props) {layer = "raw"\\domain = "order"};
  \draw[draw=gray!45, dashed, line width=0.5pt] (props) -- (t);
\end{tikzpicture}
\caption{The property graph model in miniature: nodes (the boxes), edges that connect them (the curved arrows \texttt{WRITES\_TO} and \texttt{POWERS}), and properties attached to a node (the dashed callout).}
\label{fig:propertygraph}
\end{figure}
```

That is the whole model. Everything in Parts III to V (every schema line, every `MATCH`, every blast-radius query) is just nodes, edges, and properties arranged and traversed. The reason the model felt natural is that it matches how you already *talk* about a platform: "the ingest pipeline writes the raw customer table." Subject, relationship, object. The graph stores that sentence as-is.

## 6.3 Nodes and node tables: a table you already know

A **node** is one entity: one pipeline, one dashboard. A **node table** is the set of all nodes of the same kind, with the same property schema.

Here is the part that should feel familiar: *a node table is a relational table.* When you wrote

```cypher
CREATE NODE TABLE TableAsset(
  id STRING, name STRING, layer STRING, domain STRING,
  PRIMARY KEY (id)
);
```

you created something almost identical to a SQL `CREATE TABLE`: named columns, declared types, a primary key. `table_assets.csv` loaded into it exactly the way a CSV loads into a relational table. If you opened the `TableAsset` node table and ignored the rest of the graph, you would see a perfectly ordinary table of eight rows.

The **primary key** is not a graph nicety. LadybugDB *requires* one on every node table, and for the same reason SQL wants one: every node must be unambiguously identifiable, because edges point at nodes by their key. When `writes_to.csv` says `pl_ingest_crm,tbl_customers_raw`, those are two primary keys. No keys, no edges.

So the mental model is simple: **you already know what a node table is. You have been building them for years. The graph just adds a way to connect them as first-class structure.**

## 6.4 Edges and relationship tables: the join you decided to keep

This is the term that actually changes how you think, so it is worth slowing down.

In the relational world, a connection between two tables is *implied*. `orders_raw` relates to `orders_curated` because some pipeline's SQL happens to join them. The connection is real, but it is not a thing you can point at: it lives inside query logic, recomputed every time, and invisible until someone reads the code.

An **edge** is that connection promoted to a stored, named, first-class object. When you wrote `CREATE REL TABLE WRITES_TO(FROM Pipeline TO TableAsset)`, you did not describe a query: you declared that "a pipeline writes to a table" is a *fact the database stores directly*, the same way it stores a row.

A **relationship table** is the set of all edges of one type, just as a node table is the set of all nodes of one type. `writes_to.csv` loaded into the `WRITES_TO` relationship table; its first two columns were the `FROM` key and the `TO` key, and that is the whole shape of an edge.

The practical consequence is the entire reason this book exists. Because the dependency is *stored* rather than *implied*, you can traverse it without reconstructing it. The Part V blast-radius query did not join billing to dashboards through five layers of SQL logic: it walked five edges that were already there. **An edge is a join you decided was important enough to keep.**

## 6.5 Properties and types: typed columns, on edges too

A **property** is a typed key-value fact. Nodes carry them: a `Pipeline` has a `mode` and a `schedule`. Edges *can* carry them too: had we modelled a `WRITES_TO` edge with a `last_run` timestamp, that timestamp would be an edge property. Our teaching model keeps edges bare, but the capability is there, and Appendix C's SLA-and-freshness extension is exactly where you would use it.

Properties are **strongly typed** (`STRING`, `INT64`, `DATE`, and so on) declared in the schema and enforced at load. This is the same discipline a SQL schema gives you, and it is why Part III insisted on `(header=true)`: a typed loader has to be told which line is data.

## 6.6 Direction: edges have a FROM and a TO

Every edge runs *from* one node *to* another. `WRITES_TO` goes `FROM Pipeline TO TableAsset`, never the reverse. Direction is declared once, in the schema, and it encodes meaning: a pipeline writes a table; a table does not write a pipeline.

But (and this is the point that retired the `DEPENDS_ON` edge back in Part III) *storing* an edge in one direction does not stop you *traversing* it in the other. In Cypher, `-[:POWERS]->` walks the edge forward and `<-[:POWERS]-` walks it backward. "What does this table power?" and "what powers this dashboard?" are one stored edge, read two ways. Direction is a fact about meaning, not a restriction on questions.

## 6.7 Patterns and traversal: MATCH is the verb

The last piece of vocabulary is how you *ask*.

A **pattern** is a small drawing of the graph shape you are looking for, written in ASCII. `(p:Pipeline)-[:WRITES_TO]->(t:TableAsset)` is a pattern: a pipeline node, a `WRITES_TO` edge, a table node. **Traversal** is the act of walking edges from node to node. A **path** is the trail a traversal produces: the chain of nodes and edges from a source to a destination.

`MATCH` is the verb that does it. You hand `MATCH` a pattern and it finds every place in the graph that fits. This is the deep difference from SQL worth saying outright:

> In SQL you describe *how to combine tables* (which joins, in which order) to assemble the answer. In Cypher you draw *the shape of the answer* and let the engine find it.

That is why the Part IV lineage query stayed readable while its SQL equivalent (a five-way self-join) did not. The graph query *looked like* the dependency chain it was asking about. The join chain looked like machinery.

## 6.8 Existence and universality: "is there..." and "is it always..."

Two questions run underneath almost every governance and incident conversation a platform team has. The first is *is there a...*: is there a pipeline with no owner, is there a dashboard whose lineage is broken. The second is *is it always true that...*: is **every** mart table powered by a dashboard, does **every** pipeline have an output. Logicians call these the existential quantifier (∃, "there exists") and the universal quantifier (∀, "for all"). You will never need the symbols, but the two shapes are worth recognizing on sight, because Cypher expresses them more directly than SQL does, and because they turn out to be the validation checklists you have been running by hand since Part III.

**Existence: `EXISTS { }`.** An existence check asks whether *at least one* match exists, without returning it. It is a pattern used as a yes/no test inside `WHERE`. "Which pipelines read from at least one raw-layer table?"

```cypher
MATCH (p:Pipeline)
WHERE EXISTS { MATCH (p)-[:READS_TABLE]->(t:TableAsset)
               WHERE t.layer = 'raw' }
RETURN p.name AS pipeline;
```

**Expected result** (three rows, in any order).

| pipeline |
|---|
| `curate_customers` |
| `curate_orders` |
| `curate_payments` |

The inner pattern is not asked to *produce* anything: it is asked only *does this exist*. That is the existential quantifier: ∃ a raw table this pipeline reads.

**Non-existence: `NOT EXISTS { }`, the orphan finder.** Negate the test and you get one of the most operationally valuable queries a metadata graph can answer: *find the things that are missing a connection.* "Which table assets power no dashboard at all?"

```cypher
MATCH (t:TableAsset)
WHERE NOT EXISTS { MATCH (t)-[:POWERS]->(:Dashboard) }
RETURN t.name AS table_asset, t.layer AS layer;
```

**Expected result** (five rows, in any order).

| table_asset | layer |
|---|---|
| `customers_raw` | `raw` |
| `orders_raw` | `raw` |
| `payments_raw` | `raw` |
| `customers_curated` | `curated` |
| `payments_curated` | `curated` |

Run as-is, this returns every raw and curated table, which is correct, since by design only mart tables power dashboards. The *interesting* version narrows to the layer where a missing edge is a real finding: a mart table that powers nothing is a candidate for deprecation.

```cypher
MATCH (t:TableAsset)
WHERE t.layer = 'mart'
  AND NOT EXISTS { MATCH (t)-[:POWERS]->(:Dashboard) }
RETURN t.name AS unpowered_mart;
```

**Expected result:** no rows. By design every mart table powers a dashboard, so nothing comes back.

The same shape finds ownership gaps: a dashboard nobody is on the hook for, which during an incident means nobody to page:

```cypher
MATCH (d:Dashboard)
WHERE NOT EXISTS { MATCH (:Team)-[:OWNS_DASHBOARD]->(d) }
RETURN d.name AS dashboard;
```

**Expected result:** no rows — every dashboard has an owning team in this dataset.

**Universality: there is no `FOR ALL` keyword, and you do not need one.** This is the part worth slowing down on, because it is a genuinely useful piece of logic. Cypher has no universal quantifier. It does not need one, because of an identity every engineer can verify in their head:

> *"Every X has property P"* is exactly the same statement as *"there is no X that lacks property P."*  In symbols, ∀x.P(x) ≡ ¬∃x.¬P(x).

So a universal check is a `NOT EXISTS` looking for a *counterexample*. To ask "is every mart table powered by a dashboard?", you do not try to confirm all of them: you go looking for one that fails, and an empty result *is* the confirmation:

```cypher
// Universal check: every mart table should power a dashboard.
// This query searches for a violation. An empty result means the rule holds.
MATCH (t:TableAsset)
WHERE t.layer = 'mart'
  AND NOT EXISTS { MATCH (t)-[:POWERS]->(:Dashboard) }
RETURN t.name AS unpowered_mart_table;
```

**Expected result:** no rows. The empty result *is* the confirmation: every mart table powers a dashboard, so the rule holds.

That is the entire trick: **prove a "for all" by failing to find a counterexample.** It is also why the orphan-finder above is more than a cleanup tool: every `NOT EXISTS` query is simultaneously a universal-rule check.

If you would rather see the rule pass explicitly than read an empty table, count instead: a "for all" holds when the count of things satisfying it equals the count of all things:

```cypher
MATCH (p:Pipeline)
WITH count(p) AS total_pipelines
MATCH (p:Pipeline)
WHERE EXISTS { MATCH (p)-[:WRITES_TO]->(:TableAsset) }
RETURN total_pipelines,
       count(p)                       AS pipelines_with_output,
       total_pipelines = count(p)      AS every_pipeline_writes;
```

**Expected result.**

| total_pipelines | pipelines_with_output | every_pipeline_writes |
|---|---|---|
| 7 | 7 | true |

**Quantifying over a collected set: `ALL`, `ANY`, `NONE`.** The quantifiers above range over nodes in the graph. Cypher also lets you quantify over the items of a *list* you have assembled, with the predicates `ALL`, `ANY`, and `NONE`: the list-level echoes of ∀, ∃, and ¬∃. Collect a pipeline's input layers, then test them as a set: "which pipelines read **only** curated tables?"

```cypher
MATCH (p:Pipeline)-[:READS_TABLE]->(t:TableAsset)
WITH p, collect(t.layer) AS input_layers
WHERE ALL(layer IN input_layers WHERE layer = 'curated')
RETURN p.name AS pipeline, input_layers;
```

**Expected result** (two rows, in any order).

| pipeline | input_layers |
|---|---|
| `build_customer_360` | `[curated, curated]` |
| `build_revenue_daily` | `[curated, curated]` |

This isolates the mart-building pipelines, since those are the ones whose every input is curated. Swap `ALL` for `ANY` and the question becomes "reads at least one curated table"; swap in `NONE` and it becomes "reads no curated table": the same three quantifier shapes, now applied to a collection rather than the graph.

The reason this section belongs in the vocabulary chapter is that you have *already written its questions*, in prose, in every validation checklist since Part III. "Does every pipeline have an output edge?" "Does each dashboard have an upstream path?" Those were universal claims checked by eye. You now know they are one `NOT EXISTS` query each, and that a metadata graph can audit its own integrity on demand.

## 6.9 The relational translation table

Everything above, in one place. If you think in the left column, the right column is your bridge.

| You already know (relational) | The graph term | In this book |
|---|---|---|
| Table | Node table | `TableAsset`, `Pipeline`, `Team` |
| Row | Node | one pipeline, `pl_ingest_crm` |
| Column | Property | `layer`, `domain`, `schedule` |
| Primary key | Node primary key (required) | `id` on every node table |
| Foreign key | Edge / relationship | `WRITES_TO`, `POWERS`, `OWNS_PIPELINE` |
| A JOIN written in a query | A stored, named edge | the `writes_to.csv` rows |
| Join table (many-to-many) | Relationship table | the `WRITES_TO` table |
| Multi-table JOIN | Traversal / path | the Part V blast-radius query |
| `SELECT ... FROM ... JOIN ...` | `MATCH` a pattern | every query in Parts III–V |
| Query plan deciding join order | The engine walking the pattern | what runs under `MATCH` |

The one row that carries the whole book is the fifth: **a foreign key is an edge.** Relational design *has* the connection; it just keeps it implied and recomputes it on every query. Graph design *stores* it. Once the connection is stored, traversing four or five of them in a row stays as readable as traversing one, and that is the entire reason a metadata graph answers "what breaks?" in one query instead of one hour.

## 6.10 Three things with no clean tabular equivalent

If the translation table were the whole story, graph would just be SQL with friendlier syntax. It is worth ending on the three places where the graph genuinely does something tabular thinking cannot do cheaply, because these are the places the Part I decision rule is pointing at.

**Variable-length traversal.** Cypher can walk "between one and any number of `READS_TABLE` edges" in a single short pattern. The Part IV lineage query spelled its hops out explicitly because our platform has exactly three layers, but a real catalog does not have a fixed depth, and that is precisely the case the decision rule reserves for graph: *the traversal depth is unknown ahead of time.* In SQL, an unknown number of joins means recursive CTEs, and readability falls off a cliff.

**Shortest path.** "What is the shortest dependency chain from Billing to the Executive Revenue Dashboard?" is a native graph question. There is no natural `SELECT` for it.

**The same structure, asked many ways.** You loaded the platform graph once. Part IV asked it upstream and downstream; Part V asked it for blast radius and ownership. No new schema, no new join logic: the same stored edges, traversed from different starting points. That reuse is the third clause of the decision rule, and it is what makes a metadata graph worth building rather than just querying once.

These three are the graph's home ground. Everywhere else (fixed-shape joins, aggregation, set operations, transformation) SQL remains the right tool, exactly as Part I said. You now have both the vocabulary to tell the two apart and the experience, from Parts III to V, to trust the judgment.
