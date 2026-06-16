# Graph for the Data You Already Own

*A short book on Graph Data for Working Data Engineers, with LadybugDB.*

*An enablement guide, written for engineers, openable by executives.*

*by [Author] · Draft*

---

## What this book teaches

One claim runs through every chapter:

> **Graph is not a better database. It is a better *representation* for one class of question: multi-hop dependency and impact.** A mature team should be able to say precisely when that class justifies the model, and when it does not.

The book teaches that judgment alongside the mechanics, using the team's own platform metadata (systems, pipelines, tables, dashboards, owning teams) rather than an unrelated toy domain.

## Who this is for

- **Executives and engineering leaders.** Read Part I in full. It makes the business case, states the thesis, and gives a decision rule. No database background required, no code.
- **The data engineering team.** Work through all seven parts, ideally as a facilitated program. Parts II–V and VII are hands-on; Part VI is the vocabulary chapter.
- **If you're the one running the program**, also read Appendix B, the delivery and facilitation guide.

## How the book is organized

Seven parts and four appendices. Parts I–V form the core teaching path: a strategic case followed by a hands-on program that builds a small metadata graph and uses it for lineage and blast-radius analysis. Part VI names the formal vocabulary in hindsight, against the graph the team has already built. Part VII layers on visualization with the browser-based Ladybug Explorer.

See the table of contents for full section-level detail.

## Time required

Roughly four to five hours of facilitated sessions, plus setup. Appendix B includes a four-session schedule.

## Technology

[LadybugDB](https://docs.ladybugdb.com/): an open-source (MIT), embedded property-graph database built on the Kùzu engine. No server, runs locally, loads from CSV. All commands in this book were checked against the current LadybugDB documentation.
