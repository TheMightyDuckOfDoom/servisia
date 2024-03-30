# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

liberty74_path = $(shell bender path liberty74)

all: prepare_synth

# Initialize submodules
init:
	git submodule update --init

# Update submodules
update:
	git submodule update

# Simulate RTL
sim: programs/hello.binary out
	bender script verilator -t SIM > out/sim_script.list
	verilator --trace -j -F out/sim_script.list --binary --top-module servisia_tb --Wno-UNOPTFLAT -o servisia_tb
	./obj_dir/servisia_tb

# Simulate Synthesis
sim_synth: programs/hello.binary out
	bender script verilator -t SIM_SYNTH > out/sim_synth_script.list
	verilator --trace -j -F out/sim_synth_script.list --binary --top-module servisia_tb --Wno-UNOPTFLAT --Wno-PINMISSING -o servisia_tb
	./obj_dir/servisia_tb

# Simulate Layout
sim_layout: programs/hello.binary out
	bender script verilator -t SIM_LAYOUT > out/sim_script.list
	verilator --trace -j -F out/sim_script.list --binary --top-module servisia_tb --Wno-UNOPTFLAT --Wno-IMPLICIT -o servisia_tb
	./obj_dir/servisia_tb

# Compile Programs
programs/%.binary: programs/%.bin
	hexdump -v -e '1/1 "%02X" "\n"' $< > $@

programs/%.bin: programs/%.elf
	/opt/rv32i/bin/riscv32-unknown-elf-objcopy -O binary $< $@

programs/hello.elf: programs/hello.o programs/sections.lds
	/opt/rv32i/bin/riscv32-unknown-elf-gcc -Os -mabi=ilp32 -march=rv32i -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,programs/sections.lds,--strip-debug \
		programs/hello.o -lgcc

programs/hello.o: programs/hello.S
	/opt/rv32i/bin/riscv32-unknown-elf-gcc -c -mabi=ilp32 -march=rv32i -o programs/hello.o programs/hello.S

# Synthesize
synth: prepare_synth
	cd ${liberty74_path} && make synth

# Layout
chip:
	cd ${liberty74_path} && make chip

# Prepare for Synthesis
prepare_synth: out
	bender sources -f -t SYNTH > out/synth_sources.json
	morty -f out/synth_sources.json --top servisia > out/servisia.v

# Create output directory
out:
	mkdir -p out

# Clean
clean:
	rm -rf out
	rm -rf obj_dir
	rm -f programs/*.o
	rm -f programs/*.elf
	rm -f programs/*.bin
	rm -f programs/*.binary
	rm -f *.vcd 
