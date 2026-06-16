# Book build: markdown -> pandoc -> LaTeX -> tectonic -> PDF.

SRC := 00-preface.md \
       01-part-i.md 02-part-ii.md 03-part-iii.md \
       04-part-iv.md 05-part-v.md 06-part-vi.md \
       07-part-vii.md \
       08-beyond-ladybugdb.md \
       app-a.md app-b.md app-c.md app-d.md \
       references.md

PANDOC_FLAGS := --from=markdown \
                --top-level-division=chapter \
                --syntax-definition=syntax/cypher.xml \
                --highlight-style=tango \
                --metadata-file=metadata.yaml \
                --include-in-header=preamble.tex \
                --include-before-body=cover-front.tex \
                --toc \
                --standalone

.PHONY: pdf tex clean

tex: build/book.tex

pdf: build/book.pdf

build/book.tex: $(SRC) metadata.yaml preamble.tex cover-front.tex syntax/cypher.xml | build
	pandoc $(PANDOC_FLAGS) -o $@ $(SRC)

build/book.pdf: build/book.tex assets/front-cover.png assets/back-cover.png
	tectonic build/book.tex --outdir build

build:
	mkdir -p build

clean:
	rm -rf build
