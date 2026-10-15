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
GUIX_MANIFEST_SITE ?= .guix/manifest-site.scm
GUIX_SHELL_SITE = $(GUIX_TIME_MACHINE) -- shell $(GUIX_SHELL_EXTRA_OPTIONS) --pure -m $(GUIX_MANIFEST_SITE)
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
# Prefer an editable kicad-libs checkout, the way the library path already does.
# The packaged command only appears once .guix/channels.scm is bumped to a
# kicad-libs commit that carries it.
DOCS_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-docs),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-docs,orb-weaver-kicad-docs)
DOCS_OUTPUT_DIR ?= docs/generated
DOCS_OPTIONS ?=
GLB_OUTPUT_DIR ?= tmp/glb
# Routing helpers from kicad-libs (bin/orb-weaver-kicad-*). Like DOCS_TOOL they
# prefer the sibling checkout; the packaged commands appear once the channel pin
# carries a kicad-libs commit that ships them. See kicad-libs
# docs/freerouting-autorouting.md for the routing workflow.
EXPORT_DSN_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-export-dsn),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-export-dsn,orb-weaver-kicad-export-dsn)
IMPORT_SES_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-import-ses),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-import-ses,orb-weaver-kicad-import-ses)
CLEARANCE_CHECK_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-clearance-check),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-clearance-check,orb-weaver-kicad-clearance-check)
SES ?= fab/autoroute/$(basename $(notdir $(PROJECT))).ses
EXPORT_DSN_OPTIONS ?=
IMPORT_SES_OPTIONS ?=
CLEARANCE_CHECK_OPTIONS ?=
MECHANICAL_DATUMS_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-mechanical-datums),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-mechanical-datums,orb-weaver-kicad-mechanical-datums)
MECHANICAL_DATUMS ?= docs/generated/mechanical-datums.json
MECHANICAL_DATUMS_OPTIONS ?=
BOARD_MANIFEST_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-manifest),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-manifest,orb-weaver-kicad-board-manifest)
BOARD_MANIFEST ?= kicad/board-manifest.yaml
BOARD_MANIFEST_MAP ?= docs/interface-map.md
BOARD_MANIFEST_OPTIONS ?=
COMPOSE_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-compose),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-compose,orb-weaver-kicad-compose)
COMPOSE_OPTIONS ?=
BOARD_SOURCE_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-source),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-board-source,orb-weaver-kicad-board-source)
BOARD_SOURCE ?= kicad/board.yaml
BOARD_SOURCE_OPTIONS ?=
REFRESH_BLOCK_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-refresh-block),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-refresh-block,orb-weaver-kicad-refresh-block)
REFRESH_BLOCK_OPTIONS ?=
GENERATE_GLUE_TOOL ?= $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-generate-glue),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT)/bin/orb-weaver-kicad-generate-glue,orb-weaver-kicad-generate-glue)
GENERATE_GLUE_OPTIONS ?=

MANAGED_ENV = KICAD_CONFIG_HOME=$(KICAD_CONFIG_HOME) XDG_CACHE_HOME=$(XDG_CACHE_HOME) $(if $(ORB_WEAVER_KICAD_LIBS),ORB_WEAVER_KICAD_LIBS=$(ORB_WEAVER_KICAD_LIBS))
TLS_ENV = export SSL_CERT_FILE="$${GUIX_ENVIRONMENT}/etc/ssl/certs/ca-certificates.crt"; export GIT_SSL_CAINFO="$$SSL_CERT_FILE"; export CURL_CA_BUNDLE="$$SSL_CERT_FILE"; export SSL_CERT_DIR="$${GUIX_ENVIRONMENT}/etc/ssl/certs"; exec "$$@"
AGENT_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_AGENT) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
KICAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_KICAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
FREECAD_MANAGED_SHELL = $(MANAGED_ENV) $(GUIX_SHELL_FREECAD) -E "^KICAD_CONFIG_HOME$$" -E "^XDG_CACHE_HOME$$" -E "^ORB_WEAVER_KICAD_LIBS$$" -- sh -c '$(TLS_ENV)' sh
MANAGED_SHELL = $(AGENT_MANAGED_SHELL)

LIBS_WORKSPACE := $(if $(wildcard $(ORB_WEAVER_KICAD_LIBS_CHECKOUT)),$(ORB_WEAVER_KICAD_LIBS_CHECKOUT),$(ORB_WEAVER_KICAD_LIBS))
PCB_AGENT_EXTRA_DIRS ?= $(BOARD_INTERFACES_CHECKOUT) $(ORB_WEAVER_CONTEXT_CHECKOUT) $(GUIX_AGENT_TOOLS_CHECKOUT) $(MOUSE_JOYSTICKS_MECH_CHECKOUT) $(MOUSE_JOYSTICKS_PCB_CHECKOUT) $(TMC51X0_DEV_PCB_CHECKOUT) $(SYRINGE_PUMP_CHECKOUT) $(M2K_ADAPTER_CHECKOUT) $(LA5032_ADAPTER_CHECKOUT) $(if $(LIBS_WORKSPACE),$(LIBS_WORKSPACE)) $(if $(wildcard $(AGENT_MEMORY_REPO_CHECKOUT)/AGENTS.md),$(AGENT_MEMORY_REPO_CHECKOUT))

.PHONY: mechanical-datums board-manifest-derive board-manifest-check board-manifest-render compose compose-check expand expand-check refresh-block generate-glue docs docs-check site site-serve glb export-dsn export-dsn-local freeroute freeroute-local import-ses clearance-check clearance-baseline help test prepare-kicad-config check-kicad-libs shell kicad-shell kicad-shell-local kicad-version kicad-version-local agent-reflection codex claude agent-project agent-libs agent-both agent-edits kicad-edits kicad-edits-local freecad-edits validate-db fab fab-local

help:
	@printf '%s\n' \
	  'make test              Check repository guidance and key planning docs exist' \
	  'make shell             Open a lightweight managed Guix shell' \
	  'make kicad-shell       Open a managed KiCad shell' \
	  'make kicad-shell-local Open a managed KiCad shell with the local overlay manifest' \
	  'make kicad-version     Print the managed KiCad version' \
	  'make kicad-version-local Print the KiCad version from the local overlay manifest' \
	  'make kicad-edits       Open PROJECT in KiCad using the configured library path' \
	  'make export-dsn        Export the PCB to Specctra DSN for Freerouting' \
	  'make freeroute         Export the DSN and open it in the Freerouting GUI' \
	  'make freeroute-local   Same, but take Guix packages from the local kicad-libs checkout' \
	  'make import-ses        Apply the Freerouting .ses to the PCB headlessly, with a backup' \
	  'make clearance-check   Re-enable clearance DRC on a copy and diff against the baseline' \
	  'make clearance-baseline Record the current clearance state as the baseline' \
	  'make mechanical-datums Export connector mating datums and the block placement record' \
	  'make board-manifest-check   Check kicad/board-manifest.yaml against the board, the library and the netclass patterns' \
	  'make board-manifest-derive  Write the manifest from the schematic hierarchy and the placement record (keeps meanings and reasons)' \
	  'make board-manifest-render  Render the interface map block from the manifest into docs/interface-map.md' \
	  'make compose           Make the project agree with kicad/board-manifest.yaml: create the sheet instances, pin connections and PCB groups it lacks (KiCad shell)' \
	  'make compose-check     Report what compose would create and what differs; exit 1 when there is anything' \
	  'make expand            Write kicad/board-manifest.yaml from kicad/board.yaml and its subsystem recipes' \
	  'make expand-check      Compare the expansion of kicad/board.yaml with kicad/board-manifest.yaml; exit 1 on a difference' \
	  'make refresh-block     Bring one placed block up to its library block and report what changed (INSTANCE= [BLOCK=] [RENAME=OLD=NEW]; KiCad shell)' \
	  'make generate-glue     Draw the board'"'"'s own parts from its subsystem recipes, a stub and a label per pin, into the composed sheets (KiCad shell)' \
	  'make kicad-edits-local Open PROJECT in KiCad with the local KiCad overlay' \
	  'make fab               Generate Gerber/drill fabrication files for PROJECT' \
	  'make docs             Generate published board documentation for PROJECT' \
	  'make docs-check       Report whether the generated documentation is stale' \
	  'make site             Build the documentation site from docs/ into site/ (mkdocs, strict)' \
	  'make site-serve       Serve the documentation site locally' \
	  'make glb               Export the assembled board as glTF for the rig atlas (tmp/glb/)' \
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
	  '  DOCS_OUTPUT_DIR=docs/generated                                 # board documentation output directory' \
	  '  DOCS_OPTIONS="--skip-renders"                                  # extra orb-weaver-kicad-docs options' \
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

# kicad-cli has no Specctra subcommand, so the DSN comes from KiCad's pcbnew
# Python bindings. DSN carries netclasses and existing wiring but not the
# .kicad_dru custom rules -- run `make clearance-check` after routing. The
# scripts moved to kicad-libs on 2026-09-25 (orb-weaver-kicad-export-dsn,
# -import-ses, -clearance-check); the *_TOOL variables above select them.
DSN ?= fab/autoroute/$(basename $(notdir $(PROJECT))).dsn

export-dsn:
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(EXPORT_DSN_TOOL)" --project "$(PROJECT)" --output "$(DSN)" $(EXPORT_DSN_OPTIONS)

import-ses:
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(IMPORT_SES_TOOL)" --project "$(PROJECT)" --ses "$(SES)" $(IMPORT_SES_OPTIONS)

# Opens the Freerouting GUI with the design already loaded. -di points the
# open/save dialogs at the same directory so the .ses lands beside the .dsn.
# Import the result back with Pcbnew: File > Import > Specctra Session.
freeroute: export-dsn
	$(KICAD_MANAGED_SHELL) freerouting -de "$(DSN)" -di "$(dir $(DSN))"

# The channel pin in .guix/channels.scm decides which Freerouting version the
# targets above get. These -local variants read (orb-weaver packages) straight
# from the sibling kicad-libs working tree instead, so a package bump is usable
# before it is pushed and the pin updated. Same idea as kicad-edits-local.
LIBS_GUIX_MODULES = $(if $(LIBS_WORKSPACE),$(LIBS_WORKSPACE)/.guix/modules,)

export-dsn-local:
	@if [ -z "$(LIBS_GUIX_MODULES)" ]; then echo "no kicad-libs checkout found; set ORB_WEAVER_KICAD_LIBS_CHECKOUT"; exit 1; fi
	$(MAKE) export-dsn GUIX_SHELL_EXTRA_OPTIONS="-L $(LIBS_GUIX_MODULES)"

freeroute-local:
	@if [ -z "$(LIBS_GUIX_MODULES)" ]; then echo "no kicad-libs checkout found; set ORB_WEAVER_KICAD_LIBS_CHECKOUT"; exit 1; fi
	$(MAKE) freeroute GUIX_SHELL_EXTRA_OPTIONS="-L $(LIBS_GUIX_MODULES)"

# This project sets rule_severities.clearance = ignore so that ~500 advisories
# inherited from the design blocks do not bury every other DRC finding. These
# targets restore the check on a throwaway copy -- the real .kicad_pro is never
# touched -- and diff it against a recorded baseline. Run clearance-baseline
# before routing, clearance-check after.
clearance-baseline:
	$(KICAD_MANAGED_SHELL) "$(CLEARANCE_CHECK_TOOL)" --project "$(PROJECT)" --save-baseline $(CLEARANCE_CHECK_OPTIONS)

clearance-check:
	$(KICAD_MANAGED_SHELL) "$(CLEARANCE_CHECK_TOOL)" --project "$(PROJECT)" $(CLEARANCE_CHECK_OPTIONS)

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

# Connector mating centres and directions and the placed-block record, in board
# coordinates relative to the board datum (aux axis origin when set), for the
# enclosure and the documentation; also the placement record the board
# manifest reads. Writes JSON and CSV beside each other (KiCad shell).
mechanical-datums:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	mkdir -p "$(dir $(MECHANICAL_DATUMS))"
	$(KICAD_MANAGED_SHELL) "$(MECHANICAL_DATUMS_TOOL)" --project "$(PROJECT)" --output "$(MECHANICAL_DATUMS)" --csv "$(MECHANICAL_DATUMS:.json=.csv)" $(MECHANICAL_DATUMS_OPTIONS)

# The board manifest (kicad-libs PLANS 2026-09-30 D20): kicad/board-manifest.yaml
# names every placed block with its anchor, rotation and side, maps each port
# to the label it meets in its parent sheet (or `open` with a reason), lists
# the board-authored wrapper sheets and the netclass profiles, and gives every
# net its class. `board-manifest-derive` writes it from the schematic and the
# mechanical-datums record (run `make mechanical-datums` first; an existing
# manifest keeps its meanings, reasons and notes); `board-manifest-check`
# compares it with the board, the library and the project's netclass patterns,
# and fails on a port neither mapped nor open; `board-manifest-render` writes
# the generated block of docs/interface-map.md. Pure Python, lightweight shell.
board-manifest-derive:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(AGENT_MANAGED_SHELL) "$(BOARD_MANIFEST_TOOL)" derive --project "$(PROJECT)" --output "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(BOARD_MANIFEST_OPTIONS)

board-manifest-check:
	$(AGENT_MANAGED_SHELL) "$(BOARD_MANIFEST_TOOL)" check "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(BOARD_MANIFEST_OPTIONS)

board-manifest-render:
	$(AGENT_MANAGED_SHELL) "$(BOARD_MANIFEST_TOOL)" render "$(BOARD_MANIFEST)" --output "$(BOARD_MANIFEST_MAP)" $(BOARD_MANIFEST_OPTIONS)

# The composer (kicad-libs PLANS 2026-09-30 step 4, D28): `make compose` makes
# the project agree with kicad/board-manifest.yaml, creating the child sheet,
# sheet symbol, stubs, labels, no-connects and PCB group of a placement the
# board lacks, a subsystem sheet's file, or a bare pin's stub; it never moves,
# renames or deletes. Then `make mechanical-datums` (the record keys groups by
# sheet UUID) and `make board-manifest-check`. `make compose-check` is the dry
# run. Proven 2026-10-02 on a scratch copy of this board (kicad-libs PLANS 4b).
compose:
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(COMPOSE_TOOL)" compose "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(COMPOSE_OPTIONS)

compose-check:
	$(AGENT_MANAGED_SHELL) "$(COMPOSE_TOOL)" check "$(BOARD_MANIFEST)" $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(COMPOSE_OPTIONS)

# The board source (kicad-libs PLANS 2026-09-30 step 4d, D27): kicad/board.yaml
# names the motor_encoder_switch recipe from kicad-libs by reference (pinned by
# hash) and the three board-local recipes in kicad/subsystems/, places the
# blocks per role and writes only the renames and opens; kicad/sheet-pins.yaml
# holds this board's own sheet-pin arrangements. `make expand` writes the
# record from it, `make expand-check` compares (exit 1 on a difference); the
# record stays the checked file.
expand:
	$(AGENT_MANAGED_SHELL) "$(BOARD_SOURCE_TOOL)" expand "$(BOARD_SOURCE)" --write --output "$(BOARD_MANIFEST)" $(BOARD_SOURCE_OPTIONS)

expand-check:
	$(AGENT_MANAGED_SHELL) "$(BOARD_SOURCE_TOOL)" expand "$(BOARD_SOURCE)" --check --output "$(BOARD_MANIFEST)" $(BOARD_SOURCE_OPTIONS)

# The refresh (kicad-libs PLANS 2026-09-30 step 5, D22): one placed block
# brought up to its library block, the board's own copper and wires left
# alone, the changes printed. Proven on a scratch copy of this board
# 2026-10-02 (the 5 V regulator to tpsm365r6_fixed_5v, the digital-50 DUT
# boundary's copper). Then edit kicad/board.yaml, `make expand`, `make
# compose`, `make mechanical-datums`, `make board-manifest-check`.
refresh-block:
	@if [ -z "$(INSTANCE)" ]; then echo "INSTANCE=<placed block name> is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(REFRESH_BLOCK_TOOL)" "$(BOARD_MANIFEST)" --instance "$(INSTANCE)" $(if $(BLOCK),--block "$(BLOCK)") $(if $(RENAME),--rename "$(RENAME)") $(if $(wildcard $(MECHANICAL_DATUMS)),--datums "$(MECHANICAL_DATUMS)") $(REFRESH_BLOCK_OPTIONS)

# The glue generator (kicad-libs PLANS 2026-09-30 step 8b, D28): `make
# generate-glue` draws the board's own parts from its subsystem recipes and
# kicad/board.yaml's glue (a symbol with a stub and a label per pin, two-pin
# parts in a column, no-connect flags where the recipe says) into the sheets
# `make compose` created; it creates and never moves, so a reference already
# placed is skipped. Then `make board-manifest-check` and, for a new board,
# the netlist is the record's.
generate-glue:
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(GENERATE_GLUE_TOOL)" "$(BOARD_SOURCE)" $(GENERATE_GLUE_OPTIONS)


fab:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(FAB_TOOL)" --project "$(PROJECT)" --output-dir "$(FAB_OUTPUT_DIR)" $(FAB_OPTIONS)

# The block and subsystem pages (kicad-libs PLANS 2026-10-12 steps 2 and 5): with
# the board manifest the documentation gains docs/generated/blocks/<instance>.md
# per placed block, and with the board source the subsystem pages and the GPIO
# allocation, from the library's briefs and the recipes. Both are passed when
# the files exist; --review-schematic adds the per-block review booklet.
DOCS_BLOCK_OPTIONS = $(if $(wildcard $(BOARD_MANIFEST)),--manifest "$(BOARD_MANIFEST)" --brief-check) $(if $(wildcard $(BOARD_SOURCE)),--board-source "$(BOARD_SOURCE)")
# With a site (mkdocs.yml), the documentation also writes docs/index.md, the
# front page with the turning board (kicad-libs PLANS 2026-10-14, the board site).
DOCS_SITE_OPTIONS = $(if $(wildcard mkdocs.yml),--site-index docs/index.md)

docs:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	$(KICAD_MANAGED_SHELL) "$(DOCS_TOOL)" --project "$(PROJECT)" --output-dir "$(DOCS_OUTPUT_DIR)" $(DOCS_BLOCK_OPTIONS) $(DOCS_SITE_OPTIONS) --review-schematic $(DOCS_OPTIONS)

docs-check:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(KICAD_MANAGED_SHELL) "$(DOCS_TOOL)" --project "$(PROJECT)" --output-dir "$(DOCS_OUTPUT_DIR)" $(DOCS_BLOCK_OPTIONS) $(DOCS_SITE_OPTIONS) --review-schematic --check

# The documentation site (kicad-libs PLANS 2026-10-14, the board site; docs/board-documentation.md
# "The Site"): mkdocs-material from Guix builds docs/ into site/ (ignored), strictly, as the
# Pages workflow does from the committed pages; `make site-serve` serves it at localhost:8000.
SITE_DIR ?= site
SITE_OPTIONS ?=

site:
	$(GUIX_SHELL_SITE) -- mkdocs build --strict --site-dir "$(SITE_DIR)" $(SITE_OPTIONS)

site-serve:
	$(GUIX_SHELL_SITE) -- mkdocs serve $(SITE_OPTIONS)

# The assembled board as binary glTF, with components, silkscreen and soldermask,
# for the rig atlas in mouse-joysticks-mech (atlas/boards/). Written under tmp/,
# which is ignored; copy it there and update its PROVENANCE.md.
glb:
	@if [ -z "$(PROJECT)" ]; then echo "PROJECT=/path/to/project.kicad_pro is required"; exit 1; fi
	$(MAKE) prepare-kicad-config
	mkdir -p "$(GLB_OUTPUT_DIR)"
	$(KICAD_MANAGED_SHELL) kicad-cli pcb export glb --subst-models --include-silkscreen --include-soldermask --force --output "$(GLB_OUTPUT_DIR)/$(basename $(notdir $(PROJECT))).glb" "$(PROJECT:.kicad_pro=.kicad_pcb)"

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
