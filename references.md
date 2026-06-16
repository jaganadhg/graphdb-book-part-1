# References

- LadybugDB documentation, home and overview: <https://docs.ladybugdb.com/>
- Installation guide (CLI, Python, and other clients): <https://docs.ladybugdb.com/installation>
- System requirements: <https://docs.ladybugdb.com/system-requirements>
- Create your first graph: <https://docs.ladybugdb.com/get-started>
- Command Line Interface reference: <https://docs.ladybugdb.com/client-apis/cli>
- Importing data from CSV (`COPY FROM`): <https://docs.ladybugdb.com/import/csv>
- Ladybug Explorer documentation: <https://docs.ladybugdb.com/visualization/lbug-explorer>
- Third-party visualization integrations (yFiles Jupyter Graphs, G.V()): <https://docs.ladybugdb.com/visualization/third-party-integrations/yfiles>
- Source, releases, and license: <https://github.com/LadybugDB/ladybug>

*LadybugDB is open-source under the MIT License and is built on the Kùzu engine. Commands and syntax in this book were checked against the documentation above; confirm version-specific behaviour against the docs for your installed release.*

# Use of generative AI tools

This book was prepared with assistance from generative AI tools (Anthropic's Claude). That assistance was limited to:

- **Brainstorming and planning:** shaping the structure, scope, and teaching approach.
- **Language and copy editing:** tightening the prose for clarity and consistency.
- **Typesetting and build automation:** the LaTeX and Tectonic build pipeline, the diagrams, code formatting, and page layout.

The technical substance (the data model, the Cypher queries, the dataset, and the judgments the book argues for) was directed and verified by the author against the LadybugDB documentation and a working database.

```{=latex}
\clearpage
\thispagestyle{empty}
\begin{tikzpicture}[remember picture, overlay]
  \node[anchor=center, inner sep=0pt] at (current page.center)
    {\includegraphics[width=\paperwidth, height=\paperheight]{back-cover.png}};
  \node[anchor=north, text width=0.78\paperwidth, align=center]
    at ([yshift=-1.15cm]current page.north)
    {\sffamily\bfseries\color{gbNode}\fontsize{13}{16}\selectfont
       Lineage, blast radius, and graph thinking for the data platform you already own.};
\end{tikzpicture}
\null
```
