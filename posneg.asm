;;; ============================================================================
;;; bit-rot POS/NEG
;;; (c) 2012 Sebastian Gutsfeld
;;;
;;; OUTL: bitmasked combination of left in's positive part or right in's negative
;;;       part with ring-modulation by right in
;;; OUTR: left out but inverted and with additional delay
;;;
;;; POT0: select applied bitmask before combining both ins (0 means only the left
;;;       in is sent to out)
;;; POT1: ring-modulation amount of combined out with right in
;;; POT2: delay time of right out (0 to 100ms)
;;; ============================================================================

        equ     m1      %11101111_11111111_11111111
        equ     m2      %11011111_11111111_11111111
        equ     m3      %10111111_11111111_11111111

        equ     prev    reg0

        equ     length  3276
        equ     smooth  0.125
        mem	delay   length
        equ	del_r   reg1

        equ     pot0flt reg2
        equ     fpot0   reg3
        equ     pot1flt reg4
        equ     fpot1   reg5

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
;;; combine inputs
;;; ============================================================================

lin:    ldax    adcl
        skp     gez,    mixdone
rin:    ldax    adcr
        skp     neg,    mixdone
        clr
mixdone:wrax    prev,   0


;;; ============================================================================
;;; select and apply bitmask
;;; ============================================================================

        ;; compensate non-linear pot0 behavior by using different offsets
        ldax    fpot0
        sof     1,      -0.2
        skp	neg,    leftout
        sof	1,      -0.3
        skp	neg,    nomask
        sof	1,      -0.28
        skp	neg,    mask1
        sof	1,      -0.15
        skp	neg,    mask2
        skp	run,    mask3

leftout:ldax    adcl
        wrax    prev,   1
        skp     run,    out

nomask: ldax    prev
        skp     run,    out

mask1:  ldax    prev
        and     m1
        wrax    prev,   1
        skp     run,    out

mask2:  ldax    prev
        and     m2
        wrax    prev,   1
        skp     run,    out

mask3:  ldax    prev
        and     m3
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

