#Makefile to build NEUTRINO

AUDIODEC = ffmpeg
NEUTRINO_DEPS  = $(SYSTEM_TOOLS)
ifeq ($(UCLIBC_BUILD), 1)
NEUTRINO_DEPS += libiconv
endif
ifeq ($(PLATFORM), pc)
NEUTRINO_DEPS += libstb-hal
endif
NEUTRINO_DEPS += libcurl libjpeg freetype libbluray ffmpeg libdvbsi++ giflib libsigc++
NEUTRINO_DEPS += openthreads luaposix lua-expat openssl pugixml
NEUTRINO_DEPS += wpa_supplicant parted
#ifneq ($(PLATFORM), nevis)
#NEUTRINO_DEPS += extras-mc
#endif

NEUTRINO_PKG_DEPS =

N_CFLAGS  = -Wall -Werror -Wextra -Wshadow -Wsign-compare
#N_CFLAGS += -Wconversion
#N_CFLAGS += -Wfloat-equal
N_CFLAGS += -Wuninitialized
N_CFLAGS += -Wmaybe-uninitialized
N_CFLAGS += -Werror=type-limits
N_CFLAGS += -Warray-bounds
N_CFLAGS += -Wformat-security
N_CFLAGS += -fmax-errors=10
N_CFLAGS += -D__KERNEL_STRICT_NAMES
N_CFLAGS += -DNEW_LIBCURL $(LOCAL_NEUTRINO_CFLAGS)
N_CFLAGS += -fno-strict-aliasing -rdynamic 
N_CFLAGS += -D__STDC_FORMAT_MACROS
N_CFLAGS += -D__STDC_CONSTANT_MACROS
N_CFLAGS += -DASSUME_MDEV
#N_CFLAGS += -DSTATIC_STB_HAL $(TARGETPREFIX_BASE)/lib/libstb-hal.a

N_GCC_OPTIMIZE ?= normal
ifeq ($(N_GCC_OPTIMIZE), debug)
N_CFLAGS += -O0 -g -ggdb3
endif
ifeq ($(N_GCC_OPTIMIZE), size)
N_CFLAGS += -Os
endif
ifeq ($(N_GCC_OPTIMIZE), normal)
N_CFLAGS += -O2
endif

ifeq ($(N_GCC_OPTIMIZE), sani)
N_CFLAGS_X  =
N_CFLAGS_X += -fsanitize=address -fno-omit-frame-pointer
#N_CFLAGS_X += -fsanitize=thread
N_CFLAGS_X += -fsanitize=undefined -fsanitize=enum -fsanitize=integer-divide-by-zero
N_CFLAGS_X += -fsanitize=unreachable -fsanitize=shift -fsanitize=null
N_CFLAGS_X += -fsanitize=signed-integer-overflow -fsanitize=integer-divide-by-zero 
N_CFLAGS_X += -fsanitize=vla-bound -fsanitize=leak -fsanitize=return -fsanitize=object-size
N_CFLAGS_X += -funsigned-char -fwrapv -fstack-protector-all
N_CFLAGS_X += -fstack-protector-strong -Wno-long-long -Wno-narrowing
N_CFLAGS_X +=  -O0 -g -ggdb3
N_CFLAGS   += $(N_CFLAGS_X)
endif

ifeq ($(PLATFORM), apollo)
N_CFLAGS += -mcpu=cortex-a9 -mfpu=vfpv3-d16 -mfloat-abi=hard -DFB_HW_ACCELERATION
HW_TYPE = --with-boxtype=coolstream --with-boxmodel=apollo
endif

ifeq ($(PLATFORM), kronos)
N_CFLAGS += -mcpu=cortex-a9 -mfpu=vfpv3-d16 -mfloat-abi=hard -DFB_HW_ACCELERATION
HW_TYPE = --with-boxtype=coolstream --with-boxmodel=apollo
endif

ifeq ($(PLATFORM), nevis)
N_CFLAGS += -DUSE_NEVIS_GXA
HW_TYPE = --with-boxtype=coolstream
endif

ifeq ($(PLATFORM), pc)
HW_TYPE = --with-boxtype=generic
N_LDFLAGS += -lGLEW -lGL -lGLU -lglut -lao -lswscale
endif
N_CFLAGS += $(NO_CXX11_ABI)

N_CPPFLAGS = -I$(TARGETPREFIX)/include -I$(TARGETPREFIX_BASE)/include -I$(TARGETPREFIX)/include/freetype2
## -I$(TARGETPREFIX_BASE)/include/libstb-hal
N_CPPFLAGS += -Werror -Wsign-compare
N_CPPFLAGS += $(NO_CXX11_ABI)

N_CONFIG_OPTS =
N_CONFIG_OPTS += --enable-giflib
#N_CONFIG_OPTS += --enable-pip
N_CONFIG_OPTS += --enable-lua
#N_CONFIG_OPTS += --enable-testing
N_CONFIG_OPTS += --enable-pugixml 
#N_CONFIG_OPTS += --enable-zeromq

ifeq ($(AUDIODEC), ffmpeg)
# enable ffmpeg audio decoder in neutrino
N_CONFIG_OPTS += --enable-ffmpegdec
else
NEUTRINO_DEPS += libid3tag libmad
#N_CONFIG_OPTS += --with-tremor-static
N_CONFIG_OPTS += --with-tremor
NEUTRINO_DEPS += libvorbisidec
N_CONFIG_OPTS += --enable-flac
NEUTRINO_DEPS += libFLAC
endif

NEUTRINO_DEPS2 += $(TARGETPREFIX_BASE)/bin/fbshot

neutrino-deps: $(NEUTRINO_DEPS)

N_LDFLAGS =
#N_LDFLAGS = -L$(TARGETPREFIX_BASE)/lib -lcurl -lssl -lcrypto -ldl
N_LDFLAGS += -L$(TARGETPREFIX)/lib -L$(TARGETPREFIX_BASE)/lib

ifeq ($(N_GCC_OPTIMIZE), sani)
N_LDFLAGS += -lasan
endif

N_LDFLAGS += -L$(HOST_LIBS)
ifeq ($(UCLIBC_BUILD), 1)
N_LDFLAGS += -liconv
endif

##N_LDFLAGS += -Wl,-rpath-link,$(TARGETLIB)
N_LDFLAGS += -Wl,-rpath-link,$(TARGETPREFIX)/lib:$(TARGETPREFIX_BASE)/lib:$(HOST_LIBS)

# finally we can build outside of the source directory
N_OBJDIR = $(BUILD_TMP)/$(FLAVOUR)
# use this if you want to build inside the source dir - but you don't want that ;)
# N_OBJDIR = $(N_HD_SOURCE)

copy-pcimage: $(TARGETPREFIX_BASE)/bin/neutrino
	@mkdir -p $(PC_INSTALL)
	cp -frd $(TARGETPREFIX_BASE)/. $(PC_INSTALL)
	@find $(PC_INSTALL) -name .gitignore -type f -print0 | xargs --no-run-if-empty -0 rm -f
	@find $(PC_INSTALL)/lib \( -name '*.a' -o -name '*.la' \) -print0 | xargs --no-run-if-empty -0 rm -f
	@find $(PC_INSTALL)/usr/lib \( -name '*.a' -o -name '*.la' \) -print0 | xargs --no-run-if-empty -0 rm -f
	@find $(PC_INSTALL)/usr/lib/lua/5.2 \( -name '*.a' -o -name '*.la' \) -print0 | xargs --no-run-if-empty -0 rm -f
	@echo ""
	@echo "  ***"
	@echo "  *** Data copy to $(PC_INSTALL) OK ***"
	@echo "  ***"


$(N_OBJDIR)/config.status: $(NEUTRINO_DEPS) $(MAKE_DIR)/neutrino.mk
	test -d $(N_OBJDIR) || mkdir -p $(N_OBJDIR)
	cd $(N_HD_SOURCE) && \
		git checkout $(NEUTRINO_WORK_BRANCH)
	$(N_HD_SOURCE)/autogen.sh
	set -e; cd $(N_OBJDIR); \
		CC=$(TARGET)-gcc CFLAGS="$(N_CFLAGS)" CXXFLAGS="$(N_CFLAGS)" CPPFLAGS="$(N_CPPFLAGS)" \
		LDFLAGS="$(N_LDFLAGS)" PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
		$(N_HD_SOURCE)/configure \
				--host=$(TARGET) \
				--prefix="" \
				--enable-silent-rules \
				--enable-mdev \
				--enable-maintainer-mode \
				--with-target=cdk \
				--with-targetprefix=$(PC_INSTALL) \
				$(HW_TYPE) \
				--with-stb-hal-includes=$(TARGETPREFIX_BASE)/include/libstb-hal \
				--with-stb-hal-build=$(TARGETPREFIX_BASE)/lib \
				$(N_CONFIG_OPTS) \
				$(LOCAL_NEUTRINO_BUILD_OPTIONS) \
				INSTALL="`which install` -p"; \
		test -e src/gui/svn_version.h || echo '#define BUILT_DATE "error - not set"' > src/gui/svn_version.h; \
		test -e svn_version.h || echo '#define BUILT_DATE "error - not set"' > svn_version.h; \
		test -e git_version.h || echo '#define BUILT_DATE "error - not set"' > git_version.h; \
		test -e version.h || touch version.h

HOMEPAGE = "http://gitorious.org/neutrino-hd"
IMGNAME  = "HD-Neutrino"
$(PKGPREFIX_BASE)/.version \
$(TARGETPREFIX_BASE)/.version:
	echo "version=1200`date +%Y%m%d%H%M`"	 > $@
	echo "creator=$(MAINTAINER)"		>> $@
	echo "imagename=$(IMGNAME)"		>> $@
	A=$(FLAVOUR); F=$${A#neutrino-??}; \
		B=`cd $(N_HD_SOURCE); git describe --always --dirty`; \
		C=$${B%-dirty}; D=$${B#$$C}; \
		E=`cd $(N_HD_SOURCE); git tag --contains $$C`; \
		test -n "$$E" && C="$$E"; \
		echo "builddate=$$C$$D $${F:1}" >> $@
	echo "homepage=$(HOMEPAGE)"		>> $@

PHONY += $(PKGPREFIX_BASE)/.version $(TARGETPREFIX_BASE)/.version

$(D)/locales: $(N_OBJDIR)/config.status $(NEUTRINO_DEPS2)
	cd $(BUILD_TMP)/$(FLAVOUR)/data/locale; \
		make locals

$(D)/neutrino: $(N_OBJDIR)/config.status $(NEUTRINO_DEPS2)
	rm -f $(N_OBJDIR)/src/neutrino # trigger relinking, to pick up newly built libstb-hal
	cd $(N_HD_SOURCE) && \
		git checkout $(NEUTRINO_WORK_BRANCH)
	cd $(BASE_DIR)
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	$(MAKE) -C $(N_OBJDIR) all     DESTDIR=$(TARGETPREFIX_BASE)
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(TARGETPREFIX_BASE)
	+make $(TARGETPREFIX_BASE)/.version
	: touch $@

neutrino-pkg: $(N_OBJDIR)/config.status $(NEUTRINO_DEPS2) $(NEUTRINO_PKG_DEPS)
	rm -rf $(PKGPREFIX_BASE) $(BUILD_TMP)/neutrino-control
	cd $(N_HD_SOURCE) && \
		git checkout $(NEUTRINO_WORK_BRANCH)
	cd $(BASE_DIR)
#	$(MAKE) -C $(N_OBJDIR) clean   DESTDIR=$(TARGETPREFIX_BASE)
	PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) \
	$(MAKE) -C $(N_OBJDIR) all     DESTDIR=$(TARGETPREFIX_BASE)
	$(MAKE) -C $(N_OBJDIR) install DESTDIR=$(PKGPREFIX_BASE)
ifeq ($(PLATFORM), nevis)
	install -D -m 0755 skel-root/nevis/etc/init.d/start_neutrino $(PKGPREFIX_BASE)/etc/init.d/start_neutrino;
endif
ifeq ($(PLATFORM), apollo)
	install -D -m 0755 skel-root/apollo/bin/autorun.sh $(PKGPREFIX_BASE)/bin/autorun.sh;
endif
ifeq ($(PLATFORM), kronos)
	install -D -m 0755 skel-root/kronos/bin/autorun.sh $(PKGPREFIX_BASE)/bin/autorun.sh;
endif
	make $(PKGPREFIX_BASE)/.version
	cp -a $(CONTROL_DIR)/$(NEUTRINO_PKG) $(BUILD_TMP)/neutrino-control
	DEP=`$(TARGET)-objdump -p $(PKGPREFIX_BASE)/bin/neutrino | awk '/NEEDED/{print $$2}' | sort` && \
		DEP=`echo $$DEP` && \
		DEP="$${DEP// /, }" && \
		sed -i "s/@DEP@/$$DEP/" $(BUILD_TMP)/neutrino-control/control
	sed -i 's/^\(Depends:.*\)$$/\1, cs-drivers/' $(BUILD_TMP)/neutrino-control/control
	install -p -m 0755 $(TARGETPREFIX_BASE)/bin/fbshot $(PKGPREFIX_BASE)/bin/
	ln -s usr/share $(PKGPREFIX_BASE)/share
	find $(PKGPREFIX_BASE)/share/tuxbox/neutrino/locale/ -type f \
		! -name deutsch.locale ! -name english.locale ! -name nederlands.locale ! -name slovak.locale | xargs --no-run-if-empty rm
	# ignore the .version file for package  comparison
	DONT_STRIP=$(NEUTRINO_NOSTRIP) CMP_IGNORE="/.version" $(OPKG_SH) $(BUILD_TMP)/neutrino-control
	$(RM_PKGPREFIX)

neutrino-clean:
	-make -C $(N_OBJDIR) uninstall
	-make -C $(N_OBJDIR) distclean
	-rm $(N_OBJDIR)/config.status
	-rm $(D)/neutrino

PHONY += neutrino-clean neutrino-system neutrino-system-seife
