# bbc-shadow-ram
Some code for a BBC Master 128 to prototype double buffered rendering using Shadow RAM

## Shadow RAM on a BBC Master 128

```

; The BBC Master has 128K of system RAM as follows:
;  - Four banks of paged 16Kb Sideways RAM slots, at address &8000-&BFFF
;  - 32Kb of main memory, at address &0000-&7FFF
;  - 20Kb of shadow screen memory, at address &3000-&7FFF
;  - 8Kb of filing system RAM, at address &C000
;  - 4Kb of MOS RAM, at address 

; Due to the presence of the 8Kb filing system RAM, PAGE on a BBC Master is &0E00 (rather than &1900 on a Model B)

; Accessing & controlling the Shadow RAM is achieved using the Access control register (ACCCON) at &FE34 
; See page 162 of the New Advanced User Guide (http://www.msknight.com/bbc/manuals/new-advanced-user-guide.pdf)
; Bit 7 - IRR - IRQ control
; Bit 6 - TST - always 0
; Bit 5 - IFJ - 1MHz bus/ROM cartridge select 
; Bit 4 - ITU - TUBE select
; Bit 3 - Y - 8Kb RAM function select
; Bit 2 - X - Main memory RAM source select
; Bit 1 - E - VDU Driver RAM Source select
; Bit 0 - D - CRTC RAM Source select


; D=0 Use main memory for screen, D=1 Use Shadow RAM for screen (contrary to what is specified in AUG)
; E=0 VDU Driver uses Shadow RAM, E=1 VDU Driver uses main memory
; X=0 Normal RAM in main memory, X=1 Shadow RAM in main memory
; Y=0 8K RAM at &C000 to &DFFF, Y=1 VDU Driver code at &C000
; ITU=0 enable external TUBE, ITU=1 enable internal TUBE
; IFJ=0 1Mhz bus at &FC00 to &FDFF, IFJ=1 cartridge at &FC00
; TST=0 normal state (do not change), TST=1 hardware test
; IRR=0 after IRQ processed, IRR=1 IRQ to CPU

; so double buffer rendering works as follows:
;   D=0,X=1 - Display from main memory, Draw to shadow memory (&3000-&7FFF)
;   D=1,X=0 - Display from shadow memory, Draw to main memory (&3000-&7FFF)


```

## Available RAM on a BBC Master 128
Note 'available' means you can use it, but only if you are writing pure, non-portable assembler that doesn't use MOS rendering or language functions.

```
Zero page &00-&8F

Memory from &0400 to &07FF = &0400 (1,024) bytes (1kb)
Memory from &0900 to &0CFF = &0400 (1,024) bytes (1kb)
Memory from &0E00 to &2FFF = &2200 (8,704) bytes (8.5Kb)

Vidmem from &3000-&7FFF is &5000 (20,480) bytes (20kb)
Shadow from &3000-&7FFF is &5000 (20,480) bytes (20Kb)
	Total vidmem &A000 (40,960) total bytes (40Kb)

4x SWR from &8000 to &BFFF = &4000 (16,384) bytes (16Kb)
	Total SWR &10000 (65,536) bytes (64Kb)

Memory from &C000 to &DFFF = &2000 (8,192) bytes (8Kb)


total 122.5Kb
```

If really desperate for RAM:

```
Some parts of &0200 to &03FF are usable
Some parts of &0800 to &08FF are usable
Some parts of &0D00 to &0DFF are usable
```

## Notes

CAN'T put code in Shadow/Video ram UNLESS it is duplicated in both shadow+Video ram AND does not self modify.

CAN put data in Shadow/Video RAM, as can be switched in when needed without affecting current display (but just remember to restore current double buffer setting when finished, so that rendering is not affected)

Any data placed in Shadow/Video RAM CANT be accessed if used by a renderer, since it is not guaranteed to exist in the same RAM as the current draw buffer

## References

[New Advanced User Guide p162](http://www.msknight.com/bbc/manuals/new-advanced-user-guide.pdf)