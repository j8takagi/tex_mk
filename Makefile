# TEXTARGETS:
# texファイルから作成されるpdfまたはdviファイル
#
# make および make all でのターゲットファイルになるほか、
# latex.mkで、ターゲットファイルに対応する依存関係が
# .dファイルに書き出される。
# また、tex-distcleanの削除対象になる。
#
# 初期設定では、ディレクトリにあるすべてのtexファイル
TEXTARGETS := $(subst .tex,.pdf,$(wildcard *.tex))

.PHONY: all clean distclean

all: $(TEXTARGETS)

include latex.mk

clean: tex-clean

distclean: tex-distclean
