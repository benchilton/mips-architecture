# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

TOPLEVEL_LANG ?= vhdl
SIM ?= modelsim

PWD=$(shell pwd)

# Matrix parameters
data_size ?= 32
pc_size   ?= 10

ifeq ($(TOPLEVEL_LANG),verilog)
    VERILOG_SOURCES = $(PWD)/../hdl/MIPs.sv

    # Set module parameters
    ifeq ($(SIM),icarus)
        COMPILE_ARGS += -PMIPs.data_size=$(data_size) -PMIPs.pc_size=$(pc_size)
    else ifneq ($(filter $(SIM),questa modelsim riviera activehdl),)
        SIM_ARGS += -gdata_size=$(data_size) -gpc_size=$(pc_size)
    else ifeq ($(SIM),vcs)
        COMPILE_ARGS += -pvalue+MIPs/data_size=$(data_size) -pvalue+MIPs/pc_size=$(pc_size)
    else ifeq ($(SIM),verilator)
        COMPILE_ARGS += -gdata_size=$(data_size) -Gpc_size=$(pc_size)
    else ifneq ($(filter $(SIM),ius xcelium),)
        EXTRA_ARGS += -defparam "MIPs.data_size=$(data_size)" -defparam "MIPs.pc_size=$(pc_size)"
    endif

    ifneq ($(filter $(SIM),riviera activehdl),)
        COMPILE_ARGS += -sv2k12
    endif

else ifeq ($(TOPLEVEL_LANG),vhdl)
    VHDL_SOURCES = $(PWD)/alu.vhdl $(PWD)/branch_controller.vhdl $(PWD)/data_memory.vhdl $(PWD)/decoder.vhdl
                $(PWD)/defines.vhdl $(PWD)/MIPs.vhdl $(PWD)/program_counter.vhdl $(PWD)/program_memory.vhdl
                $(PWD)/registers.vhdl $(PWD)/stage_decode.vhdl $(PWD)/stage_execute.vhdl $(PWD)/stage_fetch.vhdl
                $(PWD)/stage_memory.vhdl

    ifneq ($(filter $(SIM),ghdl questa modelsim riviera activehdl),)
        # ghdl, questa, and aldec all use SIM_ARGS with '-g' for setting generics
        SIM_ARGS += -gdata_size=$(data_size) -gpc_size=$(pc_size)
    else ifneq ($(filter $(SIM),ius xcelium),)
        SIM_ARGS += -generic "MIPs:data_size=>$(data_size)" -generic "MIPs:pc_size=>$(pc_size)"
    endif

    ifeq ($(SIM),ghdl)
        EXTRA_ARGS += --std=08
        SIM_ARGS += --wave=wave.ghw
    else ifneq ($(filter $(SIM),questa modelsim riviera activehdl),)
        COMPILE_ARGS += -2008
    endif
else
    $(error A valid value (verilog or vhdl) was not provided for TOPLEVEL_LANG=$(TOPLEVEL_LANG))
endif

# Fix the seed to ensure deterministic tests
export RANDOM_SEED := 123456789

TOPLEVEL    := MIPs
MODULE      := test_MIPs

include $(shell cocotb-config --makefiles)/Makefile.sim


# Profiling

DOT_BINARY ?= dot

test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	$(shell cocotb-config --python-bin) -m gprof2dot -f pstats ./$< | $(DOT_BINARY) -Tsvg -o $@

.PHONY: profile
profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg
