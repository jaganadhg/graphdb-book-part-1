# Preface: How to read this book

This is a short, practical book with one purpose: to take a data engineering team that thinks fluently in tables, joins, and pipelines, and give them working competence (and sound judgment) in graph data, using a problem they already own.

It is built around a single claim, defended in Part I: **graph is not a better database; it is a better *representation* for one class of question: multi-hop dependency and impact.** Everything that follows teaches that judgment alongside the mechanics.

The book is written for two audiences, and it is structured so each can take what they need:

Part I is written for both groups: data leaders and executives as well as data engineers. The hands-on parts that follow give data engineers direct, practical exposure to graph databases, and a set of appendices supports every reader with the underlying concepts. The book's aim is to approach graph databases from a different angle: instead of the usual movie or social-network examples, you will learn them through a data platform you already understand, in scenarios you already recognize.

The seven parts are cumulative and stay inside one business context (a small internal data platform) so the team builds intuition instead of resetting every session. Total hands-on time is roughly four to five hours.

**A note on the technology.** The book uses LadybugDB, an open-source, embedded property-graph database (MIT-licensed, built on the Kùzu engine). It needs no server, runs locally, and loads from CSV, which keeps the focus on modeling and reasoning rather than infrastructure. All commands and syntax in this book were checked against the LadybugDB documentation; version-specific details are noted where they matter.

**Where to get the code.** The book's source, the Cypher queries, the dataset, and the Python code are all available at <https://github.com/jaganadhg/graphdb-book-part-1>. You can read the book without it, but having the repository open makes the hands-on parts faster.
