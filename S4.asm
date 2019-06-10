; ______
;/\  _  \
;\ \ \L\ \  __  __  __     __    ____    ___     ___ ___      __
; \ \  __ \/\ \/\ \/\ \  /'__`\ /',__\  / __`\ /' __` __`\  /'__`\
;  \ \ \/\ \ \ \_/ \_/ \/\  __//\__, `\/\ \L\ \/\ \/\ \/\ \/\  __/
;   \ \_\ \_\ \___x___/'\ \____\/\____/\ \____/\ \_\ \_\ \_\ \____\
;    \/_/\/_/\/__//__/   \/____/\/___/  \/___/  \/_/\/_/\/_/\/____/
;
;
; ____                                   __
;/\  _`\               __               /\ \__
;\ \ \L\ \_ __   ___  /\_\     __    ___\ \ ,_\
; \ \ ,__/\`'__\/ __`\\/\ \  /'__`\ /'___\ \ \/
;  \ \ \/\ \ \//\ \L\ \\ \ \/\  __//\ \__/\ \ \_
;   \ \_\ \ \_\\ \____/_\ \ \ \____\ \____\\ \__\
;    \/_/  \/_/ \/___//\ \_\ \/____/\/____/ \/__/
;                     \ \____/
;                      \/___/

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; ASSEMBLY OPTIONS:
;
padToPowerOfTwo = 0
;	| If 1, pads the end of the rom to the next power of two bytes (for real hardware)
;
allOptimizations = 1
;	| If 1, enables all optimizations
;
skipChecksumCheck = 1|allOptimizations
;	| If 1, disables the unnecessary (and slow) bootup checksum calculation
;
zeroOffsetOptimization = 1|allOptimizations
;	| If 1, makes a handful of zero-offset instructions smaller
;
assembleZ80SoundDriver = 1
;	| If 1, the Z80 sound driver is assembled with the rest of the rom
;	| If 0, the Z80 sound driver is BINCLUDEd (less flexible)
;
useFullWaterTables = 1
;	| If 1, zone offset tables for water levels cover all level slots instead of only slots 8-$F
;	| Set to 1 if you've shifted level IDs around or you want water in levels with a level slot below 8

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; AS-specific macros and assembler settings
	CPU 68000
	include "S4.macrosetup.asm"

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Equates section - Names for variables.
	include "S4.constants.asm"

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; simplifying macros

; makes a VDP command
vdpComm function addr,type,rwd,(((type&rwd)&3)<<30)|((addr&$3FFF)<<16)|(((type&rwd)&$FC)<<2)|((addr&$C000)>>14)

; values for the type argument
VRAM = %100001
CRAM = %101011
VSRAM = %100101

; values for the rwd argument
READ = %001100
WRITE = %000111
DMA = %100111

; tells the VDP to copy a region of 68k memory to VRAM or CRAM or VSRAM
dma68kToVDP macro source,dest,length,type
	lea	(VDP_control_port).l,a5
	move.l	#(($9400|((((length)>>1)&$FF00)>>8))<<16)|($9300|(((length)>>1)&$FF)),(a5)
	move.l	#(($9600|((((source)>>1)&$FF00)>>8))<<16)|($9500|(((source)>>1)&$FF)),(a5)
	move.w	#$9700|(((((source)>>1)&$FF0000)>>16)&$7F),(a5)
	move.w	#((vdpComm(dest,type,DMA)>>16)&$FFFF),(a5)
	move.w	#(vdpComm(dest,type,DMA)&$FFFF),(DMA_data_thunk).w
	move.w	(DMA_data_thunk).w,(a5)
    endm

; tells the VDP to fill a region of VRAM with a certain byte
dmaFillVRAM macro byte,addr,length
	lea	(VDP_control_port).l,a5
	move.w	#$8F01,(a5) ; VRAM pointer increment: $0001
	move.l	#(($9400|((((length)-1)&$FF00)>>8))<<16)|($9300|(((length)-1)&$FF)),(a5) ; DMA length ...
	move.w	#$9780,(a5) ; VRAM fill
	move.l	#$40000080|(((addr)&$3FFF)<<16)|(((addr)&$C000)>>14),(a5) ; Start at ...
	move.w	#(byte)<<8,(VDP_data_port).l ; Fill with byte
-	move.w	(a5),d1
	btst	#1,d1
	bne.s	- ; busy loop until the VDP is finished filling...
	move.w	#$8F02,(a5) ; VRAM pointer increment: $0002
    endm

; calculates initial loop counter value for a dbf loop
; that writes n bytes total at 4 bytes per iteration
bytesToLcnt function n,n>>2-1

; calculates initial loop counter value for a dbf loop
; that writes n bytes total at 2 bytes per iteration
bytesToWcnt function n,n>>1-1

; fills a region of 68k RAM with 0 (4 bytes at a time)
clearRAM macro addr,length
    if length&3
	fatal "clearRAM len must be divisible by 4, but was length"
    endif
	lea	(addr).w,a1
	moveq	#0,d0
	move.w	#bytesToLcnt(length),d1
-	move.l	d0,(a1)+
	dbf	d1,-
    endm

; tells the Z80 to stop, and waits for it to finish stopping (acquire bus)
stopZ80 macro
	move.w	#$100,(Z80_Bus_Request).l ; stop the Z80
-	btst	#0,(Z80_Bus_Request).l
	bne.s	- ; loop until it says it's stopped
    endm

; tells the Z80 to start again
startZ80 macro
	move.w	#0,(Z80_Bus_Request).l    ; start the Z80
    endm

; function to make a little-endian 16-bit pointer for the Z80 sound driver
z80_ptr function x,(x)<<8&$FF00|(x)>>8&$7F|$80

; macro to declare a little-endian 16-bit pointer for the Z80 sound driver
rom_ptr_z80 macro addr
	dc.w z80_ptr(addr)
    endm

; macro to replace the destination with its absolute value
abs macro destination
	tst.ATTRIBUTE	destination
	bpl.s	+
	neg.ATTRIBUTE	destination
+
    endm

    if 0|allOptimizations
absw macro destination	; use a short branch instead
	abs.ATTRIBUTE	destination
    endm
    else
; macro to replace the destination with its absolute value using a word-sized branch
absw macro destination
	tst.ATTRIBUTE	destination
	bpl.w	+
	neg.ATTRIBUTE	destination
+
    endm
    endif

; macro to move the absolute value of the source in the destination
mvabs macro source,destination
	move.ATTRIBUTE	source,destination
	bpl.s	+
	neg.ATTRIBUTE	destination
+
    endm

objroutine function x,(x)-ObjBase

ckhit macro destlabel
	btst.b	#7,mappings(a0)
	beq.b	+
	move.w	#objroutine(destlabel),(a0)
	bra.ATTRIBUTE	destlabel
+
    endm

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; start of ROM

StartOfRom:
    if * <> 0
	fatal "StartOfRom was $\{*} but it should be 0"
    endif
;Vectors:
	dc.l System_Stack, EntryPoint, ErrorTrap, ErrorTrap; 4
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 8
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 12
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 16
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 20
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 24
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 28
	dc.l H_Int,     ErrorTrap, V_Int,     ErrorTrap; 32
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 36
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 40
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 44
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 48
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 52
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 56
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 60
	dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap; 64
; byte_200:
Header:
	dc.b "SEGA GENESIS    " ; Console name
	dc.b "(C)SEGA 2012.SEP" ; Copyright/Date
	dc.b "SONIC THE             HEDGEHOG 4                " ; Domestic name
	dc.b "SONIC THE             HEDGEHOG 4                " ; International name
	dc.b "GM 00001051-01"   ; Version
; word_18E
Checksum:
	dc.w $D951		; Checksum (patched later if incorrect)
	dc.b "J               " ; I/O Support
	dc.l StartOfRom		; ROM Start
; dword_1A4
ROMEndLoc:
	dc.l EndOfRom-1		; ROM End
	dc.l $FF0000		; RAM Start
	dc.l $FFFFFF		; RAM End
	dc.l $5241F820		; change to $5241E020 to create	SRAM
	dc.l $200000		; SRAM start
	dc.l $203FFF		; SRAM end
	dc.b "            "	; Modem support
	dc.b "                                        "	; Notes
	dc.b "JUE             " ; Country
EndOfHeader:

; ===========================================================================
; Crash/Freeze the 68000. Note that the Z80 continues to run, so the music keeps playing.
; loc_200:
ErrorTrap:
	nop
	nop
	bra.s	ErrorTrap

; ===========================================================================
; loc_206:
EntryPoint:
	tst.l	(Z80_Port_1_Control).l	; test port A control
	bne.s	PortA_Ok
	tst.w	(Z80_Expansion_Control).l	; test port C control
; loc_214:
PortA_Ok:
	bne.s	PortC_OK ; skip the VDP and Z80 setup code if port A or C is ok...?
	lea	SetupValues(pc),a5
	movem.w	(a5)+,d5-d7
	movem.l	(a5)+,a0-a4
	move.b	Z80_Version-Z80_Bus_Request(a1),d0	; get hardware version
	andi.b	#$F,d0
	beq.s	SkipSecurity ; branch if hardware is older than Genesis III
	move.l	#'SEGA',Security_Addr-Z80_Bus_Request(a1) ; satisfy the TMSS
; loc_234:
SkipSecurity:
	move.w	(a4),d0	; check if VDP works
	moveq	#0,d0
	movea.l	d0,a6
	move.l	a6,usp	; set usp to $0
	moveq	#VDPInitValues_End-VDPInitValues-1,d1 ; run the following loop $18 times
; loc_23E:
VDPInitLoop:
	move.b	(a5)+,d5	; add $8000 to value
	move.w	d5,(a4)	; move value to VDP register
	add.w	d7,d5	; next register
	dbf	d1,VDPInitLoop

	move.l	(a5)+,(a4)	; set VRAM write mode
	move.w	d0,(a3)	; clear the screen
	move.w	d7,(a1)	; stop the Z80
	move.w	d7,(a2)	; reset the Z80
; loc_250:
WaitForZ80:
	btst	d0,(a1)	; has the Z80 stopped?
	bne.s	WaitForZ80	; if not, branch
	moveq	#Z80StartupCodeEnd-Z80StartupCodeBegin-1,d2
; loc_256:
Z80InitLoop:
	move.b	(a5)+,(a0)+
	dbf	d2,Z80InitLoop

	move.w	d0,(a2)
	move.w	d0,(a1)	; start the Z80
	move.w	d7,(a2)	; reset the Z80
; loc_262:
ClrRAMLoop:
	move.l	d0,-(a6)
	dbf	d6,ClrRAMLoop	; clear the entire RAM
	move.l	(a5)+,(a4)	; set VDP display mode and increment
	move.l	(a5)+,(a4)	; set VDP to CRAM write
	moveq	#$1F,d3
; loc_26E:
ClrCRAMLoop:
	move.l	d0,(a3)
	dbf	d3,ClrCRAMLoop	; clear the CRAM
	move.l	(a5)+,(a4)
	moveq	#$13,d4
; loc_278: ClrVDPStuff:
ClrVSRAMLoop:
	move.l	d0,(a3)
	dbf	d4,ClrVSRAMLoop
	moveq	#PSGInitValues_End-PSGInitValues-1,d5
; loc_280:
PSGInitLoop:
	move.b	(a5)+,PSG_input-VDP_data_port(a3) ; reset the PSG
	dbf	d5,PSGInitLoop
	move.w	d0,(a2)
	movem.l	(a6),d0-a6	; clear all registers
	move	#$2700,sr	; set the sr
 ; loc_292:
PortC_OK: ;;
	bra.s	GameProgram
; ===========================================================================
; byte_294:
SetupValues:
	dc.w	$8000,$3FFF,$100

	dc.l	Z80_RAM
	dc.l	Z80_Bus_Request
	dc.l	Z80_Reset
	dc.l	VDP_data_port, VDP_control_port

VDPInitValues:	; values for VDP registers
	dc.b	  4, $14, $30, $3C
	dc.b	$07, $6C, $00, $00
	dc.b	$00, $00, $FF, $00
	dc.b	$81, $37, $00, $01
	dc.b	$01, $00, $00, $FF
	dc.b	$FF, $00, $00, $80
VDPInitValues_End:

	dc.l	vdpComm($0000,VRAM,DMA) ; value for VRAM write mode

	; Z80 instructions (not the sound driver; that gets loaded later)
	; I think this is basically unused but I've made some sense of it anyway...
Z80StartupCodeBegin: ; loc_2CA:
    if (*)+$26 < $10000
    CPU Z80 ; start compiling Z80 code
    phase 0 ; pretend we're at address 0
	xor     a	; clear a to 0
	ld      bc,((Z80_RAM_End-Z80_RAM)-zStartupCodeEndLoc)-1 ; prepare to loop this many times
	ld      de,zStartupCodeEndLoc+1	; initial destination address
	ld      hl,zStartupCodeEndLoc	; initial source address
	ld      sp,hl	; set the address the stack starts at
	ld      (hl),a	; set first byte of the stack to 0
	ldir    	; loop to fill the stack (entire remaining available Z80 RAM) with 0
	pop     ix	; clear ix
	pop     iy	; clear iy
	ld      i,a	; clear i
	ld      r,a	; clear r
	pop     de	; clear de
	pop     hl	; clear hl
	pop     af	; clear af
	ex      af,af'	; swap af with af'
	exx		; swap bc/de/hl with their shadow registers too
	pop     bc	; clear bc
	pop     de	; clear de
	pop     hl	; clear hl
	pop     af	; clear af
	ld      sp,hl	; clear sp
	di      	; clear iff1 (for interrupt handler)
	im      1	; interrupt handling mode = 1
	ld      (hl),0E9H ; replace the first instruction with a jump to itself
	jp      (hl)      ; jump to the first instruction (to stay there forever)
    zStartupCodeEndLoc:
    dephase ; stop pretending
    CPU 68000	; switch back to 68000 code
    padding off ; unfortunately our flags got reset so we have to set them again...
    listing off
    supmode on
    else ; due to an address range limitation I could work around but don't think is worth doing so:
;	message "Warning: using pre-assembled Z80 startup code."
    	dc.w $AF01,$D91F,$1127,$0021,$2600,$F977,$EDB0,$DDE1,$FDE1,$ED47,$ED4F,$D1E1,$F108,$D9C1,$D1E1,$F1F9,$F3ED,$5636,$E9E9
    endif
Z80StartupCodeEnd:

	dc.w	$8104	; value for VDP display mode
	dc.w	$8F02	; value for VDP increment
	dc.l	vdpComm($0000,CRAM,WRITE)	; value for CRAM write mode
	dc.l	vdpComm($0000,VSRAM,WRITE)	; value for VSRAM write mode

PSGInitValues:
	dc.b	$9F,$BF,$DF,$FF	; values for PSG channel volumes
PSGInitValues_End:
; ===========================================================================

	even
; loc_300:
GameProgram:
	tst.w	(VDP_control_port).l
; loc_306:
CheckSumCheck:
	move.w	(VDP_control_port).l,d1
	btst	#1,d1
	bne.s	CheckSumCheck
	btst	#6,(Z80_Expansion_Control+1).l
	beq.s	ChecksumTest
	cmpi.l	#'init',(Checksum_fourcc).w ; has checksum routine already run?
	beq.w	GameInit

; loc_328:
ChecksumTest:
    if skipChecksumCheck=0	; checksum code
	movea.l	#EndOfHeader,a0	; start checking bytes after the header ($200)
	movea.l	#ROMEndLoc,a1	; stop at end of ROM
	move.l	(a1),d0
	moveq	#0,d1
; loc_338:
ChecksumLoop:
	add.w	(a0)+,d1
	cmp.l	a0,d0
	bhs.s	ChecksumLoop
	movea.l	#Checksum,a1	; read the checksum
	cmp.w	(a1),d1	; compare correct checksum to the one in ROM
	bne.w	ChecksumError	; if they don't match, branch
    endif
;checksum_good:
	lea	(System_Stack).w,a6
	moveq	#0,d7

	move.w	#bytesToLcnt($200),d6
-	move.l	d7,(a6)+
	dbf	d6,-

	move.b	(Z80_Version).l,d0
	andi.b	#$C0,d0
	move.b	d0,(Graphics_Flags).w
	move.l	#'init',(Checksum_fourcc).w ; set flag so checksum won't be run again
; loc_370:
GameInit:
	lea	($FF0000).l,a6
	moveq	#0,d7
	move.w	#bytesToLcnt($FE00),d6
; loc_37C:
GameClrRAM:
	move.l	d7,(a6)+
	dbf	d6,GameClrRAM

	bsr.w	VDPSetupGame
	bsr.w	JmpTo_SoundDriverLoad
	bsr.w	JoypadInit
	move.b	#GameModeID_SegaScreen,(Game_Mode).w	; => SegaScreen
; loc_394:
MainGameLoop:
	move.b	(Game_Mode).w,d0
	andi.w	#$3C,d0
	jsr	GameModesArray(pc,d0.w)
	bra.s	MainGameLoop
; ===========================================================================
; loc_3A2:
GameModesArray: ;;
GameMode_SegaScreen:	bra.w	SegaScreen		; SEGA screen mode
GameMode_TitleScreen:	bra.w	TitleScreen		; Title screen mode
GameMode_Demo:		bra.w	Level			; Demo mode
GameMode_Level:		bra.w	Level			; Zone play mode
GameMode_ContinueScreen:bra.w	ContinueScreen		; Continue mode
GameMode_EndingSequence:bra.w	JmpTo_EndingSequence	; End sequence mode
GameMode_OptionsMenu:	bra.w	OptionsMenu		; Options mode
GameMode_LevelSelect:	bra.w	LevelSelectMenu		; Level select mode
; ===========================================================================
; loc_3CE:
ChecksumError:
	move.l	d1,-(sp)
	bsr.w	VDPSetupGame
	move.l	(sp)+,d1
	move.l	#vdpComm($0000,CRAM,WRITE),(VDP_control_port).l
	moveq	#$3F,d7
; loc_3E2:
Checksum_Red:
	move.w	#$E,(VDP_data_port).l
	dbf	d7,Checksum_Red
; loc_3EE:
ChecksumFailed_Loop:
	bra.s	ChecksumFailed_Loop
; ===========================================================================
; loc_3F6:
JmpTo_EndingSequence
	jmp	(EndingSequence).l
; ===========================================================================
; loc_3FC:
OptionsMenu: ;;
	jmp	(MenuScreen).l
; ===========================================================================
; loc_402:
LevelSelectMenu: ;;
	jmp	(MenuScreen).l
; ===========================================================================

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; vertical and horizontal interrupt handlers
; VERTICAL INTERRUPT HANDLER:
V_Int:
	movem.l	d0-a6,-(sp)
	tst.b	(Vint_routine).w
	beq.w	VintSub0

-	move.w	(VDP_control_port).l,d0
	andi.w	#8,d0
	beq.s	-

	move.l	#vdpComm($0000,VSRAM,WRITE),(VDP_control_port).l
	move.l	(Vscroll_Factor).w,(VDP_data_port).l
	btst	#6,(Graphics_Flags).w
	beq.s	+

	move.w	#$700,d0
-	dbf	d0,- ; wait here in a loop doing nothing for a while...
+
	move.b	(Vint_routine).w,d0
	move.b	#0,(Vint_routine).w
	move.w	#1,(Hint_flag).w
	andi.w	#$3E,d0
	move.w	Vint_SwitchTbl(pc,d0.w),d0
	jsr	Vint_SwitchTbl(pc,d0.w)

VintRet:
	jsr	Init_Sonic1_Sound_Driver
	addq.l	#1,(Vint_runcount).w
	movem.l	(sp)+,d0-a6
	rte
; ===========================================================================
Vint_SwitchTbl:
	dc.w VintSub0 - Vint_SwitchTbl
	dc.w VintSub2 - Vint_SwitchTbl	; 2
	dc.w VintSub4 - Vint_SwitchTbl	; 4
	dc.w VintSub6 - Vint_SwitchTbl	; 6
	dc.w VintSub8 - Vint_SwitchTbl	; 8
	dc.w VintSubA - Vint_SwitchTbl	; A
	dc.w VintSubC - Vint_SwitchTbl	; C
	dc.w VintSubE - Vint_SwitchTbl	; E
	dc.w VintSub10 - Vint_SwitchTbl	; 10
	dc.w VintSub12 - Vint_SwitchTbl	; 12
	dc.w VintSub14 - Vint_SwitchTbl	; 14
	dc.w VintSub16 - Vint_SwitchTbl	; 16
	dc.w VintSub18 - Vint_SwitchTbl	; 18
	dc.w VintSub1A - Vint_SwitchTbl	; 1A
; ===========================================================================

VintSub0:
	cmpi.b	#GameModeID_TitleCard|GameModeID_Demo,(Game_Mode).w	; pre-level Demo Mode?
	beq.s	loc_4C4
	cmpi.b	#GameModeID_TitleCard|GameModeID_Level,(Game_Mode).w	; pre-level Zone play mode?
	beq.s	loc_4C4
	cmpi.b	#GameModeID_Demo,(Game_Mode).w	; Demo Mode?
	beq.s	loc_4C4
	cmpi.b	#GameModeID_Level,(Game_Mode).w	; Zone play mode?
	beq.s	loc_4C4

	stopZ80			; stop the Z80
	bsr.w	sndDriverInput	; give input to the sound driver
	startZ80		; start the Z80

	bra.s	VintRet
; ---------------------------------------------------------------------------

loc_4C4:
	tst.b	(Water_flag).w
	beq.w	Vint0_noWater
	move.w	(VDP_control_port).l,d0
	btst	#6,(Graphics_Flags).w
	beq.s	+

	move.w	#$700,d0
-	dbf	d0,- ; do nothing for a while...
+
	move.w	#1,(Hint_flag).w

	stopZ80

	tst.b	(Water_fullscreen_flag).w
	bne.s	loc_526

	dma68kToVDP Normal_palette,$0000,$80,CRAM

	bra.s	loc_54A
; ---------------------------------------------------------------------------

loc_526:
	dma68kToVDP Underwater_palette,$0000,$80,CRAM

loc_54A:
	move.w	(Hint_counter_reserve).w,(a5)
	move.w	#$8230,(VDP_control_port).l	; Set scroll A PNT base to $C000
	bsr.w	sndDriverInput

	startZ80

	bra.w	VintRet
; ---------------------------------------------------------------------------

Vint0_noWater:
	move.w	(VDP_control_port).l,d0
	move.l	#vdpComm($0000,VSRAM,WRITE),(VDP_control_port).l
	move.l	(Vscroll_Factor).w,(VDP_data_port).l
	btst	#6,(Graphics_Flags).w
	beq.s	+

	move.w	#$700,d0
-	dbf	d0,- ; do nothing for a while...
+
	move.w	#1,(Hint_flag).w
	move.w	(Hint_counter_reserve).w,(VDP_control_port).l
	move.w	#$8230,(VDP_control_port).l		; Set scroll A PNT base to $C000
	move.l	($FFFFF61E).w,($FFFFEEEC).w

	stopZ80
	dma68kToVDP Sprite_Table,$F800,$280,VRAM
	bsr.w	sndDriverInput
	startZ80

	bra.w	VintRet
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

; This subroutine copies the H scroll table buffer (in main RAM) to the H scroll
; table (in VRAM).

VintSub2:
	bsr.w	sub_E98

	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM
	bsr.w	JmpTo_loc_3A68A
	tst.w	(Demo_Time_left).w
	beq.w	+	; rts
	subq.w	#1,(Demo_Time_left).w
+
	rts
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

VintSub14:
	move.b	(Vint_runcount+3).w,d0
	andi.w	#$F,d0
	bne.s	+

	stopZ80
	bsr.w	ReadJoypads
	startZ80
+
	tst.w	(Demo_Time_left).w
	beq.w	+	; rts
	subq.w	#1,(Demo_Time_left).w
+
	rts
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

VintSub4:
	bsr.w	sub_E98
	bsr.w	ProcessDPLC
	tst.w	(Demo_Time_left).w
	beq.w	+	; rts
	subq.w	#1,(Demo_Time_left).w
+
	rts
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

VintSub6:
	bsr.w	sub_E98
	rts
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

VintSub10:
;	cmpi.b	#GameModeID_SpecialStage,(Game_Mode).w	; Special Stage?
;	beq.w	Vint10_specialStage

VintSub8:

	stopZ80
;	cmp.b	#1,(Current_Zone).w	; vertical deformation
;	bgt.s	+
;	dma68kToVDP $FFFFE380,$0,$50,VSRAM
+
	bsr.w	ReadJoypads
	tst.b	(Teleport_timer).w
	beq.s	loc_6F8
	lea	(VDP_control_port).l,a5
	tst.w	(Game_paused).w
	bne.w	loc_748
	subq.b	#1,(Teleport_timer).w
	bne.s	+
	move.b	#0,(Teleport_flag).w
+
	cmpi.b	#$10,(Teleport_timer).w
	blo.s	loc_6F8
	lea	(VDP_data_port).l,a6
	move.l	#vdpComm($0000,CRAM,WRITE),(VDP_control_port).l
	move.w	#$EEE,d0

	move.w	#$1F,d1
-	move.w	d0,(a6)
	dbf	d1,-

	move.l	#vdpComm($0042,CRAM,WRITE),(VDP_control_port).l

	move.w	#$1F,d1
-	move.w	d0,(a6)
	dbf	d1,-

	bra.s	loc_748
; ---------------------------------------------------------------------------

loc_6F8:
	tst.b	(Water_fullscreen_flag).w
	bne.s	loc_724
	dma68kToVDP Normal_palette,$0000,$80,CRAM
	bra.s	loc_748
; ---------------------------------------------------------------------------

loc_724:

	dma68kToVDP Underwater_palette,$0000,$80,CRAM

loc_748:
	move.w	(Hint_counter_reserve).w,(a5)
	move.w	#$8230,(VDP_control_port).l	; Set scroll A PNT base to $C000

	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM
	dma68kToVDP Sprite_Table,$F800,$280,VRAM

	bsr.w	ProcessDMAQueue
	bsr.w	sndDriverInput

	startZ80

	movem.l	(Camera_RAM).w,d0-d7
	movem.l	d0-d7,(Camera_RAM_copy).w
	movem.l	(Camera_X_pos_P2).w,d0-d7
	movem.l	d0-d7,(Camera_P2_copy).w
	movem.l	(Scroll_flags).w,d0-d3
	movem.l	d0-d3,(Scroll_flags_copy).w
	move.l	($FFFFF61E).w,($FFFFEEEC).w
	cmpi.b	#$5C,(Hint_counter_reserve+1).w
	bra.s	DemoTime	; water crash
	move.b	#1,($FFFFF64F).w
	rts

; ---------------------------------------------------------------------------
; Subroutine to run a demo for an amount of time
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_7E6: Demo_Time:
DemoTime:
	bsr.w	JmpTo_LoadTilesAsYouMove
	jsr	(HudUpdate).l
	bsr.w	ProcessDPLC2
	tst.w	(Demo_Time_left).w	; is there time left on the demo?
	beq.w	DemoTime_End		; if not, branch
	subq.w	#1,(Demo_Time_left).w	; subtract 1 from time left

; return_800: Demo_TimeEnd:
DemoTime_End:
	rts
; End of function DemoTime

; ---------------------------------------------------------------------------

Vint10_specialStage:
	stopZ80

	bsr.w	ReadJoypads
	jsr	(sndDriverInput).l
	tst.b	($FFFFDB11).w
	beq.s	loc_84A

	dma68kToVDP Horiz_Scroll_Buf_2,$FC00,$380,VRAM
	bra.s	loc_86E
; ---------------------------------------------------------------------------
loc_84A:
	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM

loc_86E:
	startZ80
	rts
; ========================================================================>>>

VintSubA:
	stopZ80

	bsr.w	ReadJoypads
	bsr.w	sub_AE8

	dma68kToVDP Normal_palette,$0000,$80,CRAM
	dma68kToVDP Sprite_Table,$F800,$280,VRAM

	tst.b	($FFFFDB0F).w
	beq.s	loc_906

	dma68kToVDP Horiz_Scroll_Buf_2,$FC00,$380,VRAM
	bra.s	loc_92A
; ---------------------------------------------------------------------------

loc_906:
	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM

loc_92A:
	tst.b	($FFFFDB0E).w
	beq.s	++
	moveq	#0,d0
	move.b	($FFFFDB0D).w,d0
	cmpi.b	#4,d0
	bge.s	++
	add.b	d0,d0
	tst.b	($FFFFDB0C).w	; [($FFFFDB0D) * 2] = subroutine
	beq.s	+		; else
	addi.w	#8,d0		; ([($FFFFDB0D) * 2] + 8) = subroutine
+
	move.w	++(pc,d0.w),d0
	jsr	++(pc,d0.w)
+
	bsr.w	sub_B02
	addi.b	#1,($FFFFDB0D).w
	move.b	($FFFFDB0D).w,d0
	cmp.b	d1,d0
	blt.s	loc_994
	move.b	#0,($FFFFDB0D).w
	lea	(VDP_control_port).l,a6
	tst.b	($FFFFDB0C).w
	beq.s	loc_98A
	move.w	#$8230,(a6)
	bra.s	loc_98E
; ===========================================================================
/	dc.w loc_A50 - (-)	; 0
	dc.w loc_A76 - (-)	; 1
	dc.w loc_A9C - (-)	; 2
	dc.w loc_AC2 - (-)	; 3
	dc.w loc_9B8 - (-)	; 4
	dc.w loc_9DE - (-)	; 5
	dc.w loc_A04 - (-)	; 6
	dc.w loc_A2A - (-)	; 7
; ===========================================================================

loc_98A:
	move.w	#$8220,(a6)		; PNT A base: $8000

loc_98E:
	eori.b	#1,($FFFFDB0C).w

loc_994:
	bsr.w	ProcessDMAQueue
	jsr	(sndDriverInput).l

	startZ80

	bsr.w	ProcessDPLC2
	tst.w	(Demo_Time_left).w
	beq.w	+	; rts
	subq.w	#1,(Demo_Time_left).w
+	rts
; ---------------------------------------------------------------------------
; (!)
; these transfers have something to do with drawing the special stage track (hscroll?)
loc_9B8:
	dma68kToVDP PNT_Buffer,$C000,$700,VRAM
	rts
; ---------------------------------------------------------------------------
loc_9DE:
	dma68kToVDP PNT_Buffer,$C700,$700,VRAM
	rts
; ---------------------------------------------------------------------------
loc_A04:
	dma68kToVDP PNT_Buffer,$CE00,$700,VRAM
	rts
; ---------------------------------------------------------------------------
loc_A2A:
	dma68kToVDP PNT_Buffer,$D500,$700,VRAM
	rts
; ---------------------------------------------------------------------------
loc_A50:
	dma68kToVDP PNT_Buffer,$8000,$700,VRAM
	rts
; ---------------------------------------------------------------------------
loc_A76:
	dma68kToVDP PNT_Buffer,$8700,$700,VRAM
	rts
; ---------------------------------------------------------------------------
loc_A9C:
	dma68kToVDP PNT_Buffer,$8E00,$700,VRAM
	rts
; ---------------------------------------------------------------------------
loc_AC2:
	dma68kToVDP PNT_Buffer,$9500,$700,VRAM
	rts
; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_AE8:
	move.w	(VDP_control_port).l,d0
	move.l	#vdpComm($0000,VSRAM,WRITE),(VDP_control_port).l
	move.l	(Vscroll_Factor).w,(VDP_data_port).l
	rts
; End of function sub_AE8


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_B02:
	move.w	($FFFFDB16).w,d0
	cmp.w	($FFFFDB12).w,d0
	beq.s	+
	move.l	($FFFFDB12).w,($FFFFDB16).w
	move.b	#0,($FFFFDB1F).w
+	subi.b	#1,($FFFFDB1F).w
	bgt.s	+
	lea	(byte_B46).l,a0
	move.w	($FFFFDB16).w,d0
	lsr.w	#1,d0
	move.b	(a0,d0.w),d1
	move.b	d1,($FFFFDB21).w
	move.b	d1,($FFFFDB1F).w
	subq.b	#1,($FFFFDB21).w
	rts
; ---------------------------------------------------------------------------
+
	move.b	($FFFFDB21).w,d1
	addq.b	#1,d1
	rts
; End of function sub_B02

; ===========================================================================
byte_B46:
	dc.b $3C
	dc.b $1E	; 1
	dc.b  $F	; 2
	dc.b  $A	; 3
	dc.b   8	; 4
	dc.b   6	; 5
	dc.b   5	; 6
	dc.b   0	; 7
; ===========================================================================

VintSub1A:
	stopZ80
	jsr	(ProcessDMAQueue).l
	startZ80
	rts
; ===========================================================================

VintSubC:
	stopZ80

	bsr.w	ReadJoypads
	tst.b	(Water_fullscreen_flag).w
	bne.s	loc_BB2

	dma68kToVDP Normal_palette,$0000,$80,CRAM
	bra.s	loc_BD6
; ---------------------------------------------------------------------------

loc_BB2:
	dma68kToVDP Underwater_palette,$0000,$80,CRAM

loc_BD6:
	move.w	(Hint_counter_reserve).w,(a5)

	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM
	dma68kToVDP Sprite_Table,$F800,$280,VRAM

	bsr.w	ProcessDMAQueue
	jsr	(loc_15584).l
	jsr	(sndDriverInput).l

	startZ80

	movem.l	(Camera_RAM).w,d0-d7
	movem.l	d0-d7,(Camera_RAM_copy).w
	movem.l	(Scroll_flags).w,d0-d1
	movem.l	d0-d1,(Scroll_flags_copy).w
	move.l	($FFFFF61E).w,($FFFFEEEC).w
	bsr.w	ProcessDPLC
	rts
; ===========================================================================

VintSubE:
	bsr.w	sub_E98
	addq.b	#1,($FFFFF628).w
	move.b	#$E,(Vint_routine).w
	rts
; ===========================================================================

VintSub12:
	bsr.w	sub_E98
	move.w	(Hint_counter_reserve).w,(a5)
	bra.w	ProcessDPLC
; ===========================================================================

VintSub18:
	stopZ80

	bsr.w	ReadJoypads

	dma68kToVDP Normal_palette,$0000,$80,CRAM
	dma68kToVDP Sprite_Table,$F800,$280,VRAM
	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM

	bsr.w	ProcessDMAQueue
	bsr.w	sndDriverInput
	movem.l	(Camera_RAM).w,d0-d7
	movem.l	d0-d7,(Camera_RAM_copy).w
	movem.l	(Scroll_flags).w,d0-d3
	movem.l	d0-d3,(Scroll_flags_copy).w
	bsr.w	JmpTo_LoadTilesAsYouMove

	startZ80

	move.w	($FFFFF662).w,d0
	beq.s	+	; rts
	clr.w	($FFFFF662).w
	move.w	++ - 2(pc,d0.w),d0
	jsr	++(pc,d0.w)
+	rts
; ===========================================================================
/	dc.w (+) - (-)	; 1
	dc.w (++) - (-)	; 2
; ===========================================================================
+	dmaFillVRAM 0,$C000,$2000	; VRAM Fill $C000 with $2000 zeros
	rts
; ---------------------------------------------------------------------------
+	dmaFillVRAM 0,$4000,$2000
	dmaFillVRAM 0,$C000,$2000

	lea	(VDP_control_port).l,a6
	move.w	#$8B00,(a6)		; EXT-INT off, V scroll by screen, H scroll by screen
	move.w	#$8402,(a6)		; PNT B base: $8000
	move.w	#$9011,(a6)		; Scroll table size: 64x64
	lea	(Chunk_Table).l,a1
	move.l	#vdpComm($D0AC,VRAM,WRITE),d0	;$50AC0003
	moveq	#$16,d1
	moveq	#$E,d2
	bsr.w	PlaneMapToVRAM
	rts
; ===========================================================================

VintSub16:
	stopZ80

	bsr.w	ReadJoypads

	dma68kToVDP Normal_palette,$0000,$80,CRAM
	dma68kToVDP Sprite_Table,$F800,$280,VRAM
	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM

	bsr.w	ProcessDMAQueue
	bsr.w	sndDriverInput

	startZ80

	bsr.w	ProcessDPLC
	tst.w	(Demo_Time_left).w
	beq.w	+	; rts
	subq.w	#1,(Demo_Time_left).w
+
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_E98:
	stopZ80

	bsr.w	ReadJoypads
	tst.b	(Water_fullscreen_flag).w
	bne.s	loc_EDA

	dma68kToVDP Normal_palette,$0000,$80,CRAM
	bra.s	loc_EFE
; ---------------------------------------------------------------------------

loc_EDA:
	dma68kToVDP Underwater_palette,$0000,$80,CRAM

loc_EFE:
	dma68kToVDP Sprite_Table,$F800,$280,VRAM
	dma68kToVDP Horiz_Scroll_Buf,$FC00,$380,VRAM

	bsr.w	sndDriverInput

	startZ80

	rts
; End of function sub_E98
; ||||||||||||||| E N D   O F   V - I N T |||||||||||||||||||||||||||||||||||

; ===========================================================================
; Start of H-INT code
H_Int:
	tst.w	(Hint_flag).w
	beq.w	+
	tst.w	(Two_player_mode).w
	beq.w	PalToCRAM
	;move.w	#0,(Hint_flag).w
	;move.l	a5,-(sp)
	;move.l	d0,-(sp)

;-	move.w	(VDP_control_port).l,d0	; loop start: Make sure V_BLANK is over
;	andi.w	#4,d0
;	beq.s	-	; loop end

;	move.w	(VDP_Reg1_val).w,d0
;	andi.b	#$BF,d0
;	move.w	d0,(VDP_control_port).l
;	move.w	#$8228,(VDP_control_port).l
;	move.l	#vdpComm($0000,VSRAM,WRITE),(VDP_control_port).l
;	move.l	($FFFFEEEC).w,(VDP_data_port).l

;	stopZ80
;	dma68kToVDP Sprite_Table_2,$F800,$280,VRAM
;	startZ80

;-	move.w	(VDP_control_port).l,d0
;	andi.w	#4,d0
;	beq.s	-

;	move.w	(VDP_Reg1_val).w,d0
;	ori.b	#$40,d0
;	move.w	d0,(VDP_control_port).l
;	move.l	(sp)+,d0
;	movea.l	(sp)+,a5
+
	rte


; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; game code

; ---------------------------------------------------------------------------
; loc_1000:
PalToCRAM:
	move	#$2700,sr
	move.w	#0,(Hint_flag).w
	movem.l	a0-a1,-(sp)
	lea	(VDP_data_port).l,a1
	lea	(Underwater_palette).w,a0 	; load palette from RAM
	tst.b	(Water_fullscreen_flag).w
	beq.s	+
	lea	(Normal_palette).w,a0
+
	move.l	#vdpComm($0000,CRAM,WRITE),4(a1)	; set VDP to write to CRAM address $00
    rept 32
	move.l	(a0)+,(a1)	; move palette to CRAM (all 64 colors at once)
    endm
	move.w	#$8ADF,4(a1)	; Write %1101 %1111 to register 10 (interrupt every 224th line)
	movem.l	(sp)+,a0-a1
	tst.b	($FFFFF64F).w
	bne.s	loc_1072
	rte
; ===========================================================================

loc_1072:
	clr.b	($FFFFF64F).w
	movem.l	d0-a6,-(sp)
	bsr.w	DemoTime
	movem.l	(sp)+,d0-a6
	rte

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
zComRange = $1B80
sndDriverInput:
	lea	(Music_to_play&$00FFFFFF).l,a0
	lea	(Z80_RAM+zComRange).l,a1 ; $A01B80
	cmpi.b	#$80,8(a1)	; If this (zReadyFlag) isn't $80, the driver is processing a previous sound request.
	bne.s	loc_10C4	; So we'll wait until at least the next frame before putting anything in there.
	_move.b	0(a0),d0
	beq.s	loc_10A4
	_clr.b	0(a0)
	bra.s	loc_10AE
; ---------------------------------------------------------------------------

loc_10A4:
	move.b	4(a0),d0	; If there was something in Music_to_play_2, check what that was. Else, just go to the loop.
	beq.s	loc_10C4
	clr.b	4(a0)

loc_10AE:		; Check that the sound is not FE or FF
	move.b	d0,d1	; If it is, we need to put it in $A01B83 as $7F or $80 respectively
	subi.b	#$FE,d1
	bcs.s	loc_10C0
	addi.b	#$7F,d1
	move.b	d1,3(a1)
	bra.s	loc_10C4
; ---------------------------------------------------------------------------

loc_10C0:
	move.b	d0,8(a1)

loc_10C4:
	moveq	#4-1,d1
				; FFE4 (Music_to_play_2) goes to 1B8C (zMusicToPlay),
-	move.b	1(a0,d1.w),d0	; FFE3 goes to 1B8B, (unknown)
	beq.s	+		; FFE2 (SFX_to_play_2) goes to 1B8A (zSFXToPlay2),
	tst.b	9(a1,d1.w)	; FFE1 (SFX_to_play) goes to 1B89 (zSFXToPlay).
	bne.s	+
	clr.b	1(a0,d1.w)
	move.b	d0,9(a1,d1.w)
+
	dbf	d1,-
	rts
; End of function sndDriverInput


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_10E0:
JmpTo_LoadTilesAsYouMove
	jmp	(LoadTilesAsYouMove).l
; End of function JmpTo_LoadTilesAsYouMove


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


JmpTo_loc_3A68A
	jmp	(loc_3A68A).l
; End of function JmpTo_loc_3A68A
loc_3A68A:
	move.w	($FFFFF662).w,d0
	beq.w	return_37A48D
	clr.w	($FFFFF662).w
	move.w	off_3A69E-2(pc,d0.w),d0
	jmp	off_3A69E(pc,d0.w)
	
return_37A48D:
	rts
; ===========================================================================
off_3A69E:
		dc.w loc_3A6A2	; 0
		dc.w loc_3A6D4	; 2
; ===========================================================================

loc_3A6A2:
	dma68kToVDP $FFFF0B00,$1100,$2C00,VRAM

	lea	byte_3A74C(pc),a1
	move.l	#$49500003,d0
	bra.w	loc_3A710
; ===========================================================================

loc_3A6D4:
	dmaFillVRAM 0,$C000,$2000 ; clear Plane A pattern name table and common graphics

	lea	byte_3A75C(pc),a1
	move.l	#$49A00003,d0
	bra.w	loc_3A710
loc_3A710:
	lea	(VDP_data_port).l,a6
	move.l	#$1000000,d6
	moveq	#7,d1
	moveq	#9,d2

loc_3A720:
	move.l	d0,4(a6)
	move.w	d1,d3
	movea.l	a1,a2

loc_3A728:
	move.w	(a2)+,d4
	bclr	#$A,d4
	beq.s	loc_3A734
	bsr.w	loc_3A742

loc_3A734:
	move.w	d4,(a6)
	dbf	d3,loc_3A728
	add.l	d6,d0
	dbf	d2,loc_3A720
	rts
; ===========================================================================

loc_3A742:
	moveq	#$28,d5

loc_3A744:
	move.w	d4,(a6)
	dbf	d5,loc_3A744
	rts
byte_3A74C:
	dc.b $A0,$80
	dc.b $A0,$81	; 2
	dc.b $A0,$82	; 4
	dc.b $A0,$83	; 6
	dc.b $A0,$84	; 8
	dc.b $A0,$85	; 10
	dc.b $A0,$86	; 12
	dc.b $A4,$87	; 14
byte_3A75C:
	dc.b $A4,$87
	dc.b $A0,$86	; 2
	dc.b $A0,$85	; 4
	dc.b $A0,$84	; 6
	dc.b $A0,$83	; 8
	dc.b $A0,$82	; 10
	dc.b $A0,$81	; 12
	dc.b $A0,$80	; 14
byte_3A76C:
	dc.b $12
	dc.b   4	; 1
	dc.b   4	; 2
	dc.b   2	; 3
	dc.b   2	; 4
	dc.b   2	; 5
	dc.b   2	; 6
	dc.b   0	; 7
	dc.b   0	; 8
	dc.b   0	; 9
	dc.b   0	; 10
	dc.b   0	; 11
	dc.b   0	; 12
	dc.b   0	; 13
	dc.b   0	; 14
	dc.b   4	; 15
	dc.b   4	; 16
	dc.b   6	; 17
	dc.b  $A	; 18
	dc.b   8	; 19
	dc.b   6	; 20
	dc.b   4	; 21
	dc.b   4	; 22
	dc.b   4	; 23
	dc.b   4	; 24
	dc.b   6	; 25
	dc.b   6	; 26
	dc.b   8	; 27
	dc.b   8	; 28
	dc.b  $A	; 29
	dc.b  $A	; 30
	dc.b  $C	; 31
	dc.b  $E	; 32
	dc.b $10	; 33
	dc.b $16	; 34
	dc.b   0	; 35
; ---------------------------------------------------------------------------
; Subroutine to initialize joypads
; ---------------------------------------------------------------------------
; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_10EC:
JoypadInit:
	stopZ80
	moveq	#$40,d0
	move.b	d0,(Z80_Port_1_Control+1).l	; init port 1 (joypad 1)
	move.b	d0,(Z80_Port_2_Control+1).l	; init port 2 (joypad 2)
	move.b	d0,(Z80_Expansion_Control+1).l	; init port 3 (extra)
	startZ80
	rts
; End of function JoypadInit

; ---------------------------------------------------------------------------
; Subroutine to read joypad input, and send it to the RAM
; ---------------------------------------------------------------------------
; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_111C:
ReadJoypads:
	lea	(Ctrl_1).w,a0	; address where joypad states are written
	lea	(Z80_Port_1_Data+1).l,a1	; first joypad port
	bsr.s	Joypad_Read		; do the first joypad
	addq.w	#2,a1			; do the second joypad
; End of function ReadJoypads


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_112A:
Joypad_Read:
	move.b	#0,(a1)
	nop
	nop
	move.b	(a1),d0
	lsl.b	#2,d0
	andi.b	#$C0,d0
	move.b	#$40,(a1)
	nop
	nop
	move.b	(a1),d1
	andi.b	#$3F,d1
	or.b	d1,d0
	not.b	d0
	move.b	(a0),d1
	eor.b	d0,d1
	move.b	d0,(a0)+
	and.b	d0,d1
	move.b	d1,(a0)+
	rts
; End of function Joypad_Read


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_1158:
VDPSetupGame:
	lea	(VDP_control_port).l,a0
	lea	(VDP_data_port).l,a1
	lea	(VDPSetupArray).l,a2
	moveq	#(VDPSetupArray_End-VDPSetupArray)/2-1,d7
; loc_116C:
VDP_Loop:
	move.w	(a2)+,(a0)
	dbf	d7,VDP_Loop	; set the VDP registers

	move.w	(VDPSetupArray+2).l,d0
	move.w	d0,(VDP_Reg1_val).w
	move.w	#$8ADF,(Hint_counter_reserve).w	; H-INT every 224th scanline
	moveq	#0,d0

	move.l	#vdpComm($0000,VSRAM,WRITE),(VDP_control_port).l
	move.w	d0,(a1)
	move.w	d0,(a1)

	move.l	#vdpComm($0000,CRAM,WRITE),(VDP_control_port).l

	move.w	#$3F,d7
; loc_11A0:
VDP_ClrCRAM:
	move.w	d0,(a1)
	dbf	d7,VDP_ClrCRAM

	clr.l	(Vscroll_Factor).w
	clr.l	($FFFFF61A).w
	move.l	d1,-(sp)

	dmaFillVRAM 0,$0000,$10000	; fill entire VRAM with 0

	move.l	(sp)+,d1
	rts
; End of function VDPSetupGame

; ===========================================================================
; word_11E2:
VDPSetupArray:
	dc.w $8004, $8134, $8230, $8328	; 3
	dc.w $8407, $857C, $8600, $8700	; 7
	dc.w $8800, $8900, $8A00, $8B00	; 11
	dc.w $8C81, $8D3F, $8E00, $8F02	; 15
	dc.w $9001, $9100, $9200	; 18
VDPSetupArray_End:

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_1208:
ClearScreen:
	stopZ80

	dmaFillVRAM 0,$0000,$40		; Fill first $40 bytes of VRAM with 0
	dmaFillVRAM 0,$C000,$1000	; Clear Plane A pattern name table
	dmaFillVRAM 0,$E000,$1000	; Clear Plane B pattern name table

	tst.w	(Two_player_mode).w
	beq.s	+

	dmaFillVRAM 0,$A000,$1000
+
	clr.l	(Vscroll_Factor).w
	clr.l	($FFFFF61A).w

	clearRAM Sprite_Table,$284
	clearRAM Horiz_Scroll_Buf,$404

	startZ80
	rts
; End of function ClearScreen

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; JumpTo load the sound driver
; sub_130A:
JmpTo_SoundDriverLoad
;	nop
;	jmp	(SoundDriverLoadS1).l
; End of function JmpTo_SoundDriverLoad

; ===========================================================================
; unused mostly-leftover subroutine to load the sound driver
; SoundDriverLoadS1:
	move.w	#$100,(Z80_Bus_Request).l ; stop the Z80
	move.w	#$100,(Z80_Reset).l ; reset the Z80
	lea	(Kos_Z80).l,a0
	lea	(Z80_RAM).l,a1
	bsr.w	KosDec
	move.b	#$F3,(a1)+
	move.b	#$F3,(a1)+
	move.b	#$C3,(a1)+
	move.b	#0,(a1)+
	move.b	#0,(a1)+
	move.w	#0,(Z80_Reset).l
	nop
	nop
	nop
	nop
	move.w	#$100,(Z80_Reset).l ; reset the Z80
	move.w	#0,(Z80_Bus_Request).l ; start the Z80
	rts
; End of function JmpTo_SoundDriverLoad

; ===========================================================================
; unused mostly-leftover subroutine to load the sound driver
SoundDriverLoadS1:
	move.w	#$100,(Z80_Bus_Request).l ; stop the Z80
	move.w	#$100,(Z80_Reset).l ; reset the Z80
	lea	(Z80_RAM).l,a1
	move.b	#$F3,(a1)+
	move.b	#$F3,(a1)+
	move.b	#$C3,(a1)+
	move.b	#0,(a1)+
	move.b	#0,(a1)+
	move.w	#0,(Z80_Reset).l
	nop
	nop
	nop
	nop
	move.w	#$100,(Z80_Reset).l ; reset the Z80
	move.w	#0,(Z80_Bus_Request).l ; start the Z80
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; If Music_to_play is clear, move d0 into Music_to_play,
; else move d0 into Music_to_play_2.
; sub_135E:
PlayMusic:
;	tst.b	($FFFFFFE0).w
;	bne.s	+
;	move.b	d0,($FFFFFFE0).w
	move.b	d0,($FFFFF00A).w
	rts
+
	move.b	d0,($FFFFF00A).w
	rts

; End of function PlayMusic


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_1370
PlaySound:
	move.b	d0,($FFFFF00B).w
	rts
; End of function PlaySound


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; play a sound in alternating speakers (as in the ring collection sound)
; sub_1376:
PlaySoundStereo:
	bra.s	PlayMusic	; skip over routine (For S1 driver)
	move.b	d0,(SFX_to_play_2).w
	rts

; End of function PlaySoundStereo


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; play a sound if the source is onscreen
; sub_137C:
PlaySoundLocal:
	tst.b	render_flags(a0)
	bpl.s	+
	move.b	d0,($FFFFF00B).w
+
	rts
; End of function PlaySoundLocal

; ---------------------------------------------------------------------------
; Subroutine to pause the game
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_1388:
PauseGame:
	nop
	tst.b	(Life_count).w	; do you have any lives left?
	beq.w	Unpause		; if not, branch
	tst.w	(Game_paused).w	; is game already paused?
	bne.s	+		; if yes, branch
	move.b	(Ctrl_1_Press).w,d0 ; is Start button pressed?
	or.b	(Ctrl_2_Press).w,d0 ; (either player)
	andi.b	#button_start_mask,d0
	beq.s	Pause_DoNothing	; if not, branch
+
	move.w	#1,(Game_paused).w	; freeze time
	move.b	#1,($FFFFF003).w	; pause music
; loc_13B2:
Pause_Loop:
	move.b	#$10,(Vint_routine).w
	bsr.w	WaitForVint
	tst.b	(Slow_motion_flag).w	; is slow-motion cheat on?
	beq.s	Pause_ChkStart		; if not, branch
	btst	#button_A,(Ctrl_1_Press).w	; is button A pressed?
	beq.s	Pause_ChkBC		; if not, branch
	move.b	#GameModeID_TitleScreen,(Game_Mode).w	; => TitleScreen
	nop
	bra.s	Pause_Resume
; ===========================================================================
; loc_13D4:
Pause_ChkBC:
	btst	#button_B,(Ctrl_1_Held).w ; is button B pressed?
	bne.s	Pause_SlowMo		; if yes, branch
	btst	#button_C,(Ctrl_1_Press).w ; is button C pressed?
	bne.s	Pause_SlowMo		; if yes, branch
; loc_13E4:
Pause_ChkStart:
	move.b	(Ctrl_1_Press).w,d0	; is Start button pressed?
	or.b	(Ctrl_2_Press).w,d0	; (either player)
	andi.b	#button_start_mask,d0
	beq.s	Pause_Loop	; if not, branch
; loc_13F2:
Pause_Resume:
	move.b	#$80,($FFFFF003).w
; loc_13F8:
Unpause:
	move.w	#0,(Game_paused).w
; return_13FE:
Pause_DoNothing:
	rts
; ===========================================================================
; loc_1400:
Pause_SlowMo:
	move.w	#1,(Game_paused).w
	move.b	#1,($FFFFF003).w
	rts
; End of function PauseGame

; ---------------------------------------------------------------------------
; Subroutine to transfer a plane map to VRAM
; ---------------------------------------------------------------------------

; control register:
;    CD1 CD0 A13 A12 A11 A10 A09 A08     (D31-D24)
;    A07 A06 A05 A04 A03 A02 A01 A00     (D23-D16)
;     ?   ?   ?   ?   ?   ?   ?   ?      (D15-D8)
;    CD5 CD4 CD3 CD2  ?   ?  A15 A14     (D7-D0)
;
;	A00-A15 - address
;	CD0-CD3 - code
;	CD4 - 1 if VRAM copy DMA mode. 0 otherwise.
;	CD5 - DMA operation
;
;	Bits CD3-CD0:
;	0000 - VRAM read
;	0001 - VRAM write
;	0011 - CRAM write
;	0100 - VSRAM read
;	0101 - VSRAM write
;	1000 - CRAM read
;
; d0 = control register
; d1 = width
; d2 = heigth
; a1 = source address

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_140E: ShowVDPGraphics:
PlaneMapToVRAM:
	lea	(VDP_data_port).l,a6
	move.l	#$800000,d4
-	move.l	d0,4(a6)	; move d0 to VDP_control_port
	move.w	d1,d3
-	move.w	(a1)+,(a6)	; from source address to destination in VDP
	dbf	d3,-		; next tile
	add.l	d4,d0		; increase destination address by $80 (1 line)
	dbf	d2,--		; next line
	rts
; End of function PlaneMapToVRAM

; ---------------------------------------------------------------------------
; Alternate subroutine to transfer a plane map to VRAM
; (used for Special Stage background)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_142E: ShowVDPGraphics2:
PlaneMapToVRAM2:
	lea	(VDP_data_port).l,a6
	move.l	#$1000000,d4
-	move.l	d0,4(a6)
	move.w	d1,d3
-	move.w	(a1)+,(a6)
	dbf	d3,-
	add.l	d4,d0
	dbf	d2,--
	rts
; End of function PlaneMapToVRAM2


; ---------------------------------------------------------------------------
; Subroutine for queueing VDP commands (seems to only queue transfers to VRAM),
; to be issued the next time ProcessDMAQueue is called.
; Can be called a maximum of 18 times before the buffer needs to be cleared
; by issuing the commands (this subroutine DOES check for overflow)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_144E: DMA_68KtoVRAM: QueueCopyToVRAM: QueueVDPCommand: Add_To_DMA_Queue:
QueueDMATransfer:
	movea.l	(VDP_Command_Buffer_Slot).w,a1
	cmpa.w	#VDP_Command_Buffer_Slot,a1
	beq.s	QueueDMATransfer_Done ; return if there's no more room in the buffer

	; piece together some VDP commands and store them for later...
	move.w	#$9300,d0 ; command to specify DMA transfer length & $00FF
	move.b	d3,d0
	move.w	d0,(a1)+ ; store command

	move.w	#$9400,d0 ; command to specify DMA transfer length & $FF00
	lsr.w	#8,d3
	move.b	d3,d0
	move.w	d0,(a1)+ ; store command

	move.w	#$9500,d0 ; command to specify source address & $0001FE
	lsr.l	#1,d1
	move.b	d1,d0
	move.w	d0,(a1)+ ; store command

	move.w	#$9600,d0 ; command to specify source address & $01FE00
	lsr.l	#8,d1
	move.b	d1,d0
	move.w	d0,(a1)+ ; store command

	move.w	#$9700,d0 ; command to specify source address & $FE0000
	lsr.l	#8,d1
	move.b	d1,d0
	move.w	d0,(a1)+ ; store command

	andi.l	#$FFFF,d2 ; command to specify destination address and begin DMA
	lsl.l	#2,d2
	lsr.w	#2,d2
	swap	d2
	ori.l	#vdpComm($0000,VRAM,DMA),d2 ; set bits to specify VRAM transfer
	move.l	d2,(a1)+ ; store command

	move.l	a1,(VDP_Command_Buffer_Slot).w ; set the next free slot address
	cmpa.w	#VDP_Command_Buffer_Slot,a1
	beq.s	QueueDMATransfer_Done ; return if there's no more room in the buffer
	move.w	#0,(a1) ; put a stop token at the end of the used part of the buffer
; return_14AA:
QueueDMATransfer_Done:
	rts
; End of function QueueDMATransfer


; ---------------------------------------------------------------------------
; Subroutine for issuing all VDP commands that were queued
; (by earlier calls to QueueDMATransfer)
; Resets the queue when it's done
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_14AC: CopyToVRAM: IssueVDPCommands: Process_DMA: Process_DMA_Queue:
ProcessDMAQueue:
	lea	(VDP_control_port).l,a5
	lea	(VDP_Command_Buffer).w,a1
; loc_14B6:
ProcessDMAQueue_Loop:
	move.w	(a1)+,d0
	beq.s	ProcessDMAQueue_Done ; branch if we reached a stop token
	; issue a set of VDP commands...
	move.w	d0,(a5)		; transfer length
	move.w	(a1)+,(a5)	; transfer length
	move.w	(a1)+,(a5)	; source address
	move.w	(a1)+,(a5)	; source address
	move.w	(a1)+,(a5)	; source address
	move.w	(a1)+,(a5)	; destination
	move.w	(a1)+,(a5)	; destination
	cmpa.w	#VDP_Command_Buffer_Slot,a1
	bne.s	ProcessDMAQueue_Loop ; loop if we haven't reached the end of the buffer
; loc_14CE:
ProcessDMAQueue_Done:
	move.w	#0,(VDP_Command_Buffer).w
	move.l	#VDP_Command_Buffer,(VDP_Command_Buffer_Slot).w
	rts
; End of function ProcessDMAQueue



; ---------------------------------------------------------------------------
; START OF NEMESIS DECOMPRESSOR

; For format explanation see http://info.sonicretro.org/Nemesis_compression
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; Nemesis decompression to VRAM
; sub_14DE: NemDecA:
NemDec:
	movem.l	d0-a1/a3-a5,-(sp)
	lea	(NemDec_WriteAndStay).l,a3 ; write all data to the same location
	lea	(VDP_data_port).l,a4	   ; specifically, to the VDP data port
	bra.s	NemDecMain

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; Nemesis decompression to RAM
; input: a4 = starting address of destination
; sub_14F0: NemDecB:
NemDecToRAM:
	movem.l	d0-a1/a3-a5,-(sp)
	lea	(NemDec_WriteAndAdvance).l,a3 ; advance to the next location after each write


; sub_14FA:
NemDecMain:
	lea	(Decomp_Buffer).w,a1
	move.w	(a0)+,d2
	lsl.w	#1,d2
	bcc.s	+
	adda.w	#NemDec_WriteAndStay_XOR-NemDec_WriteAndStay,a3
+	lsl.w	#2,d2
	movea.w	d2,a5
	moveq	#8,d3
	moveq	#0,d2
	moveq	#0,d4
	bsr.w	NemDecPrepare
	move.b	(a0)+,d5
	asl.w	#8,d5
	move.b	(a0)+,d5
	move.w	#$10,d6
	bsr.s	NemDecRun
	movem.l	(sp)+,d0-a1/a3-a5
	rts
; End of function NemDec


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; part of the Nemesis decompressor
; sub_1528:
NemDecRun:
	move.w	d6,d7
	subq.w	#8,d7
	move.w	d5,d1
	lsr.w	d7,d1
	cmpi.b	#-4,d1
	bhs.s	loc_1574
	andi.w	#$FF,d1
	add.w	d1,d1
	move.b	(a1,d1.w),d0
	ext.w	d0
	sub.w	d0,d6
	cmpi.w	#9,d6
	bhs.s	+
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5
+	move.b	1(a1,d1.w),d1
	move.w	d1,d0
	andi.w	#$F,d1
	andi.w	#$F0,d0

loc_155E:
	lsr.w	#4,d0

loc_1560:
	lsl.l	#4,d4
	or.b	d1,d4
	subq.w	#1,d3
	bne.s	NemDec_WriteIter_Part2
	jmp	(a3) ; dynamic jump! to NemDec_WriteAndStay, NemDec_WriteAndAdvance, NemDec_WriteAndStay_XOR, or NemDec_WriteAndAdvance_XOR
; ===========================================================================
; loc_156A:
NemDec_WriteIter:
	moveq	#0,d4
	moveq	#8,d3
; loc_156E:
NemDec_WriteIter_Part2:
	dbf	d0,loc_1560
	bra.s	NemDecRun
; ===========================================================================
loc_1574:
	subq.w	#6,d6
	cmpi.w	#9,d6
	bhs.s	+
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5
+
	subq.w	#7,d6
	move.w	d5,d1
	lsr.w	d6,d1
	move.w	d1,d0
	andi.w	#$F,d1
	andi.w	#$70,d0
	cmpi.w	#9,d6
	bhs.s	loc_155E
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5
	bra.s	loc_155E
; End of function NemDecRun

; ===========================================================================
; loc_15A0:
NemDec_WriteAndStay:
	move.l	d4,(a4)
	subq.w	#1,a5
	move.w	a5,d4
	bne.s	NemDec_WriteIter
	rts
; ---------------------------------------------------------------------------
; loc_15AA:
NemDec_WriteAndStay_XOR:
	eor.l	d4,d2
	move.l	d2,(a4)
	subq.w	#1,a5
	move.w	a5,d4
	bne.s	NemDec_WriteIter
	rts
; ===========================================================================
; loc_15B6:
NemDec_WriteAndAdvance:
	move.l	d4,(a4)+
	subq.w	#1,a5
	move.w	a5,d4
	bne.s	NemDec_WriteIter
	rts

    if *-NemDec_WriteAndAdvance > NemDec_WriteAndStay_XOR-NemDec_WriteAndStay
	fatal "the code in NemDec_WriteAndAdvance must not be larger than the code in NemDec_WriteAndStay"
    endif
    org NemDec_WriteAndAdvance+NemDec_WriteAndStay_XOR-NemDec_WriteAndStay

; ---------------------------------------------------------------------------
; loc_15C0:
NemDec_WriteAndAdvance_XOR:
	eor.l	d4,d2
	move.l	d2,(a4)+
	subq.w	#1,a5
	move.w	a5,d4
	bne.s	NemDec_WriteIter
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; Part of the Nemesis decompressor

; sub_15CC:
NemDecPrepare:
	move.b	(a0)+,d0

-	cmpi.b	#$FF,d0
	bne.s	+
	rts
; ---------------------------------------------------------------------------
+	move.w	d0,d7

loc_15D8:
	move.b	(a0)+,d0
	cmpi.b	#$80,d0
	bhs.s	-

	move.b	d0,d1
	andi.w	#$F,d7
	andi.w	#$70,d1
	or.w	d1,d7
	andi.w	#$F,d0
	move.b	d0,d1
	lsl.w	#8,d1
	or.w	d1,d7
	moveq	#8,d1
	sub.w	d0,d1
	bne.s	loc_1606
	move.b	(a0)+,d0
	add.w	d0,d0
	move.w	d7,(a1,d0.w)
	bra.s	loc_15D8
; ---------------------------------------------------------------------------
loc_1606:
	move.b	(a0)+,d0
	lsl.w	d1,d0
	add.w	d0,d0
	moveq	#1,d5
	lsl.w	d1,d5
	subq.w	#1,d5

-	move.w	d7,(a1,d0.w)
	addq.w	#2,d0
	dbf	d5,-

	bra.s	loc_15D8
; End of function NemDecPrepare

; ---------------------------------------------------------------------------
; END OF NEMESIS DECOMPRESSOR
; ---------------------------------------------------------------------------



; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; Subroutine to load pattern load cues (aka to queue pattern load requests)
; ---------------------------------------------------------------------------

; ARGUMENTS
; d0 = index of PLC list (see ArtLoadCues)

; NOTICE: This subroutine does not check for buffer overruns. The programmer
;	  (or hacker) is responsible for making sure that no more than
;	  21 load requests are copied into the buffer.
;    _________DO NOT PUT MORE THAN 21 LOAD REQUESTS IN A LIST!__________

; sub_161E: PLCLoad:
LoadPLC:
	movem.l	a1-a2,-(sp)
	lea	(ArtLoadCues).l,a1
	add.w	d0,d0
	move.w	(a1,d0.w),d0
	lea	(a1,d0.w),a1
	lea	(Plc_Buffer).w,a2

-	tst.l	(a2)
	beq.s	+ ; if it's zero, exit this loop
	addq.w	#6,a2
	bra.s	-
+
	move.w	(a1)+,d0
	bmi.s	+ ; if it's negative, skip the next loop

-	move.l	(a1)+,(a2)+
	move.w	(a1)+,(a2)+
	dbf	d0,-
+
	movem.l	(sp)+,a1-a2 ; a1=object
	rts
; End of function LoadPLC


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; Queue pattern load requests, but clear the PLQ first

; ARGUMENTS
; d0 = index of PLC list (see ArtLoadCues)

; NOTICE: This subroutine does not check for buffer overruns. The programmer
;	  (or hacker) is responsible for making sure that no more than
;	  21 load requests are copied into the buffer.
;	  _________DO NOT PUT MORE THAN 21 LOAD REQUESTS IN A LIST!__________
; sub_1650:
LoadPLC2:
	movem.l	a1-a2,-(sp)
	lea	(ArtLoadCues).l,a1
	add.w	d0,d0
	move.w	(a1,d0.w),d0
	lea	(a1,d0.w),a1
	bsr.s	ClearPLC
	lea	(Plc_Buffer).w,a2
	move.w	(a1)+,d0
	bmi.s	+ ; if it's negative, skip the next loop

-	move.l	(a1)+,(a2)+
	move.w	(a1)+,(a2)+
	dbf	d0,-
+
	movem.l	(sp)+,a1-a2
	rts
; End of function LoadPLC2


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; Clear the pattern load queue ($FFF680 - $FFF700)

ClearPLC:
	lea	(Plc_Buffer).w,a2

	moveq	#bytesToLcnt(Plc_Buffer_End-Plc_Buffer),d0
-	clr.l	(a2)+
	dbf	d0,-

	rts
; End of function ClearPLC

; ---------------------------------------------------------------------------
; Subroutine to use graphics listed in a pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_168A:
RunPLC_RAM:
	tst.l	(Plc_Buffer).w
	beq.s	++	; rts
	tst.w	($FFFFF6F8).w
	bne.s	++	; rts
	movea.l	(Plc_Buffer).w,a0
	lea	NemDec_WriteAndStay(pc),a3
	nop
	lea	(Decomp_Buffer).w,a1
	move.w	(a0)+,d2
	bpl.s	+
	adda.w	#NemDec_WriteAndStay_XOR-NemDec_WriteAndStay,a3
+
	andi.w	#$7FFF,d2
	move.w	d2,($FFFFF6F8).w
	bsr.w	NemDecPrepare
	move.b	(a0)+,d5
	asl.w	#8,d5
	move.b	(a0)+,d5
	moveq	#$10,d6
	moveq	#0,d0
	move.l	a0,(Plc_Buffer).w
	move.l	a3,($FFFFF6E0).w
	move.l	d0,($FFFFF6E4).w
	move.l	d0,($FFFFF6E8).w
	move.l	d0,($FFFFF6EC).w
	move.l	d5,($FFFFF6F0).w
	move.l	d6,($FFFFF6F4).w
+
	rts
; End of function RunPLC_RAM


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; Process one PLC from the queue

; sub_16E0:
ProcessDPLC:
	tst.w	($FFFFF6F8).w
	beq.w	+	; rts
	move.w	#6,($FFFFF6FA).w
	moveq	#0,d0
	move.w	($FFFFF684).w,d0
	addi.w	#$C0,($FFFFF684).w
	bra.s	ProcessDPLC_Main

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; Process one PLC from the queue

; loc_16FC:
ProcessDPLC2:
	tst.w	($FFFFF6F8).w
	beq.s	+	; rts
	move.w	#3,($FFFFF6FA).w
	moveq	#0,d0
	move.w	($FFFFF684).w,d0
	addi.w	#$60,($FFFFF684).w

; loc_1714:
ProcessDPLC_Main:
	lea	(VDP_control_port).l,a4
	lsl.l	#2,d0		; set up target VRAM address
	lsr.w	#2,d0
	ori.w	#$4000,d0
	swap	d0
	move.l	d0,(a4)
	subq.w	#4,a4
	movea.l	(Plc_Buffer).w,a0
	movea.l	($FFFFF6E0).w,a3
	move.l	($FFFFF6E4).w,d0
	move.l	($FFFFF6E8).w,d1
	move.l	($FFFFF6EC).w,d2
	move.l	($FFFFF6F0).w,d5
	move.l	($FFFFF6F4).w,d6
	lea	(Decomp_Buffer).w,a1

-	movea.w	#8,a5
	bsr.w	NemDec_WriteIter
	subq.w	#1,($FFFFF6F8).w
	beq.s	ProcessDPLC_Pop
	subq.w	#1,($FFFFF6FA).w
	bne.s	-

	move.l	a0,(Plc_Buffer).w
	move.l	a3,($FFFFF6E0).w
	move.l	d0,($FFFFF6E4).w
	move.l	d1,($FFFFF6E8).w
	move.l	d2,($FFFFF6EC).w
	move.l	d5,($FFFFF6F0).w
	move.l	d6,($FFFFF6F4).w
+
	rts

; ===========================================================================
; pop one request off the buffer so that the next one can be filled

; loc_177A:
ProcessDPLC_Pop:
	lea	(Plc_Buffer).w,a0

	moveq	#$15,d0
-	move.l	6(a0),(a0)+
	dbf	d0,-
	rts

; End of function ProcessDPLC


; ---------------------------------------------------------------------------
; Subroutine to execute a pattern load cue directly from the ROM
; rather than loading them into the queue first
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

RunPLC_ROM:
	lea	(ArtLoadCues).l,a1
	add.w	d0,d0
	move.w	(a1,d0.w),d0
	lea	(a1,d0.w),a1

	move.w	(a1)+,d1
-	movea.l	(a1)+,a0
	moveq	#0,d0
	move.w	(a1)+,d0
	lsl.l	#2,d0
	lsr.w	#2,d0
	ori.w	#$4000,d0
	swap	d0
	move.l	d0,(VDP_control_port).l
	bsr.w	NemDec
	dbf	d1,-

	rts
; End of function RunPLC_ROM

; ---------------------------------------------------------------------------
; Enigma Decompression Algorithm

; ARGUMENTS:
; d0 = starting art tile (added to each 8x8 before writing to destination)
; a0 = source address
; a1 = destination address

; For format explanation see http://info.sonicretro.org/Enigma_compression
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; EniDec_17BC:
EniDec:
	movem.l	d0-d7/a1-a5,-(sp)
	movea.w	d0,a3		; store starting art tile
	move.b	(a0)+,d0
	ext.w	d0
	movea.w	d0,a5		; store first byte, extended to word
	move.b	(a0)+,d4	; store second byte
	lsl.b	#3,d4		; multiply by 8
	movea.w	(a0)+,a2	; store third and fourth byte
	adda.w	a3,a2		; add starting art tile
	movea.w	(a0)+,a4	; store fifth and sixth byte
	adda.w	a3,a4		; add starting art tile
	move.b	(a0)+,d5	; store seventh byte
	asl.w	#8,d5		; shift up by a byte
	move.b	(a0)+,d5	; store eighth byte in lower register byte
	moveq	#16,d6		; 16 bits = 2 bytes

EniDec_Loop:
	moveq	#7,d0		; process 7 bits at a time
	move.w	d6,d7
	sub.w	d0,d7
	move.w	d5,d1
	lsr.w	d7,d1
	andi.w	#$7F,d1		; keep only lower 7 bits
	move.w	d1,d2
	cmpi.w	#$40,d1		; is bit 6 set?
	bhs.s	+		; if it is, branch
	moveq	#6,d0		; if not, process 6 bits instead of 7
	lsr.w	#1,d2		; bitfield now becomes TTSSSS instead of TTTSSSS
+
	bsr.w	EniDec_ChkGetNextByte
	andi.w	#$F,d2	; keep only lower nybble
	lsr.w	#4,d1	; store upper nybble (max value = 7)
	add.w	d1,d1
	jmp	EniDec_JmpTable(pc,d1.w)
; End of function EniDec

; ===========================================================================

EniDec_Sub0:
	move.w	a2,(a1)+	; write to destination
	addq.w	#1,a2		; increment
	dbf	d2,EniDec_Sub0	; repeat
	bra.s	EniDec_Loop
; ===========================================================================

EniDec_Sub4:
	move.w	a4,(a1)+	; write to destination
	dbf	d2,EniDec_Sub4	; repeat
	bra.s	EniDec_Loop
; ===========================================================================

EniDec_Sub8:
	bsr.w	EniDec_GetInlineCopyVal

-	move.w	d1,(a1)+
	dbf	d2,-

	bra.s	EniDec_Loop
; ===========================================================================

EniDec_SubA:
	bsr.w	EniDec_GetInlineCopyVal

-	move.w	d1,(a1)+
	addq.w	#1,d1
	dbf	d2,-

	bra.s	EniDec_Loop
; ===========================================================================

EniDec_SubC:
	bsr.w	EniDec_GetInlineCopyVal

-	move.w	d1,(a1)+
	subq.w	#1,d1
	dbf	d2,-

	bra.s	EniDec_Loop
; ===========================================================================

EniDec_SubE:
	cmpi.w	#$F,d2
	beq.s	EniDec_End

-	bsr.w	EniDec_GetInlineCopyVal
	move.w	d1,(a1)+
	dbf	d2,-

	bra.s	EniDec_Loop
; ===========================================================================
; Enigma_JmpTable:
EniDec_JmpTable:
	bra.s	EniDec_Sub0
	bra.s	EniDec_Sub0
	bra.s	EniDec_Sub4
	bra.s	EniDec_Sub4
	bra.s	EniDec_Sub8
	bra.s	EniDec_SubA
	bra.s	EniDec_SubC
	bra.s	EniDec_SubE
; ===========================================================================

EniDec_End:
	subq.w	#1,a0
	cmpi.w	#16,d6		; were we going to start on a completely new byte?
	bne.s	+		; if not, branch
	subq.w	#1,a0
+
	move.w	a0,d0
	lsr.w	#1,d0		; are we on an odd byte?
	bcc.s	+		; if not, branch
	addq.w	#1,a0		; ensure we're on an even byte
+
	movem.l	(sp)+,d0-d7/a1-a5
	rts

;  S U B R O U T I N E


EniDec_GetInlineCopyVal:
	move.w	a3,d3		; store starting art tile
	move.b	d4,d1
	add.b	d1,d1
	bcc.s	+		; if d4 was < $80
	subq.w	#1,d6		; get next bit number
	btst	d6,d5		; is the bit set?
	beq.s	+		; if not, branch
	ori.w	#$8000,d3	; set high priority bit
+
	add.b	d1,d1
	bcc.s	+		; if d4 was < $40
	subq.w	#1,d6		; get next bit number
	btst	d6,d5
	beq.s	+
	addi.w	#$4000,d3	; set second palette line bit
+
	add.b	d1,d1
	bcc.s	+		; if d4 was < $20
	subq.w	#1,d6		; get next bit number
	btst	d6,d5
	beq.s	+
	addi.w	#$2000,d3	; set first palette line bit
+
	add.b	d1,d1
	bcc.s	+		; if d4 was < $10
	subq.w	#1,d6		; get next bit number
	btst	d6,d5
	beq.s	+
	ori.w	#$1000,d3	; set Y-flip bit
+
	add.b	d1,d1
	bcc.s	+		; if d4 was < 8
	subq.w	#1,d6
	btst	d6,d5
	beq.s	+
	ori.w	#$800,d3	; set X-flip bit
+
	move.w	d5,d1
	move.w	d6,d7		; get remaining bits
	sub.w	a5,d7		; subtract minimum bit number
	bcc.s	+		; if we're beyond that, branch
	move.w	d7,d6
	addi.w	#16,d6		; 16 bits = 2 bytes
	neg.w	d7		; calculate bit deficit
	lsl.w	d7,d1		; make space for this many bits
	move.b	(a0),d5		; get next byte
	rol.b	d7,d5		; make the upper X bits the lower X bits
	add.w	d7,d7
	and.w	EniDec_AndVals-2(pc,d7.w),d5	; only keep X lower bits
	add.w	d5,d1		; compensate for the bit deficit
-
	move.w	a5,d0
	add.w	d0,d0
	and.w	EniDec_AndVals-2(pc,d0.w),d1	; only keep as many bits as required
	add.w	d3,d1		; add starting art tile
	move.b	(a0)+,d5	; get current byte, move onto next byte
	lsl.w	#8,d5		; shift up by a byte
	move.b	(a0)+,d5	; store next byte in lower register byte
	rts
; ===========================================================================
+
	beq.s	+		; if the exact number of bits are leftover, branch
	lsr.w	d7,d1		; remove unneeded bits
	move.w	a5,d0
	add.w	d0,d0
	and.w	EniDec_AndVals-2(pc,d0.w),d1	; only keep as many bits as required
	add.w	d3,d1		; add starting art tile
	move.w	a5,d0		; store number of bits used up by inline copy
	bra.s	EniDec_ChkGetNextByte	; move onto next byte
; ===========================================================================
+
	moveq	#16,d6	; 16 bits = 2 bytes
	bra.s	-
; End of function EniDec_GetInlineCopyVal

; ===========================================================================
; word_190A:
EniDec_AndVals:
	dc.w	 1
	dc.w	 3
	dc.w	 7
	dc.w	$F
	dc.w   $1F
	dc.w   $3F
	dc.w   $7F
	dc.w   $FF
	dc.w  $1FF
	dc.w  $3FF
	dc.w  $7FF
	dc.w  $FFF
	dc.w $1FFF
	dc.w $3FFF
	dc.w $7FFF
	dc.w $FFFF
; ===========================================================================

EniDec_ChkGetNextByte:
	sub.w	d0,d6
	cmpi.w	#9,d6
	bhs.s	+	; rts
	addq.w	#8,d6	; 8 bits = 1 byte
	asl.w	#8,d5	; shift up by a byte
	move.b	(a0)+,d5	; store next byte in lower register byte
+
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; ---------------------------------------------------------------------------
; KOSINSKI DECOMPRESSION PROCEDURE
; (sometimes called KOZINSKI decompression)
;
; ARGUMENTS:
; a0 = source address
; a1 = destination address
;
; For format explanation see http://info.sonicretro.org/Kosinski_compression
; New faster version by written by vladikcomper, with additional improvements by
; MarkeyJester and Flamewing
; ---------------------------------------------------------------------------
_Kos_UseLUT := 1
_Kos_LoopUnroll := 3
_Kos_ExtremeUnrolling := 1
 
_Kos_RunBitStream macro
        dbra    d2,.skip
        moveq   #7,d2                                   ; Set repeat count to 8.
        move.b  d1,d0                                   ; Use the remaining 8 bits.
        not.w   d3                                              ; Have all 16 bits been used up?
        bne.s   .skip                                   ; Branch if not.
        move.b  (a0)+,d0                                ; Get desc field low-byte.
        move.b  (a0)+,d1                                ; Get desc field hi-byte.
        if _Kos_UseLUT==1
        move.b  (a4,d0.w),d0                    ; Invert bit order...
        move.b  (a4,d1.w),d1                    ; ... for both bytes.
        endif
.skip
        endm
 
_Kos_ReadBit macro
        if _Kos_UseLUT==1
        add.b   d0,d0                                   ; Get a bit from the bitstream.
        else
        lsr.b   #1,d0                                   ; Get a bit from the bitstream.
        endif
        endm
; ===========================================================================
; KozDec_193A:
KosDec:
        moveq   #(1<<_Kos_LoopUnroll)-1,d7
        if _Kos_UseLUT==1
        moveq   #0,d0
        moveq   #0,d1
        lea     KosDec_ByteMap(pc),a4           ; Load LUT pointer.
        endif
        move.b  (a0)+,d0                                ; Get desc field low-byte.
        move.b  (a0)+,d1                                ; Get desc field hi-byte.
        if _Kos_UseLUT==1
        move.b  (a4,d0.w),d0                    ; Invert bit order...
        move.b  (a4,d1.w),d1                    ; ... for both bytes.
        endif
        moveq   #7,d2                                   ; Set repeat count to 8.
        moveq   #0,d3                                   ; d3 will be desc field switcher.
        bra.s   .FetchNewCode
; ---------------------------------------------------------------------------
.FetchCodeLoop:
        ; Code 1 (Uncompressed byte).
        _Kos_RunBitStream
        move.b  (a0)+,(a1)+
 
.FetchNewCode:
        _Kos_ReadBit
        bcs.s   .FetchCodeLoop                  ; If code = 1, branch.
 
        ; Codes 00 and 01.
        moveq   #-1,d5
        lea     (a1),a5
        _Kos_RunBitStream
        if _Kos_ExtremeUnrolling==1
        _Kos_ReadBit
        bcs.w   .Code_01
 
        ; Code 00 (Dictionary ref. short).
        _Kos_RunBitStream
        _Kos_ReadBit
        bcs.s   .Copy45
        _Kos_RunBitStream
        _Kos_ReadBit
        bcs.s   .Copy3
        _Kos_RunBitStream
        move.b  (a0)+,d5                                ; d5 = displacement.
        adda.w  d5,a5
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        bra.s   .FetchNewCode
; ---------------------------------------------------------------------------
.Copy3:
        _Kos_RunBitStream
        move.b  (a0)+,d5                                ; d5 = displacement.
        adda.w  d5,a5
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        bra.w   .FetchNewCode
; ---------------------------------------------------------------------------
.Copy45:
        _Kos_RunBitStream
        _Kos_ReadBit
        bcs.s   .Copy5
        _Kos_RunBitStream
        move.b  (a0)+,d5                                ; d5 = displacement.
        adda.w  d5,a5
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        bra.w   .FetchNewCode
; ---------------------------------------------------------------------------
.Copy5:
        _Kos_RunBitStream
        move.b  (a0)+,d5                                ; d5 = displacement.
        adda.w  d5,a5
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        move.b  (a5)+,(a1)+
        bra.w   .FetchNewCode
; ---------------------------------------------------------------------------
        else
        moveq   #0,d4                                   ; d4 will contain copy count.
        _Kos_ReadBit
        bcs.s   .Code_01
 
        ; Code 00 (Dictionary ref. short).
        _Kos_RunBitStream
        _Kos_ReadBit
        addx.w  d4,d4
        _Kos_RunBitStream
        _Kos_ReadBit
        addx.w  d4,d4
        _Kos_RunBitStream
        move.b  (a0)+,d5                                ; d5 = displacement.
 
.StreamCopy:
        adda.w  d5,a5
        move.b  (a5)+,(a1)+                             ; Do 1 extra copy (to compensate +1 to copy counter).
 
.copy:
        move.b  (a5)+,(a1)+
        dbra    d4,.copy
        bra.w   .FetchNewCode
        endif
; ---------------------------------------------------------------------------
.Code_01:
        moveq   #0,d4                                   ; d4 will contain copy count.
        ; Code 01 (Dictionary ref. long / special).
        _Kos_RunBitStream
        move.b  (a0)+,d6                                ; d6 = %LLLLLLLL.
        move.b  (a0)+,d4                                ; d4 = %HHHHHCCC.
        move.b  d4,d5                                   ; d5 = %11111111 HHHHHCCC.
        lsl.w   #5,d5                                   ; d5 = %111HHHHH CCC00000.
        move.b  d6,d5                                   ; d5 = %111HHHHH LLLLLLLL.
        if _Kos_LoopUnroll==3
        and.w   d7,d4                                   ; d4 = %00000CCC.
        else
        andi.w  #7,d4
        endif
        bne.s   .StreamCopy                             ; if CCC=0, branch.
 
        ; special mode (extended counter)
        move.b  (a0)+,d4                                ; Read cnt
        beq.s   .Quit                                   ; If cnt=0, quit decompression.
        subq.b  #1,d4
        beq.w   .FetchNewCode                   ; If cnt=1, fetch a new code.
 
        adda.w  d5,a5
        move.b  (a5)+,(a1)+                             ; Do 1 extra copy (to compensate +1 to copy counter).
        move.w  d4,d6
        not.w   d6
        and.w   d7,d6
        add.w   d6,d6
        lsr.w   #_Kos_LoopUnroll,d4
        jmp     .largecopy(pc,d6.w)
; ---------------------------------------------------------------------------
.largecopy:
        rept (1<<_Kos_LoopUnroll)
        move.b  (a5)+,(a1)+
        endm
        dbra    d4,.largecopy
        bra.w   .FetchNewCode
; ---------------------------------------------------------------------------
        if _Kos_ExtremeUnrolling==1
.StreamCopy:
        adda.w  d5,a5
        move.b  (a5)+,(a1)+                             ; Do 1 extra copy (to compensate +1 to copy counter).
        if _Kos_LoopUnroll==3
        eor.w   d7,d4
        else
        eori.w  #7,d4
        endif
        add.w   d4,d4
        jmp     .mediumcopy(pc,d4.w)
; ---------------------------------------------------------------------------
.mediumcopy:
        rept 8
        move.b  (a5)+,(a1)+
        endm
        bra.w   .FetchNewCode
        endif
; ---------------------------------------------------------------------------
.Quit:
        rts                                                             ; End of function KosDec.
; ===========================================================================
        if _Kos_UseLUT==1
KosDec_ByteMap:
        dc.b    $00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
        dc.b    $08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
        dc.b    $04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
        dc.b    $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
        dc.b    $02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
        dc.b    $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
        dc.b    $06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
        dc.b    $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
        dc.b    $01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
        dc.b    $09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
        dc.b    $05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
        dc.b    $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
        dc.b    $03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
        dc.b    $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
        dc.b    $07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
        dc.b    $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF
        endif
; ===========================================================================
; End of function KosDec

; ===========================================================================
	nop




; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_19DC:
PalCycle_Load:
	bsr.w	PalCycle_SuperSonic
	moveq	#0,d2
	moveq	#0,d0
	move.b	(Current_Zone).w,d0	; use level number as index into palette cycles
	add.w	d0,d0			; (multiply by element size = 2 bytes)
	move.w	PalCycle(pc,d0.w),d0	; load animated palettes offset index into d0
	jmp	PalCycle(pc,d0.w)	; jump to PalCycle + offset index
; ---------------------------------------------------------------------------
	rts
; End of function PalCycle_Load

; ===========================================================================
; off_19F4:
PalCycle: zoneOffsetTable 2,1
	zoneTableEntry.w PalCycle_EHZ - PalCycle	; 0
    zoneTableEnd

; ===========================================================================
PalCycle_EHZ:
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_213E:
PalCycle_SuperSonic:
    	cmp.w    #3,(Player_mode).w
    	bge.w    PalCycle_SuperKnuckles
	move.b	(Super_Sonic_palette).w,d0
	beq.s	++	; rts	; return, if Sonic isn't super
	bmi.w	PalCycle_SuperSonic_normal	; branch, if fade-in is done
	subq.b	#1,d0
	bne.w	PalCycle_SuperSonic_revert	; branch for values greater than 1

	; fade from Sonic's to Super Sonic's palette
	; run frame timer
	subq.b	#1,(Palette_timer).w
	bpl.s	++	; rts
	move.b	#3,(Palette_timer).w

	; increment palette frame and update Sonic's palette
	lea	(CyclingPal_SSTransformation).l,a0
	move.w	(Palette_frame).w,d0
	addq.w	#8,(Palette_frame).w	; 1 palette entry = 1 word, Sonic uses 4 shades of blue
	cmpi.w	#$30,(Palette_frame).w	; has palette cycle reached the 6th frame?
	blo.s	+			; if not, branch
	move.b	#-1,(Super_Sonic_palette).w	; mark fade-in as done
	andi.b	#lock_del,(MainCharacter+status3).w	; restore Sonic's movement
+	lea	(Normal_palette+4).w,a1
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)
	; note: the fade in for Sonic's underwater palette is missing.
	; branch to the code below (*) to fix this
/	rts
PalCycle_SuperKnuckles:
        move.b    ($FFFFF65F).w,d0
        beq.s    locret_301E74
        bmi.w    loc_301E8A
        subq.b    #1,d0
        bne.s    loc_301E76
        subq.b    #1,($FFFFF65E).w
        bpl.s    locret_301E74
        move.b    #3,($FFFFF65E).w
        move.b    #$FF,($FFFFF65F).w
        move.w    #0,($FFFFF65C).w
        move.b    #0,($FFFFB02A).w

locret_301E74:

        rts


loc_301E76:
        moveq    #0,d0
        move.w    d0,($FFFFF65C).w
        move.b    d0,($FFFFF65F).w
        lea    (unk_301F1C).l,a0
        bra.w    loc_301EBA


loc_301E8A:
        subq.b    #1,($FFFFF65E).w
        bpl.w    locret_301E74
        move.b    #2,($FFFFF65E).w
        lea    (Pal_SuperKnuckles).l,a0
        move.w    ($FFFFF65C).w,d0
        addq.w    #6,($FFFFF65C).w
        cmp.w    #$3C,($FFFFF65C).w
        bcs.s    loc_301EBA
        move.w    #0,($FFFFF65C).w
        move.b    #$E,($FFFFF65E).w

loc_301EBA:

        lea    ($FFFFFB04).w,a1
        move.l    (a0,d0.w),(a1)+
        move.w    4(a0,d0.w),2(a1)
        tst.b    ($FFFFF730).w
        beq.w    locret_301E74
        lea    ($FFFFF084).w,a1
        move.l    (a0,d0.w),(a1)+
        move.w    4(a0,d0.w),2(a1)
        rts



Pal_SuperKnuckles:dc.b     4
        dc.b $28
        dc.b   6
        dc.b $4E
        dc.b  $A
        dc.b $6E
        dc.b   6
        dc.b $4A
        dc.b   8
        dc.b $6E
        dc.b  $C
        dc.b $8E
        dc.b   8
        dc.b $6C
        dc.b  $A
        dc.b $8E
        dc.b  $E
        dc.b $AE
        dc.b  $A
        dc.b $8E
        dc.b  $C
        dc.b $AE
        dc.b  $E
        dc.b $CE
        dc.b  $C
        dc.b $AE
        dc.b  $E
        dc.b $CE
        dc.b  $E
        dc.b $EE
        dc.b  $A
        dc.b $8E
        dc.b  $C
        dc.b $AE
        dc.b  $E
        dc.b $CE
        dc.b   8
        dc.b $6C
        dc.b  $A
        dc.b $8E
        dc.b  $E
        dc.b $AE
        dc.b   6
        dc.b $4A
        dc.b   8
        dc.b $6E
        dc.b  $C
        dc.b $8E
        dc.b   4
        dc.b $28
        dc.b   6
        dc.b $4E
        dc.b  $A
        dc.b $6E
        dc.b   2
        dc.b   6
        dc.b   4
        dc.b  $C
        dc.b   8
        dc.b $4E
unk_301F1C:    dc.b   2
        dc.b   6
        dc.b   2
        dc.b  $C
        dc.b   6
        dc.b $4E
; ===========================================================================
; loc_2188:
PalCycle_SuperSonic_revert:	; runs the fade in transition backwards
	; run frame timer
	subq.b	#1,(Palette_timer).w
	bpl.w	-	; rts
	move.b	#3,(Palette_timer).w

	; decrement palette frame and update Sonic's palette
	lea	(CyclingPal_SSTransformation).l,a0
	move.w	(Palette_frame).w,d0
	subq.w	#8,(Palette_frame).w	; previous frame
	bcc.s	+			; branch, if it isn't the first frame
	move.b	#0,(Palette_frame).w
	move.b	#0,(Super_Sonic_palette).w	; stop palette cycle
+
	lea	(Normal_palette+4).w,a1
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)
	; underwater palettes (*)
	lea	(CyclingPal_CPZUWTransformation).l,a0
	cmpi.b	#chemical_plant_zone,(Current_Zone).w
	beq.s	+
	cmpi.b	#aquatic_ruin_zone,(Current_Zone).w
	bne.w	-	; rts
	lea	(CyclingPal_ARZUWTransformation).l,a0
+	lea	(Underwater_palette+4).w,a1
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)
	rts
; ===========================================================================
; loc_21E6:
PalCycle_SuperSonic_normal:
	; run frame timer
	subq.b	#1,(Palette_timer).w
	bpl.w	-	; rts
	move.b	#7,(Palette_timer).w

	; increment palette frame and update Sonic's palette
	lea	(CyclingPal_SSTransformation).l,a0
	move.w	(Palette_frame).w,d0
	addq.w	#8,(Palette_frame).w	; next frame
	cmpi.w	#$78,(Palette_frame).w	; is it the last frame?
	blo.s	+			; if not, branch
	move.w	#$30,(Palette_frame).w	; reset frame counter (Super Sonic's normal palette cycle starts at $30. Everything before that is for the palette fade)
+
	lea	(Normal_palette+4).w,a1
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)
	; underwater palettes
	lea	(CyclingPal_CPZUWTransformation).l,a0
	cmpi.b	#chemical_plant_zone,(Current_Zone).w
	beq.s	+
	cmpi.b	#aquatic_ruin_zone,(Current_Zone).w
	bne.w	-	; rts
	lea	(CyclingPal_ARZUWTransformation).l,a0
+	lea	(Underwater_palette+4).w,a1
	move.l	(a0,d0.w),(a1)+
	move.l	4(a0,d0.w),(a1)
	rts
; End of function PalCycle_SuperSonic

; ===========================================================================
;----------------------------------------------------------------------------
;Palette for transformation to Super Sonic
;----------------------------------------------------------------------------
; Pal_2246:
CyclingPal_SSTransformation:
	BINCLUDE	"art/palettes/Super Sonic transformation.bin"
;----------------------------------------------------------------------------
;Palette for transformation to Super Sonic while underwater in CPZ
;----------------------------------------------------------------------------
; Pal_22C6:
CyclingPal_CPZUWTransformation:
	BINCLUDE	"art/palettes/CPZWater SS transformation.bin"
;----------------------------------------------------------------------------
;Palette for transformation to Super Sonic while underwater in ARZ
;----------------------------------------------------------------------------
; Pal_2346:
CyclingPal_ARZUWTransformation:
	BINCLUDE	"art/palettes/ARZWater SS transformation.bin"

; ---------------------------------------------------------------------------
; Subroutine to fade out and fade in
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_23C6:
Pal_FadeTo:
	move.w	#$3F,(Palette_fade_range).w
	moveq	#0,d0
	lea	(Normal_palette).w,a0
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0
	moveq	#0,d1
	move.b	(Palette_fade_length).w,d0
; loc_23DE:
Pal_ToBlack:
	move.w	d1,(a0)+
	dbf	d0,Pal_ToBlack	; fill palette with $000 (black)

	move.w	#$15,d4
-	move.b	#$12,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.s	Pal_FadeIn
	bsr.w	RunPLC_RAM
	dbf	d4,-

	rts
; End of function Pal_FadeTo

; ---------------------------------------------------------------------------
; Palette fade-in subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_23FE:
Pal_FadeIn:
	moveq	#0,d0
	lea	(Normal_palette).w,a0
	lea	(Target_palette).w,a1
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0
	adda.w	d0,a1

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_AddColor
	dbf	d0,-

	tst.b	(Water_flag).w
	beq.s	+	; rts
	moveq	#0,d0
	lea	(Underwater_palette).w,a0
	lea	(Underwater_palette_2).w,a1
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0
	adda.w	d0,a1

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_AddColor
	dbf	d0,-
+
	rts
; End of function Pal_FadeIn


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_243E:
Pal_AddColor:
	move.w	(a1)+,d2
	move.w	(a0),d3
	cmp.w	d2,d3
	beq.s	Pal_AddNone
	move.w	d3,d1
	addi.w	#$200,d1	; increase blue value
	cmp.w	d2,d1		; has blue reached threshold level?
	bhi.s	Pal_AddGreen	; if yes, branch
	move.w	d1,(a0)+	; update palette
	rts
; ===========================================================================
; loc_2454:
Pal_AddGreen:
	move.w	d3,d1
	addi.w	#$20,d1		; increase green value
	cmp.w	d2,d1
	bhi.s	Pal_AddRed
	move.w	d1,(a0)+	; update palette
	rts
; ===========================================================================
; loc_2462:
Pal_AddRed:
	addq.w	#2,(a0)+	; increase red value
	rts
; ===========================================================================
; loc_2466:
Pal_AddNone:
	addq.w	#2,a0
	rts
; End of function Pal_AddColor


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_246A:
Pal_FadeFrom:
	move.w	#$3F,(Palette_fade_range).w

	move.w	#$15,d4
-	move.b	#$12,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.s	Pal_FadeOut
	bsr.w	RunPLC_RAM
	dbf	d4,-

	rts
; End of function Pal_FadeFrom

; ---------------------------------------------------------------------------
; Palette fade-out subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_248A:
Pal_FadeOut:
	moveq	#0,d0
	lea	(Normal_palette).w,a0
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_DecColor
	dbf	d0,-

	moveq	#0,d0
	lea	(Underwater_palette).w,a0
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_DecColor
	dbf	d0,-

	rts
; End of function Pal_FadeOut


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_24B8:
Pal_DecColor:
	move.w	(a0),d2
	beq.s	Pal_DecNone
	move.w	d2,d1
	andi.w	#$E,d1
	beq.s	Pal_DecGreen
	subq.w	#2,(a0)+	; decrease red value
	rts
; ===========================================================================
; loc_24C8:
Pal_DecGreen:
	move.w	d2,d1
	andi.w	#$E0,d1
	beq.s	Pal_DecBlue
	subi.w	#$20,(a0)+	; decrease green value
	rts
; ===========================================================================
; loc_24D6:
Pal_DecBlue:
	move.w	d2,d1
	andi.w	#$E00,d1
	beq.s	Pal_DecNone
	subi.w	#$200,(a0)+	; decrease blue value
	rts
; ===========================================================================
; loc_24E4:
Pal_DecNone:
	addq.w	#2,a0
	rts
; End of function Pal_DecColor

; ---------------------------------------------------------------------------
; Subroutine to fill the palette with white
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_24E8:
Pal_MakeWhite:
	move.w	#$3F,(Palette_fade_range).w
	moveq	#0,d0
	lea	(Normal_palette).w,a0
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0
	move.w	#$EEE,d1

	move.b	(Palette_fade_length).w,d0
-	move.w	d1,(a0)+
	dbf	d0,-

	move.w	#$15,d4
-	move.b	#$12,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.s	Pal_WhiteToBlack
	bsr.w	RunPLC_RAM
	dbf	d4,-

	rts
; End of function Pal_MakeWhite


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_2522:
Pal_WhiteToBlack:
	moveq	#0,d0
	lea	(Normal_palette).w,a0
	lea	(Target_palette).w,a1
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0
	adda.w	d0,a1

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_DecColor2
	dbf	d0,-

	tst.b	(Water_flag).w
	beq.s	+	; rts
	moveq	#0,d0
	lea	(Underwater_palette).w,a0
	lea	(Underwater_palette_2).w,a1
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0
	adda.w	d0,a1

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_DecColor2
	dbf	d0,-

+	rts
; End of function Pal_WhiteToBlack


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_2562:
Pal_DecColor2:
	move.w	(a1)+,d2
	move.w	(a0),d3
	cmp.w	d2,d3
	beq.s	Pal_DecNone2
	move.w	d3,d1
	subi.w	#$200,d1	; decrease blue value
	bcs.s	Pal_DecGreen2
	cmp.w	d2,d1
	blo.s	Pal_DecGreen2
	move.w	d1,(a0)+
	rts
; ===========================================================================
; loc_257A:
Pal_DecGreen2:
	move.w	d3,d1
	subi.w	#$20,d1	; decrease green value
	bcs.s	Pal_DecRed2
	cmp.w	d2,d1
	blo.s	Pal_DecRed2
	move.w	d1,(a0)+
	rts
; ===========================================================================
; loc_258A:
Pal_DecRed2:
	subq.w	#2,(a0)+	; decrease red value
	rts
; ===========================================================================
; loc_258E:
Pal_DecNone2:
	addq.w	#2,a0
	rts
; End of function Pal_DecColor2

; ---------------------------------------------------------------------------
; Subroutine to make a white flash when you enter a special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_2592:
Pal_MakeFlash:
	move.w	#$3F,(Palette_fade_range).w

	move.w	#$15,d4
-	move.b	#$12,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.s	Pal_ToWhite
	bsr.w	RunPLC_RAM
	dbf	d4,-

	rts
; End of function Pal_MakeFlash


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_25B2:
Pal_ToWhite:
	moveq	#0,d0
	lea	(Normal_palette).w,a0
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_AddColor2
	dbf	d0,-

	moveq	#0,d0
	lea	(Underwater_palette).w,a0
	move.b	(Palette_fade_start).w,d0
	adda.w	d0,a0

	move.b	(Palette_fade_length).w,d0
-	bsr.s	Pal_AddColor2
	dbf	d0,-

	rts
; End of function Pal_ToWhite


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_25E0:
Pal_AddColor2:
	move.w	(a0),d2
	cmpi.w	#$EEE,d2
	beq.s	Pal_AddNone2
	move.w	d2,d1
	andi.w	#$E,d1
	cmpi.w	#$E,d1
	beq.s	Pal_AddGreen2
	addq.w	#2,(a0)+	; increase red value
	rts
; ===========================================================================
; loc_25F8:
Pal_AddGreen2:
	move.w	d2,d1
	andi.w	#$E0,d1
	cmpi.w	#$E0,d1
	beq.s	Pal_AddBlue2
	addi.w	#$20,(a0)+	; increase green value
	rts
; ===========================================================================
; loc_260A:
Pal_AddBlue2:
	move.w	d2,d1
	andi.w	#$E00,d1
	cmpi.w	#$E00,d1
	beq.s	Pal_AddNone2
	addi.w	#$200,(a0)+	; increase blue value
	rts
; ===========================================================================
; loc_261C:
Pal_AddNone2:
	addq.w	#2,a0
	rts
; End of function Pal_AddColor2
; ===========================================================================
; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_2712:
PalLoad1:
	lea	(PalPointers).l,a1
	lsl.w	#3,d0
	adda.w	d0,a1
	movea.l	(a1)+,a2
	movea.w	(a1)+,a3
	adda.w	#Target_palette-Normal_palette,a3

	move.w	(a1)+,d7
-	move.l	(a2)+,(a3)+
	dbf	d7,-

	rts
; End of function PalLoad1


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_272E:
PalLoad2:
	lea	(PalPointers).l,a1
	lsl.w	#3,d0
	adda.w	d0,a1
	movea.l	(a1)+,a2
	movea.w	(a1)+,a3

	move.w	(a1)+,d7
-	move.l	(a2)+,(a3)+
	dbf	d7,-

	rts
; End of function PalLoad2


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_2746:
PalLoad3_Water:
	lea	(PalPointers).l,a1
	lsl.w	#3,d0
	adda.w	d0,a1
	movea.l	(a1)+,a2
	movea.w	(a1)+,a3
	suba.w	#Normal_palette-Underwater_palette,a3
;	suba.l	#$7A80,a3

	move.w	(a1)+,d7
-	move.l	(a2)+,(a3)+
	dbf	d7,-

	rts
; End of function PalLoad3_Water


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_2764:
PalLoad4_Water:
	lea	(PalPointers).l,a1
	lsl.w	#3,d0
	adda.w	d0,a1
	movea.l	(a1)+,a2
	movea.w	(a1)+,a3
	suba.w	#Normal_palette-Underwater_palette_2,a3
;	suba.l	#$7A00,a3
	move.w	(a1)+,d7
-	move.l	(a2)+,(a3)+
	dbf	d7,-

	rts
; End of function PalLoad4_Water

; ===========================================================================
;----------------------------------------------------------------------------
; Palette pointers
; (PALETTE DESCRIPTOR ARRAY)
; This struct array defines the palette to use for each level.
;----------------------------------------------------------------------------

palptr	macro	ptr,lineno
	dc.l ptr	; Pointer to palette
	dc.w (Normal_palette+lineno*palette_line_size*2)&$FFFF	; Location in ram to load palette into
	dc.w bytesToLcnt(ptr_End-ptr)	; Size of palette in (bytes / 4)
	endm

PalPointers:
PalPtr_SEGA:	palptr Pal_SEGA,  0
PalPtr_Title:	palptr Pal_Title, 1
PalPtr_BGND:	palptr Pal_BGND,  0
PalPtr_EHZ:	palptr Pal_EHZ,   1
PalPtr_WFZ:	palptr Pal_WFZ,	 1
PalPtr_L1:	palptr Pal_L1,   1
PalPtr_Menu:	palptr Pal_Menu,  0
PalPtr_ARZ_U:	palptr Pal_ARZ_U, 0
PalPtr_Knux:	palptr Pal_Knux,  0
	;dc.l Pal_Knux ; Knux palette
	;dc.w $FB00
	;dc.w $F


; Dr.X.Insanity has added this for the Save Menu

PalPtr_SaveMenu:
	dc.l SaveMenu_Pal	; Save Menu pallets
	dc.w $FB00
	dc.w $1F
PalPtr_EHZ_Top:	palptr Pal_EHZ_Top,  0
PalPtr_EHZ_U:	palptr Pal_EHZ_U,  0

; ----------------------------------------------------------------------------
; This macro defines Pal_ABC and Pal_ABC_End, so palptr can compute the size of
; the palette automatically
palette macro {INTLABEL},path
__LABEL__ label *
	BINCLUDE path
__LABEL___End label *
	endm

Pal_SEGA:  palette "art/palettes/Pal_SEGA.pal" ; SEGA screen palette (Sonic and initial background)
Pal_Title: palette "art/palettes/Title screen.bin" ; Title screen Palette
Pal_BGND:  palette "art/palettes/SonicAndTails.bin" ; "Sonic and Miles" background palette (also usually the primary palette line)
Pal_EHZ:   palette "art/palettes/EHZ.bin" ; Emerald Hill Zone palette
Pal_WFZ:   palette "art/palettes/WFZ.bin" ; Wing Fortress Zone palette
Pal_L1:    palette "art/palettes/EHZ.bin" ; Emerald Hill Zone palette
Pal_Menu:  palette "art/palettes/Menu.bin" ; Menu palette
Pal_Knux:  palette "art/palettes/KnuxPal.bin"
Pal_ARZ_U: palette "art/palettes/ARZ underwater.bin" ; Aquatic Ruin Zone underwater palette
Pal_EHZ_Top:	palette "art/palettes/EHZ top.bin" ; EHZ top part palette
Pal_EHZ_U:	palette "art/palettes/EHZ underwater.bin" ; EHZ underwater palette
;----------------------------------------------------------------------------
;Null for title card
;----------------------------------------------------------------------------
Pal_Null:
        dc.b $02,$22,$00,$00,$0A,$22,$0C
	dc.b $42,$0E,$64,$00,$44,$0E,$EE
	dc.b $0A,$AA,$08,$88,$04,$44,$06
	dc.b $66,$0E,$86,$00,$EE,$00,$88,$0E,$A8,$0E,$CA
; ===========================================================================
	nop




; ---------------------------------------------------------------------------
; Subroutine to perform vertical synchronization
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_3384: DelayProgram:
WaitForVint:
	move	#$2300,sr

-	tst.b	(Vint_routine).w
	bne.s	-
	rts
; End of function WaitForVint


; ---------------------------------------------------------------------------
; Subroutine to generate a pseudo-random number in d0
; d0 = (RNG & $FFFF0000) | ((RNG*41 & $FFFF) + ((RNG*41 & $FFFF0000) >> 16))
; RNG = ((RNG*41 + ((RNG*41 & $FFFF) << 16)) & $FFFF0000) | (RNG*41 & $FFFF)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_3390:
RandomNumber:
	move.l	(RNG_seed).w,d1
	bne.s	+
	move.l	#$2A6D365A,d1 ; if the RNG is 0, reset it to this crazy number

	; set the high word of d0 to be the high word of the RNG
	; and multiply the RNG by 41
+	move.l	d1,d0
	asl.l	#2,d1
	add.l	d0,d1
	asl.l	#3,d1
	add.l	d0,d1

	; add the low word of the RNG to the high word of the RNG
	; and set the low word of d0 to be the result
	move.w	d1,d0
	swap	d1
	add.w	d1,d0
	move.w	d0,d1
	swap	d1

	move.l	d1,(RNG_seed).w
	rts
; End of function RandomNumber


; ---------------------------------------------------------------------------
; Subroutine to calculate sine and cosine of an angle
; d0 = input byte = angle (360 degrees == 256)
; d0 = output word = 255 * sine(angle)
; d1 = output word = 255 * cosine(angle)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_33B6:
CalcSine:
	andi.w	#$FF,d0
	add.w	d0,d0
	addi.w	#$80,d0
	move.w	Sine_Data(pc,d0.w),d1 ; cos
	subi.w	#$80,d0
	move.w	Sine_Data(pc,d0.w),d0 ; sin
	rts
; End of function CalcSine

; ===========================================================================
; word_33CE:
Sine_Data:	BINCLUDE	"misc/sinewave.bin"


; ---------------------------------------------------------------------------
; Subroutine to calculate arctangent of y/x
; d1 = input x
; d2 = input y
; d0 = output angle (360 degrees == 256)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_364E:
CalcAngle:
	movem.l	d3-d4,-(sp)
	moveq	#0,d3
	moveq	#0,d4
	move.w	d1,d3
	move.w	d2,d4
	or.w	d3,d4
	beq.s	CalcAngle_Zero ; special case return if x and y are both 0
	move.w	d2,d4

	absw.w	d3	; calculate absolute value of x
	absw.w	d4	; calculate absolute value of y
	cmp.w	d3,d4
	bhs.w	+
	lsl.l	#8,d4
	divu.w	d3,d4
	moveq	#0,d0
	move.b	Angle_Data(pc,d4.w),d0
	bra.s	++
+
	lsl.l	#8,d3
	divu.w	d4,d3
	moveq	#$40,d0
	sub.b	Angle_Data(pc,d3.w),d0
+
	tst.w	d1
	bpl.w	+
	neg.w	d0
	addi.w	#$80,d0
+
	tst.w	d2
	bpl.w	+
	neg.w	d0
	addi.w	#$100,d0
+
	movem.l	(sp)+,d3-d4
	rts
; ===========================================================================
; loc_36AA:
CalcAngle_Zero:
	move.w	#$40,d0
	movem.l	(sp)+,d3-d4
	rts
; End of function CalcAngle

; ===========================================================================
; byte_36B4:
Angle_Data:	BINCLUDE	"misc/angles.bin"

; ===========================================================================
	nop




; loc_37B8:
SegaScreen:		; CODE XREF: ROM:GameModeArrayj
	move.w	#1,(Player_option).w
	move.b	#4,($FFFFF600).w
	rts
; ---------------------------------------------------------------------------
; Subroutine that does the exact same thing as PlaneMapToVRAM2
; (this one is used at the Sega screen)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_396E: ShowVDPGraphics3:
PlaneMapToVRAM3:
	lea	(VDP_data_port).l,a6
	move.l	#$1000000,d4
-	move.l	d0,4(a6)
	move.w	d1,d3
-	move.w	(a1)+,(a6)
	dbf	d3,-
	add.l	d4,d0
	dbf	d2,--
	rts
; End of function PlaneMapToVRAM3

; ===========================================================================
	nop

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_3990:
JmpTo_RunObjects
	jmp	(RunObjects).l
; End of function JmpTo_RunObjects

; ===========================================================================
	align 4
; ===========================================================================
; loc_3998:
TitleScreen:
	move.b	#MusID_Stop,d0
	bsr.w	PlayMusic
	bsr.w	ClearPLC
	bsr.w	Pal_FadeFrom
	move	#$2700,sr
	lea	(VDP_control_port).l,a6
	move.w	#$8004,(a6)
	move.w	#$8230,(a6)
	move.w	#$8407,(a6)
	move.w	#$9001,(a6)
	move.w	#$9200,(a6)
	move.w	#$8B03,(a6)
	move.w	#$8720,(a6)
	clr.b	(Water_fullscreen_flag).w
	move.w	#$8C81,(a6)
	bsr.w	ClearScreen

	clearRAM Sprite_Table_Input,(Sprite_Table_Input_End-Sprite_Table_Input) ; fill $AC00-$AFFF with $0
	clearRAM TtlScr_Object_RAM,(TtlScr_Object_RAM_End-TtlScr_Object_RAM) ; fill object RAM ($B000-$D5FF) with $0
	clearRAM Misc_Variables,(Misc_Variables_End-Misc_Variables) ; clear CPU player RAM and following variables
	clearRAM Camera_RAM,(Camera_RAM_End-Camera_RAM) ; clear camera RAM and following variables

	move.b	#0,(Last_star_pole_hit).w
	move.w	#0,(Debug_placement_mode).w
	move.w	#0,(Demo_mode_flag).w
	move.w	#0,($FFFFFFDA).w
	move.w	#0,(PalCycle_Timer).w
	move.w	#0,(Two_player_mode).w
	move.b	#0,(Level_started_flag).w

	move.b	#3,(Life_count).w
	moveq	#0,d0
	move.w	d0,(Ring_count).w
	move.l	d0,(Timer).w
	move.l	d0,(Score).w
	move.b	d0,(Continue_count).w
	move.l	#5000,(Next_Extra_life_score).w

	moveq	#PLCID_Std1,d0
	bsr.w	LoadPLC2

	move	#$2700,sr
	move.l	#vdpComm($0000,VRAM,WRITE),(VDP_control_port).l
	lea	(MapEng_Title).l,a0
	bsr.w	NemDec
	move.l	#vdpComm($2A00,VRAM,WRITE),(VDP_control_port).l
	lea	(MapEng_TitleSprites).l,a0
	bsr.w	NemDec
	move.l	#vdpComm($7E40,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_MenuJunk).l,a0
	bsr.w	NemDec
	move.l	#vdpComm($8040,VRAM,WRITE),(VDP_control_port).l
	;lea	(ArtNem_Player1VS2).l,a0
	;bsr.w	NemDec
	;move.l	#vdpComm($D000,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_FontStuff).l,a0
	bsr.w	NemDec

TitleScreen_WaitPLC:
	move.b	#$C,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.w	RunPLC_RAM
	tst.l	(Plc_Buffer).w			; are there any items in the pattern load cue?
	bne.s	TitleScreen_WaitPLC		; if yes, branch
	bra.w	TitleScreen_ChoseOptions

ContinueStartGameFunctions:
	move.b	#GameModeID_Level,(Game_Mode).w ; => Level (Zone play mode)
	move.b	#MusID_FadeOut,d0 ; prepare to stop music (fade out)
	bsr.w	PlaySound
	moveq	#0,d0
	move.b	(Title_screen_option).w,d0
	bne.s	TitleScreen_ChoseLevelSelect	; branch if not a 1-player game
; -------------------------------------------------------------

	moveq	#0,d0
	move.w	d0,(Two_player_mode_copy).w
	move.w	d0,(Two_player_mode).w
;    if emerald_hill_zone_act_1=0
	move.w	d3,(Current_ZoneAndAct).w ; emerald_hill_zone_act_1
 ;   else
;	move.w #emerald_hill_zone_act_1,(Current_ZoneAndAct).w
  ;  endif
	;tst.b	(Level_select_flag).w	; has level select cheat been entered?
	;beq.s	+			; if not, branch
	btst	#button_A,(Ctrl_1_Held).w ; is A held down?
	beq.s	+	 		; if not, branch
	move.b	#GameModeID_LevelSelect,(Game_Mode).w ; => LevelSelectMenu
	rts
; ---------------------------------------------------------------------------
+
	move.w	d0,(Current_Special_Stage).w
	move.w	d0,(Got_Emerald).w
	move.l	d0,(Got_Emeralds_array).w
	move.l	d0,(Got_Emeralds_array+4).w
	rts
; ===========================================================================
; loc_3D20:
TitleScreen_ChoseOptions:
	move.b	#GameModeID_OptionsMenu,(Game_Mode).w ; => OptionsMenu
	move.b	#0,(Options_menu_box).w
	rts
TitleScreen_ChoseLevelSelect:
	subq.b	#1,d0
	bne.s	TitleScreen_ChoseOptions
	move.b	#GameModeID_LevelSelect,(Game_Mode).w
	rts
; ===========================================================================
; loc_3D2E:
TitleScreen_Demo:
	move.b	#MusID_FadeOut,d0
	bsr.w	PlaySound
	move.w	(Demo_number).w,d0
	andi.w	#7,d0
	add.w	d0,d0
	move.w	DemoLevels(pc,d0.w),d0
	move.w	d0,(Current_ZoneAndAct).w
	addq.w	#1,(Demo_number).w
	cmpi.w	#(DemoLevels_End-DemoLevels)/2,(Demo_number).w
	blo.s	+
	move.w	#0,(Demo_number).w
+
	move.w	#1,(Demo_mode_flag).w
	move.b	#GameModeID_Demo,(Game_Mode).w ; => Level (Demo mode)
	cmpi.w	#emerald_hill_zone_act_1,(Current_ZoneAndAct).w
	bne.s	+
	move.w	#1,(Two_player_mode).w
+
	move.b	#3,(Life_count).w
	moveq	#0,d0
	move.w	d0,(Ring_count).w
	move.l	d0,(Timer).w
	move.l	d0,(Score).w
	move.l	#5000,(Next_Extra_life_score).w
	rts
; ===========================================================================
; word_3DAC:
DemoLevels:
	dc.w	wing_fortress_zone_act_1	; WFZ
	dc.w	chemical_plant_zone_act_1	; CPZ
	dc.w	aquatic_ruin_zone_act_1		; ARZ
	dc.w	casino_night_zone_act_1		; CNZ
DemoLevels_End:

; ===========================================================================
;----------------------------------------------------------------------------
; 1P Music Playlist
;----------------------------------------------------------------------------
; byte_3EA0:
MusicList:
	dc.b   2+$80	; 0 ; EHZ
	dc.b   $A+$80	; 1
	dc.b   5+$80	; 2
	dc.b   4+$80	; 3
	dc.b   5+$80	; 4 ; MTZ1,2
	dc.b   5+$80	; 5 ; MTZ3
	dc.b  $F+$80	; 6 ; WFZ
	dc.b   6+$80	; 7 ; HTZ
	dc.b $10+$80	; 8
	dc.b  $D+$80	; 9
	dc.b   4+$80	; 10 ; OOZ
	dc.b  $B+$80	; 11 ; MCZ
	dc.b  $9+$80	; 12 ; CNZ
	dc.b  $E+$80	; 13 ; CPZ
	dc.b  $A+$80	; 14 ; DEZ
	dc.b   7+$80	; 15 ; ARZ
	dc.b  $D+$80	; 16 ; SCZ
	dc.b   0	; 17
; ----------------------------------------------------------

; ---------------------------------------------------------------------------
; Level
; DEMO AND ZONE LOOP (MLS values $08, $0C; bit 7 set indicates that load routine is running)
; ---------------------------------------------------------------------------
; loc_3EC4:
Level:
	move.b	#1,(Debug_mode_flag).w			; Force enable debug mode
	bset	#GameModeFlag_TitleCard,(Game_Mode).w	; add $80 to screen mode (for pre level sequence)
	move.b	#MusID_FadeOut,d0			; fade out music
	bsr.w	PlaySound
	bsr.w	ClearPLC				; clear the pattern load cues
	bsr.w	Pal_FadeFrom				; fade palette to black
	move	#$2700,sr
	bsr.w	ClearScreen				; clear planes and sprites
	move	#$2300,sr
	moveq	#0,d0
	move.w	d0,(Timer_frames).w			; clear level timer
	move.b	(Current_Zone).w,d0			; get current zone

	; multiply d0 by 12, the size of a level art load block
	add.w	d0,d0
	add.w	d0,d0
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0

	lea	(LevelArtPointers).l,a2			; get level art pointers
	lea	(a2,d0.w),a2
	moveq	#0,d0
	move.b	(a2),d0					; get the level's first PLC
	beq.b	+					; don't load if none specified
	bsr.w	LoadPLC
-	move.b	#$C,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.w	RunPLC_RAM
	tst.l	(Plc_Buffer).w				; are there any items in the pattern load cue?
	bne.s	-					; if so, branch

+	moveq	#1,d0					; load standard PLC 1
	bsr.w	LoadPLC
	moveq	#2,d0					; load standard PLC 2
	bsr.w	LoadPLC
	bsr.w	Level_SetPlayerMode			; copy (Player_option) to (Player_mode)
	moveq	#0,d0
	move.w	Player_mode,d0				; get the current player
	bne.b	+					; if not Sonic and Tails, branch
	addq.w	#1,d0					; add 6 for most characters
+	addq.w	#5,d0					; add 5 for S&T
	bsr.w	LoadPLC					; load player's life icon
	addq.b	#1,(Update_HUD_lives).w			; update the lives counter

Level_ClrRam:
	clearRAM Sprite_Table_Input,$400
	clearRAM Object_RAM,(LevelOnly_Object_RAM_End-Object_RAM) ; clear object RAM
	clearRAM $FFFFF628,$58
	clearRAM Misc_Variables,(Misc_Variables_End-Misc_Variables)
	clearRAM $FFFFFE60,$50
	clearRAM CNZ_saucer_data,$100
	cmpi.b	#emerald_Hill_zone,(Current_Zone).w ; EHZ
	beq.s	Level_InitWater
	cmpi.w	#chemical_plant_zone_act_2,(Current_ZoneAndAct).w ; CPZ 2
	beq.s	Level_InitWater
	cmpi.b	#aquatic_ruin_zone,(Current_Zone).w ; ARZ
	beq.s	Level_InitWater
	cmpi.b	#hidden_palace_zone,(Current_Zone).w ; HPZ
	bne.s	+

Level_InitWater:
	move.b	#1,(Water_flag).w
	move.w	#0,(Two_player_mode).w
+
	lea	(VDP_control_port).l,a6
	move.w	#$8B03,(a6)
	move.w	#$8230,(a6)
	move.w	#$8407,(a6)
	move.w	#$857C,(a6)
	move.w	#$9001,(a6)
	move.w	#$8004,(a6)
	move.w	#$8720,(a6)
	move.w	#$8C81,(a6)
	tst.b	(Night_mode_flag).w
	beq.s	++
	btst	#button_C,(Ctrl_1_Held).w
	beq.s	+
	move.w	#$8C89,(a6)
+
	btst	#button_A,(Ctrl_1_Held).w
	beq.s	+
	move.b	#1,(Debug_mode_flag).w
+
	move.w	#$8ADF,(Hint_counter_reserve).w	; H-INT every 223rd scanline
	tst.w	(Two_player_mode).w
	beq.s	+
	move.w	#$8A6B,(Hint_counter_reserve).w	; H-INT every 108th scanline
	move.w	#$8014,(a6)
	move.w	#$8C87,(a6)
+
	move.w	(Hint_counter_reserve).w,(a6)
	clr.w	(VDP_Command_Buffer).w
	move.l	#VDP_Command_Buffer,(VDP_Command_Buffer_Slot).w
	tst.b	(Water_flag).w	; does level have water?
	beq.s	Level_LoadPal	; if not, branch
	move.w	#$8014,(a6)
	moveq	#0,d0
	move.w	(Current_ZoneAndAct).w,d0
    if ~~useFullWaterTables
	subi.w	#hidden_palace_zone_act_1,d0
    endif
	ror.b	#1,d0
	lsr.w	#6,d0
	andi.w	#$FFFE,d0
	lea	(WaterHeight).l,a1	; load water height array
	move.w	(a1,d0.w),d0
	move.w	d0,(Water_Level_1).w ; set water heights
	move.w	d0,(Water_Level_2).w
	move.w	d0,(Water_Level_3).w
	clr.b	(Water_routine).w	; clear water routine counter
	clr.b	(Water_fullscreen_flag).w	; clear water movement
	move.b	#1,(Water_on).w	; enable water
; loc_407C:
Level_LoadPal:
        tst.w    (Two_player_mode).w
        bne.s    SonicPal
        cmpi.w    #$3,(Player_mode).w
        beq.w    LoadKnuxPal

SonicPal:
	moveq	#PalID_BGND,d0
	bsr.w	PalLoad1	; load Sonic's palette line
	tst.b	(Water_flag).w	; does level have water?
	beq.s	Level_GetBgm	; if not, branch
	;moveq	#PalID_HPZ_U,d0	; palette number $15
	;cmpi.b	#hidden_palace_zone,(Current_Zone).w
	;beq.s	Level_WaterPal ; branch if level is HPZ
	;moveq	#PalID_CPZ_U,d0	; palette number $16
	;cmpi.b	#chemical_plant_zone,(Current_Zone).w
	;beq.s	Level_WaterPal ; branch if level is CPZ
	moveq	#PalID_ARZ_U,d0	; palette number $17
        bra.s    Level_WaterPal

LoadKnuxPal:
        moveq    #PalID_Knux,d0; Knuckles palette
        bsr.w    PalLoad1
	tst.b	(Water_flag).w	; does level have water?
	beq.s	Level_GetBgm	; if not, branch
	;moveq	#PalID_HPZ_U,d0	; palette number $15
	;cmpi.b	#hidden_palace_zone,(Current_Zone).w
	;beq.s	Level_WaterPal ; branch if level is HPZ
	;moveq	#PalID_CPZ_U,d0	; palette number $16
	;cmpi.b	#chemical_plant_zone,(Current_Zone).w
	;beq.s	Level_WaterPal ; branch if level is CPZ
	moveq	#PalID_ARZ_U,d0	; palette number $17
; loc_409E:
Level_WaterPal:
	bsr.w	PalLoad4_Water	; load underwater palette (with d0)
	tst.b	(Last_star_pole_hit).w ; is it the start of the level?
	beq.s	Level_GetBgm	; if yes, branch
	move.b	(Saved_Water_move).w,(Water_fullscreen_flag).w
; loc_40AE:
Level_GetBgm:
	tst.w	(Demo_mode_flag).w
	bmi.s	+
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	lea	MusicList(pc),a1
; loc_40C8:
Level_PlayBgm:
	move.b	(a1,d0.w),d0		; load from music playlist
	move.w	d0,(Level_Music).w	; store level music
	bsr.w	PlayMusic		; play level music
;	move.b	#ObjID_TitleCard,(TitleCard+id).w ; load Obj34 (level title card) at $FFFFB080
; loc_40DA:

;	move.w	(TitleCard_ZoneName+x_pos).w,d0
;	cmp.w	(TitleCard_ZoneName+titlecard_x_target).w,d0 ; has title card sequence finished?
;	bne.s	Level_TtlCard		; if not, branch

	move.b	#$C,(Vint_routine).w
	bsr.w	WaitForVint
	jsr	(Hud_Base).l
+
	bsr.w	LevelSizeLoad
	bsr.w	JmpTo_DeformBgLayer
	clr.w	(Vscroll_Factor).w
	move.w	#-$E0,($FFFFF61E).w

	clearRAM Horiz_Scroll_Buf,$400

	bsr.w	LoadZoneTiles
	bsr.w	JmpTo_loadZoneBlockMaps
	jsr	(loc_402D4).l
	bsr.w	JmpTo_loc_E300
	jsr	(FloorLog_Unk).l
	bsr.w	LoadCollisionIndexes
;	bsr.w	WaterEffects
	bsr.w	InitPlayers
	move.w	#0,(Ctrl_1_Logical).w
	move.w	#0,(Ctrl_2_Logical).w
	move.w	#0,(Ctrl_1).w
	move.w	#0,(Ctrl_2).w
	move.b	#1,(Control_Locked).w
	move.b	#1,($FFFFF7CF).w
	move.b	#0,(Level_started_flag).w
	tst.b	(Water_flag).w	; does level have water?
	beq.s	+	; if not, branch
	move.w	#objroutine(Water_Surface),(WaterSurface1+id).w ; load Water_Surface (water surface) at $FFFFB380
	move.w	#$60,(WaterSurface1+x_pos).w ; set horizontal offset
	move.w	#objroutine(Water_Surface),(WaterSurface2+id).w ; load Water_Surface (water surface) at $FFFFB3C0
	move.w	#$120,(WaterSurface2+x_pos).w ; set different horizontal offset
+
	cmpi.b	#chemical_plant_zone,(Current_Zone).w	; check if zone == CPZ
;	bne.s	+			; branch if not
;	move.b	#objroutine(Obj7C),(CPZPylon+id).w ; load Obj7C (CPZ pylon) at $FFFFB340
+
	cmpi.b	#oil_ocean_zone,(Current_Zone).w	; check if zone == OOZ
;	bne.s	Level_ClrHUD		; branch if not
;	move.b	#objroutine(Water_Surface),(Oil+id).w ; load Obj07 (OOZ oil) at $FFFFB380

Level_ClrHUD:
	moveq	#0,d0
	tst.b	(Last_star_pole_hit).w	; are you starting from a lamppost?
	bne.s	Level_FromCheckpoint	; if yes, branch
	move.w	d0,(Ring_count).w	; clear rings
	move.l	d0,(Timer).w		; clear time
	move.b	d0,(Extra_life_flags).w	; clear extra lives counter

Level_FromCheckpoint:
	move.b	d0,(Time_Over_flag).w
	move.b	d0,($FFFFFF4E).w
	move.w	d0,($FFFFFF4C).w
	move.w	d0,(Debug_placement_mode).w
	move.w	d0,(Level_Inactive_flag).w
	move.b	d0,(Teleport_timer).w
	move.b	d0,(Teleport_flag).w
	move.w	d0,(Rings_Collected).w
	move.w	d0,(Monitors_Broken).w
	move.w	d0,(Loser_Time_Left).w
	bsr.w	OscillateNumInit
	move.b	#1,(Update_HUD_score).w
	move.b	#1,(Update_HUD_rings).w
	move.b	#1,(Update_HUD_timer).w
	jsr	(ObjectsManager).l
	jsr	(RingsManager).l
	jsr	(SpecialCNZBumpers).l
	jsr	(RunObjects).l
	jsr	(BuildSprites).l
	bsr.w	JmpTo_loc_3FCC4
	bsr.w	SetLevelEndType
	move.w	#0,(Demo_button_index).w
	lea	(DemoScriptPointers).l,a1
	moveq	#0,d0
	move.b	(Current_Zone).w,d0	; load zone value
	lsl.w	#2,d0
	movea.l	(a1,d0.w),a1
	tst.w	(Demo_mode_flag).w
	bpl.s	+
	lea	(EndingDemoScriptPointers).l,a1
	move.w	(Ending_demo_number).w,d0
	subq.w	#1,d0
	lsl.w	#2,d0
	movea.l	(a1,d0.w),a1
+
	move.b	1(a1),(Demo_press_counter).w
	tst.b	(Current_Zone).w	; emerald_hill_zone
	bne.s	+
	lea	(Demo_EHZ_Tails).l,a1
	move.b	1(a1),(Demo_press_counter_2P).w
+
	move.w	#$668,(Demo_Time_left).w
	tst.w	(Demo_mode_flag).w
	bpl.s	+
	move.w	#$21C,(Demo_Time_left).w
	cmpi.w	#4,(Ending_demo_number).w
	bne.s	+
	move.w	#$1FE,(Demo_Time_left).w
+
	move.b	#0,(Control_Locked).w
	move.b	#0,($FFFFF7CF).w
	move.b	#1,(Level_started_flag).w
	bclr	#GameModeFlag_TitleCard,(Game_Mode).w ; clear $80 from the game mode
	jsr	(RunObjects).l
	jsr	(BuildSprites).l

Level_TtlCard:
	move.b	#$C,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.w	RunPLC_RAM
	tst.l	(Plc_Buffer).w			; are there any items in the pattern load cue?
	bne.s	Level_TtlCard			; if yes, branch

	move.b	#1,Dirty_flag			; set the redraw-screen flag
	bsr.w	LoadTilesAsYouMove		; redraw the entire screen
	bsr.w	WaterEffects
	bsr.w	JmpTo_DeformBgLayer
	bsr.w	UpdateWaterSurface
	jsr	AnimatedTiles
	bsr.w	JmpTo_loc_3FCC4
	bsr.w	PalCycle_Load
	bsr.w	OscillateNumDo
	bsr.w	ChangeRingFrame
	jsr	ObjectsManager
	jsr	RingsManager
	jsr	RunObjects
	jsr	BuildSprites
	bsr.w	Pal_FadeTo
	
;	cmp.b	#1,(Current_Zone).w
;	bgt.s	+
;	move.w	#$8B07,(VDP_control_port).l	; vertical deformation
+


; Level_StartGame: loc_435A:

; ---------------------------------------------------------------------------
; Main level loop (when all title card and loading sequences are finished)
; ---------------------------------------------------------------------------
; loc_4360:
Level_MainLoop:
	bsr.w	PauseGame
	move.b	#8,(Vint_routine).w
	bsr.w	WaitForVint
	addq.w	#1,(Timer_frames).w ; add 1 to level timer
	bsr.w	MoveSonicInDemo
	bsr.w	WaterEffects
	jsr		(RunObjects).l
	tst.w	(Level_Inactive_flag).w
	bne.w	Level
	bsr.w	JmpTo_DeformBgLayer
	bsr.w	UpdateWaterSurface
	jsr		(RingsManager).l
	jsr		AnimatedTiles
	cmpi.b	#casino_night_zone,(Current_Zone).w	; is it CNZ?
	bne.s	+			; if not, branch past jsr
	jsr	(SpecialCNZBumpers).l
+
	bsr.w	JmpTo_loc_3FCC4
	bsr.w	PalCycle_Load
	bsr.w	RunPLC_RAM
	bsr.w	OscillateNumDo
	bsr.w	ChangeRingFrame
	bsr.w	CheckLoadSignpostArt
	jsr	(BuildSprites).l
	jsr	(ObjectsManager).l
	cmpi.b	#GameModeID_Demo,(Game_Mode).w	; check if in demo mode
	beq.s	+
	cmpi.b	#GameModeID_Level,(Game_Mode).w	; check if in normal play mode
	beq.w	Level_MainLoop
	rts
; ---------------------------------------------------------------------------
+
	tst.w	(Level_Inactive_flag).w
	bne.s	+
	tst.w	(Demo_Time_left).w
	beq.s	+
	cmpi.b	#GameModeID_Demo,(Game_Mode).w
	beq.w	Level_MainLoop
	move.b	#GameModeID_SegaScreen,(Game_Mode).w ; => SegaScreen
	rts
; ---------------------------------------------------------------------------
+
	cmpi.b	#GameModeID_Demo,(Game_Mode).w
	bne.s	+
	move.b	#GameModeID_SegaScreen,(Game_Mode).w ; => SegaScreen
+
	move.w	#$3C,(Demo_Time_left).w
	move.w	#$3F,(Palette_fade_range).w
	clr.w	($FFFFF794).w
-
	move.b	#8,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.w	MoveSonicInDemo
	jsr	(RunObjects).l
	jsr	(BuildSprites).l
	jsr	(ObjectsManager).l
	subq.w	#1,($FFFFF794).w
	bpl.s	+
	move.w	#2,($FFFFF794).w
	bsr.w	Pal_FadeOut
+
	tst.w	(Demo_Time_left).w
	bne.s	-
	rts


; ---------------------------------------------------------------------------
; Subroutine to set the player mode, which is forced to Sonic and Tails in
; the demo mode and in 2P mode
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4450:
Level_SetPlayerMode:
	cmpi.b	#GameModeID_TitleCard|GameModeID_Demo,(Game_Mode).w ; pre-level demo mode?
	beq.s	+			; if yes, branch
	move.w	(Player_option).w,(Player_mode).w ; use the option chosen in the Options screen
	rts
; ---------------------------------------------------------------------------
+	move.w	#0,(Player_mode).w	; force Sonic and Tails
	rts
; End of function Level_SetPlayerMode


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_446E:
InitPlayers:
	move.w	(Player_mode).w,d0
	bne.s	InitPlayers_Alone ; branch if this isn't a Sonic and Tails game

	move.w	#objroutine(Sonic),(MainCharacter+id).w ; load Sonic Sonic object at $FFFFB000
	move.w	#objroutine(Water_Splash_Object),(Sonic_Dust+id).w ; load Water_Splash_Object Sonic's spindash dust/splash object at $FFFFD100
	cmpi.b	#1,(Current_Zone).w
	beq.s	+ ; skip loading Tails if this is WFZ
	cmpi.b	#wing_fortress_zone,(Current_Zone).w
	beq.s	+ ; skip loading Tails if this is WFZ
	cmpi.b	#death_egg_zone,(Current_Zone).w
	beq.s	+ ; skip loading Tails if this is DEZ
	cmpi.b	#sky_chase_zone,(Current_Zone).w
	beq.s	+ ; skip loading Tails if this is SCZ

	move.w	#objroutine(Tails),(Sidekick+id).w ; load Tails Tails object at $FFFFB040
	move.w	(MainCharacter+x_pos).w,(Sidekick+x_pos).w
	move.w	(MainCharacter+y_pos).w,(Sidekick+y_pos).w
	subi.w	#$20,(Sidekick+x_pos).w
	addi.w	#4,(Sidekick+y_pos).w
	move.w	#objroutine(Water_Splash_Object),(Tails_Dust+id).w ; load Water_Splash_Object Tails' spindash dust/splash object at $FFFFD140
+
	rts
; ===========================================================================
; loc_44BE:
InitPlayers_Alone: ; either Sonic or Tails but not both
	subq.w	#1,d0
	bne.s	InitPlayers_TailsAlone ; branch if this is a Tails alone game

	move.w	#objroutine(Sonic),(MainCharacter+id).w ; load Sonic Sonic object at $FFFFB000
	move.w	#objroutine(Water_Splash_Object),(Sonic_Dust+id).w ; load Water_Splash_Object Sonic's spindash dust/splash object at $FFFFD100
	rts
; ===========================================================================
; loc_44D0:
InitPlayers_TailsAlone:
    subq.w    #1,d0
    bne.s     InitPlayers_KnuxAlone
    move.w    #objroutine(Tails),(MainCharacter).w; load Tails Tails object at $FFFFB000
    move.w    #objroutine(Water_Splash_Object),(Tails_Dust).w; load Water_Splash_Object Tails' spindash dust/splash object at $FFFFD100
    addi.w    #4,(MainCharacter+y_pos).w
    rts

InitPlayers_KnuxAlone:
    move.w    #objroutine(Knuckles),($FFFFB000).w
    move.w    #objroutine(Water_Splash_Object),($FFFFD100).w
    rts

; End of function InitPlayers





; ---------------------------------------------------------------------------
; Subroutine to move the water or oil surface sprites to where the screen is at
; (the closest match I could find to this subroutine in Sonic 1 is Obj1B_Action)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_44E4:
UpdateWaterSurface:
	tst.b	(Water_flag).w
	beq.s	++	; rts
	move.w	(Camera_X_pos).w,d1
	btst	#0,(Timer_frames+1).w
	beq.s	+
	addi.w	#$20,d1
+		; match obj x-position to screen position
	move.w	d1,d0
	addi.w	#$60,d0
	move.w	d0,(WaterSurface1+x_pos).w
	addi.w	#$120,d1
	move.w	d1,(WaterSurface2+x_pos).w
+
	rts
; End of function UpdateWaterSurface


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; ---------------------------------------------------------------------------
; Subroutine to do special water effects
; ---------------------------------------------------------------------------
; sub_450E: ; LZWaterEffects:
WaterEffects:
	tst.b	(Current_Zone).w	; is the level EHZ?
	bne.s	NoHIntEffects
	move.w	#$130,d2		; position at which the palette changes
	sub.w	(Camera_Y_pos).w,d2
	bcc.s	HIntEffect_Above
	tst.w	d2
	bpl.s	HIntEffect_Above
	move.b	#$DF,(Hint_counter_reserve+1).w
	tst.b	(Water_fullscreen_flag).w
	beq.s	HIntEffect_NoPal
	moveq	#PalID_EHZ_U,d0	; normal underwater palette
	bsr.w	PalLoad3_Water
HIntEffect_NoPal:
	;clr.b	(Water_fullscreen_flag).w	; already done
	move.b	#$DF,(Hint_counter_reserve+1).w
	bra.s	NoHIntEffects

HIntEffect_Above:
	tst.b	(Water_fullscreen_flag).w
	bne.s	+
	moveq	#PalID_EHZ_Top,d0	; top level palette
	bsr.w	PalLoad3_Water
+
	move.b	#1,(Water_fullscreen_flag).w
	cmpi.w	#$DF,d2
	blo.s	+
	move.w	#$DF,d2
+
	move.b	d2,(Hint_counter_reserve+1).w
	bra.s	NonWaterEffects

NoHIntEffects:
	clr.b	(Water_fullscreen_flag).w
	tst.b	(Water_flag).w
	beq.w	NonWaterEffects
	tst.b	(Deform_lock).w
	bne.s	MoveWater
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	NoHIntEffects_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	MoveWater	
	move.w	NoHIntEffects_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	MoveWater
	move.w	NoHIntEffects_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	MoveWater		
	bsr.w	DynamicWater
; loc_4526: ; LZMoveWater:
MoveWater:
	moveq	#0,d0
;	cmpi.b	#aquatic_ruin_zone,(Current_Zone).w	; is level ARZ?
;	beq.s	+		; if yes, branch
	move.b	($FFFFFE60).w,d0
	lsr.w	#1,d0
+
	add.w	(Water_Level_2).w,d0
	move.w	d0,(Water_Level_1).w
	move.w	(Water_Level_1).w,d0
	sub.w	(Camera_Y_pos).w,d0
	bcc.s	+
	tst.w	d0
	bpl.s	+
	move.b	#$DF,(Hint_counter_reserve+1).w
	move.b	#1,(Water_fullscreen_flag).w
+
	cmpi.w	#$DF,d0
	blo.s	+
	move.w	#$DF,d0
+
	move.b	d0,(Hint_counter_reserve+1).w
; loc_456A:
NonWaterEffects:
	cmpi.b	#oil_ocean_zone,(Current_Zone).w	; is the level OOZ?
	bne.s	+			; if not, branch
	bsr.w	OilSlides		; call oil slide routine
+
	cmpi.b	#wing_fortress_zone,(Current_Zone).w	; is the level WFZ?
	bne.s	+			; if not, branch
	bsr.w	WindTunnel		; call wind and block break routine
+
	rts
; End of function WaterEffects
NoHIntEffects_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

NoHIntEffects_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

NoHIntEffects_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)	
; ===========================================================================
    if useFullWaterTables
WaterHeight: zoneOffsetTable 2,2
	zoneTableEntry.w  $600, $600	; EHZ
	zoneTableEntry.w  $600, $600	; Zone 1
	zoneTableEntry.w  $600, $600	; WZ
	zoneTableEntry.w  $600, $600	; Zone 3
	zoneTableEntry.w  $600, $600	; MTZ
	zoneTableEntry.w  $600, $600	; MTZ
	zoneTableEntry.w  $600, $600	; WFZ
	zoneTableEntry.w  $600, $600	; HTZ
	zoneTableEntry.w  $600, $600	; HPZ
	zoneTableEntry.w  $600, $600	; Zone 9
	zoneTableEntry.w  $600, $600	; OOZ
	zoneTableEntry.w  $600, $600	; MCZ
	zoneTableEntry.w  $600, $600	; CNZ
	zoneTableEntry.w  $600, $710	; CPZ
	zoneTableEntry.w  $600, $600	; DEZ
	zoneTableEntry.w  $410, $510	; ARZ
	zoneTableEntry.w  $600, $600	; SCZ
    zoneTableEnd
    else
; word_4584:
WaterHeight:
	dc.w  $600, $600	; HPZ
	dc.w  $600, $600	; Zone 9
	dc.w  $600, $600	; OOZ
	dc.w  $600, $600	; MCZ
	dc.w  $600, $600	; CNZ
	dc.w  $600, $710	; CPZ
	dc.w  $600, $600	; DEZ
	dc.w  $410, $510	; ARZ
    endif

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_45A4: ; LZDynamicWater:
DynamicWater:
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; Equates:
windtunnel_min_x_pos	= 0
windtunnel_max_x_pos	= 4
windtunnel_min_y_pos	= 2
windtunnel_max_y_pos	= 6

; sub_460A:
WindTunnel:
	tst.w	(Debug_placement_mode).w
	bne.w	WindTunnel_End	; don't interact with wind tunnels while in debug mode
	lea	(WindTunnelsCoordinates).l,a2
	moveq	#(WindTunnelsCoordinates_End-WindTunnelsCoordinates)/8-1,d1
	lea	(MainCharacter).w,a1 ; a1=character
-	; check for current wind tunnel if the main character is inside it
	move.w	x_pos(a1),d0
	cmp.w	windtunnel_min_x_pos(a2),d0
	blo.w	WindTunnel_Leave	; branch, if main character is too far left
	cmp.w	windtunnel_max_x_pos(a2),d0
	bhs.w	WindTunnel_Leave	; branch, if main character is too far right
	move.w	y_pos(a1),d2
	cmp.w	windtunnel_min_y_pos(a2),d2
	blo.w	WindTunnel_Leave	; branch, if main character is too far up
	cmp.w	windtunnel_max_y_pos(a2),d2
	bhs.w	WindTunnel_Leave	; branch, if main character is too far down
	tst.b	($FFFFF7C9).w
	bne.w	WindTunnel_End
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	WindTunnel_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	WindTunnel_LeaveHurt	
	move.w	WindTunnel_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	WindTunnel_LeaveHurt
	move.w	WindTunnel_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	WindTunnel_LeaveHurt	
	move.w	WindTunnel_Check4(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	WindTunnel_LeaveHurt		
	move.b	#1,(WindTunnel_flag).w	; affects character animation and bubble movement
	subi.w	#4,x_pos(a1)	; move main character to the left
	move.w	#-$400,x_vel(a1)
	move.w	#0,y_vel(a1)
	move.b	#$F,anim(a1)
	bset	#1,status(a1)	; set "in-air" bit
	btst	#button_up,(Ctrl_1_Held).w	; is Up being pressed?
	beq.s	+				; if not, branch
	subq.w	#1,y_pos(a1)	; move up
+
	btst	#button_down,(Ctrl_1_Held).w	; is Down being pressed?
	beq.s	+				; if not, branch
	addq.w	#1,y_pos(a1)	; move down
+
	rts
	
WindTunnel_Check:
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Tails_Hurt)
		dc.w	objroutine(Knuckles_Hurt)
	
WindTunnel_Check2:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

WindTunnel_Check3:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

WindTunnel_Check4:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)		
; ===========================================================================
; loc_4690:
WindTunnel_Leave:
	addq.w	#8,a2
	dbf	d1,-	; check next tunnel
	; when all wind tunnels have been checked
	tst.b	(WindTunnel_flag).w
	beq.s	WindTunnel_End
	move.b	#0,anim(a1)
; loc_46A2:
WindTunnel_LeaveHurt:	; the main character is hurt or dying, leave the tunnel and don't check the other
	clr.b	(WindTunnel_flag).w
; return_46A6:
WindTunnel_End:
	rts
; End of function WindTunnel

; ===========================================================================
; word_46A8:
WindTunnelsCoordinates:
	dc.w $1510,$400,$1AF0,$580
	dc.w $20F0,$618,$2500,$680
WindTunnelsCoordinates_End:

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_46B8:
OilSlides:
	lea	(MainCharacter).w,a1 ; a1=character
	move.b	(Ctrl_1_Held_Logical).w,d2
	bsr.s	+
	lea	(Sidekick).w,a1 ; a1=character
	move.b	(Ctrl_2_Held_Logical).w,d2
+
	btst	#1,status(a1)
	bne.s	+
	move.w	y_pos(a1),d0
	add.w	d0,d0
	andi.w	#$F00,d0
	move.w	x_pos(a1),d1
	lsr.w	#7,d1
	andi.w	#$7F,d1
	add.w	d1,d0
	move.l	(LevelUncLayout).l,a2
	move.b	(a2,d0.w),d0
	lea	OilSlides_Chunks_End(pc),a2

	moveq	#OilSlides_Chunks_End-OilSlides_Chunks-1,d1
-	cmp.b	-(a2),d0
	dbeq	d1,-

	beq.s	loc_4712
+
	tst.b	status2(a1)
	bpl.s	+	; rts
	move.w	#5,move_lock(a1)
	andi.b	#$7F,status2(a1)
+	rts
; ===========================================================================

loc_4712:
	lea	(byte_47DE).l,a2
	move.b	(a2,d1.w),d0
	beq.s	loc_476E
	move.b	inertia(a1),d1
	tst.b	d0
	bpl.s	+
	cmp.b	d0,d1
	ble.s	++
	subi.w	#$40,inertia(a1)
	bra.s	++
; ===========================================================================
+
	cmp.b	d0,d1
	bge.s	+
	addi.w	#$40,inertia(a1)
+
	bclr	#0,status(a1)
	tst.b	d1
	bpl.s	+
	bset	#0,status(a1)
+
	move.b	#$1B,anim(a1)
	ori.b	#$80,status2(a1)
	move.b	(Vint_runcount+3).w,d0
	andi.b	#$1F,d0
	bne.s	+	; rts
	move.w	#SndID_OilSlide,d0
	jsr	(PlaySound).l
+
	rts
; ===========================================================================

loc_476E:
	move.w	#4,d1
	move.w	inertia(a1),d0
	btst	#button_left,d2
	beq.s	+
	move.b	#0,anim(a1)
	bset	#0,status(a1)
	sub.w	d1,d0
	tst.w	d0
	bpl.s	+
	sub.w	d1,d0
+
	btst	#button_right,d2
	beq.s	+
	move.b	#0,anim(a1)
	bclr	#0,status(a1)
	add.w	d1,d0
	tst.w	d0
	bmi.s	+
	add.w	d1,d0
+
	move.w	#4,d1
	tst.w	d0
	beq.s	+++
	bmi.s	++
	sub.w	d1,d0
	bhi.s	+
	move.w	#0,d0
	move.b	#5,anim(a1)
+	bra.s	++
; ===========================================================================
+
	add.w	d1,d0
	bhi.s	+
	move.w	#0,d0
	move.b	#5,anim(a1)
+
	move.w	d0,inertia(a1)
	ori.b	#$80,status2(a1)
	rts
; End of function OilSlides

; ===========================================================================
byte_47DE:
	dc.b  -8, -8, -8,  8,  8,  0,  0,  0, -8, -8,  0,  8,  8,  8,  0,  8
	dc.b   8,  8,  0, -8,  0,  0, -8,  8, -8, -8, -8,  8,  8,  8, -8, -8 ; 16

; These are the IDs of the chunks where Sonic and Tails will slide
OilSlides_Chunks:
	dc.b $2F,$30,$31,$33,$35,$38,$3A,$3C,$63,$64,$83,$90,$91,$93,$A1,$A3
	dc.b $BD,$C7,$C8,$CE,$D7,$D8,$E6,$EB,$EC,$ED,$F1,$F2,$F3,$F4,$FA,$FD ; 16
OilSlides_Chunks_End:
	even

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_481E:
MoveSonicInDemo:
	tst.w	(Demo_mode_flag).w	; is demo mode on?
	bne.w	MoveDemo_On	; if yes, branch
	rts

; loc_48AA:
MoveDemo_On:
	move.b	(Ctrl_1_Press).w,d0
	or.b	(Ctrl_2_Press).w,d0
	andi.b	#button_start_mask,d0
	beq.s	+
	tst.w	(Demo_mode_flag).w
	bmi.s	+
	move.b	#GameModeID_TitleScreen,(Game_Mode).w ; => TitleScreen
+
	lea	(DemoScriptPointers).l,a1 ; load pointer to input data
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
; loc_48DA:
MoveDemo_On_P1:
	lsl.w	#2,d0
	movea.l	(a1,d0.w),a1

	move.w	(Demo_button_index).w,d0
	adda.w	d0,a1	; a1 now points to the current button press data
	move.b	(a1),d0	; load button press
	lea	(Ctrl_1_Held).w,a0
	move.b	d0,d1
	moveq	#0,d2 ; this was modified from (a0) to #0 in Rev01 of Sonic 1 to nullify the following line
	eor.b	d2,d0	; does nothing now (used to let you hold a button to prevent Sonic from jumping in demos)
	move.b	d1,(a0)+ ; save button press data from demo to Ctrl_1_Held
	and.b	d1,d0	; does nothing now
	move.b	d0,(a0)+ ; save the same thing to Ctrl_1_Press
	subq.b	#1,(Demo_press_counter).w  ; decrement counter until next press
	bcc.s	MoveDemo_On_P2	   ; if it isn't 0 yet, branch
	move.b	3(a1),(Demo_press_counter).w ; reset counter to length of next press
	addq.w	#2,(Demo_button_index).w ; advance to next button press
; loc_4908:
MoveDemo_On_P2:
    if emerald_hill_zone_act_1<$100 ; will it fit within a byte?
	cmpi.b	#emerald_hill_zone_act_1,(Current_Zone).w
    else
	cmpi.w #emerald_hill_zone_act_1,(Current_ZoneAndAct).w ; avoid a range overflow error
    endif
	bne.s	MoveDemo_On_SkipP2 ; if it's not the EHZ demo, branch to skip player 2
	lea	(Demo_EHZ_Tails).l,a1

	; same as the corresponding remainder of MoveDemo_On_P1, but for player 2
	move.w	(Demo_button_index_2P).w,d0
	adda.w	d0,a1
	move.b	(a1),d0
	lea	(Ctrl_2_Held).w,a0
	move.b	d0,d1
	moveq	#0,d2
	eor.b	d2,d0
	move.b	d1,(a0)+
	and.b	d1,d0
	move.b	d0,(a0)+
	subq.b	#1,(Demo_press_counter_2P).w
	bcc.s	+	; rts
	move.b	3(a1),(Demo_press_counter_2P).w
	addq.w	#2,(Demo_button_index_2P).w
+
	rts
; ===========================================================================
; loc_4940:
MoveDemo_On_SkipP2:
	move.w	#0,(Ctrl_2).w
	rts
; End of function MoveSonicInDemo

; ===========================================================================
; ---------------------------------------------------------------------------
; DEMO SCRIPT POINTERS

; Contains an array of pointers to the script controlling the players actions
; to use for each level.
; ---------------------------------------------------------------------------
; off_4948:
DemoScriptPointers: zoneOffsetTable 4,1
	zoneTableEntry.l Demo_EHZ	; $00
	zoneTableEntry.l Demo_EHZ	; $01
	zoneTableEntry.l Demo_EHZ	; $02
	zoneTableEntry.l Demo_EHZ	; $03
	zoneTableEntry.l Demo_EHZ	; $04
	zoneTableEntry.l Demo_EHZ	; $05
	zoneTableEntry.l Demo_EHZ	; $06
	zoneTableEntry.l Demo_EHZ	; $07
	zoneTableEntry.l Demo_EHZ	; $08
	zoneTableEntry.l Demo_EHZ	; $09
	zoneTableEntry.l Demo_EHZ	; $0A
	zoneTableEntry.l Demo_EHZ	; $0B
	zoneTableEntry.l Demo_CNZ	; $0C
	zoneTableEntry.l Demo_CPZ	; $0D
	zoneTableEntry.l Demo_EHZ	; $0E
	zoneTableEntry.l Demo_ARZ	; $0F
	zoneTableEntry.l Demo_EHZ	; $10
    zoneTableEnd
; ---------------------------------------------------------------------------
; dword_498C:
EndingDemoScriptPointers:
	; these values are invalid addresses, but they were used for the ending
	; demos, which aren't present in Sonic 2
	dc.l   $8B0837
	dc.l   $42085C	; 1
	dc.l   $6A085F	; 2
	dc.l   $2F082C	; 3
	dc.l   $210803	; 4
	dc.l $28300808	; 5
	dc.l   $2E0815	; 6
	dc.l	$F0846	; 7
	dc.l   $1A08FF	; 8
	dc.l  $8CA0000	; 9
	dc.l	     0	; 10
	dc.l	     0	; 11




; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_49BC:
LoadCollisionIndexes:
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	lsl.w	#2,d0
	move.l	#Primary_Collision,(Collision_addr).w
	move.w	d0,-(sp)
	movea.l	Off_ColP(pc,d0.w),a0
	lea	(Primary_Collision).w,a1
	bsr.w	KosDec
	move.w	(sp)+,d0
	movea.l	Off_ColS(pc,d0.w),a0
	lea	(Secondary_Collision).w,a1
	bra.w	KosDec
; End of function LoadCollisionIndexes

; ===========================================================================
	Include	"code/Levels/Primary and Secondary Collision List.asm"
	even


; ---------------------------------------------------------------------------
; Oscillating number subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4A70:
OscillateNumInit:
	lea	($FFFFFE5E).w,a1
	lea	(Osc_Data).l,a2
	moveq	#(Osc_Data_End-Osc_Data)/2-1,d1
; loc_4A7C:
Osc_Loop:
	move.w	(a2)+,(a1)+
	dbf	d1,Osc_Loop
	rts
; End of function OscillateNumInit

; ===========================================================================
; word_4A84:
Osc_Data:
	dc.w   $7D, $80	; baseline values
	dc.w	 0, $80
	dc.w	 0, $80
	dc.w	 0, $80
	dc.w	 0, $80
	dc.w	 0, $80
	dc.w	 0, $80
	dc.w	 0, $80
	dc.w	 0, $80
	dc.w	 0, $3848
	dc.w   $EE, $2080
	dc.w   $B4, $3080
	dc.w  $10E, $5080
	dc.w  $1C2, $7080
	dc.w  $276, $80
	dc.w	 0, $4000
	dc.w   $FE
Osc_Data_End:

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4AC6:
OscillateNumDo:
	tst.w	(Two_player_mode).w
	bne.s	+
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	OscillateNumDo_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	OscillateNumDo_Return	
	move.w	OscillateNumDo_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	OscillateNumDo_Return
	move.w	OscillateNumDo_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	OscillateNumDo_Return
+	lea	($FFFFFE5E).w,a1
	lea	(Osc_Data2).l,a2
	move.w	(a1)+,d3

	moveq	#(Osc_Data2_End-Osc_Data2)/4-1,d1
-	move.w	(a2)+,d2
	move.w	(a2)+,d4
	btst	d1,d3
	bne.s	+
	move.w	2(a1),d0
	add.w	d2,d0
	move.w	d0,2(a1)
	_add.w	d0,0(a1)
	_cmp.b	0(a1),d4
	bhi.s	++
	bset	d1,d3
	bra.s	++
; ===========================================================================
+
	move.w	2(a1),d0
	sub.w	d2,d0
	move.w	d0,2(a1)
	_add.w	d0,0(a1)
	_cmp.b	0(a1),d4
	bls.s	+
	bclr	d1,d3
+
	addq.w	#4,a1
	dbf	d1,-

	move.w	d3,($FFFFFE5E).w
; return_4B22:
OscillateNumDo_Return:
	rts
	
OscillateNumDo_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

OscillateNumDo_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

OscillateNumDo_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)	
; End of function OscillateNumDo

; ===========================================================================
; word_4B24:
Osc_Data2:
	dc.w	 2, $10
	dc.w	 2, $18
	dc.w	 2, $20
	dc.w	 2, $30
	dc.w	 4, $20
	dc.w	 8,   8
	dc.w	 8, $40
	dc.w	 4, $40
	dc.w	 2, $38
	dc.w	 2, $38
	dc.w	 2, $20
	dc.w	 3, $30
	dc.w	 5, $50
	dc.w	 7, $70
	dc.w	 2, $40
	dc.w	 2, $40
Osc_Data2_End:



; ---------------------------------------------------------------------------
; Subroutine to change global object animation variables (like rings)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4B64:
ChangeRingFrame:
	subq.b	#1,(Logspike_anim_counter).w
	bpl.s	+
	move.b	#$B,(Logspike_anim_counter).w
	subq.b	#1,(Logspike_anim_frame).w ; animate unused log spikes
	andi.b	#7,(Logspike_anim_frame).w
+
	subq.b	#1,(Rings_anim_counter).w
	bpl.s	+
	move.b	#7,(Rings_anim_counter).w
	addq.b	#1,(Rings_anim_frame).w ; animate rings in the level (Basic_Ring)
	andi.b	#3,(Rings_anim_frame).w
+
	subq.b	#1,(Unknown_anim_counter).w
	bpl.s	+
	move.b	#7,(Unknown_anim_counter).w
	addq.b	#1,(Unknown_anim_frame).w ; animate nothing (deleted special stage object is my best guess)
	cmpi.b	#6,(Unknown_anim_frame).w
	blo.s	+
	move.b	#0,(Unknown_anim_frame).w
+
	tst.b	(Ring_spill_anim_counter).w
	beq.s	+	; rts
	moveq	#0,d0
	move.b	(Ring_spill_anim_counter).w,d0
	add.w	(Ring_spill_anim_accum).w,d0
	move.w	d0,(Ring_spill_anim_accum).w
	rol.w	#7,d0
	andi.w	#3,d0
	move.b	d0,(Ring_spill_anim_frame).w ; animate scattered rings (Hurt_Rings)
	subq.b	#1,(Ring_spill_anim_counter).w
+
	rts
; End of function ChangeRingFrame




; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

nosignpost macro actid
	cmpi.w	#actid,(Current_ZoneAndAct).w
	beq.ATTRIBUTE	+	; rts
    endm

; sub_4BD2:
SetLevelEndType:
	move.w	#0,(Level_Has_Signpost).w	; set level type to non-signpost
	tst.w	(Two_player_mode).w	; is it two-player competitive mode?
	bne.s	LevelEnd_SetSignpost	; if yes, branch
	nosignpost.w emerald_hill_zone_act_2
	nosignpost.w metropolis_zone_act_3
	nosignpost.w wing_fortress_zone_act_1
	nosignpost.w hill_top_zone_act_2
	nosignpost.w oil_ocean_zone_act_2
	nosignpost.s mystic_cave_zone_act_2
	nosignpost.s casino_night_zone_act_2
	nosignpost.s chemical_plant_zone_act_2
	nosignpost.s death_egg_zone_act_1
	nosignpost.s aquatic_ruin_zone_act_2
	nosignpost.s sky_chase_zone_act_1

; loc_4C40:
LevelEnd_SetSignpost:
	move.w	#1,(Level_Has_Signpost).w	; set level type to signpost
+	rts
; End of function SetLevelEndType


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4C48:
CheckLoadSignpostArt:
	tst.w	(Level_Has_Signpost).w
	beq.s	+	; rts
	move.w	(Camera_X_pos).w,d0
	move.w	(Camera_Max_X_pos).w,d1
	subi.w	#$100,d1
	cmp.w	d0,d1
	blt.s	+
	moveq	#PLCID_Signpost,d0 ; <== PLC_1F
	bra.w	LoadPLC2		; load signpost art
; ---------------------------------------------------------------------------
+
	rts



; ===========================================================================
; macro to simply editing the demo scripts
demoinput macro buttons,duration
btns_mask := 0
idx := 0
  rept strlen("buttons")
btn := substr("buttons",idx,1)
    switch btn
    case "U"
btns_mask := btns_mask|button_up_mask
    case "D"
btns_mask := btns_mask|button_down_mask
    case "L"
btns_mask := btns_mask|button_left_mask
    case "R"
btns_mask := btns_mask|button_right_mask
    case "A"
btns_mask := btns_mask|button_A_mask
    case "B"
btns_mask := btns_mask|button_B_mask
    case "C"
btns_mask := btns_mask|button_C_mask
    case "S"
btns_mask := btns_mask|button_start_mask
    endcase
idx := idx+1
  endm
	dc.b	btns_mask,duration-1
 endm
; ---------------------------------------------------------------------------
; EHZ Demo Script (Sonic)
; ---------------------------------------------------------------------------
; byte_4CA8: Demo_Def:
Demo_EHZ:
	demoinput ,	$4C
	demoinput R,	$43
	demoinput RC,	9
	demoinput R,	$3F
	demoinput RC,	6
	demoinput R,	$B0
	demoinput RC,	$A
	demoinput R,	$46
	demoinput ,	$1E
	demoinput L,	$F
	demoinput ,	5
	demoinput L,	5
	demoinput ,	9
	demoinput L,	$3F
	demoinput ,	5
	demoinput R,	$67
	demoinput ,	$62
	demoinput R,	$12
	demoinput ,	$22
	demoinput D,	8
	demoinput DC,	7
	demoinput D,	$E
	demoinput ,	$3C
	demoinput R,	$A
	demoinput ,	$1E
	demoinput D,	7
	demoinput DC,	7
	demoinput D,	2
	demoinput ,	$F
	demoinput R,	$100
	demoinput R,	$2F
	demoinput ,	$23
	demoinput C,	8
	demoinput RC,	$10
	demoinput R,	3
	demoinput ,	$30
	demoinput RC,	$24
	demoinput R,	$BE
	demoinput ,	$C
	demoinput L,	$14
	demoinput ,	$17
	demoinput D,	3
	demoinput DC,	7
	demoinput D,	3
	demoinput ,	$64
	demoinput S,	1
	demoinput A,	1
	demoinput ,	1
; ---------------------------------------------------------------------------
; EHZ Demo Script (Tails)
; ---------------------------------------------------------------------------
; byte_4D08:
Demo_EHZ_Tails:
	demoinput ,	$3C
	demoinput R,	$10
	demoinput UR,	$44
	demoinput URC,	$7
	demoinput UR,	$7
	demoinput R,	$CA
	demoinput ,	$12
	demoinput R,	$2
	demoinput RC,	$9
	demoinput R,	$53
	demoinput ,	$12
	demoinput R,	$B
	demoinput RC,	$F
	demoinput R,	$24
	demoinput ,	$B
	demoinput C,	$5
	demoinput ,	$E
	demoinput R,	$56
	demoinput ,	$1F
	demoinput R,	$5B
	demoinput ,	$11
	demoinput R,	$100
	demoinput R,	$C1
	demoinput ,	$21
	demoinput L,	$E
	demoinput ,	$E
	demoinput C,	$5
	demoinput RC,	$10
	demoinput C,	$6
	demoinput ,	$D
	demoinput L,	$6
	demoinput ,	$5F
	demoinput R,	$74
	demoinput ,	$19
	demoinput L,	$45
	demoinput ,	$9
	demoinput D,	$31
	demoinput ,	$9
	demoinput R,	$E
	demoinput ,	$24
	demoinput R,	$28
	demoinput ,	$5
	demoinput R,	$1
	demoinput ,	$1
	demoinput ,	$1
	demoinput ,	$1
	demoinput ,	$1
	demoinput ,	$1
; ---------------------------------------------------------------------------
; CNZ Demo Script
; ---------------------------------------------------------------------------
Demo_CNZ:
	demoinput ,	$49
	demoinput R,	$11
	demoinput UR,	1
	demoinput R,	2
	demoinput UR,	7
	demoinput R,	$61
	demoinput RC,	6
	demoinput C,	2
	demoinput ,	9
	demoinput L,	3
	demoinput DL,	4
	demoinput L,	2
	demoinput ,	$1A
	demoinput R,	$12
	demoinput RC,	$1A
	demoinput C,	5
	demoinput RC,	$24
	demoinput R,	$1B
	demoinput ,	8
	demoinput L,	$11
	demoinput ,	$F
	demoinput R,	$78
	demoinput RC,	$17
	demoinput C,	1
	demoinput ,	$10
	demoinput L,	$12
	demoinput ,	8
	demoinput R,	$53
	demoinput ,	$70
	demoinput R,	$75
	demoinput ,	$38
	demoinput R,	$17
	demoinput ,	5
	demoinput L,	$27
	demoinput ,	$D
	demoinput L,	$13
	demoinput ,	$6A
	demoinput C,	$11
	demoinput RC,	3
	demoinput DRC,	6
	demoinput DR,	$15
	demoinput R,	6
	demoinput ,	6
	demoinput L,	$D
	demoinput ,	$49
	demoinput L,	$A
	demoinput ,	$1F
	demoinput R,	7
	demoinput ,	$30
	demoinput L,	2
	demoinput ,	$100
	demoinput ,	$50
	demoinput R,	1
	demoinput RC,	$C
	demoinput R,	$2B
	demoinput ,	$5F
; ---------------------------------------------------------------------------
; CPZ Demo Script
; ---------------------------------------------------------------------------
Demo_CPZ:
	demoinput ,	$47
	demoinput R,	$1C
	demoinput RC,	8
	demoinput R,	$A
	demoinput ,	$1C
	demoinput R,	$E
	demoinput RC,	$29
	demoinput R,	$100
	demoinput R,	$E8
	demoinput DR,	5
	demoinput D,	2
	demoinput L,	$34
	demoinput DL,	$68
	demoinput L,	1
	demoinput ,	$16
	demoinput C,	1
	demoinput LC,	8
	demoinput L,	$F
	demoinput ,	$18
	demoinput R,	2
	demoinput DR,	2
	demoinput R,	$D
	demoinput ,	$20
	demoinput RC,	7
	demoinput R,	$B
	demoinput ,	$1C
	demoinput L,	$E
	demoinput ,	$1D
	demoinput L,	7
	demoinput ,	$100
	demoinput ,	$E0
	demoinput R,	$F
	demoinput ,	$1D
	demoinput L,	3
	demoinput ,	$26
	demoinput R,	7
	demoinput ,	7
	demoinput C,	5
	demoinput ,	$29
	demoinput L,	$12
	demoinput ,	$18
	demoinput R,	$1A
	demoinput ,	$11
	demoinput L,	$2E
	demoinput ,	$14
	demoinput S,	1
	demoinput A,	1
	demoinput ,	1
; ---------------------------------------------------------------------------
; ARZ Demo Script
; ---------------------------------------------------------------------------
Demo_ARZ:
	demoinput ,	$43
	demoinput R,	$4B
	demoinput RC,	9
	demoinput R,	$50
	demoinput RC,	$C
	demoinput R,	6
	demoinput ,	$1B
	demoinput R,	$61
	demoinput RC,	$15
	demoinput R,	$55
	demoinput ,	$41
	demoinput R,	5
	demoinput UR,	1
	demoinput R,	$5C
	demoinput ,	$47
	demoinput R,	$3C
	demoinput RC,	9
	demoinput R,	$28
	demoinput ,	$B
	demoinput R,	$93
	demoinput RC,	$33
	demoinput R,	$23
	demoinput ,	$23
	demoinput R,	$4D
	demoinput ,	$1F
	demoinput L,	2
	demoinput UL,	3
	demoinput L,	1
	demoinput ,	$B
	demoinput L,	$D
	demoinput ,	$11
	demoinput R,	6
	demoinput ,	$62
	demoinput R,	4
	demoinput RC,	6
	demoinput R,	$17
	demoinput ,	$1C
	demoinput R,	$57
	demoinput RC,	$B
	demoinput R,	$17
	demoinput ,	$16
	demoinput R,	$D
	demoinput ,	$2C
	demoinput C,	2
	demoinput RC,	$1B
	demoinput R,	$83
	demoinput ,	$C
	demoinput S,	1

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||



;sub_4E98:
LoadZoneTiles:
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	add.w	d0,d0
	add.w	d0,d0
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0
	lea		(LevelArtPointers).l,a2
	lea		(a2,d0.w),a2
	move.l	(a2)+,d0
	andi.l	#$FFFFFF,d0	; 8x8 tile pointer
	movea.l	d0,a0
	lea		(Chunk_Table).l,a1
	bsr.w	KosDec
	move.w	a1,d3
+	move.w	d3,d7
	andi.w	#$FFF,d3
	lsr.w	#1,d3
	rol.w	#4,d7
	andi.w	#$F,d7

-	move.w	d7,d2
	lsl.w	#7,d2
	lsl.w	#5,d2
	move.l	#$FFFFFF,d1
	move.w	d2,d1
	jsr		(QueueDMATransfer).l
	move.w	d7,-(sp)
	move.b	#$C,(Vint_routine).w
	bsr.w	WaitForVint
	bsr.w	RunPLC_RAM
	move.w	(sp)+,d7
	move.w	#$800,d3
	dbf	d7,-

	rts
; End of function LoadZoneTiles
; ===========================================================================

JmpTo_loadZoneBlockMaps
	jmp	(loadZoneBlockMaps).l

JmpTo_DeformBgLayer
	jmp	(DeformBgLayer).l

JmpTo_loc_3FCC4
	jmp	(loc_3FCC4).l

JmpTo_loc_E300
	jmp	(loc_E300).l

JmpTo_DisplaySprite
	jmp	(DisplaySprite).l

JmpTo_loc_157A4
	jmp	(loc_157A4).l

JmpTo_DeleteObject
	jmp	(DeleteObject).l

JmpTo_ObjectMove
	jmp	(ObjectMove).l

JmpTo_Hud_Base
	jmp	(Hud_Base).l

Obj5E:
Obj5F:
Obj87:
	rts

; ===========================================================================
	align 4
; ===========================================================================

; ----------------------------------------------------------------------------
; Continue Screen
; ----------------------------------------------------------------------------
; loc_7870:
ContinueScreen:
	bsr.w	Pal_FadeFrom
	move	#$2700,sr
	move.w	(VDP_Reg1_val).w,d0
	andi.b	#$BF,d0
	move.w	d0,(VDP_control_port).l
	lea	(VDP_control_port).l,a6
	move.w	#$8004,(a6)
	move.w	#$8700,(a6)
	bsr.w	ClearScreen

	clearRAM ContScr_Object_RAM,(ContScr_Object_RAM_End-ContScr_Object_RAM)

	bsr.w	ContinueScreen_LoadLetters
	move.l	#vdpComm($A000,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_ContinueTails).l,a0
	bsr.w	NemDec
	move.l	#vdpComm($A480,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_MiniSonic).l,a0
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	lea	(ArtNem_MiniTails).l,a0
+
	bsr.w	NemDec
	moveq	#$A,d1
	jsr	(ContScrCounter).l
	move.w	#0,(Target_palette).w
	move.b	#MusID_Continue,d0
	bsr.w	PlayMusic
	move.w	#$293,(Demo_Time_left).w	; 11 seconds minus 1 frame
	clr.b	(Level_started_flag).w
	clr.l	(Camera_X_pos_copy).w
	move.l	#$1000000,(Camera_Y_pos_copy).w
	;move.w	#objroutine(ObjDB),(MainCharacter+id).w ; load ObjDB (sonic on continue screen)
	;move.w	#objroutine(ObjDB),(Sidekick+id).w ; load ObjDB (tails on continue screen)
	;move.b	#6,(Sidekick+player_off24).w ; => ObjDB_Tails_Init
	;move.w	#objroutine(ObjDA),(ContinueText+id).w ; load ObjDA (continue screen text)
	;move.w	#objroutine(ObjDA),(ContinueIcons+id).w ; load ObjDA (continue icons)
	;move.b	#4,(ContinueIcons+player_off24).w ; => loc_7AD0
	jsr	(RunObjects).l
	jsr	(BuildSprites).l
	move.b	#$16,(Vint_routine).w
	bsr.w	WaitForVint
	move.w	(VDP_Reg1_val).w,d0
	ori.b	#$40,d0
	move.w	d0,(VDP_control_port).l
	bsr.w	Pal_FadeTo
-
	move.b	#$16,(Vint_routine).w
	bsr.w	WaitForVint
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	ContinueScreen_Check5(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	+	
	move.w	ContinueScreen_Check6(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	+
	move.w	ContinueScreen_Check7(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	+
	move.w	ContinueScreen_Check8(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	+	
	move	#$2700,sr
	move.w	(Demo_Time_left).w,d1
	divu.w	#$3C,d1
	andi.l	#$F,d1
	jsr	(ContScrCounter).l
	move	#$2300,sr
	bra.s	+
ContinueScreen_Check5:
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Tails_Hurt)
		dc.w	objroutine(Knuckles_Hurt)
	
ContinueScreen_Check6:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

ContinueScreen_Check7:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

ContinueScreen_Check8:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)			
+
	jsr	(RunObjects).l
	jsr	(BuildSprites).l
	cmpi.w	#$180,(Sidekick+x_pos).w
	bhs.s	+
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	ContinueScreen_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	-
	move.w	ContinueScreen_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	-
	move.w	ContinueScreen_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	-
	move.w	ContinueScreen_Check4(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	-	
	tst.w	(Demo_Time_left).w
	bne.w	-
	move.b	#GameModeID_SegaScreen,(Game_Mode).w ; => SegaScreen
	rts
	
ContinueScreen_Check:
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Tails_Hurt)
		dc.w	objroutine(Knuckles_Hurt)
	
ContinueScreen_Check2:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

ContinueScreen_Check3:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

ContinueScreen_Check4:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)			
; ---------------------------------------------------------------------------
+
	move.b	#GameModeID_Level,(Game_Mode).w ; => Level (Zone play mode)
	move.b	#3,(Life_count).w
	moveq	#0,d0
	move.w	d0,(Ring_count).w
	move.l	d0,(Timer).w
	move.l	d0,(Score).w
	move.b	d0,(Last_star_pole_hit).w
	move.l	#5000,(Next_Extra_life_score).w
	subq.b	#1,(Continue_count).w
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_7A04:
ContinueScreen_LoadLetters:
	move.l	#vdpComm($B000,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_TitleCard).l,a0
	bsr.w	NemDec
	move.l	(LevelUncLayout).w,a4
	;lea	($FFFF8000).w,a4
	lea	(ArtNem_TitleCard2).l,a0
	bsr.w	NemDecToRAM
	lea	(ContinueScreen_AdditionalLetters).l,a0
	move.l	#vdpComm($B200,VRAM,WRITE),(VDP_control_port).l
	move.l	(LevelUncLayout).l,a1
	lea	(VDP_data_port).l,a6
-
	moveq	#0,d0
	move.b	(a0)+,d0
	bmi.s	+	; rts
	lsl.w	#5,d0
	lea	(a1,d0.w),a2
	moveq	#0,d1
	move.b	(a0)+,d1
	lsl.w	#3,d1
	subq.w	#1,d1

-	move.l	(a2)+,(a6)
	dbf	d1,-

	bra.s	--
; ---------------------------------------------------------------------------
+	rts
; End of function ContinueScreen_LoadLetters

; ===========================================================================

 ; temporarily remap characters to title card letter format
 ; Characters are encoded as Aa, Bb, Cc, etc. through a macro
 charset 'A',0	; can't have an embedded 0 in a string
 charset 'B',"\4\8\xC\4\x10\x14\x18\x1C\x1E\x22\x26\x2A\4\4\x30\x34\x38\x3C\x40\x44\x48\x4C\x52\x56\4"
 charset 'a',"\4\4\4\4\4\4\4\4\2\4\4\4\6\4\4\4\4\4\4\4\4\4\6\4\4"

; letter lookup string
llookup	:= "ABCDEFGHIJKLMNOPQRSTUVWXYZ "

; macro for defining title card letters in conjunction with the remapped character set
titleLetters macro letters
     ;  " ZYXWVUTSRQPONMLKJIHGFEDCBA"
used := %110000000000110000000010000	; set to initial state
c := 0
    rept strlen(letters)
t := substr(letters,c,1)
	if ~~(used&1<<strstr(llookup,t))	; has the letter been used already?
used := used|1<<strstr(llookup,t)	; if not, mark it as used
	dc.b t			; output letter code
	dc.b lowstring(t)	; output letter size
	endif
c := c+1
    endm
	dc.w $FFFF	; output string terminator
    endm

; word_7A5E:
ContinueScreen_AdditionalLetters:
	titleLetters "CONTINUE"

 charset ; revert character set

Obj21:
	rts

JmpTo_Dynamic_Normal
	jmp	(Dynamic_Normal).l

; ===========================================================================
; loc_8BD4:
MenuScreen:
	bsr.w	Pal_FadeFrom
	move	#$2700,sr
	move.w	(VDP_Reg1_val).w,d0
	andi.b	#$BF,d0
	move.w	d0,(VDP_control_port).l
	bsr.w	ClearScreen
	lea	(VDP_control_port).l,a6
	move.w	#$8004,(a6)
	move.w	#$8230,(a6)
	move.w	#$8407,(a6)
	move.w	#$8230,(a6)
	move.w	#$8700,(a6)
	move.w	#$8C81,(a6)
	move.w	#$9001,(a6)

	clearRAM Sprite_Table_Input,$400
	clearRAM Menus_Object_RAM,(Menus_Object_RAM_End-Menus_Object_RAM)

	; load background + graphics of font/LevSelPics
	clr.w	(VDP_Command_Buffer).w
	move.l	#VDP_Command_Buffer,(VDP_Command_Buffer_Slot).w
	move.l	#vdpComm($0200,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_FontStuff).l,a0
	bsr.w	NemDec
	move.l	#vdpComm($0E00,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_MenuBox).l,a0
	bsr.w	NemDec
	move.l	#vdpComm($1200,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_LevelSelectPics).l,a0
	bsr.w	NemDec
	lea	(Chunk_Table).l,a1
	lea	(MapEng_MenuBack).l,a0
	move.w	#$6000,d0
	bsr.w	EniDec
	lea	(Chunk_Table).l,a1
	move.l	#vdpComm($E000,VRAM,WRITE),d0
	moveq	#$27,d1
	moveq	#$1B,d2
	bsr.w	JmpTo_PlaneMapToVRAM	; fullscreen background

	cmpi.b	#GameModeID_OptionsMenu,(Game_Mode).w	; options menu?
	beq.w	MenuScreen_Options	; if yes, branch

	cmpi.b	#GameModeID_LevelSelect,(Game_Mode).w	; level select menu?
	beq.w	MenuScreen_LevelSelect	; if yes, branch

; ---------------------------------------------------------------------------
; Common menu screen subroutine for transferring text to RAM

; ARGUMENTS:
; d0 = starting art tile
; a1 = data source
; a2 = destination
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_8FBE:
MenuScreenTextToRAM:
	moveq	#0,d1
	move.b	(a1)+,d1
-	move.b	(a1)+,d0
	move.w	d0,(a2)+
	dbf	d1,-
	rts
; End of function MenuScreenTextToRAM

; ===========================================================================
; loc_8FCC:
MenuScreen_Options:
	lea	(Chunk_Table).l,a1
	lea	(MapEng_Options).l,a0
	move.w	#$70,d0
	bsr.w	EniDec
	lea	($FFFF0160).l,a1
	lea	(MapEng_Options).l,a0
	move.w	#$2070,d0
	bsr.w	EniDec
	clr.b	(Options_menu_box).w
	bsr.w	sub_9186
	addq.b	#1,(Options_menu_box).w
	bsr.w	loc_91F8
	clr.b	(Options_menu_box).w
	clr.b	(Level_started_flag).w
	clr.w	($FFFFF7F0).w
;	lea	(Anim_SonicMilesBG).l,a2
;	bsr.w	JmpTo2_Dynamic_Normal
	moveq	#PalID_Menu,d0
	bsr.w	PalLoad1
	move.b	#MusID_Options,d0
	bsr.w	JmpTo_PlayMusic
	clr.w	(Two_player_mode).w
	clr.l	(Camera_X_pos).w
	clr.l	(Camera_Y_pos).w
	clr.w	(Correct_cheat_entries).w
	clr.w	(Correct_cheat_entries_2).w
	move.b	#$16,(Vint_routine).w
	bsr.w	WaitForVint
	move.w	(VDP_Reg1_val).w,d0
	ori.b	#$40,d0
	move.w	d0,(VDP_control_port).l
	bsr.w	Pal_FadeTo
; loc_9060:
OptionScreen_Main:
	move.b	#$16,(Vint_routine).w
	bsr.w	WaitForVint
	move	#$2700,sr
	bsr.w	loc_91F8
	bsr.w	OptionScreen_Controls
	bsr.w	sub_9186
	move	#$2300,sr
;	lea	(Anim_SonicMilesBG).l,a2
;	bsr.w	JmpTo2_Dynamic_Normal
	move.b	(Ctrl_1_Press).w,d0
	or.b	(Ctrl_2_Press).w,d0
	andi.b	#button_start_mask,d0
	bne.s	OptionScreen_Select
	bra.w	OptionScreen_Main
; ===========================================================================
; loc_909A:
OptionScreen_Select:
	move.b	(Options_menu_box).w,d0
	bne.s	OptionScreen_Select_Not1P
	; Start a single player game
	moveq	#0,d0
	move.w	d0,(Two_player_mode).w
	move.w	d0,(Two_player_mode_copy).w
	move.w	d0,(Current_ZoneAndAct).w	; emerald_hill_zone_act_1
	move.b	#GameModeID_Level,(Game_Mode).w ; => Level (Zone play mode)
	rts
; ===========================================================================
; loc_90B6:
OptionScreen_Select_Not1P:
; ===========================================================================
; loc_90D8:
OptionScreen_Select_Other:
	; When pressing START on the sound test option, return to the SEGA screen
	move.b	#GameModeID_SegaScreen,(Game_Mode).w ; => SegaScreen
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_90E0:
OptionScreen_Controls:
	moveq	#0,d2
	move.b	(Options_menu_box).w,d2
	move.b	(Ctrl_1_Press).w,d0
	or.b	(Ctrl_2_Press).w,d0
	btst	#button_up,d0
	beq.s	+
	subq.b	#1,d2
	bcc.s	+
	move.b	#1,d2

+
	btst	#button_down,d0
	beq.s	+
	addq.b	#1,d2
	cmpi.b	#2,d2
	blo.s	+
	moveq	#0,d2

+
	move.b	d2,(Options_menu_box).w
	lsl.w	#2,d2
	move.b	OptionScreen_Choices(pc,d2.w),d3 ; number of choices for the option
	movea.l	OptionScreen_Choices(pc,d2.w),a1 ; location where the choice is stored (in RAM)
	move.w	(a1),d2
	btst	#button_left,d0
	beq.s	+
	subq.b	#1,d2
	bcc.s	+
	move.b	d3,d2

+
	btst	#button_right,d0
	beq.s	+
	addq.b	#1,d2
	cmp.b	d3,d2
	bls.s	+
	moveq	#0,d2

+
	btst	#button_A,d0
	beq.s	+
	addi.b	#$10,d2
	cmp.b	d3,d2
	bls.s	+
	moveq	#0,d2

+
	move.w	d2,(a1)
	cmpi.b	#1,(Options_menu_box).w
	bne.s	+	; rts
	andi.w	#button_B_mask|button_C_mask,d0
	beq.s	+	; rts
	move.w	(Sound_test_sound).w,d0
	addi.w	#$80,d0
	bsr.w	JmpTo_PlayMusic
	lea	(level_select_cheat).l,a0
	lea	(continues_cheat).l,a2
	lea	(Level_select_flag).w,a1
	moveq	#0,d2	; flag to tell the routine to enable the continues cheat
	bsr.w	CheckCheats

+
	rts
; End of function OptionScreen_Controls

; ===========================================================================
; word_917A:
OptionScreen_Choices:
	dc.l (4-1)<<24|(Player_option&$FFFFFF)
;	dc.l (2-1)<<24|(Two_player_items&$FFFFFF)
	dc.l ($80-1)<<24|(Sound_test_sound&$FFFFFF)

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_9186:
	bsr.w	loc_9268
	moveq	#0,d1
	move.b	(Options_menu_box).w,d1
	lsl.w	#3,d1
	lea	(OptScrBoxData).l,a3
	lea	(a3,d1.w),a3
	move.w	#$6000,d0
	lea	($FFFF0030).l,a2
	movea.l	(a3)+,a1
	bsr.w	MenuScreenTextToRAM
	lea	($FFFF00B6).l,a2
	moveq	#0,d1
	cmpi.b	#1,(Options_menu_box).w
	beq.s	+
	move.b	(Options_menu_box).w,d1
	lsl.w	#2,d1
	lea	OptionScreen_Choices(pc),a1
	movea.l	(a1,d1.w),a1
	move.w	(a1),d1
	lsl.w	#2,d1
+
	movea.l	(a4,d1.w),a1
	bsr.w	MenuScreenTextToRAM
	cmpi.b	#1,(Options_menu_box).w
	bne.s	+
	lea	($FFFF00C2).l,a2
	bsr.w	loc_9296
+
	lea	(Chunk_Table).l,a1
	move.l	(a3)+,d0
	moveq	#$15,d1
	moveq	#7,d2
	bra.w	JmpTo_PlaneMapToVRAM
; ===========================================================================

loc_91F8:
	bsr.w	loc_9268
	moveq	#0,d1
	move.b	(Options_menu_box).w,d1
	lsl.w	#3,d1
	lea	(OptScrBoxData).l,a3
	lea	(a3,d1.w),a3
	moveq	#0,d0
	lea	($FFFF0190).l,a2
	movea.l	(a3)+,a1
	bsr.w	MenuScreenTextToRAM
	lea	($FFFF0216).l,a2
	moveq	#0,d1
	cmpi.b	#1,(Options_menu_box).w
	beq.s	+
	move.b	(Options_menu_box).w,d1
	lsl.w	#2,d1
	lea	OptionScreen_Choices(pc),a1
	movea.l	(a1,d1.w),a1
	move.w	(a1),d1
	lsl.w	#2,d1

+
	movea.l	(a4,d1.w),a1
	bsr.w	MenuScreenTextToRAM
	cmpi.b	#1,(Options_menu_box).w
	bne.s	+
	lea	($FFFF0222).l,a2
	bsr.w	loc_9296

+
	lea	($FFFF0160).l,a1
	move.l	(a3)+,d0
	moveq	#$15,d1
	moveq	#7,d2
	bra.w	JmpTo_PlaneMapToVRAM
; ===========================================================================

loc_9268:
	lea	(off_92D2).l,a4
	tst.b	(Graphics_Flags).w
	bpl.s	+
	lea	(off_92DE).l,a4

+
	tst.b	(Options_menu_box).w
	beq.s	++
	lea	(off_92F2).l,a4

+
	cmpi.b	#2,(Options_menu_box).w
	bne.s	+	; rts
	lea	(off_92F2).l,a4

+
	rts
; ===========================================================================

loc_9296:
	move.w	(Sound_test_sound).w,d1
	move.b	d1,d2
	lsr.b	#4,d1
	bsr.s	+
	move.b	d2,d1

+
	andi.w	#$F,d1
	cmpi.b	#$A,d1
	blo.s	+
	addi.b	#4,d1

+
	addi.b	#$10,d1
	move.b	d1,d0
	move.w	d0,(a2)+
	rts
; ===========================================================================
; off_92BA:
OptScrBoxData:

; macro to declare the data for an options screen box
boxData macro txtlabel,vramAddr
	dc.l txtlabel, vdpComm(vramAddr,VRAM,WRITE)
    endm

	boxData	TextOptScr_PlayerSelect,$C392
;	boxData	TextOptScr_VsModeItems,$C592
	boxData	TextOptScr_SoundTest,$C792

off_92D2:
	dc.l TextOptScr_SonicAndMiles
	dc.l TextOptScr_SonicAlone
	dc.l TextOptScr_MilesAlone
	dc.l TextOptScr_KnucklesAlone
off_92DE:
	dc.l TextOptScr_SonicAndTails
	dc.l TextOptScr_SonicAlone
	dc.l TextOptScr_TailsAlone
	dc.l TextOptScr_KnucklesAlone
;off_92EA:
;	dc.l TextOptScr_AllKindsItems
;	dc.l TextOptScr_TeleportOnly
off_92F2:
	dc.l TextOptScr_0
; ===========================================================================
; loc_92F6:
MenuScreen_LevelSelect:
	lea	(Chunk_Table).l,a1
	lea	(MapEng_LevSel).l,a0	; 2 bytes per 8x8 tile, compressed
	move.w	#0,d0
	bsr.w	EniDec
	lea	($FFFF0000).l,a1
	move.l	#vdpComm($C000,VRAM,WRITE),d0
	moveq	#$27,d1
	moveq	#$1B,d2	; 40x28 = whole screen
	bsr.w	JmpTo_PlaneMapToVRAM	; display patterns
	moveq	#0,d3
	bsr.w	LevelSelect_DrawSoundNumber
	lea	($FFFF08C0).l,a1
	lea	(MapEng_LevSelIcon).l,a0
	move.w	#$90,d0
	bsr.w	EniDec
	bsr.w	LevelSelect_DrawIcon
	clr.w	(Player_mode).w
	clr.b	(Level_started_flag).w
	clr.w	($FFFFF7F0).w
;	lea	(Anim_SonicMilesBG).l,a2
;	bsr.w	JmpTo2_Dynamic_Normal	; background
	moveq	#PalID_Menu,d0
	bsr.w	PalLoad1
	lea	(Normal_palette_line3).w,a1
	lea	(Target_palette_line3).w,a2

	moveq	#7,d1
-	move.l	(a1),(a2)+
	clr.l	(a1)+
	dbf	d1,-

	move.b	#MusID_Options,d0
	bsr.w	JmpTo_PlayMusic
	move.w	#$707,(Demo_Time_left).w
	clr.w	(Two_player_mode).w
	clr.l	(Camera_X_pos).w
	clr.l	(Camera_Y_pos).w
	clr.w	(Correct_cheat_entries).w
	clr.w	(Correct_cheat_entries_2).w
	move.b	#$16,(Vint_routine).w
	bsr.w	WaitForVint
	move.w	(VDP_Reg1_val).w,d0
	ori.b	#$40,d0
	move.w	d0,(VDP_control_port).l
	bsr.w	Pal_FadeTo

;loc_93AC:
LevelSelect_Main:	; routine running during level select
	move.b	#$16,(Vint_routine).w
	bsr.w	WaitForVint
	move	#$2700,sr
	moveq	#0,d3	; palette line << 13
	bsr.w	LevelSelect_MarkFields	; unmark fields
	bsr.w	LevSelControls	; possible change selected fields
	move.w	#$6000,d3	; palette line << 13
	bsr.w	LevelSelect_MarkFields	; mark fields
	bsr.w	LevelSelect_DrawIcon
	move	#$2300,sr
;	lea	(Anim_SonicMilesBG).l,a2
;	bsr.w	JmpTo2_Dynamic_Normal
	move.b	(Ctrl_1_Press).w,d0
	or.b	(Ctrl_2_Press).w,d0
	andi.b	#button_start_mask,d0	; start pressed?
	bne.s	LevelSelect_PressStart	; yes
	bra.w	LevelSelect_Main	; no
; ===========================================================================

;loc_93F0:
LevelSelect_PressStart:
	move.w	(Level_select_zone).w,d0
	add.w	d0,d0
	move.w	LevelSelect_Order(pc,d0.w),d0
	bmi.w	LevelSelect_Return	; sound test
	cmpi.w	#$4000,d0
	bne.s	LevelSelect_StartZone

;LevelSelect_SpecialStage:
;	move.b	#GameModeID_SpecialStage,(Game_Mode).w ; => SpecialStage
	clr.w	(Current_ZoneAndAct).w
	move.b	#3,(Life_count).w
	moveq	#0,d0
	move.w	d0,(Ring_count).w
	move.l	d0,(Timer).w
	move.l	d0,(Score).w
	move.l	#5000,(Next_Extra_life_score).w
	move.w	(Player_option).w,(Player_mode).w
	rts
; ===========================================================================

;loc_944C:
LevelSelect_Return:
	move.b	#GameModeID_SegaScreen,(Game_Mode).w ; => SegaScreen
	rts
; ===========================================================================
; -----------------------------------------------------------------------------
; Level Select Level Order

; One entry per item in the level select menu. Just set the value for the item
; you want to link to the level/act number of the level you want to load when
; the player selects that item.
; -----------------------------------------------------------------------------
;Misc_9454:
LevelSelect_Order:
	dc.w	emerald_hill_zone_act_1
	dc.w	emerald_hill_zone_act_2	; 1
	dc.w	chemical_plant_zone_act_1	; 2
	dc.w	chemical_plant_zone_act_2	; 3
	dc.w	aquatic_ruin_zone_act_1	; 4
	dc.w	aquatic_ruin_zone_act_2	; 5
	dc.w	casino_night_zone_act_1	; 6
	dc.w	casino_night_zone_act_2	; 7
	dc.w	hill_top_zone_act_1	; 8
	dc.w	hill_top_zone_act_2	; 9
	dc.w	mystic_cave_zone_act_1	; 10
	dc.w	mystic_cave_zone_act_2	; 11
	dc.w	oil_ocean_zone_act_1	; 12
	dc.w	oil_ocean_zone_act_2	; 13
	dc.w	metropolis_zone_act_1	; 14
	dc.w	metropolis_zone_act_2	; 15
	dc.w	metropolis_zone_act_3	; 16
	dc.w	sky_chase_zone_act_1	; 17
	dc.w	wing_fortress_zone_act_1	; 18
	dc.w	death_egg_zone_act_1	; 19
	dc.w	$100	; 20 - special stage
	dc.w	$FFFF	; 21 - sound test
; ===========================================================================

;loc_9480:
LevelSelect_StartZone:
	andi.w	#$3FFF,d0
	move.w	d0,(Current_ZoneAndAct).w
	move.b	#GameModeID_Level,(Game_Mode).w ; => Level (Zone play mode)
	move.b	#3,(Life_count).w
	moveq	#0,d0
	move.w	d0,(Ring_count).w
	move.l	d0,(Timer).w
	move.l	d0,(Score).w
	move.b	d0,(Continue_count).w
	move.l	#5000,(Next_Extra_life_score).w
	move.b	#MusID_FadeOut,d0
	bsr.w	JmpTo_PlaySound
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Change what you're selecting in the level select
; ---------------------------------------------------------------------------
; loc_94DC:
LevSelControls:
	move.b	(Ctrl_1_Press).w,d1
	andi.b	#button_up_mask|button_down_mask,d1
	bne.s	+	; up/down pressed
	subq.w	#1,($FFFFFF80).w
	bpl.s	LevSelControls_CheckLR

+
	move.w	#$B,($FFFFFF80).w
	move.b	(Ctrl_1_Held).w,d1
	andi.b	#button_up_mask|button_down_mask,d1
	beq.s	LevSelControls_CheckLR	; up/down not pressed, check for left & right
	move.w	(Level_select_zone).w,d0
	btst	#button_up,d1
	beq.s	+
	subq.w	#1,d0	; decrease by 1
	bcc.s	+	; >= 0?
	moveq	#$15,d0	; set to $15

+
	btst	#button_down,d1
	beq.s	+
	addq.w	#1,d0	; yes, add 1
	cmpi.w	#$16,d0
	blo.s	+	; smaller than $16?
	moveq	#0,d0	; if not, set to 0

+
	move.w	d0,(Level_select_zone).w
	rts
; ===========================================================================
; loc_9522:
LevSelControls_CheckLR:
	cmpi.w	#$15,(Level_select_zone).w	; are we in the sound test?
	bne.s	LevSelControls_SwitchSide	; no
	move.w	(Sound_test_sound).w,d0
	move.b	(Ctrl_1_Press).w,d1
	btst	#button_left,d1
	beq.s	+
	subq.b	#1,d0
	bcc.s	+
	moveq	#$7F,d0

+
	btst	#button_right,d1
	beq.s	+
	addq.b	#1,d0
	cmpi.w	#$80,d0
	blo.s	+
	moveq	#0,d0

+
	btst	#button_A,d1
	beq.s	+
	addi.b	#$10,d0
	andi.b	#$7F,d0

+
	move.w	d0,(Sound_test_sound).w
	andi.w	#button_B_mask|button_C_mask,d1
	beq.s	+	; rts
	move.w	(Sound_test_sound).w,d0
	addi.w	#$80,d0
	bsr.w	JmpTo_PlayMusic
	lea	(debug_cheat).l,a0
	lea	(super_sonic_cheat).l,a2
	lea	(Night_mode_flag).w,a1
	moveq	#1,d2	; flag to tell the routine to enable the Super Sonic cheat
	bsr.w	CheckCheats

+
	rts
; ===========================================================================
; loc_958A:
LevSelControls_SwitchSide:	; not in soundtest, not up/down pressed
	move.b	(Ctrl_1_Press).w,d1
	andi.b	#button_left_mask|button_right_mask,d1
	beq.s	+				; no direction key pressed
	move.w	(Level_select_zone).w,d0	; left or right pressed
	move.b	LevelSelect_SwitchTable(pc,d0.w),d0 ; set selected zone according to table
	move.w	d0,(Level_select_zone).w
+
	rts
; ===========================================================================
;byte_95A2:
LevelSelect_SwitchTable:
	dc.b $E
	dc.b $F		; 1
	dc.b $11	; 2
	dc.b $11	; 3
	dc.b $12	; 4
	dc.b $12	; 5
	dc.b $13	; 6
	dc.b $13	; 7
	dc.b $14	; 8
	dc.b $14	; 9
	dc.b $15	; 10
	dc.b $15	; 11
	dc.b $C		; 12
	dc.b $D		; 13
	dc.b 0		; 14
	dc.b 1		; 15
	dc.b 1		; 16
	dc.b 2		; 17
	dc.b 4		; 18
	dc.b 6		; 19
	dc.b 8		; 20
	dc.b $A		; 21
; ===========================================================================

;loc_95B8:
LevelSelect_MarkFields:
	lea	(Chunk_Table).l,a4
	lea	(LevSel_MarkTable).l,a5
	lea	(VDP_data_port).l,a6
	moveq	#0,d0
	move.w	(Level_select_zone).w,d0
	lsl.w	#2,d0
	lea	(a5,d0.w),a3
	moveq	#0,d0
	move.b	(a3),d0
	mulu.w	#$50,d0
	moveq	#0,d1
	move.b	1(a3),d1
	add.w	d1,d0
	lea	(a4,d0.w),a1
	moveq	#0,d1
	move.b	(a3),d1
	lsl.w	#7,d1
	add.b	1(a3),d1
	addi.w	#-$4000,d1
	lsl.l	#2,d1
	lsr.w	#2,d1
	ori.w	#$4000,d1
	swap	d1
	move.l	d1,4(a6)

	moveq	#$D,d2
-	move.w	(a1)+,d0
	add.w	d3,d0
	move.w	d0,(a6)
	dbf	d2,-

	addq.w	#2,a3
	moveq	#0,d0
	move.b	(a3),d0
	beq.s	+
	mulu.w	#$50,d0
	moveq	#0,d1
	move.b	1(a3),d1
	add.w	d1,d0
	lea	(a4,d0.w),a1
	moveq	#0,d1
	move.b	(a3),d1
	lsl.w	#7,d1
	add.b	1(a3),d1
	addi.w	#-$4000,d1
	lsl.l	#2,d1
	lsr.w	#2,d1
	ori.w	#$4000,d1
	swap	d1
	move.l	d1,4(a6)
	move.w	(a1)+,d0
	add.w	d3,d0
	move.w	d0,(a6)

+
	cmpi.w	#$15,(Level_select_zone).w
	bne.s	+	; rts
	bsr.w	LevelSelect_DrawSoundNumber
+
	rts
; ===========================================================================
;loc_965A:
LevelSelect_DrawSoundNumber:
	move.l	#vdpComm($C944,VRAM,WRITE),(VDP_control_port).l
	move.w	(Sound_test_sound).w,d0
	move.b	d0,d2
	lsr.b	#4,d0
	bsr.s	+
	move.b	d2,d0

+
	andi.w	#$F,d0
	cmpi.b	#$A,d0
	blo.s	+
	addi.b	#4,d0

+
	addi.b	#$10,d0
	add.w	d3,d0
	move.w	d0,(a6)
	rts
; ===========================================================================

;loc_9688:
LevelSelect_DrawIcon:
	move.w	(Level_select_zone).w,d0
	lea	(LevSel_IconTable).l,a3
	lea	(a3,d0.w),a3
	lea	($FFFF08C0).l,a1
	moveq	#0,d0
	move.b	(a3),d0
	lsl.w	#3,d0
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0
	lea	(a1,d0.w),a1
	move.l	#vdpComm($CB36,VRAM,WRITE),d0
	moveq	#3,d1
	moveq	#2,d2
	bsr.w	JmpTo_PlaneMapToVRAM
	lea	(Pal_LevelIcons).l,a1
	moveq	#0,d0
	move.b	(a3),d0
	lsl.w	#5,d0
	lea	(a1,d0.w),a1
	lea	(Normal_palette_line3).w,a2

	moveq	#7,d1
-	move.l	(a1)+,(a2)+
	dbf	d1,-

	rts
; ===========================================================================
;byte_96D8
LevSel_IconTable:
	dc.b   0,0	;0	EHZ
	dc.b   7,7	;2	CPZ
	dc.b   8,8	;4	ARZ
	dc.b   6,6	;6	CNZ
	dc.b   2,2	;8	HTZ
	dc.b   5,5	;$A	MCZ
	dc.b   4,4	;$C	OOZ
	dc.b   1,1,1	;$E	MTZ
	dc.b   9	;$11	SCZ
	dc.b  $A	;$12	WFZ
	dc.b  $B	;$13	DEZ
	dc.b  $C	;$14	Special Stage
	dc.b  $E	;$15	Sound Test
;byte_96EE:
LevSel_MarkTable:	; 4 bytes per level select entry
; line primary, 2*column ($E fields), line secondary, 2*column secondary (1 field)
	dc.b   3,  6,  3,$24	;0
	dc.b   3,  6,  4,$24
	dc.b   6,  6,  6,$24
	dc.b   6,  6,  7,$24
	dc.b   9,  6,  9,$24	;4
	dc.b   9,  6, $A,$24
	dc.b  $C,  6, $C,$24
	dc.b  $C,  6, $D,$24
	dc.b  $F,  6, $F,$24	;8
	dc.b  $F,  6,$10,$24
	dc.b $12,  6,$12,$24
	dc.b $12,  6,$13,$24
	dc.b $15,  6,$15,$24	;$C
	dc.b $15,  6,$16,$24
; --- second column ---
	dc.b   3,$2C,  3,$48
	dc.b   3,$2C,  4,$48
	dc.b   3,$2C,  5,$48	;$10
	dc.b   6,$2C,  0,  0
	dc.b   9,$2C,  0,  0
	dc.b  $C,$2C,  0,  0
	dc.b  $F,$2C,  0,  0	;$14
	dc.b $12,$2C,$12,$48
; ===========================================================================
; loc_9746:
CheckCheats:	; This is called from 2 places: the options screen and the level select screen
	move.w	(Correct_cheat_entries).w,d0	; Get the number of correct sound IDs entered so far
	adda.w	d0,a0				; Skip to the next entry
	move.w	(Sound_test_sound).w,d0		; Get the current sound test sound
	cmp.b	(a0),d0				; Compare it to the cheat
	bne.s	+				; If they're different, branch
	addq.w	#1,(Correct_cheat_entries).w	; Add 1 to the number of correct entries
	tst.b	1(a0)				; Is the next entry 0?
	bne.s	++				; If not, branch
	move.w	#$101,(a1)			; Enable the cheat
	move.b	#$B5,d0			; Play the ring sound
	bsr.w	JmpTo_PlaySound
+
	move.w	#0,(Correct_cheat_entries).w	; Clear the number of correct entries
+
	move.w	(Correct_cheat_entries_2).w,d0	; Do the same procedure with the other cheat
	adda.w	d0,a2
	move.w	(Sound_test_sound).w,d0
	cmp.b	(a2),d0
	bne.s	++
	addq.w	#1,(Correct_cheat_entries_2).w
	tst.b	1(a2)
	bne.s	+++	; rts
	tst.w	d2				; Test this to determine which cheat to enable
	bne.s	+				; If not 0, branch
	move.b	#$F,(Continue_count).w		; Give 15 continues
	; The next line causes the bug where the OOZ music plays until reset.
	; Remove "&$7F" to fix the bug.
	move.b	#$BF,d0	; Play the continue jingle
	bsr.w	JmpTo_PlayMusic
	bra.s	++
; ===========================================================================
+
	move.w	#7,(Got_Emerald).w		; Give 7 emeralds to the player
	move.b	#MusID_Emerald,d0		; Play the emerald jingle
	bsr.w	JmpTo_PlayMusic
+
	move.w	#0,(Correct_cheat_entries_2).w	; Clear the number of correct entries
+
	rts
; ===========================================================================
level_select_cheat:	dc.b 1, 1,   1, 1,   0
continues_cheat:	dc.b   1,   1,   2,   4,   0	; byte_97B7
debug_cheat:		dc.b   2,   2,   2,   2,   2,   2,   2,   2,   0
super_sonic_cheat:	dc.b   3,   3,   3,   3,   0	; byte_97C5

	; set the character set for menu text
	charset '@',"\27\30\31\32\33\34\35\36\37\38\39\40\41\42\43\44\45\46\47\48\49\50\51\52\53\54\55"
	charset '0',"\16\17\18\19\20\21\22\23\24\25"
	charset '*',$1A
	charset ':',$1C
	charset '.',$1D
	charset ' ',0

	; options screen menu text
menutxt	macro	text
	dc.b	strlen(text)-1
	dc.b	text
	endm

TextOptScr_PlayerSelect:	menutxt	"* PLAYER SELECT *"	; byte_97CA:
TextOptScr_SonicAndMiles:	menutxt	"SONIC AND MILES"	; byte_97DC:
TextOptScr_SonicAndTails:	menutxt	"SONIC AND TAILS"	; byte_97EC:
TextOptScr_SonicAlone:		menutxt	"SONIC ALONE    "	; byte_97FC:
TextOptScr_MilesAlone:		menutxt	"MILES ALONE    "	; byte_980C:
TextOptScr_TailsAlone:		menutxt	"TAILS ALONE    "	; byte_981C:
TextOptScr_KnucklesAlone:	menutxt	"KNUCKLES ALONE	"
;TextOptScr_VsModeItems:		menutxt	"* VS MODE ITEMS *"	; byte_982C:
;TextOptScr_AllKindsItems:	menutxt	"ALL KINDS ITEMS"	; byte_983E:
;TextOptScr_TeleportOnly:	menutxt	"TELEPORT ONLY  "	; byte_984E:
TextOptScr_SoundTest:		menutxt	"*  SOUND TEST   *"	; byte_985E:
TextOptScr_0:			menutxt	"      00       "	; byte_9870:

	charset ; reset character set

; level select picture palettes
; byte_9880:
Pal_LevelIcons:	BINCLUDE "art/palettes/Level Select Icons.bin"


; options screen mappings (Enigma compressed)
; byte_9AB2:
MapEng_Options:	BINCLUDE "mappings/misc/Options Screen.bin"

; level select screen mappings (Enigma compressed)
; byte_9ADE:
MapEng_LevSel:	BINCLUDE "mappings/misc/Level Select.bin"

; 1P and 2P level select icon mappings (Enigma compressed)
; byte_9C32:
MapEng_LevSelIcon:	BINCLUDE "mappings/misc/Level Select Icons.bin"

; ===========================================================================
JmpTo_PlaySound
	jmp	(PlaySound).l
; ===========================================================================

JmpTo_PlayMusic
	jmp	(PlayMusic).l
; ===========================================================================
; loc_9C70:
JmpTo_PlaneMapToVRAM
	jmp	(PlaneMapToVRAM).l
; End of function sub_9186


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; Attributes: thunk

JmpTo2_Dynamic_Normal
	jmp	(Dynamic_Normal).l
; End of function JmpTo2_Dynamic_Normal




; ===========================================================================
; loc_9C7C:
EndingSequence:
	rts

ObjCA:
ObjCC:
ObjCD:
ObjCE:
ObjCF:
ObjCB:
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; sub_ABE2:
EndingSequence_LoadCharacterArt:
	rts

Pal_AC7E:	BINCLUDE	"art/palettes/Ending Sonic.bin"
Pal_AC9E:	BINCLUDE	"art/palettes/Ending Sonic Far.bin"
Pal_ACDE:	BINCLUDE	"art/palettes/Ending Background.bin"
Pal_AD1E:	BINCLUDE	"art/palettes/Ending Photos.bin"
Pal_AD3E:	BINCLUDE	"art/palettes/Ending Super Sonic.bin"

word_AD5E:
	dc.w $3E
	dc.b 0;ObjID_EndingSeqClouds
	dc.b $00
word_AD62:
	dc.w $3E
	dc.b 0;ObjID_EndingSeqTrigger
	dc.b $00
word_AD66:
	dc.w $3E
	dc.b 0;ObjID_EndingSeqBird
	dc.b $00
word_AD6A:
	dc.w $3E
	dc.b 0;ObjID_EndingSeqSonic
	dc.b $00
word_AD6E:
	dc.w $3E
	dc.b 0;ObjID_TornadoHelixes
	dc.b $00

; off_AD72:
Animal_From_Badnik_SubObjData:
	dc.l Animal_From_Badnik_MapUnc_11E1C
	dc.w $594
	dc.b 4,2,8,0

; --------------------------------------------------------------------------------------
; Unknown Enigma compressed data
; --------------------------------------------------------------------------------------
byte_B23A:
	dc.b   7,  1,  0,  1,  0,  1, $A,  0,$18,$10,  0,$C1,$80,  6, $A,$81
	dc.b $40, $B,  2,  0,$58,$88,  3,$86,$4C,$A4,  1,$C3,$40,$52,  1,$C0; 16
	dc.b $14,$21,$13,$C2,$80,$97,$FC,  0; 32
sub_B262:
	lea	off_B2CA(pc),a1
	move.w	($FFFFFF4C).w,d0
	lsl.w	#2,d0
	move.l	(a1,d0.w),d0
	movea.l	d0,a1

loc_B272:
	move	#$2700,sr
	lea	(VDP_data_port).l,a6
-
	move.l	(a1)+,d0
	bmi.s	++
	movea.l	d0,a2
	move.w	(a1)+,d0
	bsr.s	sub_B29E
	move.l	d0,4(a6)
	move.b	(a2)+,d0
	lsl.w	#8,d0
-
	move.b	(a2)+,d0
	bmi.s	+
	move.w	d0,(a6)
	bra.s	-
; ===========================================================================
+	bra.s	--
; ===========================================================================
+
	move	#$2300,sr
	rts
; End of function sub_B262


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_B29E:
	andi.l	#$FFFF,d0
	lsl.l	#2,d0
	lsr.w	#2,d0
	ori.w	#$4000,d0
	swap	d0
	rts
; End of function sub_B29E

; ===========================================================================

; macro for declaring pointer/position structures for intro/credit text
creditsPtrs macro addr,pos
	if "addr"<>""
		dc.l addr
		dc.w pos
		shift
		shift
		creditsPtrs ALLARGS
	else
		dc.w -1
	endif
    endm

; intro text pointers (one intro screen)
off_B2B0: creditsPtrs	byte_BD1A,$C49E, byte_BCEE,$C622, \
			byte_BCF6,$C786, byte_BCE9,$C924

; credits screen pointer table
off_B2CA:
	dc.l off_B322, off_B336, off_B34A, off_B358	; 3
	dc.l off_B366, off_B374, off_B388, off_B3A8	; 7
	dc.l off_B3C2, off_B3DC, off_B3F0, off_B41C	; 11
	dc.l off_B436, off_B450, off_B45E, off_B490	; 15
	dc.l off_B4B0, off_B4C4, off_B4F0, off_B51C	; 19
	dc.l off_B548, -1				; 21

; credits text pointers for each screen of credits
off_B322: creditsPtrs	byte_BC46,$C59C, byte_BC51,$C5B0, byte_BC55,$C784
off_B336: creditsPtrs	byte_B55C,$C586, byte_B56F,$C5AC, byte_B581,$C78C
off_B34A: creditsPtrs	byte_B56F,$C598, byte_B59F,$C78E
off_B358: creditsPtrs	byte_B5BC,$C598, byte_B5CD,$C78C
off_B366: creditsPtrs	byte_B5EB,$C58A, byte_B60C,$C78E
off_B374: creditsPtrs	byte_B628,$C510, byte_B642,$C708, byte_B665,$C814
off_B388: creditsPtrs	byte_B67B,$C408, byte_B69C,$C522, byte_B6A4,$C612, byte_B6BC,$C808, byte_B6DE,$C910
off_B3A8: creditsPtrs	byte_B6F8,$C496, byte_B70B,$C592, byte_B723,$C794, byte_B738,$C886
off_B3C2: creditsPtrs	byte_B75C,$C488, byte_B642,$C688, byte_B77E,$C78E, byte_B799,$C88E
off_B3DC: creditsPtrs	byte_B7B5,$C510, byte_B75C,$C608, byte_B799,$C80E
off_B3F0: creditsPtrs	byte_B7F2,$C312, byte_B6BC,$C508, byte_B80B,$C614, byte_B821,$C712, byte_B839,$C80E, byte_B855,$C916, byte_B869,$CA16
off_B41C: creditsPtrs	byte_B7B5,$C492, byte_B87D,$C594, byte_B893,$C796, byte_B8A8,$C88E
off_B436: creditsPtrs	byte_B8C5,$C48C, byte_B8E2,$C68A, byte_B902,$C786, byte_B90F,$C888
off_B450: creditsPtrs	byte_B932,$C588, byte_B954,$C78A
off_B45E: creditsPtrs	byte_B974,$C288, byte_B995,$C49E, byte_B9A1,$C59E, byte_B9AD,$C69E, byte_B9B8,$C7A0, byte_B9C1,$C8A2, byte_B9C8,$C9A2, byte_B9D0,$CA9E
off_B490: creditsPtrs	byte_B9DB,$C406, byte_BA00,$C610, byte_BA1B,$C70C, byte_BA3A,$C812, byte_BA52,$C914
off_B4B0: creditsPtrs	byte_BA69,$C512, byte_BA81,$C70A, byte_B7CE,$C806
off_B4C4: creditsPtrs	byte_B55C,$C316, byte_BAA2,$C414, byte_BAB8,$C606, byte_BADC,$C70E, byte_BAF7,$C80A, byte_BB16,$C90E, byte_BB32,$CA04
off_B4F0: creditsPtrs	byte_BB58,$C30C, byte_BB75,$C424, byte_BB7B,$C60C, byte_BC9F,$C70A, byte_BBD8,$C810, byte_BBF2,$C910, byte_BC0C,$CA12
off_B51C: creditsPtrs	byte_BB58,$C30C, byte_BB75,$C424, byte_BB98,$C606, byte_BBBC,$C70E, byte_BCBE,$C80E, byte_BCD9,$C91A, byte_BC25,$CA08
off_B548: creditsPtrs	byte_BC7B,$C496, byte_BC8F,$C6A4, byte_BC95,$C8A0

 ; temporarily remap characters to credit text format
 ; let's encode 2-wide characters like Aa, Bb, Cc, etc. and hide it with a macro
 charset '@',"\x3B\2\4\6\8\xA\xC\xE\x10\x12\x13\x15\x17\x19\x1B\x1D\x1F\x21\x23\x25\x27\x29\x2B\x2D\x2F\x31\x33"
 charset 'a',"\3\5\7\9\xB\xD\xF\x11\x12\x14\x16\x18\x1A\x1C\x1E\x20\x22\x24\x26\x28\x2A\x2C\x2E\x30\x32\x34"
 charset '!',"\x3D\x39\x3F\x36"
 charset '\H',"\x39\x37\x38"
 charset '9',"\x3E\x40\x41"
 charset '1',"\x3C\x35"
 charset '.',"\x3A"
 charset ' ',0

 ; macro for defining credit text in conjunction with the remapped character set
creditText macro pre,ss
c := 0
	dc.b pre
	rept strlen(ss)
t := substr(ss,c,1)
	dc.b t
l := lowstring(t)
	if t="I"
	elseif l<>t
		dc.b l
	elseif t="1"
		dc.b "!"
	elseif t="2"
		dc.b "$"
	elseif t="9"
		dc.b "#"
	endif
c := c+1
	endm
	dc.b -1
    endm

; credits text data (palette index followed by a string)
byte_B55C:	creditText $20,"EXECUTIVE"
byte_B56F:	creditText $20,"PRODUCER"
byte_B581:	creditText   0,"HAYAO  NAKAYAMA"
byte_B59F:	creditText   0,"SHINOBU  TOYODA"
byte_B5BC:	creditText $20,"DIRECTOR"
byte_B5CD:	creditText   0,"MASAHARU  YOSHII"
byte_B5EB:	creditText $20,"CHIEF  PROGRAMMER"
byte_B60C:	creditText   0,"YUJI  NAKA (YU2)"
byte_B628:	creditText $20,"GAME  PLANNER"
byte_B642:	creditText   0,"HIROKAZU  YASUHARA"
byte_B665:	creditText   0,"(CAROL  YAS)"
byte_B67B:	creditText $20,"CHARACTER  DESIGN"
byte_B69C:	creditText $20,"AND"
byte_B6A4:	creditText $20,"CHIEF  ARTIST"
byte_B6BC:	creditText   0,"YASUSHI  YAMAGUCHI"
byte_B6DE:	creditText   0,"(JUDY  TOTOYA)"
byte_B6F8:	creditText $20,"ASSISTANT"
byte_B70B:	creditText $20,"PROGRAMMERS"
byte_B723:	creditText   0,"BILL  WILLIS"
byte_B738:	creditText   0,"MASANOBU  YAMAMOTO"
byte_B75C:	creditText $20,"OBJECT  PLACEMENT"
byte_B77E:	creditText   0,"TAKAHIRO  ANTO"
byte_B799:	creditText   0,"YUTAKA  SUGANO"
byte_B7B5:	creditText $20,"SPECIALSTAGE"
byte_B7CE:	creditText   0,"CAROL  ANN  HANSHAW"
byte_B7F2:	creditText $20,"ZONE  ARTISTS"
byte_B80B:	creditText   0,"CRAIG  STITT"
byte_B821:	creditText   0,"BRENDA  ROSS"
byte_B839:	creditText   0,"JINA  ISHIWATARI"
byte_B855:	creditText   0,"TOM  PAYNE"
byte_B869:	creditText   0,"PHENIX  RIE"
byte_B87D:	creditText $20,"ART  AND  CG"
byte_B893:	creditText   0,"TIM  SKELLY"
byte_B8A8:	creditText   0,"PETER  MORAWIEC"
byte_B8C5:	creditText $20,"MUSIC  COMPOSER"
byte_B8E2:	creditText   0,"MASATO  NAKAMURA"
byte_B902:	creditText   0,"( @1992"
byte_B90F:	creditText   0,"DREAMS  COME  TRUE)"
byte_B932:	creditText $20,"SOUND  PROGRAMMER"
byte_B954:	creditText   0,"TOMOYUKI  SHIMADA"
byte_B974:	creditText $20,"SOUND  ASSISTANTS"
byte_B995:	creditText   0,"MACKY"
byte_B9A1:	creditText   0,"JIMITA"
byte_B9AD:	creditText   0,"MILPO"
byte_B9B8:	creditText   0,"IPPO"
byte_B9C1:	creditText   0,"S.O"
byte_B9C8:	creditText   0,"OYZ"
byte_B9D0:	creditText   0,"N.GEE"
byte_B9DB:	creditText $20,"PROJECT  ASSISTANTS"
byte_BA00:	creditText   0,"SYUICHI  KATAGI"
byte_BA1B:	creditText   0,"TAKAHIRO  HAMANO"
byte_BA3A:	creditText   0,"YOSHIKI  OOKA"
byte_BA52:	creditText   0,"STEVE  WOITA"
byte_BA69:	creditText $20,"GAME  MANUAL"
byte_BA81:	creditText   0,"YOUICHI  TAKAHASHI"
byte_BAA2:	creditText $20,"SUPPORTERS"
byte_BAB8:	creditText   0,"DAIZABUROU  SAKURAI"
byte_BADC:	creditText   0,"HISASHI  SUZUKI"
byte_BAF7:	creditText   0,"THOMAS  KALINSKE"
byte_BB16:	creditText   0,"FUJIO  MINEGISHI"
byte_BB32:	creditText   0,"TAKAHARU UTSUNOMIYA"
byte_BB58:	creditText $20,"SPECIAL  THANKS"
byte_BB75:	creditText $20,"TO"
byte_BB7B:	creditText   0,"CINDY  CLAVERAN"
byte_BB98:	creditText   0,"DEBORAH  MCCRACKEN"
byte_BBBC:	creditText   0,"TATSUO  YAMADA"
byte_BBD8:	creditText   0,"DAISUKE  SAITO"
byte_BBF2:	creditText   0,"KUNITAKE  AOKI"
byte_BC0C:	creditText   0,"TSUNEKO  AOKI"
byte_BC25:	creditText   0,"MASAAKI  KAWAMURA"
byte_BC46:	creditText   0,"SONIC"
byte_BC51:	creditText $20,"2"
byte_BC55:	creditText   0,"CAST  OF  CHARACTERS"
byte_BC7B:	creditText   0,"PRESENTED"
byte_BC8F:	creditText   0,"BY"
byte_BC95:	creditText   0,"SEGA"
byte_BC9F:	creditText   0,"FRANCE  TANTIADO"
byte_BCBE:	creditText   0,"RICK  MACARAEG"
byte_BCD9:	creditText   0,"LOCKY  P"

 charset ; have to revert character set before changing again

 ; temporarily remap characters to intro text format
 charset '@',"\x3A\1\3\5\7\9\xB\xD\xF\x11\x12\x14\x16\x18\x1A\x1C\x1E\x20\x22\x24\x26\x28\x2A\x2C\x2E\x30\x32"
 charset 'a',"\2\4\6\8\xA\xC\xE\x10\x11\x13\x15\x17\x19\x1B\x1D\x1F\x21\x23\x25\x27\x29\x2B\x2D\x2F\x31\x33"
 charset '!',"\x3C\x38\x3E\x35"
 charset '\H',"\x38\x36\x37"
 charset '9',"\x3D\x3F\x40"
 charset '1',"\x3B\x34"
 charset '.',"\x39"
 charset ' ',0

; intro text
byte_BCE9:	creditText   5,"IN"
byte_BCEE:	creditText   5,"AND"
byte_BCF6:	creditText   5,"MILES 'TAILS' PROWER"
byte_BD1A:	creditText   5,"SONIC"

 charset ; revert character set

	even

; -------------------------------------------------------------------------------
; Nemesis compressed art
; 64 blocks
; Standard font used in credits
; -------------------------------------------------------------------------------
; ArtNem_BD26:
ArtNem_CreditText:	BINCLUDE	"art/nemesis/Credit Text.bin"
; ===========================================================================

loc_3AF58:
	subq.b	#1,objoff_37(a0)
	bmi.w	JmpToloc_3AF60
	rts
; ===========================================================================

JmpTo5_DisplaySprite
	jmp	(DisplaySprite).l

JmpTo3_DeleteObject
	jmp	(DeleteObject).l

JmpTo2_PlaySound
	jmp	(PlaySound).l

JmpTo_loc_3AF58
	jmp	(loc_3AF58).l

JmpTo_AnimateSprite
	jmp	(AnimateSprite).l

JmpTo_NemDec
	jmp	(NemDec).l

JmpTo_EniDec
	jmp	(EniDec).l

JmpToloc_3AF60:
	jmp	loc_3AF60

JmpTo_ClearScreen
	jmp	(ClearScreen).l

JmpTo2_PlayMusic
	jmp	(PlayMusic).l

JmpTo2_PlaneMapToVRAM
	jmp	(PlaneMapToVRAM).l

JmpTo2_ObjectMove
	jmp	(ObjectMove).l

JmpTo_PalCycle_Load
	jmp	(PalCycle_Load).l

loc_3FCC4:
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	add.w	d0,d0
	add.w	d0,d0
	move.w	PLC_DYNANM+2(pc,d0.w),d1
	lea	PLC_DYNANM(pc,d1.w),a2
	move.w	PLC_DYNANM(pc,d0.w),d0
	jmp	PLC_DYNANM(pc,d0.w)
; ---------------------------------------------------------------------------
; ZONE ANIMATION PROCEDURES AND SCRIPTS
;
; Each zone gets two entries in this jump table. The first entry points to the
; zone's animation procedure (usually Dynamic_Normal, but some zones have special
; procedures for complicated animations). The second points to the zone's animation
; script.
;
; Note that Animated_Null is not a valid animation script, so don't pair it up
; with anything except Dynamic_Null, or bad things will happen (for example, a bus error exception).
; ---------------------------------------------------------------------------
PLC_DYNANM: zoneOffsetTable 2,2		; Zone ID
	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $00
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $01
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $02
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $03
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $04
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $05
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $06
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM		; $07
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $08
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $09
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $0A
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $0B
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM		; $0C
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $0D
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $0E
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM		; $0F
	zoneTableEntry.w Animated_Null - PLC_DYNANM

	zoneTableEntry.w Dynamic_Null - PLC_DYNANM	; $10
	zoneTableEntry.w Animated_Null - PLC_DYNANM
    zoneTableEnd
Dynamic_Null:
	rts
; ===========================================================================

Dynamic_Normal:
	lea	($FFFFF7F0).w,a3

loc_3FF30:
	move.w	(a2)+,d6

loc_3FF32:
	subq.b	#1,(a3)
	bcc.s	loc_3FF78
	moveq	#0,d0
	move.b	1(a3),d0
	cmp.b	6(a2),d0
	blo.s	loc_3FF48
	moveq	#0,d0
	move.b	d0,1(a3)

loc_3FF48:
	addq.b	#1,1(a3)
	move.b	(a2),(a3)
	bpl.s	loc_3FF56
	add.w	d0,d0
	move.b	9(a2,d0.w),(a3)

loc_3FF56:
	move.b	8(a2,d0.w),d0
	lsl.w	#5,d0
	move.w	4(a2),d2
	move.l	(a2),d1
	andi.l	#$FFFFFF,d1
	add.l	d0,d1
	moveq	#0,d3
	move.b	7(a2),d3
	lsl.w	#4,d3
	jsr	(QueueDMATransfer).l

loc_3FF78:
	move.b	6(a2),d0
	tst.b	(a2)
	bpl.s	loc_3FF82
	add.b	d0,d0

loc_3FF82:
	addq.b	#1,d0
	andi.w	#$FE,d0
	lea	8(a2,d0.w),a2
	addq.w	#2,a3
	dbf	d6,loc_3FF32
	rts
Animated_Null:
	; invalid

loc_402D4:

	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	add.w	d0,d0
	move.w	AnimPatMaps(pc,d0.w),d0
	lea	AnimPatMaps(pc,d0.w),a0
+
	tst.w	(a0)
	beq.s	+	; rts
	lea	(Block_Table).w,a1
	adda.w	(a0)+,a1
	move.w	(a0)+,d1

LoadLevelBlocks:
	move.w	(a0)+,(a1)+	; copy blocks to RAM
	dbf	d1,LoadLevelBlocks
+
	rts
; --------------------------------------------------------------------------------------
; Animated Pattern Mappings (16x16)
; --------------------------------------------------------------------------------------
; off_40350:
AnimPatMaps: zoneOffsetTable 2,1
	zoneTableEntry.w APM_Null - AnimPatMaps ;  0
	zoneTableEntry.w APM_Null - AnimPatMaps  ;  1
	zoneTableEntry.w APM_Null - AnimPatMaps  ;  2
	zoneTableEntry.w APM_Null - AnimPatMaps  ;  3
	zoneTableEntry.w APM_Null - AnimPatMaps ;  4
	zoneTableEntry.w APM_Null - AnimPatMaps ;  5
	zoneTableEntry.w APM_Null - AnimPatMaps  ;  6
	zoneTableEntry.w APM_Null - AnimPatMaps ;  7
	zoneTableEntry.w APM_Null - AnimPatMaps   ;  8
	zoneTableEntry.w APM_Null - AnimPatMaps  ;  9
	zoneTableEntry.w APM_Null - AnimPatMaps   ; $A
	zoneTableEntry.w APM_Null - AnimPatMaps  ; $B
	zoneTableEntry.w APM_Null - AnimPatMaps   ; $C
	zoneTableEntry.w APM_Null - AnimPatMaps   ; $D
	zoneTableEntry.w APM_Null - AnimPatMaps   ; $E
	zoneTableEntry.w APM_Null - AnimPatMaps   ; $F
	zoneTableEntry.w APM_Null - AnimPatMaps  ;$10
    zoneTableEnd

APM_Null:	dc.w   0

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to load level boundaries and start locations
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_BFBC:
LevelSizeLoad:
	clr.w	(Scroll_flags).w
	clr.w	(Scroll_flags_BG).w
	clr.w	(Scroll_flags_BG2).w
	clr.w	(Scroll_flags_BG3).w
	clr.w	(Scroll_flags_P2).w
	clr.w	($FFFFEE5A).w
	clr.w	($FFFFEE5C).w
	clr.w	($FFFFEE5E).w
	clr.w	(Scroll_flags_copy).w
	clr.w	(Scroll_flags_BG_copy).w
	clr.w	(Scroll_flags_BG2_copy).w
	clr.w	(Scroll_flags_BG3_copy).w
	clr.w	(Scroll_flags_copy_P2).w
	clr.w	($FFFFEEAA).w
	clr.w	($FFFFEEAC).w
	clr.w	($FFFFEEAE).w
	clr.b	(Deform_lock).w
	clr.b	(Screen_Shaking_Flag_HTZ).w
	clr.b	(Screen_Shaking_Flag).w
	clr.b	(Scroll_lock).w
	clr.b	(Scroll_lock_P2).w
	moveq	#0,d0
	move.b	d0,(Dynamic_Resize_Routine).w ; load level boundaries
	move.w	(Current_ZoneAndAct).w,d0
	ror.b	#1,d0
	lsr.w	#4,d0
	lea	WrdArr_LvlSize(pc,d0.w),a0
	move.l	(a0)+,d0
	move.l	d0,(Camera_Min_X_pos).w
	move.l	d0,($FFFFEEC0).w	; unused besides this one write...
	move.l	d0,(Tails_Min_X_pos).w
	move.l	(a0)+,d0
	move.l	d0,(Camera_Min_Y_pos).w
	move.l	d0,($FFFFEEC4).w	; unused besides this one write...
	move.l	d0,($FFFFEEFC).w
	move.w	#$1010,(Horiz_block_crossed_flag).w
	move.w	#$60,(Camera_Y_pos_bias).w
	move.w	#$60,(Camera_Y_pos_bias_P2).w
	bra.w	+
LoadLevelSizeActTransition:
	moveq	#0,d0
	move.w	(Current_ZoneAndAct).w,d0
	ror.b	#1,d0
	lsr.w	#4,d0
	lea	WrdArr_LvlSize(pc,d0.w),a0
	move.w	(a0)+,(Camera_Min_X_pos).w
	move.w	(a0)+,(Camera_Max_X_pos).w
	move.w	(a0)+,(Camera_Min_Y_pos).w	; unused besides this one write...
	move.w	(a0)+,(Camera_Max_Y_pos).w
	rts
; ===========================================================================
;WrdArr_LvlSize	
	Include	"code/Levels/Level Size List.asm"
	even

; ===========================================================================

+
	tst.b	(Last_star_pole_hit).w		; was a CheckPoint hit yet?
	beq.s	+				; if not, branch
	jsr	(CheckPoint_LoadData).l		; load the previously saved data
	move.w	(MainCharacter+x_pos).w,d1
	move.w	(MainCharacter+y_pos).w,d0
	bra.s	++
; ===========================================================================
+	; Put the character at the start location for the level
	move.w	(Current_ZoneAndAct).w,d0
	ror.b	#1,d0
	lsr.w	#5,d0
	cmp.w	#1,(Player_mode).w
	bgt.w	StartLocationTailsCheck
	lea	WrdArr_StartLocSonic(pc,d0.w),a1

LoadStartPositions:
	moveq	#0,d1
	move.w	(a1)+,d1
	move.w	d1,(MainCharacter+x_pos).w
	moveq	#0,d0
	move.w	(a1),d0
	move.w	d0,(MainCharacter+y_pos).w
+
	subi.w	#$A0,d1
	bcc.s	+
	moveq	#0,d1
+
	move.w	(Camera_Max_X_pos).w,d2
	cmp.w	d2,d1
	blo.s	+
	move.w	d2,d1
+
	move.w	d1,(Camera_X_pos).w
	move.w	d1,(Camera_X_pos_P2).w
	subi.w	#$60,d0
	bcc.s	+
	moveq	#0,d0
+
	cmp.w	(Camera_Max_Y_pos_now).w,d0
	blt.s	+
	move.w	(Camera_Max_Y_pos_now).w,d0
+
	move.w	d0,(Camera_Y_pos).w
	move.w	d0,(Camera_Y_pos_P2).w
	bsr.w	sub_C258
	rts
; End of function LevelSizeLoad
	Include	"code/Levels/Sonic Start Locations List.asm"
	even	
; ===========================================================================
StartLocationTailsCheck:
	cmp.w	#2,(Player_mode).w
	bne.w	StartLocationKnucklesCheck
	lea	WrdArr_StartLocTails(pc,d0.w),a1
	bra.w	LoadStartPositions
	
	Include	"code/Levels/Tails Start Locations List.asm"
	even		
; =============================================================
StartLocationKnucklesCheck:
	lea	WrdArr_StartLocKnuckles(pc,d0.w),a1
	bra.w	LoadStartPositions
	
; Start Positions of Characters	

	Include	"code/Levels/Knuckles Start Locations List.asm"
	even		
; =========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_C258:
	tst.b	(Last_star_pole_hit).w	; was a CheckPoint hit yet?
	bne.s	+			; if yes, branch
	move.w	d0,(Camera_BG_Y_pos).w
	move.w	d0,(Camera_BG2_Y_pos).w
	move.w	d1,(Camera_BG_X_pos).w
	move.w	d1,(Camera_BG2_X_pos).w
	;move.w	d1,(Camera_BG3_X_pos).w
	move.w	d0,($FFFFEE2C).w
	move.w	d0,($FFFFEE34).w
	move.w	d1,($FFFFEE28).w
	move.w	d1,($FFFFEE30).w
	move.w	d1,($FFFFEE38).w
+
	moveq	#0,d2
	move.b	(Current_Zone).w,d2
	add.w	d2,d2
	move.w	off_C296(pc,d2.w),d2
	jmp	off_C296(pc,d2.w)
; End of function sub_C258

; ===========================================================================
off_C296: zoneOffsetTable 2,1
	zoneTableEntry.w loc_C2B8 - off_C296
	zoneTableEntry.w loc_C2E4 - off_C296	; 1
	zoneTableEntry.w loc_C2E4 - off_C296	; 2
	zoneTableEntry.w loc_C2E4 - off_C296	; 3
	zoneTableEntry.w loc_C2E4 - off_C296	; 4
	zoneTableEntry.w loc_C2E4 - off_C296	; 5
	zoneTableEntry.w return_C2F2 - off_C296	; 6
	zoneTableEntry.w loc_C2F4 - off_C296	; 7
	zoneTableEntry.w return_C320 - off_C296	; 8
	zoneTableEntry.w return_C320 - off_C296	; 9
	zoneTableEntry.w loc_C322 - off_C296	; 10
	zoneTableEntry.w loc_C332 - off_C296	; 11
	zoneTableEntry.w loc_C364 - off_C296	; 12
	zoneTableEntry.w loc_C372 - off_C296	; 13
	zoneTableEntry.w return_C38A - off_C296	; 14
	zoneTableEntry.w loc_C38C - off_C296	; 15
	zoneTableEntry.w loc_C3C6 - off_C296	; 16
    zoneTableEnd
; ===========================================================================

loc_C2B8:
	clr.l	(Camera_BG_X_pos).w
	clr.l	(Camera_BG_Y_pos).w
	clr.l	(Camera_BG2_Y_pos).w
	;clr.l	(Camera_BG3_Y_pos).w
	lea	(TempArray_LayerDef).w,a2
	clr.l	(a2)+
	clr.l	(a2)+
	clr.l	(a2)+
	clr.l	($FFFFEE28).w
	clr.l	($FFFFEE2C).w
	clr.l	($FFFFEE34).w
	clr.l	($FFFFEE3C).w
	rts
; ===========================================================================

loc_C2E4:
	asr.w	#2,d0
	move.w	d0,(Camera_BG_Y_pos).w
	asr.w	#3,d1
	move.w	d1,(Camera_BG_X_pos).w
	rts
; ===========================================================================

return_C2F2:
	rts
; ===========================================================================

loc_C2F4:
	clr.l	(Camera_BG_X_pos).w
	clr.l	(Camera_BG_Y_pos).w
	clr.l	(Camera_BG2_Y_pos).w
	;clr.l	(Camera_BG3_Y_pos).w
	lea	(TempArray_LayerDef).w,a2
	clr.l	(a2)+
	clr.l	(a2)+
	clr.l	(a2)+
	clr.l	($FFFFEE28).w
	clr.l	($FFFFEE2C).w
	clr.l	($FFFFEE34).w
	clr.l	($FFFFEE3C).w
	rts
; ===========================================================================

return_C320:
	rts
; ===========================================================================

loc_C322:
	lsr.w	#3,d0
	addi.w	#$50,d0
	move.w	d0,(Camera_BG_Y_pos).w
	clr.l	(Camera_BG_X_pos).w
	rts
; ===========================================================================

loc_C332:
	clr.l	(Camera_BG_X_pos).w
	clr.l	($FFFFEE28).w
	tst.b	(Current_Act).w
	bne.s	+
	divu.w	#3,d0
	subi.w	#$140,d0
	move.w	d0,(Camera_BG_Y_pos).w
	move.w	d0,($FFFFEE2C).w
	rts
; ===========================================================================
+
	divu.w	#6,d0
	subi.w	#$10,d0
	move.w	d0,(Camera_BG_Y_pos).w
	move.w	d0,($FFFFEE2C).w
	rts
; ===========================================================================

loc_C364:
	clr.l	(Camera_BG_X_pos).w
	clr.l	(Camera_BG_Y_pos).w
	clr.l	($FFFFEE2C).w
	rts
; ===========================================================================

loc_C372:
	lsr.w	#2,d0
	move.w	d0,(Camera_BG_Y_pos).w
	move.w	d0,($FFFFEE2C).w
	lsr.w	#1,d1
	move.w	d1,(Camera_BG2_X_pos).w
	lsr.w	#2,d1
	move.w	d1,(Camera_BG_X_pos).w
	rts
; ===========================================================================

return_C38A:
	rts
; ===========================================================================

loc_C38C:
	tst.b	(Current_Act).w
	beq.s	+
	subi.w	#$E0,d0
	lsr.w	#1,d0
	move.w	d0,(Camera_BG_Y_pos).w
	bra.s	loc_C3A6
; ===========================================================================
+
	subi.w	#$180,d0
	move.w	d0,(Camera_BG_Y_pos).w

loc_C3A6:
	muls.w	#$119,d1
	asr.l	#8,d1
	move.w	d1,(Camera_BG_X_pos).w
	move.w	d1,($FFFFF672).w
	clr.w	($FFFFEE0A).w
	clr.w	($FFFFF674).w
	clr.l	(Camera_BG2_Y_pos).w
	;clr.l	(Camera_BG3_Y_pos).w
	rts
; ===========================================================================

loc_C3C6:
	clr.l	(Camera_BG_X_pos).w
	clr.l	(Camera_BG_Y_pos).w
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; sub_C3D0:
DeformBgLayer:
	tst.b	(Deform_lock).w
	beq.s	+
	rts
; ===========================================================================
+
	clr.w	(Scroll_flags).w
	clr.w	(Scroll_flags_BG).w
	clr.w	(Scroll_flags_BG2).w
	clr.w	(Scroll_flags_BG3).w
	clr.w	(Scroll_flags_P2).w
	clr.w	($FFFFEE5A).w
	clr.w	($FFFFEE5C).w
	clr.w	($FFFFEE5E).w
	clr.w	(Camera_X_pos_diff).w
	clr.w	(Camera_Y_pos_diff).w
	clr.w	(Camera_X_pos_diff_P2).w
	clr.w	(Camera_Y_pos_diff_P2).w
	cmpi.b	#sky_chase_zone,(Current_Zone).w
	bne.w	+
	tst.w	(Debug_placement_mode).w
	beq.w	loc_C4D0	; skip normal scrolling for SCZ
+
	tst.b	(Scroll_lock).w
	bne.s	+++
	lea	(MainCharacter).w,a0 ; a0=character
	lea	(Camera_X_pos).w,a1
	lea	(Camera_Min_X_pos).w,a2
	lea	(Scroll_flags).w,a3
	lea	(Camera_X_pos_diff).w,a4
	lea	(Horiz_scroll_delay_val).w,a5
	lea	(Sonic_Pos_Record_Buf).w,a6
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	lea	(Horiz_scroll_delay_val_P2).w,a5
	lea	(Tails_Pos_Record_Buf).w,a6
+
	bsr.w	ScrollHoriz
	lea	(Horiz_block_crossed_flag).w,a2
	bsr.w	SetHorizScrollFlags
	lea	(Camera_Y_pos).w,a1
	lea	(Camera_Min_X_pos).w,a2
	lea	(Camera_Y_pos_diff).w,a4
	move.w	(Camera_Y_pos_bias).w,d3
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	move.w	(Camera_Y_pos_bias_P2).w,d3
+
	bsr.w	ScrollVerti
	lea	(Verti_block_crossed_flag).w,a2
	bsr.w	SetVertiScrollFlags
+
	tst.w	(Two_player_mode).w
	beq.s	loc_C4D0
	tst.b	(Scroll_lock_P2).w
	bne.s	loc_C4D0
	lea	(Sidekick).w,a0 ; a0=character
	lea	(Camera_X_pos_P2).w,a1
	lea	(Tails_Min_X_pos).w,a2
	lea	(Scroll_flags_P2).w,a3
	lea	(Camera_X_pos_diff_P2).w,a4
	lea	(Horiz_scroll_delay_val_P2).w,a5
	lea	(Tails_Pos_Record_Buf).w,a6
	bsr.w	ScrollHoriz
	lea	(Horiz_block_crossed_flag_P2).w,a2
	bsr.w	SetHorizScrollFlags
	lea	(Camera_Y_pos_P2).w,a1
	lea	(Tails_Min_X_pos).w,a2
	lea	(Camera_Y_pos_diff_P2).w,a4
	move.w	(Camera_Y_pos_bias_P2).w,d3
	bsr.w	ScrollVerti
	lea	(Verti_block_crossed_flag_P2).w,a2
	bsr.w	SetVertiScrollFlags

loc_C4D0:
	jsr		RunDynamicArtLoading
	jsr		RunActTransitions
	bsr.w	RunDynamicLevelEvents
	move.w	(Camera_Y_pos).w,(Vscroll_Factor).w
	move.w	(Camera_BG_Y_pos).w,(Vscroll_Factor+2).w
	move.l	(Camera_X_pos).w,(Camera_X_pos_copy).w
	move.l	(Camera_Y_pos).w,(Camera_Y_pos_copy).w
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	add.w	d0,d0
	move.w	JmpTbl_SwScrlMgr(pc,d0.w),d0
	jmp	JmpTbl_SwScrlMgr(pc,d0.w)
; End of function DeformBgLayer

; ===========================================================================
	Include	"code/Levels/Deformation List.asm"
	even
; loc_C51E:
SwScrl_Title:
	move.w	(Camera_BG_Y_pos).w,(Vscroll_Factor+2).w
	addq.w	#1,(Camera_X_pos).w
	move.w	(Camera_X_pos).w,d2
	neg.w	d2
	asr.w	#2,d2
	lea	(Horiz_Scroll_Buf).w,a1
	moveq	#0,d0

	move.w	#bytesToLcnt($280),d1
-	move.l	d0,(a1)+
	dbf	d1,-

	move.w	d2,d0

	move.w	#bytesToLcnt($80),d1
-	move.l	d0,(a1)+
	dbf	d1,-

	move.w	d0,d3
	move.b	(Vint_runcount+3).w,d1
	andi.w	#7,d1
	bne.s	+
	subq.w	#1,(TempArray_LayerDef).w
+
	move.w	(TempArray_LayerDef).w,d1
	andi.w	#$1F,d1
	lea	SwScrl_RippleData(pc),a2
	lea	(a2,d1.w),a2

	move.w	#bytesToLcnt($40),d1
-	move.b	(a2)+,d0
	ext.w	d0
	add.w	d3,d0
	move.l	d0,(a1)+
	dbf	d1,-

	rts
; ===========================================================================
SwScrl_EHZ:
		move.w	#8,(Camera_Bg_Y_pos).w
		move.w	(Camera_Bg_Y_pos).w,($FFFFF618).w
		lea	($FFFFE000).w,a1			; load buffer location to a1

DeformEHZ_FG:
		lea	(a1),a2					; load X buffer location to a2
		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		neg.w	d5					; reverse it
		move.W	#$DF,d1					; set repeat times

DeformEHZ_FG_X:
		move.w	d5,(a2)+				; deform it to buffer
		lea	$02(a2),a2				; skip BG deform
		dbf	d1,DeformEHZ_FG_X			; repeat til full deformation is met on X axis

		lea	$380(a1),a2				; load Y buffer location to a2
		move.w	(Camera_Y_pos).w,d5			; load camera's current Y position
		move.W	#$14,d1					; set repeat times

DeformEHZ_FG_Y:
		move.w	d5,(a2)+				; deform it to buffer
		lea	$02(a2),a2				; skip BG deform
		dbf	d1,DeformEHZ_FG_Y			; repeat til full deformation is met on Y axis

; Top Clouds

DeformEHZ_BG:
		lea	(a1),a2					; load X buffer location to a2
		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$01,d5					; divide by 2 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$47,d1					; set repeat times

DeformEHZ_BG_X1:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X1			; repeat til full deformation is met on Y axis

; Bottom Clouds
		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$02,d5					; divide by 4 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$27,d1					; set repeat times

DeformEHZ_BG_X2:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X2			; repeat til full deformation is met on Y axis

; Sky and top Mountains
		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$06,d5					; divide by 40 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$47,d1					; set repeat times

DeformEHZ_BG_X3:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X3			; repeat til full deformation is met on Y axis

		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$05,d5					; divide by 20 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$07,d1					; set repeat times

DeformEHZ_BG_X4:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X4			; repeat til full deformation is met on Y axis

		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$04,d5					; divide by 10 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$07,d1					; set repeat times

DeformEHZ_BG_X5:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X5			; repeat til full deformation is met on Y axis

		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$03,d5					; divide by 08 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$07,d1					; set repeat times

DeformEHZ_BG_X6:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X6			; repeat til full deformation is met on Y axis

		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$02,d5					; divide by 04 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$07,d1					; set repeat times

DeformEHZ_BG_X7:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X7			; repeat til full deformation is met on Y axis

		move.w	(Camera_X_pos).w,d5			; load camera's current X position
		lsr.w	#$01,d5					; divide by 02 (reduces speed)
		neg.w	d5					; reverse it
		move.W	#$07,d1					; set repeat times

DeformEHZ_BG_X8:
		lea	$02(a2),a2				; skip FG deform
		move.w	d5,(a2)+				; deform it to buffer
		dbf	d1,DeformEHZ_BG_X8			; repeat til full deformation is met on Y axis

		move.w	#$110,d0
		sub.w	(Camera_Y_pos).w,d0
		bpl.b	+
		moveq	#0,d0
		bra.b	DeformEHZ_End
+		cmpi.w	#$E0,d0
		ble.b	+
		move.w	#$E0,d0
+		move.w	d0,d1
		add.w	d1,d1
		add.w	d1,d0
		lsr.w	#2,d0
		neg.w	d0
		subi.w	#$40,d0

DeformEHZ_End:
		move.w	d0,(Camera_BG_Y_pos).w
		move.w	d0,(Vscroll_Factor+2).w
		rts						; return

; ===========================================================================
; byte_C682:
SwScrl_RippleData:
	dc.b   1,  2,  3,  4,  1,  2,  3,  4,  1,  2,  3,  4,  1,  2,  3,  4; 16
	dc.b   2,  0,  3,  2,  2,  3,  2,  2,  1,  3,  0,  0,  1,  0,  1,  3; 32
	dc.b   1,  2,  1,  3,  1,  2,  2,  1,  2,  3,  1,  2,  1,  2,  0,  0; 48
	dc.b   2,  0,  3,  2,  2,  3,  2,  2,  1,  3,  0,  0,  1,  0,  1,  3; 64
	dc.b   1,  2	; 66
; ===========================================================================
SwScrl_WFZ:
	move.w	#$10,(Camera_Bg_Y_pos).w
	move.w	(Camera_Bg_Y_pos).w,($FFFFF618).w

	lea	(Horiz_Scroll_Buf).w,a1
	move.w	(Camera_X_pos).w,d5
	neg.w	d5
	move.w	#$DF,d1
-	move.w	d5,(a1)+
	adda.w	#2,a1
	dbf	d1,-
SwScrl_WFZ_Vrtc:
	lea	($FFFFE380).w,a1	; vertical scrolling buffer
	move.w	(Camera_Y_pos).w,d5
SwScrl_WFZ_Vrtc1:
	moveq	#$14,d1
	moveq	#0,d2
-	move.w	d5,(a1)+
	add.w	#4,(a1)+
	dbf	d1,-
	rts
; ---------------------------------------------------------------------------
; Subroutine to set horizontal scroll flags
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_D6E2:
SetHorizScrollFlags:
	move.w	(a1),d0		; get camera X pos
	andi.w	#$10,d0
	move.b	(a2),d1
	eor.b	d1,d0		; has the camera crossed a 16-pixel boundary?
	bne.s	++		; if not, branch
	eori.b	#$10,(a2)
	move.w	(a1),d0		; get camera X pos
	sub.w	d4,d0		; subtract previous camera X pos
	bpl.s	+		; branch if the camera has moved forward
	bset	#2,(a3)		; set moving back in level bit
	rts
; ===========================================================================
+
	bset	#3,(a3)		; set moving forward in level bit
+
	rts
; End of function SetHorizScrollFlags

; ---------------------------------------------------------------------------
; Subroutine to scroll the camera horizontally
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_D704:
ScrollHoriz:
	move.w	(a1),d4		; get camera X pos
	tst.b	(Teleport_flag).w
	bne.s	+++		; if a teleport is in progress, return
	move.w	(a5),d1		; should scrolling be delayed?
	beq.s	+		; if not, branch
	subi.w	#$100,d1	; reduce delay value
	move.w	d1,(a5)
	moveq	#0,d1
	move.b	(a5),d1		; get delay value
	lsl.b	#2,d1		; multiply by 4, the size of a position buffer entry
	addq.b	#4,d1
	move.w	2(a5),d0	; get current position buffer index
	sub.b	d1,d0
	move.w	(a6,d0.w),d0	; get Sonic's position a certain number of frames ago
	andi.w	#$3FFF,d0
	bra.s	++		; use that value for scrolling
; ===========================================================================
+
	move.w	x_pos(a0),d0
+
	sub.w	(a1),d0
	subi.w	#144,d0		; is the player less than 144 pixels from the screen edge?
	blt.s	++		; if he is, scroll
	subi.w	#16,d0		; is the player more than 159 pixels from the screen edge?
	bge.s	loc_D758	; if he is, scroll
	clr.w	(a4)		; otherwise, don't scroll
+
	rts
; ===========================================================================
+
	cmpi.w	#-16,d0
	bgt.s	+
	move.w	#-16,d0		; limit scrolling to 16 pixels per frame
+
	add.w	(a1),d0		; get new camera position
	cmp.w	(a2),d0		; is it greater than the minimum position?
	bgt.s	++		; if it is, branch
	move.w	(a2),d0		; prevent camera from going any further back
	bra.s	++
; ===========================================================================

loc_D758:
	cmpi.w	#16,d0
	blo.s	+
	move.w	#16,d0
+
	add.w	(a1),d0		; get new camera position
	cmp.w	2(a2),d0	; is it less than the max position?
	blt.s	+		; if it is, branch
	move.w	2(a2),d0	; prevent camera from going any further forward
+
	move.w	d0,d1
	sub.w	(a1),d1		; subtract old camera position
	asl.w	#8,d1		; shift up by a byte
	move.w	d0,(a1)		; set new camera position
	move.w	d1,(a4)		; set difference between old and new positions
	rts
; End of function ScrollHoriz

; ---------------------------------------------------------------------------
; Subroutine to scroll the camera vertically
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_D77A:
ScrollVerti:
	moveq	#0,d1
	move.w	y_pos(a0),d0
	sub.w	(a1),d0		; subtract camera Y pos
	cmpi.w	#-$100,(Camera_Min_Y_pos).w ; does the level wrap vertically?
	bne.s	+		; if not, branch
	andi.w	#$7FF,d0
+
	btst	#2,status(a0)	; is the player rolling?
	beq.s	+		; if not, branch
	subq.w	#5,d0		; subtract difference between standing and rolling heights
+
	btst	#1,status(a0)	; is the player in the air?
	beq.s	+		; if not, branch
	addi.w	#$20,d0
	sub.w	d3,d0		; subtract camera bias
	bcs.s	loc_D7FC
	subi.w	#$40,d0
	bcc.s	loc_D7FC
	tst.b	($FFFFEEDE).w	; is the max Y pos changing?
	bne.s	loc_D80E	; if it is, branch
	bra.s	++
; ===========================================================================
+
	sub.w	d3,d0		; subtract camera bias
	bne.s	++
	tst.b	($FFFFEEDE).w	; is the max Y pos changing?
	bne.s	loc_D80E	; if it is, branch
+
	clr.w	(a4)		; clear Y position difference
	rts
; ===========================================================================
+
	cmpi.w	#$60,d3		; is the camera bias normal?
	bne.s	loc_D7EA	; if not, branch
	mvabs.w	inertia(a0),d1	; get player ground velocity, force it to be positive
	cmpi.w	#$800,d1	; is the player travelling very fast?
	bhs.s	loc_D7FC	; if he is, branch
	move.w	#$600,d1
	cmpi.w	#6,d0		; is the positions difference greater than 6 pixels?
	bgt.s	loc_D84A	; if it is, branch
	cmpi.w	#-6,d0		; is the positions difference less than -6 pixels?
	blt.s	loc_D824	; if it is, branch
	bra.s	loc_D814
; ===========================================================================

loc_D7EA:
	move.w	#$200,d1
	cmpi.w	#2,d0
	bgt.s	loc_D84A
	cmpi.w	#-2,d0
	blt.s	loc_D824
	bra.s	loc_D814
; ===========================================================================

loc_D7FC:
	move.w	#$1000,d1
	cmpi.w	#$10,d0
	bgt.s	loc_D84A
	cmpi.w	#-$10,d0
	blt.s	loc_D824
	bra.s	loc_D814
; ===========================================================================

loc_D80E:
	moveq	#0,d0
	move.b	d0,($FFFFEEDE).w	; clear camera max Y pos changing flag

loc_D814:
	moveq	#0,d1
	move.w	d0,d1		; get position difference
	add.w	(a1),d1		; add old camera Y position
	tst.w	d0		; is the camera to scroll down?
	bpl.w	loc_D852	; if it is, branch
	bra.w	+
; ===========================================================================

loc_D824:
	neg.w	d1
	ext.l	d1
	asl.l	#8,d1
	add.l	(a1),d1
	swap	d1		; calculate new camera pos
+
	cmp.w	4(a2),d1	; is the new position less than the minimum Y pos?
	bgt.s	loc_D868	; if not, branch
	cmpi.w	#-$100,d1	; Test if the level is meant to loop at the top (or at all, now)
	bgt.s	+
; 	andi.w	#$7FF,d1        ; Reposition the camera around the loop (fixed $800 size)
; 	andi.w	#$7FF,(a1)      ; Reposition the camera around the loop (fixed $800 size)
	move.w	6(a2),d2        ; Reposition the camera around the loop (size given by level size array, should work)
	add.w	d2,d1           ; Reposition the camera around the loop (size given by level size array, should work)
	add.w	d2,(a1)         ; Reposition the camera around the loop (size given by level size array, should work)
	bra.s	loc_D868
; ===========================================================================
+
	move.w	4(a2),d1	; prevent camera from going any further up
	bra.s	loc_D868
; ===========================================================================

loc_D84A:
	ext.l	d1
	asl.l	#8,d1
	add.l	(a1),d1
	swap	d1		; calculate new camera pos

loc_D852:
	cmp.w	6(a2),d1	; is the new position greater than the maximum Y pos?
	blt.s	loc_D868	; if not, branch
; 	subi.w	#$800,d1	; Test if the level is meant to loop at the bottom (limited vertical size to $800
; 	bcs.s	+
;	subi.w	#$800,(a1)      ; Reposition the camera around the loop (fixed $800 size)
	cmpi.w	#-$100,4(a2)	; Test if the level is meant to loop at the top (and bottom)
	bgt.s	+
	sub.w	d1,(a1)         ; Reposition the camera around the loop (size given by level size array, should work)
	bra.s	loc_D868
; ===========================================================================
+
	move.w	6(a2),d1	; prevent camera from going any further down

loc_D868:
	move.w	(a1),d4		; get old pos
	swap	d1
	move.l	d1,d3
	sub.l	(a1),d3
	ror.l	#8,d3
	move.w	d3,(a4)		; set difference between old and new positions
	move.l	d1,(a1)		; set new camera Y pos
	rts
; End of function ScrollVerti

; ---------------------------------------------------------------------------
; Subroutine to set vertical scroll flags
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


SetVertiScrollFlags:
	move.w	(a1),d0		; get camera Y pos
	andi.w	#$10,d0
	move.b	(a2),d1
	eor.b	d1,d0		; has the camera crossed a 16-pixel boundary?
	bne.s	++		; if not, branch
	eori.b	#$10,(a2)
	move.w	(a1),d0		; get camera Y pos
	sub.w	d4,d0		; subtract old camera Y pos
	bpl.s	+		; branch if the camera has scrolled down
	bset	#0,(a3)		; set moving up in level bit
	rts
; ===========================================================================
+
	bset	#1,(a3)		; set moving down in level bit
+
	rts
; End of function SetVertiScrollFlags


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; d4 is horizontal, d5 vertical, derived from $FFFFEEB0 & $FFFFEEB2 respectively

;sub_D89A:
Hztl_Vrtc_Bg_Deformation: ; used by lev2, MTZ, HTZ, CPZ, DEZ, SCZ, Minimal
	move.l	(Camera_BG_X_pos).w,d2
	move.l	d2,d0
	add.l	d4,d0	; add x-shift for this frame
	move.l	d0,(Camera_BG_X_pos).w
	move.l	d0,d1
	swap	d1
	andi.w	#$10,d1
	move.b	(Horiz_block_crossed_flag_BG).w,d3
	eor.b	d3,d1
	bne.s	++
	eori.b	#$10,(Horiz_block_crossed_flag_BG).w
	sub.l	d2,d0
	bpl.s	+
	bset	#2,(Scroll_flags_BG).w
	bra.s	++
; ===========================================================================
+
	bset	#3,(Scroll_flags_BG).w
+
	move.l	(Camera_BG_Y_pos).w,d3
	move.l	d3,d0
	add.l	d5,d0	; add y-shift for this frame
	move.l	d0,(Camera_BG_Y_pos).w
	move.l	d0,d1
	swap	d1
	andi.w	#$10,d1
	move.b	(Verti_block_crossed_flag_BG).w,d2
	eor.b	d2,d1
	bne.s	++	; rts
	eori.b	#$10,(Verti_block_crossed_flag_BG).w
	sub.l	d3,d0
	bpl.s	+
	bset	#0,(Scroll_flags_BG).w
	rts
; ===========================================================================
+
	bset	#1,(Scroll_flags_BG).w
+
	rts
; End of function Hztl_Vrtc_Bg_Deformation


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_D904:
Horizontal_Bg_Deformation:	; used by WFZ, HTZ, HPZ
	move.l	(Camera_BG_X_pos).w,d2
	move.l	d2,d0
	add.l	d4,d0	; add x-shift for this frame
	move.l	d0,(Camera_BG_X_pos).w
	move.l	d0,d1
	swap	d1
	andi.w	#$10,d1
	move.b	(Horiz_block_crossed_flag_BG).w,d3
	eor.b	d3,d1
	bne.s	++	; rts
	eori.b	#$10,(Horiz_block_crossed_flag_BG).w
	sub.l	d2,d0
	bpl.s	+
	bset	d6,(Scroll_flags_BG).w
	bra.s	++	; rts
; ===========================================================================
+
	addq.b	#1,d6
	bset	d6,(Scroll_flags_BG).w
+
	rts
; End of function Horizontal_Bg_Deformation


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_D938:
Vertical_Bg_Deformation1:		;	used by WFZ, HTZ, HPZ, ARZ
	move.l	(Camera_BG_Y_pos).w,d3
	move.l	d3,d0
	add.l	d5,d0	; add y-shift for this frame

;loc_D940:
Vertical_Bg_Deformation2:
	move.l	d0,(Camera_BG_Y_pos).w
	move.l	d0,d1
	swap	d1
	andi.w	#$10,d1
	move.b	(Verti_block_crossed_flag_BG).w,d2
	eor.b	d2,d1
	bne.s	++	; rts
	eori.b	#$10,(Verti_block_crossed_flag_BG).w
	sub.l	d3,d0
	bpl.s	+
	bset	d6,(Scroll_flags_BG).w	; everytime Verti_block_crossed_flag_BG changes from $10 to $00
	rts
; ===========================================================================
+
	addq.b	#1,d6
	bset	d6,(Scroll_flags_BG).w	; everytime Verti_block_crossed_flag_BG changes from $00 to $10
+
	rts
; End of function Vertical_Bg_Deformation1


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_D96C:
ARZ_Bg_Deformation:	; only used by ARZ
	move.l	($FFFFF672).w,d0
	add.l	d4,d0
	move.l	d0,($FFFFF672).w
	lea	(Camera_BG_X_pos).w,a1
	move.w	(a1),d2
	move.w	($FFFFF672).w,d0
	sub.w	d2,d0
	bcs.s	+
	bhi.s	++
	rts
; ===========================================================================
+
	cmpi.w	#-$10,d0
	bgt.s	++
	move.w	#-$10,d0
	bra.s	++
; ===========================================================================
+
	cmpi.w	#$10,d0
	blo.s	+
	move.w	#$10,d0
+
	add.w	(a1),d0
	move.w	d0,(a1)
	move.w	d0,d1
	andi.w	#$10,d1
	move.b	(Horiz_block_crossed_flag_BG).w,d3
	eor.b	d3,d1
	bne.s	++	; rts
	eori.b	#$10,(Horiz_block_crossed_flag_BG).w
	sub.w	d2,d0
	bpl.s	+
	bset	d6,(Scroll_flags_BG).w
	bra.s	++	; rts
; ===========================================================================
+
	addq.b	#1,d6
	bset	d6,(Scroll_flags_BG).w
+
	rts
; End of function ARZ_Bg_Deformation


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_D9C8:
CPZ_Bg_Deformation:	; only used by CPZ
	move.l	(Camera_BG2_X_pos).w,d2
	move.l	d2,d0
	add.l	d4,d0
	move.l	d0,(Camera_BG2_X_pos).w
	move.l	d0,d1
	swap	d1
	andi.w	#$10,d1
	move.b	(Horiz_block_crossed_flag_BG2).w,d3
	eor.b	d3,d1
	bne.s	++	; rts
	eori.b	#$10,(Horiz_block_crossed_flag_BG2).w
	sub.l	d2,d0
	bpl.s	+
	bset	d6,(Scroll_flags_BG2).w
	bra.s	++	; rts
; ===========================================================================
+
	addq.b	#1,d6
	bset	d6,(Scroll_flags_BG2).w
+
	rts
; End of function CPZ_Bg_Deformation

; ===========================================================================
; some apparently unused code
;	move.l	(Camera_BG3_X_pos).w,d2
;	move.l	d2,d0
;	add.l	d4,d0
;	move.l	d0,(Camera_BG3_X_pos).w
;	move.l	d0,d1
;	swap	d1
;	andi.w	#$10,d1
;	move.b	($FFFFEE46).w,d3
;	eor.b	d3,d1
;	bne.s	++	; rts
;	eori.b	#$10,($FFFFEE46).w
;	sub.l	d2,d0
;	bpl.s	+
;	bset	d6,(Scroll_flags_BG3).w
;	bra.s	++	; rts
;; ===========================================================================
;+
;	addq.b	#1,d6
;	bset	d6,(Scroll_flags_BG3).w
;+
;	rts
; ===========================================================================
; Unused - dead code leftover from S1:
	lea	(VDP_control_port).l,a5
	lea	(VDP_data_port).l,a6
	lea	(Scroll_flags_BG).w,a2
	lea	(Camera_BG_X_pos).w,a3
	move.l	(LevelUncLayout).l,a4	; first background line
; 	adda.l	#$80,a4
	adda.l	#$02,a4
	move.w	#$6000,d2
	bsr.w	Draw_BG1
	lea	(Scroll_flags_BG2).w,a2
	lea	(Camera_BG2_X_pos).w,a3
	bra.w	Draw_BG2

; ===========================================================================




; ---------------------------------------------------------------------------
; Subroutine to display correct tiles as you move
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; loc_DA5C:
LoadTilesAsYouMove:
	lea	(VDP_control_port).l,a5
	lea	(VDP_data_port).l,a6
	lea	(Scroll_flags_BG_copy).w,a2
	lea	(Camera_BG_copy).w,a3
	move.l	(LevelUncLayout).l,a4	; first background line
; 	adda.l	#$80,a4
	adda.l	#$02,a4
	move.w	#$6000,d2
	bsr.w	Draw_BG1
	lea	(Scroll_flags_BG2_copy).w,a2
	lea	(Camera_BG2_copy).w,a3	; used in CPZ deformation routine
	bsr.w	Draw_BG2
	;lea	(Scroll_flags_BG3_copy).w,a2	; used in CPZ deformation routine
	;lea	(Camera_BG3_copy).w,a3
	;bsr.w	Draw_BG3
	tst.w	(Two_player_mode).w
	beq.s	+
	lea	(Scroll_flags_copy_P2).w,a2
	lea	(Camera_P2_copy).w,a3	; second player camera
	move.l	(LevelUncLayout).l,a4
	move.w	#$6000,d2
	bsr.w	Draw_FG_P2

+
	lea	(Scroll_flags_copy).w,a2
	lea	(Camera_RAM_copy).w,a3
	move.l	(LevelUncLayout).l,a4
	move.w	#$4000,d2
	tst.b	(Dirty_flag).w

	; comment out this line to disable blast processing
	beq.s	Draw_FG

	move.b	#0,(Dirty_flag).w
	moveq	#-$10,d4
	moveq	#$F,d6
; loc_DACE:
Draw_All:
	movem.l	d4-d6,-(sp)	; This whole routine basically redraws the whole
	moveq	#-$10,d5	; area instead of merely a line of tiles
	move.w	d4,d1
	bsr.w	CalcBlockVRAMPos
	move.w	d1,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockRow1	; draw the current row
	movem.l	(sp)+,d4-d6
	addi.w	#$10,d4		; move onto the next row
	dbf	d6,Draw_All	; repeat for all rows
	move.b	#0,(Scroll_flags_copy).w
	rts
; ===========================================================================
; loc_DAF6:
Draw_FG:
	tst.b	(a2)		; is any scroll flag set?
	beq.s	return_DB5A	; if not, branch
	bclr	#0,(a2)		; has the level scrolled up?
	beq.s	+		; if not, branch
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockRow1	; redraw upper row
+
	bclr	#1,(a2)		; has the level scrolled down?
	beq.s	+		; if not, branch
	move.w	#224,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	move.w	#224,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockRow1	; redraw bottom row
+
	bclr	#2,(a2)		; has the level scrolled to the left?
	beq.s	+	; if not, branch
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockCol1	; redraw left-most column
+
	bclr	#3,(a2)		; has the level scrolled to the right?
	beq.s	return_DB5A	; if not, return
	moveq	#-$10,d4
	move.w	#320,d5
	bsr.w	CalcBlockVRAMPos
	moveq	#-$10,d4
	move.w	#320,d5
	bsr.w	DrawBlockCol1	; redraw right-most column

return_DB5A:
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_DB5C:
Draw_FG_P2:
	tst.b	(a2)
	beq.s	return_DBC0
	bclr	#0,(a2)
	beq.s	+
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	loc_E2C2
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockRow1
+
	bclr	#1,(a2)
	beq.s	+
	move.w	#$E0,d4
	moveq	#-$10,d5
	bsr.w	loc_E2C2
	move.w	#$E0,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockRow1
+
	bclr	#2,(a2)
	beq.s	+
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	loc_E2C2
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockCol1
+
	bclr	#3,(a2)
	beq.s	return_DBC0
	moveq	#-$10,d4
	move.w	#320,d5
	bsr.w	loc_E2C2
	moveq	#-$10,d4
	move.w	#320,d5
	bsr.w	DrawBlockCol1

return_DBC0:
	rts
; End of function Draw_FG_P2


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_DBC2:
Draw_BG1:
	tst.b	(a2)
	beq.w	return_DC90
	bclr	#0,(a2)
	beq.s	+
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockRow1
+
	bclr	#1,(a2)
	beq.s	+
	move.w	#$E0,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	move.w	#$E0,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockRow1
+
	bclr	#2,(a2)
	beq.s	+
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	DrawBlockCol1
+
	bclr	#3,(a2)
	beq.s	+
	moveq	#-$10,d4
	move.w	#320,d5
	bsr.w	CalcBlockVRAMPos
	moveq	#-$10,d4
	move.w	#320,d5
	bsr.w	DrawBlockCol1
+
	bclr	#4,(a2)
	beq.s	+
	moveq	#-$10,d4
	moveq	#0,d5
	bsr.w	CalcBlockVRAMPos2
	moveq	#-$10,d4
	moveq	#0,d5
	moveq	#$1F,d6
	bsr.w	DrawBlockRow2
+
	bclr	#5,(a2)
	beq.s	+
	move.w	#$E0,d4
	moveq	#0,d5
	bsr.w	CalcBlockVRAMPos2
	move.w	#$E0,d4
	moveq	#0,d5
	moveq	#$1F,d6
	bsr.w	DrawBlockRow2
+
	bclr	#6,(a2)
	beq.s	+
	moveq	#-$10,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	moveq	#-$10,d4
	moveq	#-$10,d5
	moveq	#$1F,d6
	bsr.w	DrawBlockRow
+
	bclr	#7,(a2)
	beq.s	return_DC90
	move.w	#$E0,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	move.w	#$E0,d4
	moveq	#-$10,d5
	moveq	#$1F,d6
	bsr.w	DrawBlockRow

return_DC90:
	rts
; End of function Draw_BG1


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_DC92:
Draw_BG2:
	tst.b	(a2)
	beq.w	++	; rts
	bclr	#0,(a2)
	beq.s	+
	move.w	#$70,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	move.w	#$70,d4
	moveq	#-$10,d5
	moveq	#2,d6
	bsr.w	DrawBlockCol2
+
	bclr	#1,(a2)
	beq.s	+	; rts
	move.w	#$70,d4
	move.w	#320,d5
	bsr.w	CalcBlockVRAMPos
	move.w	#$70,d4
	move.w	#320,d5
	moveq	#2,d6
	bsr.w	DrawBlockCol2
+
	rts
; End of function Draw_BG2

; ===========================================================================
byte_DCD6:	; unused array
	dc.b   0
	dc.b   0	; 1
	dc.b   0	; 2
	dc.b   0	; 3
	dc.b   0	; 4
	dc.b   6	; 5
	dc.b   6	; 6
	dc.b   6	; 7
	dc.b   6	; 8
	dc.b   6	; 9
	dc.b   6	; 10
	dc.b   6	; 11
	dc.b   6	; 12
	dc.b   6	; 13
	dc.b   6	; 14
	dc.b   4	; 15
	dc.b   4	; 16
	dc.b   4	; 17
	dc.b   4	; 18
	dc.b   4	; 19
	dc.b   4	; 20
	dc.b   4	; 21
	dc.b   2	; 22
	dc.b   2	; 23
	dc.b   2	; 24
	dc.b   2	; 25
	dc.b   2	; 26
	dc.b   2	; 27
	dc.b   2	; 28
	dc.b   2	; 29
	dc.b   2	; 30
	dc.b   2	; 31
	dc.b   2	; 32
	dc.b   0	; 33
; ===========================================================================
; begin unused routine
	moveq	#-$10,d4
	bclr	#0,(a2)
	bne.s	+
	bclr	#1,(a2)
	beq.s	+++
	move.w	#$E0,d4
+
	lea	byte_DCD6+1(pc),a0
	move.w	(Camera_BG_Y_pos).w,d0
	add.w	d4,d0
	andi.w	#$1F0,d0
	lsr.w	#4,d0
	move.b	(a0,d0.w),d0
	lea	(word_DE7E).l,a3
	movea.w	(a3,d0.w),a3
	beq.s	+
	moveq	#-$10,d5
	movem.l	d4-d5,-(sp)
	bsr.w	CalcBlockVRAMPos
	movem.l	(sp)+,d4-d5
	bsr.w	DrawBlockRow1
	bra.s	++
; ===========================================================================
+
	moveq	#0,d5
	movem.l	d4-d5,-(sp)
	bsr.w	CalcBlockVRAMPos2
	movem.l	(sp)+,d4-d5
	moveq	#$1F,d6
	bsr.w	DrawBlockRow2
+
	tst.b	(a2)
	bne.s	+
	rts
; ===========================================================================
+
	moveq	#-$10,d4
	moveq	#-$10,d5
	move.b	(a2),d0
	andi.b	#-$58,d0
	beq.s	+
	lsr.b	#1,d0
	move.b	d0,(a2)
	move.w	#320,d5
+
	lea	byte_DCD6(pc),a0
	move.w	(Camera_BG_Y_pos).w,d0
	andi.w	#$1F0,d0
	lsr.w	#4,d0
	lea	(a0,d0.w),a0
	bra.w	loc_DE86
; end unused routine

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

;sub_DD82:
Draw_BG3:
	tst.b	(a2)
	beq.w	++	; rts
	cmpi.b	#chemical_plant_zone,(Current_Zone).w
	beq.w	Draw_BG3_CPZ
	bclr	#0,(a2)
	beq.s	+
	move.w	#$40,d4
	moveq	#-$10,d5
	bsr.w	CalcBlockVRAMPos
	move.w	#$40,d4
	moveq	#-$10,d5
	moveq	#2,d6
	bsr.w	DrawBlockCol2
+
	bclr	#1,(a2)
	beq.s	+	; rts
	move.w	#$40,d4
	move.w	#320,d5
	bsr.w	CalcBlockVRAMPos
	move.w	#$40,d4
	move.w	#320,d5
	moveq	#2,d6
	bsr.w	DrawBlockCol2
+
	rts
; ===========================================================================
byte_DDD0:
	dc.b   2
	dc.b   2	; 1
	dc.b   2	; 2
	dc.b   2	; 3
	dc.b   2	; 4
	dc.b   2	; 5
	dc.b   2	; 6
	dc.b   2	; 7
	dc.b   2	; 8
	dc.b   2	; 9
	dc.b   2	; 10
	dc.b   2	; 11
	dc.b   2	; 12
	dc.b   2	; 13
	dc.b   2	; 14
	dc.b   2	; 15
	dc.b   2	; 16
	dc.b   2	; 17
	dc.b   2	; 18
	dc.b   2	; 19
	dc.b   4	; 20
	dc.b   4	; 21
	dc.b   4	; 22
	dc.b   4	; 23
	dc.b   4	; 24
	dc.b   4	; 25
	dc.b   4	; 26
	dc.b   4	; 27
	dc.b   4	; 28
	dc.b   4	; 29
	dc.b   4	; 30
	dc.b   4	; 31
	dc.b   4	; 32
	dc.b   4	; 33
	dc.b   4	; 34
	dc.b   4	; 35
	dc.b   4	; 36
	dc.b   4	; 37
	dc.b   4	; 38
	dc.b   4	; 39
	dc.b   4	; 40
	dc.b   4	; 41
	dc.b   4	; 42
	dc.b   4	; 43
	dc.b   4	; 44
	dc.b   4	; 45
	dc.b   4	; 46
	dc.b   4	; 47
	dc.b   4	; 48
	dc.b   4	; 49
	dc.b   4	; 50
	dc.b   4	; 51
	dc.b   4	; 52
	dc.b   4	; 53
	dc.b   4	; 54
	dc.b   4	; 55
	dc.b   4	; 56
	dc.b   4	; 57
	dc.b   4	; 58
	dc.b   4	; 59
	dc.b   4	; 60
	dc.b   4	; 61
	dc.b   4	; 62
	dc.b   4	; 63
	dc.b   4	; 64
	dc.b   0	; 65
; ===========================================================================
; loc_DE12:
Draw_BG3_CPZ:
	moveq	#-$10,d4	; bit0 = top row
	bclr	#0,(a2)
	bne.s	+
	bclr	#1,(a2)
	beq.s	++
	move.w	#$E0,d4		; bit1 = bottom row
+
	lea	byte_DDD0+1(pc),a0
	move.w	(Camera_BG_Y_pos).w,d0
	add.w	d4,d0
	andi.w	#$3F0,d0
	lsr.w	#4,d0
	move.b	(a0,d0.w),d0
	movea.w	word_DE7E(pc,d0.w),a3	; Camera, either BG1 or BG2 depending on Y
	moveq	#-$10,d5
	movem.l	d4-d5,-(sp)
	bsr.w	CalcBlockVRAMPos
	movem.l	(sp)+,d4-d5
	bsr.w	DrawBlockRow1
+
	tst.b	(a2)
	bne.s	+
	rts
; ===========================================================================
+
	moveq	#-$10,d4
	moveq	#-$10,d5
	move.b	(a2),d0
	andi.b	#-$58,d0
	beq.s	+
	lsr.b	#1,d0
	move.b	d0,(a2)
	move.w	#320,d5
+
	lea	byte_DDD0(pc),a0
	move.w	(Camera_BG_Y_pos).w,d0
	andi.w	#$7F0,d0
	lsr.w	#4,d0
	lea	(a0,d0.w),a0
	bra.w	loc_DE86
; ===========================================================================
word_DE7E:
	dc.w $EE68	; BG Camera
	dc.w $EE68	; BG Camera
	dc.w $EE70	; BG2 Camera
	dc.w $EE78	; BG3 Camera (only referenced in unused array)
; ===========================================================================

loc_DE86:
	tst.w	(Two_player_mode).w
	bne.s	++
	moveq	#$F,d6
	move.l	#$800000,d7

-	moveq	#0,d0
	move.b	(a0)+,d0
	btst	d0,(a2)
	beq.s	+
	movea.w	word_DE7E(pc,d0.w),a3
	movem.l	d4-d5/a0,-(sp)
	movem.l	d4-d5,-(sp)
	bsr.w	sub_E244
	movem.l	(sp)+,d4-d5
	bsr.w	CalcBlockVRAMPos
	bsr.w	ProcessAndWriteBlock2
	movem.l	(sp)+,d4-d5/a0
+
	addi.w	#$10,d4
	dbf	d6,-

	clr.b	(a2)
	rts
; ===========================================================================
+
	moveq	#$F,d6
	move.l	#$800000,d7

-	moveq	#0,d0
	move.b	(a0)+,d0
	btst	d0,(a2)
	beq.s	+
	movea.w	word_DE7E(pc,d0.w),a3
	movem.l	d4-d5/a0,-(sp)
	movem.l	d4-d5,-(sp)
	bsr.w	sub_E244
	movem.l	(sp)+,d4-d5
	bsr.w	CalcBlockVRAMPos
	bsr.w	sub_E1FA
	movem.l	(sp)+,d4-d5/a0
+
	addi.w	#$10,d4
	dbf	d6,-

	clr.b	(a2)
	rts
; End of function Draw_BG3


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_DF04:
DrawBlockCol1:
	moveq	#$F,d6

DrawBlockCol2:
	add.w	(a3),d5		; add camera X pos
	add.w	4(a3),d4	; add camera Y pos
	move.l	#$800000,d7	; store VDP command for line increment
	move.l	d0,d1		; copy byte-swapped VDP command for later access
	bsr.w	GetBlockAddr
	tst.w	(Two_player_mode).w
	bne.s	++

-	move.w	(a0),d3		; get ID of the 16x16 block
	andi.w	#$3FF,d3
	lsl.w	#3,d3		; multiply by 8, the size in bytes of a 16x16
	lea	(Block_Table).w,a1
	adda.w	d3,a1		; a1 = address of the current 16x16 in the block table
	move.l	d1,d0
	bsr.w	ProcessAndWriteBlock2
	adda.w	#$10,a0		; move onto the 16x16 vertically below this one
	addi.w	#$100,d1	; draw on alternate 8x8 lines
	andi.w	#$FFF,d1
	addi.w	#$10,d4		; add 16 to Y offset
	move.w	d4,d0
	andi.w	#$70,d0		; have we reached a new 128x128?
	bne.s	+	; if not, branch
	bsr.w	GetBlockAddr	; otherwise, renew the block address
+	dbf	d6,-		; repeat 16 times

	rts
; ===========================================================================

/	move.w	(a0),d3
	andi.w	#$3FF,d3
	lsl.w	#3,d3
	lea	(Block_Table).w,a1
	adda.w	d3,a1
	move.l	d1,d0
	bsr.w	sub_E1FA
	adda.w	#$10,a0
	addi.w	#$80,d1
	andi.w	#$FFF,d1
	addi.w	#$10,d4
	move.w	d4,d0
	andi.w	#$70,d0
	bne.s	+
	bsr.w	GetBlockAddr
+	dbf	d6,-

	rts
; End of function DrawBlockCol1


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_DF8A: DrawTiles_Vertical:
DrawBlockRow:
	add.w	(a3),d5
	add.w	4(a3),d4
	bra.s	DrawBlockRow3
; End of function DrawBlockRow


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_DF92: DrawTiles_Vertical1:
DrawBlockRow1:
	moveq	#$15,d6
	add.w	(a3),d5		; add X pos
; loc_DF96: DrawTiles_Vertical2:
DrawBlockRow2:
	add.w	4(a3),d4	; add Y pos
; loc_DF9A: DrawTiles_Vertical3:
DrawBlockRow3:
	move.l	a2,-(sp)
	move.w	d6,-(sp)
	lea	(Block_cache).w,a2
	move.l	d0,d1
	or.w	d2,d1
	swap	d1		; make VRAM write command
	move.l	d1,-(sp)
	move.l	d1,(a5)		; set up a VRAM write at that address
	swap	d1
	bsr.w	GetBlockAddr

-	move.w	(a0),d3		; get ID of the 16x16 block
	andi.w	#$3FF,d3
	lsl.w	#3,d3		; multiply by 8, the size in bytes of a 16x16
	lea	(Block_Table).w,a1
	adda.w	d3,a1		; a1 = address of current 16x16 in the block table
	bsr.w	ProcessAndWriteBlock
	addq.w	#2,a0		; move onto next 16x16
	addq.b	#4,d1		; increment VRAM write address
	bpl.s	+
	andi.b	#$7F,d1		; restrict to a single 8x8 line
	swap	d1
	move.l	d1,(a5)		; set up a VRAM write at a new address
	swap	d1
+
	addi.w	#$10,d5		; add 16 to X offset
	move.w	d5,d0
	andi.w	#$70,d0		; have we reached a new 128x128?
	bne.s	+		; if not, branch
	bsr.w	GetBlockAddr	; otherwise, renew the block address
+
	dbf	d6,-		; repeat 22 times

	move.l	(sp)+,d1
	addi.l	#$800000,d1	; move onto next line
	lea	(Block_cache).w,a2
	move.l	d1,(a5)		; write to this VRAM address
	swap	d1
	move.w	(sp)+,d6

-	move.l	(a2)+,(a6)	; write stored 8x8s
	addq.b	#4,d1		; increment VRAM write address
	bmi.s	+
	ori.b	#$80,d1		; force to bottom 8x8 line
	swap	d1
	move.l	d1,(a5)		; set up a VRAM write at a new address
	swap	d1
+
	dbf	d6,-		; repeat 22 times

	movea.l	(sp)+,a2
	rts

; End of function DrawBlockRow1


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_E09E:
GetBlockAddr:
	movem.l	d4-d5,-(sp)
	move.w	d4,d3		; d3 = camera Y pos + offset
; 	add.w	d3,d3
; 	andi.w	#$F00,d3	; limit to units of $100 ($100 = $80 * 2, $80 = height of a 128x128)
	lsr.w	#7,d3		; divide by 128 for row (list entry)
	add.w	d3,d3		; double it (WORD data)
	add.w	d3,d3		; double it (FG and BG WORDs are interleaved)
	add.w	#8,d3		; Skip the Size Information
	move.w	(a4,d3.w),d3	; get row offset data for this row
	and.w	#$7FFF,d3	; Strip the high bit from the value
	cmpa.l	(LevelUncLayout).l,a4
	beq	+
	suba.l	2,a4
+
	lsr.w	#3,d5		; divide by 8
	move.w	d5,d0
	lsr.w	#4,d0		; divide by 16 (overall division of 128)
; 	andi.w	#$FF,d0		; Layout smaller 7F
	add.w	d3,d0		; get offset of current 128x128 in the level layout table
	moveq	#-1,d3
	clr.w	d3		; d3 = $FFFF0000
	move.b	(a4,d0.w),d3	; get tile ID of the current 128x128 tile
	lsl.w	#7,d3		; multiply by 128, the size in bytes of a 128x128 in RAM
	andi.w	#$70,d4		; round down to nearest 16-pixel boundary
	andi.w	#$E,d5		; force this to be a multiple of 16
	add.w	d4,d3		; add vertical offset of current 16x16
	add.w	d5,d3		; add horizontal offset of current 16x16
	movea.l	d3,a0		; store address, in the metablock table, of the current 16x16
	movem.l	(sp)+,d4-d5
	rts
; End of function GetBlockAddr


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_E0D4:
ProcessAndWriteBlock:
	btst	#3,(a0)		; is this 16x16 to be Y-flipped?
	bne.s	ProcessAndWriteBlock_FlipY	; if it is, branch
	btst	#2,(a0)		; is this 16x16 to be X-flipped?
	bne.s	ProcessAndWriteBlock_FlipX	; if it is, branch
	move.l	(a1)+,(a6)	; write top two 8x8s to VRAM
	move.l	(a1)+,(a2)+	; store bottom two 8x8s for later writing
	rts
; ===========================================================================

ProcessAndWriteBlock_FlipX:
	move.l	(a1)+,d3
	eori.l	#$8000800,d3	; toggle X-flip flag of the 8x8s
	swap	d3		; swap the position of the 8x8s
	move.l	d3,(a6)		; write top two 8x8s to VRAM
	move.l	(a1)+,d3
	eori.l	#$8000800,d3
	swap	d3
	move.l	d3,(a2)+	; store bottom two 8x8s for later writing
	rts
; ===========================================================================

ProcessAndWriteBlock_FlipY:
	btst	#2,(a0)		; is this 16x16 to be X-flipped as well?
	bne.s	ProcessAndWriteBlock_FlipXY	; if it is, branch
	move.l	(a1)+,d0
	move.l	(a1)+,d3
	eori.l	#$10001000,d3	; toggle Y-flip flag of the 8x8s
	move.l	d3,(a6)		; write bottom two 8x8s to VRAM
	eori.l	#$10001000,d0
	move.l	d0,(a2)+	; store top two 8x8s for later writing
	rts
; ===========================================================================

ProcessAndWriteBlock_FlipXY:
	move.l	(a1)+,d0
	move.l	(a1)+,d3
	eori.l	#$18001800,d3	; toggle X and Y-flip flags of the 8x8s
	swap	d3
	move.l	d3,(a6)		; write bottom two 8x8s to VRAM
	eori.l	#$18001800,d0
	swap	d0
	move.l	d0,(a2)+	; store top two 8x8s for later writing
	rts
; End of function ProcessAndWriteBlock


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_E136:
	btst	#3,(a0)
	bne.s	loc_E154
	btst	#2,(a0)
	bne.s	loc_E146
	move.l	(a1)+,(a6)
	rts
; ===========================================================================

loc_E146:
	move.l	(a1)+,d3
	eori.l	#$8000800,d3
	swap	d3
	move.l	d3,(a6)
	rts
; ===========================================================================

loc_E154:
	btst	#2,(a0)
	bne.s	loc_E166
	move.l	(a1)+,d3
	eori.l	#$10001000,d3
	move.l	d3,(a6)
	rts
; ===========================================================================

loc_E166:
	move.l	(a1)+,d3
	eori.l	#$18001800,d3
	swap	d3
	move.l	d3,(a6)
	rts
; End of function sub_E136


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_E174:
ProcessAndWriteBlock2:
	or.w	d2,d0
	swap	d0		; make VRAM write command
	btst	#3,(a0)		; is the 16x16 to be Y-flipped?
	bne.s	ProcessAndWriteBlock2_FlipY	; if it is, branch
	btst	#2,(a0)		; is the 16x16 to be X-flipped?
	bne.s	ProcessAndWriteBlock2_FlipX	; if it is, branch
	move.l	d0,(a5)		; write to this VRAM address
	move.l	(a1)+,(a6)	; write top two 8x8s
	add.l	d7,d0		; move onto next line
	move.l	d0,(a5)
	move.l	(a1)+,(a6)	; write bottom two 8x8s
	rts
; ===========================================================================

ProcessAndWriteBlock2_FlipX:
	move.l	d0,(a5)
	move.l	(a1)+,d3
	eori.l	#$8000800,d3	; toggle X-flip flag of the 8x8s
	swap	d3		; swap the position of the 8x8s
	move.l	d3,(a6)		; write top two 8x8s
	add.l	d7,d0		; move onto next line
	move.l	d0,(a5)
	move.l	(a1)+,d3
	eori.l	#$8000800,d3
	swap	d3
	move.l	d3,(a6)		; write bottom two 8x8s
	rts
; ===========================================================================

ProcessAndWriteBlock2_FlipY:
	btst	#2,(a0)		; is the 16x16 to be X-flipped as well?
	bne.s	ProcessAndWriteBlock2_FlipXY	; if it is, branch
	move.l	d5,-(sp)
	move.l	d0,(a5)
	move.l	(a1)+,d5
	move.l	(a1)+,d3
	eori.l	#$10001000,d3	; toggle Y-flip flag of 8x8s
	move.l	d3,(a6)		; write bottom two 8x8s
	add.l	d7,d0		; move onto next line
	move.l	d0,(a5)
	eori.l	#$10001000,d5
	move.l	d5,(a6)		; write top two 8x8s
	move.l	(sp)+,d5
	rts
; ===========================================================================

ProcessAndWriteBlock2_FlipXY:
	move.l	d5,-(sp)
	move.l	d0,(a5)
	move.l	(a1)+,d5
	move.l	(a1)+,d3
	eori.l	#$18001800,d3	; toggle X and Y-flip flags of 8x8s
	swap	d3		; swap the position of the 8x8s
	move.l	d3,(a6)		; write bottom two 8x8s
	add.l	d7,d0
	move.l	d0,(a5)
	eori.l	#$18001800,d5
	swap	d5
	move.l	d5,(a6)		; write top two 8x8s
	move.l	(sp)+,d5
	rts
; End of function ProcessAndWriteBlock2


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_E1FA:
	or.w	d2,d0
	swap	d0
	btst	#3,(a0)
	bne.s	loc_E220
	btst	#2,(a0)
	bne.s	loc_E210
	move.l	d0,(a5)
	move.l	(a1)+,(a6)
	rts
; ===========================================================================

loc_E210:
	move.l	d0,(a5)
	move.l	(a1)+,d3
	eori.l	#$8000800,d3
	swap	d3
	move.l	d3,(a6)
	rts
; ===========================================================================

loc_E220:
	btst	#2,(a0)
	bne.s	loc_E234
	move.l	d0,(a5)
	move.l	(a1)+,d3
	eori.l	#$10001000,d3
	move.l	d3,(a6)
	rts
; ===========================================================================

loc_E234:
	move.l	d0,(a5)
	move.l	(a1)+,d3
	eori.l	#$18001800,d3
	swap	d3
	move.l	d3,(a6)
	rts
; End of function sub_E1FA


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_E244:
	add.w	(a3),d5
	add.w	4(a3),d4
	lea	(Block_Table).w,a1
	move.w	d4,d3
	add.w	d3,d3
	andi.w	#$F00,d3
	lsr.w	#3,d5
	move.w	d5,d0
	lsr.w	#4,d0
	andi.w	#$7F,d0	; layout size
	add.w	d3,d0
	moveq	#-1,d3
	clr.w	d3
	move.b	(a4,d0.w),d3
	lsl.w	#7,d3
	andi.w	#$70,d4
	andi.w	#$E,d5
	add.w	d4,d3
	add.w	d5,d3
	movea.l	d3,a0
	move.w	(a0),d3
	andi.w	#$3FF,d3
	lsl.w	#3,d3
	adda.w	d3,a1
	rts
; End of function sub_E244


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_E286: Calc_VRAM_Pos:
CalcBlockVRAMPos:
	add.w	(a3),d5		; add X pos

CalcBlockVRAMPos2:
	add.w	4(a3),d4	; add Y pos
	andi.w	#$F0,d4		; round down to the nearest 16-pixel boundary
	andi.w	#$1F0,d5	; round down to the nearest 16-pixel boundary
	lsl.w	#4,d4		; make it into units of $100 - the height in plane A of a 16x16
	lsr.w	#2,d5		; make it into units of 4 - the width in plane A of a 16x16
	add.w	d5,d4		; combine the two to get final address
	moveq	#3,d0		; access a VDP address >= $C000
	swap	d0
	move.w	d4,d0		; make word-swapped VDP command
	rts
; End of function CalcBlockVRAMPos


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


loc_E2C2:
	add.w	4(a3),d4
	add.w	(a3),d5
	andi.w	#$F0,d4
	andi.w	#$1F0,d5
	lsl.w	#4,d4
	lsr.w	#2,d5
	add.w	d5,d4
	moveq	#2,d0
	swap	d0
	move.w	d4,d0
	rts

; ===========================================================================

loc_E300:
	lea	(VDP_control_port).l,a5
	lea	(VDP_data_port).l,a6
	lea	(Camera_BG_X_pos).w,a3
	move.l	(LevelUncLayout).l,a4	; first background line
; 	adda.l	#$80,a4
	adda.l	#$02,a4
	move.w	#$6000,d2
	moveq	#0,d4
	cmpi.b	#casino_night_zone,(Current_Zone).w
	beq.w	++
	tst.w	(Two_player_mode).w
	beq.w	+
	cmpi.b	#mystic_cave_zone,(Current_Zone).w
	beq.w	loc_E396
+
	moveq	#-$10,d4
+
	moveq	#$F,d6
-	movem.l	d4-d6,-(sp)
	moveq	#0,d5
	move.w	d4,d1
	bsr.w	CalcBlockVRAMPos
	move.w	d1,d4
	moveq	#0,d5
	moveq	#$1F,d6
	move	#$2700,sr
	bsr.w	DrawBlockRow
	move	#$2300,sr
	movem.l	(sp)+,d4-d6
	addi.w	#$10,d4
	dbf	d6,-

	rts
; ===========================================================================
	moveq	#-$10,d4

	moveq	#$F,d6
-	movem.l	d4-d6,-(sp)
	moveq	#0,d5
	move.w	d4,d1
	bsr.w	loc_E2C2
	move.w	d1,d4
	moveq	#0,d5
	moveq	#$1F,d6
	move	#$2700,sr
	bsr.w	DrawBlockRow
	move	#$2300,sr
	movem.l	(sp)+,d4-d6
	addi.w	#$10,d4
	dbf	d6,-

	rts
; ===========================================================================

loc_E396:
	moveq	#0,d4

	moveq	#$1F,d6
-	movem.l	d4-d6,-(sp)
	moveq	#0,d5
	move.w	d4,d1
	bsr.w	loc_E2AC
	move.w	d1,d4
	moveq	#0,d5
	moveq	#$1F,d6
	move	#$2700,sr
	bsr.w	DrawBlockRow3
	move	#$2300,sr
	movem.l	(sp)+,d4-d6
	addi.w	#$10,d4
	dbf	d6,-

	rts
; ===========================================================================
loc_E2AC:
	andi.w	#$1F0,d4
	andi.w	#$1F0,d5
	lsl.w	#3,d4
	lsr.w	#2,d5
	add.w	d5,d4
	moveq	#3,d0
	swap	d0
	move.w	d4,d0
	rts
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; loadZoneBlockMaps

; Loads block and bigblock mappings for the current Zone.

loadZoneBlockMaps:
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	add.w	d0,d0
	add.w	d0,d0
	move.w	d0,d1
	add.w	d0,d0
	add.w	d1,d0
	lea	(LevelArtPointers).l,a2
	lea	(a2,d0.w),a2
	move.l	a2,-(sp)
	addq.w	#4,a2
	move.l	(a2)+,d0
	andi.l	#$FFFFFF,d0	; pointer to block mappings
	movea.l	d0,a0
	lea	(Block_Table).w,a1
	bsr.w	JmpTo_KosDec	; load block maps
+
	tst.w	(Two_player_mode).w
	beq.s	+
	; In 2P mode, adjust the block table to halve the pattern index on each block
	lea	(Block_Table).w,a1

	move.w	#bytesToWcnt(Block_Table_End-Block_Table),d2
-	move.w	(a1),d0		; read an entry
	move.w	d0,d1
	andi.w	#$F800,d0	; filter for upper five bits
	andi.w	#$7FF,d1	; filter for lower eleven bits (patternIndex)
	lsr.w	#1,d1		; halve the pattern index
	or.w	d1,d0		; put the parts back together
	move.w	d0,(a1)+	; change the entry with the adjusted value
	dbf	d2,-
+
	move.l	(a2)+,d0
	andi.l	#$FFFFFF,d0	; pointer to chunk mappings
	movea.l	d0,a0
	lea	(Chunk_Table).l,a1
	bsr.w	JmpTo_KosDec
	bsr.w	loadLevelLayout
	movea.l	(sp)+,a2	; zone specific pointer in LevelArtPointers
	addq.w	#4,a2
	moveq	#0,d0
	move.b	(a2),d0	; PLC2 ID
	beq.s	+
	bsr.w	JmpTo_LoadPLC
+
	addq.w	#4,a2
	moveq	#0,d0
	move.b	(a2),d0	; palette ID
	jsr	PalLoad1
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


loadLevelLayout:
	moveq	#0,d0
	move.w	(Current_ZoneAndAct).w,d0
	ror.b	#1,d0
	lsr.w	#6,d0
	lea	(Off_Level).l,a0
	move.w	(a0,d0.w),d0
	lea	(a0,d0.l),a0
	move.l	a0,(LevelUncLayout).l
	;move.w	(a0,d0.w),d0
	;lea	(a0,d0.l),a0
	;lea	(Level_Layout).w,a1
	;bra.w	JmpTo_KosDec
	rts
; End of function loadLevelLayout

; ===========================================================================
	move.l	(LevelUncLayout).l,a3
	move.w	#bytesToLcnt(Level_Layout_End-Level_Layout),d1
	moveq	#0,d0

-	move.l	d0,(a3)+
	dbf	d1,-

	move.l	(LevelUncLayout).l,a3
	moveq	#0,d1
	bsr.w	sub_E4A2
	move.l	(LevelUncLayout).l,a3
; 	adda.l	#$80,a3
	adda.l	#$02,a4
	moveq	#2,d1

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_E4A2:
	moveq	#0,d0
	move.w	(Current_ZoneAndAct).w,d0
	ror.b	#1,d0
	lsr.w	#5,d0
	add.w	d1,d0
	lea	(Off_Level).l,a1
	move.w	(a1,d0.w),d0
	lea	(a1,d0.l),a1
	moveq	#0,d1
	move.w	d1,d2
	move.b	(a1)+,d1
	move.b	(a1)+,d2
	move.l	d1,d5
	addq.l	#1,d5
	moveq	#0,d3
	move.w	#$80,d3
	divu.w	d5,d3
	subq.w	#1,d3

-	movea.l	a3,a0

	move.w	d3,d4
-	move.l	a1,-(sp)

	move.w	d1,d0
-	move.b	(a1)+,(a0)+
	dbf	d0,-

	movea.l	(sp)+,a1
	dbf	d4,--

	lea	(a1,d5.w),a1
	lea	$100(a3),a3
	dbf	d2,---

	rts
; End of function sub_E4A2

; ===========================================================================
	lea	($FE0000).l,a1
	lea	($FE0080).l,a2
	lea	(Chunk_Table).l,a3

	move.w	#$3F,d1
-	bsr.w	sub_E59C
	bsr.w	sub_E59C
	dbf	d1,-

	lea	($FE0000).l,a1
	lea	($FF0000).l,a2

	move.w	#$3F,d1
-	move.w	#0,(a2)+
	dbf	d1,-

	move.w	#$3FBF,d1
-	move.w	(a1)+,(a2)+
	dbf	d1,-

	rts
; ===========================================================================
	lea	($FE0000).l,a1
	lea	(Chunk_Table).l,a3

	moveq	#$1F,d0
-	move.l	(a1)+,(a3)+
	dbf	d0,-

	moveq	#0,d7
	lea	($FE0000).l,a1
	move.w	#$FF,d5

loc_E55A:
	lea	(Chunk_Table).l,a3
	move.w	d7,d6

-	movem.l	a1-a3,-(sp)
	move.w	#$3F,d0

-	cmpm.w	(a1)+,(a3)+
	bne.s	+
	dbf	d0,-
	movem.l	(sp)+,a1-a3
	adda.w	#$80,a1
	dbf	d5,loc_E55A

	bra.s	++
; ===========================================================================
+	movem.l	(sp)+,a1-a3
	adda.w	#$80,a3
	dbf	d6,--

	moveq	#$1F,d0
-	move.l	(a1)+,(a3)+
	dbf	d0,-

	addq.l	#1,d7
	dbf	d5,loc_E55A
/
	bra.s	-	; infinite loop

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_E59C:
	moveq	#7,d0
-	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a1)+
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	dbf	d0,-

	adda.w	#$80,a1
	adda.w	#$80,a2
	rts
; End of function sub_E59C


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


JmpTo_PalLoad2
	jmp	(PalLoad2).l
; End of function JmpTo_PalLoad2


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


JmpTo_LoadPLC
	jmp	(LoadPLC).l
; End of function JmpTo_LoadPLC


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


JmpTo_KosDec
	jmp	(KosDec).l
; End of function JmpTo_KosDec

; ===========================================================================
	align 4




; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; screen resizing, earthquakage, etc

; sub_E5D0:
RunDynamicLevelEvents:
;	moveq	#0,d0
;	move.b	(Current_Zone).w,d0
;	add.w	d0,d0
;	move.w	DynamicLevelEventIndex(pc,d0.w),d0
;	jsr	DynamicLevelEventIndex(pc,d0.w)
	moveq	#2,d1
	move.w	(Camera_Max_Y_pos).w,d0
	sub.w	(Camera_Max_Y_pos_now).w,d0
	beq.s	++	; rts
	bcc.s	+++
	neg.w	d1
	move.w	(Camera_Y_pos).w,d0
	cmp.w	(Camera_Max_Y_pos).w,d0
	bls.s	+
	move.w	d0,(Camera_Max_Y_pos_now).w
	andi.w	#$FFFE,(Camera_Max_Y_pos_now).w
+
	add.w	d1,(Camera_Max_Y_pos_now).w
	move.b	#1,($FFFFEEDE).w
+
	rts
; ===========================================================================
+
	move.w	(Camera_Y_pos).w,d0
	addi.w	#8,d0
	cmp.w	(Camera_Max_Y_pos_now).w,d0
	blo.s	+
	btst	#1,(MainCharacter+status).w
	beq.s	+
	add.w	d1,d1
	add.w	d1,d1
+
	add.w	d1,(Camera_Max_Y_pos_now).w
	move.b	#1,($FFFFEEDE).w
	rts
; End of function RunDynamicLevelEvents
; ===========================================================================
; ===========================================================================
; Routine to Check for act transitions and run them
; ===========================================================================
RunActTransitions
	tst.b	(Current_Act).w
	bne.w	NoActTransitions
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	ext.w	d0
	add.w	d0,d0
	lea		WrdArr_ActTransitionCheck(pc,d0.w),a0
	move.w	a0,d0
	move.w	(camera_X_pos).w,d1
	cmp.w	d0,d1
	bge.w	TriggerEvent
	rts
NoActTransitions:
	rts
WrdArr_ActTransitionCheck:
	dc.w	$7E00
	dc.w	$7E00
TriggerEvent:
		tst.b	(ActTransitionStartFlag).w
		beq.w	NoActTransitions
		clr.b	(ActTransitionStartFlag).w
		movem.l	d7-a0/a2-a3,-(sp)
		moveq	#$28,d0
		jsr	(LoadPLC).l
		;jsr	LoadTitleCard
		move.w	#1,($FFFFFE10).w
		clr.b	(Dynamic_Resize_Routine).w
		clr.b	(Obj_placement_routine).w
		clr.b	($FFFFF710).w
		clr.b	(Current_Boss_ID).w
		jsr	LoadLevelLayout
		jsr	(LoadCollisionIndexes).l
		jsr	sub_4F8F8(pc)
		movem.l	(sp)+,d7-a0/a2-a3
		move.w	(Camera_X_pos).w,d0
		sub.w	d0,(MainCharacter+8).w
		sub.w	d0,(Sidekick+8).w
		sub.w	d0,(Camera_X_pos).w
		sub.w	d0,(Camera_X_pos_copy).w
		move.w	(Camera_X_pos_copy).w,($FFFFEEB4).w
		sub.w	d0,(Camera_Min_X_pos).w
		sub.w	d0,(Camera_Max_X_pos).w
		jsr	sub_54CF4(pc)		; keeps sign in place
		jsr	UpdateRoundedCameraValues(pc)
		move.b	#1,(Dirty_flag).w
		jsr	LoadLevelSizeActTransition
loc_54C3C:
		lea	($FFFFEEB4).w,a1
		move.w	(Camera_X_pos_copy).w,d0
		move.w	#$100,d2
		move.w	#$200,d3
		jsr	sub_4F368(pc)
		jsr	sub_54C68(pc)
		lea	($FFFFEE90).w,a6
		lea	($FFFFEE96).w,a5
		moveq	#0,d1
		moveq	#$20,d6
		jsr	UpdateLevelFGRows(pc)
		jmp	sub_4F072(pc)
; ===============================================================================
sub_4F8F8:
		lea	($FFFFF7E0).w,a1
		moveq	#7,d0

loc_4F8FE:
		clr.l	(a1)+
		dbf	d0,loc_4F8FE
		rts
; End of function sub_4F8F8
UpdateRoundedCameraValues:
		move.w	(Camera_X_pos_copy).w,d0
		move.w	d0,d1
		and.w	#-$10,d0
		move.w	d0,(Camera_X_pos_rounded).w
		move.w	(Camera_Y_pos_copy).w,d0
		and.w	(Camera_Y_round_value).w,d0
		move.w	d0,(Camera_Y_pos_rounded).w
		rts
; End of function UpdateRoundedCameraValues
; ==============================================================================
UpdateLevelFGRows:
		move.w	(a6),d0
		and.w	(Camera_Y_round_value).w,d0
		move.w	(a5),d2
		move.w	d0,(a5)
		move.w	d2,d3
		sub.w	d0,d2
		beq.w	return_4EC46
		tst.b	d2
		bpl.s	loc_4EAFA
		neg.w	d2
		move.w	d3,d0
		add.w	#$F0,d0
		and.w	(Camera_Y_round_value).w,d0

loc_4EAFA:
		and.w	#$30,d2
		cmp.w	#$10,d2
		sne	(Dirty_flag).w
		movem.w	d1/d6,-(sp)
		bsr.s	sub_4EB6C
		movem.w	(sp)+,d1/d6
		tst.b	(Dirty_flag).w
		beq.w	return_4EC46
		add.w	#$10,d0
		and.w	(Camera_Y_round_value).w,d0
;		bra.s	sub_4EB6C
; =============================================================================
sub_4EB6C:
		asr.w	#4,d1
		move.w	d1,d2
		move.w	d1,d4
		asr.w	#3,d1
		add.w	d2,d2
		move.w	d2,d3
		and.w	#$E,d2
		add.w	d3,d3
		and.w	#$7C,d3
		and.w	#$1F,d4
		moveq	#$20,d5
		sub.w	d4,d5
		move.w	d5,d4
		sub.w	d6,d5
		bmi.s	loc_4EBB2
		move.w	d0,d5
		and.w	#$F0,d5
		lsl.w	#4,d5
		add.w	d7,d5
		add.w	d3,d5
		move.w	d5,(a0)+
		move.w	d6,d5
		subq.w	#1,d6
		move.w	d6,(a0)+
		lea	(a0),a1
		add.w	d5,d5
		add.w	d5,d5
		add.w	d5,a0
		jsr	sub_4EC48(pc)
		bra.s	sub_4EBF2
; ---------------------------------------------------------------------------
loc_4EBB2:
		neg.w	d5
		move.w	d5,-(sp)
		move.w	d0,d5
		and.w	#$F0,d5
		lsl.w	#4,d5
		add.w	d7,d5
		add.w	d3,d5
		move.w	d5,(a0)+
		move.w	d4,d6
		subq.w	#1,d6
		move.w	d6,(a0)+
		lea	(a0),a1
		add.w	d4,d4
		add.w	d4,d4
		add.w	d4,a0
		bsr.s	sub_4EC48
		bsr.s	sub_4EBF2
		move.w	(sp)+,d6
		move.w	d0,d5
		and.w	#$F0,d5
		lsl.w	#4,d5
		add.w	d7,d5
		move.w	d5,(a0)+
		move.w	d6,d5
		subq.w	#1,d6
		move.w	d6,(a0)+
		lea	(a0),a1
		add.w	d5,d5
		add.w	d5,d5
		add.w	d5,a0
; End of function sub_4EB6C


; =============== S U B	R O U T	I N E =======================================


sub_4EBF2:
		move.w	(a5,d2.w),d3
		move.w	d3,d4
		and.w	#$3FF,d3
		lsl.w	#3,d3

loc_4EBFE:
		move.l	(a2,d3.w),d5

loc_4EC02:
		move.l	4(a2,d3.w),d3

loc_4EC06:
		btst	#$B,d4

loc_4EC0A:
		beq.s	loc_4EC1A

loc_4EC0C:
		eor.l	#$10001000,d5
		eor.l	#$10001000,d3
		exg	d3,d5

loc_4EC1A:
		btst	#$A,d4
		beq.s	loc_4EC30
		eor.l	#$8000800,d5
		eor.l	#$8000800,d3
		swap	d5
		swap	d3

loc_4EC30:
		move.l	d5,(a1)+
		move.l	d3,(a0)+
		addq.w	#2,d2
		and.w	#$E,d2
		bne.s	loc_4EC40
		addq.w	#1,d1
		bsr.s	loc_4EC54

loc_4EC40:
		dbf	d6,sub_4EBF2
		clr.w	(a0)

return_4EC46:
		rts
; End of function sub_4EBF2


; =============== S U B	R O U T	I N E =======================================


sub_4EC48:
		move.w	d0,d3
		asr.w	#5,d3
;		and.w	(Level_row_count).w,d3
		and.w	#7,d3
		move.w	(a3,d3.w),a4

loc_4EC54:
		moveq	#-$1,d3
		clr.w	d3
		move.b	(a4,d1.w),d3
		lsl.w	#7,d3
		move.w	d0,d4
		and.w	#$70,d4
		add.w	d4,d3
		move.l	d3,a5
		rts
; End of function sub_4EC48


; =============== S U B	R O U T	I N E =======================================
; =============== S U B	R O U T	I N E =======================================


sub_54C68:
		move.w	(Camera_Y_pos_copy).w,d0
		swap	d0
		clr.w	d0
		asr.l	#3,d0
		move.l	d0,d1
		asr.l	#2,d1
		add.l	d1,d0
		swap	d0
		add.w	#$76,d0
		move.w	d0,(word_FFFFEE90).w
		move.w	(unk_FFFFEEB6).w,d0
		swap	d0
		clr.w	d0
		asr.l	#1,d0
		move.l	d0,d1
		asr.l	#2,d1
		sub.l	d1,d0
		asr.l	#1,d1
		swap	d0
		move.w	d0,(unk_FFFFEE8C).w
		swap	d0
		sub.l	d1,d0
		swap	d0
		move.w	d0,(unk_FFFFEEE2).w
		swap	d0
		sub.l	d1,d0
		swap	d0
		move.w	d0,(unk_FFFFEEE4).w
		rts
; End of function sub_54C68

; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================


sub_4F368:
		move.w	(a1),d1
		move.w	d0,(a1)+
		sub.w	d1,d0
		bpl.s	loc_4F37C
		neg.w	d0
		cmp.w	d2,d0
		bcs.s	loc_4F378
		sub.w	d3,d0

loc_4F378:
		sub.w	d0,(a1)+
		rts
; ---------------------------------------------------------------------------

loc_4F37C:
		cmp.w	d2,d0
		bcs.s	loc_4F382
		sub.w	d3,d0

loc_4F382:
		add.w	d0,(a1)+
		rts
; End of function sub_4F368
; =============== S U B	R O U T	I N E =======================================


sub_54CF4:
		lea	($FFFFB800).w,a1
		moveq	#$5F,d2

loc_54CFA:
		tst.b	(a1)
		beq.s	loc_54D26
		cmp.b	#$D,(a1)
		beq.s	loc_54D16
		cmp.b	#$3A,(a1)
		beq.s	loc_54D26
		jsr	DeleteObject2
		bra.s	loc_54D26

loc_54D16:
		sub.w	d0,8(a1)

loc_54D26:
		lea	$40(a1),a1
		dbf	d2,loc_54CFA
		rts
; End of function sub_54CF4
loc_2B962:
	;	jmp	MarkObjNotGone
		rts
; =============== S U B	R O U T	I N E =======================================


sub_4F072:
		lea	($FFFFE000).w,a1
		move.w	(Camera_X_pos_copy).w,d0
		neg.w	d0
		swap	d0
		move.w	(unk_FFFFEE8C).w,d0
		neg.w	d0
		moveq	#$37,d1

loc_4F086:
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		dbf	d1,loc_4F086
		rts
; End of function sub_4F072
; ===========================================================================
; Dynamic art loading check
; ===========================================================================
RunDynamicArtLoading:
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	add.w	d0,d0
	move.w	DynamicArtLoadingIndex(pc,d0.w),d0
	jmp		DynamicArtLoadingIndex(pc,d0.w)
; ===========================================================================
DynamicArtLoadingIndex: zoneOffsetTable 2,1
	zoneTableEntry.w DynamicArt_EHZ  - DynamicArtLoadingIndex	;   0 ; EHZ
    zoneTableEnd	
; ---------------------------------------------------------------------------
DynamicArt_EHZ:
	rts
; ---------------------------------------------------------------------------	
; loc_F626:
PlayLevelMusic:
	move.w	(Level_Music).w,d0
	bra.w	JmpTo3_PlayMusic
; ===========================================================================

; loc_F62E:
LoadPLC_AnimalExplosion:
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	;lea	(Animal_PLCTable).l,a2
	move.b	(a2,d0.w),d0
	bsr.w	JmpTo2_LoadPLC
	moveq	#PLCID_Explosion,d0
	bsr.w	JmpTo2_LoadPLC
	rts
; ===========================================================================

JmpTo_SingleObjLoad
	jmp	(SingleObjLoad).l

JmpTo3_PlaySound
	jmp	(PlaySound).l

JmpTo2_PalLoad2
	jmp	(PalLoad2).l

JmpTo2_LoadPLC
	jmp	(LoadPLC).l

JmpTo3_PlayMusic
	jmp	(PlayMusic).l


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
loc_15584:
	lea	(VDP_data_port).l,a6
	tst.w	(SpecialStageHUD+layer).w
	bne.w	loc_15670
	moveq	#$3F,d5
	move.l	#$85DA85DA,d6
	tst.w	(Two_player_mode).w
	beq.s	loc_155A8
	moveq	#$1F,d5
	move.l	#$82ED82ED,d6

loc_155A8:
	lea	(SpecialStageShadow_Sonic+$36).w,a0
	moveq	#1,d7

loc_155AE:
	move.w	(a0)+,d0
	beq.s	loc_155C6
	clr.w	-2(a0)
	jsr	sub_15792(pc)
	move.l	d0,4(a6)
	move.w	d5,d4

loc_155C0:
	move.l	d6,(a6)
	dbf	d4,loc_155C0

loc_155C6:
	dbf	d7,loc_155AE
	moveq	#$26,d1
	sub.w	(SpecialStageShadow_Tails+$3A).w,d1
	lsr.w	#1,d1
	subq.w	#1,d1
	moveq	#7,d5
	move.l	#$A5DCA5DC,d6
	tst.w	(Two_player_mode).w
	beq.s	loc_155EA
	moveq	#3,d5
	move.l	#$A2EEA2EE,d6

loc_155EA:
	lea	(SpecialStageShadow_Tails+$36).w,a0
	moveq	#1,d7

loc_155F0:
	move.w	(a0)+,d0
	beq.s	loc_15614
	clr.w	-2(a0)
	jsr	sub_15792(pc)
	move.w	d5,d4

loc_155FE:
	move.l	d0,4(a6)
	move.w	d1,d3

loc_15604:
	move.l	d6,(a6)
	dbf	d3,loc_15604
	addi.l	#$800000,d0
	dbf	d4,loc_155FE

loc_15614:
	dbf	d7,loc_155F0
	move.w	(SpecialStageTails_Tails+$3A).w,d1
	subq.w	#1,d1
	moveq	#$D,d5
	move.l	#$85D885D8,d6
	tst.w	(Two_player_mode).w
	beq.s	loc_15634
	moveq	#6,d5
	move.l	#$82EC82EC,d6

loc_15634:
	lea	(SpecialStageTails_Tails+$36).w,a0
	moveq	#1,d7
	move.w	#$8F80,4(a6)

loc_15640:
	move.w	(a0)+,d0
	beq.s	loc_15664
	clr.w	-2(a0)
	jsr	sub_15792(pc)
	move.w	d1,d4

loc_1564E:
	move.l	d0,4(a6)
	move.w	d5,d3

loc_15654:
	move.l	d6,(a6)
	dbf	d3,loc_15654
	addi.l	#$20000,d0
	dbf	d4,loc_1564E

loc_15664:
	dbf	d7,loc_15640
	move.w	#$8F02,4(a6)		; VRAM pointer increment: $0002
	rts
loc_15670:
	moveq	#9,d3
	moveq	#3,d4
	move.l	#$85DA85DA,d5
	move.l	#$A5DCA5DC,d6
	tst.w	(Two_player_mode).w
	beq.s	+
	moveq	#4,d3
	moveq	#1,d4
	move.l	#$82ED82ED,d5
	move.l	#$A2EEA2EE,d6
+
	lea	(SpecialStageTails_Tails+$36).w,a0
	moveq	#1,d7
	move.w	#$8F80,4(a6)

loc_156A2:
	move.w	(a0)+,d0
	beq.s	loc_156CE
	clr.w	-2(a0)
	jsr	sub_15792(pc)
	moveq	#3,d2

loc_156B0:
	move.l	d0,4(a6)

	move.w	d3,d1
-	move.l	d5,(a6)
	dbf	d1,-

	move.w	d4,d1
-	move.l	d6,(a6)
	dbf	d1,-

	addi.l	#$20000,d0
	dbf	d2,loc_156B0

loc_156CE:
	dbf	d7,loc_156A2
	move.w	#$8F02,4(a6)		; VRAM pointer increment: $0002
	moveq	#7,d5
	move.l	#$85DA85DA,d6
	tst.w	(Two_player_mode).w
	beq.s	+
	moveq	#3,d5
	move.l	#$82ED82ED,d6
+
	lea	(SpecialStageShadow_Tails+$36).w,a0
	moveq	#1,d7

loc_156F4:
	move.w	(a0)+,d0
	beq.s	loc_15714
	clr.w	-2(a0)
	jsr	sub_15792(pc)

	move.w	d5,d4
-	move.l	d0,4(a6)
	move.l	d6,(a6)
	move.l	d6,(a6)
	addi.l	#$800000,d0
	dbf	d4,-

loc_15714:
	dbf	d7,loc_156F4
	move.w	(SpecialStageShadow_Sonic+$36).w,d4
	beq.s	loc_1578C
	lea	4(a6),a5
	tst.w	(Two_player_mode).w
	beq.s	loc_15758
	lea	(Camera_X_pos_P2).w,a3
	move.l	(LevelUncLayout).l,a4
	move.w	#$6000,d2

	moveq	#1,d6
-	movem.l	d4-d6,-(sp)
	moveq	#-$10,d5
	move.w	d4,d1
	bsr.w	loc_E2C2
	move.w	d1,d4
	moveq	#-$10,d5
	moveq	#$1F,d6
	bsr.w	DrawBlockRow
	movem.l	(sp)+,d4-d6
	addi.w	#$10,d4
	dbf	d6,-

loc_15758:
	lea	(Camera_X_pos).w,a3
	move.l	(LevelUncLayout).l,a4
	move.w	#$4000,d2
	move.w	(SpecialStageShadow_Sonic+$36).w,d4

	moveq	#1,d6
-	movem.l	d4-d6,-(sp)
	moveq	#-$10,d5
	move.w	d4,d1
	bsr.w	CalcBlockVRAMPos
	move.w	d1,d4
	moveq	#-$10,d5
	moveq	#$1F,d6
	bsr.w	DrawBlockRow
	movem.l	(sp)+,d4-d6
	addi.w	#$10,d4
	dbf	d6,-

loc_1578C:
	clr.w	(SpecialStageShadow_Sonic+$36).w
	rts


sub_15792:
	andi.l	#$FFFF,d0
	lsl.l	#2,d0
	lsr.w	#2,d0
	ori.w	#$4000,d0
	swap	d0
	rts
; End of function sub_15792

; ===========================================================================

loc_157A4:
	movem.l	d0/a0,-(sp)
	bsr.s	LoadTitleCard0
	movem.l	(sp)+,d0/a0
	bra.s	loc_157EC

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_157B0:
LoadTitleCard0:

	move.l	#vdpComm($B000,VRAM,WRITE),(VDP_control_port).l
	lea	(ArtNem_TitleCard).l,a0
	bsr.w	JmpTo2_NemDec
	move.l	(LevelUncLayout).w,a4
	;lea	($FFFF8000).w,a4
	lea	(ArtNem_TitleCard2).l,a0
	bra.w	JmpTo_NemDecToRAM
; ===========================================================================
; loc_157D2:
LoadTitleCard:
	bsr.s	LoadTitleCard0
	moveq	#0,d0
	move.b	(Current_Zone).w,d0
	move.b	Off_TitleCardLetters(pc,d0.w),d0
	lea	TitleCardLetters(pc),a0
	lea	(a0,d0.w),a0
	move.l	#vdpComm($BBC0,VRAM,WRITE),d0

loc_157EC:
	move	#$2700,sr
;	lea	($FFFF8000).w,a1
	move.l	(LevelUncLayout).w,a1
	lea	(VDP_data_port).l,a6
	move.l	d0,4(a6)

loc_157FE:
	moveq	#0,d0
	move.b	(a0)+,d0
	bmi.s	loc_1581A
	lsl.w	#5,d0
	lea	(a1,d0.w),a2
	moveq	#0,d1
	move.b	(a0)+,d1
	lsl.w	#3,d1
	subq.w	#1,d1

loc_15812:
	move.l	(a2)+,(a6)
	dbf	d1,loc_15812
	bra.s	loc_157FE
; ===========================================================================

loc_1581A:
	move	#$2300,sr
	rts
; ===========================================================================
	nop

JmpTo2_NemDec
	jmp	(NemDec).l
; ===========================================================================

JmpTo_NemDecToRAM
	jmp	(NemDecToRAM).l
; End of function LoadTitleCard0


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


JmpTo3_LoadPLC

	jmp	(LoadPLC).l
; End of function JmpTo3_LoadPLC
; ===========================================================================
Off_TitleCardLetters:	Include	"code/Levels/Title Card List.asm"
	even

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
;sub_15E18:
BreakObjectToPieces:	; splits up one object into its current mapping frame pieces
	moveq	#0,d0
	move.b	mapping_frame(a0),d0
	add.w	d0,d0
	movea.l	mappings(a0),a3
	adda.w	(a3,d0.w),a3	; put address of appropriate frame to a3
	move.w	(a3)+,d1	; amount of pieces the frame consists of
	subq.w	#1,d1
	bset	#5,render_flags(a0)
	move.w	id(a0),d4
	move.b	render_flags(a0),d5
	movea.l	a0,a1
	bra.s	loc_15E46
; ===========================================================================

loc_15E3E:
	jsr	SingleObjLoad2
	bne.s	loc_15E82
	addq.w	#8,a3	; next mapping piece

loc_15E46:
	;move.b	#4,player_off24(a1)
	move.w	d4,id(a1) ; load object with ID of parent object and routine 4
	move.l	a3,mappings(a1)
	move.b	d5,render_flags(a1)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	art_tile(a0),art_tile(a1)
	move.w	priority(a0),priority(a1)
	move.b	width_pixels(a0),width_pixels(a1)
	move.w	(a4)+,x_vel(a1)
	move.w	(a4)+,y_vel(a1)
	dbf	d1,loc_15E3E

loc_15E82:
	move.w	#SndID_SlowSmash,d0
	jmp	(PlaySound).l
; End of function BreakObjectToPieces
; -------------------------------------------------------------------------------
; This runs the code of all the objects that are in Object_RAM
; -------------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_15F9C: ObjectsLoad:
RunObjects:
	tst.b	(Teleport_flag).w
	bne.s	return_15FE4
	lea	(Object_RAM).w,a0 ; a0=object

	move.w	#(Dynamic_Object_RAM_End-Object_RAM)/object_size-1,d7 ; run the first $80 objects out of levels
	moveq	#0,d0
	cmpi.b	#GameModeID_Demo,(Game_Mode).w	; demo mode?
	beq.s	+	; if in a level in a demo, branch
	cmpi.b	#GameModeID_Level,(Game_Mode).w	; regular level mode?
	bne.s	RunObject ; if not in a level, branch to RunObject
+
	move.w	#(LevelOnly_Object_RAM_End-Object_RAM)/object_size-1,d7	; run the first $90 objects in levels
	tst.w	(Two_player_mode).w
	bne.s	RunObject ; if in 2 player competition mode, branch to RunObject

	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	RunObjects_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	RunObjectsWhenPlayerIsDead	
	move.w	RunObjects_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	RunObjectsWhenPlayerIsDead
	move.w	RunObjects_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	RunObjectsWhenPlayerIsDead		
	
	; continue straight to RunObject
; ---------------------------------------------------------------------------

; -------------------------------------------------------------------------------
; This is THE place where each individual object's code gets called from
; -------------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_15FCC:
RunObject:
	moveq	#1,d0			; base object code address = $010000
	swap	d0
	move.w	(a0),d0			; get the object code pointer
	beq.b	+			; if empty, skip
	movea.l	d0,a1
	jsr	(a1)			; run the object code
	moveq	#0,d0
+	lea	next_object(a0),a0
	dbf	d7,RunObject

return_15FE4:
	rts
RunObjects_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

RunObjects_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

RunObjects_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)	
; ---------------------------------------------------------------------------
; this skips certain objects to make enemies and things pause when Sonic dies
; loc_15FE6:
RunObjectsWhenPlayerIsDead:
	move.w	#(Reserved_Object_RAM_End-Reserved_Object_RAM)/object_size-1,d7
	bsr.s	RunObject	; run the first $10 objects normally
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d7
	bsr.s	RunObjectDisplayOnly ; all objects in this range are paused
	move.w	#(LevelOnly_Object_RAM_End-LevelOnly_Object_RAM)/object_size-1,d7
	bra.s	RunObject	; run the last $10 objects normally

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_15FF2:
RunObjectDisplayOnly:
	tst.w	(a0)			; is the object slot empty?
	beq.b	+			; if so, skip
	tst.b	render_flags(a0)	; should we render it?
	bpl.b	+			; if not, skip it
	bsr.w	DisplaySprite		; display the sprite
+	lea	next_object(a0),a0
	dbf	d7,RunObjectDisplayOnly
	rts
; End of function RunObjectDisplayOnly

; ---------------------------------------------------------------------------
; Subroutine to make an object move and fall downward increasingly fast
; This moves the object horizontally and vertically
; and also applies gravity to its speed
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_16380: ObjectFall:
ObjectMoveAndFall:
	move.w  x_vel(a0),d0
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,x_pos(a0)
	move.w  y_vel(a0),d0
	addi.w  #$38,y_vel(a0) ; apply gravity
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,y_pos(a0)
	rts
; End of function ObjectMoveAndFall
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

; ---------------------------------------------------------------------------
; Subroutine translating object speed to update object position
; This moves the object horizontally and vertically
; but does not apply gravity to it
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_163AC: SpeedToPos:
ObjectMove:
	move.w  x_vel(a0),d0
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,x_pos(a0)
	move.w  y_vel(a0),d0
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,y_pos(a0)
	rts
; End of function ObjectMove
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

; ---------------------------------------------------------------------------
; Routines to mark an enemy/monitor/ring/platform as destroyed
; ---------------------------------------------------------------------------

; ===========================================================================
; input: a0 = the object
; loc_163D2:
MarkObjGone:
	tst.w	(Two_player_mode).w
	beq.s	+
	bra.w	DisplaySprite
+
	move.w	x_pos(a0),d0
	andi.w	#$FF80,d0
	sub.w	(Camera_X_pos_coarse).w,d0
	cmpi.w	#$280,d0
	bhi.w	+
	bra.w	DisplaySprite

+	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	beq.s	+
	bclr	#7,2(a2,d0.w)
+
	jmp	DeleteObject
; ===========================================================================
; input: d0 = the object's x position
; loc_1640A:
MarkObjGone2:
	tst.w	(Two_player_mode).w
	beq.s	+
	bra.w	DisplaySprite
+
	andi.w	#$FF80,d0
	sub.w	(Camera_X_pos_coarse).w,d0
	cmpi.w	#$280,d0
	bhi.w	+
	bra.w	DisplaySprite
+
	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	beq.s	+
	bclr	#7,2(a2,d0.w)
+
	jmp	DeleteObject
; ===========================================================================
; input: a0 = the object
; does nothing instead of calling DisplaySprite in the case of no deletion
; loc_1643E:
MarkObjGone3:
	tst.w	(Two_player_mode).w
	beq.s	+
	rts
+
	move.w	x_pos(a0),d0
	andi.w	#$FF80,d0
	sub.w	(Camera_X_pos_coarse).w,d0
	cmpi.w	#$280,d0
	bhi.w	+
	rts
+
	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	beq.s	+
	bclr	#7,2(a2,d0.w)
+
	jmp	DeleteObject
; ===========================================================================
; input: a0 = the object
; loc_16472:
MarkObjGone_P1:
	tst.w	(Two_player_mode).w
	bne.s	MarkObjGone_P2
	move.w	x_pos(a0),d0
	andi.w	#$FF80,d0
	sub.w	(Camera_X_pos_coarse).w,d0
	cmpi.w	#$280,d0
	bhi.w	+
	bra.w	DisplaySprite
+
	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	beq.s	+
	bclr	#7,2(a2,d0.w)
+
	jmp	DeleteObject
; ---------------------------------------------------------------------------
; input: a0 = the object
; loc_164A6:
MarkObjGone_P2:
	move.w	x_pos(a0),d0
	andi.w	#$FF00,d0
	move.w	d0,d1
	sub.w	(Camera_X_pos_coarse).w,d0
	cmpi.w	#$300,d0
	bhi.w	+
	bra.w	DisplaySprite
+
	sub.w	($FFFFF7DC).w,d1
	cmpi.w	#$300,d1
	bhi.w	+
	bra.w	DisplaySprite
+
	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	beq.s	+
	bclr	#7,2(a2,d0.w)
+
	jmp	DeleteObject

; ---------------------------------------------------------------------------
; Subroutine to display a sprite/object, when a0 is the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_164F4:
DisplaySprite:
	lea	(Sprite_Table_Input).w,a1
	adda.w  priority(a0),a1
	cmpi.w	#$7E,(a1)
	bhs.s	return_16510
	addq.w	#2,(a1)
	adda.w	(a1),a1
	move.w	a0,(a1)

return_16510:
	rts
; End of function DisplaySprite

; ---------------------------------------------------------------------------
; Subroutine to display a sprite/object, when a1 is the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_16512:
DisplaySprite2:
	lea	(Sprite_Table_Input).w,a2
	adda.w  priority(a0),a2
	cmpi.w	#$7E,(a2)
	bhs.s	return_1652E
	addq.w	#2,(a2)
	adda.w	(a2),a2
	move.w	a1,(a2)

return_1652E:
	rts
; End of function DisplaySprite2

; ---------------------------------------------------------------------------
; Subroutine to display a sprite/object, when a0 is the object RAM
; and d0 is already (priority/2)&$380
; ---------------------------------------------------------------------------

; loc_16530:
DisplaySprite3:
	lea	(Sprite_Table_Input).w,a1
	adda.w	d0,a1
	cmpi.w	#$7E,(a1)
	bhs.s	return_16542
	addq.w	#2,(a1)
	adda.w	(a1),a1
	move.w	a0,(a1)

return_16542:
	rts

; ---------------------------------------------------------------------------
; Subroutine to animate a sprite using an animation script
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_16544:
AnimateSprite:
	moveq	#0,d0
	move.b	anim(a0),d0		; move animation number to d0
	cmp.b	next_anim(a0),d0	; is animation set to change?
	beq.s	Anim_Run		; if not, branch
	move.b	d0,next_anim(a0)	; set next anim to current current
	move.b	#0,anim_frame(a0)	; reset animation
	move.b	#0,anim_frame_duration(a0)	; reset frame duration
; loc_16560:
Anim_Run:
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.s	Anim_Wait	; if time remains, branch
	add.w	d0,d0
	adda.w	(a1,d0.w),a1	; calculate address of appropriate animation script
	move.b	(a1),anim_frame_duration(a0)	; load frame duration
	moveq	#0,d1
	move.b	anim_frame(a0),d1	; load current frame number
	move.b	1(a1,d1.w),d0   	; read sprite number from script
	bmi.s	Anim_End_FF     	; if animation is complete, branch
; loc_1657C:
Anim_Next:
	andi.b	#$7F,d0			; clear sign bit
	move.b	d0,mapping_frame(a0)	; load sprite number
	move.b	status(a0),d1		;* match the orientaion dictated by the object
	andi.b	#3,d1			;* with the orientation used by the object engine
	andi.b	#$FC,render_flags(a0)	;*
	or.b	d1,render_flags(a0)	;*
	addq.b	#1,anim_frame(a0)	; next frame number
; return_1659A:
Anim_Wait:
	rts
; ===========================================================================
; loc_1659C:
Anim_End_FF:
	addq.b	#1,d0		; is the end flag = $FF ?
	bne.s	Anim_End_FE	; if not, branch
	move.b	#0,anim_frame(a0)	; restart the animation
	move.b	1(a1),d0	; read sprite number
	bra.s	Anim_Next
; ===========================================================================
; loc_165AC:
Anim_End_FE:
	addq.b	#1,d0	; is the end flag = $FE ?
	bne.s	Anim_End_FD	; if not, branch
	move.b	2(a1,d1.w),d0	; read the next byte in the script
	sub.b	d0,anim_frame(a0)	; jump back d0 bytes in the script
	sub.b	d0,d1
	move.b	1(a1,d1.w),d0	; read sprite number
	bra.s	Anim_Next
; ===========================================================================
; loc_165C0:
Anim_End_FD:
	addq.b	#1,d0		; is the end flag = $FD ?
	bne.s	Anim_End_FC	; if not, branch
	move.b	2(a1,d1.w),anim(a0)	; read next byte, run that animation
	rts
; ===========================================================================
; loc_165CC:
Anim_End_FC:
	addq.b	#1,d0	; is the end flag = $FC ?
	bne.s	Anim_End_FB	; if not, branch
	ori.b	#$C0,mappings(a0)	; set the object's touched flag
	move.b	#0,anim_frame_duration(a0)
	addq.b	#1,anim_frame(a0)
	rts
; ===========================================================================
; loc_165E0:
Anim_End_FB:
	addq.b	#1,d0	; is the end flag = $FB ?
	bne.s	Anim_End_FA	; if not, branch
	move.b	#0,anim_frame(a0)	; reset animation
	rts
; ===========================================================================
; loc_165F0:
Anim_End_FA:
	addq.b	#1,d0	; is the end flag = $FA ?
	bne.s	Anim_End_F9	; if not, branch
	rts
; ===========================================================================
; loc_165FA:
Anim_End_F9:
	addq.b	#1,d0	; is the end flag = $F9 ?
	bne.s	Anim_End	; if not, branch
	addq.b	#2,objoff_2A(a0)
; return_16602:
Anim_End:
	rts
; End of function AnimateSprite


; ---------------------------------------------------------------------------
; Subroutine to convert mappings (etc) to proper Megadrive sprites
; ---------------------------------------------------------------------------

BuildSprites:
	lea	(Sprite_Table).w,a2
	moveq	#0,d5
	moveq	#0,d4
	tst.b	(Level_started_flag).w
	beq.s	+
	bsr.w	JmpTo_BuildHUD
	bsr.w	loc_17178
+
	lea	(Sprite_Table_Input).w,a4
	moveq	#7,d7	; 8 priority levels

BuildSprites_LevelLoop:
	tst.w	(a4)	; does this level have any objects?
	beq.w	BuildSprites_NextLevel	; if not, check the next one
	moveq	#2,d6

BuildSprites_ObjLoop:
	movea.w	(a4,d6.w),a0		; a0=object
	tst.w	(a0)			; is this object slot occupied?
	beq.w	BuildSprites_NextObj	; if not, check next one
	andi.b	#$7F,render_flags(a0)	; clear on-screen flag
	moveq	#0,d0
	move.b	render_flags(a0),d0
	move.b	d0,d4
	andi.w	#$C,d0	; is this to be positioned by screen coordinates?
	beq.s	BuildSprites_ScreenSpaceObj	; if it is, branch
	lea	(Camera_X_pos_copy).w,a1
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	move.w	x_pos(a0),d3
	sub.w	(a1),d3
	move.w	d3,d1
	add.w	d0,d1	; is the object right edge to the left of the screen?
	bmi.w	BuildSprites_NextObj	; if it is, branch
	move.w	d3,d1
	sub.w	d0,d1
	cmpi.w	#320,d1	; is the object left edge to the right of the screen?
	bge.w	BuildSprites_NextObj	; if it is, branch
	addi.w	#128,d3
	btst	#4,d4		; is the accurate Y check flag set?
	beq.s	BuildSprites_ApproxYCheck	; if not, branch
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	move.w	y_pos(a0),d2
	sub.w	4(a1),d2
	move.w	d2,d1
	add.w	d0,d1
	bmi.s	BuildSprites_NextObj	; if the object is above the screen
	move.w	d2,d1
	sub.w	d0,d1
	cmpi.w	#224,d1
	bge.s	BuildSprites_NextObj	; if the object is below the screen
	addi.w	#128,d2
	bra.s	BuildSprites_DrawSprite

BuildSprites_ScreenSpaceObj:
	move.w	objoff_A(a0),d2
	move.w	x_pos(a0),d3
	bra.s	BuildSprites_DrawSprite

BuildSprites_ApproxYCheck:
	move.w	y_pos(a0),d2
	sub.w	4(a1),d2
	addi.w	#128,d2
	andi.w	#$7FF,d2
	cmpi.w	#-32+128,d2	; assume Y radius to be 32 pixels
	blo.s	BuildSprites_NextObj
	cmpi.w	#32+128+224,d2
	bhs.s	BuildSprites_NextObj

BuildSprites_DrawSprite:
	ori.b	#$80,render_flags(a0)	; set on-screen flag
	moveq	#0,d0
	move.b	d4,d0
	andi.b	#$60,d0			; extract mapping system
	lsr.b	#4,d0			; form word indices
	move.w	BuildSprites_Methods(pc,d0.w),d0
	jsr	BuildSprites_Methods(pc,d0.w)

BuildSprites_NextObj:
	addq.w	#2,d6			; load next object
	subq.w	#2,(a4)			; decrement object count
	bne.w	BuildSprites_ObjLoop	; if there are objects left, repeat

BuildSprites_NextLevel:
	lea	$80(a4),a4		; load next priority level
	dbf	d7,BuildSprites_LevelLoop	; loop
	move.b	d5,(Sprite_count).w
	cmpi.b	#80,d5			; was the sprite limit reached?
	beq.s	+			; if it was, branch
	move.l	#0,(a2)			; set link field to 0
	rts
+	move.b	#0,-5(a2)		; set link field to 0
	rts
; ===========================================================================
BuildSprites_Methods:
	dc.w	BuildSprites_Classic-BuildSprites_Methods
	dc.w	BuildSprites_Static-BuildSprites_Methods
	dc.w	BuildSprites_Compound-BuildSprites_Methods
; ===========================================================================

BuildSprites_Classic:
	movea.l	mappings(a0),a1
	moveq	#0,d1
	move.b	mapping_frame(a0),d1
	add.w	d1,d1
	adda.w	(a1,d1.w),a1
	move.w	(a1)+,d1
	subq.w	#1,d1			; get number of pieces
	bmi.s	+			; if there are 0 pieces, branch
	bra.w	DrawSprite		; draw the sprite
+	rts
; ===========================================================================

BuildSprites_Static:
	movea.l	mappings(a0),a1
	moveq	#0,d1
	bra.w	DrawSprite		; draw the sprite
; ===========================================================================

BuildSprites_Compound:
	movea.l	mappings(a0),a5
	movea.w	art_tile(a0),a3
	lea	$20(a0),a6
	moveq	#0,d0
	move.b	(a6)+,d0	; get child sprite count
	subq.w	#1,d0		; if there are 0, go to next object
	bcs.s	BuildSprites_Compound_NextObj
-	movem.w	d0/d2/d3/d4,-(sp)
	move.b	(a6)+,d1	; get X pos
	ext.w	d1
	add.w	d1,d3
	move.b	(a6)+,d1	; get Y pos
	ext.w	d1
	add.w	d1,d2
	andi.w	#$7FF,d2
	moveq	#0,d1
	move.b	(a6)+,d1	; get mapping frame
	add.w	d1,d1
	movea.l	a5,a1
	adda.w	(a1,d1.w),a1
	move.w	(a1)+,d1
	subq.w	#1,d1
	bmi.s	+
	bsr.w	ChkDrawSprite
+	movem.w	(sp)+,d0/d2/d3/d4
	dbf	d0,-	; repeat for number of child sprites

BuildSprites_Compound_NextObj:
	rts

; End of function BuildSprites


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_1680A:
ChkDrawSprite:
	cmpi.b	#80,d5		; has the sprite limit been reached?
	blo.s	DrawSprite_Cont	; if it hasn't, branch
	rts	; otherwise, return
; End of function ChkDrawSprite


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_16812:
DrawSprite:
	movea.w	art_tile(a0),a3
	cmpi.b	#80,d5
	bhs.s	DrawSprite_Done
; loc_1681C:
DrawSprite_Cont:
	btst	#0,d4	; is the sprite to be X-flipped?
	bne.s	DrawSprite_FlipX	; if it is, branch
	btst	#1,d4	; is the sprite to be Y-flipped?
	bne.w	DrawSprite_FlipY	; if it is, branch
; loc__1682A:
DrawSprite_Loop:
	move.b	(a1)+,d0
	ext.w	d0
	add.w	d2,d0
	move.w	d0,(a2)+	; set Y pos
	move.b	(a1)+,(a2)+	; set sprite size
	addq.b	#1,d5
	move.b	d5,(a2)+	; set link field
	move.w	(a1)+,d0
	add.w	a3,d0
	move.w	d0,(a2)+	; set art tile and flags
	addq.w	#2,a1
	move.w	(a1)+,d0
	add.w	d3,d0
	andi.w	#$1FF,d0
	bne.s	+
	addq.w	#1,d0	; avoid activating sprite masking
+
	move.w	d0,(a2)+	; set X pos
	dbf	d1,DrawSprite_Loop	; repeat for next sprite
; return_16852:
DrawSprite_Done:
	rts
; ===========================================================================
; loc_16854:
DrawSprite_FlipX:
	btst	#1,d4	; is it to be Y-flipped as well?
	bne.w	DrawSprite_FlipXY	; if it is, branch

-	move.b	(a1)+,d0
	ext.w	d0
	add.w	d2,d0
	move.w	d0,(a2)+
	move.b	(a1)+,d4	; store size for later use
	move.b	d4,(a2)+
	addq.b	#1,d5
	move.b	d5,(a2)+
	move.w	(a1)+,d0
	add.w	a3,d0
	eori.w	#$800,d0	; toggle X flip flag
	move.w	d0,(a2)+
	addq.w	#2,a1
	move.w	(a1)+,d0
	neg.w	d0	; negate X offset
	move.b	CellOffsets_XFlip(pc,d4.w),d4
	sub.w	d4,d0	; subtract sprite size
	add.w	d3,d0
	andi.w	#$1FF,d0
	bne.s	+
	addq.w	#1,d0
+
	move.w	d0,(a2)+
	dbf	d1,-

	rts
; ===========================================================================
; offsets for horizontally mirrored sprite pieces
CellOffsets_XFlip:
	dc.b   8,  8,  8,  8	; 4
	dc.b $10,$10,$10,$10	; 8
	dc.b $18,$18,$18,$18	; 12
	dc.b $20,$20,$20,$20	; 16
; offsets for vertically mirrored sprite pieces
CellOffsets_YFlip:
	dc.b   8,$10,$18,$20	; 4
	dc.b   8,$10,$18,$20	; 8
	dc.b   8,$10,$18,$20	; 12
	dc.b   8,$10,$18,$20	; 16
; ===========================================================================
; loc_168B4:
DrawSprite_FlipY:
	move.b	(a1)+,d0
	move.b	(a1),d4
	ext.w	d0
	neg.w	d0
	move.b	CellOffsets_YFlip(pc,d4.w),d4
	sub.w	d4,d0
	add.w	d2,d0
	move.w	d0,(a2)+	; set Y pos
	move.b	(a1)+,(a2)+	; set size
	addq.b	#1,d5
	move.b	d5,(a2)+	; set link field
	move.w	(a1)+,d0
	add.w	a3,d0
	eori.w	#$1000,d0	; toggle Y flip flag
	move.w	d0,(a2)+	; set art tile and flags
	addq.w	#2,a1
	move.w	(a1)+,d0
	add.w	d3,d0
	andi.w	#$1FF,d0
	bne.s	+
	addq.w	#1,d0
+
	move.w	d0,(a2)+	; set X pos
	dbf	d1,DrawSprite_FlipY
	rts
; ===========================================================================
; offsets for vertically mirrored sprite pieces
CellOffsets_YFlip2:
	dc.b   8,$10,$18,$20	; 4
	dc.b   8,$10,$18,$20	; 8
	dc.b   8,$10,$18,$20	; 12
	dc.b   8,$10,$18,$20	; 16
; ===========================================================================
; loc_168FC:
DrawSprite_FlipXY:
	move.b	(a1)+,d0
	move.b	(a1),d4
	ext.w	d0
	neg.w	d0
	move.b	CellOffsets_YFlip2(pc,d4.w),d4
	sub.w	d4,d0
	add.w	d2,d0
	move.w	d0,(a2)+
	move.b	(a1)+,d4
	move.b	d4,(a2)+
	addq.b	#1,d5
	move.b	d5,(a2)+
	move.w	(a1)+,d0
	add.w	a3,d0
	eori.w	#$1800,d0	; toggle X and Y flip flags
	move.w	d0,(a2)+
	addq.w	#2,a1
	move.w	(a1)+,d0
	neg.w	d0
	move.b	CellOffsets_XFlip2(pc,d4.w),d4
	sub.w	d4,d0
	add.w	d3,d0
	andi.w	#$1FF,d0
	bne.s	+
	addq.w	#1,d0
+
	move.w	d0,(a2)+
	dbf	d1,DrawSprite_FlipXY
	rts
; End of function DrawSprite

; ===========================================================================
; offsets for horizontally mirrored sprite pieces
CellOffsets_XFlip2:
	dc.b   8,  8,  8,  8	; 4
	dc.b $10,$10,$10,$10	; 8
	dc.b $18,$18,$18,$18	; 12
	dc.b $20,$20,$20,$20	; 16
; ===========================================================================


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


JmpTo_BuildHUD
	jmp	(BuildHUD).l
; ===========================================================================

	ds.b	$5500




; ===========================================================================
	align 4
	include "code/engines/rings_manager.asm"
	even


; ---------------------------------------------------------------------------
; Pseudo-object to do collision with (and initialize?) the special bumpers in CNZ.
; These are the bumpers that are part of the level layout but have object-like collision.
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_173BC:
SpecialCNZBumpers:
	moveq	#0,d0
	move.b	(CNZ_Bumper_routine).w,d0
	move.w	SpecialCNZBumpers_Index(pc,d0.w),d0
	jmp	SpecialCNZBumpers_Index(pc,d0.w)
; ===========================================================================
; off_173CA:
SpecialCNZBumpers_Index:
	dc.w loc_173CE - SpecialCNZBumpers_Index; 0
	dc.w loc_17422 - SpecialCNZBumpers_Index; 1
; ===========================================================================

loc_173CE:
	addq.b	#2,(CNZ_Bumper_routine).w
	lea	(byte_1781A).l,a1
	tst.b	(Current_Act).w
	beq.s	loc_173E4
	lea	(byte_1795E).l,a1

loc_173E4:
	move.w	(Camera_X_pos).w,d4
	subq.w	#8,d4
	bhi.s	loc_173F4
	moveq	#1,d4
	bra.s	loc_173F4
; ===========================================================================

loc_173F0:
	lea	6(a1),a1

loc_173F4:
	cmp.w	2(a1),d4
	bhi.s	loc_173F0
	move.l	a1,($FFFFF71C).w
	move.l	a1,($FFFFF724).w
	addi.w	#$150,d4
	bra.s	loc_1740C
; ===========================================================================

loc_17408:
	lea	6(a1),a1

loc_1740C:
	cmp.w	2(a1),d4
	bhi.s	loc_17408
	move.l	a1,($FFFFF720).w
	move.l	a1,($FFFFF728).w
	move.b	#1,($FFFFF71B).w
	rts
; ===========================================================================

loc_17422:
	movea.l	($FFFFF71C).w,a1
	move.w	(Camera_X_pos).w,d4
	subq.w	#8,d4
	bhi.s	loc_17436
	moveq	#1,d4
	bra.s	loc_17436
; ===========================================================================

loc_17432:
	lea	6(a1),a1

loc_17436:
	cmp.w	2(a1),d4
	bhi.s	loc_17432
	bra.s	loc_17440
; ===========================================================================

loc_1743E:
	subq.w	#6,a1

loc_17440:
	cmp.w	-4(a1),d4
	bls.s	loc_1743E
	move.l	a1,($FFFFF71C).w
	movea.l	($FFFFF720).w,a2
	addi.w	#$150,d4
	bra.s	loc_17458
; ===========================================================================

loc_17454:
	lea	6(a2),a2

loc_17458:
	cmp.w	2(a2),d4
	bhi.s	loc_17454
	bra.s	loc_17462
; ===========================================================================

loc_17460:
	subq.w	#6,a2

loc_17462:
	cmp.w	-4(a2),d4
	bls.s	loc_17460
	move.l	a2,($FFFFF720).w
	tst.w	(Two_player_mode).w
	bne.s	loc_1747C
	move.l	a1,($FFFFF724).w
	move.l	a2,($FFFFF728).w
	rts
; ===========================================================================

loc_1747C:
	movea.l	($FFFFF724).w,a1
	move.w	(Camera_X_pos_P2).w,d4
	subq.w	#8,d4
	bhi.s	loc_17490
	moveq	#1,d4
	bra.s	loc_17490
; ===========================================================================

loc_1748C:
	lea	6(a1),a1

loc_17490:
	cmp.w	2(a1),d4
	bhi.s	loc_1748C
	bra.s	loc_1749A
; ===========================================================================

loc_17498:
	subq.w	#6,a1

loc_1749A:
	cmp.w	-4(a1),d4
	bls.s	loc_17498
	move.l	a1,($FFFFF724).w
	movea.l	($FFFFF728).w,a2
	addi.w	#$150,d4
	bra.s	loc_174B2
; ===========================================================================

loc_174AE:
	lea	6(a2),a2

loc_174B2:
	cmp.w	2(a2),d4
	bhi.s	loc_174AE
	bra.s	loc_174BC
; ===========================================================================

loc_174BA:
	subq.w	#6,a2

loc_174BC:
	cmp.w	-4(a2),d4
	bls.s	loc_174BA
	move.l	a2,($FFFFF728).w
	rts
; ===========================================================================

loc_174C8:
	movea.l	($FFFFF71C).w,a1
	movea.l	($FFFFF720).w,a2
	cmpa.w	#MainCharacter,a0
	beq.s	loc_174DE
	movea.l	($FFFFF724).w,a1
	movea.l	($FFFFF728).w,a2

loc_174DE:
	cmpa.l	a1,a2
	beq.w	return_17578
	move.w	x_pos(a0),d2
	move.w	y_pos(a0),d3
	subi.w	#9,d2
	moveq	#0,d5
	move.b	height_pixels(a0),d5
	lsr.b	#1,d5
	subq.b	#3,d5
	sub.w	d5,d3
	cmpi.b	#$4D,mapping_frame(a0)
	bne.s	loc_17508
	addi.w	#$C,d3
	moveq	#$A,d5

loc_17508:
	move.w	#$12,d4
	add.w	d5,d5

loc_1750E:
	move.w	(a1),d0
	andi.w	#$E,d0
	lea	byte_17558(pc,d0.w),a3
	moveq	#0,d1
	move.b	(a3)+,d1
	move.w	2(a1),d0
	sub.w	d1,d0
	sub.w	d2,d0
	bcc.s	loc_17530
	add.w	d1,d1
	add.w	d1,d0
	bcs.s	loc_17536
	bra.w	loc_1756E
; ===========================================================================

loc_17530:
	cmp.w	d4,d0
	bhi.w	loc_1756E

loc_17536:
	moveq	#0,d1
	move.b	(a3)+,d1
	move.w	4(a1),d0
	sub.w	d1,d0
	sub.w	d3,d0
	bcc.s	loc_17550
	add.w	d1,d1
	add.w	d1,d0
	bcs.w	loc_17564
	bra.w	loc_1756E
; ===========================================================================

loc_17550:
	cmp.w	d5,d0
	bhi.w	loc_1756E
	bra.s	loc_17564
; ===========================================================================
byte_17558:
	dc.b $20
	dc.b $20	; 1
	dc.b $20	; 2
	dc.b $20	; 3
	dc.b $40	; 4
	dc.b   8	; 5
	dc.b $40	; 6
	dc.b   8	; 7
	dc.b   8	; 8
	dc.b $40	; 9
	dc.b   8	; 10
	dc.b $40	; 11
; ===========================================================================

loc_17564:
	move.w	(a1),d0
	move.w	off_1757A(pc,d0.w),d0
	jmp	off_1757A(pc,d0.w)
; ===========================================================================

loc_1756E:
	lea	6(a1),a1
	cmpa.l	a1,a2
	bne.w	loc_1750E

return_17578:
	rts
; ===========================================================================
off_1757A:
	dc.w loc_17586 - off_1757A
	dc.w loc_17638 - off_1757A; 1
	dc.w loc_1769E - off_1757A; 2
	dc.w loc_176F6 - off_1757A; 3
	dc.w loc_1774C - off_1757A; 4
	dc.w loc_177A4 - off_1757A; 5
; ===========================================================================

loc_17586:
	move.w	4(a1),d0
	sub.w	y_pos(a0),d0
	neg.w	d0
	cmpi.w	#$20,d0
	blt.s	loc_175A0
	move.w	#$A00,y_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_175A0:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	neg.w	d0
	cmpi.w	#$20,d0
	blt.s	loc_175BA
	move.w	#$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_175BA:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	cmpi.w	#$20,d0
	blt.s	loc_175CC
	move.w	#$20,d0

loc_175CC:
	add.w	4(a1),d0
	subq.w	#8,d0
	move.w	y_pos(a0),d1
	addi.w	#$E,d1
	sub.w	d1,d0
	bcc.s	return_175E8
	move.w	#$20,d3
	bsr.s	loc_175EA
	bra.w	loc_177FA
; ===========================================================================

return_175E8:
	rts
; ===========================================================================

loc_175EA:
	move.w	x_vel(a0),d1
	move.w	y_vel(a0),d2
	jsr	(CalcAngle).l
	move.b	d0,($FFFFFFDC).w
	sub.w	d3,d0
	mvabs.w	d0,d1
	neg.w	d0
	add.w	d3,d0
	move.b	d0,($FFFFFFDD).w
	move.b	d1,($FFFFFFDF).w
	cmpi.b	#$38,d1
	blo.s	loc_17618
	move.w	d3,d0

loc_17618:
	move.b	d0,($FFFFFFDE).w
	jsr	(CalcSine).l
	muls.w	#-$A00,d1
	asr.l	#8,d1
	move.w	d1,x_vel(a0)
	muls.w	#-$A00,d0
	asr.l	#8,d0
	move.w	d0,y_vel(a0)
	rts
; ===========================================================================

loc_17638:
	move.w	4(a1),d0
	sub.w	y_pos(a0),d0
	neg.w	d0
	cmpi.w	#$20,d0
	blt.s	loc_17652
	move.w	#$A00,y_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_17652:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	cmpi.w	#$20,d0
	blt.s	loc_1766A
	move.w	#-$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_1766A:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	neg.w	d0
	cmpi.w	#$20,d0
	blt.s	loc_1767E
	move.w	#$20,d0

loc_1767E:
	add.w	4(a1),d0
	subq.w	#8,d0
	move.w	y_pos(a0),d1
	addi.w	#$E,d1
	sub.w	d1,d0
	bcc.s	return_1769C
	move.w	#$60,d3
	bsr.w	loc_175EA
	bra.w	loc_177FA
; ===========================================================================

return_1769C:
	rts
; ===========================================================================

loc_1769E:
	move.w	4(a1),d0
	sub.w	y_pos(a0),d0
	neg.w	d0
	cmpi.w	#8,d0
	blt.s	loc_176B8
	move.w	#$A00,y_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_176B8:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	cmpi.w	#$40,d0
	blt.s	loc_176D0
	move.w	#-$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_176D0:
	neg.w	d0
	cmpi.w	#$40,d0
	blt.s	loc_176E2
	move.w	#$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_176E2:
	move.w	#$38,d3
	tst.w	d0
	bmi.s	loc_176EE
	move.w	#$48,d3

loc_176EE:
	bsr.w	loc_175EA
	bra.w	loc_177FA
; ===========================================================================

loc_176F6:
	move.w	4(a1),d0
	sub.w	y_pos(a0),d0
	cmpi.w	#8,d0
	blt.s	loc_1770E
	move.w	#-$A00,y_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_1770E:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	cmpi.w	#$40,d0
	blt.s	loc_17726
	move.w	#-$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_17726:
	neg.w	d0
	cmpi.w	#$40,d0
	blt.s	loc_17738
	move.w	#$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_17738:
	move.w	#$C8,d3
	tst.w	d0
	bmi.s	loc_17744
	move.w	#$B8,d3

loc_17744:
	bsr.w	loc_175EA
	bra.w	loc_177FA
; ===========================================================================

loc_1774C:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	neg.w	d0
	cmpi.w	#8,d0
	blt.s	loc_17766
	move.w	#$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_17766:
	move.w	4(a1),d0
	sub.w	y_pos(a0),d0
	cmpi.w	#$40,d0
	blt.s	loc_1777E
	move.w	#-$A00,y_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_1777E:
	neg.w	d0
	cmpi.w	#$40,d0
	blt.s	loc_17790
	move.w	#$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_17790:
	move.w	#8,d3
	tst.w	d0
	bmi.s	loc_1779C
	move.w	#$F8,d3

loc_1779C:
	bsr.w	loc_175EA
	bra.w	loc_177FA
; ===========================================================================

loc_177A4:
	move.w	2(a1),d0
	sub.w	x_pos(a0),d0
	cmpi.w	#8,d0
	blt.s	loc_177BC
	move.w	#$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_177BC:
	move.w	4(a1),d0
	sub.w	y_pos(a0),d0
	cmpi.w	#$40,d0
	blt.s	loc_177D4
	move.w	#-$A00,y_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_177D4:
	neg.w	d0
	cmpi.w	#$40,d0
	blt.s	loc_177E6
	move.w	#$A00,x_vel(a0)
	bra.w	loc_177FA
; ===========================================================================

loc_177E6:
	move.w	#$78,d3
	tst.w	d0
	bmi.s	loc_177F2
	move.w	#$88,d3

loc_177F2:
	bsr.w	loc_175EA
	bra.w	loc_177FA
loc_177FA:
	bset	#1,status(a0)
	bclr	#4,status(a0)
	bclr	#5,status(a0)
	bclr	#s3b_jumping,status3(a0)
	move.w	#SndID_LargeBumper,d0
	jmp	(PlaySound).l
; ===========================================================================
byte_1781A:	BINCLUDE	"level/objects/CNZ 1 bumpers.bin"
byte_1795E:	BINCLUDE	"level/objects/CNZ 2 bumpers.bin"
; ===========================================================================
	nop




; ===========================================================================
; ---------------------------------------------------------------------------
; Objects Manager
; Subroutine that loads objects from an act's object layout once they are in
; range and keeps track of any objects that need to remember their state, such
; as monitors or enemies.
; Weather an object is in range is determined by its x-position. Objects are
; checked on a per-chunk basis, rather than using the exact camera coordinates.
; An object is out of range when it is either two chunks behind the left edge of
; the screen or two chunks beyond the right edge.
; Every object that remembers its state has its own entry in the object respawn table.
; How this entry is used is up to the object, itself.
; The first two bytes in the respawn table do not belong to any object, instead they
; keep track of how many respawning objects have moved in range from the right
; and how many have moved out of range from the left, respectively.
; ---------------------------------------------------------------------------

; loc_17AA4
ObjectsManager:
	moveq	#0,d0
	move.b	(Obj_placement_routine).w,d0
	move.w	+(pc,d0.w),d0
	jmp	+(pc,d0.w)
; ============== RELATIVE OFFSET LIST     ===================================
/	dc.w ObjectsManager_Init - (-)
	dc.w ObjectsManager_Main - (-); 2
; ============== END RELATIVE OFFSET LIST ===================================
; loc_17AB8
ObjectsManager_Init:
	addq.b	#2,(Obj_placement_routine).w
	move.w	(Current_ZoneAndAct).w,d0 ; If level == $0F01 (ARZ 2)...
	ror.b	#1,d0			; then this yields $0F80...
	lsr.w	#6,d0			; and this yields $003E.
	lea	(Off_Objects).l,a0	; Next, we load the first pointer in the object layout list pointer index,
	movea.l	a0,a1			; then copy it for quicker use later.
	adda.w	(a0,d0.w),a0		; (Point1 * 2) + $003E

	move.l	a0,(Obj_load_addr_0).w
	move.l	a0,(Obj_load_addr_1).w
	move.l	a0,(Obj_load_addr_2).w
	move.l	a0,(Obj_load_addr_3).w
	lea	(Object_Respawn_Table).w,a2	; load respawn list
	move.w	#$101,(a2)+	; the first two bytes are not used as respawn values
	move.w	#$5E,d0		; set loop counter

-
	clr.l	(a2)+		; loop clears all other respawn values
	dbf	d0,-

	lea	(Object_Respawn_Table).w,a2	; reset
	moveq	#0,d2
	move.w	(Camera_X_pos).w,d6
	subi.w	#$80,d6	; pretend the camera is farther left
	bcc.s	+	; if the result was not negative, skip the next instruction
	moveq	#0,d6	; no negative values allowed
+
	andi.w	#$FF80,d6	; limit to increments of $80 (width of a chunk)
	movea.l	(Obj_load_addr_0).w,a0	; load address of object placement list

-	; at the beginning of a level this gives respawn table entries to any object that is one chunk
	; behind the left edge of the screen that needs to remember its state (Monitors, Badniks, etc.)
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17B3E	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	move.b	(a2),d2
	addq.b	#1,(a2)	; number of objects with a respawn table entry, so far
+
	addq.w	#6,a0	; next object
	bra.s	-
; ---------------------------------------------------------------------------

loc_17B3E:
	move.l	a0,(Obj_load_addr_0).w	; remember rightmost object that has been processed, so far (we still need to look forward)
	move.l	a0,(Obj_load_addr_2).w
	movea.l	(Obj_load_addr_1).w,a0	; reset
	subi.w	#$80,d6		; look even farther left (any object behind this is out of range)
	bcs.s	loc_17B62	; branch, if camera position would be behind level's left boundary

-	; count how many objects are behind the screen that are not in range and need to remember their state
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17B62	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	addq.b	#1,1(a2)	; out-of-range number of objects with a respawn table entry

+
	addq.w	#6,a0
	bra.s	-	; continue with next object
; ---------------------------------------------------------------------------

loc_17B62:
	move.l	a0,(Obj_load_addr_1).w	; remember rightmost out-of-range object
	move.l	a0,(Obj_load_addr_3).w
	move.w	#-1,(Camera_X_pos_last).w	; make sure the GoingForward routine is run
	move.w	#-1,($FFFFF78C).w
; ---------------------------------------------------------------------------
; loc_17B84
ObjectsManager_Main:
	move.w	(Camera_X_pos).w,d1
	subi.w	#$80,d1
	andi.w	#$FF80,d1
	move.w	d1,(Camera_X_pos_coarse).w

	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d2
	move.w	(Camera_X_pos).w,d6
	andi.w	#$FF80,d6
	cmp.w	(Camera_X_pos_last).w,d6	; is the X range the same as last time?
	beq.w	ObjectsManager_SameXRange	; if yes, branch
	bge.s	ObjectsManager_GoingForward	; if new pos is greater than old pos, branch
	; if the player is moving back
	move.w	d6,(Camera_X_pos_last).w
	movea.l	(Obj_load_addr_1).w,a0	; get rightmost out-of-range object
	subi.w	#$80,d6		; pretend the camera is farther to the left
	bcs.s	loc_17BE6	; branch, if camera position would be behind level's left boundary

-	; load all objects left of the screen that are now in range
	cmp.w	-6(a0),d6	; is the previous object's X pos less than d6?
	bge.s	loc_17BE6	; if it is, branch
	subq.w	#6,a0
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	subq.b	#1,1(a2)	; out-of-range number of objects with a respawn table entry
	move.b	1(a2),d2	; this will be the object's index in the respawn table
+
	bsr.w	ChkLoadObj	; load object
	bne.s	+		; branch, if SST is full
	subq.w	#6,a0
	bra.s	-	; continue with previous object
; ---------------------------------------------------------------------------

+	; undo a few things, if the object couldn't load
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	addq.b	#1,1(a2)	; since we didn't load the object, undo last decrement
+
	addq.w	#6,a0	; go back to next object

loc_17BE6:
	move.l	a0,(Obj_load_addr_1).w	; remember rightmost out-of-range object
	movea.l	(Obj_load_addr_0).w,a0	; get rightmost in-range object
	addi.w	#$300,d6	; look two chunks beyond the right edge of the screen

-	; subtract number of objects that have been moved out-of-range (from the right side)
	cmp.w	-6(a0),d6	; is the previous object's X pos less than d6?
	bgt.s	loc_17C04	; if it is, branch
	tst.b	-4(a0)	; does the previous object get a respawn table entry?
	bpl.s	+	; if not, branch
	subq.b	#1,(a2)	; number of objects with a respawn table entry
+
	subq.w	#6,a0
	bra.s	-	; continue with previous object
; ---------------------------------------------------------------------------

loc_17C04:
	move.l	a0,(Obj_load_addr_0).w	; remember rightmost in-range object
	rts
; ---------------------------------------------------------------------------

ObjectsManager_GoingForward:
	move.w	d6,(Camera_X_pos_last).w
	movea.l	(Obj_load_addr_0).w,a0	; get rightmost in-range object
	addi.w	#$280,d6	; look two chunks forward

-	; load all objects right of the screen, that are now in range
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17C2A	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	move.b	(a2),d2	; this will be the object's index in the respawn table
	addq.b	#1,(a2)	; number of objects with a respawn table entry
+
	bsr.w	ChkLoadObj	; load object
	beq.s	-	; continue loading objects, if the SST isn't full

loc_17C2A:
	move.l	a0,(Obj_load_addr_0).w	; remember rightmost in-range object
	movea.l	(Obj_load_addr_1).w,a0	; get rightmost out-of-range object
	subi.w	#$300,d6	; look two chunks behind the left edge of the screen
	bcs.s	loc_17C4A	; branch, if camera position would be behind level's left boundary

-	; count number of objects that have been moved out-of-range (from the left)
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17C4A	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	addq.b	#1,1(a2)	; out-of-range number of objects with a respawn table entry
+
	addq.w	#6,a0
	bra.s	-	; continue with next object
; ---------------------------------------------------------------------------

loc_17C4A:
	move.l	a0,(Obj_load_addr_1).w	; remember rightmost out-of-range object

ObjectsManager_SameXRange:
	rts

; ===========================================================================
;loc_17F36
ChkLoadObj:
	tst.b	2(a0)			; does the object get a respawn table entry?
	bpl.s	+			; if not, branch
	bset	#7,respawnentry(a2,d2.w)		; mark object as loaded
	beq.s	+			; branch if it wasn't already loaded
	addq.w	#6,a0			; next object
	moveq	#0,d0			; let the objects manager know that it can keep going
	rts
+	moveq	#0,d0
	move.b	4(a0),d0		; get object index
	subq	#1,d0			; is it empty?
	bmi.b	ChkLoadObj_Empty	; if so, branch
	add.w	d0,d0			; form word indices
	move.w	Obj_Index(pc,d0.w),a3	; get object's initial routine
	bsr.w	SingleObjLoad		; find empty slot
	bne.s	ChkLoadObj_Return	; branch, if there is no room left in the SST
	move.w	a3,(a1)			; set object routine pointer
	move.w	(a0)+,x_pos(a1)
	move.w	(a0)+,d0		; there are three things stored in this word
	bpl.s	+			; branch, if the object doesn't get a respawn table entry
	move.b	d2,respawn_index(a1)	; this value is provided by the objects manager
+	move.w	d0,d1			; copy for later
	andi.w	#$FFF,d0		; filter out y-position
	move.w	d0,y_pos(a1)
	rol.w	#3,d1			; adjust bits
	andi.b	#3,d1			; filter lowest two
	move.b	d1,render_flags(a1)
	move.b	d1,status(a1)
	move.w	(a0)+,d0
	move.b	d0,subtype(a1)

ChkLoadObj_Empty:
	moveq	#0,d0

ChkLoadObj_Return:
	rts
	
; ===========================================================================
	include "code/objects/Object_Specific_Routines/object_index.asm"
	even
; ---------------------------------------------------------------------------
; Solid object subroutines (includes spikes, blocks, rocks etc)
; These check collision of Sonic/Tails with objects on the screen
;
; input variables:
; d1 = object width
; d2 = object height / 2 (when jumping)
; d3 = object height / 2 (when walking)
; d4 = object x-axis position
;
; address registers:
; a0 = the object to check collision with
; a1 = sonic or tails (set inside these subroutines)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_19718:
SolidObject:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)	; store input registers
	bsr.s	+	; first check collision with Sonic
	movem.l	(sp)+,d1-d4	; restore input registers
	lea	(Sidekick).w,a1 ; a1=character ; now check collision with Tails
	tst.b	render_flags(a1)
	bpl.w	return_19776	; return if no Tails
	addq.b	#1,d6
+
	btst	d6,status(a0)
	beq.w	SolidObject_cont
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_1975A
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_1975A
	cmp.w	d2,d0
	blo.s	loc_1976E

loc_1975A:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_1976E:
	move.w	d4,d2
	bsr.w	MvSonicOnPtfm
	moveq	#0,d4

return_19776:
	rts

; ===========================================================================
; there are a few slightly different SolidObject functions
; specialized for certain objects, in this case, obj74 and obj30
; loc_19778:
SolidObject74_30:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	loc_1978E
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

loc_1978E:
	btst	d6,status(a0)
	beq.w	SolidObject2
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_197B2
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_197B2
	cmp.w	d2,d0
	blo.s	loc_197C6

loc_197B2:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_197C6:
	move.w	d4,d2
	bsr.w	MvSonicOnPtfm
	moveq	#0,d4
	rts

; ===========================================================================
; loc_197D0:
SolidObject86_30:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	SolidObject_Simple
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

; this gets called from a few more places...
; loc_197E6:
SolidObject_Simple:
	btst	d6,status(a0)
	beq.w	SolidObject86_30_alt
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_1980A
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_1980A
	cmp.w	d2,d0
	blo.s	loc_1981E

loc_1980A:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_1981E:
	move.w	d4,d2
	bsr.w	loc_19BCC
	moveq	#0,d4
	rts

; ===========================================================================
; unused/dead code for some SolidObject check
; SolidObject_Unk: loc_19828:
	; a0=object
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	+
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6
+
	btst	d6,status(a0)
	beq.w	SolidObject_Unk_cont
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_19862
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_19862
	cmp.w	d2,d0
	blo.s	loc_19876

loc_19862:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_19876:
	move.w	d4,d2
	bsr.w	loc_19C0E
	moveq	#0,d4
	rts

; ===========================================================================
; loc_19880:
SolidObject45:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	loc_19896
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

loc_19896:
	btst	d6,status(a0)
	beq.w	SolidObject45_alt
	btst	#1,status(a1)
	bne.s	loc_198B8
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_198B8
	add.w	d1,d1
	cmp.w	d1,d0
	blo.s	loc_198CC

loc_198B8:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_198CC:
	move.w	y_pos(a0),d0
	sub.w	d2,d0
	add.w	d3,d0
	moveq	#0,d1
	move.b	height_pixels(a1),d1
	lsr.b	#1,d1
	sub.w	d1,d0
	move.w	d0,y_pos(a1)
	sub.w	x_pos(a0),d4
	sub.w	d4,x_pos(a1)
	moveq	#0,d4
	rts
; ===========================================================================
; loc_198EC:
SolidObject45_alt:
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	loc_19AC4
	move.w	d1,d4
	add.w	d4,d4
	cmp.w	d4,d0
	bhi.w	loc_19AC4
	move.w	y_pos(a0),d5
	add.w	d3,d5
	move.b	height_pixels(a1),d3
	lsr.b	#1,d3
	ext.w	d3
	add.w	d3,d2
	move.w	y_pos(a1),d3
	sub.w	d5,d3
	addq.w	#4,d3
	add.w	d2,d3
	bmi.w	loc_19AC4
	move.w	d2,d4
	add.w	d4,d4
	cmp.w	d4,d3
	bhs.w	loc_19AC4
	bra.w	loc_19A2E
; ===========================================================================
; loc_1992E:
SolidObject86_30_alt:
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	loc_19AC4
	move.w	d1,d3
	add.w	d3,d3
	cmp.w	d3,d0
	bhi.w	loc_19AC4
	move.w	d0,d5
	btst	#0,render_flags(a0)
	beq.s	+
	not.w	d5
	add.w	d3,d5
+
	lsr.w	#1,d5
	move.b	(a2,d5.w),d3
	sub.b	(a2),d3
	ext.w	d3
	move.w	y_pos(a0),d5
	sub.w	d3,d5
	move.b	height_pixels(a1),d3
	lsr.b	#1,d3
	ext.w	d3
	add.w	d3,d2
	move.w	y_pos(a1),d3
	sub.w	d5,d3
	addq.w	#4,d3
	add.w	d2,d3
	bmi.w	loc_19AC4
	move.w	d2,d4
	add.w	d4,d4
	cmp.w	d4,d3
	bhs.w	loc_19AC4
	bra.w	loc_19A2E
; ===========================================================================
; seems to be unused
; loc_19988:
SolidObject_Unk_cont:
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	loc_19AC4
	move.w	d1,d3
	add.w	d3,d3
	cmp.w	d3,d0
	bhi.w	loc_19AC4
	move.w	d0,d5
	btst	#0,render_flags(a0)
	beq.s	+
	not.w	d5
	add.w	d3,d5
+
	andi.w	#$FFFE,d5
	move.b	(a2,d5.w),d3
	move.b	1(a2,d5.w),d2
	ext.w	d2
	ext.w	d3
	move.w	y_pos(a0),d5
	sub.w	d3,d5
	move.w	y_pos(a1),d3
	sub.w	d5,d3
	move.b	height_pixels(a1),d5
	lsr.b	#1,d5
	ext.w	d5
	add.w	d5,d3
	addq.w	#4,d3
	bmi.w	loc_19AC4
	add.w	d5,d2
	move.w	d2,d4
	add.w	d5,d4
	cmp.w	d4,d3
	bhs.w	loc_19AC4
	bra.w	loc_19A2E
; ===========================================================================
; loc_199E8:
SolidObject_cont:
	tst.b	render_flags(a0)
	bpl.w	loc_19AC4

SolidObject2:
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	loc_19AC4
	move.w	d1,d3
	add.w	d3,d3
	cmp.w	d3,d0
	bhi.w	loc_19AC4
	move.b	height_pixels(a1),d3
	lsr.b	#1,d3
	ext.w	d3
	add.w	d3,d2
	move.w	y_pos(a1),d3
	sub.w	y_pos(a0),d3
	addq.w	#4,d3
	add.w	d2,d3
	bmi.w	loc_19AC4
	andi.w	#$7FF,d3
	move.w	d2,d4
	add.w	d4,d4
	cmp.w	d4,d3
	bhs.w	loc_19AC4

loc_19A2E:
	btst	#s3b_lock_jumping,status3(a1)
	bne.w	loc_19AC4
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	SolidObject2_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	loc_19AEA	
	move.w	SolidObject2_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	loc_19AEA
	move.w	SolidObject2_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	loc_19AEA		
	tst.w	(Debug_placement_mode).w
	bne.w	loc_19AEA
	move.w	d0,d5
	cmp.w	d0,d1
	bhs.s	loc_19A56
	add.w	d1,d1
	sub.w	d1,d0
	move.w	d0,d5
	neg.w	d5

loc_19A56:
	move.w	d3,d1
	cmp.w	d3,d2
	bhs.s	loc_19A64
	subq.w	#4,d3
	sub.w	d4,d3
	move.w	d3,d1
	neg.w	d1

loc_19A64:
	cmp.w	d1,d5
	bhi.w	loc_19AEE

loc_19A6A:
	cmpi.w	#4,d1
	bls.s	loc_19AB6
	tst.w	d0
	beq.s	loc_19A90
	bmi.s	loc_19A7E
	tst.w	x_vel(a1)
	bmi.s	loc_19A90
	bra.s	loc_19A84
	
SolidObject2_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

SolidObject2_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

SolidObject2_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)		
; ===========================================================================

loc_19A7E:
	tst.w	x_vel(a1)
	bpl.s	loc_19A90

loc_19A84:
	move.w	#0,inertia(a1)
	move.w	#0,x_vel(a1)

loc_19A90:
	sub.w	d0,x_pos(a1)
	btst	#1,status(a1)
	bne.s	loc_19AB6
	move.l	d6,d4
	addq.b	#2,d4
	bset	d4,status(a0)
	bset	#5,status(a1)
	move.w	d6,d4
	addi.b	#$D,d4
	bset	d4,d6
	moveq	#1,d4
	rts
; ===========================================================================

loc_19AB6:
	bsr.s	loc_19ADC
	move.w	d6,d4
	addi.b	#$D,d4
	bset	d4,d6
	moveq	#1,d4
	rts
; ===========================================================================

loc_19AC4:
	move.l	d6,d4
	addq.b	#2,d4
	btst	d4,status(a0)
	beq.s	loc_19AEA
	cmpi.b	#2,anim(a1)
	beq.s	loc_19ADC
	move.w	#1,anim(a1)

loc_19ADC:
	move.l	d6,d4
	addq.b	#2,d4
	bclr	d4,status(a0)
	bclr	#5,status(a1)

loc_19AEA:
	moveq	#0,d4
	rts
; ===========================================================================

loc_19AEE:
	tst.w	d3
	bmi.s	loc_19B06
	cmpi.w	#$10,d3
	blo.s	loc_19B56
	cmpi.b	#-$7B,(a0)
	bne.s	loc_19AC4
	cmpi.w	#$14,d3
	blo.s	loc_19B56
	bra.s	loc_19AC4
; ===========================================================================

loc_19B06:
	tst.w	y_vel(a1)
	beq.s	loc_19B28
	bpl.s	loc_19B1C
	tst.w	d3
	bpl.s	loc_19B1C
	sub.w	d3,y_pos(a1)
	move.w	#0,y_vel(a1)

loc_19B1C:
	move.w	d6,d4
	addi.b	#$F,d4
	bset	d4,d6
	moveq	#-2,d4
	rts
; ===========================================================================

loc_19B28:
	btst	#1,status(a1)
	bne.s	loc_19B1C
	mvabs.w	d0,d4
	cmpi.w	#$10,d4
	blo.w	loc_19A6A
	move.l	a0,-(sp)
	movea.l	a1,a0
	jsr	(KillCharacter).l
	movea.l	(sp)+,a0 ; load 0bj address
	move.w	d6,d4
	addi.b	#$F,d4
	bset	d4,d6
	moveq	#-2,d4
	rts
; ===========================================================================

loc_19B56:
	subq.w	#4,d3
	moveq	#0,d1
	move.b	width_pixels(a0),d1
	move.w	d1,d2
	add.w	d2,d2
	add.w	x_pos(a1),d1
	sub.w	x_pos(a0),d1
	bmi.s	loc_19B8E
	cmp.w	d2,d1
	bhs.s	loc_19B8E
	tst.w	y_vel(a1)
	bmi.s	loc_19B8E
	sub.w	d3,y_pos(a1)
	subq.w	#1,y_pos(a1)
	bsr.w	loc_19E14
	move.w	d6,d4
	addi.b	#$11,d4
	bset	d4,d6
	moveq	#-1,d4
	rts
; ===========================================================================

loc_19B8E:
	moveq	#0,d4
	rts
; ===========================================================================

; Subroutine to change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; loc_19B92:

MvSonicOnPtfm:
	move.w	y_pos(a0),d0
	sub.w	d3,d0
	bra.s	loc_19BA2
; ===========================================================================
	; a couple lines of unused/leftover/dead code from Sonic 1 ; a0=object
	move.w	y_pos(a0),d0
	subi.w	#9,d0

loc_19BA2:
	btst	#s3b_lock_jumping,status3(a1)
	bne.s	return_19BCA
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	MvSonicOnPtfm_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_19BCA	
	move.w	MvSonicOnPtfm_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_19BCA
	move.w	MvSonicOnPtfm_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_19BCA		
	tst.w	(Debug_placement_mode).w
	bne.s	return_19BCA
	moveq	#0,d1
	move.b	height_pixels(a1),d1
	lsr.b	#1,d1
	sub.w	d1,d0
	move.w	d0,y_pos(a1)
	sub.w	x_pos(a0),d2
	sub.w	d2,x_pos(a1)

return_19BCA:
	rts
	
MvSonicOnPtfm_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

MvSonicOnPtfm_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

MvSonicOnPtfm_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)		
; ===========================================================================

loc_19BCC:
	btst	#3,status(a1)
	beq.s	return_19C0C
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	lsr.w	#1,d0
	btst	#0,render_flags(a0)
	beq.s	loc_19BEC
	not.w	d0
	add.w	d1,d0

loc_19BEC:
	move.b	(a2,d0.w),d1
	ext.w	d1
	move.w	y_pos(a0),d0
	sub.w	d1,d0
	moveq	#0,d1
	move.b	height_pixels(a1),d1
	lsr.b	#1,d1
	sub.w	d1,d0
	move.w	d0,y_pos(a1)
	sub.w	x_pos(a0),d2
	sub.w	d2,x_pos(a1)

return_19C0C:
	rts
; ===========================================================================

loc_19C0E:
	btst	#3,status(a1)
	beq.s	return_19C0C
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	btst	#0,render_flags(a0)
	beq.s	loc_19C2C
	not.w	d0
	add.w	d1,d0

loc_19C2C:
	andi.w	#$FFFE,d0
	bra.s	loc_19BEC
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to collide Sonic/Tails with the top of a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_19C32:
PlatformObject:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	PlatformObject_SingleCharacter
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

; loc_19C48:
PlatformObject_SingleCharacter:
	btst	d6,status(a0)
	beq.w	loc_19DBA
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	+
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	+
	cmp.w	d2,d0
	blo.s	loc_19C80
+

	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_19C80:
	move.w	d4,d2
	bsr.w	MvSonicOnPtfm
	moveq	#0,d4
	rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to collide Sonic/Tails with the top of a sloped platform like a seesaw
; ---------------------------------------------------------------------------

; loc_19C8A:
SlopeObject:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	SlopeObject_SingleCharacter
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

; loc_19CA0:
SlopeObject_SingleCharacter:
	btst	d6,status(a0)
	beq.w	loc_19E90
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_19CC4
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_19CC4
	cmp.w	d2,d0
	blo.s	loc_19CD8

loc_19CC4:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_19CD8:
	move.w	d4,d2
	bsr.w	loc_19BCC
	moveq	#0,d4
	rts
; ===========================================================================

loc_19CE2:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	loc_19CF8
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

loc_19CF8:
	btst	d6,status(a0)
	beq.w	loc_19EC8
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_19D1C
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_19D1C
	cmp.w	d2,d0
	blo.s	loc_19D30

loc_19D1C:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ===========================================================================

loc_19D30:
	move.w	d4,d2
	bsr.w	MvSonicOnPtfm
	moveq	#0,d4
	rts
; ===========================================================================

loc_19D3A:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	loc_19D50
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

loc_19D50:
	btst	d6,status(a0)
	bne.s	loc_19D62
	btst	#3,status(a1)
	bne.s	loc_19D8E
	bra.w	loc_19DBA
; ===========================================================================

loc_19D62:
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_19D7E
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_19D7E
	cmp.w	d2,d0
	blo.s	loc_19D92

loc_19D7E:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)

loc_19D8E:
	moveq	#0,d4
	rts
; ===========================================================================

loc_19D92:
	move.w	d4,d2
	bsr.w	MvSonicOnPtfm
	moveq	#0,d4
	rts
; ===========================================================================

loc_19D9C:
	tst.w	y_vel(a1)
	bmi.w	return_19E8E
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	return_19E8E
	cmp.w	d2,d0
	bhs.w	return_19E8E
	bra.s	loc_19DD8
; ===========================================================================

loc_19DBA:
	tst.w	y_vel(a1)
	bmi.w	return_19E8E
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	return_19E8E
	add.w	d1,d1
	cmp.w	d1,d0
	bhs.w	return_19E8E

loc_19DD8:
	move.w	y_pos(a0),d0
	sub.w	d3,d0

loc_19DDE:
	move.w	y_pos(a1),d2
	move.b	height_pixels(a1),d1
	lsr.b	#1,d1
	ext.w	d1
	add.w	d2,d1
	addq.w	#4,d1
	sub.w	d1,d0
	bhi.w	return_19E8E
	cmpi.w	#-$10,d0
	blo.w	return_19E8E
	btst	#s3b_lock_jumping,status3(a1)
	bne.w	return_19E8E
	move.w	(MainCharacter).w,d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	SlopeObject_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_19E8E	
	move.w	SlopeObject_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_19E8E
	move.w	SlopeObject_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_19E8E
	add.w	d0,d2
	addq.w	#3,d2
	move.w	d2,y_pos(a1)

loc_19E14:
	btst	#3,status(a1)
	beq.s	loc_19E30
	moveq	#-1,d0
	move.w	interact_obj(a1),d0
	movea.l	d0,a3	; a3=object
	bclr	d6,status(a3)

loc_19E30:
	move.w	a0,interact_obj(a1)
	move.b	#0,angle(a1)
	move.w	#0,y_vel(a1)
	move.w	x_vel(a1),inertia(a1)
	btst	#1,status(a1)
	beq.s	loc_19E7E
	move.l	a0,-(sp)
	movea.l	a1,a0
	move.w	a0,d1
	subi.w	#Object_RAM,d1
	bne.s	loc_19E76
	cmpi.w	#2,(Player_mode).w
	beq.s	loc_19E76
	jsr	(Sonic_ResetOnFloor_Part2).l
	bra.s	loc_19E7C
	
SlopeObject_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

SlopeObject_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

SlopeObject_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)		
; ===========================================================================

loc_19E76:
	jsr	(Tails_ResetOnFloor_Part2).l

loc_19E7C:
	movea.l	(sp)+,a0 ; a0=character

loc_19E7E:
	bset	#3,status(a1)
	bclr	#1,status(a1)
	bset	d6,status(a0)

return_19E8E:
	rts
; ===========================================================================

loc_19E90:
	tst.w	y_vel(a1)
	bmi.w	return_19E8E
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	return_19E8E
	add.w	d1,d1
	cmp.w	d1,d0
	bhs.s	return_19E8E
	btst	#0,render_flags(a0)
	beq.s	loc_19EB6
	not.w	d0
	add.w	d1,d0

loc_19EB6:
	lsr.w	#1,d0
	move.b	(a2,d0.w),d3
	ext.w	d3
	move.w	y_pos(a0),d0
	sub.w	d3,d0
	bra.w	loc_19DDE
; ===========================================================================

loc_19EC8:
	tst.w	y_vel(a1)
	bmi.w	return_19E8E
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	return_19E8E
	add.w	d1,d1
	cmp.w	d1,d0
	bhs.w	return_19E8E
	move.w	y_pos(a0),d0
	sub.w	d3,d0
	bra.w	loc_19DDE
; ===========================================================================

loc_19EF0:
	lea	(MainCharacter).w,a1 ; a1=character
	btst	#3,status(a0)
	beq.s	loc_19F1E
	jsr	(loc_1EDA8).l
	tst.w	d1
	beq.s	loc_19F08
	bpl.s	loc_19F1E

loc_19F08:
	lea	(MainCharacter).w,a1 ; a1=character
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	#3,status(a0)

loc_19F1E:
	lea	(Sidekick).w,a1 ; a1=character
	btst	#4,status(a0)
	beq.s	loc_19F4C
	jsr	(loc_1EDA8).l
	tst.w	d1
	beq.s	loc_19F36
	bpl.s	loc_19F4C

loc_19F36:
	lea	(Sidekick).w,a1 ; a1=character
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	#4,status(a0)

loc_19F4C:
	moveq	#0,d4
	rts


JmpTo2_KillCharacter
	jmp	(KillCharacter).l
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to change Sonic's angle & position as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1E234: Sonic_AnglePos:
AnglePos:
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,layer(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	layer(a0),d5
	btst	#3,status(a0)
	beq.s	+
	moveq	#0,d0
	move.b	d0,($FFFFF768).w
	move.b	d0,($FFFFF76A).w
	rts
; ---------------------------------------------------------------------------
+	moveq	#3,d0
	move.b	d0,($FFFFF768).w
	move.b	d0,($FFFFF76A).w
	move.b	angle(a0),d0
	addi.b	#$20,d0
	bpl.s	loc_1E286
	move.b	angle(a0),d0
	bpl.s	+
	subq.b	#1,d0
+
	addi.b	#$20,d0
	bra.s	loc_1E292
; ---------------------------------------------------------------------------
loc_1E286:
	move.b	angle(a0),d0
	bpl.s	loc_1E28E
	addq.b	#1,d0

loc_1E28E:
	addi.b	#$1F,d0

loc_1E292:
	andi.b	#$C0,d0
	cmpi.b	#$40,d0
	beq.w	loc_1E4E8
	cmpi.b	#$80,d0
	beq.w	loc_1E43A
	cmpi.b	#$C0,d0
	beq.w	Sonic_WalkVertR
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF768).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindFloor
	move.w	d1,-(sp)
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	neg.w	d0
	add.w	d0,d3
	lea	($FFFFF76A).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindFloor
	move.w	(sp)+,d0
	bsr.w	Sonic_Angle
	tst.w	d1
	beq.s	return_1E31C
	bpl.s	loc_1E31E
	cmpi.w	#-$E,d1
	blt.s	return_1E31C
	add.w	d1,y_pos(a0)

return_1E31C:
	rts
; ===========================================================================

loc_1E31E:
	mvabs.b	x_vel(a0),d0
	addq.b	#4,d0
	cmpi.b	#$E,d0
	blo.s	+
	move.b	#$E,d0
+
	cmp.b	d0,d1
	bgt.s	loc_1E33C

loc_1E336:
	add.w	d1,y_pos(a0)
	rts
; ===========================================================================

loc_1E33C:
	btst	#s3b_stick_convex,status3(a0)
	bne.s	loc_1E336
	bset	#1,status(a0)
	bclr	#5,status(a0)
	move.b	#1,next_anim(a0)
	rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's angle as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1E356:
Sonic_Angle:
	move.b	($FFFFF76A).w,d2
	cmp.w	d0,d1
	ble.s	+
	move.b	($FFFFF768).w,d2
	move.w	d0,d1
+
	btst	#0,d2
	bne.s	loc_1E380
	move.b	d2,d0
	sub.b	angle(a0),d0
	bpl.s	+
	neg.b	d0
+
	cmpi.b	#$20,d0
	bhs.s	loc_1E380
	move.b	d2,angle(a0)
	rts
; ===========================================================================

loc_1E380:
	move.b	angle(a0),d2
	addi.b	#$20,d2
	andi.b	#$C0,d2
	move.b	d2,angle(a0)
	rts
; End of function Sonic_Angle

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to his right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1E392:
Sonic_WalkVertR:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	neg.w	d0
	add.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF768).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindWall
	move.w	d1,-(sp)
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF76A).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindWall
	move.w	(sp)+,d0
	bsr.w	Sonic_Angle
	tst.w	d1
	beq.s	return_1E400
	bpl.s	loc_1E402
	cmpi.w	#-$E,d1
	blt.s	return_1E400
	add.w	d1,x_pos(a0)

return_1E400:
	rts
; ===========================================================================

loc_1E402:
	mvabs.b	y_vel(a0),d0
	addq.b	#4,d0
	cmpi.b	#$E,d0
	blo.s	+
	move.b	#$E,d0
+
	cmp.b	d0,d1
	bgt.s	loc_1E420

loc_1E41A:
	add.w	d1,x_pos(a0)
	rts
; ===========================================================================

loc_1E420:
	btst	#s3b_stick_convex,status3(a0)
	bne.s	loc_1E41A
	bset	#1,status(a0)
	bclr	#5,status(a0)
	move.b	#1,next_anim(a0)
	rts
; ===========================================================================

loc_1E43A:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	eori.w	#$F,d2
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF768).w,a4
	movea.w	#-$10,a3
	move.w	#$800,d6
	bsr.w	FindFloor
	move.w	d1,-(sp)
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	eori.w	#$F,d2
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d3
	lea	($FFFFF76A).w,a4
	movea.w	#-$10,a3
	move.w	#$800,d6
	bsr.w	FindFloor
	move.w	(sp)+,d0
	bsr.w	Sonic_Angle
	tst.w	d1
	beq.s	return_1E4AE
	bpl.s	loc_1E4B0
	cmpi.w	#-$E,d1
	blt.s	return_1E4AE
	sub.w	d1,y_pos(a0)

return_1E4AE:
	rts
; ===========================================================================

loc_1E4B0:
	mvabs.b	x_vel(a0),d0
	addq.b	#4,d0
	cmpi.b	#$E,d0
	blo.s	+
	move.b	#$E,d0
+
	cmp.b	d0,d1
	bgt.s	loc_1E4CE

loc_1E4C8:
	sub.w	d1,y_pos(a0)
	rts
; ===========================================================================

loc_1E4CE:
	btst	#s3b_stick_convex,status3(a0)
	bne.s	loc_1E4C8
	bset	#1,status(a0)
	bclr	#5,status(a0)
	move.b	#1,next_anim(a0)
	rts
; ===========================================================================

loc_1E4E8:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d3
	eori.w	#$F,d3
	lea	($FFFFF768).w,a4
	movea.w	#-$10,a3
	move.w	#$400,d6
	bsr.w	FindWall
	move.w	d1,-(sp)
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d3
	eori.w	#$F,d3
	lea	($FFFFF76A).w,a4
	movea.w	#-$10,a3
	move.w	#$400,d6
	bsr.w	FindWall
	move.w	(sp)+,d0
	bsr.w	Sonic_Angle
	tst.w	d1
	beq.s	return_1E55C
	bpl.s	loc_1E55E
	cmpi.w	#-$E,d1
	blt.s	return_1E55C
	sub.w	d1,x_pos(a0)

return_1E55C:
	rts
; ===========================================================================

loc_1E55E:
	mvabs.b	y_vel(a0),d0
	addq.b	#4,d0
	cmpi.b	#$E,d0
	blo.s	+
	move.b	#$E,d0
+
	cmp.b	d0,d1
	bgt.s	loc_1E57C

loc_1E576:
	sub.w	d1,x_pos(a0)
	rts
; ===========================================================================

loc_1E57C:
	btst	#s3b_stick_convex,status3(a0)
	bne.s	loc_1E576
	bset	#1,status(a0)
	bclr	#5,status(a0)
	move.b	#1,next_anim(a0)
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to find which tile the object is standing on
; d2 = y_pos
; d3 = x_pos
; returns relevant block ID in (a1)
; a1 is pointer to block in chunk table
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1E596:
Floor_ChkTile:
	move.w	d2,d0	; y_pos
; 	add.w	d0,d0
; 	andi.w	#$F00,d0	; rounded 2*y_pos
	lsr.w	#7,d0		; divide by 128 for row (list entry)
	add.w	d0,d0		; double it (WORD data)
	add.w	d0,d0		; double it (FG and BG WORDs are interleaved)
	add.w	#8,d0		; Skip the Size Information
	move.l	(LevelUncLayout).l,a1
	move.w	(a1,d0.w),d0	; get row offset data for this row
	and.w	#$7FFF,d0	; Strip the high bit from the value
	move.w	d3,d1	; x_pos
	lsr.w	#3,d1
	move.w	d1,d4
	lsr.w	#4,d1	; x_pos/128 = x_of_chunk
; 	andi.w	#$FF,d1
	add.w	d1,d0	; d0 is relevant chunk ID now
	moveq	#-1,d1
	clr.w	d1
; 	move.l	(LevelUncLayout).l,a1
	move.b	(a1,d0.w),d1	; move 128*128 chunk ID to d1
	lsl.w	#7,d1
	move.w	d2,d0	; y_pos
	andi.w	#$70,d0
	add.w	d0,d1
	andi.w	#$E,d4	; x_pos/8
	add.w	d4,d1
	movea.l	d1,a1	; address of block ID
	rts

; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; d2 = y_pos
; d3 = x_pos
; d5 = ($c,$d) - solidity type bit (L/R/B or top)
; returns relevant block ID in (a1)
; returns distance to bottom in d1

; loc_1E7D0:
FindFloor:
	bsr.w	Floor_ChkTile
	move.w	(a1),d0
	move.w	d0,d4
	andi.w	#$3FF,d0
	beq.s	loc_1E7E2
	btst	d5,d4
	bne.s	loc_1E7F0

loc_1E7E2:
	add.w	a3,d2
	bsr.w	FindFloor2
	sub.w	a3,d2
	addi.w	#$10,d1
	rts
; ===========================================================================

loc_1E7F0:	; block has some solidity
	movea.l	(Collision_addr).w,a2	; pointer to collision data, i.e. blockID -> collisionID array
	move.b	(a2,d0.w),d0	; get collisionID
	andi.w	#$FF,d0
	beq.s	loc_1E7E2
	lea	(ColCurveMap).l,a2
	move.b	(a2,d0.w),(a4)	; get angle from AngleMap --> (a4)
	lsl.w	#4,d0
	move.w	d3,d1	; x_pos
	btst	#$A,d4	; adv.blockID in d4 - X flipping
	beq.s	+
	not.w	d1
	neg.b	(a4)
+
	btst	#$B,d4	; Y flipping
	beq.s	+
	addi.b	#$40,(a4)
	neg.b	(a4)
	subi.b	#$40,(a4)
+
	andi.w	#$F,d1	; x_pos (mod 16)
	add.w	d0,d1	; d0 = 16*blockID -> offset in ColArray to look up
	lea	(ColArray).l,a2
	move.b	(a2,d1.w),d0	; heigth from ColArray
	ext.w	d0
	eor.w	d6,d4
	btst	#$B,d4	; Y flipping
	beq.s	+
	neg.w	d0
+
	tst.w	d0
	beq.s	loc_1E7E2	; no collision
	bmi.s	loc_1E85E
	cmpi.b	#$10,d0
	beq.s	loc_1E86A
	move.w	d2,d1
	andi.w	#$F,d1
	add.w	d1,d0
	move.w	#$F,d1
	sub.w	d0,d1
	rts
; ===========================================================================

loc_1E85E:
	move.w	d2,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bpl.w	loc_1E7E2

loc_1E86A:
	sub.w	a3,d2
	bsr.w	FindFloor2
	add.w	a3,d2
	subi.w	#$10,d1
	rts
; End of function FindFloor


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


; loc_1E878:
FindFloor2:
	bsr.w	Floor_ChkTile
	move.w	(a1),d0
	move.w	d0,d4
	andi.w	#$3FF,d0
	beq.s	loc_1E88A
	btst	d5,d4
	bne.s	loc_1E898

loc_1E88A:
	move.w	#$F,d1
	move.w	d2,d0
	andi.w	#$F,d0
	sub.w	d0,d1
	rts
; ===========================================================================

loc_1E898:
	movea.l	(Collision_addr).w,a2
	move.b	(a2,d0.w),d0
	andi.w	#$FF,d0
	beq.s	loc_1E88A
	lea	(ColCurveMap).l,a2
	move.b	(a2,d0.w),(a4)
	lsl.w	#4,d0
	move.w	d3,d1
	btst	#$A,d4
	beq.s	+
	not.w	d1
	neg.b	(a4)
+
	btst	#$B,d4
	beq.s	+
	addi.b	#$40,(a4)
	neg.b	(a4)
	subi.b	#$40,(a4)
+
	andi.w	#$F,d1
	add.w	d0,d1
	lea	(ColArray).l,a2
	move.b	(a2,d1.w),d0
	ext.w	d0
	eor.w	d6,d4
	btst	#$B,d4
	beq.s	+
	neg.w	d0
+
	tst.w	d0
	beq.s	loc_1E88A
	bmi.s	loc_1E900
	move.w	d2,d1
	andi.w	#$F,d1
	add.w	d1,d0
	move.w	#$F,d1
	sub.w	d0,d1
	rts
; ===========================================================================

loc_1E900:
	move.w	d2,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bpl.w	loc_1E88A
	not.w	d1
	rts
; ===========================================================================
; loc_1E910:
Obj_CheckInFloor:
	bsr.w	Floor_ChkTile
	move.w	(a1),d0
	move.w	d0,d4
	andi.w	#$3FF,d0
	beq.s	loc_1E922
	btst	d5,d4
	bne.s	loc_1E928

loc_1E922:
	move.w	#$10,d1
	rts
; ===========================================================================

loc_1E928:
	movea.l	(Collision_addr).w,a2
	move.b	(a2,d0.w),d0
	andi.w	#$FF,d0
	beq.s	loc_1E922
	lea	(ColCurveMap).l,a2
	move.b	(a2,d0.w),(a4)
	lsl.w	#4,d0
	move.w	d3,d1
	btst	#$A,d4
	beq.s	+
	not.w	d1
	neg.b	(a4)
+
	btst	#$B,d4
	beq.s	+
	addi.b	#$40,(a4)
	neg.b	(a4)
	subi.b	#$40,(a4)
+
	andi.w	#$F,d1
	add.w	d0,d1
	lea	(ColArray).l,a2
	move.b	(a2,d1.w),d0
	ext.w	d0
	eor.w	d6,d4
	btst	#$B,d4
	beq.s	+
	neg.w	d0
+
	tst.w	d0
	beq.s	loc_1E922
	bmi.s	loc_1E996
	cmpi.b	#$10,d0
	beq.s	loc_1E9A2
	move.w	d2,d1
	andi.w	#$F,d1
	add.w	d1,d0
	move.w	#$F,d1
	sub.w	d0,d1
	rts
; ===========================================================================

loc_1E996:
	move.w	d2,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bpl.w	loc_1E922

loc_1E9A2:
	sub.w	a3,d2
	bsr.w	FindFloor2
	add.w	a3,d2
	subi.w	#$10,d1
	rts
; ===========================================================================

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; d2 = y_pos
; d3 = x_pos
; d5 = ($c,$d) - solidity type bit (L/R/B or top)
; returns relevant block ID in (a1)
; returns distance to left/right in d1
; returns angle in (a4)

; loc_1E9B0:
FindWall:
	bsr.w	Floor_ChkTile
	move.w	(a1),d0
	move.w	d0,d4
	andi.w	#$3FF,d0	; plain blockID
	beq.s	loc_1E9C2	; no collision
	btst	d5,d4
	bne.s	loc_1E9D0

loc_1E9C2:
	add.w	a3,d3
	bsr.w	FindWall2
	sub.w	a3,d3
	addi.w	#$10,d1
	rts
; ===========================================================================

loc_1E9D0:
	movea.l	(Collision_addr).w,a2
	move.b	(a2,d0.w),d0
	andi.w	#$FF,d0	; relevant collisionArrayEntry
	beq.s	loc_1E9C2
	lea	(ColCurveMap).l,a2
	move.b	(a2,d0.w),(a4)
	lsl.w	#4,d0	; offset in collision array
	move.w	d2,d1	; y
	btst	#$B,d4	; y-mirror?
	beq.s	+
	not.w	d1
	addi.b	#$40,(a4)
	neg.b	(a4)
	subi.b	#$40,(a4)
+
	btst	#$A,d4	; x-mirror?
	beq.s	+
	neg.b	(a4)
+
	andi.w	#$F,d1	; y
	add.w	d0,d1	; line to look up
	lea	(ColArray+$1000).l,a2	; rotated collision array
	move.b	(a2,d1.w),d0	; collision value
	ext.w	d0
	eor.w	d6,d4	; set x-flip flag if from the right
	btst	#$A,d4	; x-mirror?
	beq.s	+
	neg.w	d0
+
	tst.w	d0
	beq.s	loc_1E9C2
	bmi.s	loc_1EA3E
	cmpi.b	#$10,d0
	beq.s	loc_1EA4A
	move.w	d3,d1	; x
	andi.w	#$F,d1
	add.w	d1,d0
	move.w	#$F,d1
	sub.w	d0,d1
	rts
; ===========================================================================

loc_1EA3E:
	move.w	d3,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bpl.w	loc_1E9C2	; no collision

loc_1EA4A:
	sub.w	a3,d3
	bsr.w	FindWall2
	add.w	a3,d3
	subi.w	#$10,d1
	rts
; End of function FindWall


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EA58:
FindWall2:
	bsr.w	Floor_ChkTile
	move.w	(a1),d0
	move.w	d0,d4
	andi.w	#$3FF,d0
	beq.s	loc_1EA6A
	btst	d5,d4
	bne.s	loc_1EA78

loc_1EA6A:
	move.w	#$F,d1
	move.w	d3,d0
	andi.w	#$F,d0
	sub.w	d0,d1
	rts
; ===========================================================================

loc_1EA78:
	movea.l	(Collision_addr).w,a2
	move.b	(a2,d0.w),d0
	andi.w	#$FF,d0
	beq.s	loc_1EA6A
	lea	(ColCurveMap).l,a2
	move.b	(a2,d0.w),(a4)
	lsl.w	#4,d0
	move.w	d2,d1
	btst	#$B,d4
	beq.s	+
	not.w	d1
	addi.b	#$40,(a4)
	neg.b	(a4)
	subi.b	#$40,(a4)
+
	btst	#$A,d4
	beq.s	+
	neg.b	(a4)
+
	andi.w	#$F,d1
	add.w	d0,d1
	lea	(ColArray+$1000).l,a2
	move.b	(a2,d1.w),d0
	ext.w	d0
	eor.w	d6,d4
	btst	#$A,d4
	beq.s	+
	neg.w	d0
+
	tst.w	d0
	beq.s	loc_1EA6A
	bmi.s	loc_1EAE0
	move.w	d3,d1
	andi.w	#$F,d1
	add.w	d1,d0
	move.w	#$F,d1
	sub.w	d0,d1
	rts
; ===========================================================================

loc_1EAE0:
	move.w	d3,d1
	andi.w	#$F,d1
	add.w	d1,d0
	bpl.w	loc_1EA6A
	not.w	d1
	rts
; End of function FindWall2

; ---------------------------------------------------------------------------
; Unused floor/wall subroutine - logs something to do with collision
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; return_1EAF0:
FloorLog_Unk:
	rts
; ---------------------------------------------------------------------------
	lea	(ColArray).l,a1
	lea	(ColArray).l,a2

	; for d3 from 255 to 0
	move.w	#$FF,d3
-	moveq	#$10,d5

	; for d2 from 15 to 0
	move.w	#$F,d2
-	moveq	#0,d4

	; for d1 from 15 to 0
	move.w	#$F,d1
-	move.w	(a1)+,d0
	lsr.l	d5,d0
	addx.w	d4,d4
	dbf	d1,- ; end for d1

	move.w	d4,(a2)+
	suba.w	#$20,a1
	subq.w	#1,d5
	dbf	d2,-- ; end for d2

	adda.w	#$20,a1
	dbf	d3,--- ; end for d3

	lea	(ColArray).l,a1
	lea	(ColArray2).l,a2
	bsr.s	FloorLog_Unk2
	lea	(ColArray).l,a1
	lea	(ColArray).l,a2

; End of function FloorLog_Unk

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EB46:
FloorLog_Unk2:
	move.w	#$FFF,d3

-	moveq	#0,d2
	move.w	#$F,d1
	move.w	(a1)+,d0
	beq.s	loc_1EB78
	bmi.s	++

-	lsr.w	#1,d0
	bcc.s	+
	addq.b	#1,d2
+	dbf	d1,-

	bra.s	loc_1EB7A
; ===========================================================================
+
	cmpi.w	#-1,d0
	beq.s	++

-	lsl.w	#1,d0
	bcc.s	+
	subq.b	#1,d2
+	dbf	d1,-

	bra.s	loc_1EB7A
; ===========================================================================
+
	move.w	#$10,d0

loc_1EB78:
	move.w	d0,d2

loc_1EB7A:
	move.b	d2,(a2)+
	dbf	d3,---

	rts

; End of function FloorLog_Unk2
	nop

; ---------------------------------------------------------------------------
; Subroutine to calculate how much space is in front of Sonic or Tails on the ground
; d0 = some input angle
; d1 = output about how many pixels (up to some high enough amount)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EB84: Sonic_WalkSpeed:
CalcRoomInFront:
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,layer(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	layer_plus(a0),d5
	move.l	x_pos(a0),d3
	move.l	y_pos(a0),d2
	move.w	x_vel(a0),d1
	ext.l	d1
	asl.l	#8,d1
	add.l	d1,d3
	move.w	y_vel(a0),d1
	ext.l	d1
	asl.l	#8,d1
	add.l	d1,d2
	swap	d2
	swap	d3
	move.b	d0,($FFFFF768).w
	move.b	d0,($FFFFF76A).w
	move.b	d0,d1
	addi.b	#$20,d0
	bpl.s	loc_1EBDC

	move.b	d1,d0
	bpl.s	+
	subq.b	#1,d0
+
	addi.b	#$20,d0
	bra.s	loc_1EBE6
; ---------------------------------------------------------------------------
loc_1EBDC:
	move.b	d1,d0
	bpl.s	+
	addq.b	#1,d0
+
	addi.b	#$1F,d0

loc_1EBE6:
	andi.b	#$C0,d0
	beq.w	loc_1ECE6
	cmpi.b	#$80,d0
	beq.w	CheckSlopeDist
	andi.b	#$38,d1
	bne.s	+
	addq.w	#8,d2
+
	cmpi.b	#$40,d0
	beq.w	CheckLeftWallDist_Part2
	bra.w	CheckRightWallDist_Part2

; End of function CalcRoomInFront


; ---------------------------------------------------------------------------
; Subroutine to calculate how much space is empty above Sonic's/Tails' head
; d0 = input angle perpendicular to the spine
; d1 = output about how many pixels are overhead (up to some high enough amount)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_1EC0A:
CalcRoomOverHead:
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,layer(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	layer_plus(a0),d5
	move.b	d0,($FFFFF768).w
	move.b	d0,($FFFFF76A).w
	addi.b	#$20,d0
	andi.b	#$C0,d0
	cmpi.b	#$40,d0
	beq.w	CheckLeftCeilingDist
	cmpi.b	#$80,d0
	beq.w	CheckCeilingDist
	cmpi.b	#$C0,d0
	beq.w	CheckRightCeilingDist

; End of function CalcRoomOverHead

; ---------------------------------------------------------------------------
; Subroutine to check if Sonic/Tails is near the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EC4E: Sonic_HitFloor:
Sonic_CheckFloor:
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,layer(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	layer(a0),d5
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF768).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindFloor
	move.w	d1,-(sp)
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d3
	lea	($FFFFF76A).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindFloor
	move.w	(sp)+,d0
	move.b	#0,d2

loc_1ECC6:
	move.b	($FFFFF76A).w,d3
	cmp.w	d0,d1
	ble.s	loc_1ECD4
	move.b	($FFFFF768).w,d3
	exg	d0,d1

loc_1ECD4:
	btst	#0,d3
	beq.s	+
	move.b	d2,d3
+
	rts
; ===========================================================================

	; a bit of unused/dead code here
	move.w	y_pos(a0),d2 ; a0=character
	move.w	x_pos(a0),d3

	; no idea what this is for, some collision check
loc_1ECE6:
	addi.w	#$A,d2
	lea	($FFFFF768).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindFloor
	move.b	#0,d2

	; called at the end of the wall checking routines... don't know what it does either
loc_1ECFE:
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	+
	move.b	d2,d3
+
	rts
; ===========================================================================

	; Unused collision checking subroutine

	move.w	x_pos(a0),d3 ; a0=character
	move.w	y_pos(a0),d2
	subq.w	#4,d2
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$D,layer_plus(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#$10,a3
	move.w	#0,d6
	move.b	layer_plus(a0),d5
	bsr.w	FindFloor
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	+
	move.b	#0,d3
+
	rts

; ===========================================================================
; loc_1ED56:
ChkFloorEdge:
	move.w	x_pos(a0),d3
; loc_1ED5A:
ChkFloorEdge_Part2:
loc_1ED5A:; CODE XREF: h+354Ap h+356Ep ...
        move.w    $C(a0),d2
        moveq    #0,d0
        move.b    $16(a0),d0
        ext.w    d0
        add.w    d0,d2

loc_1ED68:
        move.l    #-$2A00,($FFFFF796).w
        cmpi.b    #$C,$3E(a0)
        beq.s    +
        move.l    #-$2700,($FFFFF796).w
+
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#$10,a3
	move.w	#0,d6
	move.b	layer(a0),d5
	bsr.w	FindFloor
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	+
	move.b	#0,d3
+
	rts
; ===========================================================================

loc_1EDA8:
	move.w	x_pos(a1),d3
	move.w	y_pos(a1),d2
	moveq	#0,d0
	move.b	height_pixels(a1),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,layer(a1)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#$10,a3
	move.w	#0,d6
	move.b	layer(a1),d5
	bsr.w	FindFloor
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	return_1EDF8
	move.b	#0,d3

return_1EDF8:
	rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine checking if an object should interact with the floor
; (objects such as a monitor Sonic bumps from underneath)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EDFA: ObjHitFloor:
ObjCheckFloorDist:
	move.w	x_pos(a0),d3
	move.w	y_pos(a0),d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#$10,a3
	move.w	#0,d6
	moveq	#$C,d5
	bsr.w	FindFloor
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	+
	move.b	#0,d3
+
	rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Collision check used to let the HTZ boss fire attack to hit the ground
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EE30:
FireCheckFloorDist:
	move.w	x_pos(a1),d3
	move.w	y_pos(a1),d2
	move.b	height_pixels(a1),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#$10,a3
	move.w	#0,d6
	moveq	#$C,d5
	bra.w	FindFloor
; End of function FireCheckFloorDist

; ---------------------------------------------------------------------------
; Collision check used to let scattered rings bounce on the ground
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EE56:
RingCheckFloorDist:
	move.w	x_pos(a0),d3
	move.w	y_pos(a0),d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#$10,a3
	move.w	#0,d6
	moveq	#$C,d5
	bra.w	Obj_CheckInFloor
; End of function RingCheckFloorDist

; ---------------------------------------------------------------------------
; Stores a distance to the nearest wall above Sonic/Tails,
; where "above" = right, into d1
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EE7C:
CheckRightCeilingDist:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF768).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindWall
	move.w	d1,-(sp)
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF76A).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindWall
	move.w	(sp)+,d0
	move.b	#-$40,d2
	bra.w	loc_1ECC6
; End of function CheckRightCeilingDist

; ---------------------------------------------------------------------------
; Stores a distance to the nearest wall on the right of Sonic/Tails into d1
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_1EEDC:
CheckRightWallDist:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
; loc_1EEE4:
CheckRightWallDist_Part2:
	addi.w	#$A,d3
	lea	($FFFFF768).w,a4
	movea.w	#$10,a3
	move.w	#0,d6
	bsr.w	FindWall
	move.b	#-$40,d2
	bra.w	loc_1ECFE
; End of function CheckRightWallDist

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EF00:
ObjCheckLeftWallDist:
	add.w	x_pos(a0),d3
	move.w	y_pos(a0),d2
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#$10,a3
	move.w	#0,d6
	moveq	#$D,d5
	bsr.w	FindWall
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	+
	move.b	#-$40,d3
+
	rts
; End of function ObjCheckLeftWallDist

; ---------------------------------------------------------------------------
; Stores a distance from Sonic/Tails to the nearest ceiling into d1
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EF2E: Sonic_DontRunOnWalls:
CheckCeilingDist:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	eori.w	#$F,d2 ; flip position upside-down within the current 16x16 block?
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d3
	lea	($FFFFF768).w,a4
	movea.w	#-$10,a3
	move.w	#$800,d6
	bsr.w	FindFloor
	move.w	d1,-(sp)

	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	eori.w	#$F,d2
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d3
	lea	($FFFFF76A).w,a4
	movea.w	#-$10,a3
	move.w	#$800,d6
	bsr.w	FindFloor
	move.w	(sp)+,d0

	move.b	#$80,d2
	bra.w	loc_1ECC6
; End of function CheckCeilingDist

; ===========================================================================
	; a bit of unused/dead code here
	move.w	y_pos(a0),d2 ; a0=character
	move.w	x_pos(a0),d3

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; called when Sonic/Tails walks up a curving slope... I'm not sure what it does
; loc_1EF9E:
CheckSlopeDist:
        subi.w #$A,d2

loc_1EFA2:
        eori.w #$F,d2
        lea ($FFFFF768).w,a4
        movea.w #-$10,a3
        move.w #$800,d6
        bsr.w FindFloor
        move.b #-$80,d2
        bra.w loc_1ECFE
; End of function CheckSlopeDist

; ---------------------------------------------------------------------------
; Stores a distance to the nearest wall above the object into d1
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EFBE: ObjHitCeiling:
ObjCheckCeilingDist:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	eori.w	#$F,d2
	lea	($FFFFF768).w,a4
	movea.w	#-$10,a3
	move.w	#$800,d6
	moveq	#$D,d5
	bsr.w	FindFloor
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	+
	move.b	#$80,d3
+
	rts
; End of function ObjCheckCeilingDist

; ---------------------------------------------------------------------------
; Stores a distance to the nearest wall above Sonic/Tails,
; where "above" = left, into d1
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1EFF6:
CheckLeftCeilingDist:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d3
	eori.w	#$F,d3
	lea	($FFFFF768).w,a4
	movea.w	#-$10,a3
	move.w	#$400,d6
	bsr.w	FindWall
	move.w	d1,-(sp)

	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
	moveq	#0,d0
	move.b	width_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	add.w	d0,d2
	move.b	height_pixels(a0),d0
	lsr.b	#1,d0
	ext.w	d0
	sub.w	d0,d3
	eori.w	#$F,d3
	lea	($FFFFF76A).w,a4
	movea.w	#-$10,a3
	move.w	#$400,d6
	bsr.w	FindWall
	move.w	(sp)+,d0
	move.b	#$40,d2
	bra.w	loc_1ECC6
; End of function CheckLeftCeilingDist

; ---------------------------------------------------------------------------
; Stores a distance to the nearest wall on the left of Sonic/Tails into d1
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1F05E: Sonic_HitWall:
CheckLeftWallDist:
	move.w	y_pos(a0),d2
	move.w	x_pos(a0),d3
; loc_1F066:
CheckLeftWallDist_Part2:
        subi.w #$A,d3

loc_1F06A:
        eori.w #$F,d3
        lea ($FFFFF768).w,a4
        movea.w #-$10,a3
        move.w #$400,d6
        bsr.w FindWall
        move.b #$40,d2
        bra.w loc_1ECFE
; End of function CheckLeftWallDist

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1F086:
ObjCheckRightWallDist:
	add.w	x_pos(a0),d3
	move.w	y_pos(a0),d2
	lea	($FFFFF768).w,a4
	move.b	#0,(a4)
	movea.w	#-$10,a3
	move.w	#$400,d6
	moveq	#$D,d5
	bsr.w	FindWall
	move.b	($FFFFF768).w,d3
	btst	#0,d3
	beq.s	+
	move.b	#$40,d3
+
	rts

; ===========================================================================

; ---------------------------------------------------------------------------
; Object code
; ---------------------------------------------------------------------------

    if * > $10000
	fatal "At ROM position $\{*}; needed to be <= $10000"
    endif

	align $10000

ObjBase:
	rts		; value 0 in (a0).w, used to indicate no object
ObjData:
	rts		; value 1 in (a0).w, used to indicate additional data for the previous object

	include "code/objects/Object_Specific_Routines/object_loading.asm"
	even
	include "code/objects/Object_Specific_Routines/object_touch_response.asm"
	even	
	include "code/objects/Object_Specific_Routines/object_delete.asm"
	even	
	include "code/objects/Sonic.asm"
	even
	include "code/objects/Tails.asm"
	even
	include "code/objects/Knuckles.asm"
	even
	include "code/objects/Bubbles.asm"
	even
	include "code/objects/Shields.asm"
	even
	include "code/objects/Splash.asm"
	even
	include "code/objects/PathSwitch.asm"
	even
	include "code/objects/badniks/PitcherPlant.asm"
	even
	include "code/objects/WaterSurface.asm"
	even
	include "code/objects/Explosion.asm"
	even
	;include "code/objects/Continue.asm"
	include "code/objects/Ring.asm"
	even
	include "code/objects/Monitor.asm"
	even
	include "code/objects/Spikes.asm"
	even
	include "code/objects/Spring.asm"
	even
	include "code/objects/Signpost.asm"
	even
	include "code/objects/HUD.asm"
	even
	;include "code/objects/Boss.asm"


    if * > $20000
	fatal "At ROM position $\{*}; needed to be <= $20000"
    endif

	align $20000

; ===========================================================================
; ---------------------------------------------------------------------------
; Object animation scripts
; ---------------------------------------------------------------------------

Ani_objCD:	include "animations/Sprite/Object CD.asm"
		even
Ani_objCF:	include "animations/Sprite/Object CF.asm"
		even
Ani_objDB:	Include "animations/Sprite/Continue screen tails.asm"
		even
SonicAniData:	Include "animations/Sprite/Sonic.asm"
		even
SuperSonicAniData:	Include "animations/Sprite/Super Sonic.asm"
		even
TailsAniData:	Include "animations/Sprite/Tails.asm"
		even
AniKnux:	Include "animations/Sprite/Knuckles.asm"
		even
Ani_SignPost:	include "animations/Sprite/Signpost.asm"
		even
Ani_Ring:	Include "animations/Sprite/Ring.asm"
		even
Ani_Monitor:	Include "animations/Sprite/Monitor.asm"
		even
Ani_Spring:	Include "animations/Sprite/Spring.asm"
		even
Ani_Egg_Prison:	Include "animations/Sprite/Egg Prison.asm"
		even
Ani_Small_Bubbles:	Include "animations/Sprite/Bubbles.asm"
		even
Ani_Bubbles_Base:	Include "animations/Sprite/Bubbles Base.asm"
		even
Ani_CheckPoint:	Include "animations/Sprite/CheckPoint.asm"
		even
Ani_Water_Splash_Object:	Include "animations/Sprite/Spindash Dust And Water Splash.asm"
		even
Ani_Plain_Shield:	Include "animations/Sprite/Shield.asm"
		even
Pitcher_Plant_Badnik_Animate:	Include	"animations/Sprite/Pitcher Plant.asm"
		even
; ===========================================================================
; water sprite animation 'script' (custom format for this object)

Anim_Water_Surface:
	dc.b 0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dc.b 1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2
	dc.b 2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1
	dc.b 1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0

; ===========================================================================
; ---------------------------------------------------------------------------
; Object mappings
; ---------------------------------------------------------------------------

ObjCF_MapUnc_ADA2:	binclude "mappings/sprite/objCF.bin"
		even
ObjDA_MapUnc_7CB6:	binclude "mappings/sprite/objDA.bin"
		even
SignPost_MapUnc_195BE:	BINCLUDE "mappings/sprite/SignPost_a.bin"
		even
SignPost_MapUnc_19656:	BINCLUDE "mappings/sprite/SignPost_b.bin"
		even
SignPost_MapUnc_196EE:	BINCLUDE "mappings/sprite/SignPost_c.bin"
		even
Obj11_Maps:	INCLUDE	"mappings/sprite/orbsmaps.asm"
		even
Explosion_MapUnc_21120:	BINCLUDE "mappings/sprite/Explosion.bin"
		even
Animal_From_Badnik_MapUnc_11E1C:	BINCLUDE "mappings/sprite/Animal_From_Badnik_a.bin"
		even
Animal_From_Badnik_MapUnc_11E40:	BINCLUDE "mappings/sprite/Animal_From_Badnik_b.bin"
		even
Animal_From_Badnik_MapUnc_11E64:	BINCLUDE "mappings/sprite/Animal_From_Badnik_c.bin"
		even
Animal_From_Badnik_MapUnc_11E88:	BINCLUDE "mappings/sprite/Animal_From_Badnik_d.bin"
		even
Animal_From_Badnik_MapUnc_11EAC:	BINCLUDE "mappings/sprite/Animal_From_Badnik_e.bin"
		even
Points_Text_MapUnc_11ED0:	BINCLUDE "mappings/sprite/Points_Text.bin"
		even
Basic_Ring_MapUnc_12382:	BINCLUDE "mappings/sprite/Hurt_Rings_a.bin"
		even
Monitor_MapUnc_12D36:	BINCLUDE "mappings/sprite/Monitor.bin"
		even
Spikes_MapUnc_15B68:	BINCLUDE "mappings/sprite/Spikes.bin"
		even
Spring_MapUnc_1901C:	Include "mappings/sprite/Spring 1.asm"
		even
Spring_MapUnc_19032:	Include "mappings/sprite/Spring 2.asm"
		even
Egg_Prison_MapUnc_3F436:	BINCLUDE "mappings/sprite/Egg_Prison.bin"
		even
Obj58_MapUnc_2D50A:	BINCLUDE "mappings/sprite/obj58.bin"
		even
Bubbles_Base_MapUnc_1FC18:	Include "mappings/sprite/Bubbles Base Bubbles 2.asm"
		even
CheckPoint_MapUnc_1F424:	BINCLUDE "mappings/sprite/CheckPoint_a.bin"
		even
CheckPoint_MapUnc_1F4A0:	BINCLUDE "mappings/sprite/CheckPoint_b.bin"
		even
Path_Swapper_MapUnc_1FFB8:	BINCLUDE "mappings/sprite/Path_Swapper.bin"
		even
Water_Surface_MapUnc_20A0E:	BINCLUDE "mappings/sprite/Water_Surface_a.bin"
		even
Water_Surface_MapUnc_20AFE:	BINCLUDE "mappings/sprite/Water_Surface_b.bin"
		even
Water_Splash_Object_MapUnc_1DF5E:	BINCLUDE "mappings/sprite/Water_Splash.bin"
		even
Plain_Shield_MapUnc_1DBE4:	BINCLUDE "mappings/sprite/Plain_Shield.bin"
		even
Invincibility_Stars_MapUnc_1DCBC:	BINCLUDE "mappings/sprite/Invincibility_Stars.bin"
		even
map_ppbadnik:		INCLUDE	"mappings/sprite/plantbadmaps.asm"
		even
SS_Stars_MapUnc_1E1BE:	BINCLUDE "mappings/sprite/SS_Stars.bin"
		even

; ===========================================================================
; ---------------------------------------------------------------------------
; Object DPLCs
; ---------------------------------------------------------------------------

Water_Splash_Object_MapRUnc_1E074:	BINCLUDE "mappings/spriteDPLC/Water_Splash.bin"
		even

GiantBirdMaps:	INCLUDE	"mappings/sprite/birdmaps.asm"
Artnem_GiantBird:	BINCLUDE	"art/nemesis/birdart.bin"
	even

; ===========================================================================

JmpTo5_DisplaySprite3
	jmp	(DisplaySprite3).l
; ===========================================================================

JmpTo45_DisplaySprite
	jmp	(DisplaySprite).l
; ===========================================================================

JmpTo65_DeleteObject
	jmp	(DeleteObject).l
; ===========================================================================

JmpTo19_SingleObjLoad
	jmp	(SingleObjLoad).l
; ===========================================================================

JmpTo39_MarkObjGone
	jmp	(MarkObjGone).l
; ===========================================================================

JmpTo6_DeleteObject2
	jmp	(DeleteObject2).l
; ===========================================================================

JmpTo12_PlaySound
	jmp	(PlaySound).l
; ===========================================================================

JmpTo25_SingleObjLoad2
	jmp	(SingleObjLoad2).l
; ===========================================================================

JmpTo25_AnimateSprite
	jmp	(AnimateSprite).l
; ===========================================================================

JmpTo_PlaySoundLocal
	jmp	(PlaySoundLocal).l
; ===========================================================================

JmpTo6_RandomNumber
	jmp	(RandomNumber).l
; ===========================================================================

JmpTo2_MarkObjGone_P1
	jmp	(MarkObjGone_P1).l
; ===========================================================================

JmpTo_Pal_AddColor2
	jmp	(Pal_AddColor2).l
; ===========================================================================

JmpTo_LoadTailsDynPLC_Part2
	jmp	(LoadTailsDynPLC_Part2).l
; ===========================================================================

JmpTo_LoadSonicDynPLC_Part2
	jmp	(LoadSonicDynPLC_Part2).l
; ===========================================================================

JmpTo8_MarkObjGone3
	jmp	(MarkObjGone3).l
; ===========================================================================

JmpTo5_PlayMusic
	jmp	(PlayMusic).l
; ===========================================================================

JmpTo9_PlatformObject
	jmp	(PlatformObject).l
; ===========================================================================

JmpTo27_SolidObject
	jmp	(SolidObject).l
; ===========================================================================

JmpTo8_ObjectMoveAndFall
	jmp	(ObjectMoveAndFall).l
; ===========================================================================
; loc_3EAC0:
JmpTo26_ObjectMove
	jmp	(ObjectMove).l
; ===========================================================================
	align 4
return_37A48:
	rts
loc_3AF60:
	move.b	#8,objoff_37(a0)
	moveq	#0,d0
	move.b	objoff_36(a0),d0
	moveq	#$18,d1
	cmpi.w	#2,(Player_mode).w
	bne.s	loc_3AF78
	moveq	#4,d1

loc_3AF78:
	addq.b	#1,d0
	cmp.w	d1,d0
	blo.s	loc_3AF80
	moveq	#0,d0

loc_3AF80:
	move.b	d0,objoff_36(a0)
	cmpi.w	#2,(Player_mode).w
	bne.s	loc_3AF94
	move.b	byte_3AF9C(pc,d0.w),d0
	bra.w	JmpTo_LoadSonicDynPLC_Part2
; ===========================================================================

loc_3AF94:
	move.b	byte_3AFA0(pc,d0.w),d0
	bra.w	JmpTo_LoadTailsDynPLC_Part2
; ===========================================================================
byte_3AF9C:
	dc.b $2D
	dc.b $2E	; 1
	dc.b $2F	; 2
	dc.b $30	; 3
byte_3AFA0:
	dc.b $10
	dc.b $10	; 1
	dc.b $10	; 2
	dc.b $10	; 3
	dc.b   1	; 4
	dc.b   2	; 5
	dc.b   3	; 6
	dc.b   2	; 7
	dc.b   1	; 8
	dc.b   1	; 9
	dc.b $10	; 10
	dc.b $10	; 11
	dc.b $10	; 12
	dc.b $10	; 13
	dc.b   1	; 14
	dc.b   2	; 15
	dc.b   3	; 16
	dc.b   2	; 17
	dc.b   1	; 18
	dc.b   1	; 19
	dc.b   4	; 20
	dc.b   4	; 21
	dc.b   1	; 22
	dc.b   1	; 23
word_3AFB8:
	dc.w $3E
	dc.b 0;ObjID_Tornado
	dc.b $58
word_3AFBC:
	dc.w $3C
	dc.b 0;ObjID_Tornado
	dc.b $56
word_3AFC0:
	dc.w $3A
	dc.b 0;ObjID_Tornado
	dc.b $5C
	dc.w $3E
	dc.b 0;ObjID_Tornado
	dc.b $5A
; off_3AFC8:
ObjB2_SubObjData:
	dc.l ObjB2_MapUnc_3AFF2
	dc.w $8500
	dc.w $404
	dc.w $6000
; off_3AFD2:
ObjB2_SubObjData2:
	dc.l ObjB2_MapUnc_3B292
	dc.w $561
	dc.w $403
	dc.w $4000
; -----------------------------------------------------------------------------
; sprite mappings
; -----------------------------------------------------------------------------
ObjB2_MapUnc_3AFF2:	BINCLUDE "mappings/sprite/objB2_a.bin"
; -----------------------------------------------------------------------------
; sprite mappings
; -----------------------------------------------------------------------------
ObjB2_MapUnc_3B292:	BINCLUDE "mappings/sprite/objB2_b.bin"
; ----------------------------------------------------------------------------
; Object 8A - Blank
; ----------------------------------------------------------------------------
Obj8A:
	rts
	align 4






; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


JmpTo_DrawSprite_Loop
	jmp	(DrawSprite_Loop).l
; End of function JmpTo_DrawSprite_Loop




; ===========================================================================
; ---------------------------------------------------------------------------
; When debug mode is currently in use
; ---------------------------------------------------------------------------
; loc_41A78:
DebugMode:
	moveq	#0,d0
	move.b	(Debug_placement_mode).w,d0
	move.w	Debug_Index(pc,d0.w),d1
	jmp	Debug_Index(pc,d1.w)
; ===========================================================================
; off_41A86:
Debug_Index:
	dc.w Debug_Main - Debug_Index
	dc.w loc_41B0C - Debug_Index; 1
; ===========================================================================
; loc_41A8A:
Debug_Main:
	addq.b	#2,(Debug_placement_mode).w
	move.w	(Camera_Min_Y_pos).w,($FFFFFFCC).w
	move.w	(Camera_Max_Y_pos).w,($FFFFFFCE).w
	cmpi.b	#sky_chase_zone,(Current_Zone).w
	bne.s	loc_41AAE
	move.w	#0,(Camera_Min_X_pos).w
	move.w	#$3FFF,(Camera_Max_X_pos).w

loc_41AAE:
	andi.w	#$7FF,(MainCharacter+y_pos).w
	andi.w	#$7FF,(Camera_Y_pos).w
	andi.w	#$7FF,(Camera_BG_Y_pos).w
	clr.b	(Scroll_lock).w
	move.b	#0,mapping_frame(a0)
	move.b	#0,anim(a0)
;	cmpi.b	#GameModeID_SpecialStage,(Game_Mode).w ; special stage mode?
;	bne.s	loc_41ADC		; if not, branch
	;moveq	#6,d0
;	bra.s	loc_41AE2
; ===========================================================================

loc_41ADC:
	moveq	#0,d0
	move.b	(Current_Zone).w,d0

loc_41AE2:
	lea	(JmpTbl_DbgObjLists).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d6
	cmp.b	(Debug_object).w,d6
	bhi.s	loc_41AFC
	move.b	#0,(Debug_object).w

loc_41AFC:
	bsr.w	sub_41CEC
	move.b	#$C,($FFFFFE0A).w
	move.b	#1,($FFFFFE0B).w

loc_41B0C:
	moveq	#6,d0
;	cmpi.b	#GameModeID_SpecialStage,(Game_Mode).w	; special stage mode?
;	beq.s	loc_41B1C		; if yes, branch
	moveq	#0,d0
	move.b	(Current_Zone).w,d0

loc_41B1C:
	lea	(JmpTbl_DbgObjLists).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d6
	bsr.w	sub_41B34
	jmp	(DisplaySprite).l

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_41B34:
	moveq	#0,d4
	move.w	#1,d1
	move.b	(Ctrl_1_Press).w,d4
	andi.w	#button_up_mask|button_down_mask|button_left_mask|button_right_mask,d4
	bne.s	loc_41B76
	move.b	(Ctrl_1_Held).w,d0
	andi.w	#button_up_mask|button_down_mask|button_left_mask|button_right_mask,d0
	bne.s	loc_41B5E
	move.b	#$C,($FFFFFE0A).w
	move.b	#$F,($FFFFFE0B).w
	bra.w	loc_41BDA
; ===========================================================================

loc_41B5E:
	subq.b	#1,($FFFFFE0A).w
	bne.s	loc_41B7A
	move.b	#1,($FFFFFE0A).w
	addq.b	#1,($FFFFFE0B).w
	bne.s	loc_41B76
	move.b	#-1,($FFFFFE0B).w

loc_41B76:
	move.b	(Ctrl_1_Held).w,d4

loc_41B7A:
	moveq	#0,d1
	move.b	($FFFFFE0B).w,d1
	addq.w	#1,d1
	swap	d1
	asr.l	#4,d1
	move.l	y_pos(a0),d2
	move.l	x_pos(a0),d3
	btst	#button_up,d4
	beq.s	loc_41BA4
	sub.l	d1,d2
	moveq	#0,d0
	move.w	(Camera_Min_Y_pos).w,d0
	swap	d0
	cmp.l	d0,d2
	bge.s	loc_41BA4
	move.l	d0,d2

loc_41BA4:
	btst	#button_down,d4
	beq.s	loc_41BBE
	add.l	d1,d2
	moveq	#0,d0
	move.w	(Camera_Max_Y_pos).w,d0
	addi.w	#$DF,d0
	swap	d0
	cmp.l	d0,d2
	blt.s	loc_41BBE
	move.l	d0,d2

loc_41BBE:
	btst	#button_left,d4
	beq.s	loc_41BCA
	sub.l	d1,d3
	bcc.s	loc_41BCA
	moveq	#0,d3

loc_41BCA:
	btst	#button_right,d4
	beq.s	loc_41BD2
	add.l	d1,d3

loc_41BD2:
	move.l	d2,y_pos(a0)
	move.l	d3,x_pos(a0)

loc_41BDA:
	btst	#button_A,(Ctrl_1_Held).w
	beq.s	loc_41C12
	btst	#button_C,(Ctrl_1_Press).w
	beq.s	loc_41BF6
	subq.b	#1,(Debug_object).w
	bcc.s	BranchTo_sub_41CEC
	add.b	d6,(Debug_object).w
	bra.s	BranchTo_sub_41CEC
; ===========================================================================

loc_41BF6:
	btst	#button_A,(Ctrl_1_Press).w
	beq.s	loc_41C12
	addq.b	#1,(Debug_object).w
	cmp.b	(Debug_object).w,d6
	bhi.s	BranchTo_sub_41CEC
	move.b	#0,(Debug_object).w

BranchTo_sub_41CEC
	bra.w	sub_41CEC
; ===========================================================================

loc_41C12:
	btst	#button_C,(Ctrl_1_Press).w
	beq.s	loc_41C56
	jsr	(SingleObjLoad).l
	bne.s	loc_41C56
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	mappings(a0),id(a1) ; load obj
	move.b	render_flags(a0),render_flags(a1)
	move.b	render_flags(a0),status(a1)
	andi.b	#$7F,status(a1)
	moveq	#0,d0
	move.b	(Debug_object).w,d0
	lsl.w	#3,d0
	move.b	4(a2,d0.w),subtype(a1)
	rts
; ===========================================================================

loc_41C56:
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	return_41CB6
	moveq	#0,d0
	move.w	d0,(Debug_placement_mode).w
	lea	(MainCharacter).w,a1 ; a1=character
	move.w	#$780,art_tile(a1)	
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	add.w	d0,d0
	move.l	Character_Mapping_Options(pc,d0.w),mappings(a1)	
	;move.l	#Mapunc_Sonic,mappings(a1)
	;cmp.w	#3,(Player_mode).w
	;bne.s	+
	;move.l	#SK_Map_Knuckles,mappings(a1)
;+
;	cmp.w	#2,(Player_mode).w
;	bne.s	loc_41C82
;	move.w	#$7A0,art_tile(a1)
;	move.l	#MapUnc_Tails,mappings(a1)

loc_41C82:
	bsr.s	sub_41CB8
	move.b	#$26,height_pixels(a1)
	move.b	#18,width_pixels(a1)
	move.w	($FFFFFFCC).w,(Camera_Min_Y_pos).w
	move.w	($FFFFFFCE).w,(Camera_Max_Y_pos).w

return_41CB6:
	rts
	
Character_Mapping_Options:
		dc.l	Mapunc_Sonic
		dc.l	Mapunc_Sonic
		dc.l	MapUnc_Tails
		dc.l	SK_Map_Knuckles
; End of function sub_41B34


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_41CB8:
	move.b	d0,anim(a1)
	move.w	d0,2+x_pos(a1) ; subpixel x
	move.w	d0,2+y_pos(a1) ; subpixel y
	andi.b	#lock_del,status3(a1)
	bclr	#s3b_spindash,status3(a1)
	move.w	d0,x_vel(a1)
	move.w	d0,y_vel(a1)
	move.w	d0,inertia(a1)
	move.b	#2,status(a1)
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	move.w	Undo_Debug_Character_Options(pc,d0.w),(a1)
	rts
; End of function sub_41CB8

Undo_Debug_Character_Options:
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Tails_Control)
		dc.w	objroutine(Knuckles_Control)
; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_41CEC:
	moveq	#0,d0
	move.b	(Debug_object).w,d0
	lsl.w	#3,d0
	move.l	(a2,d0.w),mappings(a0)
	move.w	6(a2,d0.w),art_tile(a0)
	move.b	5(a2,d0.w),mapping_frame(a0)
	rts
; End of function sub_41CEC

; ===========================================================================
	align 4
	include "code/Levels/Debug Object List.asm"

; ---------------------------------------------------------------------------
; "MAIN LEVEL LOAD BLOCK" (after Nemesis)
;
; This struct array tells the engine where to find all the art associated with
; a particular zone. Each zone gets three longwords, in which it stores three
; pointers (in the lower 24 bits) and three jump table indeces (in the upper eight
; bits). The assembled data looks something like this:
;
; aaBBBBBB
; ccDDDDDD
; eeFFFFFF
;
; aa = index for primary pattern load request list
; BBBBBB = pointer to level art
; cc = index for secondary pattern load request list
; DDDDDD = pointer to 16x16 block mappings
; ee = index for palette
; FFFFFF = pointer to 128x128 block mappings
;
; Nemesis refers to this as the "main level load block". However, that name implies
; that this is code (obviously, it isn't), or at least that it points to the level's
; collision, object and ring placement arrays (it only points to art...
; although the 128x128 mappings do affect the actual level layout and collision)
; ---------------------------------------------------------------------------

; declare some global variables to be used by the levartptrs macro
cur_zone_id := 0
cur_zone_str := "0"

; macro for declaring a "main level load block" (MLLB)
levartptrs macro plc1,plc2,palette,art,map16x16,map128x128
	!org LevelArtPointers+zone_id_{cur_zone_str}*12
	dc.l (plc1<<24)|art
	dc.l (plc2<<24)|map16x16
	dc.l (palette<<24)|map128x128
cur_zone_id := cur_zone_id+1
cur_zone_str := "\{cur_zone_id}"
    endm

; BEGIN SArt_Ptrs Art_Ptrs_Array[17]
; dword_42594: MainLoadBlocks: saArtPtrs:
	Include	"code/Levels/Level Art Pointers.asm"
	even
;LevelArtPointers:

    if (cur_zone_id<>no_of_zones)&&(MOMPASS=1)
	message "Warning: Table LevelArtPointers has \{cur_zone_id/1.0} entries, but it should have \{no_of_zones/1.0} entries"
    endif
	!org LevelArtPointers+cur_zone_id*12

; ---------------------------------------------------------------------------
; END Art_Ptrs_Array[17]
;ArtLoadCues:
	Include	"code/Levels/PLC List.asm"

; macro for a pattern load request list header
; must be on the same line as a label that has a corresponding _End label later


knuxlifeicon:	binclude	"art/nemesis/knuxlife.bin"
Knuxeoatext:	binclude	"art/nemesis/knuxtext.bin"

;---------------------------------------------------------------------------------------
; Curve and resistance mapping
;---------------------------------------------------------------------------------------
ColCurveMap:	BINCLUDE	"collision/Curve and resistance mapping.bin"
;--------------------------------------------------------------------------------------
; Collision arrays
;--------------------------------------------------------------------------------------
ColArray:	BINCLUDE	"collision/Collision array 1.bin"
ColArray2:	BINCLUDE	"collision/Collision array 2.bin"

ArtNem_MetallicSphere:	BINCLUDE	"art/nemesis/orbsart.bin"


;---------------------------------------------------------------------------------------
; Level Data, seperated to make adding levels easier
;---------------------------------------------------------------------------------------
;Off_Level: 
	Include	"code/Levels/Layout List.asm"
	even
; ======================================================================================
;Off_TitleCardLetters:	Include	"code/Levels/Title Card List.asm"
;TitleCardLetters - In Title Card List.asm	
; ======================================================================================
;Off_Rings:
	Include	"code/Levels/Ring Layout List.asm"
	even
; ======================================================================================
;Off_Objects:
	Include	"code/Levels/Object Layout List.asm"
	even
; ======================================================================================
;---------------------------------------------------------------------------------------
; Uncompressed art
; Patterns for Sonic  ; ArtUnc_50000:
;---------------------------------------------------------------------------------------
	align $20
ArtUnc_Sonic:	BINCLUDE	"art/uncompressed/Sonic's art.bin"
;---------------------------------------------------------------------------------------
; Uncompressed art
; Patterns for Tails  ; ArtUnc_64320:
;---------------------------------------------------------------------------------------
	align $20
ArtUnc_Tails:	BINCLUDE	"art/uncompressed/Tails's art.bin"
;--------------------------------------------------------------------------------------
; Sprite Mappings
; Sonic			; MapUnc_6FBE0: SprTbl_Sonic:
;--------------------------------------------------------------------------------------
Mapunc_Sonic:	BINCLUDE	"mappings/sprite/Sonic.bin"
;--------------------------------------------------------------------------------------
; Sprite Dynamic Pattern Reloading
; Sonic DPLCs   		; MapRUnc_714E0:
;--------------------------------------------------------------------------------------
; WARNING: the build script needs editing if you rename this label
;          or if you move Sonic's running frame to somewhere else than frame $2D
MapRUnc_Sonic:	BINCLUDE	"mappings/spriteDPLC/Sonic.bin"
;--------------------------------------------------------------------------------------
; Nemesis compressed art (32 blocks)
; Shield			; ArtNem_71D8E:
ArtNem_Shield:	BINCLUDE	"art/nemesis/Shield.bin"
;--------------------------------------------------------------------------------------
; Nemesis compressed art (34 blocks)
; Invincibility stars		; ArtNem_71F14:
ArtUnc_InvStars:	BINCLUDE	"art/uncompressed/invstars.bin"
;--------------------------------------------------------------------------------------
; Uncompressed art
; Splash in water		; ArtUnc_71FFC:
ArtUnc_Splash:	BINCLUDE	"art/uncompressed/Splash.bin"
;--------------------------------------------------------------------------------------
; Uncompressed art
; Smoke from dashing		; ArtUnc_7287C:
ArtUnc_Dust:	BINCLUDE	"art/uncompressed/Spindash smoke.bin"
;--------------------------------------------------------------------------------------
; Nemesis compressed art (14 blocks)
; Supersonic stars		; ArtNem_7393C:
ArtNem_SuperSonic_stars:	BINCLUDE	"art/nemesis/Super Sonic stars.bin"
;--------------------------------------------------------------------------------------
; Sprite Mappings
; Tails			; MapUnc_739E2:
;--------------------------------------------------------------------------------------
MapUnc_Tails:	BINCLUDE	"mappings/sprite/Tails.bin"
;--------------------------------------------------------------------------------------
; Sprite Dynamic Pattern Reloading
; Tails DPLCs	; MapRUnc_7446C:
;--------------------------------------------------------------------------------------
MapRUnc_Tails:	BINCLUDE	"mappings/spriteDPLC/Tails.bin"
;-------------------------------------------------------------------------------------
; Nemesis compressed art (127 blocks)
; "SEGA" Patterns	; ArtNem_74876:
ArtNem_SEGA:	BINCLUDE	"art/nemesis/SEGA.bin"
;-------------------------------------------------------------------------------------
; Nemesis compressed art (9 blocks)
; Shaded blocks from intro	; ArtNem_74CF6:
ArtNem_IntroTrails:	BINCLUDE	"art/nemesis/Shaded blocks from intro.bin"
;---------------------------------------------------------------------------------------
; Enigma compressed art mappings
; "SEGA" mappings		; MapEng_74D0E:
MapEng_SEGA:	BINCLUDE	"mappings/misc/SEGA mappings.bin"
;---------------------------------------------------------------------------------------
; Enigma compressed art mappings
; Mappings for title screen background	; ArtNem_74DC6:
MapEng_TitleScreen:	BINCLUDE	"mappings/misc/Mappings for title screen background.bin"
;--------------------------------------------------------------------------------------
; Enigma compressed art mappings
; Mappings for title screen background (smaller part, water/horizon)	; MapEng_74E3A:
MapEng_TitleBack:	BINCLUDE	"mappings/misc/Mappings for title screen background 2.bin"
;---------------------------------------------------------------------------------------
; Enigma compressed art mappings
; "Sonic the Hedgehog 2" title screen logo mappings	; MapEng_74E86:
MapEng_TitleLogo:	BINCLUDE	"mappings/misc/Sonic the Hedgehog 2 title screen logo mappings.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (336 blocks)
; Main patterns from title screen	; ArtNem_74F6C:
	even
MapEng_Title:	BINCLUDE	"art/nemesis/Main patterns from title screen.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (674 blocks)
; Sonic and tails from title screen	; ArtNem_7667A:
	even
MapEng_TitleSprites:	BINCLUDE	"art/nemesis/Sonic and Tails from title screen.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (10 blocks)
; A few menu patterns	; ArtNem_78CBC:
	even
ArtNem_MenuJunk:	BINCLUDE	"art/nemesis/A few menu blocks.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (16 blocks)
; Button			ArtNem_78DAC:
	even
ArtNem_Button:	BINCLUDE	"art/nemesis/Button.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (20 blocks)
; Vertical Spring		ArtNem_78E84:
	even
ArtNem_VrtclSprng:	BINCLUDE	"art/nemesis/Vertical spring.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (12 blocks)
; Horizontal spring		ArtNem_78FA0:
	even
ArtNem_HrzntlSprng:	BINCLUDE	"art/nemesis/Horizontal spring.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (32 blocks)
; Diagonal spring		ArtNem_7906A:
	even
ArtNem_DignlSprng:	BINCLUDE	"art/nemesis/Diagonal spring.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (24 blocks)
; Score, Rings, Time patterns	ArtNem_7923E:
	even
ArtNem_HUD:	BINCLUDE	"art/nemesis/HUD.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (12 blocks)
; Sonic lives counter		ArtNem_79346:
	even
ArtNem_Sonic_life_counter:	BINCLUDE	"art/nemesis/Sonic lives counter.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (14 blocks)
; Ring				ArtNem_7945C:
	even
ArtNem_Ring:	BINCLUDE	"art/nemesis/Ring.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (60 blocks)
; Monitors and contents		ArtNem_79550:
	even
ArtNem_Powerups:	BINCLUDE	"art/nemesis/Monitor and contents.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (8 blocks)
; Spikes			7995C:
	even
ArtNem_Spikes:	BINCLUDE	"art/nemesis/Spikes.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (18 blocks)
; Numbers			799AC:
	even
ArtNem_Numbers:	BINCLUDE	"art/nemesis/Numbers.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (16 blocks)
; CheckPoint			79A86:
	even
ArtNem_Checkpoint:	BINCLUDE	"art/nemesis/CheckPoint.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (78 blocks)
; Signpost		; ArtNem_79BDE:
	even
ArtNem_Signpost:	BINCLUDE	"art/nemesis/Signpost.bin"
;---------------------------------------------------------------------------------------
; Uncompressed art
; Signpost		; ArtUnc_7A18A:
; Yep, it's in the rom twice, once compressed and once uncompressed
	even
ArtUnc_Signpost:	BINCLUDE	"art/uncompressed/Signpost.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (8 blocks)
; Long horizontal spike		; ArtNem_7AC9A:
	even
ArtNem_HorizSpike:	BINCLUDE	"art/nemesis/Long horizontal spike.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (24 blocks)
; Bubble thing from underwater	; ArtNem_7AD16:
	even
ArtNem_BigBubbles:	BINCLUDE	"art/nemesis/Bubble generator.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (10 blocks)
; Bubbles from character	7AEE2:
	even
ArtNem_Bubbles:	BINCLUDE	"art/nemesis/Bubbles.bin"
;---------------------------------------------------------------------------------------
; Uncompressed art
; Countdown text for drowning	; ArtUnc_7AF80:
	even
ArtUnc_Countdown:	BINCLUDE	"art/uncompressed/Numbers for drowning countdown.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (34 blocks)
; Game/Time over text		7B400:
	even
ArtNem_Game_Over:	BINCLUDE	"art/nemesis/Game and Time Over text.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (68 blocks)
; Explosion			7B592:
	even
ArtNem_Explosion:	BINCLUDE	"art/nemesis/Explosion.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (12 blocks)
; Miles life counter	; ArtNem_7B946:
	even
ArtUnc_MilesLife:	BINCLUDE	"art/nemesis/Miles life counter.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (49 blocks)
; Egg prison		; ArtNem_7BA32:
	even
ArtNem_Capsule:	BINCLUDE	"art/nemesis/Egg Prison.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (36 blocks)
; Tails on the continue screen (nagging Sonic)	; ArtNem_7BDBE:
	even
ArtNem_ContinueTails:	BINCLUDE	"art/nemesis/Tails on continue screen.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (12 blocks)
; Sonic extra continue icon	; ArtNem_7C0AA:
	even
ArtNem_MiniSonic:	BINCLUDE	"art/nemesis/Sonic continue.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (12 blocks)
; Tails life counter		; ArtNem_7C20C:
	even
ArtNem_TailsLife:	BINCLUDE	"art/nemesis/Tails life counter.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (12 blocks)
; Tails extra continue icon	; ArtNem_7C2F2:
	even
ArtNem_MiniTails:	BINCLUDE	"art/nemesis/Tails continue.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (88 blocks)
; Standard font		; ArtNem_7C43A:
	even
ArtNem_FontStuff:	BINCLUDE	"art/nemesis/Standard font.bin"
;---------------------------------------------------------------------------------------
; Enigma compressed art mappings
; Sonic/Miles animated background mappings	; MapEng_7CB80:
MapEng_MenuBack:	BINCLUDE	"mappings/misc/Sonic and Miles animated background.bin"
;---------------------------------------------------------------------------------------
; Uncompressed art
; Sonic/Miles animated background patterns	; ArtUnc_7CD2C:
	even
ArtUnc_MenuBack:	BINCLUDE	"art/uncompressed/Sonic and Miles animated background.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (94 blocks)
; Title card patterns		; ArtNem_7D22C:
	even
ArtNem_TitleCard:	BINCLUDE	"art/nemesis/Title card.bin"
;--------------------------------------------------------------------------------------
; Nemesis compressed art (92 blocks)
; Alphabet for font using large broken letters	; ArtNem_7D58A:
	even
ArtNem_TitleCard2:	BINCLUDE	"art/nemesis/Font using large broken letters.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (21 blocks)
; A menu box with a shadow	; ArtNem_7D990:
	even
ArtNem_MenuBox:	BINCLUDE	"art/nemesis/A menu box with a shadow.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (170 blocks)
; Pictures in level preview box in level select		; ArtNem_7DA10:
	even
ArtNem_LevelSelectPics:	BINCLUDE	"art/nemesis/Pictures in level preview box from level select.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (68 blocks)
; Text for Sonic or Tails Got Through Act and Bonus/Perfect	; ArtNem_7E86A:
	even
ArtNem_ResultsText:	BINCLUDE	"art/nemesis/End of level results text.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (14 blocks)
; "Perfect" text	; ArtNem_7EEBE:
	even
ArtNem_Perfect:	BINCLUDE	"art/nemesis/Perfect text.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (16 blocks)
; Flicky		; ArtNem_7EF60:
	even
ArtNem_Bird:	BINCLUDE	"art/nemesis/Flicky.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (20 blocks)
; Squirrel		; ArtNem_7F0A2:
	even
ArtNem_Squirrel:	BINCLUDE	"art/nemesis/Squirrel.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (16 blocks)
; Mouse			; ArtNem_7F206:
	even
ArtNem_Mouse:	BINCLUDE	"art/nemesis/Mouse.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (16 blocks)
; Chicken		; ArtNem_7F340:
	even
ArtNem_Chicken:	BINCLUDE	"art/nemesis/Chicken.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (20 blocks)
; Beaver		; ArtNem_7F4A2:
	even
ArtNem_Beaver:	BINCLUDE	"art/nemesis/Beaver.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (16 blocks)
; Some bird		; ArtNem_7F5E2:
	even
ArtNem_Eagle:	BINCLUDE	"art/nemesis/Penguin.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (10 blocks)
; Pig			; ArtNem_7F710:
	even
ArtNem_Pig:	BINCLUDE	"art/nemesis/Pig.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (14 blocks)
; Seal			; ArtNem_7F846:
	even
ArtNem_Seal:	BINCLUDE	"art/nemesis/Seal.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (18 blocks)
; Penguin		; ArtNem_7F962:
	even
ArtNem_Penguin:	BINCLUDE	"art/nemesis/Penguin 2.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (20 blocks)
; Turtle		; ArtNem_7FADE:
	even
ArtNem_Turtle:	BINCLUDE	"art/nemesis/Turtle.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (20 blocks)
; Bear			; ArtNem_7FC90:
	even
ArtNem_Bear:	BINCLUDE	"art/nemesis/Bear.bin"
;---------------------------------------------------------------------------------------
; Nemesis compressed art (18 blocks)
; Splats		; ArtNem_7FDD2:
	even
ArtNem_Rabbit:	BINCLUDE	"art/nemesis/Rabbit.bin"
;--------------------------------------------------------------------------------------
; Nemesis compressed art (24 blocks)
; Top of water in HPZ and CPZ	; ArtNem_82364:
	even
ArtNem_WaterSurface:	BINCLUDE	"art/nemesis/Top of water in HPZ and CNZ.bin"
;--------------------------------------------------------------------------------------
; Nemesis compressed art
; Pitcher Plant		; ArtNem_8316A:
	even
ArtNem_PitcherPlant:	BINCLUDE	"art/nemesis/plantbadnikart.bin"
;--------------------------------------------------------------------------------------
; Nemesis compressed art (100 blocks)
; Large explosion		; ArtNem_84890:
	even
ArtNem_FieryExplosion:	BINCLUDE	"art/nemesis/Large explosion.bin"
;--------------------------------------------------------------------------------------
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; LEVEL ART AND BLOCK MAPPINGS (16x16 and 128x128)
;
; #define BLOCK_TBL_LEN  // table length unknown
; #define BIGBLOCK_TBL_LEN // table length unknown
; typedef uint16_t uword
;
; struct blockMapElement {
;  uword unk : 5;    // u
;  uword patternIndex : 11; };  // i
; // uuuu uiii iiii iiii
;
; blockMapElement (*blockMapTable)[BLOCK_TBL_LEN][4] = 0xFFFF9000
;
; struct bigBlockMapElement {
;  uword : 4
;  uword blockMapIndex : 12; };  //I
; // 0000 IIII IIII IIII
;
; bigBlockMapElement (*bigBlockMapTable)[BIGBLOCK_TBL_LEN][64] = 0xFFFF0000
;
; /*
; This data determines how the level blocks will be constructed graphically. There are
; two kinds of block mappings: 16x16 and 128x128.
;
; 16x16 blocks are made up of four cells arranged in a square (thus, 16x16 pixels).
; Two bytes are used to define each cell, so the block is 8 bytes long. It can be
; represented by the bitmap blockMapElement, of which the members are:
;
; unk
;  These bits have to do with pattern orientation. I do not know their exact
;  meaning.
; patternIndex
;  The pattern's address divided by $20. Otherwise said: an index into the
;  pattern array.
;
; Each mapping can be expressed as an array of four blockMapElements, while the
; whole table is expressed as a two-dimensional array of blockMapElements (blockMapTable).
; The maps are read in left-to-right, top-to-bottom order.
;
; 128x128 maps are basically lists of indices into blockMapTable. The levels are built
; out of these "big blocks", rather than the "small" 16x16 blocks. bigBlockMapTable is,
; predictably, the table of big block mappings.
; Each big block is 8 16x16 blocks, or 16 cells, square. This produces a total of 16
; blocks or 64 cells.
; As noted earlier, each element of the table provides 'i' for blockMapTable[i][j].
; */
	align 4
	Include	"code/Levels/Tile List.asm"
	even
	Include	"code/Levels/Block List.asm"
	even
	Include	"code/Levels/Chunk List.asm"	
	even
; ---------------------------------------------------------------------------
; Sonic 1 Sound Driver
; ---------------------------------------------------------------------------
		align $10
Go_SoundTypes:	dc.l SoundTypes		; XREF: Sound_Play
Go_SoundD0:	dc.l SoundD0Index	; XREF: Sound_D0toDF
Go_MusicIndex:	dc.l MusicIndex		; XREF: Sound_81to9F
Go_SoundIndex:	dc.l SoundIndex		; XREF: Sound_A0toCF
Go_SoundIndex_E0toF9:	dc.l SoundIndex_E0plus
off_719A0:	dc.l byte_71A94		; XREF: Sound_81to9F
Go_PSGIndex:	dc.l PSG_Index		; XREF: sub_72926
; ---------------------------------------------------------------------------
; PSG instruments used in music
; ---------------------------------------------------------------------------
PSG_Index:	dc.l PSG1, PSG2, PSG3
		dc.l PSG4, PSG5, PSG6
		dc.l PSG7, PSG8, PSG9
PSG1:		BINCLUDE	sound\psg1.bin
PSG2:		BINCLUDE	sound\psg2.bin
PSG3:		BINCLUDE	sound\psg3.bin
PSG4:		BINCLUDE	sound\psg4.bin
PSG6:		BINCLUDE	sound\psg6.bin
PSG5:		BINCLUDE	sound\psg5.bin
PSG7:		BINCLUDE	sound\psg7.bin
PSG8:		BINCLUDE	sound\psg8.bin
PSG9:		BINCLUDE	sound\psg9.bin

byte_71A94:	dc.b 7,	$72, $73, $26, $15, 8, $FF, 5
; ---------------------------------------------------------------------------
; Music	Pointers
; ---------------------------------------------------------------------------
MusicIndex:
MusPtr_2PResult:		dc.l Music81
MusPtr_EHZ:	dc.l Music82
MusPtr_MCZ_2P:		dc.l Music83
MusPtr_OOZ:		dc.l Music84
MusPtr_MTZ:		dc.l Music85
MusPtr_HTZ:		dc.l Music86
MusPtr_ARZ:		dc.l Music87
MusPtr_CNZ_2P:		dc.l Music88
MusPtr_CNZ:		dc.l Music89
MusPtr_DEZ:		dc.l Music8A
MusPtr_MCZ:		dc.l Music8B
MusPtr_EHZ_2P:		dc.l Music8C
MusPtr_SCZ:		dc.l Music8D
MusPtr_CPZ:		dc.l Music8E
MusPtr_WFZ:		dc.l Music8F
MusPtr_HPZ:		dc.l Music90
MusPtr_Options:		dc.l Music91
MusPtr_SpecStage:		dc.l Music92
MusPtr_Boss:		dc.l Music93
MusPtr_EndBoss:		dc.l Music94
MusPtr_Ending:		dc.l Music95
MusPtr_SuperSonic:		dc.l Music96
MusPtr_Invincible:		dc.l Music97
MusPtr_ExtraLife:		dc.l Music98
MusPtr_Title:		dc.l Music99
MusPtr_EndLevel:		dc.l Music9A
MusPtr_GameOver:		dc.l Music9B
MusPtr_Continue:		dc.l Music9C
MusPtr_Emerald:		dc.l Music9D
MusPtr_Credits:		dc.l Music9E
MusPtr_Countdown:		dc.l Music9F
; ---------------------------------------------------------------------------
; Type of sound	being played ($90 = music; $70 = normal	sound effect)
; ---------------------------------------------------------------------------
SoundTypes:	dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$90
		dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$80
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $68, $70, $70, $70, $60, $70,	$70
		dc.b $60, $70, $60, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $7F,	$60
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $70,	$80
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $70,	$70
		dc.b $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70
		dc.b $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

Init_Sonic1_Sound_Driver:               ; Esrael L. G. Neto
sub_71B4C:				; XREF: loc_B10; PalToCRAM
		move.w	#$100,($A11100).l ; stop the Z80
		nop
		nop
		nop

loc_71B5A:
		btst	#0,($A11100).l
		bne.s	loc_71B5A

		btst	#7,($A01FFD).l
		beq.s	loc_71B82
		move.w	#0,($A11100).l	; start	the Z80
		nop
		nop
		nop
		nop
		nop
		bra.s	sub_71B4C
dfsf:
	dc.w	$FFFF,$FFFF
; ===========================================================================

loc_71B82:
		lea	($FFFFF000).l,a6
		clr.b	$E(a6)
		tst.b	3(a6)		; is music paused?
		bne.w	loc_71E50	; if yes, branch
		subq.b	#1,1(a6)
		bne.s	loc_71B9E
		jsr	sub_7260C(pc)

loc_71B9E:
		move.b	4(a6),d0
		beq.s	loc_71BA8
		jsr	sub_72504(pc)

loc_71BA8:
		tst.b	$24(a6)
		beq.s	loc_71BB2
		jsr	sub_7267C(pc)

loc_71BB2:
		tst.w	$A(a6)		; is music or sound being played?
		beq.s	loc_71BBC	; if not, branch
		jsr	Sound_Play(pc)

loc_71BBC:
		cmpi.b	#$80,9(a6)
		beq.s	loc_71BC8
		jsr	Sound_ChkValue(pc)

loc_71BC8:
		lea	$40(a6),a5
		tst.b	(a5)
		bpl.s	loc_71BD4
		jsr	sub_71C4E(pc)

loc_71BD4:
		clr.b	8(a6)
		moveq	#5,d7

loc_71BDA:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71BE6
		jsr	sub_71CCA(pc)

loc_71BE6:
		dbf	d7,loc_71BDA

		moveq	#2,d7

loc_71BEC:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71BF8
		jsr	sub_72850(pc)

loc_71BF8:
		dbf	d7,loc_71BEC

		move.b	#$80,$E(a6)
		moveq	#2,d7

loc_71C04:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C10
		jsr	sub_71CCA(pc)

loc_71C10:
		dbf	d7,loc_71C04

		moveq	#2,d7

loc_71C16:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C22
		jsr	sub_72850(pc)

loc_71C22:
		dbf	d7,loc_71C16
		move.b	#$40,$E(a6)
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C38
		jsr	sub_71CCA(pc)

loc_71C38:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C44
		jsr	sub_72850(pc)

loc_71C44:
		move.w	#0,($A11100).l	; start	the Z80
		rts
; End of function sub_71B4C


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71C4E:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	locret_71CAA
		move.b	#$80,8(a6)
		movea.l	4(a5),a4

loc_71C5E:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.s	loc_71C6E
		jsr	sub_72A5A(pc)
		bra.s	loc_71C5E
; ===========================================================================

loc_71C6E:
		tst.b	d5
		bpl.s	loc_71C84
		move.b	d5,$10(a5)
		move.b	(a4)+,d5
		bpl.s	loc_71C84
		subq.w	#1,a4
		move.b	$F(a5),$E(a5)
		bra.s	loc_71C88
; ===========================================================================

loc_71C84:
		jsr	sub_71D40(pc)

loc_71C88:
		move.l	a4,4(a5)
		btst	#2,(a5)
		bne.s	locret_71CAA
		moveq	#0,d0
		move.b	$10(a5),d0
		cmpi.b	#$80,d0
		beq.s	locret_71CAA
		cmp.b   #0,($FFFFFF3A).w
		bgt.s	locret_71CAA
		btst	#3,d0
		bne.s	loc_71CAC
		cmp.b	#$8C,d0
		bge.s	loc_71CAC
		jsr	Calculate_PCM
		move.b	d0,($A01FFF).l


locret_71CAA:
		rts
; ===========================================================================

loc_71CAC:
		cmpi.b	#$8C,d0
		beq.w	Tom_71CAC
		cmpi.b	#$8D,d0
		beq.w	Tom_71CAC
		cmpi.b	#$8E,d0
		beq.w	Tom_71CAC
		cmpi.b	#$8F,d0
		beq.w	Bongo_71CAC
		cmpi.b	#$90,d0
		beq.w	Bongo_71CAC
		cmpi.b	#$91,d0
		beq.w	Bongo_71CAC
		move.l	d0,-(sp)
		move.b  #$85,d0
		jsr	(Calculate_PCM).l
		move.l  (sp)+,d0
		subi.b	#$88,d0
		move.b	byte_71CC4(pc,d0.w),d0
		move.b	d0,($A00224).l
		move.b	#$85,($A01FFF).l
		rts

Tom_71CAC:
		move.l	d0,-(sp)
		move.b  #$86,d0
		jsr	(Calculate_PCM).l
		move.l  (sp)+,d0
		subi.b	#$8C,d0
		move.b	Tom_71CC4(pc,d0.w),d0
		move.b	d0,($A0022C).l
		move.b	#$86,($A01FFF).l
		rts

Bongo_71CAC:
		move.l	d0,-(sp)
		move.b  #$87,d0
		jsr	(Calculate_PCM).l
		move.l  (sp)+,d0
		subi.b	#$8F,d0
		move.b	Bongo_71CC4(pc,d0.w),d0
		move.b	d0,($A00234).l
		move.b	#$87,($A01FFF).l
		rts

NoBend_71CAC:
		move.b	d0,d1
		subi.b	#7,d1
		move.b  d1,d0
		jsr	(Calculate_PCM).l
		move.b	d0,($A01FFF).l
		bra.w	locret_71CAA

; End of function sub_71C4E

; ===========================================================================
byte_71CC4:	dc.b $14, $17, $1E, $1F
Tom_71CC4: dc.b $4, $7, $A, $FF
Bongo_71CC4: dc.b $A, $D, $14, $FF

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CCA:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	loc_71CE0
		bclr	#4,(a5)
		jsr	sub_71CEC(pc)
		jsr	sub_71E18(pc)
		bra.w	loc_726E2
; ===========================================================================

loc_71CE0:
		jsr	sub_71D9E(pc)
		jsr	sub_71DC6(pc)
		bra.w	loc_71E24
; End of function sub_71CCA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CEC:				; XREF: sub_71CCA
		movea.l	4(a5),a4
		bclr	#1,(a5)

loc_71CF4:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.s	loc_71D04
		jsr	sub_72A5A(pc)
		bra.s	loc_71CF4
; ===========================================================================

loc_71D04:
		jsr	sub_726FE(pc)
		tst.b	d5
		bpl.s	loc_71D1A
		jsr	sub_71D22(pc)
		move.b	(a4)+,d5
		bpl.s	loc_71D1A
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_71D1A:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_71CEC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D22:				; XREF: sub_71CEC
		subi.b	#$80,d5
		beq.s	loc_71D58
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_72790(pc),a0
		move.w	(a0,d5.w),d6
		move.w	d6,$10(a5)
		rts
; End of function sub_71D22


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D40:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		move.b	d5,d0
		move.b	respawnentry(a5),d1

loc_71D46:
		subq.b	#1,d1
		beq.s	loc_71D4E
		add.b	d5,d0
		bra.s	loc_71D46
; ===========================================================================

loc_71D4E:
		move.b	d0,$F(a5)
		move.b	d0,$E(a5)
		rts
; End of function sub_71D40

; ===========================================================================

loc_71D58:				; XREF: sub_71D22
		bset	#1,(a5)
		clr.w	$10(a5)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D60:				; XREF: sub_71CEC; sub_72878; sub_728AC
		move.l	a4,4(a5)
		move.b	$F(a5),$E(a5)
		btst	#4,(a5)
		bne.s	locret_71D9C
		move.b	$13(a5),$12(a5)
		clr.b	$C(a5)
		btst	#3,(a5)
		beq.s	locret_71D9C
		movea.l	$14(a5),a0
		move.b	(a0)+,$18(a5)
		move.b	(a0)+,$19(a5)
		move.b	(a0)+,$1A(a5)
		move.b	(a0)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)

locret_71D9C:
		rts
; End of function sub_71D60


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D9E:				; XREF: sub_71CCA; sub_72850
		tst.b	$12(a5)
		beq.s	locret_71DC4
		subq.b	#1,$12(a5)
		bne.s	locret_71DC4
		bset	#1,(a5)
		tst.b	1(a5)
		bmi.w	loc_71DBE
		jsr	sub_726FE(pc)
		addq.w	#4,sp
		rts
; ===========================================================================

loc_71DBE:
		jsr	sub_729A0(pc)
		addq.w	#4,sp

locret_71DC4:
		rts
; End of function sub_71D9E


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71DC6:				; XREF: sub_71CCA; sub_72850
		addq.w	#4,sp
		btst	#3,(a5)
		beq.s	locret_71E16
		tst.b	$18(a5)
		beq.s	loc_71DDA
		subq.b	#1,$18(a5)
		rts
; ===========================================================================

loc_71DDA:
		subq.b	#1,$19(a5)
		beq.s	loc_71DE2
		rts
; ===========================================================================

loc_71DE2:
		movea.l	$14(a5),a0
		move.b	1(a0),$19(a5)
		tst.b	$1B(a5)
		bne.s	loc_71DFE
		move.b	3(a0),$1B(a5)
		neg.b	$1A(a5)
		rts
; ===========================================================================

loc_71DFE:
		subq.b	#1,$1B(a5)
		move.b	$1A(a5),d6
		ext.w	d6
		add.w	$1C(a5),d6
		move.w	d6,$1C(a5)
		add.w	$10(a5),d6
		subq.w	#4,sp

locret_71E16:
		rts
; End of function sub_71DC6


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71E18:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.s	locret_71E48
		move.w	$10(a5),d6
		beq.s	loc_71E4A

loc_71E24:				; XREF: sub_71CCA
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.s	locret_71E48
		move.w	d6,d1
		lsr.w	#8,d1
		move.b	#-$5C,d0
		jsr	sub_72722(pc)
		move.b	d6,d1
		move.b	#-$60,d0
		jsr	sub_72722(pc)

locret_71E48:
		rts
; ===========================================================================

loc_71E4A:
		bset	#1,(a5)
		rts
; End of function sub_71E18

; ===========================================================================

loc_71E50:				; XREF: sub_71B4C
		bmi.s	loc_71E94
		cmpi.b	#2,3(a6)
		beq.w	loc_71EFE
		move.b	#2,3(a6)
		moveq	#2,d3
		move.b	#-$4C,d0
		moveq	#0,d1

loc_71E6A:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.b	#1,d0
		dbf	d3,loc_71E6A

		moveq	#2,d3
		moveq	#$28,d0

loc_71E7C:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbf	d3,loc_71E7C

		jsr	sub_729B6(pc)
		bra.w	loc_71C44
; ===========================================================================

loc_71E94:				; XREF: loc_71E50
		clr.b	3(a6)
		moveq	#$30,d3
		lea	$40(a6),a5
		moveq	#6,d4

loc_71EA0:
		btst	#7,(a5)
		beq.s	loc_71EB8
		btst	#2,(a5)
		bne.s	loc_71EB8
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EB8:
		adda.w	d3,a5
		dbf	d4,loc_71EA0

		lea	$220(a6),a5
		moveq	#2,d4

loc_71EC4:
		btst	#7,(a5)
		beq.s	loc_71EDC
		btst	#2,(a5)
		bne.s	loc_71EDC
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EDC:
		adda.w	d3,a5
		dbf	d4,loc_71EC4

		lea	$340(a6),a5
		btst	#7,(a5)
		beq.s	loc_71EFE
		btst	#2,(a5)
		bne.s	loc_71EFE
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EFE:
		bra.w	loc_71C44

; ---------------------------------------------------------------------------
; Subroutine to	play a sound or	music track
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_Play:				; XREF: sub_71B4C
		movea.l	(Go_SoundTypes).l,a0
		lea	$A(a6),a1	; load music track number
		move.b	0(a6),d3
		moveq	#2,d4

loc_71F12:
		move.b	(a1),d0		; move track number to d0
		move.b	d0,d1
		clr.b	(a1)+
		subi.b	#$81,d0
		bcs.s	loc_71F3E
		cmpi.b	#$80,9(a6)
		beq.s	loc_71F2C
		move.b	d1,$A(a6)
		bra.s	loc_71F3E
; ===========================================================================

loc_71F2C:
		andi.w	#$7F,d0
		move.b	(a0,d0.w),d2
		cmp.b	d3,d2
		bcs.s	loc_71F3E
		move.b	d2,d3
		move.b	d1,9(a6)	; set music flag

loc_71F3E:
		dbf	d4,loc_71F12

		tst.b	d3
		bmi.s	locret_71F4A
		move.b	d3,0(a6)

locret_71F4A:
		rts
; End of function Sound_Play


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_ChkValue:				; XREF: sub_71B4C
		moveq	#0,d7
		move.b	9(a6),d7
		beq.w	Sound_E4
		bpl.s	locret_71F8C
		move.b	#$80,9(a6)	; reset	music flag
		cmpi.b  #$E0,d7
		bge.s  Sound_E0plus
Sound_ChkValue_OtherChecks:
		cmpi.b  #$FF,d7
		bge.s Sound_E0toF8
		cmpi.b	#$9F,d7
		ble.w	Sound_81To9F
		cmpi.b	#$F0,d7
		ble.w	Sound_A0ToCF
		cmpi.b	#$F9,d7
		bge.w	Sound_E0toE4

locret_71F8C:

		rts

Sound_E0plus:
		cmpi.b	#$F8,d7
		bge.s	Sound_ChkValue_OtherChecks
		subi.b	#$E0,d7
		bra.s	Sound_ChkValue_OtherChecks

Sound_E0toF8:
		tst.b	$27(a6)
		bne.w	loc_722C6
		tst.b	4(a6)
		bne.w	loc_722C6
		tst.b	$24(a6)
		bne.w	loc_722C6
		bra.s	++
		cmpi.b	#$B5,d7		; is ring sound	effect played?
		bne.s	++	; if not, branch
		tst.b	$2B(a6)
		bne.s	+
 		move.b	#$CE,d7		; play ring sound in left speaker

+
		bchg	#0,$2B(a6)	; change speaker

+
		cmpi.b	#$A7,d7		; is "pushing" sound played?
		bne.s	+	; if not, branch
		tst.b	$2C(a6)
		bne.w	locret_722C4
		move.b	#$80,$2C(a6)

+
		movea.l	(Go_SoundIndex_E0toF9).l,a0
		jmp	SFX_Continue
; End of function Sound_ChkValue
; ===========================================================================

Sound_E0toE4:				; XREF: Sound_ChkValue
		;subi.b	#$E0,d7
		subi.b	#$F9, D7
		lsl.w	#2,d7
		jmp	Sound_ExIndex(pc,d7.w)
; ===========================================================================

Sound_ExIndex:
		bra.w	Sound_E0
; ===========================================================================
		bra.w	Sound_E1
; ===========================================================================
		bra.w	Sound_E2
; ===========================================================================
		bra.w	Sound_E3
; ===========================================================================
		bra.w	Sound_E4
; ===========================================================================
; ---------------------------------------------------------------------------
; Play "Say-gaa" PCM sound
; ---------------------------------------------------------------------------
Sound_E1:
		lea	(SegaPCM).l,a2			; Load the SEGA PCM sample into a2. It's important that we use a2 since a0 and a1 are going to be used up ahead when reading the joypad ports
		move.l	#$6978,d3			; Load the size of the SEGA PCM sample into d3
		move.b	#$2A,($A04000).l		; $A04000 = $2A -> Write to DAC channel
PlayPCM_Loop:
		move.b	(a2)+,($A04001).l		; Write the PCM data (contained in a2) to $A04001 (YM2612 register D0)
		move.w	#$14,d0				; Write the pitch ($14 in this case) to d0
		dbf	d0,*				; Decrement d0; jump to itself if not 0. (for pitch control, avoids playing the sample too fast)
		sub.l	#1,d3				; Subtract 1 from the PCM sample size
		beq.s	return_PlayPCM			; If d3 = 0, we finished playing the PCM sample, so stop playing, leave this loop, and unfreeze the 68K
		lea	($FFFFF604).w,a0		; address where JoyPad states are written
		lea	($A10003).l,a1			; address where JoyPad states are read from
		jsr	(Joypad_Read).w			; Read only the first joypad port. It's important that we do NOT do the two ports, we don't have the cycles for that
		btst	#7,($FFFFF504).w		; Check for Start button
		bne.s	return_PlayPCM			; If start is pressed, stop playing, leave this loop, and unfreeze the 68K
		bra.s	PlayPCM_Loop			; Otherwise, continue playing PCM sample
return_PlayPCM:
		addq.w	#4,sp
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Play music track $81-$9F
; ---------------------------------------------------------------------------

Sound_81to9F:				; XREF: Sound_ChkValue
		cmpi.b	#$98,d7		; is "extra life" music	played?
		bne.s	loc_72024	; if not, skip functions
		tst.b	$27(a6)		; check if music ram ??? is empty
		bne.w	loc_721B6	; if not, branch
		lea	$40(a6),a5	; load 1st channel ram to a5
		moveq	#9,d0		; set repeat times

loc_71FE6:
		bclr	#2,(a5)		; clear bit 0010 to the current channel
		adda.w	#$30,a5		; load next channel ram
		dbf	d0,loc_71FE6	; repeat til ALL 0A channel's have been done (In RAM) (6FM 1DAC 3PSG)

		lea	$220(a6),a5	; load ??? I think FM sfx Channel Ram to a5
		moveq	#5,d0		; set to repeat 5 times (6 fm channels to use SFX)

loc_71FF8:
		bclr	#7,(a5)		; clear bits 0111 to the current channel
		adda.w	#$30,a5		; load next channel ram
		dbf	d0,loc_71FF8	; repeat til all 06 channel's have been done (In RAM) (I think 6FM)
		clr.b	0(a6)		; clear the fisrt byte in music ram (???)
		movea.l	a6,a0		; load address to a0
		lea	$3A0(a6),a1	; load ??? to a1
		move.w	#$87,d0		; set repeat times

loc_72012:
		move.l	(a0)+,(a1)+	; copy ALL data from the music ram to 3A0 bytes after it
		dbf	d0,loc_72012	; repeat til 88 times have passed (posibly the first info of Music RAM and 1st channel and a bit of second channel)
		move.b	#$80,$27(a6)	; move 80 to ??? which was checked to see if it was empty
		clr.b	0(a6)		; clear the fisrt byte in music ram (???)
		bra.s	loc_7202C	; continue without clearing $27(a6) & $26(a6)

; 5C0 bytes of ram space is taken for Music Ram

; ===========================================================================

loc_72024:
		clr.b	$27(a6)
		clr.b	$26(a6)

loc_7202C:
		jsr	sub_725CA(pc)
		movea.l	(off_719A0).l,a4
		subi.b	#$81,d7
		move.b	(a4,d7.w),$29(a6)
		movea.l	(Go_MusicIndex).l,a4
		lsl.w	#2,d7
		movea.l	(a4,d7.w),a4
		moveq	#0,d0
		move.w	(a4),d0
		add.l	a4,d0
		move.l	d0,$18(a6)
		move.b	5(a4),d0
		move.b	d0,$28(a6)
		tst.b	$2A(a6)
		beq.s	loc_72068
		move.b	$29(a6),d0

loc_72068:
		move.b	d0,2(a6)
		move.b	d0,1(a6)
		moveq	#0,d1
		movea.l	a4,a3
		addq.w	#6,a4
		moveq	#0,d7
		move.b	2(a3),d7
		beq.w	loc_72114
		subq.b	#1,d7
		move.b	#-$40,d1
		move.b	4(a3),d4
		moveq	#$30,d6
		move.b	#1,d5
		lea	$40(a6),a1
		lea	byte_721BA(pc),a2

loc_72098:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d1,$A(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		adda.w	d6,a1
		dbf	d7,loc_72098
		cmpi.b	#7,2(a3)
		bne.s	loc_720D8
		moveq	#$2B,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		bra.w	loc_72114
; ===========================================================================

loc_720D8:
		moveq	#$28,d0
		moveq	#6,d1
		jsr	sub_7272E(pc)
		move.b	#$42,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4A,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$46,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4E,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#-$4A,d0
		move.b	#-$40,d1
		jsr	sub_72764(pc)

loc_72114:
		moveq	#0,d7
		move.b	3(a3),d7
		beq.s	loc_72154
		subq.b	#1,d7
		lea	$190(a6),a1
		lea	byte_721C2(pc),a2

loc_72126:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		move.b	(a4)+,d0
		move.b	(a4)+,$B(a1)
		adda.w	d6,a1
		dbf	d7,loc_72126

loc_72154:
		lea	$220(a6),a1
		moveq	#5,d7

loc_7215A:
		tst.b	(a1)
		bpl.w	loc_7217C
		moveq	#0,d0
		move.b	1(a1),d0
		bmi.s	loc_7216E
		subq.b	#2,d0
		lsl.b	#2,d0
		bra.s	loc_72170
; ===========================================================================

loc_7216E:
		lsr.b	#3,d0

loc_72170:
		lea	dword_722CC(pc),a0
		movea.l	(a0,d0.w),a0
		bset	#2,(a0)

loc_7217C:
		adda.w	d6,a1
		dbf	d7,loc_7215A

		tst.w	$340(a6)
		bpl.s	loc_7218E
		bset	#2,$100(a6)

loc_7218E:
		tst.w	$370(a6)
		bpl.s	loc_7219A
		bset	#2,$1F0(a6)

loc_7219A:
		lea	$70(a6),a5
		moveq	#5,d4

loc_721A0:
		jsr	sub_726FE(pc)
		adda.w	d6,a5
		dbf	d4,loc_721A0
		moveq	#2,d4

loc_721AC:
		jsr	sub_729A0(pc)
		adda.w	d6,a5
		dbf	d4,loc_721AC

loc_721B6:
		addq.w	#4,sp
		rts
; ===========================================================================
byte_721BA:	dc.b 6,	0, 1, 2, 4, 5, 6, 0
		even
byte_721C2:	dc.b $80, $A0, $C0, 0
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Play normal sound effect
; ---------------------------------------------------------------------------

Sound_A0toCF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	loc_722C6
		tst.b	4(a6)
		bne.w	loc_722C6
		tst.b	$24(a6)
		bne.w	loc_722C6
		cmpi.b	#$B5,d7		; is ring sound	effect played?
		bne.s	Sound_notB5	; if not, branch
		tst.b	$2B(a6)
		bne.s	loc_721EE
		move.b	#$CE,d7		; play ring sound in left speaker

loc_721EE:
		bchg	#0,$2B(a6)	; change speaker

Sound_notB5:
		;cmpi.b	#$A7,d7		; is "pushing" sound played?
		;bne.s	Sound_notA7	; if not, branch
		bra.s	Sound_notA7
		tst.b	$2C(a6)
		bne.w	locret_722C4
		move.b	#$80,$2C(a6)

Sound_notA7:
		movea.l	(Go_SoundIndex).l,a0
		subi.b	#$A0,d7

SFX_Continue:
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d1
		move.w	(a1)+,d1
		add.l	a3,d1
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72228:
		moveq	#0,d3
		move.b	1(a1),d3
		move.b	d3,d4
		bmi.s	loc_72244
		subq.w	#2,d3
		lsl.w	#2,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		bra.s	loc_7226E
; ===========================================================================

loc_72244:
		lsr.w	#3,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		cmpi.b	#$C0,d4
		bne.s	loc_7226E
		move.b	d4,d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l
		bchg	#5,d0
		move.b	d0,($C00011).l

loc_7226E:
		movea.l	dword_722EC(pc,d3.w),a5
		movea.l	a5,a2
		moveq	#$B,d0

loc_72276:
		clr.l	(a2)+
		dbf	d0,loc_72276

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.s	loc_722A8
		move.b	#$C0,$A(a5)
		move.l	d1,$20(a5)

loc_722A8:
		dbf	d7,loc_72228

		tst.b	$250(a6)
		bpl.s	loc_722B8
		bset	#2,$340(a6)

loc_722B8:
		tst.b	$310(a6)
		bpl.s	locret_722C4
		bset	#2,$370(a6)

locret_722C4:
		rts
; ===========================================================================

loc_722C6:
		clr.b	0(a6)
		rts
; ===========================================================================
dword_722CC:	dc.l $FFF0D0
		dc.l 0
		dc.l $FFF100
		dc.l $FFF130
		dc.l $FFF190
		dc.l $FFF1C0
		dc.l $FFF1F0
		dc.l $FFF1F0
dword_722EC:	dc.l $FFF220
		dc.l 0
		dc.l $FFF250
		dc.l $FFF280
		dc.l $FFF2B0
		dc.l $FFF2E0
		dc.l $FFF310
		dc.l $FFF310
; ===========================================================================
; ---------------------------------------------------------------------------
; Play GHZ waterfall sound
; ---------------------------------------------------------------------------

Sound_D0toDF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	locret_723C6
		tst.b	4(a6)
		bne.w	locret_723C6
		tst.b	$24(a6)
		bne.w	locret_723C6
		movea.l	(Go_SoundD0).l,a0
		subi.b	#$D0,d7
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,$20(a6)
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72348:
		move.b	1(a1),d4
		bmi.s	loc_7235A
		bset	#2,$100(a6)
		lea	$340(a6),a5
		bra.s	loc_72364
; ===========================================================================

loc_7235A:
		bset	#2,$1F0(a6)
		lea	$370(a6),a5

loc_72364:
		movea.l	a5,a2
		moveq	#$B,d0

loc_72368:
		clr.l	(a2)+
		dbf	d0,loc_72368

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.s	loc_72396
		move.b	#$C0,$A(a5)

loc_72396:
		dbf	d7,loc_72348

		tst.b	$250(a6)
		bpl.s	loc_723A6
		bset	#2,$340(a6)

loc_723A6:
		tst.b	$310(a6)
		bpl.s	locret_723C6
		bset	#2,$370(a6)
		ori.b	#$1F,d4
		move.b	d4,($C00011).l
		bchg	#5,d4
		move.b	d4,($C00011).l

locret_723C6:
		rts
; End of function Sound_ChkValue

; ===========================================================================
		dc.l $FFF100
		dc.l $FFF1F0
		dc.l $FFF250
		dc.l $FFF310
		dc.l $FFF340
		dc.l $FFF370

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut1:				; XREF: Sound_E0
		clr.b	0(a6)
		lea	$220(a6),a5
		moveq	#5,d7

loc_723EA:
		tst.b	(a5)
		bpl.w	loc_72472
		bclr	#7,(a5)
		moveq	#0,d3
		move.b	1(a5),d3
		bmi.s	loc_7243C
		jsr	sub_726FE(pc)
		cmpi.b	#4,d3
		bne.s	loc_72416
		tst.b	$340(a6)
		bpl.s	loc_72416
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.s	loc_72428
; ===========================================================================

loc_72416:
		subq.b	#2,d3
		lsl.b	#2,d3
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		movea.l	(a0,d3.w),a5
		movea.l	$18(a6),a1

loc_72428:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5
		bra.s	loc_72472
; ===========================================================================

loc_7243C:
		jsr	sub_729A0(pc)
		lea	$370(a6),a0
		cmpi.b	#$E0,d3
		beq.s	loc_7245A
		cmpi.b	#$C0,d3
		beq.s	loc_7245A
		lsr.b	#3,d3
		lea	dword_722CC(pc),a0
		movea.l	(a0,d3.w),a0

loc_7245A:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.s	loc_72472
		move.b	$1F(a0),($C00011).l

loc_72472:
		adda.w	#$30,a5
		dbf	d7,loc_723EA

		rts
; End of function Snd_FadeOut1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut2:				; XREF: Sound_E0
		lea	$340(a6),a5
		tst.b	(a5)
		bpl.s	loc_724AE
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.s	loc_724AE
		jsr	loc_7270A(pc)
		lea	$100(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.s	loc_724AE
		movea.l	$18(a6),a1
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_724AE:
		lea	$370(a6),a5
		tst.b	(a5)
		bpl.s	locret_724E4
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.s	locret_724E4
		jsr	loc_729A6(pc)
		lea	$1F0(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.s	locret_724E4
		cmpi.b	#-$20,1(a5)
		bne.s	locret_724E4
		move.b	$1F(a5),($C00011).l

locret_724E4:
		rts
; End of function Snd_FadeOut2

; ===========================================================================
; ---------------------------------------------------------------------------
; Fade out music
; ---------------------------------------------------------------------------

Sound_E0:				; XREF: Sound_ExIndex
		jsr	Snd_FadeOut1(pc)
		jsr	Snd_FadeOut2(pc)
		move.b	#3,6(a6)
		move.b	#$28,4(a6)
		clr.b	$40(a6)
		clr.b	$2A(a6)
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72504:				; XREF: sub_71B4C
		move.b	6(a6),d0
		beq.s	loc_72510
		subq.b	#1,6(a6)
		rts
; ===========================================================================

loc_72510:
		subq.b	#1,4(a6)
		beq.w	Sound_E4
		move.b	#3,6(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_72524:
		tst.b	(a5)
		bpl.s	loc_72538
		addq.b	#1,9(a5)
		bpl.s	loc_72534
		bclr	#7,(a5)
		bra.s	loc_72538
; ===========================================================================

loc_72534:
		jsr	sub_72CB4(pc)

loc_72538:
		adda.w	#$30,a5
		dbf	d7,loc_72524

		moveq	#2,d7

loc_72542:
		tst.b	(a5)
		bpl.s	loc_72560
		addq.b	#1,9(a5)
		cmpi.b	#$10,9(a5)
		bcs.s	loc_72558
		bclr	#7,(a5)
		bra.s	loc_72560
; ===========================================================================

loc_72558:
		move.b	9(a5),d6
		jsr	sub_7296A(pc)

loc_72560:
		adda.w	#$30,a5
		dbf	d7,loc_72542

		rts
; End of function sub_72504


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7256A:				; XREF: Sound_E4; sub_725CA
		moveq	#2,d3
		moveq	#$28,d0

loc_7256E:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbf	d3,loc_7256E

		moveq	#$40,d0
		moveq	#$7F,d1
		moveq	#2,d4

loc_72584:
		moveq	#3,d3

loc_72586:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.w	#4,d0
		dbf	d3,loc_72586

		subi.b	#$F,d0
		dbf	d4,loc_72584

		rts
; End of function sub_7256A

; ===========================================================================
; ---------------------------------------------------------------------------
; Stop music
; ---------------------------------------------------------------------------

Sound_E4:				; XREF: Sound_ChkValue; Sound_ExIndex; sub_72504
		moveq	#$2B,d0
		move.b	#$80,d1
		jsr	sub_7272E(pc)
		moveq	#$27,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		movea.l	a6,a0
		move.w	#$E3,d0

loc_725B6:
		clr.l	(a0)+
		dbf	d0,loc_725B6

		move.b	#$80,9(a6)	; set music to $80 (silence)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_725CA:				; XREF: Sound_ChkValue
		movea.l	a6,a0
		move.b	0(a6),d1
		move.b	$27(a6),d2
		move.b	$2A(a6),d3
		move.b	$26(a6),d4
		move.w	$A(a6),d5
		move.w	#$87,d0

loc_725E4:
		clr.l	(a0)+
		dbf	d0,loc_725E4

		move.b	d1,0(a6)
		move.b	d2,$27(a6)
		move.b	d3,$2A(a6)
		move.b	d4,$26(a6)
		move.w	d5,$A(a6)
		move.b	#$80,9(a6)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6
; End of function sub_725CA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7260C:				; XREF: sub_71B4C
		move.b	2(a6),1(a6)
		lea	$4E(a6),a0
		moveq	#$30,d0
		moveq	#9,d1

loc_7261A:
		addq.b	#1,(a0)
		adda.w	d0,a0
		dbf	d1,loc_7261A

		rts
; End of function sub_7260C

; ===========================================================================
; ---------------------------------------------------------------------------
; Speed	up music
; ---------------------------------------------------------------------------

Sound_E2:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.s	loc_7263E
		move.b	$29(a6),2(a6)
		move.b	$29(a6),1(a6)
		move.b	#$80,$2A(a6)
		rts
; ===========================================================================

loc_7263E:
		move.b	$3C9(a6),$3A2(a6)
		move.b	$3C9(a6),$3A1(a6)
		move.b	#$80,$3CA(a6)
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Change music back to normal speed
; ---------------------------------------------------------------------------

Sound_E3:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.s	loc_7266A
		move.b	$28(a6),2(a6)
		move.b	$28(a6),1(a6)
		clr.b	$2A(a6)
		rts
; ===========================================================================

loc_7266A:
		move.b	$3C8(a6),$3A2(a6)
		move.b	$3C8(a6),$3A1(a6)
		clr.b	$3CA(a6)
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7267C:				; XREF: sub_71B4C
		tst.b	$25(a6)
		beq.s	loc_72688
		subq.b	#1,$25(a6)
		rts
; ===========================================================================

loc_72688:
		tst.b	$26(a6)
		beq.s	loc_726D6
		subq.b	#1,$26(a6)
		move.b	#2,$25(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_7269E:
		tst.b	(a5)
		bpl.s	loc_726AA
		subq.b	#1,9(a5)
		jsr	sub_72CB4(pc)

loc_726AA:
		adda.w	#$30,a5
		dbf	d7,loc_7269E
		moveq	#2,d7

loc_726B4:
		tst.b	(a5)
		bpl.s	loc_726CC
		subq.b	#1,9(a5)
		move.b	9(a5),d6
		cmpi.b	#$10,d6
		bcs.s	loc_726C8
		moveq	#$F,d6

loc_726C8:
		jsr	sub_7296A(pc)

loc_726CC:
		adda.w	#$30,a5
		dbf	d7,loc_726B4
		rts
; ===========================================================================

loc_726D6:
		bclr	#2,$40(a6)
		clr.b	$24(a6)
		rts
; End of function sub_7267C

; ===========================================================================

loc_726E2:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.s	locret_726FC
		btst	#2,(a5)
		bne.s	locret_726FC
		moveq	#$28,d0
		move.b	1(a5),d1
		ori.b	#-$10,d1
		bra.w	sub_7272E
; ===========================================================================

locret_726FC:
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_726FE:				; XREF: sub_71CEC; sub_71D9E; Sound_ChkValue; Snd_FadeOut1
		btst	#4,(a5)
		bne.s	locret_72714
		btst	#2,(a5)
		bne.s	locret_72714

loc_7270A:				; XREF: Snd_FadeOut2
		moveq	#$28,d0
		move.b	1(a5),d1
		bra.w	sub_7272E
; ===========================================================================

locret_72714:
		rts
; End of function sub_726FE

; ===========================================================================

loc_72716:				; XREF: sub_72A5A
		btst	#2,(a5)
		bne.s	locret_72720
		bra.w	sub_72722
; ===========================================================================

locret_72720:
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72722:				; XREF: sub_71E18; sub_72C4E; sub_72CB4
		btst	#2,1(a5)
		bne.s	loc_7275A
		add.b	1(a5),d0
; End of function sub_72722


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7272E:				; XREF: loc_71E6A
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	sub_7272E
		move.b	d0,($A04000).l
		nop
		nop
		nop

loc_72746:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	loc_72746

		move.b	d1,($A04001).l
		rts
; End of function sub_7272E

; ===========================================================================

loc_7275A:				; XREF: sub_72722
		move.b	1(a5),d2
		bclr	#2,d2
		add.b	d2,d0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72764:				; XREF: loc_71E6A; Sound_ChkValue; sub_7256A; sub_72764
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	sub_72764
		move.b	d0,($A04002).l
		nop
		nop
		nop

loc_7277C:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	loc_7277C

		move.b	d1,($A04003).l
		rts
; End of function sub_72764

; ===========================================================================
word_72790:	dc.w $25E, $284, $2AB, $2D3, $2FE, $32D, $35C, $38F, $3C5
		dc.w $3FF, $43C, $47C, $A5E, $A84, $AAB, $AD3, $AFE, $B2D
		dc.w $B5C, $B8F, $BC5, $BFF, $C3C, $C7C, $125E,	$1284
		dc.w $12AB, $12D3, $12FE, $132D, $135C,	$138F, $13C5, $13FF
		dc.w $143C, $147C, $1A5E, $1A84, $1AAB,	$1AD3, $1AFE, $1B2D
		dc.w $1B5C, $1B8F, $1BC5, $1BFF, $1C3C,	$1C7C, $225E, $2284
		dc.w $22AB, $22D3, $22FE, $232D, $235C,	$238F, $23C5, $23FF
		dc.w $243C, $247C, $2A5E, $2A84, $2AAB,	$2AD3, $2AFE, $2B2D
		dc.w $2B5C, $2B8F, $2BC5, $2BFF, $2C3C,	$2C7C, $325E, $3284
		dc.w $32AB, $32D3, $32FE, $332D, $335C,	$338F, $33C5, $33FF
		dc.w $343C, $347C, $3A5E, $3A84, $3AAB,	$3AD3, $3AFE, $3B2D
		dc.w $3B5C, $3B8F, $3BC5, $3BFF, $3C3C,	$3C7C

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72850:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	loc_72866
		bclr	#4,(a5)
		jsr	sub_72878(pc)
		jsr	sub_728DC(pc)
		bra.w	loc_7292E
; ===========================================================================

loc_72866:
		jsr	sub_71D9E(pc)
		jsr	sub_72926(pc)
		jsr	sub_71DC6(pc)
		jsr	sub_728E2(pc)
		rts
; End of function sub_72850


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72878:				; XREF: sub_72850
		bclr	#1,(a5)
		movea.l	4(a5),a4

loc_72880:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#$E0,d5
		bcs.s	loc_72890
		jsr	sub_72A5A(pc)
		bra.s	loc_72880
; ===========================================================================

loc_72890:
		tst.b	d5
		bpl.s	loc_728A4
		jsr	sub_728AC(pc)
		move.b	(a4)+,d5
		tst.b	d5
		bpl.s	loc_728A4
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_728A4:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_72878


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728AC:				; XREF: sub_72878
		subi.b	#$81,d5
		bcs.s	loc_728CA
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_729CE(pc),a0
		move.w	(a0,d5.w),$10(a5)
		bra.w	sub_71D60
; ===========================================================================

loc_728CA:
		bset	#1,(a5)
		move.w	#-1,$10(a5)
		jsr	sub_71D60(pc)
		bra.w	sub_729A0
; End of function sub_728AC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728DC:				; XREF: sub_72850
		move.w	$10(a5),d6
		bmi.s	loc_72920
; End of function sub_728DC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728E2:				; XREF: sub_72850
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.s	locret_7291E
		btst	#1,(a5)
		bne.s	locret_7291E
		move.b	1(a5),d0
		cmpi.b	#$E0,d0
		bne.s	loc_72904
		move.b	#$C0,d0

loc_72904:
		move.w	d6,d1
		andi.b	#$F,d1
		or.b	d1,d0
		lsr.w	#4,d6
		andi.b	#$3F,d6
		move.b	d0,($C00011).l
		move.b	d6,($C00011).l

locret_7291E:
		rts
; End of function sub_728E2

; ===========================================================================

loc_72920:				; XREF: sub_728DC
		bset	#1,(a5)
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72926:				; XREF: sub_72850
		tst.b	$B(a5)
		beq.w	locret_7298A

loc_7292E:				; XREF: sub_72850
		move.b	9(a5),d6
		moveq	#0,d0
		move.b	$B(a5),d0
		beq.s	sub_7296A
		movea.l	(Go_PSGIndex).l,a0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a0,d0.w),a0
		move.b	$C(a5),d0
		move.b	(a0,d0.w),d0
		addq.b	#1,$C(a5)
		btst	#7,d0
		beq.s	loc_72960
		cmpi.b	#$80,d0
		beq.s	loc_7299A

loc_72960:
		add.w	d0,d6
		cmpi.b	#$10,d6
		bcs.s	sub_7296A
		moveq	#$F,d6
; End of function sub_72926


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7296A:				; XREF: sub_72504; sub_7267C; sub_72926
		btst	#1,(a5)
		bne.s	locret_7298A
		btst	#2,(a5)
		bne.s	locret_7298A
		btst	#4,(a5)
		bne.s	loc_7298C

loc_7297C:
		or.b	1(a5),d6
		addi.b	#$10,d6
		move.b	d6,($C00011).l

locret_7298A:
		rts
; ===========================================================================

loc_7298C:
		tst.b	$13(a5)
		beq.s	loc_7297C
		tst.b	$12(a5)
		bne.s	loc_7297C
		rts
; End of function sub_7296A

; ===========================================================================

loc_7299A:				; XREF: sub_72926
		subq.b	#1,$C(a5)
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729A0:				; XREF: sub_71D9E; Sound_ChkValue; Snd_FadeOut1; sub_728AC
		btst	#2,(a5)
		bne.s	locret_729B4

loc_729A6:				; XREF: Snd_FadeOut2
		move.b	1(a5),d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l

locret_729B4:
		rts
; End of function sub_729A0


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729B6:				; XREF: loc_71E7C
		lea	($C00011).l,a0
		move.b	#$9F,(a0)
		move.b	#$BF,(a0)
		move.b	#$DF,(a0)
		move.b	#$FF,(a0)
		rts
; End of function sub_729B6

; ===========================================================================
word_729CE:	dc.w $356, $326, $2F9, $2CE, $2A5, $280, $25C, $23A, $21A
		dc.w $1FB, $1DF, $1C4, $1AB, $193, $17D, $167, $153, $140
		dc.w $12E, $11D, $10D, $FE, $EF, $E2, $D6, $C9,	$BE, $B4
		dc.w $A9, $A0, $97, $8F, $87, $7F, $78,	$71, $6B, $65
		dc.w $5F, $5A, $55, $50, $4B, $47, $43,	$40, $3C, $39
		dc.w $36, $33, $30, $2D, $2B, $28, $26,	$24, $22, $20
		dc.w $1F, $1D, $1B, $1A, $18, $17, $16,	$15, $13, $12
		dc.w $11, 0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72A5A:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		subi.w	#$E0,d5
		lsl.w	#2,d5
		jmp	loc_72A64(pc,d5.w)
; End of function sub_72A5A

; ===========================================================================

loc_72A64:
		bra.w	loc_72ACC
; ===========================================================================
		bra.w	loc_72AEC
; ===========================================================================
		bra.w	loc_72AF2
; ===========================================================================
		bra.w	loc_72AF8
; ===========================================================================
		bra.w	loc_72B14
; ===========================================================================
		bra.w	loc_72B9E
; ===========================================================================
		bra.w	loc_72BA4
; ===========================================================================
		bra.w	loc_72BAE
; ===========================================================================
		bra.w	loc_72BB4
; ===========================================================================
		bra.w	loc_72BBE
; ===========================================================================
		bra.w	loc_72BC6
; ===========================================================================
		bra.w	loc_72BD0
; ===========================================================================
		bra.w	loc_72BE6
; ===========================================================================
		bra.w	loc_72BEE
; ===========================================================================
		bra.w	loc_72BF4
; ===========================================================================
		bra.w	loc_72C26
; ===========================================================================
		bra.w	loc_72D30
; ===========================================================================
		bra.w	loc_72D52
; ===========================================================================
		bra.w	loc_72D58
; ===========================================================================
		bra.w	loc_72E06
; ===========================================================================
		bra.w	loc_72E20
; ===========================================================================
		bra.w	loc_72E26
; ===========================================================================
		bra.w	loc_72E2C
; ===========================================================================
		bra.w	loc_72E38
; ===========================================================================
		bra.w	loc_72E52
; ===========================================================================
		bra.w	loc_72E64
; ===========================================================================

loc_72ACC:				; XREF: loc_72A64
		move.b	(a4)+,d1
		tst.b	1(a5)
		bmi.s	locret_72AEA
		move.b	$A(a5),d0
		andi.b	#$37,d0
		or.b	d0,d1
		move.b	d1,$A(a5)
		move.b	#$B4,d0
		bra.w	loc_72716
; ===========================================================================

locret_72AEA:
		rts
; ===========================================================================

loc_72AEC:				; XREF: loc_72A64
		move.b	(a4)+,$1E(a5)
		rts
; ===========================================================================

loc_72AF2:				; XREF: loc_72A64
		move.b	(a4)+,7(a6)
		rts
; ===========================================================================

loc_72AF8:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		movea.l	(a5,d0.w),a4
		move.l	#0,(a5,d0.w)
		addq.w	#2,a4
		addq.b	#4,d0
		move.b	d0,$D(a5)
		rts
; ===========================================================================

loc_72B14:				; XREF: loc_72A64
		movea.l	a6,a0
		lea	$3A0(a6),a1
		move.w	#$87,d0

loc_72B1E:
		move.l	(a1)+,(a0)+
		dbf	d0,loc_72B1E

		bset	#2,$40(a6)
		movea.l	a5,a3
		move.b	#$28,d6
		sub.b	$26(a6),d6
		moveq	#5,d7
		lea	$70(a6),a5

loc_72B3A:
		btst	#7,(a5)
		beq.s	loc_72B5C
		bset	#1,(a5)
		add.b	d6,9(a5)
		btst	#2,(a5)
		bne.s	loc_72B5C
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		jsr	sub_72C4E(pc)

loc_72B5C:
		adda.w	#$30,a5
		dbf	d7,loc_72B3A

		moveq	#2,d7

loc_72B66:
		btst	#7,(a5)
		beq.s	loc_72B78
		bset	#1,(a5)
		jsr	sub_729A0(pc)
		add.b	d6,9(a5)

loc_72B78:
		adda.w	#$30,a5
		dbf	d7,loc_72B66
		movea.l	a3,a5
		move.b	#$80,$24(a6)
		move.b	#$28,$26(a6)
		clr.b	$27(a6)
		move.w	#0,($A11100).l
		addq.w	#8,sp
		rts
; ===========================================================================

loc_72B9E:				; XREF: loc_72A64
		move.b	(a4)+,2(a5)
		rts
; ===========================================================================

loc_72BA4:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		bra.w	sub_72CB4
; ===========================================================================

loc_72BAE:				; XREF: loc_72A64
		bset	#4,(a5)
		rts
; ===========================================================================

loc_72BB4:				; XREF: loc_72A64
		move.b	(a4),$12(a5)
		move.b	(a4)+,$13(a5)
		rts
; ===========================================================================

loc_72BBE:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,8(a5)
		rts
; ===========================================================================

loc_72BC6:				; XREF: loc_72A64
		move.b	(a4),2(a6)
		move.b	(a4)+,1(a6)
		rts
; ===========================================================================

loc_72BD0:				; XREF: loc_72A64
		lea	$40(a6),a0
		move.b	(a4)+,d0
		moveq	#$30,d1
		moveq	#9,d2

loc_72BDA:
		move.b	d0,2(a0)
		adda.w	d1,a0
		dbf	d2,loc_72BDA

		rts
; ===========================================================================

loc_72BE6:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		rts
; ===========================================================================

loc_72BEE:				; XREF: loc_72A64
		clr.b	$2C(a6)
		rts
; ===========================================================================

loc_72BF4:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		jsr	sub_726FE(pc)
		tst.b	$250(a6)
		bmi.s	loc_72C22
		movea.l	a5,a3
		lea	$100(a6),a5
		movea.l	$18(a6),a1
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5

loc_72C22:
		addq.w	#8,sp
		rts
; ===========================================================================

loc_72C26:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	d0,$B(a5)
		btst	#2,(a5)
		bne.w	locret_72CAA
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.s	sub_72C4E
		movea.l	$20(a5),a1
		tst.b	$E(a6)
		bmi.s	sub_72C4E
		movea.l	$20(a6),a1

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72C4E:				; XREF: Snd_FadeOut1; et al
		subq.w	#1,d0
		bmi.s	loc_72C5C
		move.w	#$19,d1

loc_72C56:
		adda.w	d1,a1
		dbf	d0,loc_72C56

loc_72C5C:
		move.b	(a1)+,d1
		move.b	d1,$1F(a5)
		move.b	d1,d4
		move.b	#$B0,d0
		jsr	sub_72722(pc)
		lea	byte_72D18(pc),a2
		moveq	#$13,d3

loc_72C72:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		jsr	sub_72722(pc)
		dbf	d3,loc_72C72
		moveq	#3,d5
		andi.w	#7,d4
		move.b	byte_72CAC(pc,d4.w),d4
		move.b	9(a5),d3

loc_72C8C:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.s	loc_72C96
		add.b	d3,d1

loc_72C96:
		jsr	sub_72722(pc)
		dbf	d5,loc_72C8C
		move.b	#$B4,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

locret_72CAA:
		rts
; End of function sub_72C4E

; ===========================================================================
byte_72CAC:	dc.b 8,	8, 8, 8, $A, $E, $E, $F

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72CB4:				; XREF: sub_72504; sub_7267C; loc_72BA4
		btst	#2,(a5)
		bne.s	locret_72D16
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.s	loc_72CD8
		movea.l	$20(a6),a1
		tst.b	$E(a6)
		bmi.s	loc_72CD8
		movea.l	$20(a6),a1

loc_72CD8:
		subq.w	#1,d0
		bmi.s	loc_72CE6
		move.w	#$19,d1

loc_72CE0:
		adda.w	d1,a1
		dbf	d0,loc_72CE0

loc_72CE6:
		adda.w	#$15,a1
		lea	byte_72D2C(pc),a2
		move.b	$1F(a5),d0
		andi.w	#7,d0
		move.b	byte_72CAC(pc,d0.w),d4
		move.b	9(a5),d3
		bmi.s	locret_72D16
		moveq	#3,d5

loc_72D02:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.s	loc_72D12
		add.b	d3,d1
		bcs.s	loc_72D12
		jsr	sub_72722(pc)

loc_72D12:
		dbf	d5,loc_72D02

locret_72D16:
		rts
; End of function sub_72CB4

; ===========================================================================
byte_72D18:	dc.b $30, $38, $34, $3C, $50, $58, $54,	$5C, $60, $68
		dc.b $64, $6C, $70, $78, $74, $7C, $80,	$88, $84, $8C
byte_72D2C:	dc.b $40, $48, $44, $4C
; ===========================================================================

loc_72D30:				; XREF: loc_72A64
		bset	#3,(a5)
		move.l	a4,$14(a5)
		move.b	(a4)+,$18(a5)
		move.b	(a4)+,$19(a5)
		move.b	(a4)+,$1A(a5)
		move.b	(a4)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)
		rts
; ===========================================================================

loc_72D52:				; XREF: loc_72A64
		bset	#3,(a5)
		rts
; ===========================================================================

loc_72D58:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		tst.b	1(a5)
		bmi.s	loc_72D74
		tst.b	8(a6)
		bmi.w	loc_72E02
		jsr	sub_726FE(pc)
		bra.s	loc_72D78
; ===========================================================================

loc_72D74:
		jsr	sub_729A0(pc)

loc_72D78:
		tst.b	$E(a6)
		bpl.w	loc_72E02
		clr.b	0(a6)
		moveq	#0,d0
		move.b	1(a5),d0
		bmi.s	loc_72DCC
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		cmpi.b	#4,d0
		bne.s	loc_72DA8
		tst.b	$340(a6)
		bpl.s	loc_72DA8
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.s	loc_72DB8
; ===========================================================================

loc_72DA8:
		subq.b	#2,d0
		lsl.b	#2,d0
		movea.l	(a0,d0.w),a5
		tst.b	(a5)
		bpl.s	loc_72DC8
		movea.l	$18(a6),a1

loc_72DB8:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_72DC8:
		movea.l	a3,a5
		bra.s	loc_72E02
; ===========================================================================

loc_72DCC:
		lea	$370(a6),a0
		tst.b	(a0)
		bpl.s	loc_72DE0
		cmpi.b	#$E0,d0
		beq.s	loc_72DEA
		cmpi.b	#$C0,d0
		beq.s	loc_72DEA

loc_72DE0:
		lea	dword_722CC(pc),a0
		lsr.b	#3,d0
		movea.l	(a0,d0.w),a0

loc_72DEA:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.s	loc_72E02
		move.b	$1F(a0),($C00011).l

loc_72E02:
		addq.w	#8,sp
		rts
; ===========================================================================

loc_72E06:				; XREF: loc_72A64
		move.b	#$E0,1(a5)
		move.b	(a4)+,$1F(a5)
		btst	#2,(a5)
		bne.s	locret_72E1E
		move.b	-1(a4),($C00011).l

locret_72E1E:
		rts
; ===========================================================================

loc_72E20:				; XREF: loc_72A64
		bclr	#3,(a5)
		rts
; ===========================================================================

loc_72E26:				; XREF: loc_72A64
		move.b	(a4)+,$B(a5)
		rts
; ===========================================================================

loc_72E2C:				; XREF: loc_72A64
		move.b	(a4)+,d0
		lsl.w	#8,d0
		move.b	(a4)+,d0
		adda.w	d0,a4
		subq.w	#1,a4
		rts
; ===========================================================================

loc_72E38:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	(a4)+,d1
		tst.b	$24(a5,d0.w)
		bne.s	loc_72E48
		move.b	d1,$24(a5,d0.w)

loc_72E48:
		subq.b	#1,$24(a5,d0.w)
		bne.s	loc_72E2C
		addq.w	#2,a4
		rts
; ===========================================================================

loc_72E52:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		subq.b	#4,d0
		move.l	a4,(a5,d0.w)
		move.b	d0,$D(a5)
		bra.s	loc_72E2C
; ===========================================================================

loc_72E64:				; XREF: loc_72A64
		move.b	#$88,d0
		move.b	#$F,d1
		jsr	sub_7272E(pc)
		move.b	#$8C,d0
		move.b	#$F,d1
		bra.w	sub_7272E
; ===========================================================================
Calculate_PCM:
		move.w	d0,d1
		subi.w	#$81,d1
		add.w	d1,d1
		add.w	d1,d1
		move.w	d1,d2
		add.w	d1,d1
		add.w	d2,d1
		lea	PCM_Table(pc,d1.w),a2
		movea.l	(a2),a1
		move.l	4(a2),d1	; Get address of the PCM sample
		move.w  d1,d2			; Move it to d2
		lsr.l	#8,d1			; Divide d1 by $100
		andi.w	#$FF80,d1		; Get upper 9 bits
		tst.w	d2				; Test lower 16 bits of PCM sample address
		bmi.s	Calc_PCM2		; If negative already, branch
		addi.w	#$8000,d2		; otherwise, add $8000 to make it negative

Calc_PCM2:
		move.b  d1,5(a1)	; Move lower byte of d1 to bank byte 1 of table
		lsr.w	#8,d1		; shift right by 8
		move.b  d1,6(a1)	; Move upper byte of d1 to bank byte 2 of table
		move.b  d2,(a1)	; Move lower byte of d2 to location byte 1 of table
		lsr.w	#8,d2		; Shift right by 8
		move.b  d2,1(a1)	; Move upper byte of d2 to location byte 2 of table
		move.b  9(a2),2(a1)	; Move lower byte of whatever size value you want into size byte 1 of table
		move.b  8(a2),3(a1)	; Move upper byte of whatever size value you want into size byte 2 of table
		move.b  $A(a2),4(a1)	; Move sample rate/pitch into pitch byte of table
		move.b $B(a2),7(a1)	; Move number of banks to span into byte 7 of table. NOTE: only applicable to multi-bank PCMs. uncomment only i you are setting one up
		rts
;--------------------------------------------------------
PCM_Table:	dc.l	$A00200, DAC1
		dc.w	$352
		dc.b	$19,0
		dc.l	$A00208, DAC2
		dc.w	$770
		dc.b	$4,0
		dc.l	$A00210, DAC3
		dc.w	$576
		dc.b	$8,0
		dc.l	$A00218, DAC4
		dc.w	$BB5
		dc.b	$A,0
		dc.l	$A00220, DAC5
		dc.w	$1016
		dc.b	$1D,0
		dc.l	$A00228, DAC6
		dc.w	$622
		dc.b	$C,0
		dc.l	$A00230, DAC7
		dc.w	$5C4
		dc.b	$1D,0
;--------------------------------------------------------
Kos_Z80: BINCLUDE	sound\z80_new.bin
		;BINCLUDE	sound\z80_1.bin
		;dc.w ((SegaPCM&$FF)<<8)+((SegaPCM&$FF00)>>8)
		;dc.b $21
		;dc.w (((EndOfRom-SegaPCM)&$FF)<<8)+(((EndOfRom-SegaPCM)&$FF00)>>8)
		;BINCLUDE	sound\z80_2.bin
		even
Music81:	BINCLUDE	sound\music81.bin
		even
Music82:	BINCLUDE	sound\music82.bin
		even
Music83:	BINCLUDE	sound\music83.bin
		even
Music84:	BINCLUDE	sound\music84.bin
		even
Music85:	BINCLUDE	sound\music85.bin
		even
Music86:	BINCLUDE	sound\music86.bin
		even
Music87:	BINCLUDE	sound\music87.bin
		even
Music88:	BINCLUDE	sound\music88.bin
		even
Music89:	BINCLUDE	sound\music89.bin
		even
Music8A:	BINCLUDE	sound\music8A.bin
		even
Music8B:	BINCLUDE	sound\music8B.bin
		even
Music8C:	BINCLUDE	sound\music8C.bin
		even
Music8D:	BINCLUDE	sound\music8D.bin
		even
Music8E:	BINCLUDE	sound\music8E.bin
		even
Music8F:	BINCLUDE	sound\music8F.bin
		even
Music90:	BINCLUDE	sound\music90.bin
		even
Music91:	BINCLUDE	sound\music91.bin
		even
Music92:	BINCLUDE	sound\music92.bin
		even
Music93:	BINCLUDE	sound\music93.bin
		even
Music94:	BINCLUDE	sound\music94.bin
		even
Music95:	BINCLUDE	sound\music95.bin
		even
Music96:	BINCLUDE	sound\music96.bin
		even
Music97:	BINCLUDE	sound\music97.bin
		even
Music98:	BINCLUDE	sound\music98.bin
		even
Music99:	BINCLUDE	sound\music99.bin
		even
Music9A:	BINCLUDE	sound\music9A.bin
		even
Music9B:	BINCLUDE	sound\music9B.bin
		even
Music9C:	BINCLUDE	sound\music9C.bin
		even
Music9D:	BINCLUDE	sound\music9D.bin
		even
Music9E:	BINCLUDE	sound\music9E.bin
		even
Music9F:	BINCLUDE	sound\music9F.bin
		even
; ---------------------------------------------------------------------------
; Sound	effect pointers
; ---------------------------------------------------------------------------
SoundIndex:
SndPtr_Jump:		dc.l SoundA0
SndPtr_Checkpoint:		dc.l SoundA1
SndPtr_SpikeSwitch:		dc.l SoundA2
SndPtr_Hurt:		dc.l SoundA3
SndPtr_Skidding:		dc.l SoundA4
SndPtr_BlockPush:		dc.l SoundA5
SndPtr_HurtBySpikes:		dc.l SoundA6
SndPtr_Sparkle:		dc.l SoundA7
SndPtr_Beep:		dc.l SoundA8
SndPtr_Bwoop:		dc.l SoundA9
SndPtr_Splash:		dc.l SoundAA
SndPtr_Swish:		dc.l SoundAB
SndPtr_BossHit:		dc.l SoundAC
SndPtr_InhalingBubble:		dc.l SoundAD
SndPtr_ArrowFiring:		dc.l SoundAE
SndPtr_Shield:		dc.l SoundAF
SndPtr_LaserBeam:		dc.l SoundB0
SndPtr_Zap:		dc.l SoundB1
SndPtr_Drown:		dc.l SoundB2
SndPtr_FireBurn:		dc.l SoundB3
SndPtr_Bumper:		dc.l SoundB4
SndPtr_Ring:		dc.l SoundB5
SndPtr_SpikesMove:		dc.l SoundB6
SndPtr_Rumbling:		dc.l SoundB7
		dc.l SoundB8
SndPtr_Smash:		dc.l SoundB9
		dc.l SoundBA
SndPtr_DoorSlam:		dc.l SoundBB
SndPtr_SpindashRelease:		dc.l SoundBC
SndPtr_Hammer:		dc.l SoundBD
SndPtr_Roll:		dc.l SoundBE
SndPtr_ContinueJingle:		dc.l SoundBF
SndPtr_CasinoBonus:		dc.l SoundC0
SndPtr_Explosion:		dc.l SoundC1
SndPtr_WaterWarning:		dc.l SoundC2
SndPtr_EnterGiantRing:		dc.l SoundC3
SndPtr_BossExplosion:		dc.l SoundC4
SndPtr_TallyEnd:		dc.l SoundC5
SndPtr_RingSpill:		dc.l SoundC6
		dc.l SoundC7
SndPtr_Flamethrower:		dc.l SoundC8
SndPtr_Bonus:		dc.l SoundC9
SndPtr_SpecStageEntry:		dc.l SoundCA
SndPtr_SlowSmash:		dc.l SoundCB
SndPtr_Spring:		dc.l SoundCC
SndPtr_Blip:		dc.l SoundCD
SndPtr_RingLeft:		dc.l SoundCE
SndPtr_Signpost:		dc.l SoundCF
SndPtr_CNZBossZap:		dc.l SoundD0
		dc.l SoundD1
		dc.l SoundD2
SndPtr_Signpost2P:		dc.l SoundD3
SndPtr_OOZLidPop:		dc.l SoundD4
SndPtr_SlidingSpike:		dc.l SoundD5
SndPtr_CNZElevator:		dc.l SoundD6
SndPtr_PlatformKnock:		dc.l SoundD7
SndPtr_BonusBumper:		dc.l SoundD8
SndPtr_LargeBumper:		dc.l SoundD9
SndPtr_Gloop:		dc.l SoundDA
SndPtr_PreArrowFiring:		dc.l SoundDB
SndPtr_Fire:		dc.l SoundDC
SndPtr_ArrowStick:		dc.l SoundDD
SndPtr_Helicopter:		dc.l SoundDE
SndPtr_SuperTransform:		dc.l SoundDF

SoundIndex_E0plus:
SndPtr_SpindashRev:		dc.l SoundE0
SndPtr_Rumbling2:		dc.l SoundE1
SndPtr_CNZLaunch:		dc.l SoundE2
SndPtr_Flipper:		dc.l SoundE3
SndPtr_HTZLiftClick:		dc.l SoundE4
SndPtr_Leaves:		dc.l SoundE5
SndPtr_MegaMackDrop:		dc.l SoundE6
SndPtr_DrawbridgeMove:		dc.l SoundE7
SndPtr_QuickDoorSlam:		dc.l SoundE8
SndPtr_DrawbridgeDown:		dc.l SoundE9
SndPtr_LaserBurst:		dc.l SoundEA
SndPtr_Scatter:		dc.l SoundEB
SndPtr_Teleport:		dc.l SoundEC
SndPtr_Error:		dc.l SoundED
SndPtr_MechaSonicBuzz:		dc.l SoundEE
SndPtr_LargeLaser:		dc.l SoundEF
SndPtr_OilSlide:		dc.l SoundF0
		dc.l	SoundF1
		dc.l	SoundF2
		dc.l	SoundF3
		dc.l	SoundF4
		dc.l	SoundF5
		dc.l	SoundF6
		dc.l	SoundF7

SoundD0Index:

SoundA0:	BINCLUDE	sound\soundA0.bin
		even
SoundA1:	BINCLUDE	sound\soundA1.bin
		even
SoundA2:	BINCLUDE	sound\soundA2.bin
		even
SoundA3:	BINCLUDE	sound\soundA3.bin
		even
SoundA4:	BINCLUDE	sound\soundA4.bin
		even
SoundA5:	BINCLUDE	sound\soundA5.bin
		even
SoundA6:	BINCLUDE	sound\soundA6.bin
		even
SoundA7:	BINCLUDE	sound\soundA7.bin
		even
SoundA8:	BINCLUDE	sound\soundA8.bin
		even
SoundA9:	BINCLUDE	sound\soundA9.bin
		even
SoundAA:	BINCLUDE	sound\soundAA.bin
		even
SoundAB:	BINCLUDE	sound\soundAB.bin
		even
SoundAC:	BINCLUDE	sound\soundAC.bin
		even
SoundAD:	BINCLUDE	sound\soundAD.bin
		even
SoundAE:	BINCLUDE	sound\soundAE.bin
		even
SoundAF:	BINCLUDE	sound\soundAF.bin
		even
SoundB0:	BINCLUDE	sound\soundB0.bin
		even
SoundB1:	BINCLUDE	sound\soundB1.bin
		even
SoundB2:	BINCLUDE	sound\soundB2.bin
		even
SoundB3:	BINCLUDE	sound\soundB3.bin
		even
SoundB4:	BINCLUDE	sound\soundB4.bin
		even
SoundB5:	BINCLUDE	sound\soundB5.bin
		even
SoundB6:	BINCLUDE	sound\soundB6.bin
		even
SoundB7:	BINCLUDE	sound\soundB7.bin
		even
SoundB8:	BINCLUDE	sound\soundB8.bin
		even
SoundB9:	BINCLUDE	sound\soundB9.bin
		even
SoundBA:	BINCLUDE	sound\soundBA.bin
		even
SoundBB:	BINCLUDE	sound\soundBB.bin
		even
SoundBC:	BINCLUDE	sound\soundBC.bin
		even
SoundBD:	BINCLUDE	sound\soundBD.bin
		even
SoundBE:	BINCLUDE	sound\soundBE.bin
		even
SoundBF:	BINCLUDE	sound\soundBF.bin
		even
SoundC0:	BINCLUDE	sound\soundC0.bin
		even
SoundC1:	BINCLUDE	sound\soundC1.bin
		even
SoundC2:	BINCLUDE	sound\soundC2.bin
		even
SoundC3:	BINCLUDE	sound\soundC3.bin
		even
SoundC4:	BINCLUDE	sound\soundC4.bin
		even
SoundC5:	BINCLUDE	sound\soundC5.bin
		even
SoundC6:	BINCLUDE	sound\soundC6.bin
		even
SoundC7:	BINCLUDE	sound\soundC7.bin
		even
SoundC8:	BINCLUDE	sound\soundC8.bin
		even
SoundC9:	BINCLUDE	sound\soundC9.bin
		even
SoundCA:	BINCLUDE	sound\soundCA.bin
		even
SoundCB:	BINCLUDE	sound\soundCB.bin
		even
SoundCC:	BINCLUDE	sound\soundCC.bin
		even
SoundCD:	BINCLUDE	sound\soundCD.bin
		even
SoundCE:	BINCLUDE	sound\soundCE.bin
		even
SoundCF:	BINCLUDE	sound\soundCF.bin
		even
SoundD0:	BINCLUDE	sound\soundD0.bin
		even
SoundD1:	BINCLUDE	sound\soundD1.bin
		even
SoundD2:	BINCLUDE	sound\soundD2.bin
		even
SoundD3:	BINCLUDE	sound\soundD3.bin
		even
SoundD4:	BINCLUDE	sound\soundD4.bin
		even
SoundD5:	BINCLUDE	sound\soundD5.bin
		even
SoundD6:	BINCLUDE	sound\soundD6.bin
		even
SoundD7:	BINCLUDE	sound\soundD7.bin
		even
SoundD8:	BINCLUDE	sound\soundD8.bin
		even
SoundD9:	BINCLUDE	sound\soundD9.bin
		even
SoundDA:	BINCLUDE	sound\soundDA.bin
		even
SoundDB:	BINCLUDE	sound\soundDB.bin
		even
SoundDC:	BINCLUDE	sound\soundDC.bin
		even
SoundDD:	BINCLUDE	sound\soundDD.bin
		even
SoundDE:	BINCLUDE	sound\soundDE.bin
		even
SoundDF:	BINCLUDE	sound\soundDF.bin
		even
SoundE0:	BINCLUDE	sound\soundE0.bin
		even
SoundE1:	BINCLUDE	sound\soundE1.bin
		even
;SoundE2:	BINCLUDE	sound\soundE2.bin
;		even
;SoundE3:	BINCLUDE	sound\soundE3.bin
;		even
;SoundE4:	BINCLUDE	sound\soundE4.bin
;		even
SoundE5:	BINCLUDE	sound\soundE5.bin
		even
SoundE6:	BINCLUDE	sound\soundE6.bin
		even
SoundE7:	BINCLUDE	sound\soundE7.bin
		even
SoundE8:	BINCLUDE	sound\soundE8.bin
		even
SoundE9:	BINCLUDE	sound\soundE9.bin
		even
SoundEA:	BINCLUDE	sound\soundEA.bin
		even
SoundEB:	BINCLUDE	sound\soundEB.bin
		even
SoundEC:	BINCLUDE	sound\soundEC.bin
		even
SoundED:	BINCLUDE	sound\soundED.bin
		even
SoundEE:	BINCLUDE	sound\soundEE.bin
		even
SoundEF:	BINCLUDE	sound\soundEF.bin
		even
SoundF0:	BINCLUDE	sound\soundF0.bin
		even
SoundF1:	BINCLUDE	sound/sound_s3tailsfly(2).bin
		even
SoundF2:	BINCLUDE	sound/sound_s3tailstired.bin
		even
SoundF3:	BINCLUDE	sound/Sound73.bin
		even
SoundF4:	BINCLUDE	sound/Sound74.bin
		even
SoundF5:	BINCLUDE	sound/fire_get.bin
		even
SoundF6:	BINCLUDE	sound/electric_get.bin
		even
SoundF7:	BINCLUDE	sound/bubble_get.bin
		even
SoundE2:	BINCLUDE	sound/fire_use.bin
		even
SoundE3:	BINCLUDE	sound/electric_use.bin
		even
SoundE4:	BINCLUDE	sound/bubble_use.bin
		even

		cnop $0, (((((*+$6978)>>$10)+$01)*$10000)-$6978)
SegaPCM:	BINCLUDE	sound\segapcm.bin
		even

		align $8000
DAC1: BINCLUDE sound\dac1d.bin
		even
DAC2: BINCLUDE sound\dac2d.bin
		even
DAC3: BINCLUDE sound\dac3d.bin
		even
DAC4: BINCLUDE sound\dac4d.bin
		even
DAC5: BINCLUDE sound\dac5d.bin
		even
DAC6: BINCLUDE sound\dac6d.bin
		even
DAC7: BINCLUDE sound\dac7d.bin
		even
; ===========================================================================
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to clear EVERYTHING
; ---------------------------------------------------------------------------

ClearAll:
		move.b	#MusID_FadeOut,d0		; load "Fade out" sfx
		jsr	PlaySound			; play sfx

ClearAll_RetainBGM:
		jsr	Pal_FadeFrom			; fade pallets out
		jsr	ClearScreen			; clear screen art
		jsr	ClearPLC			; clear Pattern Load Cues
		move	#$2700,sr			; ???
		lea	($FFFFD000).w,a1		; set starting address for clearing
		moveq	#$00,d0				; clear d0
		move.w	#$07FF,d1			; load repeat times

Clear_ObjectRAM:
		move.l	#$00000000,(a1)+		; clear set address and move a longword forward for next clear
		dbf	d1,Clear_ObjectRAM 		; repeat proccess
		rts					; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to map art to a screen
; ---------------------------------------------------------------------------

MapScreen:
		lea	($C00000).l,a6			; load "Vram location"

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Settings
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; d0		; temp use		=	for examining the "enigma mapping setout" for POS and NEG
; a1		; enigma mapping setout	=	Screen mappings for the screen
; a6		; Vram location		=	the location in the RAM where the art is to be loaded
; d4		; mapping possition	=	Where to place the "enigma mapping setout"
; d1		; X loop		=	number of Y to read down on the "enigma mapping setout"
; d2		; Y loop		=	number of X to read along on the "enigma mapping setout"

; an example of what to put BEFORE using this routine

	;	move.l	#$40000000,($C00004).l		; set "Vram location" to load art to
	;	lea	(BackGround_Art).l,a0 		; load "Nemesis art" to (a0)
	;	jsr	NemDec				; Decompress "Nemesis art" addressed in (a0) and put in "Vram location" set
	;	move.l	#$60000003,d4			; code 1 (Plane 6 Low 4 High) code 2/3 (X/Y position on screen)
	;	lea	(BackGround_Mappings).l,a1	; load "enigma mapping setout"
	;	moveq	#$27,d3				; set "X loop"
	;	moveq	#$1B,d2				; set "Y loop"
	;	jsr	MapScreen	;;;; JUMP TO THIS ROUTINE ;;;;

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

MapScreen_Loop:
		move.l	d4,4(a6)			; set "mapping possition" to address (a6)
		move.w	d3,d1				; load "X loop"

XMappingLoop:
		moveq	#$00,d0				; clear d0
		move.w	(a1)+,d0			; load "enigma mapping setout", then move up 1 word (For next single tile map)
		bpl.s	XMap_Possitive			; if current tile map is possitive, branch

XMap_Negative:
		clr.w	(a6)				; clear a word of "Vram location"
		dbf	d1,XMappingLoop			; restart mapping Use "X loop"
		addi.l	#$800000,d4			; add 800000 to "mapping possition" (Set for next line)
		dbf	d2,MapScreen_Loop		; restart mapping Use "Y loop"
		rts					; return

XMap_Possitive:
		move.w	d0,(a6)				; load current tile map to "Vram location"
		dbf	d1,XMappingLoop			; restart mapping Use "X loop"
		addi.l	#$800000,d4			; add 800000 to "mapping possition" (Set for next line)
		dbf	d2,MapScreen_Loop		; restart mapping Use "Y loop"
		rts					; return

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to map a 2nd plane of art to a screen
; ---------------------------------------------------------------------------

MapScreen2:

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Settings
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; d0		; temp use		=	for examining the "uncompressed mappings" for POS and NEG
; a1		; enigma mapping setout	=	Screen mappings for the screen
; a6		; Vram location		=	the location in the RAM where the art is to be loaded
; d4		; mapping possition	=	Where to place the "uncompressed mappings"
; d1		; X loop		=	number of Y to read down on the "uncompressed mappings"
; d2		; Y loop		=	number of X to read along on the "uncompressed mappings"

; an example of what to put BEFORE using this routine

	;	move.w	#$0000,d5			; load correct art
	;	lea	(BackGround_2ndMappings).l,a1	; load uncompressed mappings to a1
	;	moveq	#$27,d3				; set "X loop"
	;	moveq	#$1B,d2				; set "Y loop"
	;	lea	($C00000).l,a6			; load "Vram location"
	;	move.l	#$40000003,d4			; code 1 (Plane 6 Low 4 High) code 2/3 (X/Y position on screen)
	;	jsr	MapScreen2	;;;; JUMP TO THIS ROUTINE ;;;;

; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

MapScreen2_Loop:
		move.l	d4,4(a6)
		move.w	d3,d1				; load "X loop"

XMapping2Loop:
		moveq	#0,d0
		move.b	(a1)+,d0
		bpl.s	XMap2_Possitive

XMap2_Negative:
		clr.w	(a6)
		dbf	d1,XMapping2Loop
		addi.l	#$800000,d4
		dbf	d2,MapScreen2_Loop
		rts

XMap2_Possitive:
		add.w	d5,d0
		move.w	d0,(a6)
		dbf	d1,XMapping2Loop
		addi.l	#$800000,d4
		dbf	d2,MapScreen2_Loop
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to enable objects to be loaded
; ---------------------------------------------------------------------------

LoadObjects:
		lea	($FFFFD000).w,a0 			; set object address
		moveq	#2,d7					; set 7F objects to check for
		moveq	#0,d0					; clear d0

LoadCore:
		move.b	(a0),d0					; load object code
		beq.s	LoadBypass				; if the answer is 00, branch
		add.w	d0,d0					; double d0
		add.w	d0,d0					; double d0
		movea.l	CoreLocation-4(pc,d0.w),a1		; get correct object routine
		jsr	(a1)					; start object's routine
		moveq	#0,d0					; clear d0

LoadBypass:
		lea	$40(a0),a0				; load the next 40th byte (Next object) to a0
		dbf	d7,LoadCore				; repeat until 7F object's have been checked for in object ram
		rts

CoreLocation:
		dc.l	SaveMenu_Obj				; Save Manu Objects (ID 01)
		dc.l	SaveMenu_Obj
		dc.l	SaveMenu_Obj
		even						; even the table
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine translating object	speed to update	object position
; (FOR OBJECTS WITH DIFFERENT X & Y POSSITION LOCATIONS)
; ---------------------------------------------------------------------------

SpeedToPos2:
		move.l	$08(a0),d2	; laod object's X position
		move.l	$0A(a0),d3	; load object's Y position

		move.w	$10(a0),d0	; load horizontal speed
		ext.l	d0		; extend
		asl.l	#8,d0		; multiply speed by $100
		add.l	d0,d2		; add to x-axis	position

		move.w	$12(a0),d0	; load vertical	speed
		ext.l	d0		; extend
		asl.l	#8,d0		; multiply by $100
		add.l	d0,d3		; add to y-axis	position

		move.l	d2,$08(a0)	; update x-axis	position
		move.l	d3,$0A(a0)	; update y-axis	position
		rts
; ===========================================================================
; $200001 - Slot used flag
; $200003 - Character ID
; $200005 - Current Zone
; $200007 - Current Act
; $200009 - Lives










; ===========================================================================
; ---------------------------------------------------------------------------
; Options Menu
; ---------------------------------------------------------------------------

SaveMenu_DXI:
	; == Clearing ==================================
		jsr	ClearAll

	; == Art Loading ===============================
		move.l	#$40000000,($C00004).l		; set "Vram location" to load art to
		lea	(SaveMenu_Art).l,a0 		; load "Nemesis art" to (a0)
		jsr	NemDec				; Decompress "Nemesis art" addressed in (a0) and put in "Vram location" set

	; == Mapping ===================================
		move.l	#$60000003,d4			; code 1 (Plane 6 Low 4 High) code 2/3 (X/Y position on screen)
		lea	(SaveMenu_Map).l,a1		; load "enigma mapping setout"
		moveq	#$27,d3				; set "X loop"
		moveq	#$1B,d2				; set "Y loop"
		jsr	MapScreen			; map the screen

	; == Mapping 2nd Plane =========================
		move.w	#$0000,d5			; load correct art
		lea	(SaveMenu_Map2).l,a1		; load uncompressed mappings to a1
		moveq	#$27,d3				; set "X loop"
		moveq	#$1B,d2				; set "Y loop"
		lea	($C00000).l,a6			; load "Vram location"
		move.l	#$40000003,d4			; code 1 (Plane 6 Low 4 High) code 2/3 (X/Y position on screen)
		jsr	MapScreen2			; map 2nd screen

	; == Object Loading ============================
	; ----------------------------------------------
		move.b	#$01,($FFFFD000).w		; load Save Menu objects (ID 01)
		move.b	#$00,($FFFFD028).w		; load Object 00 (temp words on screen)
		move.b	#$01,($FFFFD040).w		; load Save Menu objects (ID 01)
		move.b	#2,($FFFFD068).w		; load Object 01 (temp selector)
		move.b	#1,($FFFFD080).w
		move.b	#4,($FFFFD0A8).w
	; ----------------------------------------------
		jsr	LoadObjects			; load objects
		jsr	BuildSprites			; build the objects

	; == Finalize ==================================
		move.b	#$90,d0				; load music
		jsr	PlayMusic			; play music
		moveq	#$09,d0				; set pallet ID to load
		jsr	PalLoad1			; load pallet ID
		jsr	Pal_FadeTo			; fade pallets in

	; == Start Options =============================
		jmp	SMDXI_MainLoop

; ---------------------------------------------------------------------------
SaveMenu_Pal:	Binclude	_menu\SaveMenu\SaveMenu_Pal.bin
		even
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
SaveMenu_Art:	Binclude	_menu\SaveMenu\SaveMenu_Art.bin
		even
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
SaveMenu_Map:	Binclude	_menu\SaveMenu\SaveMenu_Map.bin
		even
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
SaveMenu_Map2:	Binclude	_menu\SaveMenu\SaveMenu_Map2.bin
		even
; ---------------------------------------------------------------------------
; ===========================================================================
; ---------------------------------------------------------------------------
; Save Menu Main Loop
; ---------------------------------------------------------------------------

SMDXI_MainLoop:
		move.b	#$04,(Vint_routine).w		; set delay type
		jsr	WaitForVint			; delay menu (retains menu)
		jsr	LoadObjects			; load objects
		jsr	BuildSprites			; build the objects
		move.l	#$FFFFD080,a1			; load selector object's RAM to a1 (mal, Sinse the selector object contains what line it's on in $2A, you can use this to determin how to exit the Save Menu)
		cmp.b	#$01,$29(a1)			; has the selector been set to be selectable?
		bne.w	SMDXI_MainLoop			; if not, skip selectable optionms

		move.b	($FFFFF605).w,d0		; load unloackable pressed controls
		andi.b	#$70,d0				; is A,	B or C pressed?
		bne.w	returnBackTit			; if so, branch
		bra.w	SMDXI_MainLoop			; repeat menu functions

returnBackTit:
		cmp.b	#$09,$2A(a1)			; is selector object lower than 8?
		blt.s	StartLevelSlot			; if not, branch
		jmp	TitleScreen			; back to title

StartLevelSlot:
		lea	($200000).l,a2
		moveq	#0,d0
		move.b	$2A(a1),d0
		lsl.w	#5,d0
		adda.l	d0,a2
		tst.b	1(a2)
		beq.w	+
		move.w	#0,(Player_option).w
		move.b	3(a2),d2
		ext.w	d2
		move.w	d2,(Player_option).w
		moveq	#0,d0
		move.b	5(a2),d0
		ext.w	d0
		move.b	7(a2),d0
		move.b	9(a2),d4
		bra.s	++
+
		move.l	#$FFFFD040,a1
		move.w	#0,(Player_option).w
		moveq	#0,d2
		move.b	$2C(a1),d2
		ext.w	d2
		move.w	d2,(Player_option).w
		move.b	$2C(a1),3(a2)
		move.b	#1,1(a2)
		move.b	#3,9(a2)
		move.b	9(a2),d4
		moveq	#0,d0
+
		move.w	d0,(Current_ZoneAndAct).w
		move.b	#GameModeID_Level,(Game_Mode).w ; => Level (Zone play mode)
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Save Menu's Private Objects
; ---------------------------------------------------------------------------

SaveMenu_Obj:
		moveq	#0,d0					; clear d0
		move.b	$28(a0),d0				; load object ram 28
		add.w	d0,d0					; double d0
		;add.w	d0,d0					; double d0
		jmp	SvMn_Objcts(pc,d0.w)			; jump to correct object routine using object ram 28
		rts						; return

SvMn_Objcts:
		bra.w	SvMn_TempWords				; Object 00 - Temporary words on screen to test this damn routine works
		bra.w	SvMn_CharacterSelector				; Object 01 - Selector to show an example of a selector idk some bullshit
		bra.w	SvMn_SlotSelector
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 00 - Temporary words on screen to test this damn routine works
; ---------------------------------------------------------------------------

SvMn_TempWords:
		cmp.b	#$01,$29(a0)			; has object started?
		beq.s	SvMnTW_Started			; if so, branch
		move.w	#$010A,$08(a0)			; object's x possition 00 Defualt Left
		move.w	#$0085,$0C(a0)			; object's Y possition 80 Defualt Top
		move.w	#-$0A00,$10(a0)			; set object to move back at speed -800
		move.b	#$01,$29(a0)			; set object as started

SvMnTW_Started:
		cmp.w	#$000A,$08(a0)			; has object move to correct position?
		ble.w	SvMnTW_FinMove			; if so, branch
		add.w	#$0030,$10(a0)			; slow object down from moving left
		bra.w	SvMnTW_Show

SvMnTW_FinMove:
		move.l	#$FFFFD080,a1			; load selector object's RAM to a1 (mal, Sinse the selector object contains what line it's on in $2A, you can use this to determin how to exit the Save Menu)
		move.w	#$000A,$08(a0)			; set object's X position
		clr.w	$10(a0)				; stop object moving left or right
		move.b	#$01,$29(a1)			; set selector as selectable

SvMnTW_Show:
		jsr	ObjectMove			; jump to first one because Screen mode couldn't be set on the object
		move.l	#MapSvMnTW,$04(a0)		; load correct mappings
		move.w	#$0000,$02(a0)			; load correct art
		move.b	#$04,$01(a0)			; set object in (Level Mode) (For some reason Screen mode doesn't work, probably a difference in S2 no doubt)
		move.b	#$00,$18(a0)			; set object high plane
		move.b	#$00,$1A(a0)			; set first map

		jmp	DisplaySprite			; show the sprite
; ===========================================================================
MapSvMnTW:	dc.w	SvMnTW00-MapSvMnTW
SvMnTW00:	dc.b	$00,$32

	; FORMAT notes on object mapping for Dr.X.Insanity =P

		; SS =	Y position on map area (Same as S1)
		; TT =	Mapping Setout (Same as S1)
		; UU =	color & flip settings (Same as S1)
		; VV =	Tile in VRAM set ($02(a0)) to start loading from (Same as S1)
		; WW =	???
		; YY =	???
		; ZZ =	X position on map area (Same as S1)

		; S2 seems to be different at reading X values
		; SS =	80 Highest/7F Lowest
		; ZZ =	00 Far Left/FF Far Right


		;	$SS,$TT,$UU,$VV,$WW,$XX,$YY,$ZZ

								; START
		dc.b	$B0,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$B0,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$B0,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$B0,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$B0,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$C0,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$C0,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$C0,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$C0,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$C0,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$D0,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$D0,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$D0,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$D0,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$D0,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$E0,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$E0,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$E0,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$E0,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$E0,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$F0,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$F0,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$F0,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$F0,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$F0,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$0,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$0,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$0,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$0,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$0,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$10,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$10,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$10,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$10,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$10,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$20,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$20,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$20,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$20,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$20,$01,$00,$3B,$00,$00,$00,$80		; T

								; START
		dc.b	$30,$01,$00,$39,$00,$00,$00,$40		; S
		dc.b	$30,$01,$00,$3B,$00,$00,$00,$50		; T
		dc.b	$30,$01,$00,$15,$00,$00,$00,$60		; A
		dc.b	$30,$01,$00,$37,$00,$00,$00,$70		; R
		dc.b	$30,$01,$00,$3B,$00,$00,$00,$80		; T

								; TITLE
		dc.b	$40,$01,$00,$3B,$00,$00,$00,$40		; T
		dc.b	$40,$01,$00,$25,$00,$00,$00,$50		; I
		dc.b	$40,$01,$00,$3B,$00,$00,$00,$60		; T
		dc.b	$40,$01,$00,$2B,$00,$00,$00,$70		; L
		dc.b	$40,$01,$00,$1D,$00,$00,$00,$80		; E
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 01 - Selector to show an example of a selector idk some bullshit
; ---------------------------------------------------------------------------

SvMn_CharacterSelector:
		tst.b	$29(a0)			; has object started?
		bne.s	SvMnCSL_Started			; if so, branch
		move.w	#$0010,$08(a0)			; object's x possition 00 Defualt Left
		move.w	#$0068,$0C(a0)			; object's Y possition 80 Defualt Top
		move.b	#$01,$29(a0)			; set object as started

SvMnCSL_Started:
; ---------------------------------------------------------------------------
; controls
; ===========================================================================

		move.l	#$FFFFD080,a1
		tst.b	$2A(a1)
		bne.w	+
		tst.b	($200001).l
		bne.w	SMCSelSRAM1
+

		cmp.b	#1,$2A(a1)
		bne.w	+
		tst.b	($200021).l
		bne.w	SMCSelSRAM2
+

		cmp.b	#2,$2A(a1)
		bne.w	+
		tst.b	($200041).l
		bne.w	SMCSelSRAM3
+

		cmp.b	#3,$2A(a1)
		bne.w	+
		tst.b	($200061).l
		bne.w	SMCSelSRAM4
+

		cmp.b	#4,$2A(a1)
		bne.w	+
		tst.b	($200081).l
		bne.w	SMCSelSRAM5

+
		cmp.b	#5,$2A(a1)
		bne.w	+
		tst.b	($2000A1).l
		bne.w	SMCSelSRAM6

+
		cmp.b	#6,$2A(a1)
		bne.w	+
		tst.b	($2000C1).l
		bne.w	SMCSelSRAM7

+
		cmp.b	#7,$2A(a1)
		bne.w	+
		tst.b	($2000E1).l
		bne.w	SMCSelSRAM8
+
		btst	#2,($FFFFF605).w 		; is Left being pressed?
		bne.w	SMCSelLeft			; if so, branch
		btst	#3,($FFFFF605).w 		; is Right being pressed?
		bne.w	SMCSelRight			; if so, branch
		bra.w	ContinueToReposition		; if nothing is pressed, skip

SMCSelLeft:
		cmp.b	#$00,$2C(a0)			; is selector already set at far left?
		beq.w	SMCSelLeftRestart		; if so, skip (prevent alowing to go Left)
		sub.b	#$01,$2C(a0)			; set select to go left 1
		bra.w	ContinueToReposition		; continue object routine

SMCSelRight:
		cmp.b	#$03,$2C(a0)			; is selector already set at far right?
		beq.w	SMCSelRightRestart		; if so, skip (prevent alowing to go Right)
		add.b	#$01,$2C(a0)			; set select to go right 1
		bra.w	ContinueToReposition

SMCSelLeftRestart:
		move.b	#$03,$2C(a0)
		bra.w	ContinueToReposition
SMCSelRightRestart:
		move.b	#$00,$2C(a0)
		bra.w	ContinueToReposition


SMCSelSRAM1:
		move.b	($200003).l,$2C(a0)
		bra.w	ContinueToReposition
SMCSelSRAM2:
		move.b	($200023).l,$2C(a0)
		bra.w	ContinueToReposition
SMCSelSRAM3:
		move.b	($200043).l,$2C(a0)
		bra.w	ContinueToReposition
SMCSelSRAM4:
		move.b	($200063).l,$2C(a0)
		bra.w	ContinueToReposition
SMCSelSRAM5:
		move.b	($200083).l,$2C(a0)
		bra.w	ContinueToReposition
SMCSelSRAM6:
		move.b	($2000A3).l,$2C(a0)
		bra.w	ContinueToReposition
SMCSelSRAM7:
		move.b	($2000C3).l,$2C(a0)
		bra.w	ContinueToReposition
SMCSelSRAM8:
		move.b	($2000e3).l,$2C(a0)
; ###################
ContinueToReposition:


		move.b	$2C(a0),d0			; load highlight number
		add.w	d0,d0				; double = 2 (If the highlight is 1)
		add.w	d0,d0				; double = 4
		add.w	d0,d0				; double = 8
		add.w	d0,d0				; double = 10
		add.w	d0,d0				; double = 20

		move.w	#$0010,$08(a0)			; set object to be on 00 to begin with
		add.w	d0,$08(a0)			; so it was defualt set at X pos 10, add the 20 equals 30 (New X Pos Set)
		bra.w	SvMnSL_Show
	; if the highlight number was 2, the answer would be 40, and 40 would've been added to the X position
	; if the highlight number was 3, the answer would be 60, and 60 would've been added to the X position


; ###################
SvMn_SlotSelector:
		cmp.b	#$01,$29(a0)			; has object started?
		beq.s	SvMnSSL_Started			; if so, branch
		move.w	#$0030,$08(a0)			; object's x possition 00 Defualt Left
		move.w	#$0070,$0C(a0)			; object's Y possition 80 Defualt Top
		move.b	#$01,$29(a0)			; set object as started

SvMnSSL_Started:
		btst	#0,($FFFFF605).w 		; is Left being pressed?
		bne.w	SMsSelUp			; if so, branch
		btst	#1,($FFFFF605).w 		; is Right being pressed?
		bne.w	SMSSelDown			; if so, branch
		bra.w	ContinueToReposition2		; if nothing is pressed, skip

SMSSelUp:
		cmp.b	#$00,$2A(a0)			; is selector already set at far left?
		beq.w	SMSSelRevertDown		; if so, skip (prevent alowing to go Left)
		sub.b	#$01,$2A(a0)			; set select to go left 1
		move.b	#0,($FFFFD06C).w
		bra.w	ContinueToReposition2		; continue object routine

SMSSelDown:
		cmp.b	#$09,$2A(a0)			; is selector already set at far right?
		beq.w	SMSSelRevertUp		; if so, skip (prevent alowing to go Right)
		add.b	#$01,$2A(a0)			; set select to go right 1
		move.b	#0,($FFFFD06C).w
		bra.w	ContinueToReposition2
SMSSelRevertUp:
		move.b	#0,$2A(a0)
		bra.w	ContinueToReposition2

SMSSelRevertDown:
		move.b	#9,$2A(a0)

ContinueToReposition2:
		move.b	$2A(a0),d0			; load highlight number
		add.w	d0,d0				; double = 2 (If the highlight is 1)
		add.w	d0,d0				; double = 4
		add.w	d0,d0				; double = 8
		add.w	d0,d0				; double = 10
		;add.w	d0,d0				; double = 20
		move.w	#$0070,$0C(a0)			; set object to be on 00 to begin with
		add.w	d0,$0C(a0)			; so it was defualt set at X pos 10, add the 20 equals 30 (New X Pos Set)
; ===========================================================================
SvMnSL_Show:
		move.l	#MapSvMnSL,$04(a0)		; load correct mappings
		move.w	#$0000,$02(a0)			; load correct art
		move.b	#$04,$01(a0)			; set object in (Level Mode) (For some reason Screen mode doesn't work, probably a difference in S2 no doubt)
		move.b	#$00,$18(a0)			; set object high plane
		move.b	#$00,$1A(a0)			; set first map

		jmp	DisplaySprite			; show the sprite
; ===========================================================================
MapSvMnSL:	dc.w	SvMnSL00-MapSvMnSL
SvMnSL00:	dc.b	$00,$01

		dc.b	$C0,$0A,$00,$63,$00,$00,$00,$00		; Selector

		even
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to animate tiles in a level
; ---------------------------------------------------------------------------

AnimatedTiles:
		cmpi.b	#emerald_Hill_zone,(Current_Zone).w	; is the level EHZ?
		beq.s	AnimateEHZ				; if so, branch
		rts						; return

; ---------------------------------------------------------------------------

AnimateEHZ:
		lea	(BGScrollGrass).l,a1		; load stars art location to a1
		clr.l	d0				; clear d0
		move.w	(Camera_Y_pos).w,d0		; load screen's X position to d0
		lea	($C00000).l,a6			; set a6 for dumping art
		lsr.w	#$01,d0				; divide it by 2 (this will decrease the speed of animation)
	;	neg.w	d0				; negate to reverse the direction
		andi.w	#$01FF,d0			; clear the first 7 bits (Clears uneeded coding before conversion)

AniStateChk1:
		cmp.w	#$000D,d0			; is the screen's Y position passed 30?
		blt.s	AniStateOk1			; if not, branch to present frame
		sub.w	#$000D,d0			; minus 30...
		bra.w	AniStateChk1			; ...and try again

AniStateOk1:
		mulu.w	#$0020,d0			; Multiply by 20 (by one 8x8 tile that is $20 bytes
		adda.l	d0,a1				; add it to animation art location (to load next tile frame)
		move.l	#$40200000,($C00004).l		; set location in VRam for art to be loaded
		jsr	LoadAniTile			; dump 1 tiles worth of art to VDP
		adda.l	#$220,a1				; add E0 to animation art location (Loads next animation tileset "6 tiles forward")
		jsr	LoadAniTile			; dump 1 tiles worth of art to VDP
		adda.l	#$220,a1				; add E0 to animation art location (Loads next animation tileset "6 tiles forward")
		jsr	LoadAniTile			; dump 1 tiles worth of art to VDP
		adda.l	#$220,a1				; add E0 to animation art location (Loads next animation tileset "6 tiles forward")
		jsr	LoadAniTile			; dump 1 tiles worth of art to VDP
		adda.l	#$220,a1				; add E0 to animation art location (Loads next animation tileset "6 tiles forward")
		jsr	LoadAniTile			; dump 1 tiles worth of art to VDP
		rts					; return

LoadAniTile:
		move.l	(a1)+,(a6)			; dump first 8 nibles (top row 8 pixels)
		move.l	(a1)+,(a6)			; dump first 8 nibles (2nd row 8 pixels)
		move.l	(a1)+,(a6)			; dump first 8 nibles (3rd row 8 pixels)
		move.l	(a1)+,(a6)			; dump first 8 nibles (4th row 8 pixels)
		move.l	(a1)+,(a6)			; dump first 8 nibles (5th row 8 pixels)
		move.l	(a1)+,(a6)			; dump first 8 nibles (6th row 8 pixels)
		move.l	(a1)+,(a6)			; dump first 8 nibles (7th row 8 pixels)
		move.l	(a1)+,(a6)			; dump first 8 nibles (bottom row 8 pixels)
		rts					; return (One tile is now fully loaded to VDP)

; ---------------------------------------------------------------------------
BGScrollGrass:	Binclude	art\uncompressed\AnimatedGrass.bin
		even
; ---------------------------------------------------------------------------
; ===========================================================================
SK_ArtUnc_Knux:		Binclude	"art/uncompressed/KnuxArt.bin"
		even
SK_Map_Knuckles:	Include	"mappings/sprite/KnuxMap.asm"
		even
SK_PLC_Knuckles:	Include	"plcs/KnuxPLC.asm"
		even
Map_InstaShield:	Include "mappings/sprite/Instashield.asm"
		even
DPLC_InstaShield:	Include "mappings/spriteDPLC/Instashield.asm"
		even
Ani_InstaShield:	Include "animations/Sprite/Instashield.asm"	
		even
Ani_FireShield:		Include "animations/Sprite/Fireshield.asm"
		even
Ani_LightningShield:	Include "animations/Sprite/Lightningshield.asm"
		even
Ani_BubbleShield:	Include "animations/Sprite/Bubbleshield.asm"
		even
Map_FireShield:		BINCLUDE "mappings/sprite/S2 fireshield.bin"
		even
DPLC_FireShield:	BINCLUDE  "mappings/spriteDPLC/S2 fireshield.bin"
		even
Map_LighteningShield:	INCLUDE "mappings/sprite/S2 Lightningshield.asm"
		even
DPLC_LighteningShield:	BINCLUDE  "mappings/spriteDPLC/S2 lightshield.bin"
		even
Map_BubbleShield:	BINCLUDE "mappings/sprite/S2 BubbleShield.bin"
		even
DPLC_BubbleShield:	BINCLUDE "mappings/spriteDPLC/S2 BubbleShield.bin"
		even
ArtUnc_InstaShield:	BINCLUDE	"art/uncompressed/instashield.bin"
		even
ArtUnc_FireShield:	BINCLUDE	"art/uncompressed/Fireshield.bin"
		even
ArtUnc_LighteningShield_Sparks:	BINCLUDE	"art/uncompressed/Spark.bin"
		even
ArtUnc_LighteningShield:BINCLUDE	"art/uncompressed/LighteningShield.bin"
		even
ArtUnc_BubbleShield:	BINCLUDE	"art/uncompressed/watershield.bin"
		even
	if padToPowerOfTwo && (*)&(*-1)
		cnop	-1,2<<lastbit(*-1)
		dc.b	0
paddingSoFar	:= paddingSoFar+1
	else
		even
	endif
	if MOMPASS=2
		; "About" because it will be off by the same amount that Size_of_Snd_driver_guess is incorrect (if you changed it), and because I may have missed a small amount of internal padding somewhere
		message "rom size is $\{*} bytes (\{*/1024.0} kb). About $\{paddingSoFar} bytes are padding. "
	endif
	; share these symbols externally (WARNING: don't rename, move or remove these labels!)
;	shared word_728C_user,Obj5F_MapUnc_7240,off_3A294,MapRUnc_Sonic,movewZ80CompSize

	even
EndOfRom:
	END
