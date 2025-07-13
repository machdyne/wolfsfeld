RTL_PICO = \
	rtl/sysctl.v \
	rtl/cpu/picorv32/picorv32.v \
	rtl/mem/bram.v \
	rtl/mem/vram.v \
	rtl/mem/spram.v \
	rtl/spiflashro.v \
	rtl/debug.v \
	rtl/i2c.v \
	rtl/rtc.v \
	rtl/power.v \
	rtl/vid/ntsc.v \
	rtl/vid/pll.v \
	rtl/ext/uart16550/rtl/verilog/uart_top.v \
	rtl/ext/uart16550/rtl/verilog/uart_wb.v \
	rtl/ext/uart16550/rtl/verilog/uart_debug_if.v \
	rtl/ext/uart16550/rtl/verilog/uart_defines.v \
	rtl/ext/uart16550/rtl/verilog/uart_regs.v \
	rtl/ext/uart16550/rtl/verilog/uart_rfifo.v \
	rtl/ext/uart16550/rtl/verilog/uart_tfifo.v \
	rtl/ext/uart16550/rtl/verilog/uart_sync_flops.v \
	rtl/ext/uart16550/rtl/verilog/uart_transmitter.v \
	rtl/ext/uart16550/rtl/verilog/uart_receiver.v \
	rtl/ext/uart16550/rtl/verilog/raminfr.v

BOARD = wolfsfeld
BOARD_LC = $(shell echo '$(BOARD)' | tr '[:upper:]' '[:lower:]')
BOARD_UC = $(shell echo '$(BOARD)' | tr '[:lower:]' '[:upper:]')

ifndef CABLE
	CABLE = dirtyJtag
endif

ifeq ($(BOARD_LC), wolfsfeld)
	FAMILY = ice40
	DEVICE = up5k
	PACKAGE = sg48
	PCF = wolfsfeld.pcf
	PROG = ldprog -s
	FLASH = ldprog -f
endif

FAMILY_UC = $(shell echo '$(FAMILY)' | tr '[:lower:]' '[:upper:]')

zeitlos: zeitlos_pico bios soc

ifeq ($(FAMILY), ice40)
zeitlos_pico: zeitlos_ice40_pico
else ifeq ($(FAMILY), ecp5)
zeitlos_pico: zeitlos_ecp5_pico
else ifeq ($(FAMILY), gatemate)
zeitlos_pico: zeitlos_gatemate_pico
endif

zeitlos_ice40_pico:
	mkdir -p output/$(BOARD_LC)
	yosys -DBOARD_$(BOARD_UC) -q -p \
		"synth_ice40 -top sysctl -json output/$(BOARD_LC)/soc.json" $(RTL_PICO)
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) --pcf $(PCF) \
		--asc output/$(BOARD_LC)/soc.txt --json output/$(BOARD_LC)/soc.json \
		--pcf-allow-unconstrained --opt-timing \
		--pre-pack rtl/constraints.py

zeitlos_ecp5_pico:
	mkdir -p output/$(BOARD_LC)
	yosys -DBOARD_$(BOARD_UC) -q -p \
		"synth_ecp5 -top sysctl -json output/$(BOARD_LC)/soc.json" $(RTL_PICO)
	nextpnr-ecp5 --$(DEVICE) --package $(PACKAGE) --lpf boards/$(LPF) \
		--json output/$(BOARD_LC)/soc.json \
		--report output/$(BOARD_LC)/report.txt \
		--textcfg output/$(BOARD_LC)/soc.config \
		--timing-allow-fail #--lpf-allow-unconstrained

zeitlos_gatemate_pico:
	mkdir -p output/$(BOARD_LC)
	$(SYNTH) -DBOARD_$(BOARD_UC) -q -l synth.log -p \
		"read -sv $(RTL_PICO); synth_gatemate -top sysctl -nomx8 -vlog output/$(BOARD_LC)/soc_synth.v"
	$(PR) -i output/$(BOARD_LC)/soc_synth.v -o output/$(BOARD_LC)/soc $(PRFLAGS)

bios:
	cd sw/bios && make BOARD=$(BOARD_UC) FAMILY=$(FAMILY_UC)

os:
	cd sw/os && make BOARD=$(BOARD_UC) FAMILY=$(FAMILY_UC)

ifeq ($(FAMILY), ice40)
soc:
	icebram sw/bios/bios_seed.hex sw/bios/bios.hex < \
		output/$(BOARD_LC)/soc.txt | icepack > output/$(BOARD_LC)/soc.bin
else ifeq ($(FAMILY), ecp5)
soc:
	ecpbram -i output/$(BOARD_LC)/soc.config \
		-o output/$(BOARD_LC)/soc_final.config \
		-f sw/bios/bios_seed.hex \
		-t sw/bios/bios.hex
	ecppack -v --compress --freq 2.4 output/$(BOARD_LC)/soc_final.config \
		--bit output/$(BOARD_LC)/soc.bin
endif

dev: clean_bios bios
dev-prog: dev soc prog
dev-os: clean_bios bios clean_os os flash

prog: 
	$(PROG) output/$(BOARD_LC)/soc.bin

flash:
	#$(FLASH) $(FLASH_OFFSET) output/$(BOARD_LC)/soc.bin
	$(FLASH) $(FLASH_OFFSET) sw/os/kernel.bin 40000

clean: clean_os clean_bios clean_apps

clean_soc:
	rm -rf output/*

clean_bios:
	cd sw/bios && make clean

clean_os:
	cd sw/os && make clean

.PHONY: clean_bios bios
