# makefile to build crosstool

CROSSTOOL_NG_VER = $(CT_VER_PC)

## PC crosstool ###############################################

CT_NG_CONFIG = $(PATCHES)/ct-ng-1.20/ct-ng-1.21.0-1-pc.config

crosstool: $(CROSS_DIR)/bin/$(TARGET)-gcc

$(CROSS_DIR)/bin/$(TARGET)-gcc: $(ARCHIVE)/crosstool-ng-$(CROSSTOOL_NG_VER).tar.xz
	make $(BUILD_TMP)
	if [ ! -e $(CROSS_DIR) ]; then \
		mkdir -p $(CROSS_DIR); \
	fi;
	$(REMOVE)/crosstool-ng-$(CROSSTOOL_NG_VER)
	$(UNTAR)/crosstool-ng-$(CROSSTOOL_NG_VER).tar.xz
	mkdir -p $(BUILD_TMP)/crosstool-ng-$(CROSSTOOL_NG_VER)/targets/src
	set -e; unset CONFIG_SITE; cd $(BUILD_TMP)/crosstool-ng-$(CROSSTOOL_NG_VER); \
		\
		cp -a $(CT_NG_CONFIG) .config; \
		\
		NUM_CPUS=$$(expr `getconf _NPROCESSORS_ONLN` \* 2); \
		MEM_512M=$$(awk '/MemTotal/ {M=int($$2/1024/512); print M==0?1:M}' /proc/meminfo); \
		test $$NUM_CPUS -gt $$MEM_512M && NUM_CPUS=$$MEM_512M; \
		test $$NUM_CPUS -lt 1 && NUM_CPUS=1; \
		sed -i "s@^CT_PARALLEL_JOBS=.*@CT_PARALLEL_JOBS=$$NUM_CPUS@" .config; \
		\
		export CST_BASE_DIR=$(BASE_DIR); \
		export LD_LIBRARY_PATH=; \
		test -f ./configure || ./bootstrap && \
		./configure \
			--enable-local \
			--host=$(TARGET); \
		MAKELEVEL=0 make; \
		chmod 0755 ct-ng; \
		./ct-ng oldconfig; \
		./ct-ng build
	ln -sf sys-root/lib $(CROSS_DIR)/$(TARGET)/

############################################

crossmenuconfig: $(ARCHIVE)/crosstool-ng-$(CROSSTOOL_NG_VER).tar.xz
	make $(BUILD_TMP)
	$(REMOVE)/crosstool-ng-$(CROSSTOOL_NG_VER)
	$(UNTAR)/crosstool-ng-$(CROSSTOOL_NG_VER).tar.xz
	set -e; unset CONFIG_SITE; cd $(BUILD_TMP)/crosstool-ng-$(CROSSTOOL_NG_VER); \
		cp -a $(CT_NG_CONFIG) .config; \
		test -f ./configure || ./bootstrap && \
		./configure --enable-local; MAKELEVEL=0 make; chmod 0755 ct-ng; \
		./ct-ng menuconfig

############################################
