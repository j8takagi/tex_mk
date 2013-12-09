.PHONY: all clean distclean

FIND := find
ECHO := /bin/echo
# 複数の子ディレクトリーでmakeを実行
# 用例: $(call make_dirs,list_dir,target,options)
define make_dirs
    $(foreach d,$1,$(ECHO) '---------- $d ----------'; $(MAKE) $3 -C $d $2; )
endef

# テスト名。カレントディレクトリー内の、名前が大文字または.以外で始まるディレクトリー
TESTS = $(notdir $(shell $(FIND) -maxdepth 1 -name "[^A-Z.]*" -type d))

all:
	@$(call make_dirs,$(TESTS),$@,-s)

clean:
	@$(call make_dirs,$(TESTS),$@)

distclean:
	@$(call make_dirs,$(TESTS),$@)
