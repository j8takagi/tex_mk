# HTMLファイルで使うCSSファイルを指定
CSS := style.css

.PHONY: all clean distclean

.SECONDERY: latex_mk.tex

all: latex_mk.html latex_mk.pdf

include texinfo.mk

latex_mk.html latex_mk_html: $(CSS)

clean: texinfo-clean

distclean: texinfo-distclean
