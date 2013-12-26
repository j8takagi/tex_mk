TEXTARGETS := makeindex.pdf

.PHONY: all rebase index-update body-update clean distclean

CMP := cmp -s
ECHO := echo
SED := sed

all: $(TEXTARGETS)

body-update:
	$(SED) -i.bak -e 's/本文変更なし。/本文を変更。/' makeindex.tex && $(ECHO) 'makeindex.tex body is updated.'

index-update:
	$(SED) -i.bak -e 's/楽譜の/楽譜\\index{がくふ@楽譜}の/' makeindex.tex && $(ECHO) 'makeindex.tex index is updated.'

rebase:
	$(CMP) makeindex.tex.base makeindex.tex || $(CP) makeindex.tex.base makeindex.tex

include tex.mk

clean: tex-clean rebase
	$(RM) *.bak

distclean: clean tex-distclean
	$(RM) makeindex*.pdf
