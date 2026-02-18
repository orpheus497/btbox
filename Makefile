.PHONY: all install clean

PREFIX?=/usr/local
ETCDIR?=$(PREFIX)/etc
LIBDIR?=$(PREFIX)/lib/btbox

all:
	@echo "Nothing to build. Run 'make install' to install scripts."

install:
	mkdir -p $(DESTDIR)$(PREFIX)/sbin
	mkdir -p $(DESTDIR)$(ETCDIR)
	mkdir -p $(DESTDIR)$(LIBDIR)/vmm
	install -m 0755 src/btbox $(DESTDIR)$(PREFIX)/sbin/btbox
	install -m 0644 src/common.sh $(DESTDIR)$(LIBDIR)/common.sh
	install -m 0644 src/ui_utils.sh $(DESTDIR)$(LIBDIR)/ui_utils.sh
	install -m 0755 src/check_hw.sh $(DESTDIR)$(LIBDIR)/check_hw.sh
	install -m 0755 src/vmm/bhyve_runner.sh $(DESTDIR)$(LIBDIR)/vmm/bhyve_runner.sh
	install -m 0644 conf/btbox.conf.sample $(DESTDIR)$(ETCDIR)/btbox.conf.sample

clean:
	rm -rf work/
