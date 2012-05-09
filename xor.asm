;;; ringmod / xor combiner

        equ     m1      %10000000_00000000_00000000
        equ     m2      %01000000_00000000_00000000
        equ     m3      %00100000_00000000_00000000
        equ     m4      %00010000_00000000_00000000

        equ     a       reg0
        equ     b       reg1
        equ     prev    reg2

        equ     length  3276
        equ     smooth  0.0125
        mem	delay   length
        equ	dread   reg3

init:   skp	run,    loop
        clr
        wrax	dread,  0

loop:
        ;; read pot for delay shift
        clr
        or      length * 256    ; delay length into acc aligned to acc[22:8]
        mulx	pot1
        rdfx	dread,  smooth  ; smooth: (target - current) * C + current
        wrax	dread,  0

        ;; read and store inputs
        rdax    adcl,   1
        wrax    a,      0
        rdax    adcr,   1
        wrax    b,      0

        ;; read pot for bit mask
        ldax    pot0
        sof     1,      -0.2
        skp	neg,    outa
        sof	1,      -0.2
        skp	neg,    mask1
        sof	1,      -0.2
        skp	neg,    mask2
        sof	1,      -0.2
        skp	neg,    mask3
        skp	run,    mask4

mask1:  ldax    a
        and     m1
        wrax    a,      0

        ldax    b
        and     m1
        wrax    b,      0

        skp     run,    mix

mask2:  ldax    a
        and     m2
        wrax    a,      0

        ldax    b
        and     m2
        wrax    b,      0

        skp     run,    mix

mask3:  ldax    a
        and     m3
        wrax    a,      0

        ldax    b
        and     m3
        wrax    b,      0

        skp     run,    mix

mask4:  ldax    a
        and     m4
        wrax    a,      0

        ldax    b
        and     m4
        wrax    b,      0

        skp     run,    mix


        ;; prepare output
mix:    ldax    a
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
        skp     run,    out
outb:   ldax    adcr
        skp     run,    out
outprev:ldax    prev
        skp     run,    out

out:    wrax    prev,   1
        mulx    adcr            ; ringmod with right input
        rdax    prev,   -1
        mulx    pot2
        rdax    prev,   1
        wrax    dacl,   -1      ; invert
echo:   wra	delay,	0
        rdax	dread,  1
        wrax	addr_ptr, 0
        rmpa	1
        wrax	dacr,	0
end:
