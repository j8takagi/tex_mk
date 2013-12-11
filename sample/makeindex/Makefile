TEXTARGETS := makeindex.pdf

.PHONY: all index-update rebase index-rebase tex-update tex-rebase clean distclean

CMP := cmp -s
SED := sed

$(TEXTARGETS):

all:
	@$(MAKE) -s makeindex_1.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s makeindex_2.pdf
	@$(ECHO) '--------------------'
	@$(MAKE) -s makeindex_3.pdf

makeindex_1.pdf: rebase
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s makeindex.pdf
	@$(CP) -v makeindex.pdf $@

makeindex_2.pdf: body-update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s makeindex.pdf
	@$(CP) -v makeindex.pdf $@

makeindex_3.pdf: index-update
	@$(ECHO) '---------- $@: $^ ----------'
	@$(MAKE) -s makeindex.pdf
	@$(CP) -v makeindex.pdf $@

body-update:
	$(SED) -i.bak -e 's/本文変更なし。/本文を変更。/' makeindex.tex

index-update:
	$(SED) -i.bak -e 's/楽譜の/楽譜\\index{がくふ@楽譜}の/' makeindex.tex

rebase:
	$(CMP) makeindex.tex.base makeindex.tex || $(CP) makeindex.tex.base makeindex.tex

include latex.mk

clean: tex-clean rebase
	$(RM) *.bak

distclean: clean tex-distclean
	$(RM) makeindex_*.pdf
