PORT=COM4
AVRDUDE_CONF_PATH = "./config/avrdude.conf"
MCU=m2560
AS="/mnt/c/Program Files (x86)/Atmel/Studio/7.0/toolchain/avr8/avrassembler/avrasm2.exe"
# INCLUDE_PATH = "/mnt/c/Program Files (x86)/Atmel/Studio/7.0/packs/atmel/ATmega_DFP/1.7.374/avrasm/inc"
INCLUDE_PATH = "./inc"
AVRDUDE = "/mnt/c/Program Files (x86)/Arduino/hardware/tools/avr/bin/avrdude.exe"
TARGET=main
SRC_DIR=./src
HEX_FILES=$(TARGET).hex

# Rule to build all hex files
all: $(HEX_FILES)

# Clean command to remove generated files
clean:
	rm -f *.o *.hex *.obj *.elf *.cof *.eep.hex *.map

# Rule to assemble .asm files into .hex files
$(TARGET).hex: $(SRC_DIR)/$(TARGET).asm
	$(AS) -fI -I $(INCLUDE_PATH) $< -o $@

# Rule to program the hex file onto the microcontroller
program: $(HEX_FILES)
	$(AVRDUDE) -C $(AVRDUDE_CONF_PATH) -c wiring -p $(MCU) -P $(PORT) -U flash:w:$(HEX_FILES):i -D