
-include $(BASE_DIR)/make/pc-playfiles.mk

n_play ?= dummy.ts
n_prog ?= usr/bin/ffplay-ext

play-neutrino:
	cd $(PC_INSTALL); \
		export LD_LIBRARY_PATH=$(PC_INSTALL)/lib:$(PC_INSTALL)/usr/lib:$(LD_LIBRARY_PATH); \
		export PATH=$(PC_INSTALL)/var/bin:$(PC_INSTALL)/var/sbin:$(PC_INSTALL)/usr/bin:$(PC_INSTALL)/usr/sbin:$(PC_INSTALL)/bin:$(PC_INSTALL)/sbin:$(PATH); \
		if [ "$(USE_GDB)" = "1" ]; then \
			rm -f /usr/bin/gdb; \
			ln -s /Data/coolstream/build/bs-pc/host/bin/gdb /usr/bin/gdb; \
			ddd $(n_prog); \
		else \
			$(n_prog) $(n_play); \
		fi;

gdb-neutrino:
	make run-neutrino USE_GDB=1

kill-neutrino:
	@P=$$(pidof neutrino) > /dev/null; \
	if [ ! "$$P" = "" ]; then \
		echo "kill neutrino"; \
		killall neutrino; \
		sleep 2; \
		P=$$(pidof neutrino) > /dev/null; \
		if [ ! "$$P" = "" ]; then \
			echo "kill -9 neutrino"; \
			killall -9 neutrino; \
		fi; \
	fi;

run-neutrino: $(PC_INSTALL)/bin/neutrino
	make kill-neutrino
	cd $(PC_INSTALL); \
		export LD_LIBRARY_PATH=$(PC_INSTALL)/lib:$(PC_INSTALL)/usr/lib:$(LD_LIBRARY_PATH); \
		export PATH=$(PC_INSTALL)/var/bin:$(PC_INSTALL)/var/sbin:$(PC_INSTALL)/usr/bin:$(PC_INSTALL)/usr/sbin:$(PC_INSTALL)/bin:$(PC_INSTALL)/sbin:$(PATH); \
		export SIMULATE_FE=1; \
		if [ "$(USE_GDB)" = "1" ]; then \
			rm -f /usr/bin/gdb; \
			ln -s /Data/coolstream/build/bs-pc/host/bin/gdb /usr/bin/gdb; \
			ddd bin/neutrino; \
		else \
			NSF=$(PC_INSTALL)/tmp/neutrino.sh; \
			mkdir -p $(PC_INSTALL)/tmp; \
			echo "#!/bin/bash"       > $$NSF; \
			echo ""                 >> $$NSF; \
			echo "cd $(PC_INSTALL)" >> $$NSF; \
			echo "bin/neutrino &"   >> $$NSF; \
			echo "bin/sh"           >> $$NSF; \
			chmod 0755 $$NSF; \
			$$NSF; \
			rm -f $$NSF; \
		fi; \
		chown -R micha:users $(PC_INSTALL) | true
	@make kill-neutrino
	@echo ""
	@echo "Haben fertig..."
	@echo ""
