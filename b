ALL_RECURSIVE_TARGETS =
SUBDIRS = po . gnulib-tests
EXTRA_DIST =				\
  .mailmap				\
  .prev-version				\
  .version				\
  .vg-suppressions			\
  THANKS.in				\
  THANKS-to-translators			\
  THANKStt.in				\
  bootstrap				\
  bootstrap.conf			\
  build-aux/gen-lists-of-programs.sh	\
  build-aux/gen-single-binary.sh	\
  cfg.mk				\
  dist-check.mk				\
  maint.mk				\
  tests/GNUmakefile			\
  thanks-gen
gen_progs_lists = $(top_srcdir)/build-aux/gen-lists-of-programs.sh
gen_single_binary = $(top_srcdir)/build-aux/gen-single-binary.sh
$(top_srcdir)/m4/cu-progs.m4: $(gen_progs_lists)
	$(AM_V_GEN)rm -f $@ $@-t \
	  && $(SHELL) $(gen_progs_lists) --autoconf >$@-t \
	  && chmod a-w $@-t && mv -f $@-t $@
$(srcdir)/src/cu-progs.mk: $(gen_progs_lists)
	$(AM_V_GEN)rm -f $@ $@-t \
	  && $(SHELL) $(gen_progs_lists) --automake >$@-t \
	  && chmod a-w $@-t && mv -f $@-t $@
$(srcdir)/src/single-binary.mk: $(gen_single_binary) $(srcdir)/src/local.mk
	$(AM_V_GEN)rm -f $@ $@-t \
	  && $(SHELL) $(gen_single_binary) $(srcdir)/src/local.mk >$@-t \
	  && chmod a-w $@-t && mv -f $@-t $@
ACLOCAL_AMFLAGS = -I m4
check-expensive:
	$(MAKE) check RUN_EXPENSIVE_TESTS=yes
check-very-expensive:
	$(MAKE) check-expensive RUN_VERY_EXPENSIVE_TESTS=yes
rm_subst = \
  s!(rm -f (rm\b|\$$\(bin_PROGRAMS\)$$))!$$1 > /dev/null 2>&1 || /bin/$$1!
BUILT_SOURCES = .version
.version:
	$(AM_V_GEN)echo $(VERSION) > $@-t && mv $@-t $@
dist-hook: gen-ChangeLog
	$(AM_V_GEN)chmod -R +rw $(distdir)
	$(AM_V_GEN)echo $(VERSION) > $(distdir)/.tarball-version
	$(AM_V_GEN)date +%s > $(distdir)/.timestamp
	$(AM_V_at)perl -pi -e '$(rm_subst)' $(distdir)/Makefile.in
	$(AM_V_at)touch $(distdir)/doc/constants.texi \
	  $(distdir)/doc/coreutils.info
gen_start_ver = 8.20
.PHONY: gen-ChangeLog
gen-ChangeLog:
	$(AM_V_GEN)if test -d .git; then				\
	  log_fix="$(srcdir)/build-aux/git-log-fix";			\
	  test -e "$$log_fix"						\
	    && amend_git_log="--amend=$$log_fix"			\
	    || amend_git_log=;						\
	  $(top_srcdir)/build-aux/gitlog-to-changelog $$amend_git_log	\
	    -- v$(gen_start_ver)~.. > $(distdir)/cl-t &&		\
	    { printf '\n\nSee the source repo for older entries\n'	\
	      >> $(distdir)/cl-t &&					\
	      rm -f $(distdir)/ChangeLog &&				\
	      mv $(distdir)/cl-t $(distdir)/ChangeLog; }		\
	fi
ALL_RECURSIVE_TARGETS += distcheck-hook
distcheck-hook: check-ls-dircolors
	$(MAKE) my-distcheck
	$(MAKE) taint-distcheck
DISTCLEANFILES = VERSION
MAINTAINERCLEANFILES = THANKS-to-translators
THANKS-to-translators: po/LINGUAS THANKStt.in
	$(AM_V_GEN)(							\
	  cat $(srcdir)/THANKStt.in;					\
	  for lang in `cat $(srcdir)/po/LINGUAS`; do			\
	    echo https://translationproject.org/team/$$lang.html;	\
	  done;								\
	) > $@-tmp && mv $@-tmp $@
.PHONY: check-ls-dircolors
check-ls-dircolors:
	$(AM_V_GEN)dc=$$(sed -n '/static.*ls_codes\[/,/};'/p	\
	    $(srcdir)/src/dircolors.c				\
	  |sed -n '/^  *"/p'|tr , '\n'|sed 's/^  *//'		\
	  |sed -n 's/^"\(..\)"/\1/p'|sort -u);			\
	ls=$$(sed -n '/static.*indicator_name\[/,/};'/\p	\
	    $(srcdir)/src/ls.c					\
	  |sed -n '/^  *"/p'|tr , '\n'|sed 's/^  *//'		\
	  |sed -n 's/^"\(..\)"/\1/p'|sort -u);			\
	test "$$dc" = "$$ls"
THANKS: THANKS.in Makefile.am .mailmap thanks-gen .version
	$(AM_V_GEN)rm -f $@-t $@;					\
	{								\
	  $(prologue); echo;						\
	  { perl -ne '/^$$/.../^$$/ and !/^$$/ and s/  +/\0/ and print'	\
	      $(srcdir)/THANKS.in;					\
	    git log --pretty=format:'%aN%x00%aE'			\
	      | $(ASSORT) -u;						\
	  } | $(srcdir)/thanks-gen					\
	    | LC_ALL=en_US.UTF-8 sort -k1,1;				\
	  echo;								\
	  printf ';; %s\n' 'Local Variables:' 'coding: utf-8' End:;	\
	} > $@-t && chmod a-w $@-t && mv $@-t $@
.PHONY: check-git-hook-script-sync
check-git-hook-script-sync:
	@fail=0;							\
	t=$$(mktemp -d)							\
	  && cd $$t && git init -q && cd .git/hooks			\
	  && for i in pre-commit pre-applypatch applypatch-msg; do	\
	       diff $(abs_top_srcdir)/scripts/git-hooks/$$i $$i.sample	\
		 || fail=1;						\
	     done;							\
	rm -rf $$t;							\
	test $$fail = 0
install-exec-hook:
	$(AM_V_at)ctrans=$$(printf coreutils | sed -e "$(transform)");	\
	for p in x $(single_binary_progs); do				\
	  test $$p = x && continue;					\
	  ptrans=$$(printf '%s' "$$p" | sed -e "$(transform)");		\
	  rm -f $(DESTDIR)$(bindir)/$$ptrans$(EXEEXT) || exit $$?;	\
	  if test "x$(single_binary_install_type)" = xshebangs; then	\
	    printf '#!%s --coreutils-prog-shebang=%s\n'			\
	      $(bindir)/$$ctrans$(EXEEXT) $$p				\
	      >$(DESTDIR)$(bindir)/$$ptrans$(EXEEXT) || exit $$?;	\
	    chmod a+x,a-w $(DESTDIR)$(bindir)/$$ptrans$(EXEEXT) || exit $$?;\
	  else								\
	    $(LN_S) -s $$ctrans$(EXEEXT)				\
	      $(DESTDIR)$(bindir)/$$ptrans$(EXEEXT) || exit $$?;	\
	  fi								\
	done
noinst_LIBRARIES =
MOSTLYCLEANFILES =
CLEANFILES =
MOSTLYCLEANDIRS =
AM_CPPFLAGS = -Ilib -I$(top_srcdir)/lib -Isrc -I$(top_srcdir)/src
include $(top_srcdir)/lib/local.mk
include $(top_srcdir)/src/local.mk
include $(top_srcdir)/doc/local.mk
include $(top_srcdir)/man/local.mk
include $(top_srcdir)/tests/local.mk