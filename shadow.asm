
; Shadow RAM demo code
; BBC Master 128K
; Written for the purposes of speed rather than compatibility

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

ACCCON_D = (1<<0)
ACCCON_X = (1<<2)

; D=0 Use Shadow RAM for screen, D=1 Use main memory for screen
; E=0 VDU Driver uses Shadow RAM, E=1 VDU Driver uses main memory
; X=0 Normal RAM in main memory, X=1 Shadow RAM in main memory
; Y=0 8K RAM at &C000 to &DFFF, Y=1 VDU Driver code at &C000
; ITU=0 enable external TUBE, ITU=1 enable internal TUBE
; IFJ=0 1Mhz bus at &FC00 to &FDFF, IFJ=1 cartridge at &FC00
; TST=0 normal state (do not change), TST=1 hardware test
; IRR=0 after IRQ processed, IRR=1 IRQ to CPU

; so double buffer rendering works as follows:
;   D=1,X=1 - Display from main memory, Draw to shadow memory
;   D=0,X=0 - Display from shadow memory, Draw to main memory


ORG &0E00

.start

; Fill a teletext screen (1Kb) with a given character
; on entry A=character, X=memory address msb to write 
.fill_screen
{
    ldx #0
.loop
    sta &7c00,x
    sta &7d00,x
    sta &7e00,x
    sta &7f00,x
    inx
    bne loop
    rts
}




; we set bits 0 and 2, so that display=Main RAM, and shadow ram is selected as main memory
.shadow_init_buffers
{
    lda &fe34
    ora #1+4    ; set D and X to 1
    and #255-8  ; set Y to 0, so that the 8Kb Buffer can be used as RAM
    sta &fe34
    rts
}

; we swap the buffers by inverting bits 0 and 2
;  the previously selected main memory becomes display memory
;  and previously selected display memory becomes main memory
.shadow_swap_buffers
{
    lda &fe34
    eor #1+4
    sta &fe34
    rts
}


.entry
{
    ; switch to mode 7 (teletext)
    lda #22
    jsr &ffee
    lda #7
    jsr &ffee

    ; turn off cursor
	lda #10
    sta &fe00
	lda #32
    sta &fe01

    ; fill the current screen
    ; currently display buffer = draw buffer
    lda #65
    jsr fill_screen

    jsr &ffe0

    ; initialise the double buffer display scheme
    jsr shadow_init_buffers

    ; now we have shadow ram selected as the draw buffer
    ; so fill that
    lda #66
    jsr fill_screen

    ; now we can just sit in a loop swapping these buffers as long as we like
    ; at any time we can write to &7C00 and it will only be shown on the next swap update
.main_loop

    ; wait for vertical sync
    lda #19
    jsr &fff4

    ; swap display & draw buffers
    jsr shadow_swap_buffers

    ; wait for a keypress
    jsr &ffe0

    jmp main_loop


    rts
}


.end

SAVE "Main", start, end, entry