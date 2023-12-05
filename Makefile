# Copyright 2023 Tobias Senti
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

all: prepare_synth

init:
	git submodule update --init

update:
	git submodule update

sim: programs/hello.binary sim_exe
	./obj_dir/servisia_tb

sim_post: programs/hello.binary sim_post_exe
	./obj_dir/servisia_tb

sim_post_exe: ../liberty74/out/servisia.v rtl/servisia_tb.sv
	verilator --trace -DPOST_SYNTHESIS -j ../liberty74/out/servisia.v ../liberty74/pdk/verilog/74lvc1g.v ../liberty74/pdk/verilog/74vhc.v ../liberty74/pdk/verilog/W24129A.v ../liberty74/verilog_models/* rtl/servisia_tb.sv --binary --top-module servisia_tb --Wno-UNOPTFLAT -o servisia_tb

sim_exe: rtl/*.v out/servisia.v
	verilator --trace -j out/servisia.v subservient/rtl/subservient_generic_ram.v ../liberty74/pdk/verilog/74lvc1g.v ../liberty74/pdk/verilog/74vhc.v ../liberty74/pdk/verilog/W24129A.v ../liberty74/verilog_models/* rtl/servisia_tb.sv --binary --top-module servisia_tb --Wno-UNOPTFLAT -o servisia_tb

prepare_synth: out/servisia.v

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

out/servisia.v: rtl/*.v out
	bender sources -f > out/sources.json
	morty -f out/sources.json --top servisia > out/servisia.v

out:
	mkdir -p out

clean:
	rm -rf out
	rm -rf obj_dir
	rm -f programs/*.o
	rm -f programs/*.elf
	rm -f programs/*.bin
	rm -f programs/*.binary
	rm -f *.vcd 
