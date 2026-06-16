# Part I: The Case for Graph

## 1.1 The question nobody can answer fast enough

It is 9:15 AM on a Tuesday. The billing extract that normally lands at 6:00 AM has not arrived. Within twenty minutes the question on the incident channel is the one that always comes up and never gets answered cleanly: *what does this break, and who needs to know?*

The honest answer, in most teams, is a small archaeology project. Someone opens a pipeline repo. Someone else greps the warehouse for tables with "payment" in the name. A third person tries to remember which dashboards the finance team cares about. The dependency structure of the platform exists, but it lives in scattered code, in naming conventions, and in the heads of whoever has been around longest. None of that is queryable, and none of it survives an org change.

This book is about turning that structure into something you can ask questions of directly.

## 1.2 The thesis

> **Graph is not a better database. It is a better *representation* for one class of question: multi-hop dependency and impact.**
>
> A mature team should be able to say precisely when that class of question justifies the model, and when it does not. This book teaches that judgment, not just the syntax. By the end, *"what breaks if this upstream asset changes?"* should register immediately as a connected-data problem, with a known way to answer it.

Most graph tutorials fail data teams because they teach the technology on a domain the team will never own (movies, actors, social follows) and the learner never makes the leap back to their own systems. This book inverts that. Lineage, ownership, and downstream risk are already real and already painful in a data platform, so the model has somewhere to land.

## 1.3 Executive briefing

*This section is for engineering and data leaders deciding whether the capability is worth the team's time. It requires no graph or database background.*

**The problem.** Every data platform accumulates a dependency structure (sources feeding pipelines feeding tables feeding dashboards) that no single person fully holds. When a feed is late, a schema changes, or a migration is proposed, the team answers "what is affected and who owns it" by pinging several people and reading join logic nobody enjoys reading. That tribal knowledge is an operational risk. It slows incident response, makes change estimation guesswork, and walks out the door when people leave.

**What this capability changes.** Making the dependency structure explicit and queryable turns three recurring activities from hours into minutes:

| Activity | Today | With a metadata graph |
|---|---|---|
| Incident impact assessment | Manual tracing across repos and the warehouse | One query: affected tables, dashboards, owning teams |
| Pre-migration change risk | Guesswork, often discovered in production | Quantified blast radius before the change ships |
| Governance and audit lineage requests | Bespoke investigation each time | A standing, traversable lineage model |

**The investment.** One short enablement program (roughly four to five hours of facilitated sessions plus setup) using a free, open-source, embedded database that needs no servers or infrastructure. The output is both a trained team and a small working metadata graph that can grow toward production use.

**The honest boundary.** This is not a recommendation to move the platform onto a graph database. Graph is being introduced for a *specific, narrow* purpose where it clearly outperforms repeated SQL joins. The decision rule below is the deliverable that matters most: it keeps the team from over-applying the tool.

## 1.4 The decision rule: when graph, when SQL

Reach for graph when **all three** are true:

1. The question is about **paths**, not rows: "what is connected to what," not "what are the values."
2. The traversal **depth is variable or unknown** ahead of time, so you cannot write the join count in advance.
3. The same connected structure will be **queried many different ways**: upstream, downstream, by owner, by blast radius.

Stay in SQL when the question is a **fixed two- or three-table join that will not change shape.** SQL remains the right tool for set-based transformation, filtering, aggregation, and data shaping. Graph's payoff begins roughly where a join chain stops being readable, typically three or more hops with branching. If you can comfortably write and maintain the join, you do not need a graph.

This rule is the spine of the book. Return to it whenever the team is tempted to model something as a graph simply because it *can* be.
