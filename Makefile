#
# Makefile - build wrapper for Samba 4 on RHEL 6
#
#	git clone RHEL 6 SRPM building tools from
#	https://github.com/nkadel/[package] into designated
#	SAMBAPKGS below
#
#	Set up local 

REPOBASE=http://localhost
$REPOBASE=file://$(PWD)

# RHEL 8 dependency for libldb
SAMBAPKGS+=cmocka-1.1.x-srpm

# RHEL 8 dependency for libldb
SAMBAPKGS+=lmdb-0.9.x-srpm

# RHEL 7 needs compat-nettle32-3.x, which uses epel-7-x86_64
SAMBAPKGS+=compat-nettle32-3.x-srpm

# Current libtalloc-2.x required
SAMBAPKGS+=libtalloc-2.2.x-srpm

# Current libtdb-1.4.x required
SAMBAPKGS+=libtdb-1.4.x-srpm

# Current libtevent-0.10.x required for Samba 4.10
SAMBAPKGS+=libtevent-0.10.x-srpm

# RHEL 7 needs compat-gnutls3.4.x-sprm, which uses compat-nettle32
SAMBAPKGS+=compat-gnutls34-3.x-srpm

# Also requires libtevent
SAMBAPKGS+=libldb-2.0.x-srpm

# RHEL 8 dependency for libtomcrypt
SAMBAPKGS+=libtommath-1.0.x-srpm

# RHEL 8 dependency, uses libtommath
SAMBAPKGS+=libtomcrypt-1.18.x-srpm

# RHEL 8 dependency, uses libtomcrypt
SAMBAPKGS+=python-crypto-2.6.x-srpm

# RHEL 8 dependency
SAMBAPKGS+=quota-4.x-srpm

# Current samba release, requires all curent libraries
SAMBAPKGS+=samba-4.11.x-srpm

REPOS+=samba4repo/el/7
REPOS+=samba4repo/el/8
REPOS+=samba4repo/fedora/30
REPOS+=samba4repo/fedora/31

REPODIRS := $(patsubst %,%/x86_64/repodata,$(REPOS)) $(patsubst %,%/SRPMS/repodata,$(REPOS))

CFGS+=samba4repo-7-x86_64.cfg
CFGS+=samba4repo-8-x86_64.cfg
CFGS+=samba4repo-f30-x86_64.cfg
CFGS+=samba4repo-f31-x86_64.cfg

# Link from /etc/mock
MOCKCFGS+=epel-7-x86_64.cfg
MOCKCFGS+=epel-8-x86_64.cfg
MOCKCFGS+=fedora-30-x86_64.cfg
MOCKCFGS+=fedora-31-x86_64.cfg

all:: $(CFGS)
all:: $(MOCKCFGS)
all:: $(REPODIRS)
all:: $(SAMBAPKGS)

all install clean getsrc:: FORCE
	@for name in $(SAMBAPKGS); do \
	     (cd $$name && $(MAKE) $(MFLAGS) $@); \
	done  

# Build for locacl OS
build:: FORCE
	@for name in $(SAMBAPKGS); do \
	     (cd $$name && $(MAKE) $(MFLAGS) $@); \
	done

# Git submodule checkout operation
# For more recent versions of git, use "git checkout --recurse-submodules"
#*-srpm::
#	@[ -d $@/.git ] || \
#	     git submodule update --init $@

# Dependencies of libraries on other libraries for compilation

compat-gnutls34-3.x-srpm:: compat-nettle32-3.x-srpm

libtevent-0.10.x-srpm:: libtalloc-2.2.x-srpm

libldb-2.0.x-srpm:: cmocka-1.1.x-srpm
libldb-2.0.x-srpm:: lmdb-0.9.x-srpm
libldb-2.0.x-srpm:: libtalloc-2.2.x-srpm
libldb-2.0.x-srpm:: libtdb-1.4.x-srpm
libldb-2.0.x-srpm:: libtevent-0.10.x-srpm

# Needed for with_mitkrb5
compat-nettle32-3.x-srpm:: libldb-2.0.x-srpm
compat-gnutls34-3.x-srpm:: libldb-2.0.x-srpm

# Samba rellies on all the othe components
samba-4.11.x-srpm:: compat-gnutls34-3.x-srpm
samba-4.11.x-srpm:: lmdb-0.9.x-srpm
samba-4.11.x-srpm:: libtalloc-2.2.x-srpm
samba-4.11.x-srpm:: libtdb-1.4.x-srpm
samba-4.11.x-srpm:: libtevent-0.10.x-srpm
samba-4.11.x-srpm:: libldb-2.0.x-srpm

# Actually build in directories
$(SAMBAPKGS):: FORCE
	(cd $@ && $(MAKE) $(MLAGS) install)

repos: $(REPOS) $(REPODIRS)
$(REPOS):
	install -d -m 755 $@

.PHONY: $(REPODIRS)
$(REPODIRS): $(REPOS)
	@install -d -m 755 `dirname $@`
	/usr/bin/createrepo -q `dirname $@`


.PHONY: cfg
cfg:: cfgs

.PHONY: cfgs
cfgs: $(CFGS) $(MOCKCFGS)

samba4repo-7-x86_64.cfg: /etc/mock/epel-7-x86_64.cfg
	@echo Generating $@ from $?
	@cat $? > $@
	@sed -i 's/epel-7-x86_64/samba4repo-7-x86_64/g' $@
	@echo >> $@
	@echo "Disabling 'best=' for $@"
	@sed -i '/^best=/d' $@
	@echo "best=0" >> $@
	@echo "config_opts['yum.conf'] += \"\"\"" >> $@
	@echo '[samba4repo]' >> $@
	@echo 'name=samba4repo' >> $@
	@echo 'enabled=1' >> $@
	@echo 'baseurl=$(REPOBASE)/samba4repo/el/7/x86_64/' >> $@
	@echo 'failovermethod=priority' >> $@
	@echo 'skip_if_unavailable=False' >> $@
	@echo 'metadata_expire=1' >> $@
	@echo 'gpgcheck=0' >> $@
	@echo '#cost=2000' >> $@
	@echo '"""' >> $@

samba4repo-8-x86_64.cfg: /etc/mock/epel-8-x86_64.cfg
	@echo Generating $@ from $?
	@cat $? > $@
	@sed -i 's/epel-8-x86_64/samba4repo-8-x86_64/g' $@
	@echo >> $@
	@echo "Disabling 'best=' for $@"
	@sed -i '/^best=/d' $@
	@echo "best=0" >> $@
	@echo "config_opts['yum.conf'] += \"\"\"" >> $@
	@echo '[samba4repo]' >> $@
	@echo 'name=samba4repo' >> $@
	@echo 'enabled=1' >> $@
	@echo 'baseurl=$(REPOBASE)/samba4repo/el/8/x86_64/' >> $@
	@echo 'failovermethod=priority' >> $@
	@echo 'skip_if_unavailable=False' >> $@
	@echo 'metadata_expire=1' >> $@
	@echo 'gpgcheck=0' >> $@
	@echo '#cost=2000' >> $@
	@echo '"""' >> $@

samba4repo-f30-x86_64.cfg: /etc/mock/fedora-30-x86_64.cfg
	@echo Generating $@ from $?
	@cat $? > $@
	@sed -i 's/fedora-30-x86_64/samba4repo-f30-x86_64/g' $@
	@echo >> $@
	@echo "Disabling 'best=' for $@"
	@sed -i '/^best=/d' $@
	@echo "best=0" >> $@
	@echo "config_opts['yum.conf'] += \"\"\"" >> $@
	@echo '[samba4repo]' >> $@
	@echo 'name=samba4repo' >> $@
	@echo 'enabled=1' >> $@
	@echo 'baseurl=$(REPOBASE)/samba4repo/fedora/30/x86_64/' >> $@
	@echo 'failovermethod=priority' >> $@
	@echo 'skip_if_unavailable=False' >> $@
	@echo 'metadata_expire=1' >> $@
	@echo 'gpgcheck=0' >> $@
	@echo '#cost=2000' >> $@
	@echo '"""' >> $@

samba4repo-f31-x86_64.cfg: /etc/mock/fedora-31-x86_64.cfg
	@echo Generating $@ from $?
	@cat $? > $@
	@sed -i 's/fedora-31-x86_64/samba4repo-f31-x86_64/g' $@
	@echo >> $@
	@echo "Disabling 'best=' for $@"
	@sed -i '/^best=/d' $@
	@echo "best=0" >> $@
	@echo "config_opts['yum.conf'] += \"\"\"" >> $@
	@echo '[samba4repo]' >> $@
	@echo 'name=samba4repo' >> $@
	@echo 'enabled=1' >> $@
	@echo 'baseurl=$(REPOBASE)/samba4repo/fedora/31/x86_64/' >> $@
	@echo 'failovermethod=priority' >> $@
	@echo 'skip_if_unavailable=False' >> $@
	@echo 'metadata_expire=1' >> $@
	@echo 'gpgcheck=0' >> $@
	@echo '#cost=2000' >> $@
	@echo '"""' >> $@

samba4repo-rawhide-x86_64.cfg: /etc/mock/fedora-rawhide-x86_64.cfg
	@echo Generating $@ from $?
	@cat $? > $@
	@sed -i 's/fedora-rawhide-x86_64/samba4repo-rawhide-x86_64/g' $@
	@echo >> $@
	@echo "Disabling 'best=' for $@"
	@sed -i '/^best=/d' $@
	@echo "best=0" >> $@
	@echo "config_opts['yum.conf'] += \"\"\"" >> $@
	@echo '[samba4repo]' >> $@
	@echo 'name=samba4repo' >> $@
	@echo 'enabled=1' >> $@
	@echo 'baseurl=$(REPOBASE)/samba4repo/fedora/rawhide/x86_64/' >> $@
	@echo 'failovermethod=priority' >> $@
	@echo 'skip_if_unavailable=False' >> $@
	@echo 'metadata_expire=1' >> $@
	@echo 'gpgcheck=0' >> $@
	@echo '#cost=2000' >> $@
	@echo '"""' >> $@

$(MOCKCFGS)::
	ln -sf /etc/mock/$@ $@

repo: samba4repo.repo
samba4repo.repo:: Makefile samba4repo.repo.in
	if [ -s /etc/fedora-release ]; then \
		cat $@.in | \
			sed "s|@REPOBASEDIR@/|$(PWD)/|g" | \
			sed "s|/@RELEASEDIR@/|/fedora/|g" > $@; \
	elif [ -s /etc/redhat-release ]; then \
		cat $@.in | \
			sed "s|@REPOBASEDIR@/|$(PWD)/|g" | \
			sed "s|/@RELEASEDIR@/|/el/|g" > $@; \
	else \
		echo Error: unknown release, check /etc/*-release; \
		exit 1; \
	fi

samba4repo.repo::
	@cmp -s $@ /etc/yum.repos.d/$@ || \
	    diff -u $@ /etc/yum.repos.d/$@

clean::
	find . -name \*~ -exec rm -f {} \;
	rm -f *.cfg
	rm -f *.out
	@for name in $(SAMBAPKGS); do \
	    $(MAKE) -C $$name clean; \
	done

distclean: clean
	rm -rf $(REPOS)
	rm -rf samba4repo
	@for name in $(SAMBAPKGS); do \
	    (cd $$name; git clean -x -d -f); \
	done

maintainer-clean: distclean
	rm -rf $(SAMBAPKGS)
	@for name in $(SAMBAPKGS); do \
	    (cd $$name; git clean -x -d -f); \
	done

FORCE::

