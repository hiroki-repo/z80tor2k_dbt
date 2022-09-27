org $f200

;;Global Control/Status Register
GCSR	equ	$00
;;Global Output Control Register
GOCR	equ	$0e
;;MMU: Memory Bank 0 Control Ragister
MB0CR	equ	$14
;;MMU: Memory Bank 1 Control Ragister
MB1CR	equ	$15
;;MMU: MMU Instruction/Data Register
MMIDR	equ	$10
;;MMU: Data Segment Register(Z180 BBR)
DATASEG	equ	$12
;;MMU: Segment Size Register(Z180 CBAR)
SEGSIZE	equ	$13
;;MMU: Stack Segment Register(Z180 CBR)
STACKSEG	equ	$11


;;Parallel ports 
;;PPC
;;Port C Data Ragister
PCDR	equ	$50
;;Port C Function Ragister
PCFR	equ	$55


;;Timer A
;;Timer A Control/Status Register
TACSR	equ	$a0
;;Timer A Control Register
TACR	equ	$a4
;;Timer A1 Constant register
TAT1R	equ	$A3
;;Timer A4 Constant register
TAT4R	equ	$A9

;;Serial A port
;;Serial A Port Status Register
SASR	equ	$c3
;;Serial A port Control Register
SACR	equ	$c4
;;Serial A port Data Register
SADR	equ	$c0
;;Serial A port Long Register
SALR	equ	$c2


	jp boot
wbt:	jp wboot
	jp const
	jp conin
	jp conout
	jp list
	jp punch
	jp reader
	jp home
	jp seldsk
	jp settrk
	jp setsec
	jp setdma
	jp read
	jp write
	jp listst
	jp sectran

boot_from_r2k:
	ld sp,emz80onr2k-256
	ld hl,$f200
	jp emz80onr2k

;
;	Data tables for disks
;	Four disks, 26 sectors/track, disk size = number of 1024 byte blocks
;	Number of directory entries (32-bytes each) set to 127 per 500 blocks
;	Allocation map bits = number of blocks needed to contain directory entries
;	No translations -- translation maps commented out
;
;	disk Parameter header for disk 00
dpbase:	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk00, all00
;	disk parameter header for disk 01
	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk01, all01
;	disk parameter header for disk 02
	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk02, all02
;	disk parameter header for disk 03
	dw	0000h, 0000h
	dw	0000h, 0000h
	dw	dirbf, dpblk
	dw	chk03, all03
;
;	sector translate vector
;Since no translation will comment out
;trans:	db	 1,  7, 13, 19	;sectors  1,  2,  3,  4
;	db	25,  5, 11, 17	;sectors  5,  6,  7,  6
;	db	23,  3,  9, 15	;sectors  9, 10, 11, 12
;	db	21,  2,  8, 14	;sectors 13, 14, 15, 16
;	db	20, 26,  6, 12	;sectors 17, 18, 19, 20
;	db	18, 24,  4, 10	;sectors 21, 22, 23, 24
;	db	16, 22		;sectors 25, 26
;
dpblk:	;disk parameter block for all disks.
	dw	256		;sectors per track
	db	4		;block shift factor
	db	15		;block mask - with block shift, sets block size to 1024
	db	0		;null mask
	dw	1023		;disk size-1 = number of blocks in a disk - 1
	dw	256		;directory max = no. directory entries/disk, arbitrary
	db	240		;alloc 0 -- need 4 bits (blocks) for 256 directory entries -- 
	db	0		;alloc 1 -- no. bits = (directory max x 32)/block size	
	dw	0		;check size -- no checking, so zero
	dw	1		;track offset -- first track for system
;
;	end of fixed tables
;



boot:
	db $76
bootx:
	ld	a,$08				;proc=OSC,pclk=osc,periodic interrupt=disable
	ioi ld	(GCSR),a
	ld	a,$00				;0x000000 Use /OE0 or /WE0 Use CS0
	ioi ld	(MB0CR),a		;use ROM
	ld	a,$05				;0x400000 Use /OE1 or /WE1 Use CS1
	ioi ld	(MB1CR),a		;use RAM
;
	ld	a,$01				;PCLK/2 Timer A Enabled
	ioi ld	(TACSR),a
	ld	a,$00				;Timer A4~A7 Clocked by PCLK/2,interrupts disabled
	ioi ld	(TACR),a
	ld	a,0x0f			;A-ch Clock timer :=(PCLK/2/16/38400)-1 (PCLK=19.6608MHz >> 38400bps)
	ioi ld	(TAT4R),a

	ld	a,$40				;MMU Data Reg Physics address 0x40000 (CS1)
	;ioi ld	(DATASEG),a
	ld	a,$40				;MMU Stack Reg Physics address 0x40000 (CS1)
	;ioi ld 	(STACKSEG),a
	ld	a,$a8				;MMU Segsize logic Data address 0x8000 (CS1:0x48000)
	;ioi ld	(SEGSIZE),a		;MMU Segsize logic Stack address 0xa000 (CS1:0x4a000)
	
	ld	a,$40				;MMU XPC Physics address 0x40000 (CS1:0x4e000)
	;ld	xpc,a
	
	;jp	main

main:
	;ld	sp,$e000			;stack pointer set

	call	ppinit			;parallel ports initialize
	call	sioinit			;serial channel initialize

	ld a,$94
	ld ($0003),a

	;ld a,'H'
	;call	putchar

	jp wbootfromboot

loop:
	call	getchar
	call	putchar
	jr	loop
	
ppinit:
	ld	a,$40
	ioi ld	(PCFR),a		;C Port TxA set
	ret
sioinit:
	ld	a,$00
	ioi ld	(SACR),a		;Asynch mode, C port used, 8bit, Interrupt Disabled
	ret

putchar:				
	push	af
putchar01:
	ioi ld	a,(SASR)		;Serial A port Status in
      	bit     3,a			
        jr      nz,putchar01		;XMIT DATA REG > Full(bit3==1) check
 	pop	af
 	push	af
	ioi ld	(SADR),a		;no full(Empty) >> TxA data out
putchar_busy:
	ioi ld	a,(SASR)		;Serial A port Status in
	bit	3,a			;XMIT DATA REG > Full(bit3==1) check 
	jr	nz,putchar_busy
	pop	af			;no full(Empty) >> return
	ret
	
getchar:
	ioi ld 	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG > EMPTY(bit7==0) check
	jr	z,getchar
	ioi ld	a,(SADR)		;No EMPTY(Full) > RxA data in
	push	af
getchar01:
	ioi ld	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG >EMPTY(bit7==0) check
	jr	nz,getchar01
	pop	af			;EMPTY >> return
	ret

wboot:
	db $76
	ld (backup4de),de
wbootfromboot:
	ld hl,$dc00
	ld b,1
wbootfromboot_1:
	ld a,b
	ioe ld ($0000),a
	inc b
	ld a,0
	ioe ld ($0001),a
	ioe ld ($0002),hl
	ld a,l
	add $80
	ld l,a
	ld a,h
	adc 0
	ld h,a
	ld a,0
	sla a
	and a,$1e
	set 0,a
	ioe ld ($0005),a
	ld a,b
	cp a,45
	jr nz,wbootfromboot_1
	ld a,0c3h
	ld (0),a
	ld de,wbt
	ld (1),de
	ld (5),a
	ld de,$e406
	ld (6),de
	ld a,($0004)
	ld (context+2),a
	ld hl,$0080
	ld (context+8),hl
	ld (cpmdma),hl
	ld hl,$dc00
	ret
const:
	db $76
	;ld a,'H'
	;call	putchar
	ld a,($0003)
	and a,3
	cp a,0
	jr z,const_tty
	cp a,1
	jr z,const_crt
	cp a,2
	jp z,listst
const_uc1:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret

const_tty:
	ioi ld 	a,(SASR)		;Serial A port Status in
	bit	7,a			;RCV DATA REG > EMPTY(bit7==0) check
	jr	z,const_tty_zero
	ld a,$ff
	ld (context+1),a
	ld hl,return_to_cpm
	ret
const_tty_zero:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret

const_crt:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret

conin:
	db $76
	ld a,($0003)
	and a,3
	cp a,0
	jr z,conin_tty
	cp a,1
	jr z,conin_crt
	cp a,2
	jp z,reader
conin_uc1:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret

conin_tty:
	call getchar
	ld (context+1),a
	ld hl,return_to_cpm
	ret
conin_crt:
	ld a,0
	ld (context+1),a
	ld hl,return_to_cpm
	ret

conout:
	db $76
	ld a,($0003)
	and a,3
	cp a,0
	jr z,conout_tty
	cp a,1
	jr z,conout_crt
	cp a,2
	jp z,list
conout_uc1:
	ld hl,return_to_cpm
	ret

conout_tty:
	ld a,(context+2)
	call putchar
	ld hl,return_to_cpm
	ret
conout_crt:
	ld hl,return_to_cpm
	ret

list:
	db $76
	ld a,($0003)
	rra
	rra
	rra
	rra
	rra
	rra
	and a,3
	cp a,0
	jp z,conout_tty
	cp a,1
	jp z,conout_crt
	cp a,2
	jr z,list_lpt
list_ul1:
	ld hl,return_to_cpm
	ret

list_lpt:
	ld hl,return_to_cpm
	ret

punch:
	db $76
	ld a,($0003)
	rra
	rra
	rra
	rra
	and a,3
	cp a,0
	jp z,conout_tty
	cp a,1
	jr z,punch_ptp
	cp a,2
	jr z,punch_up1
punch_up2:
	ld hl,return_to_cpm
	ret
punch_up1:
	ld hl,return_to_cpm
	ret
punch_ptp:
	ld hl,return_to_cpm
	ret

reader:
	db $76
	ld a,($0003)
	rra
	rra
	and a,3
	cp a,0
	jp z,conin_tty
	cp a,1
	jr z,reader_ptp
	cp a,2
	jr z,reader_ur1
reader_ur2:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret
reader_ur1:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret
reader_ptp:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret

home:
	db $76
	ld hl,return_to_cpm
	ret
seldsk:
	db $76
	ld a,(context+1)
	cp a,4
	jr nc,seldsk_nulldrv
	ld (cpmdrive),a
	ld hl,dpbase
	ld b,0
	sla a
	sla a
	sla a
	sla a
	ld c,a
	add hl,bc
	ld (context+6),hl
	ld hl,return_to_cpm
	ret
seldsk_nulldrv:
	ld hl,0
	ld (context+6),hl
	ld hl,return_to_cpm
	ret

settrk:
	db $76
	ld hl,(context+2)
	ld (cpmtrk),hl
	ld hl,return_to_cpm
	ret
setsec:
	db $76
	ld hl,(context+2)
	ld (cpmsec),hl
	ld hl,return_to_cpm
	ret
setdma:
	db $76
	ld hl,(context+2)
	ld (cpmdma),hl
	ld hl,return_to_cpm
	ret
read:
	db $76
	ld a,(cpmsec)
	ioe ld ($0000),a
	ld a,(cpmtrk)
	ioe ld ($0001),a
	ld hl,(cpmdma)
	ioe ld ($0002),hl
	ld a,(cpmdrive)
	sla a
	and a,$1e
	set 0,a
	ioe ld ($0005),a
	ioe ld a,($0005)
	bit 0,a
	jr nz,readwrite_failed
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret
write:
	db $76
	ld a,(cpmsec)
	ioe ld ($0000),a
	ld a,(cpmtrk)
	ioe ld ($0001),a
	ld hl,(cpmdma)
	ioe ld ($0002),hl
	ld a,(cpmdrive)
	sla a
	and a,$1e
	res 0,a
	ioe ld ($0005),a
	ioe ld a,($0005)
	bit 0,a
	jr nz,readwrite_failed
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret
readwrite_failed:
	ld a,$FF
	ld (context+1),a
	ld hl,return_to_cpm
	ret
listst:
	db $76
	ld a,($0003)
	rra
	rra
	rra
	rra
	rra
	rra
	and a,3
	cp a,0
	jp z,const_tty
	cp a,1
	jp z,const_crt
	cp a,2
	jr z,listst_lpt
listst_ul1:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret

listst_lpt:
	ld a,$00
	ld (context+1),a
	ld hl,return_to_cpm
	ret

sectran:
	db $76
	ld hl,(context+4)
	ld bc,(context+2)
	add hl,bc
	ld (context+6),hl
	ld hl,return_to_cpm
	ret

;
;	the remainder of the cbios is reserved uninitialized
;	data area, and does not need to be a Part of the
;	system	memory image (the space must be available,
;	however, between"begdat" and"enddat").
;
track:	defs	2		;two bytes for expansion
sector:	defs	2		;two bytes for expansion
dmaad:	defs	2		;direct memory address
diskno:	defs	1		;disk number 0-15
;
;	scratch ram area for bdos use
begdat:	equ	$	 	;beginning of data area
dirbf:	defs	128	 	;scratch directory area
;Allocation scratch areas, size of each must be (DSM/8)+1
all00:	defs	128	 	;allocation vector 0
all01:	defs	128	 	;allocation vector 1
all02:	defs	128	 	;allocation vector 2
all03:	defs	128	 	;allocation vector 3
;Could probably remove these chk areas, but just made size small
chk00:	defs	1		;check vector 0
chk01:	defs	1		;check vector 1
chk02:	defs	1	 	;check vector 2
chk03:	defs	1	 	;check vector 3
;
enddat:	equ	$	 	;end of data area
datsiz:	equ	$-begdat;	;size of data area
hstbuf: ds	256		;buffer for host disk sector
addrbeepconf:db 00h


return_to_cpm:
	ret
backup4de:dw 0

cpmtrk:	dw 0
cpmsec:	dw 0
cpmdma:	dw 0
cpmdrive:	db 0
	
ds $a00-$
emz80onr2k:
ld a,0
ld (codestpy0-1),a
emz80onr2k_prefixed_rest:
ld a,0
ld (codestpy0+0),a
ld (codestpy0+1),a
ld (codestpy0+2),a
ld (codestpy0+3),a
ld (codestpy0+4),a
ld (codestpy0+5),a
ld (codestpy0+6),a
ld (codestpy0+7),a
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
cp a,$d3
jp z,emz80onr2k_opc_ioi
cp a,$db
jp z,emz80onr2k_opc_ioe

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
emz80onr2k_opc_ioi:
inc hl
ld a,$d3
ld (codestpy0-1),a
jp emz80onr2k_prefixed_rest
emz80onr2k_opc_ioe:
inc hl
ld a,$db
ld (codestpy0-1),a
jp emz80onr2k_prefixed_rest

emz80onr2k_opc_e9:
ld a,$22
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
ld (codestpy0+6),ix
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
ld (codestpy0+6),iy
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
cp a,$26
jr z,emz80onr2k_opc_xxyy_1
cp a,$2a
jr z,emz80onr2k_opc_xxyy_2
cp a,$2e
jr z,emz80onr2k_opc_xxyy_1
cp a,$34
jr z,emz80onr2k_opc_xxyy_1
cp a,$35
jr z,emz80onr2k_opc_xxyy_1
cp a,$36
jr z,emz80onr2k_opc_xxyy_2
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
inc hl
ld a,(hl)
ld (de),a
inc de
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
cp a,6
jp z,emz80onr2k_opc_c0_ff_gen_arith_args
cp a,7
jp z,emz80onr2k_opc_c0_ff_gen_rst

jp codestpx0

emz80onr2k_opc_c0_ff_gen_arith_args:
inc hl
ld a,(hl)
ld (codestpy0+1),a
jp codestpx0

emz80onr2k_opc_c0_ff_gen_ret_cond:
ld b,$c2
ld a,(hl)
and a,$38
or a,b
ld (codestpy0),a
ld de,ret4hlpcreg
ld (codestpy0+1),de
ld a,$c3
ld (codestpy0+3),a
ld de,codestpx1
ld (codestpy0+4),de
jp codestpx0

emz80onr2k_opc_c0_ff_gen_jp_cond:
ld b,$c2
ld a,(hl)
and a,$38
or a,b
ld (codestpy0),a
ld de,jp4hlpcreg
ld (codestpy0+1),de
ld a,$c3
ld (codestpy0+3),a
ld de,codestpx1
ld (codestpy0+4),de
inc hl
ld a,(hl)
ld (codestpy0+6),a
inc hl
ld a,(hl)
ld (codestpy0+7),a
jp codestpx0

emz80onr2k_opc_c0_ff_gen_call_cond:
ld b,$c2
ld a,(hl)
and a,$38
or a,b
ld (codestpy0),a
ld de,call4hlpcreg
ld (codestpy0+1),de
ld a,$c3
ld (codestpy0+3),a
ld de,codestpx1
ld (codestpy0+4),de
inc hl
ld a,(hl)
ld (codestpy0+6),a
inc hl
ld a,(hl)
ld (codestpy0+7),a
jp codestpx0

emz80onr2k_opc_c0_ff_gen_rst:
ld a,$c3
ld (codestpy0),a
ld de,call4hlpcreg
ld (codestpy0+1),de
ld a,(hl)
and a,$38
ld (codestpy0+6),a
ld a,0
ld (codestpy0+7),a
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
ld (codestpy0+6),a
inc hl
ld a,(hl)
ld (codestpy0+7),a
jp codestpx0

emz80onr2k_opc_c0_ff_gen_call:
ld a,$c3
ld (codestpy0),a
ld de,call4hlpcreg
ld (codestpy0+1),de
inc hl
ld a,(hl)
ld (codestpy0+6),a
inc hl
ld a,(hl)
ld (codestpy0+7),a
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
jp z,emz80onr2k_opc_00_3f_oplongsx_chk2
cp a,6
jp z,emz80onr2k_opc_00_3f_oplongsx_1
ld a,(hl)
and a,$27
cp a,$22
jp z,emz80onr2k_opc_00_3f_oplongsx_2
jp codestpx0
emz80onr2k_opc_00_3f_oplongsx_chk2:
ld a,(hl)
and a,8
jp z,emz80onr2k_opc_00_3f_oplongsx_2
jp codestpx0
emz80onr2k_opc_00_3f_lp:
ld de,codestpy0+1
emz80onr2k_opc_00_3f_lp_2:
inc hl
ld a,(hl)
ld (de),a
inc de
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
ld (codestpy0+6),a
jp codestpx0
emz80onr2k_opc_jrtranslatex_gencond_00_djnz:
ld a,$c3
ld (codestpy0),a
ld de,jr4hlpcreg_djnz
ld (codestpy0+1),de
ld (codestpy0+3),a
ld de,codestpx1
ld (codestpy0+4),de
inc hl
ld a,(hl)
ld (codestpy0+6),a
jp codestpx0

emz80onr2k_opc_jrtranslatex_gencond_20:
ld a,(hl)
and a,$18
or a,b
emz80onr2k_opc_jrtranslatex_gencond_common:
ld (codestpy0),a
ld de,jr4hlpcreg
ld (codestpy0+1),de
ld a,$c3
ld (codestpy0+3),a
ld de,codestpx1
ld (codestpy0+4),de
inc hl
ld a,(hl)
ld (codestpy0+6),a
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

nop

codestpy0:

nop
nop
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
ld a,(codestpy0+6)
and a,128
jr nz,jr4hlpcreg_sub
ld a,(codestpy0+6)
ld e,a
ld hl,(context+10)
add hl,de
ld (context+10),hl
jp emz80onr2k
jr4hlpcreg_sub:
ld a,(codestpy0+6)
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
ld hl,(codestpy0+6)
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

