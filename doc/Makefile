# HTMLファイルで使うCSSファイルを指定
CSS := style.css

TEX := ptex
TEXINDEX := texindex

# General commands
SED := sed

.PHONY: all clean distclean

TEXITARGETS := tex_mk.html tex_mk.pdf

tex_mk.dvi: tex_mk.texi tex_mk.cps
	$(TEX) $<

tex_mk.cps: tex_mk.texi
	$(CP) $@ $@_prev
	$(TEX) $<
	$(TEXINDEX) $(subst .texi,.cp,$<)
	$(TEX) $<
	$(TEXINDEX) $(subst .texi,.cp,$<)

all: $(TEXITARGETS)

include texinfo.mk

include db2epub.mk

commands.texi: ../tex.mk
	$(SED) -n -e '/^# TeX commands/,/^$$/p' $< | sed -e '/^#/d' -e '/^$$/d' >$@

tex_mk.html tex_mk_html: $(CSS)

clean: texi-clean db2epub-clean
	$(RM) commands.texi

distclean: texi-distclean db2epub-distclean
