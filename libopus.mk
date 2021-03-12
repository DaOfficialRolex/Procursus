ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libopus
LIBOPUS_VERSION := 1.3.1
DEB_LIBOPUS_V   ?= $(LIBOPUS_VERSION)

libopus-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://archive.mozilla.org/pub/opus/opus-$(LIBOPUS_VERSION).tar.gz
	$(call EXTRACT_TAR,opus-$(LIBOPUS_VERSION).tar.gz,opus-$(LIBOPUS_VERSION),libopus)

ifneq ($(wildcard $(BUILD_WORK)/libopus/.build_complete),)
libopus:
	@echo "Using previously built libopus."
else
libopus: libopus-setup
	cd $(BUILD_WORK)/libopus && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-doc
	+$(MAKE) -C $(BUILD_WORK)/libopus
	+$(MAKE) -C $(BUILD_WORK)/libopus install \
		DESTDIR=$(BUILD_STAGE)/libopus
	+$(MAKE) -C $(BUILD_WORK)/libopus install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libopus/.build_complete
endif

libopus-package: libopus-stage
	# libopus.mk Package Structure
	rm -rf $(BUILD_DIST)/libopus{0,-dev}
	mkdir -p $(BUILD_DIST)/libopus{0,-dev}/usr/lib
	
	# libopus.mk Prep libopus0
	cp -a $(BUILD_STAGE)/libopus/usr/lib/libopus.0.dylib $(BUILD_DIST)/libopus0/usr/lib

	# libopus.mk Prep libopus-dev
	cp -a $(BUILD_STAGE)/libopus/usr/lib/libopus.{a,dylib} $(BUILD_DIST)/libopus-dev/usr/lib
	cp -a $(BUILD_STAGE)/libopus/usr/include $(BUILD_DIST)/libopus-dev/usr
	
	# libopus.mk Sign
	$(call SIGN,libopus0,general.xml)
	
	# libopus.mk Make .debs
	$(call PACK,libopus0,DEB_LIBOPUS_V)
	$(call PACK,libopus-dev,DEB_LIBOPUS_V)
	
	# libopus.mk Build cleanup
	rm -rf $(BUILD_DIST)/libopus{0,-dev}

.PHONY: libopus libopus-package
