TEXTARGETS := simple.pdf

CMP := cmp -s
SED := sed

.PHONY: all update rebase clean distclean

all: $(TEXTARGETS)

update:
	$(SED) -i.bak -e 's/，/、/g' -e 's/．/。/g' simple.tex

rebase:
	$(CMP) simple.tex.base simple.tex || $(CP) simple.tex.base simple.tex

include tex.mk

clean: rebase tex-clean
	$(RM) *.bak

distclean: clean tex-distclean
	$(RM) simple_*.pdf
