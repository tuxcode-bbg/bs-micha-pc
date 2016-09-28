# Makefile to build system tools

$(D)/vsftpd: $(D)/openssl $(ARCHIVE)/vsftpd-$(VSFTPD_VER).tar.gz | $(TARGETPREFIX)
	$(RM_PKGPREFIX)
	$(UNTAR)/vsftpd-$(VSFTPD_VER).tar.gz
	set -e; cd $(BUILD_TMP)/vsftpd-$(VSFTPD_VER); \
		$(PATCH)/vsftpd-ssl.diff; \
		make clean; \
		TARGETPREFIX=$(TARGETPREFIX) make CC=$(TARGET)-gcc LIBS="-lcrypt -lcrypto -lssl" CFLAGS="-pipe -O2 -g0 -I$(TARGETPREFIX)/include" LDFLAGS="$(LD_FLAGS) -Wl,-rpath-link,$(TARGETLIB)"
	install -d $(PKGPREFIX)/share/empty
	install -D -m 755 $(BUILD_TMP)/vsftpd-$(VSFTPD_VER)/vsftpd $(PKGPREFIX)/sbin/vsftpd
	install -D -m 644 $(SCRIPTS)/vsftpd.conf $(PKGPREFIX_BASE)/etc/vsftpd.conf
	install -D -m 644 $(SCRIPTS)/banner.ftp $(PKGPREFIX_BASE)/etc/banner.ftp
	install -D -m 755 $(SCRIPTS)/vsftpd.init $(PKGPREFIX_BASE)/etc/init.d/vsftpd
	# it is important that vsftpd is started *before* inetd to override busybox ftpd...
	ln -sf vsftpd $(PKGPREFIX_BASE)/etc/init.d/S53vsftpd
	if [ "$(NO_USR_BUILD)" = "1" ]; then \
		mkdir -p $(PKGPREFIX)/usr; \
		mv $(PKGPREFIX)/share $(PKGPREFIX)/usr; \
		ln -sf usr/share $(PKGPREFIX)/share; \
	fi;
	cp -a $(PKGPREFIX_BASE)/* $(TARGETPREFIX_BASE)/
	PKG_VER=$(VSFTPD_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/vsftpd
	$(REMOVE)/vsftpd-$(VSFTPD_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/rsync: $(ARCHIVE)/rsync-$(RSYNC_VER).tar.gz | $(TARGETPREFIX)
	$(REMOVE)/rsync-$(RSYNC_VER)
	$(RM_PKGPREFIX)
	$(UNTAR)/rsync-$(RSYNC_VER).tar.gz
	set -e; cd $(BUILD_TMP)/rsync-$(RSYNC_VER); \
		$(CONFIGURE) \
			--prefix=$(DEFAULT_PREFIX) \
			--disable-locale \
			--sysconfdir=/etc \
			--mandir=/.remove; \
		$(MAKE) all; \
		make install-all DESTDIR=$(PKGPREFIX_BASE)
	rm -fr $(PKGPREFIX_BASE)/.remove
	install -D -m 0755 $(SCRIPTS)/rsyncd.init $(PKGPREFIX_BASE)/etc/init.d/rsyncd
	ln -sf rsyncd $(PKGPREFIX_BASE)/etc/init.d/K40rsyncd
	ln -sf rsyncd $(PKGPREFIX_BASE)/etc/init.d/S60rsyncd
	cd $(PKGPREFIX_BASE)/etc && { \
		test -e rsyncd.conf    || cp $(SCRIPTS)/rsyncd.conf . ; \
		test -e rsyncd.secrets || cp $(SCRIPTS)/rsyncd.secrets . ; }; true
	cp -a $(PKGPREFIX_BASE)/* $(TARGETPREFIX_BASE)
	PKG_VER=$(RSYNC_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX_BASE)` \
		$(OPKG_SH) $(CONTROL_DIR)/rsync
	$(REMOVE)/rsync-$(RSYNC_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/procps: $(D)/libncurses $(ARCHIVE)/procps-$(PROCPS_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/procps-$(PROCPS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/procps-$(PROCPS_VER); \
		$(PATCH)/procps-3.2.8-avoid-ICE-with-gcc-4.3.2-arm.diff; \
		$(PATCH)/procps-3.2.8-fix-unknown-HZ-compatible.diff; \
		make CC=$(TARGET)-gcc LDFLAGS="$(LD_FLAGS)" \
			CPPFLAGS="-pipe -O2 -g -I$(TARGETPREFIX)/include -I$(TARGETPREFIX)/include/ncurses -D__GNU_LIBRARY__" proc/libproc-$(PROCPS_VER).so; \
		make CC=$(TARGET)-gcc LDFLAGS="$(LD_FLAGS) proc/libproc-$(PROCPS_VER).so" \
			CPPFLAGS="-pipe -O2 -g -I$(TARGETPREFIX)/include -I$(TARGETPREFIX)/include/ncurses -D__GNU_LIBRARY__" top ps/ps; \
		mkdir -p $(TARGETPREFIX)/bin; \
		rm -f $(TARGETPREFIX)/bin/ps $(TARGETPREFIX)/bin/top; \
		install -m 755 top ps/ps $(TARGETPREFIX)/bin; \
		install -m 755 proc/libproc-$(PROCPS_VER).so $(TARGETPREFIX)/lib
	$(RM_PKGPREFIX)
	$(REMOVE)/procps-$(PROCPS_VER)
	mkdir -p $(PKGPREFIX)/lib $(PKGPREFIX)/bin
	cp -a $(TARGETPREFIX)/bin/{ps,top} $(PKGPREFIX)/bin
	cp -a $(TARGETPREFIX)/lib/libproc-$(PROCPS_VER).so $(PKGPREFIX)/lib
	PKG_VER=$(PROCPS_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/procps
	$(RM_PKGPREFIX)
	touch $@

$(D)/busybox: $(ARCHIVE)/busybox-$(BUSYBOX_VER).tar.bz2 | $(TARGETPREFIX)
	rm -fr $(BUILD_TMP)/busybox-$(BUSYBOX_VER)
	$(UNTAR)/busybox-$(BUSYBOX_VER).tar.bz2
	rm -rf $(BUILD_TMP)/bb-control
	$(RM_PKGPREFIX)
	set -e; cd $(BUILD_TMP)/busybox-$(BUSYBOX_VER); \
	\
		if [ "$(BUSYBOX_VER)" = "1.21.0" ]; then \
			$(PATCH)/bb_fixes-1.21.0/busybox-1.21.0-mdev.patch; \
			$(PATCH)/bb_fixes-1.21.0/busybox-1.21.0-platform.patch; \
			$(PATCH)/bb_fixes-1.21.0/busybox-1.21.0-xz.patch; \
			$(PATCH)/bb_fixes-1.21.0/busybox-1.21.0-ntfs.patch; \
		fi; \
		if [ "$(BUSYBOX_VER)" = "1.23.1" ]; then \
			$(PATCH)/bb_fixes-1.23.1/busybox-1.23.1-modprobe-small.patch; \
			$(PATCH)/bb_fixes-1.23.1/busybox-1.23.1-dc.patch; \
			$(PATCH)/bb_fixes-1.23.1/busybox-1.23.1-wget.patch; \
			$(PATCH)/bb_fixes-1.23.1/busybox-1.23.1-modinfo.patch; \
		fi; \
	\
		$(PATCH)/busybox-1.18-hack-init-s-console.patch; \
		$(PATCH)/busybox-mdev-1.21.c.diff; \
		$(PATCH)/busybox-1.20-ifupdown.c.diff; \
		if [ "$(BUSYBOX_VER)" = "1.21.0" ]; then \
			cp $(PATCHES)/$(PLATFORM)/busybox-$(PLATFORM)-1.21.0.config .config; \
		else \
			cp $(PATCHES)/$(PLATFORM)/busybox-$(PLATFORM)-1.23.1.config .config; \
		fi; \
		sed -i -e 's#^CONFIG_PREFIX.*#CONFIG_PREFIX="$(PKGPREFIX_BASE)"#' .config; \
		grep -q DBB_BT=AUTOCONF_TIMESTAMP Makefile.flags && \
		sed -i 's#AUTOCONF_TIMESTAMP#"\\"$(PLATFORM)\\""#' Makefile.flags || true; \
		$(BUILDENV) $(MAKE) busybox CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)"; \
		make install CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)"
	install -m 0755 $(SCRIPTS)/run-parts $(PKGPREFIX_BASE)/bin
	cp -a $(PKGPREFIX_BASE)/* $(TARGETPREFIX_BASE)
	cp -a $(CONTROL_DIR)/busybox $(BUILD_TMP)/bb-control
	# "auto-provides/conflicts". let's hope opkg can deal with this...
	printf "Provides:" >> $(BUILD_TMP)/bb-control/control
	for i in `find $(PKGPREFIX_BASE)/ ! -type d ! -name busybox`; do printf " `basename $$i`," >> $(BUILD_TMP)/bb-control/control; done
	sed -i 's/,$$//' $(BUILD_TMP)/bb-control/control
	sed -i 's/\(^Provides:\)\(.*$$\)/\1\2\nConflicts:\2/' $(BUILD_TMP)/bb-control/control
	echo >> $(BUILD_TMP)/bb-control/control
	PKG_VER=$(BUSYBOX_VER) $(OPKG_SH) $(BUILD_TMP)/bb-control
	$(REMOVE)/busybox-$(BUSYBOX_VER) $(BUILD_TMP)/bb-control
	$(RM_PKGPREFIX)
	touch $@

$(D)/e2fsprogs: $(ARCHIVE)/e2fsprogs-$(E2FSPROGS_VER).tar.gz | $(TARGETPREFIX)
	$(RM_PKGPREFIX)
	$(UNTAR)/e2fsprogs-$(E2FSPROGS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/e2fsprogs-$(E2FSPROGS_VER); \
		ln -sf /bin/true ./ldconfig; \
		CC=$(TARGET)-gcc \
		RANLIB=$(TARGET)-ranlib \
		CFLAGS="-Os" \
		PATH=$(BUILD_TMP)/e2fsprogs-$(E2FSPROGS_VER):$(PATH) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix=/ \
			--infodir=/.remove \
			--mandir=/.remove \
			--enable-elf-shlibs \
			--enable-htree \
			--disable-profile \
			--disable-e2initrd-helper \
			--disable-debugfs \
			--disable-imager \
			--disable-resizer \
			--disable-uuidd \
			--enable-fsck \
			--disable-defrag \
			--with-gnu-ld \
			--enable-symlink-install \
			--disable-nls; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(PKGPREFIX_BASE); \
		$(MAKE) -C lib/uuid  install DESTDIR=$(PKGPREFIX_BASE); \
		$(MAKE) -C lib/blkid install DESTDIR=$(PKGPREFIX_BASE); \
		:
	$(REMOVE)/e2fsprogs-$(E2FSPROGS_VER) $(PKGPREFIX_BASE)/.remove
	cp -a --remove-destination $(PKGPREFIX_BASE)/* $(TARGETPREFIX_BASE)/
	if [ ! $(PKG_CONFIG_PATH_BASE) = $(PKG_CONFIG_PATH) ]; then \
		mv $(PKG_CONFIG_PATH_BASE)/uuid.pc $(PKG_CONFIG_PATH); \
		mv $(PKG_CONFIG_PATH_BASE)/blkid.pc $(PKG_CONFIG_PATH); \
	fi;
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/uuid.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/blkid.pc
	cd $(PKGPREFIX_BASE) && rm sbin/badblocks sbin/dumpe2fs sbin/logsave \
		sbin/e2undo sbin/filefrag sbin/e2freefrag bin/chattr bin/lsattr bin/uuidgen \
		lib/*.so && rm -r lib/pkgconfig include && rm -f lib/*.a
	PKG_VER=$(E2FSPROGS_VER) $(OPKG_SH) $(CONTROL_DIR)/e2fsprogs
	$(RM_PKGPREFIX)
	touch $@

$(TARGETPREFIX)/lib/libuuid.so.1:
	@echo
	@echo "to build libuuid.so.1, you have to build either the 'e2fsprogs'"
	@echo "or the 'libuuid' target. Using 'e2fsprogs' is recommended."
	@echo
	@false

$(D)/ntfs-3g: $(ARCHIVE)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER).tgz | $(TARGETPREFIX)
	$(UNTAR)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER).tgz
	set -e; cd $(BUILD_TMP)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER); \
		CFLAGS="-pipe -O2 -g" ./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix= \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-ldconfig \
			--disable-ntfsprogs \
			--disable-static \
			--enable-silent-rules \
			; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX_BASE)
	$(REMOVE)/ntfs-3g_ntfsprogs-$(NTFS_3G_VER) $(PKGPREFIX_BASE)/.remove
	cp -a $(PKGPREFIX_BASE)/* $(TARGETPREFIX_BASE)
	if [ ! $(PKG_CONFIG_PATH_BASE) = $(PKG_CONFIG_PATH) ]; then \
		mv $(PKG_CONFIG_PATH_BASE)/libntfs-3g.pc $(PKG_CONFIG_PATH); \
	fi;
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libntfs-3g.pc
	rm -r $(PKGPREFIX_BASE)/include $(PKGPREFIX_BASE)/lib/*.la $(PKGPREFIX_BASE)/lib/*.so \
		$(PKGPREFIX_BASE)/lib/pkgconfig/ $(PKGPREFIX_BASE)/bin/ntfs-3g.{usermap,secaudit}
	find $(PKGPREFIX_BASE) -name '*lowntfs*' | xargs rm
	PKG_VER=$(NTFS_3G_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX_BASE)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX_BASE)` \
		$(OPKG_SH) $(CONTROL_DIR)/ntfs-3g
	$(RM_PKGPREFIX)
	touch $@

ifeq ($(PLATFORM), apollo)
SMB_PREFIX=/usr
endif
ifeq ($(PLATFORM), kronos)
SMB_PREFIX=/usr
endif
ifeq ($(PLATFORM), nevis)
SMB_PREFIX=/opt/pkg
endif
ifeq ($(PLATFORM), pc)
SMB_PREFIX=/usr
endif
$(D)/samba2: $(ARCHIVE)/samba-$(SAMBA2_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/samba-$(SAMBA2_VER).tar.gz
	$(RM_PKGPREFIX)
	set -e; cd $(BUILD_TMP)/samba-$(SAMBA2_VER); \
		$(PATCH)/samba_2.2.12.diff; \
		$(PATCH)/samba_2.2.12-noprint.diff; \
		cd source; \
		rm -f config.guess; \
		rm -f config.sub; \
		autoconf configure.in > configure; \
		automake --add-missing || true; \
		./configure \
			--build=$(BUILD) \
			--prefix=$(SMB_PREFIX) \
			samba_cv_struct_timespec=yes \
			samba_cv_HAVE_GETTIMEOFDAY_TZ=yes \
			--with-configdir=$(SMB_PREFIX)/etc \
			--with-privatedir=$(SMB_PREFIX)/etc/samba/private \
			--with-lockdir=/var/lock \
			--with-piddir=/var/run \
			--with-logfilebase=/var/log/ \
			--disable-cups \
			--with-swatdir=$(PKGPREFIX)/swat; \
		$(MAKE) clean || true; \
		$(MAKE) bin/make_smbcodepage bin/make_unicodemap CC=$(CC); \
		install -d $(PKGPREFIX)$(SMB_PREFIX)/lib/codepages; \
		./bin/make_smbcodepage c 850 codepages/codepage_def.850 \
			$(PKGPREFIX)$(SMB_PREFIX)/lib/codepages/codepage.850; \
		./bin/make_unicodemap 850 codepages/CP850.TXT \
			$(PKGPREFIX)$(SMB_PREFIX)/lib/codepages/unicode_map.850; \
		./bin/make_unicodemap ISO8859-1 codepages/CPISO8859-1.TXT \
			$(PKGPREFIX)$(SMB_PREFIX)/lib/codepages/unicode_map.ISO8859-1
	$(MAKE) -C $(BUILD_TMP)/samba-$(SAMBA2_VER)/source distclean
	set -e; cd $(BUILD_TMP)/samba-$(SAMBA2_VER)/source; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(SMB_PREFIX) \
			samba_cv_struct_timespec=yes \
			samba_cv_HAVE_GETTIMEOFDAY_TZ=yes \
			samba_cv_HAVE_IFACE_IFCONF=yes \
			samba_cv_HAVE_EXPLICIT_LARGEFILE_SUPPORT=yes \
			samba_cv_HAVE_OFF64_T=yes \
			samba_cv_have_longlong=yes \
			--with-configdir=$(SMB_PREFIX)/etc \
			--with-privatedir=$(SMB_PREFIX)/etc/samba/private \
			--with-lockdir=/var/lock \
			--with-piddir=/var/run \
			--with-logfilebase=/var/log/ \
			--disable-cups \
			--with-swatdir=$(PKGPREFIX)/swat \
			; \
		$(MAKE) bin/smbd bin/nmbd bin/smbclient bin/smbmount bin/smbmnt bin/smbpasswd
	install -d $(PKGPREFIX)$(SMB_PREFIX)/bin
	for i in smbd nmbd; do \
		install $(BUILD_TMP)/samba-$(SAMBA2_VER)/source/bin/$$i $(PKGPREFIX)$(SMB_PREFIX)/bin; \
	done
	install -d $(PKGPREFIX)$(SMB_PREFIX)/etc/samba/private
	install -d $(PKGPREFIX)$(SMB_PREFIX)/etc/init.d
	install $(SCRIPTS)/smb.conf $(PKGPREFIX)$(SMB_PREFIX)/etc
	install -m 755 $(SCRIPTS)/samba2.init $(PKGPREFIX)$(SMB_PREFIX)/etc/init.d/samba
	ln -s samba $(PKGPREFIX)$(SMB_PREFIX)/etc/init.d/S99samba
	ln -s samba $(PKGPREFIX)$(SMB_PREFIX)/etc/init.d/K01samba
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(TARGET)-strip $(PKGPREFIX)$(SMB_PREFIX)/bin/*
	DONT_STRIP=1 $(OPKG_SH) $(CONTROL_DIR)/samba2/server
	rm -rf $(PKGPREFIX)/*
	install -d $(PKGPREFIX)$(SMB_PREFIX)/bin
	for i in smbclient smbmount smbmnt smbpasswd; do \
		install $(BUILD_TMP)/samba-$(SAMBA2_VER)/source/bin/$$i $(PKGPREFIX)$(SMB_PREFIX)/bin; \
	done
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	$(OPKG_SH) $(CONTROL_DIR)/samba2/client
	$(REMOVE)/samba-$(SAMBA2_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/portmap: $(ARCHIVE)/portmap-$(PORTMAP-VER).tgz
	$(UNTAR)/portmap-$(PORTMAP-VER).tgz
	set -e; cd $(BUILD_TMP)/portmap_$(PORTMAP-VER); \
		$(PATCH)/portmap_6.0-nocheckport.diff; \
		$(BUILDENV) $(MAKE) NO_TCP_WRAPPER=1 DAEMON_UID=65534 DAEMON_GID=65535 CC="$(TARGET)-gcc"; \
		install -m 0755 portmap $(TARGETPREFIX)/sbin; \
		install -m 0755 pmap_dump $(TARGETPREFIX)/sbin; \
		install -m 0755 pmap_set $(TARGETPREFIX)/sbin
	$(REMOVE)/portmap_$(PORTMAP-VER)
	touch $@

$(D)/unfsd: $(D)/libflex $(D)/portmap $(ARCHIVE)/unfs3-$(UNFS3-VER).tar.gz
	$(UNTAR)/unfs3-$(UNFS3-VER).tar.gz
	set -e; cd $(BUILD_TMP)/unfs3-$(UNFS3-VER); \
		$(CONFIGURE) --build=$(BUILD) --host=$(TARGET) --target=$(TARGET) \
			--prefix= --mandir=/.remove; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	rm -f -r $(TARGETPREFIX)/.remove
	$(RM_PKGPREFIX)
	mkdir -p $(PKGPREFIX)/sbin
	install -m 755 -D $(SCRIPTS)/nfsd.init $(TARGETPREFIX)/etc/init.d/nfsd
	install -m 755 -D $(SCRIPTS)/nfsd.init $(PKGPREFIX)/etc/init.d/nfsd
	ln -s nfsd $(PKGPREFIX)/etc/init.d/S99nfsd # needs to start after modules are loaded
	ln -s nfsd $(PKGPREFIX)/etc/init.d/K01nfsd
	cp -a $(TARGETPREFIX)/sbin/{unfsd,portmap} $(PKGPREFIX)/sbin
	$(OPKG_SH) $(CONTROL_DIR)/unfsd
	$(REMOVE)/unfs3-$(UNFS3-VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/fbshot: $(TARGETPREFIX_BASE)/bin/fbshot
	touch $@

$(TARGETPREFIX_BASE)/bin/fbshot: $(ARCHIVE)/fbshot-$(FBSHOT_VER).tar.gz $(PATCHES)/fbshot-0.3-32bit_cs_fb.diff $(D)/libpng | $(TARGETPREFIX)
	$(UNTAR)/fbshot-$(FBSHOT_VER).tar.gz
	set -e; cd $(BUILD_TMP)/fbshot-$(FBSHOT_VER); \
		$(PATCH)/fbshot-0.3-32bit_cs_fb.diff; \
		if [ $(PNG_VER_X) -gt 12 ]; then \
			$(PATCH)/fbshot-zlib.diff; \
		fi; \
		$(TARGET)-gcc -DHW_$(PLATFORM) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) fbshot.c -lpng -lz -o $@
	$(REMOVE)/fbshot-$(FBSHOT_VER)

# old valgrind for TD with old toolchain (linuxthreads glibc)
$(D)/valgrind-old: $(ARCHIVE)/valgrind-3.3.1.tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/valgrind-3.3.1.tar.bz2
	set -e; cd $(BUILD_TMP)/valgrind-3.3.1; \
		export ac_cv_path_GDB=/opt/pkg/bin/gdb; \
		export AR=$(TARGET)-ar; \
		$(CONFIGURE) --prefix=/ --enable-only32bit --enable-tls; \
		make all; \
		make install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/valgrind-3.3.1
	touch $@

ifeq ($(BOXARCH), arm)
VALGRIND_EXTRA_EXPORT = export ac_cv_host=armv7-unknown-linux-gnueabi
else
VALGRIND_EXTRA_EXPORT = :
endif
# newer valgrind is probably only usable with external toolchain and newer glibc (posix threads)
$(DEPDIR)/valgrind: $(ARCHIVE)/valgrind-$(VALGRIND_VER).tar.bz2 | $(TARGETPREFIX)
	$(UNTAR)/valgrind-$(VALGRIND_VER).tar.bz2
	$(RM_PKGPREFIX)
	set -e; cd $(BUILD_TMP)/valgrind-$(VALGRIND_VER); \
		export ac_cv_path_GDB=/opt/pkg/bin/gdb; \
		$(VALGRIND_EXTRA_EXPORT); \
		export AR=$(TARGET)-ar; \
		$(CONFIGURE) --prefix=/opt/pkg --enable-only32bit --mandir=/.remove --datadir=/.remove; \
		$(MAKE) all; \
		make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove
	mv $(PKGPREFIX)/opt/pkg/lib/pkgconfig/* $(PKG_CONFIG_PATH)
	$(REWRITE_PKGCONF_OPT) $(PKG_CONFIG_PATH)/valgrind.pc
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	rm -rf $(PKGPREFIX)/opt/pkg/include $(PKGPREFIX)/opt/pkg/lib/pkconfig
	rm -rf $(PKGPREFIX)/opt/pkg/lib/valgrind/*.a
	rm -rf $(PKGPREFIX)/opt/pkg/bin/{cg_*,callgrind_*,ms_print} # perl scripts - we don't have perl
	PKG_VER=$(VALGRIND_VER) $(OPKG_SH) $(CONTROL_DIR)/valgrind
	$(REMOVE)/valgrind-$(VALGRIND_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/iperf: $(ARCHIVE)/iperf-$(IPERF-VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/iperf-$(IPERF-VER).tar.gz
	$(RM_PKGPREFIX)
	set -e; cd $(BUILD_TMP)/iperf-$(IPERF-VER); \
		ac_cv_func_malloc_0_nonnull=yes \
		$(BUILDENV) ./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix=/opt/pkg \
			--mandir=/.remove \
			; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove
	install -D -m 0755 $(PKGPREFIX)/opt/pkg/bin/iperf $(TARGETPREFIX)/opt/pkg/bin/iperf
	PKG_VER=$(IPERF-VER) $(OPKG_SH) $(CONTROL_DIR)/iperf
	$(REMOVE)/iperf-$(IPERF-VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/tcpdump: $(D)/libpcap $(ARCHIVE)/tcpdump-$(TCPDUMP-VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/tcpdump-$(TCPDUMP-VER).tar.gz
	set -e; cd $(BUILD_TMP)/tcpdump-$(TCPDUMP-VER); \
		cp -a $(PATCHES)/ppi.h .; \
		echo "ac_cv_linux_vers=2" >> config.cache ; \
		$(CONFIGURE) --prefix= --disable-smb --without-crypto -C --mandir=/.remove; \
		$(MAKE) all; \
		make install DESTDIR=$(PKGPREFIX)
	rm -rf $(PKGPREFIX)/.remove $(PKGPREFIX)/sbin/tcpdump.*
	PKG_VER=$(TCPDUMP-VER) $(OPKG_SH) $(CONTROL_DIR)/tcpdump
	$(REMOVE)/tcpdump-$(TCPDUMP-VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/ntp: $(D)/openssl $(ARCHIVE)/ntp-$(NTP_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/ntp-$(NTP_VER).tar.gz
	$(RM_PKGPREFIX)
	set -e; cd $(BUILD_TMP)/ntp-$(NTP_VER); \
		$(PATCH)/ntp-remove-buildtime2.patch; \
		$(BUILDENV) ./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix= \
			--disable-tick \
			--disable-tickadj \
			--with-yielding-select=yes \
			--without-ntpsnmpd \
			--disable-debugging \
			; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
	cp -a $(PKGPREFIX)/bin/ntpdate $(TARGETPREFIX)/sbin/
	mv -v $(PKGPREFIX)/bin/ntpdate $(PKGPREFIX)/sbin/
	rm -rf $(PKGPREFIX)/bin $(PKGPREFIX)/include $(PKGPREFIX)/lib $(PKGPREFIX)/libexec $(PKGPREFIX)/share
	PKG_VER=$(NTP_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/ntp
	$(REMOVE)/ntp-$(NTP_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/wget: $(D)/e2fsprogs $(D)/openssl $(ARCHIVE)/wget-$(WGET_VER).tar.xz | $(TARGETPREFIX)
	$(UNTAR)/wget-$(WGET_VER).tar.xz
	$(RM_PKGPREFIX)
	set -e; cd $(BUILD_TMP)/wget-$(WGET_VER); \
		ac_cv_path_POD2MAN=no \
		$(BUILDENV) ./configure \
			--disable-nls \
			--disable-opie \
			--disable-digest \
			--with-ssl=openssl \
			--with-libssl-prefix=$(TARGETPREFIX) \
			--with-openssl=yes \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--prefix= \
			; \
		$(MAKE) install DESTDIR=$(PKGPREFIX)
		rm -f $(TARGETPREFIX)/bin/wget; \
		cp -a $(PKGPREFIX)/bin/wget $(TARGETPREFIX)/bin && \
		$(TARGET)-strip $(TARGETPREFIX)/bin/wget
	rm -rf $(PKGPREFIX)/share $(PKGPREFIX)/etc
	PKG_VER=$(WGET_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/wget
	$(REMOVE)/wget-$(WGET_VER)
	$(RM_PKGPREFIX)
	touch $@

mkimage: $(HOSTPREFIX)/bin/mkimage

$(HOSTPREFIX)/bin/mkimage: $(ARCHIVE)/u-boot-$(UBOOT_VER).tar.bz2
	$(REMOVE)/u-boot-$(UBOOT_VER)
	$(UNTAR)/u-boot-$(UBOOT_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/u-boot-$(UBOOT_VER); \
		make defconfig tools/; \
	cp -a $(BUILD_TMP)/u-boot-$(UBOOT_VER)/tools/mkimage $(HOSTPREFIX)/bin
	cp -a $(BUILD_TMP)/u-boot-$(UBOOT_VER)/tools/mkenvimage $(HOSTPREFIX)/bin
	strip $(HOSTPREFIX)/bin/mkimage
	strip $(HOSTPREFIX)/bin/mkenvimage
	$(REMOVE)/u-boot-$(UBOOT_VER)

$(D)/openvpn: $(D)/killproc $(D)/openssl $(ARCHIVE)/openvpn-$(OPENVPN_VER).tar.xz | $(TARGETPREFIX)
	$(UNTAR)/openvpn-$(OPENVPN_VER).tar.xz
	set -e; cd $(BUILD_TMP)/openvpn-$(OPENVPN_VER); \
		$(CONFIGURE) \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--target=$(TARGET) \
			--disable-lzo \
			--disable-plugins \
			--prefix= \
			; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX)
	rm -fr $(PKGPREFIX)/include $(PKGPREFIX)/share
	cp $(PKGPREFIX)/sbin/openvpn $(TARGETPREFIX)/sbin
	PKG_VER=$(OPENVPN_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/openvpn
	$(REMOVE)/openvpn-$(OPENVPN_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/killproc: $(ARCHIVE)/killproc-$(KILLPROC_VER).tar.gz | $(TARGETPREFIX)
	$(UNTAR)/killproc-$(KILLPROC_VER).tar.gz
	set -e; cd $(BUILD_TMP)/killproc-$(KILLPROC_VER); \
		$(PATCH)/killproc.diff; \
		export TARGET_X=$(TARGET); \
		$(MAKE); \
		cp killproc $(TARGETPREFIX)/sbin
		$(TARGET)-strip $(TARGETPREFIX)/sbin/killproc
	$(REMOVE)/killproc-$(KILLPROC_VER)
	touch $@

$(D)/ncftp: $(ARCHIVE)/ncftp-$(NCFTP_VER)-src.tar.bz2 | $(TARGETPREFIX)
	$(RM_PKGPREFIX)
	$(UNTAR)/ncftp-$(NCFTP_VER)-src.tar.bz2
	set -e; cd $(BUILD_TMP)/ncftp-$(NCFTP_VER); \
		CC=$(TARGET)-gcc $(BUILDENV) \
		./configure $(CONFIGURE_OPTS) \
			--target=$(TARGET) \
			--prefix= \
			; \
		$(MAKE); \
		cp bin/ncftp $(TARGETPREFIX)/bin; \
		cp bin/ncftpget $(TARGETPREFIX)/bin; \
		cp bin/ncftpput $(TARGETPREFIX)/bin
		$(TARGET)-strip $(TARGETPREFIX)/bin/ncftp
		$(TARGET)-strip $(TARGETPREFIX)/bin/ncftpget
		$(TARGET)-strip $(TARGETPREFIX)/bin/ncftpput
	rm -rf $(PKGPREFIX)
	mkdir -p $(PKGPREFIX)/bin
	cp $(TARGETPREFIX)/bin/ncftp $(PKGPREFIX)/bin
	cp $(TARGETPREFIX)/bin/ncftpget $(PKGPREFIX)/bin
	cp $(TARGETPREFIX)/bin/ncftpput $(PKGPREFIX)/bin
	PKG_VER=$(NCFTP_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/ncftp
	$(REMOVE)/ncftp-$(NCFTP_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/parted: $(ARCHIVE)/parted-$(PARTED_VER).tar.xz $(D)/readline | $(TARGETPREFIX)
	## parted-3.2-device-mapper.patch: https://lists.gnu.org/archive/html/bug-parted/2014-07/msg00036.html
	$(UNTAR)/parted-$(PARTED_VER).tar.xz
	set -e; cd $(BUILD_TMP)/parted-$(PARTED_VER); \
		$(PATCH)/parted-3.2-device-mapper.patch; \
		$(CONFIGURE) \
			--prefix= \
			--disable-device-mapper \
			--infodir=/.remove \
			--mandir=/.remove; \
		if [ "$(UCLIBC_BUILD)" = "1" ]; then \
			ICONV_X="-liconv"; \
		else \
			ICONV_X=""; \
		fi; \
		$(MAKE) all LDFLAGS="$(LD_FLAGS)" LIBS="-luuid $$ICONV_X"; \
		make install DESTDIR=$(PKGPREFIX)
	rm -fr $(PKGPREFIX)/.remove
	rm -fr $(PKGPREFIX)/share
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)/
	rm -fr $(PKGPREFIX)/include
	rm -fr $(PKGPREFIX)/lib/pkgconfig
	rm -f $(PKGPREFIX)/lib/*.a
	rm -f $(PKGPREFIX)/lib/*.la
	rm -f $(PKGPREFIX)/lib/*.so
	$(REWRITE_LIBTOOL)/libparted.la
	$(REWRITE_LIBTOOL)/libparted-fs-resize.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libparted.pc
	PKG_VER=$(PARTED_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
			$(OPKG_SH) $(CONTROL_DIR)/parted
	rm -fr $(BUILD_TMP)/parted-$(PARTED_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/exfat-utils: $(ARCHIVE)/exfat-utils-$(EXFAT_UTILS_VER).tar.gz | $(TARGETPREFIX)
	rm -fr $(BUILD_TMP)/exfat-utils-$(EXFAT_UTILS_VER)
	$(RM_PKGPREFIX)
	$(UNTAR)/exfat-utils-$(EXFAT_UTILS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/exfat-utils-$(EXFAT_UTILS_VER); \
		sed -i -e 's/^#error C99-compliant compiler is required/#warning C99-compliant compiler is required/' libexfat/compiler.h; \
		autoreconf --install; \
		$(CONFIGURE) \
			--prefix=$(DEFAULT_PREFIX_BASE) \
			; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX_BASE)
	cp -a $(PKGPREFIX_BASE)/sbin $(TARGETPREFIX_BASE)
	PKG_VER=$(EXFAT_UTILS_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX_BASE)` \
			$(OPKG_SH) $(CONTROL_DIR)/exfat-utils
	rm -fr $(BUILD_TMP)/exfat-utils-$(EXFAT_UTILS_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/fuse-exfat: $(D)/fuse $(ARCHIVE)/fuse-exfat-$(FUSE_EXFAT_VER).tar.gz | $(TARGETPREFIX)
	rm -fr $(BUILD_TMP)/fuse-exfat-$(FUSE_EXFAT_VER)
	$(RM_PKGPREFIX)
	$(UNTAR)/fuse-exfat-$(FUSE_EXFAT_VER).tar.gz
	set -e; cd $(BUILD_TMP)/fuse-exfat-$(FUSE_EXFAT_VER); \
		sed -i -e 's/^#error C99-compliant compiler is required/#warning C99-compliant compiler is required/' libexfat/compiler.h; \
		autoreconf --install; \
		$(CONFIGURE) \
			--prefix=$(DEFAULT_PREFIX_BASE) \
			; \
		if [ "$(UCLIBC_BUILD)" = "1" ]; then \
			ICONV_X="-liconv"; \
		else \
			ICONV_X=""; \
		fi; \
		$(MAKE) LIBS="$$ICONV_X"; \
		make install DESTDIR=$(PKGPREFIX_BASE)
	cp -a $(PKGPREFIX_BASE)/sbin $(TARGETPREFIX_BASE)
	PKG_VER=$(FUSE_EXFAT_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX_BASE)` \
			$(OPKG_SH) $(CONTROL_DIR)/fuse-exfat
	rm -fr $(BUILD_TMP)/fuse-exfat-$(FUSE_EXFAT_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/iptables: $(ARCHIVE)/iptables-$(IPTABLES_VER).tar.bz2 | $(TARGETPREFIX)
	$(REMOVE)/iptables-$(IPTABLES_VER)
	$(RM_PKGPREFIX)
	$(UNTAR)/iptables-$(IPTABLES_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/iptables-$(IPTABLES_VER); \
		$(CONFIGURE) \
			--prefix=$(DEFAULT_PREFIX) \
			--mandir=/.remove; \
		$(MAKE); \
		make install DESTDIR=$(PKGPREFIX_BASE)
	mkdir -p $(TARGETPREFIX)/lib/pkgconfig
	mkdir -p $(TARGETPREFIX)/include
	cp -a $(PKGPREFIX)/lib/pkgconfig/* $(TARGETPREFIX)/lib/pkgconfig
	cp -a $(PKGPREFIX)/include/* $(TARGETPREFIX)/include
	rm -rf $(PKGPREFIX)/lib/pkgconfig
	rm -rf $(PKGPREFIX)/include
	rm -rf $(PKGPREFIX_BASE)/.remove
	cp -a $(PKGPREFIX)/* $(TARGETPREFIX)
	rm -f $(PKGPREFIX)/lib/*.la
	$(REWRITE_LIBTOOL)/libip4tc.la
	$(REWRITE_LIBTOOL)/libip6tc.la
	$(REWRITE_LIBTOOL)/libiptc.la
	$(REWRITE_LIBTOOL)/libxtables.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libip4tc.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libip6tc.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libiptc.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/xtables.pc
	PKG_VER=$(IPTABLES_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/iptables
	$(REMOVE)/iptables-$(IPTABLES_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/iptables-rules:
	$(RM_PKGPREFIX)
	mkdir -p $(PKGPREFIX_BASE)
	cp -a $(SCRIPTS)/iptables-rules/* $(PKGPREFIX_BASE)
	PKG_VER=$(IPTABLES_RULES_VER) \
		$(OPKG_SH) $(CONTROL_DIR)/iptables-rules
	$(RM_PKGPREFIX)
	touch $@

$(D)/systemlibs-dummy:
	$(RM_PKGPREFIX)
#	mkdir -p $(PKGPREFIX_BASE)/var/bin
	install -d $(PKGPREFIX_BASE)/var/bin
	install -D -m 755 $(SCRIPTS)/find-system-libs.sh $(PKGPREFIX_BASE)/var/bin/find-system-libs.sh
	PKG_VER=$(SYSTEMLIBS_DUMMY_VER) \
		$(OPKG_SH) $(CONTROL_DIR)/systemlibs-dummy
	$(RM_PKGPREFIX)
	touch $@



FONTCONFIG_VER = 2.11.93

$(ARCHIVE)/fontconfig-$(FONTCONFIG_VER).tar.bz2:
	$(WGET) http://www.freedesktop.org/software/fontconfig/release/fontconfig-$(FONTCONFIG_VER).tar.bz2


$(D)/fontconfig: $(ARCHIVE)/fontconfig-$(FONTCONFIG_VER).tar.bz2 | $(TARGETPREFIX)
	$(REMOVE)/fontconfig-$(FONTCONFIG_VER)
	$(RM_PKGPREFIX)
	$(UNTAR)/fontconfig-$(FONTCONFIG_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/fontconfig-$(FONTCONFIG_VER); \
		$(BUILDENV) \
		FREETYPE_CFLAGS="-I$(TARGETPREFIX)/include/freetype2" \
		FREETYPE_LIBS="-L$(TARGETPREFIX)/lib -lfreetype" \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(DEFAULT_PREFIX) \
			--sysconfdir=/etc \
			--enable-libxml2 \
			--disable-docs \
			; \
		$(MAKE) all; \
		make install DESTDIR=$(PKGPREFIX_BASE); \
		make install DESTDIR=$(TARGETPREFIX_BASE)
	rm -rf $(PKGPREFIX)/lib/pkgconfig
	rm -rf $(PKGPREFIX)/include
	rm -f $(PKGPREFIX)/lib/*.la
	rm -f $(PKGPREFIX)/lib/*.so
	$(REWRITE_LIBTOOL)/libfontconfig.la
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fontconfig.pc
	PKG_VER=$(FONTCONFIG_VER) \
		PKG_DEP=`opkg-find-requires.sh $(PKGPREFIX)` \
		PKG_PROV=`opkg-find-provides.sh $(PKGPREFIX)` \
		$(OPKG_SH) $(CONTROL_DIR)/fontconfig
	$(REMOVE)/fontconfig-$(FONTCONFIG_VER)
	$(RM_PKGPREFIX)
	touch $@

$(D)/sfdisk-static: $(ARCHIVE)/util-linux-$(UTIL_LINUX_VER).tar.xz | $(TARGETPREFIX)
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	$(RM_PKGPREFIX)
	$(UNTAR)/util-linux-$(UTIL_LINUX_VER).tar.xz
	set -e; cd $(BUILD_TMP)/util-linux-$(UTIL_LINUX_VER); \
		if [ "$(UCLIBC_BUILD)" = "1" ]; then \
			$(PATCH)/util-linux/0001-sscanf-no-ms-as.patch; \
			$(PATCH)/util-linux/0003-c.h-define-mkostemp-for-older-version-of-uClibc.patch; \
		fi; \
		$(PATCH)/util-linux/0002-program-invocation-short-name.patch; \
		$(BUILDENV) \
		NCURSES_CFLAGS="-I$(TARGETPREFIX)/include/ncurses" \
		NCURSES_LIBS="-L$(TARGETPREFIX)/lib -lncurses" \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(DEFAULT_PREFIX) \
			--sysconfdir=/etc \
			--mandir=/.remove \
			--docdir=/.remove \
			--without-python \
			--without-user \
			--with-ncurses \
			--disable-login \
			--disable-su \
			--disable-fsck \
			--disable-uuidd \
			--disable-tls \
			--disable-libmount \
			--disable-mount \
			--disable-losetup \
			--disable-zramctl \
			--disable-fsck \
			--disable-mountpoint \
			--disable-fallocate \
			--disable-unshare \
			--disable-nsenter \
			--disable-setpriv \
			--disable-eject \
			--disable-agetty \
			--disable-cramfs \
			--disable-bfs \
			--disable-minix \
			--disable-hwclock \
			--disable-wdctl \
			--disable-switch_root \
			--disable-pivot_root \
			--disable-kill \
			--disable-last \
			--disable-utmpdump \
			--disable-mesg \
			--disable-raw \
			--disable-rename \
			--disable-nologin \
			--disable-sulogin \
			--disable-su \
			--disable-runuser \
			--disable-ul \
			--disable-more \
			--disable-pg \
			--disable-setterm \
			--disable-schedutils \
			--disable-partx \
			--disable-fdformat \
			--disable-wall \
			--disable-bash-completion \
			--disable-rpath \
			--disable-nls \
			--enable-static-programs=sfdisk \
			; \
		$(MAKE); \
		install -D -m 755 sfdisk.static $(PKGPREFIX_BASE)/sbin/sfdisk; \
		install -D -m 755 sfdisk.static $(TARGETPREFIX_BASE)/sbin/sfdisk
	PKG_VER=$(UTIL_LINUX_VER) \
		$(OPKG_SH) $(CONTROL_DIR)/util-linux/sfdisk-static
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	$(RM_PKGPREFIX)
	touch $@


SYSTEM_TOOLS = $(D)/rsync $(D)/procps $(D)/busybox $(D)/e2fsprogs $(D)/vsftpd $(D)/opkg 
SYSTEM_TOOLS += $(D)/ntfs-3g $(D)/ntp $(D)/openvpn $(D)/xupnpd $(D)/iptables
ifeq ($(UCLIBC_BUILD), 1)
SYSTEM_TOOLS += $(D)/libiconv
endif

ifneq ($(PLATFORM), pc)
SYSTEM_TOOLS += $(D)/exfat-utils $(D)/fuse-exfat
SYSTEM_TOOLS += $(D)/sfdisk-static $(D)/ncftp $(HOSTPREFIX)/bin/mkimage
endif

system-tools: $(SYSTEM_TOOLS)
system-tools-opt: $(D)/samba2
system-tools-all: system-tools system-tools-opt

PHONY += system-tools system-tools-opt system-tools-all
