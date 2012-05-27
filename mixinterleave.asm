;;; ============================================================================
;;; bit-rot INTERLEAVE MIX/L/R
;;; (c) 2012 Sebastian Gutsfeld
;;;
;;; OUTL: interleaved bitwise combination of the mix of both ins and both
;;;       individual ins with ring-modulation by right in
;;; OUTR: left out but inverted and with additional delay
;;;
;;; POT0: select applied bitmask for interleaving the bits (0 means no input
;;;       combination, only left in is sent to out)
;;; POT1: ring-modulation amount of combined out with right in
;;; POT2: delay time of right out (0 to 100ms)
;;; ============================================================================

        equ     m1m     %11110000_00001111_00000000
        equ     m2m     %11100000_01110000_00111000
        equ     m3m     %11000011_00001100_00110000
        equ     m4m     %10010010_01001001_00100100

        equ     m1l     %00001111_00000000_11110000
        equ     m2l     %00011100_00001110_00000111
        equ     m3l     %00110000_11000011_00001100
        equ     m4l     %01001001_00100100_10010010

        equ     m1r     %00000000_11110000_00001111
        equ     m2r     %00000011_10000001_11000000
        equ     m3r     %00001100_00110000_11000011
        equ     m4r     %00100100_10010010_01001001

        equ     a       reg0
        equ     b       reg1
        equ     c       reg2
        equ     prev    reg3

        equ     length  3276
        equ     smooth  0.125
        mem	delay   length
        equ	del_r   reg4

        equ     pot0flt reg5
        equ     fpot0   reg6
        equ     pot1flt reg7
        equ     fpot1   reg8

init:   skp	run,    loop
        clr
        wrax    prev,   0
        wrax	del_r,  0
        wrax	pot0flt,0
        wrax	fpot0,  0
        wrax	pot1flt,0
        wrax	fpot1,  0
loop:


;;; ============================================================================
;;; read delay length
;;; ============================================================================

        clr
        or      length * 256    ; shift length in acc by 8 bits
        mulx	pot2
        mulx	pot2            ; exponential for more fun when mixing both outs
        rdfx	del_r,  smooth
        wrax	del_r,  0


;;; ============================================================================
;;; shelving highpass for faster pot response
;;; ============================================================================

        ldax    pot0
        rdfx    pot0flt,0.001
        wrhx    pot0flt,-0.75
        rdax    fpot0,  0.75
        wrax    fpot0,  0

        ldax    pot1
        rdfx    pot1flt,0.001
        wrhx    pot1flt,-0.75
        rdax    fpot1,  0.75
        wrax    fpot1,  0


;;; ============================================================================
;;; select bitmask
;;; ============================================================================

        ;; compensate non-linear pot0 behavior by using different offsets
        ldax    fpot0
        sof     1,      -0.2
        skp	neg,    outl
        sof	1,      -0.3
        skp	neg,    mask1
        sof	1,      -0.28
        skp	neg,    mask2
        sof	1,      -0.15
        skp	neg,    mask3
        skp	run,    mask4

mask1:  ldax    adcl
        and     m1l
        wrax    a,      0
        ldax    adcr
        and     m1r
        wrax    b,      0
        ldax    adcl
        rdax    adcr,   1
        and     m1m
        wrax    c,      0
        skp     run,    combine

mask2:  ldax    adcl
        and     m2l
        wrax    a,      0
        ldax    adcr
        and     m2r
        wrax    b,      0
        ldax    adcl
        rdax    adcr,   1
        and     m2m
        wrax    c,      0
        skp     run,    combine

mask3:  ldax    adcl
        and     m3l
        wrax    a,      0
        ldax    adcr
        and     m3r
        wrax    b,      0
        ldax    adcl
        rdax    adcr,   1
        and     m3m
        wrax    c,      0
        skp     run,    combine

mask4:  ldax    adcl
        and     m4l
        wrax    a,      0
        ldax    adcr
        and     m4r
        wrax    b,      0
        ldax    adcl
        rdax    adcr,   1
        and     m4m
        wrax    c,      0
        skp     run,    combine


;;; ============================================================================
;;; combine inputs
;;; ============================================================================

outl:   ldax    adcl
        skp     run,    saveprev
combine:clr
        rdax    a,      0.8
        rdax    b,      0.8
        rdax    c,      0.8
saveprev:
        wrax    prev,   1


;;; ============================================================================
;;; output with ring-modulation and delay
;;; ============================================================================

out:    mulx    adcr            ; ringmod with right in
        sof     1.7,    0
        rdax    prev,   -1
        mulx    fpot1
        rdax    prev,   1
        wrax    dacl,   -1      ; invert and apply delay on right out
dly:    wra	delay,	0
        rdax	del_r,  1
        wrax	addr_ptr, 0
        rmpa	1
        wrax	dacr,	0
