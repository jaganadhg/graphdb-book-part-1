# Appendix C: Where to go next

Once the team completes the core program, extend the dataset in ways that preserve realism and build on the same graph shape:

- Add freshness timestamps and SLA metadata to assets.
- Introduce **variable-length and recursive traversal** in place of explicit hop-by-hop patterns: the natural next capability once the team is comfortable with fixed-depth paths.
- Add data products or domains as a layer above table assets.
- Add quality incidents or alerts as first-class nodes.
- Add cross-orchestration pipeline dependencies, and job-run history.
- Add ML features or user-facing reports as additional downstream consumers.
- Explore Ladybug Explorer (Part VII) to visualize the metadata graph, and consider the LadybugDB MCP server if the team wants an LLM agent to answer lineage questions in natural language.
