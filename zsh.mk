ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += zsh
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS   += zsh
endif # ($(MEMO_TARGET),darwin-\*)
ZSH_VERSION   := 5.8
DEB_ZSH_V     ?= $(ZSH_VERSION)-2

zsh-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.zsh.org/pub/zsh-$(ZSH_VERSION).tar.xz{,.asc}
	$(call EXTRACT_TAR,zsh-$(ZSH_VERSION).tar.xz,zsh-$(ZSH_VERSION),zsh)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ZSH_CONFIGURE_ARGS := --enable-etcdir=/$(MEMO_PREFIX)/etc \
		zsh_cv_shared_environ=yes \
		zsh_cv_sys_elf=no \
		zsh_cv_sys_dynamic_execsyms=yes \
		zsh_cv_path_utmpx=/var/run/utmpx \
		zsh_cv_path_utmp=no \
	$(SED) -i 's/|| eno == ENOENT)/|| eno == ENOENT || eno == EPERM)/' $(BUILD_WORK)/zsh/Src/exec.c
	$(SED) -i 's/(eno == ENOEXEC)/(eno == ENOEXEC || eno == EPERM)/' $(BUILD_WORK)/zsh/Src/exec.c
else
ZSH_CONFIGURE_ARGS := --enable-etcdir=/etc
endif

ifneq ($(wildcard $(BUILD_WORK)/zsh/.build_complete),)
zsh:
	@echo "Using previously built zsh."
else
zsh: zsh-setup pcre ncurses
	cd $(BUILD_WORK)/zsh && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) \
		--enable-fndir=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/functions \
		--enable-scriptdir=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/scripts \
		--enable-site-fndir=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/zsh/site-functions \
		--enable-site-scriptdir=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/zsh/site-scripts \
		--enable-runhelpdir=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/help \
		--enable-cap \
		--enable-pcre \
		--enable-multibyte \
		--enable-zsh-secure-free \
		--enable-unicode9 \
		--with-tcsetpgrp \
		--enable-function-subdirs \
		--disable-gdbm \
		zsh_cv_rlimit_rss_is_as=yes \
		DL_EXT=bundle \
		ac_cv_prog_PCRECONF="$(BUILD_STAGE)/pcre/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/pcre-config" \
		$(ZSH_CONFIGURE_ARGS)
	+$(MAKE) -C $(BUILD_WORK)/zsh \
		CPP="$(CPP) $(CPPFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/zsh install \
		DESTDIR="$(BUILD_STAGE)/zsh"
	rm -f $(BUILD_STAGE)/zsh/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/zsh-$(ZSH_VERSION)
	touch $(BUILD_WORK)/zsh/.build_complete
endif

zsh-package: zsh-stage
	# zsh.mk Package Structure
	rm -rf $(BUILD_DIST)/zsh
	mkdir -p $(BUILD_DIST)/zsh/$(MEMO_PREFIX)/bin
	
	# zsh.mk Prep zsh
	cp -a $(BUILD_STAGE)/zsh/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/* $(BUILD_DIST)/zsh/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)
ifneq ($(MEMO_SUB_PREFIX),)
	ln -s /$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/zsh $(BUILD_DIST)/zsh/$(MEMO_PREFIX)/bin/zsh
endif
	
	# zsh.mk Sign
	$(call SIGN,zsh,general.xml)
	
	# zsh.mk Make .debs
	$(call PACK,zsh,DEB_ZSH_V)
	
	# zsh.mk Build cleanup
	rm -rf $(BUILD_DIST)/zsh

.PHONY: zsh zsh-package
