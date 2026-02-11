.PHONY: all install clean

PREFIX?=/usr/local
ETCDIR?=$(PREFIX)/etc

all:
	@echo "Nothing to build. Run 'make install' to install scripts."

install:
	mkdir -p $(DESTDIR)$(PREFIX)/sbin
	mkdir -p $(DESTDIR)$(ETCDIR)
	install -m 0755 src/btbox $(DESTDIR)$(PREFIX)/sbin/btbox
	install -m 0644 conf/btbox.conf.sample $(DESTDIR)$(ETCDIR)/btbox.conf.sample

clean:
	rm -rf work/
