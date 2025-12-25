.POSIX:

ID = org.vinegarhq.Vinegar

PREFIX      ?= /usr
DATAPREFIX  = $(PREFIX)/share/vinegar
APPPREFIX   = $(PREFIX)/share/applications
MIMEPREFIX  = $(PREFIX)/share/mime
ICONPREFIX  = $(PREFIX)/share/icons/hicolor
LIBPREFIX   = $(PREFIX)/lib
LAYERPREFIX = $(PREFIX)/share/vulkan/explicit_layer.d
LOCALEPREFIX  = $(PREFIX)/share/locale

CXX ?= c++

PKG_CONFIG = pkg-config
INCS != $(PKG_CONFIG) --cflags vulkan

GO         ?= go
GO_LDFLAGS ?= -s -w -X main.LocaleDir="$(LOCALEPREFIX)"

%.mo: %.po
	msgfmt $< -o $@

SOURCES != find . -type f -name "*.go" # for automatically re-building vinegar
LOCALES != find data/po/. -type f -name "*.po" # for automatically re-building locales

RESOURCE = internal/gutil/vinegar.gresource
VKLAYER = layer/libVkLayer_VINEGAR_VinegarLayer.so
MO_FILES = $(LOCALES:.po=.mo)

all: vinegar $(VKLAYER) $(MO_FILES)

vinegar: $(SOURCES) $(RESOURCE)
	$(GO) build $(GOFLAGS) -ldflags="$(GO_LDFLAGS)" ./cmd/vinegar

$(RESOURCE): data/vinegar.gresource.xml
	glib-compile-resources --sourcedir=data --target=$(RESOURCE) $<

$(VKLAYER): layer/vinegar_layer.cpp
	$(CXX) -shared -fPIC $(INCS) $< -o $@

install: all
	install -Dm755 vinegar $(DESTDIR)$(PREFIX)/bin/vinegar
	install -Dm644 data/$(ID).metainfo.xml -t $(DESTDIR)$(PREFIX)/share/metainfo
	install -Dm644 data/$(ID).desktop -t $(DESTDIR)$(APPPREFIX)
	install -Dm644 data/$(ID)-studio.xml -t $(DESTDIR)$(MIMEPREFIX)/packages
	install -Dm644 data/icons/vinegar.svg $(DESTDIR)$(ICONPREFIX)/scalable/apps/$(ID).svg
	install -Dm644 data/icons/roblox-studio.svg $(DESTDIR)$(ICONPREFIX)/scalable/apps/$(ID).studio.svg
	install -Dm644 $(VKLAYER) -t $(DESTDIR)$(LIBPREFIX)
	install -Dm644 layer/VkLayer_VINEGAR_VinegarLayer.json -t $(DESTDIR)$(LAYERPREFIX)
	for mo in $(MO_FILES); do \
		lang=$$(basename "$$mo" .mo); \
		install -Dm644 "$$mo" $(DESTDIR)$(LOCALEPREFIX)/$$lang/LC_MESSAGES/vinegar.mo; \
	done

host:
	gtk-update-icon-cache -f -t $(DESTDIR)$(ICONPREFIX)
	update-desktop-database $(DESTDIR)$(APPPREFIX)
	update-mime-database -n $(DESTDIR)$(MIMEPREFIX)

uninstall:
	# Retain removal of old studio desktop & old mime name
	rm -f $(DESTDIR)$(PREFIX)/bin/vinegar \
		$(DESTDIR)$(PREFIX)/share/metainfo/$(ID).metainfo.xml \
		$(DESTDIR)$(APPPREFIX)/$(ID).desktop \
		$(DESTDIR)$(APPPREFIX)/$(ID).studio.desktop \
		$(DESTDIR)$(MIMEPREFIX)/packages/vinegar-mime.xml \
		$(DESTDIR)$(MIMEPREFIX)/packages/$(ID)-studio.xml \
		$(DESTDIR)$(ICONPREFIX)/scalable/apps/$(ID).svg \
		$(DESTDIR)$(ICONPREFIX)/scalable/apps/$(ID).studio.svg \
		$(DESTDIR)$(LIBPREFIX)/libVkLayer_VINEGAR_VinegarLayer.so \
		$(DESTDIR)$(LAYERPREFIX)/VkLayer_VINEGAR_VinegarLayer.json \
		$(DESTDIR)$(LOCALEPREFIX)/*/LC_MESSAGES/vinegar.mo

clean:
	rm -f vinegar $(RESOURCE) $(VKLAYER) $(MO_FILES)
	
.PHONY: all install uninstall clean
