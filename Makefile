DISCO_VERSION = 0.3.2
DISCO_RELEASE = 0.3.2

# standard make installation variables
sysconfdir    = /etc
prefix        = /usr/local
exec_prefix   = $(prefix)
localstatedir = $(prefix)/var
bindir        = $(exec_prefix)/bin
libdir        = $(exec_prefix)/lib

SHELL           = /bin/sh
INSTALL         = /usr/bin/install -c
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA    = $(INSTALL) -m 644
INSTALL_TREE    = cp -r

# installation directories
TARGETBIN = $(DESTDIR)$(bindir)
TARGETLIB = $(DESTDIR)$(libdir)/disco
TARGETCFG = $(DESTDIR)$(sysconfdir)/disco
TARGETSRV = $(DESTDIR)$(localstatedir)/disco

# options to sphinx for building the docs
SPHINXOPTS = "-D version=$(DISCO_VERSION) -D release=$(DISCO_RELEASE)"

# used to choose which conf file will be generated
UNAME = $(shell uname)

# utilities used for building disco
ERL        = erl
ERLC       = erlc
EOPT       = -W
DIALYZER   = dialyzer
TYPER      = typer
PYTHON     = python
PY_INSTALL = $(PYTHON) setup.py install --root=$(DESTDIR)/ --prefix=$(prefix)
RE_VERSION = sed -e s/%DISCO_VERSION%/$(DISCO_VERSION)/

WWW   = master/www
EBIN  = master/ebin
ESRC  = master/src
ETEST = master/test

ELIBS    = $(ESRC) $(ESRC)/ddfs $(ESRC)/mochiweb
ESOURCES = $(foreach lib,$(ELIBS),$(wildcard $(lib)/*.erl))
EHEADERS = $(foreach lib,$(ELIBS),$(wildcard $(lib)/*.hrl))
EAPPS    = $(subst $(ESRC),$(EBIN),$(ELIBS))
EOBJECTS = $(subst $(ESRC),$(EBIN),$(ESOURCES:.erl=.beam))
ETARGETS = $(foreach object,$(EOBJECTS),$(TARGETLIB)/$(object))

ETESTSOURCES = $(wildcard $(ETEST)/*.erl)
ETESTOBJECTS = $(ETESTSOURCES:.erl=.beam)

EPLT  = .dialyzer_plt

.PHONY: all master clean distclean doc docclean doctest
.PHONY: install \
	install-master \
	install-core \
	install-discodb \
	install-discodex \
	install-examples \
	install-tests
.PHONY: test dialyzer typer

all: master

master: $(EBIN)/disco.app $(EOBJECTS)

clean:
	- rm -Rf $(EBIN) $(ETESTOBJECTS)
	- rm -Rf lib/build lib/disco.egg-info
	- rm -Rf doc/.build

distclean: clean
	- rm -Rf $(EPLT)

doc:
	(cd doc && $(MAKE) SPHINXOPTS=$(SPHINXOPTS) html)

docclean:
	(cd doc && $(MAKE) SPHINXOPTS=$(SPHINXOPTS) clean)

doctest:
	(cd doc && $(MAKE) SPHINXOPTS=$(SPHINXOPTS) doctest)

install: install-core install-master

install-core:
	(cd lib && $(PY_INSTALL))

install-discodb:
	(cd contrib/discodb && $(PY_INSTALL))

install-discodex:
	(cd contrib/discodex && $(PY_INSTALL))

install-examples: $(TARGETLIB)/examples

install-master: master \
		$(ETARGETS) \
		$(TARGETBIN)/disco $(TARGETBIN)/ddfs \
		$(TARGETCFG)/settings.py \
		$(TARGETLIB)/$(EBIN)/disco.app \
		$(TARGETLIB)/$(WWW) \
		$(TARGETSRV)/ddfs

install-tests: $(TARGETLIB)/ext $(TARGETLIB)/tests

uninstall:
	- rm -f  $(TARGETBIN)/disco $(TARGETBIN)/ddfs
	- rm -Rf $(TARGETCFG) $(TARGETLIB) $(TARGETSRV)

test: master $(ETESTOBJECTS)
	$(ERL) -noshell -pa $(ETEST) $(EAPPS) -s master_tests main -s init stop

dialyzer: EOPT = -W +debug_info
dialyzer: $(EPLT)
	$(DIALYZER) --get_warnings -Wunmatched_returns -Werror_handling -Wbehaviours --plt $(EPLT) --src -r $(ESRC)

typer: $(EPLT)
	$(TYPER) --plt $(EPLT) -r $(ESRC)

$(EBIN):
	mkdir $(EAPPS)

$(EBIN)/disco.app: $(ESRC)/disco.app | $(EBIN)
	- $(RE_VERSION) $< > $@

$(EBIN)/%.beam: $(ESRC)/%.erl $(EHEADERS) | $(EBIN)
	$(ERLC) $(EOPT) -o $(dir $@) $<

$(ETEST)/%.beam: $(ETEST)/%.erl
	$(ERLC) $(EOPT) -o $(dir $@) $<

$(EPLT):
	$(DIALYZER) --build_plt --output_plt $(EPLT) \
		    --apps stdlib kernel erts mnesia compiler crypto inets xmerl ssl syntax_tools

$(TARGETBIN):
	$(INSTALL) -d $(TARGETBIN)

$(TARGETBIN)/%: bin/% | $(TARGETBIN)
	$(INSTALL_PROGRAM) $< $@

$(TARGETCFG):
	$(INSTALL) -d $(TARGETCFG)

$(TARGETCFG)/settings.py: | $(TARGETCFG)
	(TARGETLIB=$(TARGETLIB) TARGETSRV=$(TARGETSRV) \
	 conf/gen.settings.sys-$(UNAME) > $@ && chmod 644 $@)

$(TARGETLIB):
	$(INSTALL) -d $(addprefix $(TARGETLIB)/,$(EAPPS))

$(TARGETLIB)/$(EBIN)/%: $(EBIN)/% | $(TARGETLIB)
	$(INSTALL_DATA) $< $@

$(TARGETLIB)/%: % | $(TARGETLIB)
	$(INSTALL_TREE) $< $@

$(TARGETSRV)/ddfs:
	$(INSTALL) -d $(TARGETSRV)/ddfs
