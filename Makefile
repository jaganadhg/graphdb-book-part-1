# Book build: markdown -> pandoc -> LaTeX -> tectonic -> PDF.
# Chapter sources live in chapters/; readme.md and toc.md there are front
# matter and are intentionally excluded from the build.

CHAPTERS := chapters
NAMES := 00-preface \
         01-part-i 02-part-ii 03-part-iii 04-part-iv 05-part-v \
         06-part-vi 07-part-vii 08-beyond-ladybugdb \
         app-a app-b app-c app-d \
         references
SRC := $(addprefix $(CHAPTERS)/,$(addsuffix .md,$(NAMES)))

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
