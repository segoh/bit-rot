;;; ringmod / xor combiner

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
        or      length * 256	        ; delay length into acc aligned to acc[22:8]
        mulx	pot1
        rdfx	dread,  smooth	        ; smooth: (target - current) * C + current
        wrax	dread,  0

        ;; read and store inputs
        rdax    adcl,   1
        wrax    a,      0
        rdax    adcr,   1
        wrax    b,      0

        ;; read pot for bit mask
        rdax    pot0,   1
        and	%01110000_00000000_00000000
        skp	zro,    outthru
        sof	1,      -0.125
        skp	zro,    mask1
        sof	1,      -0.125
        skp	zro,    mask2
        sof	1,      -0.125
        skp	zro,    mask3
        sof	1,      -0.125
        skp	zro,    mask4
        sof	1,      -0.125
        skp	zro,    mask5
        sof	1,      -0.125
        skp	zro,    mask6
        clr
        skp	zro,    mask7

mask1:  rdax    a,      1
        and     %10000000_00000000_00000000
        wrax    a,      0

        rdax    b,      1
        and     %10000000_00000000_00000000
        wrax    b,      0

        skp     run,    mix

mask2:  rdax    a,      1
        and     %01000000_00000000_00000000
        wrax    a,      0

        rdax    b,      1
        and     %01000000_00000000_00000000
        wrax    b,      0

        skp     run,    mix

mask3:  rdax    a,      1
        and     %00100000_00000000_00000000
        wrax    a,      0

        rdax    b,      1
        and     %00100000_00000000_00000000
        wrax    b,      0

        skp     run,    mix

mask4:  rdax    a,      1
        and     %00010000_00000000_00000000
        wrax    a,      0

        rdax    b,      1
        and     %00010000_00000000_00000000
        wrax    b,      0

        skp     run,    mix

mask5:  rdax    a,      1
        and     %00001000_00000000_00000000
        wrax    a,      0

        rdax    b,      1
        and     %00001000_00000000_00000000
        wrax    b,      0

        skp     run,    mix

mask6:  rdax    a,      1
        and     %00000100_00000000_00000000
        wrax    a,      0

        rdax    b,      1
        and     %00000100_00000000_00000000
        wrax    b,      0

        skp     run,    mix

mask7:  rdax    a,      1
        and     %00000010_00000000_00000000
        wrax    a,      0

        rdax    b,      1
        and     %00000010_00000000_00000000
        wrax    b,      0

        skp     run,    mix

        ;; prepare output
outthru:ldax    adcl
        skp     run,    out

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
