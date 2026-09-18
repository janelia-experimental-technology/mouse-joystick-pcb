KICAD_CONFIG_HOME := $(CURDIR)/.guix/.config/kicad
KICAD_CONFIG_DIR := $(KICAD_CONFIG_HOME)/10.0
KICAD_COMMON_JSON := $(KICAD_CONFIG_DIR)/kicad_common.json
XDG_CACHE_HOME := /tmp/codex-kicad-cache
GUIX_TIME_MACHINE = guix time-machine -C .guix/channels.scm
GUIX_MANIFEST_AGENT ?= .guix/manifest-agent.scm
GUIX_MANIFEST_KICAD ?= .guix/manifest-kicad.scm
GUIX_MANIFEST_KICAD_LOCAL ?= .guix/manifest-kicad-local.scm
GUIX_MANIFEST_FREECAD ?= .guix/manifest-freecad.scm
GUIX_SHELL_EXTRA_OPTIONS ?=
GUIX_SHELL_AGENT = $(GUIX_TIME_MACHINE) -- shell $(GUIX_SHELL_EXTRA_OPTIONS) --pure -m $(GUIX_MANIFEST_AGENT)
GUIX_SHELL_KICAD = $(GUIX_TIME_MACHINE) -- shell $(GUIX_SHELL_EXTRA_OPTIONS) --pure -m $(GUIX_MANIFEST_KICAD)
GUIX_SHELL_FREECAD = $(GUIX_TIME_MACHINE) -- shell $(GUIX_SHELL_EXTRA_OPTIONS) --pure -m $(GUIX_MANIFEST_FREECAD)
GUIX_SHELL = $(GUIX_SHELL_AGENT)

ORB_WEAVER_KICAD_LIBS_CHECKOUT ?= $(firstword $(wildcard $(abspath ../kicad-libs) $(abspath ../orb-weaver-kicad-libs)))
ORB_WEAVER_KICAD_LIBS ?= $(if $(and $(ORB_WEAVER_KICAD_LIBS_CHECKOUT),$(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/kicad/db-libraries/orb_weaver_internal.kicad_dbl)),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT),)
ORB_WEAVER_KICAD_LIBS_AUTO_BUILD ?= 0
GUIX_AGENT_TOOLS_CHECKOUT ?= $(abspath ../guix-agent-tools)
CODEX_GUIX_SHELL ?= $(if $(wildcard $(GUIX_AGENT_TOOLS_CHECKOUT)/bin/codex-guix-shell),$(GUIX_AGENT_TOOLS_CHECKOUT)/bin/codex-guix-shell,codex-guix-shell)
CLAUDE_GUIX_SHELL ?= $(if $(wildcard $(GUIX_AGENT_TOOLS_CHECKOUT)/bin/claude-guix-shell),$(GUIX_AGENT_TOOLS_CHECKOUT)/bin/claude-guix-shell,claude-guix-shell)
BOARD_INTERFACES_CHECKOUT ?= $(abspath ../board-interfaces)
ORB_WEAVER_CONTEXT_CHECKOUT ?= $(abspath ../orb-weaver-context)
MOUSE_JOYSTICKS_MECH_CHECKOUT ?= $(abspath ../mouse-joysticks-mech)
MOUSE_JOYSTICKS_PCB_CHECKOUT ?= $(abspath ../mouse-joysticks-pcb)
TMC51X0_DEV_PCB_CHECKOUT ?= $(abspath ../tmc51x0-driver-dev-pcb)
SYRINGE_PUMP_CHECKOUT ?= $(abspath ../../github/syringe-pump)
M2K_ADAPTER_CHECKOUT ?= $(abspath ../m2k-instrument-port-adapter)
LA5032_ADAPTER_CHECKOUT ?= $(abspath ../la5032-instrument-port-adapter)
AGENT_MEMORY_REPO_CHECKOUT ?= $(abspath ../agent-memory)
AGENT_MEMORY_ENV = $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),GUIX_AGENT_TOOLS_MEMORY_REPO=$(AGENT_MEMORY_REPO_CHECKOUT),)
AGENT_EXTRA_DIRS ?=
PROJECT ?= $(firstword $(wildcard kicad/*.kicad_pro *.kicad_pro examples/*/*.kicad_pro))
FAB_TOOL ?= orb-weaver-kicad-fab
FAB_OUTPUT_DIR ?= $(if $(PROJECT),fab/$(basename $(notdir $(PROJECT))),fab)
FAB_OPTIONS ?=

MANAGED_ENV = KICAD_CONFIG_HOME=$(KICAD_CONFIG_HOME) XDG_CACHE_HOME=$(XDG_CACHE_HOME) $(if $(ORB_WEAVER_KICAD_LIBS),ORB_WEAVER_KICAD_LIBS=$(ORB_WEAVER_KICAD_LIBS))
TLS_ENV = export SSL_CERT_FILE="$${GUIX_ENVIRONMENT}/etc/ssl/certs/ca-certificates.crt"; export GIT_SSL_CAINFO="$$SSL_CERT_FILE"; export CURL_CA_BUNDLE="$$SSL_CERT_FILE"; export SSL_CERT_DIR="$${GUIX_ENVIRONMENT}/etc/ssl/certs"; exec "$$@"
AGENT_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
KICAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_KICAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
FREECAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_FREECAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
MANAGED_SHELL = $(AGENT_MANAGED_SHELL)

LIBS_WORKSPACE := $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT),$(ORB_WEAVER_KICAD_LIBS))
PCB_AGENT_EXTRA_DIRS ?= $(BOARD_INTERFACES_CHECKOUT) $(ORB_WEAVER_CONTEXT_CHECKOUT) $(GUIX_AGENT_TOOLS_CHECKOUT) $(MOUSE_JOYSTICKS_MECH_CHECKOUT) $(MOUSE_JOYSTICKS_PCB_CHECKOUT) $(TMC51X0_DEV_PCB_CHECKOUT) $(SYRINGE_PUMP_CHECKOUT) $(M2K_ADAPTER_CHECKOUT) $(LA5032_ADAPTER_CHECKOUT) $(if $(LIBS_WORKSPACE),$(LIBS_WORKSPACE)) $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT))

.PHONY: clearance-check clearance-baseline help test prepare-kicad-config check-kicad-libs shell kicad-shell kicad-shell-local kicad-version kicad-version-local agent-reflection codex claude agent-project agent-libs agent-both agent-edits kicad-edits kicad-edits-local freecad-edits validate-db fab fab-local

help:
	@printf '%s\n' \
	  'make test              Check repository guidance and key planning docs exist' \
	  'make shell             Open a lightweight managed Guix shell' \
	  'make kicad-shell       Open a managed KiCad shell' \
	  'make kicad-shell-local Open a managed KiCad shell with the local overlay manifest' \
	  'make kicad-version     Print the managed KiCad version' \
	  'make kicad-version-local Print the KiCad version from the local overlay manifest' \
	  'make kicad-edits       Open PROJECT in KiCad using the configured library path' \
	  'make clearance-check   Re-enable clearance DRC on a copy and diff against the baseline' \
	  'make clearance-baseline Record the current clearance state as the baseline' \
	  'make kicad-edits-local Open PROJECT in KiCad with the local KiCad overlay' \
	  'make fab               Generate Gerber/drill fabrication files for PROJECT' \
	  'make fab-local         Generate fabrication files with the local KiCad overlay' \
	  'make agent-reflection  Print Codex and Claude dry-run Reflection records' \
	  'make codex             Start Codex with this board, libraries, interfaces, context, and memory' \
	  'make claude            Start Claude with this board, libraries, interfaces, context, and memory' \
	  'make freecad-edits     Launch FreeCAD for 3D model work' \
	  'make agent-project     Start Codex centered on this project repo only' \
	  'make agent-libs        Start Codex centered on the sibling kicad-libs checkout' \
	  'make agent-both        Start Codex in this repo with the library repo added as workspace' \
	  'make agent-edits       Alias for make agent-both' \
	  'make validate-db       Validate the Orb Weaver KiCad database library wiring' \
	  'make check-kicad-libs  Check ORB_WEAVER_KICAD_LIBS points at usable libraries' \
	  '' \
	  'Variables:' \
	  '  PROJECT=/abs/path/to/project.kicad_pro' \
	  '  FAB_TOOL=orb-weaver-kicad-fab                              # fabrication helper command' \
	  '  FAB_OUTPUT_DIR=fab/project-name                                # fabrication output directory' \
	  '  FAB_OPTIONS="--skip-erc --skip-drc"                            # extra orb-weaver-kicad-fab options' \
	  '  ORB_WEAVER_KICAD_LIBS=/path/to/orb-weaver-kicad-libs-root     # explicit override' \
	  '  ORB_WEAVER_KICAD_LIBS_CHECKOUT=/path/to/kicad-libs             # editable checkout, preferred when present' \
	  '  ORB_WEAVER_KICAD_LIBS_AUTO_BUILD=1                            # resolve packaged libraries during prepare-kicad-config' \
	  '  GUIX_AGENT_TOOLS_CHECKOUT=/path/to/guix-agent-tools           # optional local checkout'

test:
	test -f .agents/AGENTS.md
	test -f .agents/PLANS.md
	test -f kicad/mouse-joystick-pcb.kicad_pro
	test -f kicad/mouse-joystick-pcb.kicad_sch
	test -f kicad/mouse-joystick-pcb.kicad_pcb
	test -f kicad/mouse-joystick-pcb.kicad_dru
	test -f kicad/sym-lib-table
	test -f kicad/fp-lib-table
	test -f kicad/design-block-lib-table
	test -f docs/rev0-plan.md
	test -f docs/interface-map.md
	test -f docs/power.md
	test -f docs/pycontrol-port-pinout.md
	test -f docs/pycontrol-interface.md
	test -f docs/uart-protocol.md
	test -f docs/instrument-strategy.md
	test -f docs/design-block-map.md
	test -f docs/encoder-analog-output.md
	test -f docs/relationship-to-twin-axis-board.md
	test -f docs/validation-plan.md

# This project sets rule_severities.clearance = ignore so that ~500 advisories
# inherited from the design blocks do not bury every other DRC finding. These
# targets restore the check on a throwaway copy -- the real .kicad_pro is never
# touched -- and diff it against a recorded baseline. Run clearance-baseline
# before routing, clearance-check after.
clearance-baseline:
	$(KICAD_MANAGED_SHELL) python3 scripts/clearance_check.py --save-baseline

clearance-check:
	$(KICAD_MANAGED_SHELL) python3 scripts/clearance_check.py

check-kicad-libs:
	@orb_libs="$(ORB_WEAVER_KICAD_LIBS)"; \
	if [ -z "$$orb_libs" ]; then \
	  echo "No editable Orb Weaver KiCad library checkout found; resolving packaged orb-weaver-kicad-libs..."; \
	  package_root="$$($(GUIX_TIME_MACHINE) -- build orb-weaver-kicad-libs)" || exit $$?; \
	  orb_libs="$$package_root/share/orb-weaver-kicad-libs"; \
	fi; \
	if [ ! -f "$$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl" ]; then \
	  echo "Missing KiCad DB library: $$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl"; \
	  exit 1; \
	fi; \
	if [ ! -f "$$orb_libs/db/build/orb_weaver_parts.sqlite" ]; then \
	  echo "Missing generated SQLite catalog: $$orb_libs/db/build/orb_weaver_parts.sqlite"; \
	  exit 1; \
	fi

prepare-kicad-config:
	mkdir -p $(KICAD_CONFIG_DIR) $(XDG_CACHE_HOME)
	printf '%s\n' '(sym_lib_table' '  (version 7)' ')' > "$(KICAD_CONFIG_DIR)/sym-lib-table"
	printf '%s\n' '(fp_lib_table' '  (version 7)' ')' > "$(KICAD_CONFIG_DIR)/fp-lib-table"
	@orb_libs="$(ORB_WEAVER_KICAD_LIBS)"; \
	if [ -z "$$orb_libs" ] && [ "$(ORB_WEAVER_KICAD_LIBS_AUTO_BUILD)" = "1" ]; then \
	  echo "Resolving packaged orb-weaver-kicad-libs..."; \
	  package_root="$$($(GUIX_TIME_MACHINE) -- build orb-weaver-kicad-libs)" || exit $$?; \
	  orb_libs="$$package_root/share/orb-weaver-kicad-libs"; \
	fi; \
	KICAD_COMMON_JSON="$(KICAD_COMMON_JSON)" ORB_WEAVER_KICAD_LIBS="$$orb_libs" python3 -c 'import json, os, pathlib; path = pathlib.Path(os.environ["KICAD_COMMON_JSON"]); data = json.loads(path.read_text()) if path.exists() else {}; env = data.setdefault("environment", {}); vars_map = env.get("vars"); vars_map = vars_map if isinstance(vars_map, dict) else {}; orb_libs = os.environ.get("ORB_WEAVER_KICAD_LIBS", ""); vars_map.pop("ORB_WEAVER_KICAD_LIBS", None) if not orb_libs else vars_map.__setitem__("ORB_WEAVER_KICAD_LIBS", orb_libs); env["vars"] = vars_map; data.setdefault("meta", {}).setdefault("version", 5); path.write_text(json.dumps(data, indent=2) + "\n")'

shell:
	$(MAKE) prepare-kicad-config
	$(AGENT_MANAGED_SHELL) bash

kicad-shell:
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) bash

kicad-shell-local:
	$(MAKE) kicad-shell GUIX_MANIFEST_KICAD=$(GUIX_MANIFEST_KICAD_LOCAL) GUIX_SHELL_EXTRA_OPTIONS="-L .guix/local-modules"

kicad-version:
	mkdir -p $(KICAD_CONFIG_HOME) $(XDG_CACHE_HOME)
	$(KICAD_MANAGED_SHELL) kicad-cli version

kicad-version-local:
	$(MAKE) kicad-version GUIX_MANIFEST_KICAD=$(GUIX_MANIFEST_KICAD_LOCAL) GUIX_SHELL_EXTRA_OPTIONS="-L .guix/local-modules"

agent-reflection:
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent --print-reflection "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)
	$(AGENT_MEMORY_ENV) $(CLAUDE_GUIX_SHELL) --session-role agent --print-reflection "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)

codex: agent-both

claude:
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CLAUDE_GUIX_SHELL) --session-role agent "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)

agent-project:
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent "$(CURDIR)" "$(GUIX_AGENT_TOOLS_CHECKOUT)" $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT)) $(AGENT_EXTRA_DIRS)

agent-libs:
	@if [ ! -d "$(LIBS_WORKSPACE)" ]; then echo "ORB_WEAVER_KICAD_LIBS_CHECKOUT=/path/to/kicad-libs is required for agent-libs"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent "$(LIBS_WORKSPACE)" "$(CURDIR)" "$(BOARD_INTERFACES_CHECKOUT)" "$(ORB_WEAVER_CONTEXT_CHECKOUT)" "$(GUIX_AGENT_TOOLS_CHECKOUT)" $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT)) $(AGENT_EXTRA_DIRS)

agent-both:
	$(MAKE) prepare-kicad-config
	$(AGENT_MEMORY_ENV) $(CODEX_GUIX_SHELL) --session-role agent "$(CURDIR)" $(PCB_AGENT_EXTRA_DIRS) $(AGENT_EXTRA_DIRS)

agent-edits: agent-both

kicad-edits:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) kicad "$(PROJECT)"

kicad-edits-local:
	$(MAKE) kicad-edits GUIX_MANIFEST_KICAD=$(GUIX_MANIFEST_KICAD_LOCAL) GUIX_SHELL_EXTRA_OPTIONS="-L .guix/local-modules" PROJECT="$(PROJECT)"

fab:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(FAB_TOOL)" --project "$(PROJECT)" --output-dir "$(FAB_OUTPUT_DIR)" $(FAB_OPTIONS)

fab-local:
	$(MAKE) fab GUIX_MANIFEST_KICAD=$(GUIX_MANIFEST_KICAD_LOCAL) GUIX_SHELL_EXTRA_OPTIONS="-L .guix/local-modules" PROJECT="$(PROJECT)" FAB_OUTPUT_DIR="$(FAB_OUTPUT_DIR)" FAB_OPTIONS="$(FAB_OPTIONS)"

freecad-edits:
	$(MAKE) prepare-kicad-config
	$(FREECAD_MANAGED_SHELL) freecad

validate-db:
	mkdir -p $(KICAD_CONFIG_HOME) $(XDG_CACHE_HOME)
	@orb_libs="$(ORB_WEAVER_KICAD_LIBS)"; \
	if [ -z "$$orb_libs" ]; then \
	  echo "No editable Orb Weaver KiCad library checkout found; resolving packaged orb-weaver-kicad-libs..."; \
	  package_root="$$($(GUIX_TIME_MACHINE) -- build orb-weaver-kicad-libs)" || exit $$?; \
	  orb_libs="$$package_root/share/orb-weaver-kicad-libs"; \
	fi; \
	if [ ! -f "$$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl" ]; then \
	  echo "Missing KiCad DB library: $$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl"; \
	  exit 1; \
	fi; \
	KICAD_CONFIG_HOME="$(KICAD_CONFIG_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" ORB_WEAVER_KICAD_LIBS="$$orb_libs" $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- kicad-agent inspect-db-library "$$orb_libs/kicad/db-libraries/orb_weaver_internal.kicad_dbl"; \
	KICAD_CONFIG_HOME="$(KICAD_CONFIG_HOME)" XDG_CACHE_HOME="$(XDG_CACHE_HOME)" ORB_WEAVER_KICAD_LIBS="$$orb_libs" $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- kicad-agent inspect-db-library "$$orb_libs/kicad/db-libraries/orb_weaver_catalog.kicad_dbl"
