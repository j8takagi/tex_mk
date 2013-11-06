# texファイルから作成されるpdfまたはdviファイルを
# ターゲットファイルとして指定
#
# make および make all でのターゲットファイルになるほか、
# latex.mkで、ターゲットファイルに対応する依存関係が
# .dファイルに書き出される。
# また、tex-distcleanの削除対象になる。
#
# 初期設定では、ディレクトリにあるすべてのtexファイル
TARGETS := $(subst .tex,.pdf,$(wildcard *.tex))

.PHONY: all clean distclean

all: $(TARGETS)

include latex.mk

clean: tex-clean

distclean: tex-distclean
