# HTMLファイルで使うCSSファイルを指定
CSS := style.css

# General commands
SED := sed

.PHONY: all clean distclean

TEXITARGETS := tex_mk.html tex_mk.pdf

all: $(TEXITARGETS)

include texinfo.mk

commands.texi: ../tex.mk
	$(SED) -n -e '/^# TeX commands/,/^$$/p' $< | sed -e '/^#/d' -e '/^$$/d' >$@

tex_mk.html tex_mk_html: $(CSS)

clean: texi-clean

distclean: texi-distclean
