;;; ============================================================================
;;; bit-rot XOR
;;; (c) 2012 Sebastian Gutsfeld
;;;
;;; OUTL: XOR-based combination of both ins with ring-modulation of right in
;;; OUTR: left out but inverted and with additional delay
;;;
;;; POT0: select applied bitmask before calculating the XOR combination of both
;;;       ins (0 means no input combination, only left in is sent to out)
;;; POT1: ring-modulation amount of combined out with right in
;;; POT2: delay time of right out (0 to 100ms)
;;; ============================================================================

        equ     m1      %10000000_00000000_00000000
        equ     m2      %01000000_00000000_00000000
        equ     m3      %00100000_00000000_00000000
        equ     m4      %00010000_00000000_00000000

        equ     a       reg0
        equ     b       reg1
        equ     prev    reg2

        equ     length  3276
        equ     smooth  0.125
        mem	delay   length
        equ	del_r   reg3

        equ     pot0flt reg4
        equ     fpot0   reg5

init:   skp	run,    loop
        clr
        wrax    prev,   0
        wrax	del_r,  0
        wrax	pot0flt,0
        wrax	fpot0,  0
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
;;; select bitmask
;;; ============================================================================

        ldax    pot0

        ;; shelving highpass for faster pot0 response
        rdfx    pot0flt,0.001
        wrhx    pot0flt,-0.75
        rdax    fpot0,  0.75
        wrax    fpot0,  1

        ;; compensate non-linear pot0 behavior by using different offsets
        sof     1,      -0.2
        skp	neg,    outa    ; no bitmask
        sof	1,      -0.3
        skp	neg,    mask1
        sof	1,      -0.28
        skp	neg,    mask2
        sof	1,      -0.15
        skp	neg,    mask3
        skp	run,    mask4

mask1:  ldax    adcl
        and     m1
        wrax    a,      0
        ldax    adcr
        and     m1
        wrax    b,      0
        skp     run,    combine

mask2:  ldax    adcl
        and     m2
        wrax    a,      0
        ldax    adcr
        and     m2
        wrax    b,      0
        skp     run,    combine

mask3:  ldax    adcl
        and     m3
        wrax    a,      0
        ldax    adcr
        and     m3
        wrax    b,      0
        skp     run,    combine

mask4:  ldax    adcl
        and     m4
        wrax    a,      0
        ldax    adcr
        and     m4
        wrax    b,      0
        skp     run,    combine


;;; ============================================================================
;;; combine inputs
;;; ============================================================================

combine:ldax    a
        skp     zro,    f
t:      ldax    b
        skp     zro,    tf
tt:     skp     run,    outb
tf:     skp     run,    outa
f:      ldax    b
        skp     zro,    ff
ft:     skp     run,    outa
ff:     skp     run,    outb

outa:   ldax    adcl
        skp     run,    saveprev
outb:   ldax    adcr
        skp     run,    saveprev
outprev:ldax    prev
        skp     run,    saveprev
saveprev:
        wrax    prev,   1


;;; ============================================================================
;;; output with ring-modulation and delay
;;; ============================================================================

out:    mulx    adcr            ; ringmod with right in
        sof     1.7,    0
        rdax    prev,   -1
        mulx    pot1
        rdax    prev,   1
        wrax    dacl,   -1      ; invert and apply delay on right out
dly:    wra	delay,	0
        rdax	del_r,  1
        wrax	addr_ptr, 0
        rmpa	1
        wrax	dacr,	0
