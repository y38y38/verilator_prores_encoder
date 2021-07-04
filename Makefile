# Copyright 2018 Tomas Brabec
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SHELL=bash

vsrc = wrapper.sv
csrc = test_main.cpp test_utility.c
cflags = -lpthread
ldflags = -lpthread
objdir = obj
obj = $(csrc:%.cpp=%)
vflags = $(if $(cflags),-CFLAGS "$(cflags)" ) $(if $(ldflags),-LDFLAGS "$(ldflags)" ) --cc --exe --Mdir $(objdir) \
	 --top-module dut

vflags_extra = --trace
sflags =


.PHONY: help
help:
	@echo -e "Usage:\n\tmake [ooptions] [target] [<variable>=<value>]"
	@echo -e "\nTargets:"
	@echo -e "  help        prints this help message"
	@echo -e "  build       creates a testbench binary ($(objdir)/$(obj))"
	@echo -e "  clean       delete all outputs"
	@echo -e "\nVariables:"
	@echo -e "  cflags           extra C++ compiler flags"
	@echo -e ""

.PHONY: all build
all build: $(objdir)/$(obj)

.PHONY: verilate
verilate: $(objdir)/Vdut.mk

$(objdir)/Vdut.mk: $(vsrc) $(csrc)
	verilator $(vflags) $(vflags_extra) -o $(notdir $(obj)) $(csrc) $(vsrc)

$(objdir)/$(obj): $(objdir)/Vdut.mk
	make -C $(objdir) -f Vdut.mk

.PHONY: clean
clean:
	rm -rf $(objdir) dump.vcd