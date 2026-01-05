# Toplevel sources
TOP:=toplevel
SIM_MODULE:=toplevel_tb

# Enables or disables logging of simulation signals
WRITE_SIGNALS:=1

# Source files
SOURCES:=\
	src/context.vhd\
	src/toplevel.vhd\
	src/parallel_rgb.vhd

SIM_SOURCES:=\
	sim/common/context.vhd\
	sim/gatemate_primitives/cc_pll.vhd\
	sim/gatemate_primitives/cc_bufg.vhd\
	sim/gatemate_primitives/cc_usr_rstn.vhd\
	sim/gatemate_primitives/cc_lvds_obuf.vhd\
	sim/gatemate_primitives/cc_oddr.vhd\
	sim/testbenches/${SIM_MODULE}.vhd

SYNTHLIB_SOURCES:=\
	synth_lib/synth_lib.vhd

SIMLIB_SOURCES:=\
	sim_lib/sim_lib.vhd

CONSTRAINTS:=\
	constr/gatemate.ccf

GLOBAL_DEPS:=\
    ${SYNTHLIB_SOURCES}\
    ${SIMLIB_SOURCES}

# Installation directory for OSS CAD suite
OSS_CAD_DIR=/opt/oss-cad-suite/

# Other settings
VHDL_STD:=--std=08
WORK_SYNTH:=synth
WORK_SIM:=sim
CWD:=$(shell pwd)

# Color coding escape sequences
COL=\e[44m
ERR=\e[41m
CLR=\e[0m\e[49m

###################
# GHDL SIMULATION #
###################

# Simulation settings
MAX_TIME:=2000ms
ASSERT:=failure
GENERICS:=

# Select between GHW and VCD signal format
SIGNALS_FORMAT=GHW
SIGNALS_FILE:=$(CWD)/signals.ghw

#SIGNALS_FORMAT=VCD
#SIGNALS_FILE:=$(CWD)/signals.vcd

GHDL:=$(OSS_CAD_DIR)/bin/ghdl
GHDL_ELABORATION_FLAGS:=--syn-binding

OBJDIR:=build
SRC_OBJDIR:=$(OBJDIR)/src
SRC_OBJ:=$(addprefix $(SRC_OBJDIR)/, $(notdir $(patsubst %.vhd,%.o,$(SOURCES))))

SIM_OBJDIR:=$(OBJDIR)/sim
SIM_OBJ:=$(addprefix $(SIM_OBJDIR)/, $(notdir $(patsubst %.vhd,%.o,$(SIM_SOURCES))))

SIMLIB_OBJDIR:=$(OBJDIR)/sim_lib
SIMLIB_OBJ:=$(addprefix $(SIMLIB_OBJDIR)/, $(notdir $(patsubst %.vhd,%.o,$(SIMLIB_SOURCES))))

SYNTHLIB_OBJDIR:=$(OBJDIR)/synth_lib
SYNTHLIB_OBJ:=$(addprefix $(SYNTHLIB_OBJDIR)/, $(notdir $(patsubst %.vhd,%.o,$(SYNTHLIB_SOURCES))))

help:
	@echo "Availabel makefile rules:\n"
	@echo "sim:    Build and run simulation with GHDL"
	@echo "build:  Run synthesis, implementation and bitfile creation"
	@echo "fbuild: Fast build, like build but run implementation with relaxed timing settings
	@echo "synth:  Run synthesis only"
	@echo "impl:   Run implementation with strict timing settings and try different seeds if it fails"
	@echo "fimpl:  Run implementation with relaxed timing settings"
	@echo "bit:    Run bitfile creation only"
	@echo "run:    Loads the current bitfile to the FPGA through JTAG"
	@echo "flash:  Flashes the current bitfile to the FPGA through JTAG"
	@echo "gui:    Launches NEXTPNR GUI"
	@echo "clean:  Delete all build files (including simulation)"

# Create build directories
$(SRC_OBJDIR):
	mkdir -p $(SRC_OBJDIR)
$(SIM_OBJDIR):
	mkdir -p $(SIM_OBJDIR)
$(SIMLIB_OBJDIR):
	mkdir -p $(SIMLIB_OBJDIR)
$(SYNTHLIB_OBJDIR):
	mkdir -p $(SYNTHLIB_OBJDIR)

# Compile sim_lib
define simlib_rule
$(1): $$(filter %/$$(notdir $$(patsubst %.o, %.vhd, $(1))), $(SIMLIB_SOURCES)) $(GLOBAL_DEPS) | $(SIMLIB_OBJDIR)
	@echo "$(COL)Compiling $(CWD)/$$<$(CLR)" && \
	cd $(SIMLIB_OBJDIR) && $(GHDL) -a $(VHDL_STD) --work=sim_lib -v $(CWD)/$$<
endef
$(foreach v, $(SIMLIB_OBJ), $(eval $(call simlib_rule,$(v))))

# Compile synth_lib
define synthlib_rule
$(1): $$(filter %/$$(notdir $$(patsubst %.o, %.vhd, $(1))), $(SYNTHLIB_SOURCES)) $(GLOBAL_DEPS) | $(SYNTHLIB_OBJDIR)
	@echo "$(COL)Compiling $(CWD)/$$<$(CLR)" && \
	cd $(SYNTHLIB_OBJDIR) && $(GHDL) -a $(VHDL_STD) --work=synth_lib -v $(CWD)/$$<
endef
$(foreach v, $(SYNTHLIB_OBJ), $(eval $(call synthlib_rule,$(v))))

# Compile synthesis sources
define compile_src
$(1): $$(filter %/$$(notdir $$(patsubst %.o, %.vhd, $(1))), $(SOURCES)) $(GLOBAL_DEPS) | $(SRC_OBJDIR)
	@echo "$(COL)Compiling $(CWD)/$$<$(CLR)" && \
	cd $(SRC_OBJDIR) && $(GHDL) -a $(VHDL_STD) --work=$(WORK_SYNTH) -P../sim_lib -P../synth_lib -v $(CWD)/$$<
endef
$(foreach v, $(SRC_OBJ), $(eval $(call compile_src,$(v))))

# Compile simulation sources
define compile_sim
$(1): $$(filter %/$$(notdir $$(patsubst %.o, %.vhd, $(1))), $(SIM_SOURCES)) $(GLOBAL_DEPS) | $(SIM_OBJDIR)
	@echo "$(COL)Compiling $(CWD)/$$<$(CLR)" && \
	cd $(SIM_OBJDIR) && $(GHDL) -a $(VHDL_STD) --work=$(WORK_SIM) -P../src -P../sim_lib -P../synth_lib -v $(CWD)/$$<
endef
$(foreach v, $(SIM_OBJ), $(eval $(call compile_sim,$(v))))

# Elaboration
$(SIM_OBJDIR)/$(SIM_MODULE): $(SIMLIB_OBJ) $(SYNTHLIB_OBJ) $(SRC_OBJ) $(SIM_OBJ)
	@echo "$(COL)Elaborating $(CWD)/$(SIM_MODULE)$(CLR)" && \
	cd $(SIM_OBJDIR) && $(GHDL) -e -v $(VHDL_STD) $(GHDL_ELABORATION_FLAGS) -P../src -P../sim -P../sim_lib -P../synth_lib --work=$(WORK_SIM) $(SIM_MODULE)

# Running simulation
SIGNALS_ARG:=$(shell if [ $(WRITE_SIGNALS) -eq 1 -a "$(SIGNALS_FORMAT)" = "VCD" ]; then echo "--vcd=$(SIGNALS_FILE)"; fi) \
	$(shell if [ $(WRITE_SIGNALS) -eq 1 -a "$(SIGNALS_FORMAT)" = "GHW" ]; then echo "--wave=$(SIGNALS_FILE)"; fi)

sim: $(SIM_OBJDIR)/$(SIM_MODULE)
	@echo "$(COL)Running $(CWD)/$(SIM_MODULE)$(CLR)" && \
	cd $(SIM_OBJDIR) && $(GHDL) -r -v -P../src -P../sim -P../sim_lib --work=$(WORK_SIM) $(SIM_MODULE) \
		--stop-time=$(MAX_TIME) --assert-level=$(ASSERT) --ieee-asserts=disable $(SIGNALS_ARG) $(GENERICS)

###################
# YOSYS SYNTHESIS #
###################

YOSYS:=$(OSS_CAD_DIR)/bin/yosys
SYNTHFLAGS:=-luttree -nomx8 -retime

NEXTPNR:=$(OSS_CAD_DIR)/bin/nextpnr-himbaechel
NEXTPNR_FLAGS:=--device CCGM1A1 --vopt fpga_mode=economy
STRICT_TIMING_SETTINGS:=--vopt time_mode=worst
RELAXED_TIMING_SETTINGS:=--router router2 --vopt time_mode=typical
PLACING_MAX_RETRIES=10
SEED:=0 # Overwritten for non-fast builds

LOADER:=$(OSS_CAD_DIR)/bin/openFPGALoader
GMPACK:=$(OSS_CAD_DIR)/bin/gmpack

SOURCES_ABS=$(addprefix $(CWD)/,$(SOURCES))
SYNTHLIB_SOURCES_ABS=$(addprefix $(CWD)/,$(SYNTHLIB_SOURCES))

build/log:
	mkdir -p build/log
build/synth:
	mkdir -p build/synth
build/impl:
	mkdir -p build/impl

synth: build/log build/synth
	@echo "$(COL)Synthesizing VHDL to Verilog$(CLR)"
	$(GHDL) synth --warn-no-binding --no-formal -fexplicit --out=verilog $(VHDL_STD) --work=synth_lib $(SYNTHLIB_SOURCES_ABS)\
		--work=$(WORK_SYNTH) $(SOURCES_ABS) -e $(TOP) > build/synth/$(TOP).v
	@echo "$(COL)Synthesizing Verilog$(CLR)"
	$(YOSYS) -l $(CWD)/build/log/synth.log -p "\
		read_verilog build/synth/$(TOP).v; \
		synth_gatemate -top $(TOP) -vlog $(CWD)/build/synth/$(TOP)_synth.v -json $(CWD)/build/synth/$(TOP)_synth.json $(SYNTHFLAGS)"

pnr: build/impl
	$(NEXTPNR) $(NEXTPNR_FLAGS) --json build/synth/$(TOP)_synth.json --vopt ccf=constr/gatemate.ccf --sdc=constr/timing.sdc\
		--write build/impl/$(TOP).json --report build/impl/timing.json --detailed-timing-report \
		--vopt out=build/impl/bitstream.txt --seed=$(SEED) --log build/log/impl.log;\
	failed=`grep ERROR build/log/impl.log | wc -l`;\
	if test $$failed -ne 0; then \
		echo "$(ERR)FAILED!$(CLR)"; \
		exit 1; \
	else \
		echo "$(COL)SUCCESS!$(CLR)"; \
		break; \
	fi \

fimpl:
	@echo "$(COL)Fast Implementation$(CLR)"
	$(MAKE) NEXTPNR_FLAGS="$(NEXTPNR_FLAGS) $(RELAXED_TIMING_SETTINGS)" pnr
	@echo "$(COL)Generating Bitfile$(CLR)"
	$(GMPACK) build/impl/bitstream.txt build/bitfile.bit

impl:
	# Repeat implementation with different seeds until success
	@for i in $$(seq 1 1 $(PLACING_MAX_RETRIES)); do \
		echo "$(COL)Implementation with seed=$$i$(CLR)";\
		$(MAKE) SEED=$$i NEXTPNR_FLAGS="$(NEXTPNR_FLAGS) $(STRICT_TIMING_SETTINGS)" pnr  && break; \
		test $$i -ne $(PLACING_MAX_RETRIES) || exit 1; \
	done
	@echo "$(COL)Generating Bitfile$(CLR)"
	$(GMPACK) build/impl/bitstream.txt build/bitfile.bit

run: build/bitfile.bit
	$(LOADER) -r build/bitfile.bit

flash: build/bitfile.bit
	$(LOADER) -f -r build/bitfile.bit

gui:
	$(NEXTPNR) $(NEXTPNR_FLAGS) --gui --json build/impl/$(TOP).json

build: synth impl

fbuild: synth fimpl

########
# MISC #
########

clean:
	rm -Rf $(OBJDIR)/*
