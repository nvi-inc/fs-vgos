all: pdf html docx
.PHONY: all


MDFLAGS = 

%.docx: %.md
	pandoc -f markdown+smart -o $@ $<
	
# %.pdf: %.md
# 	pandoc \
# 		--toc \
# 		--number-sections \
# 		-t context\
# 		$< -o $@
#

%.tex: %.md header.tex
	pandoc -f markdown+smart\
		-H header.tex\
		--toc \
		--toc-depth=2 \
		--listings \
		-V fontsize=12pt\
		-V subparagraph \
		-V verbatim-in-note \
		--number-sections \
		$< -o $@

%.pdf: %.md header.tex
	pandoc -f markdown+smart \
		-H header.tex\
		--toc \
		--toc-depth=2 \
		--listings \
		--pdf-engine=xelatex\
		--pdf-engine-opt '-shell-escape'\
		--metadata date="$(shell date -r $< +%F)" \
		-V subparagraph \
		-V verbatim-in-note \
		--number-sections \
		$< -o $@
		# -V fontsize=12pt\
	#--filter pandoc-minted
		# --latex-engine=lualatex\
	# pandoc -V subparagraph $< -o $@
	# pandoc  -H header.tex -V subparagraph -V classoption=twocolumn $< -o $@

%.html: %.md
	pandoc  -f markdown+smart --toc --highlight-style monochrome -t html5 -c style.css $< -o $@
	
%.html: %.md style.css
	pandoc --self-contained -S -c style.css --mathjax -t slidy -o $@ $<

DOCX := $(patsubst %.md,%.docx,$(wildcard *.md))
PDF := $(patsubst %.md,%.pdf,$(wildcard *.md))
TEX := $(patsubst %.md,%.tex,$(wildcard *.md))
HTML := $(patsubst %.md,%.html,$(wildcard *.md))
SLIDES := $(patsubst %.md,%.html,$(wildcard *.md))

tex: $(TEX)


pdf: $(PDF)
html: $(HTML)
docx: $(DOCX)
slides:  $(SLIDES)
