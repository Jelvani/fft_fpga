# Project setup
PROJ      = packet_proc
BUILD     = ./build
DEVICE    = 8k
FOOTPRINT = ct256


# Files
FILES = top.v ../uart_trx.v packet_processor.v ../baud_clock.v
TB_FILES = top_tb.v ../uart_trx.v packet_processor.v ../baud_clock.v

.PHONY: all clean burn

all:$(BUILD)/$(PROJ).bin

$(BUILD)/$(PROJ).bin: $(FILES) Makefile
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top top -json $(BUILD)/$(PROJ).json" $(FILES)
	# Place and route using arachne
	nextpnr-ice40 --hx8k --package $(FOOTPRINT) --asc $(BUILD)/$(PROJ).asc --pcf ../pinmap_$(FOOTPRINT).pcf --json $(BUILD)/$(PROJ).json
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

sim: $(FILES)
	verilator --cc --binary $(TB_FILES)

burn:   $(BUILD)/$(PROJ).bin
	iceprog $<

clean:
	rm -f build/*
