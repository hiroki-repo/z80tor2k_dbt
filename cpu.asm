org $fc00
emz80onr2k:
ld a,0
ld (codestpy0+0),a
ld (codestpy0+1),a
ld (codestpy0+2),a
ld (codestpy0+3),a
ld (codestpy0+4),a
ld (codestpy0+5),a
ld a,(hl)
ld (codestpy0),a
cp a,$cb
jp z,emz80onr2k_opc_cb
cp a,$dd
jp z,emz80onr2k_opc_dd
cp a,$fd
jp z,emz80onr2k_opc_fd
cp a,$e9
jp z,emz80onr2k_opc_e9
cp a,$ed
jp z,emz80onr2k_opc_ed
cp a,$76
jp z,emz80onr2k_opc_hlt

rra
rra
rra
rra
rra
rra
and a,3
cp a,0
jp z,emz80onr2k_opc_00_3f
cp a,3
jp z,emz80onr2k_opc_c0_ff

jp codestpx0

emz80onr2k_opc_e9:
ld a,22
ld (codestpy0),a
ld de,context+10
ld (codestpy0+1),de
jp codestpx0

emz80onr2k_opc_hlt:
ld de,context
inc hl
call emz80onr2k_opc_thunk_hl
jp emz80onr2k
emz80onr2k_opc_thunk_hl:
jp (hl)

emz80onr2k_opc_ed:
inc hl
ld a,(hl)
ld (codestpy0+1),a
and a,$c7
cp a,$43
jr z,emz80onr2k_opc_ed_addr
ld a,(hl)
and a,$f7
cp a,$65
jr z,emz80onr2k_opc_ed_addr
jp codestpx0
emz80onr2k_opc_ed_addr:
inc hl
ld a,(hl)
ld (codestpy0+2),a
inc hl
ld a,(hl)
ld (codestpy0+3),a
jp codestpx0


emz80onr2k_opc_cb:
inc hl
ld a,(hl)
ld (codestpy0+1),a
jp codestpx0

emz80onr2k_opc_dd:
inc hl
ld a,(hl)
ld (codestpy0+1),a
cp a,$e9
jr z,emz80onr2k_opc_dd_e9
jp emz80onr2k_opc_xxyy
emz80onr2k_opc_dd_e9:
ld a,$c3
ld (codestpy0),a
ld de,jp4hlpcreg
ld (codestpy0+1),de
ld (codestpy0+3),ix
jp codestpx0

emz80onr2k_opc_fd:
inc hl
ld a,(hl)
ld (codestpy0+1),a
cp a,$e9
jr z,emz80onr2k_opc_fd_e9
jp emz80onr2k_opc_xxyy
emz80onr2k_opc_fd_e9:
ld a,$c3
ld (codestpy0),a
ld de,jp4hlpcreg
ld (codestpy0+1),de
ld (codestpy0+3),iy
jp codestpx0


emz80onr2k_opc_xxyy:
ld a,(hl)
cp a,$cb
jr z,emz80onr2k_opc_xxyy_cb
and a,$78
cp a,$70
jr z,emz80onr2k_opc_xxyy_1
ld a,(hl)
cp a,$21
jr z,emz80onr2k_opc_xxyy_2
cp a,$22
jr z,emz80onr2k_opc_xxyy_2
cp a,$2a
jr z,emz80onr2k_opc_xxyy_2
cp a,$34
jr z,emz80onr2k_opc_xxyy_1
cp a,$35
jr z,emz80onr2k_opc_xxyy_1
cp a,$65
jr z,emz80onr2k_opc_xxyy_2
cp a,$6d
jr z,emz80onr2k_opc_xxyy_2
and a,$c4
cp a,$c4
jr z,emz80onr2k_opc_xxyy_1
ld a,(hl)
and a,7
cp a,6
jp nz,codestpx0
emz80onr2k_opc_xxyy_1:
inc hl
ld a,(hl)
ld (codestpy0+2),a
jp codestpx0
emz80onr2k_opc_xxyy_2:
inc hl
ld a,(hl)
ld (codestpy0+2),a
inc hl
ld a,(hl)
ld (codestpy0+3),a
jp codestpx0

emz80onr2k_opc_xxyy_cb:
inc hl
ld a,(hl)
ld (codestpy0+2),a
inc hl
ld a,(hl)
ld (codestpy0+3),a
jp codestpx0

emz80onr2k_opc_xxyy_lp:
ld de,codestpy0+2
emz80onr2k_opc_xxyy_lp_2:
ld a,(hl)
ld (de),a
inc de
inc hl
djnz emz80onr2k_opc_xxyy_lp_2
jp codestpx0
emz80onr2k_opc_xxyy_oplongsx_1:
ld b,1
jr emz80onr2k_opc_xxyy_lp
emz80onr2k_opc_xxyy_oplongsx_2:
ld b,2
jr emz80onr2k_opc_xxyy_lp

emz80onr2k_opc_c0_ff:
ld a,(hl)
cp a,$c3
jp z,emz80onr2k_opc_c0_ff_gen_jp
cp a,$c9
jp z,emz80onr2k_opc_c0_ff_gen_ret
cp a,$cd
jp z,emz80onr2k_opc_c0_ff_gen_call
cp a,$e3
jp z,emz80onr2k_opc_c0_ff_gen_exsphl


ld a,(hl)
and a,7
cp a,0
jp z,emz80onr2k_opc_c0_ff_gen_ret_cond
cp a,2
jp z,emz80onr2k_opc_c0_ff_gen_jp_cond
cp a,4
jp z,emz80onr2k_opc_c0_ff_gen_call_cond
cp a,7
jp z,emz80onr2k_opc_c0_ff_gen_rst

jp codestpx0
emz80onr2k_opc_c0_ff_gen_ret_cond:
ld b,$c2
ld a,(hl)
and a,$38
or a,b
ld (codestpy0),a
ld de,ret4hlpcreg
ld (codestpy0+1),de
jp codestpx0

emz80onr2k_opc_c0_ff_gen_jp_cond:
ld b,$c2
ld a,(hl)
and a,$38
or a,b
ld (codestpy0),a
ld de,jp4hlpcreg
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+3),a
inc hl
ld a,(hl)
ld (codestpy0+4),a
jp codestpx0

emz80onr2k_opc_c0_ff_gen_call_cond:
ld b,$c2
ld a,(hl)
and a,$38
or a,b
ld (codestpy0),a
ld de,call4hlpcreg
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+3),a
inc hl
ld a,(hl)
ld (codestpy0+4),a
jp codestpx0

emz80onr2k_opc_c0_ff_gen_rst:
ld a,$c3
ld (codestpy0),a
ld de,call4hlpcreg
ld (codestpy0+1),de
ld a,(hl)
and a,$38
ld (codestpy0+3),a
ld a,0
ld (codestpy0+4),a
jp codestpx0


emz80onr2k_opc_c0_ff_gen_ret:
ld a,$c3
ld (codestpy0),a
ld de,ret4hlpcreg
ld (codestpy0+1),de
jp codestpx0

emz80onr2k_opc_c0_ff_gen_jp:
ld a,$c3
ld (codestpy0),a
ld de,jp4hlpcreg
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+3),a
inc hl
ld a,(hl)
ld (codestpy0+4),a
jp codestpx0

emz80onr2k_opc_c0_ff_gen_call:
ld a,$c3
ld (codestpy0),a
ld de,call4hlpcreg
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+3),a
inc hl
ld a,(hl)
ld (codestpy0+4),a
jp codestpx0


emz80onr2k_opc_c0_ff_gen_exsphl:
ld a,$ed
ld (codestpy0+0),a
ld a,$54
ld (codestpy0+1),a
jp codestpx0

emz80onr2k_opc_00_3f:
ld a,(hl)
and a,7
cp a,0
jp z,emz80onr2k_opc_jrtranslatex
cp a,1
jp z,emz80onr2k_opc_00_3f_oplongsx_2
cp a,6
jp z,emz80onr2k_opc_00_3f_oplongsx_1
ld a,(hl)
and a,27
cp a,$22
jp z,emz80onr2k_opc_00_3f_oplongsx_2
jp codestpx0
emz80onr2k_opc_00_3f_lp:
ld de,codestpy0+1
emz80onr2k_opc_00_3f_lp_2:
ld a,(hl)
ld (de),a
inc de
inc hl
djnz emz80onr2k_opc_00_3f_lp_2
jp codestpx0
emz80onr2k_opc_00_3f_oplongsx_1:
ld b,1
jr emz80onr2k_opc_00_3f_lp
emz80onr2k_opc_00_3f_oplongsx_2:
ld b,2
jr emz80onr2k_opc_00_3f_lp
emz80onr2k_opc_jrtranslatex:
ld b,$c2
ld a,(hl)
and a,$20
jr nz,emz80onr2k_opc_jrtranslatex_gencond_20

emz80onr2k_opc_jrtranslatex_gencond_00:
ld a,(hl)
and a,$10
jp z,codestpx0
ld a,(hl)
and a,$8
jr z,emz80onr2k_opc_jrtranslatex_gencond_00_djnz
ld a,$c3
ld (codestpy0),a
ld de,jr4hlpcreg
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+3),a
jp codestpx0
emz80onr2k_opc_jrtranslatex_gencond_00_djnz:
ld (codestpy0),a
ld de,jr4hlpcreg_djnz
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+3),a
jp codestpx0

emz80onr2k_opc_jrtranslatex_gencond_20:
ld a,(hl)
and a,$18
or a,b
emz80onr2k_opc_jrtranslatex_gencond_common:
ld (codestpy0),a
ld de,jr4hlpcreg
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+3),a
jp codestpx0

codestpx0:
inc hl
ld bc,(context+0)
ld (syscontext),sp
ld sp,syscontext4stk
push bc
pop af
ld (context+10),hl
ld bc,(context+2)
ld de,(context+4)
ld hl,(context+6)
ld sp,(context+8)
codestpy0:

nop
nop
nop
nop
nop
nop

codestpx1:
ld (context+2),bc
ld (context+4),de
ld (context+6),hl
ld (context+8),sp
ld hl,(context+10)
ld sp,syscontext4stk
push af
pop bc
ld sp,(syscontext)
ld (context+0),bc
jp emz80onr2k
codestpy1:

jr4hlpcreg_djnz:
dec b
ld (context+2),bc
ld a,b
and a
jr nz,jr4hlpcreg
ld hl,(context+10)
ld sp,(syscontext)
jp emz80onr2k
jr4hlpcreg:
ld d,0
ld a,(codestpy0+3)
and a,128
jr nz,jr4hlpcreg_sub
ld a,(codestpy0+3)
ld e,a
ld hl,(context+10)
add hl,de
ld (context+10),hl
jp emz80onr2k
jr4hlpcreg_sub:
ld a,(codestpy0+3)
sub 255
dec a
xor 255
inc a
ld e,a
ld hl,(context+10)
ld a,l
sub e
ld l,a
ld a,h
sbc a,0
ld h,a
ld (context+10),hl
ld sp,(syscontext)
jp emz80onr2k

call4hlpcreg:
ld hl,(context+10)
push hl
ld (context+8),sp
jp4hlpcreg:
ld hl,(codestpy0+3)
ld (context+10),hl
ld sp,(syscontext)
jp emz80onr2k

ret4hlpcreg:
pop hl
ld (context+10),hl
ld (context+8),sp
ld sp,(syscontext)
jp emz80onr2k

syscontext: dw 0,0,0
syscontext4stk:
context: dw 0,0,0,0,0,0,0,0,0,0

