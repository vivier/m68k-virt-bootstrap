rom.bin: rom
	$(CROSS_COMPILE)objcopy -O binary -j .text rom rom.bin.X
	(cat rom.bin.X ; cat /dev/zero) | dd of=rom.bin iflag=fullblock bs=1024 count=1024
	rm -f rom.bin.X

rom: rom.S

%: %.S
	$(CROSS_COMPILE)gcc -m68040 -nostartfiles  -nodefaultlibs  -nostdlib -o $@ $<

.PHONY: clean

clean:
	rm  -f rom rom.bin
