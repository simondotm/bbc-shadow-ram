
; Shadow RAM demo code
; BBC Master 128K
; Written for the purposes of speed rather than compatibility



ORG &0E00

.start

; check if host machine is a Master 128
; we do this by testing if memory address &C000 is writable
; returns z=0 if master 128
;         z=1 if not 
.check_master
{
    sei
    lda &c000
    tay
    eor #&ff
    tax
    sta &c000
    cpx &c000
    sty &c000
    cli
    rts
}

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
    ora #4    	; set X to 1
    and #255-1  ; set D to 0
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
    eor #1+4	; invert bits 0 & 2
    sta &fe34
    rts
}

.error_text EQUS "Compatible with BBC Master 128 Only", 13, 10, 0
.entry
{
    jsr check_master
    beq ok

    ldx #0
.loop
    lda error_text,x
    beq quit
    jsr &ffee
    inx
    bne loop
.quit
    rts

.ok

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