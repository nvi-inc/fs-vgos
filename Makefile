all: pdf html docx slides
.PHONY: all

docx/%.docx: %.md
	pandoc -S -o $@ $<
	
pdf/%.pdf: %.md header.tex
	pandoc -H header.tex\
		--latex-engine-opt '-shell-escape'\
		--filter pandoc-minted\
		-V subparagraph -V verbatim-in-note --number-sections $< -o $@
	# pandoc -V subparagraph $< -o $@
	# pandoc  -H header.tex -V subparagraph -V classoption=twocolumn $< -o $@

html/%.html: %.md html/style.css
	pandoc --toc -t html5 -S -c style.css $< -o $@

html/style.css: style.css
	cp style.css html/style.css
	
slides/%.html: %.md style.css
	pandoc --self-contained -S -c style.css --mathjax -t slidy -o $@ $<

DOCX := $(patsubst %.md,docx/%.docx,$(wildcard *.md))
PDF := $(patsubst %.md,pdf/%.pdf,$(wildcard *.md))
HTML := $(patsubst %.md,html/%.html,$(wildcard *.md))
SLIDES := $(patsubst %.md,slides/%.html,$(wildcard *.md))



pdf: $(PDF)
html: $(HTML)
docx: $(DOCX)
slides:  $(SLIDES)
