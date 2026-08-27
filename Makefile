# Instalação com DESTDIR/PREFIX, para empacotamento (.deb, Flatpak) e para
# instalação manual a partir do fonte.
PREFIX  ?= /usr
DESTDIR ?=

BINDIR  := $(PREFIX)/bin
DATADIR := $(PREFIX)/share
SYSTEMD_USER_DIR ?= $(PREFIX)/lib/systemd/user
# O Flatpak não usa systemd do usuário; passe INSTALL_SYSTEMD=0 para pular.
INSTALL_SYSTEMD ?= 1

APPID := io.github.augustotecnos.ocr-tela

.PHONY: all install uninstall check clean

all:
	@echo "Nada a compilar. Use: make install [PREFIX=...] [DESTDIR=...]"

install:
	install -Dm755 ocr-tela                  $(DESTDIR)$(BINDIR)/ocr-tela
	install -Dm755 ocr-warmup.sh             $(DESTDIR)$(BINDIR)/ocr-warmup
	install -Dm755 tools/ocr-tela-atalho     $(DESTDIR)$(BINDIR)/ocr-tela-atalho
	install -Dm644 data/$(APPID).desktop      $(DESTDIR)$(DATADIR)/applications/$(APPID).desktop
	install -Dm644 data/$(APPID).metainfo.xml $(DESTDIR)$(DATADIR)/metainfo/$(APPID).metainfo.xml
	install -Dm644 data/$(APPID).svg          $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/$(APPID).svg
	install -Dm644 data/man/ocr-tela.1        $(DESTDIR)$(DATADIR)/man/man1/ocr-tela.1
	install -Dm644 data/man/ocr-tela-atalho.1 $(DESTDIR)$(DATADIR)/man/man1/ocr-tela-atalho.1
	install -Dm644 data/man/ocr-warmup.1      $(DESTDIR)$(DATADIR)/man/man1/ocr-warmup.1
ifeq ($(INSTALL_SYSTEMD),1)
	install -d $(DESTDIR)$(SYSTEMD_USER_DIR)
	sed 's|@BINDIR@|$(BINDIR)|g' data/ocr-warmup.service.in \
	    > $(DESTDIR)$(SYSTEMD_USER_DIR)/ocr-warmup.service
	chmod 644 $(DESTDIR)$(SYSTEMD_USER_DIR)/ocr-warmup.service
endif

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/ocr-tela
	rm -f $(DESTDIR)$(BINDIR)/ocr-warmup
	rm -f $(DESTDIR)$(BINDIR)/ocr-tela-atalho
	rm -f $(DESTDIR)$(DATADIR)/applications/$(APPID).desktop
	rm -f $(DESTDIR)$(DATADIR)/metainfo/$(APPID).metainfo.xml
	rm -f $(DESTDIR)$(DATADIR)/icons/hicolor/scalable/apps/$(APPID).svg
	rm -f $(DESTDIR)$(DATADIR)/man/man1/ocr-tela.1
	rm -f $(DESTDIR)$(DATADIR)/man/man1/ocr-tela-atalho.1
	rm -f $(DESTDIR)$(DATADIR)/man/man1/ocr-warmup.1
	rm -f $(DESTDIR)$(SYSTEMD_USER_DIR)/ocr-warmup.service

check:
	python3 -m py_compile ocr-tela tools/ocr-tela-atalho
	bash -n ocr-warmup.sh install.sh uninstall.sh
	desktop-file-validate data/$(APPID).desktop
	appstreamcli validate --no-net data/$(APPID).metainfo.xml

clean:
	rm -rf __pycache__ tools/__pycache__
