; ----------------------------------------------------------------------------
; Object 58 - Boss explosion
; ----------------------------------------------------------------------------
; Sprite_2D494:
Obj58:
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	off_2D4A2(pc,d0.w),d1
	jmp	off_2D4A2(pc,d1.w)
; ===========================================================================
off_2D4A2:
	dc.w loc_2D4A6 - off_2D4A2
	dc.w loc_2D4EC - off_2D4A2; 1
; ===========================================================================

loc_2D4A6:
	addq.b	#2,routine(a0)
	move.l	#Obj58_MapUnc_2D50A,mappings(a0)
	move.w	#$8580,art_tile(a0)
	cmp.b	#1,(Current_Zone).w
	bne.s	+
	move.w	#$2480,2(a0)
+
	move.b	#4,render_flags(a0)
	move.w	#$80,priority(a0)
	move.b	#0,collision_response(a0)
	move.b	#$C,width_pixels(a0)
	move.b	#$C,height_pixels(a0)
	move.b	#7,anim_frame_duration(a0)
	move.b	#0,mapping_frame(a0)
	move.w	#SndID_BossExplosion,d0
	jmp	(PlaySound).l
; ===========================================================================
	rts
; ===========================================================================

loc_2D4EC:
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	BranchTo_JmpTo33_DisplaySprite
	move.b	#7,anim_frame_duration(a0)
	addq.b	#1,mapping_frame(a0)
	cmpi.b	#7,mapping_frame(a0)
	beq.w	JmpTo50_DeleteObject

BranchTo_JmpTo33_DisplaySprite
	bra.w	JmpTo33_DisplaySprite
; ===========================================================================
loc_2D57C:
	cmpi.b	#8,angle(a0)
	bhs.s	return_2D5C2
	tst.b	objoff_32(a0)
	beq.s	loc_2D5C4
	tst.b	collision_response(a0)
	bne.s	return_2D5C2
	tst.b	objoff_14(a0)
	bne.s	loc_2D5A6
	move.b	#$20,objoff_14(a0)
	move.w	#SndID_BossHit,d0
	jsr	(PlaySound).l

loc_2D5A6:
	lea	(Normal_palette_line2+2).w,a1
	moveq	#0,d0
	tst.w	(a1)
	bne.s	loc_2D5B4
	move.w	#$EEE,d0

loc_2D5B4:
	move.w	d0,(a1)
	subq.b	#1,objoff_14(a0)
	bne.s	return_2D5C2
	move.b	#$F,collision_flags(a0)

return_2D5C2:
	rts
; ===========================================================================

loc_2D5C4:
	moveq	#$64,d0
	bsr.w	JmpTo_AddPoints
	move.w	#$B3,($FFFFF75C).w
	move.b	#8,angle(a0)
	moveq	#PLCID_Capsule,d0
	bsr.w	JmpTo4_LoadPLC
	rts
; ===========================================================================

;loc_2D5DE:
Boss_MoveObject:
	move.l	(Boss_X_pos).w,d2
	move.l	(Boss_Y_pos).w,d3
	move.w	(Boss_X_vel).w,d0
	ext.l	d0
	asl.l	#8,d0
	add.l	d0,d2
	move.w	(Boss_Y_vel).w,d0
	ext.l	d0
	asl.l	#8,d0
	add.l	d0,d3
	move.l	d2,(Boss_X_pos).w
	move.l	d3,(Boss_Y_pos).w
	rts
; ===========================================================================
; a1 = animation script pointer
;AnimationArray: up to 8 2-byte entries:
	; 4-bit: anim_ID (1)
	; 4-bit: anim_ID (2) - the relevant one
	; 4-bit: anim_frame
	; 4-bit: anim_timer until next anim_frame
; if anim_ID (1) & (2) are not equal, new animation data is loaded

;loc_2D604:
AnimateBoss:
	moveq	#0,d6
	movea.l	a1,a4		; address of animation script
	lea	(Boss_AnimationArray).w,a2
	lea	objoff_B(a0),a3	; mapframe 1 (main object)
	tst.b	(a3)
	bne.s	+
	addq.w	#2,a2
	bra.s	++
; ----------------------------------------------------------------------------
+
	bsr.w	AnimateBoss_Loop

+
	moveq	#0,d6
	move.b	objoff_F(a0),d6	; number of child sprites
	subq.w	#1,d6		; = amount of iterations to run the code from AnimateBoss_Loop
	bmi.s	return_2D690	; if was 0, don't run
	lea	objoff_15(a0),a3	; mapframe 2
; ----------------------------------------------------------------------------
;loc_2D62A:
AnimateBoss_Loop:	; increases a2 (AnimationArray) by 2 each iteration
	movea.l	a4,a1
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d4
	move.b	(a2)+,d0
	move.b	d0,d1
	lsr.b	#4,d1		; anim_ID (1)
	andi.b	#$F,d0		; anim_ID (2)
	move.b	d0,d2
	cmp.b	d0,d1
	beq.s	+
	st	d4		; anim_IDs not equal
+
	move.b	d0,d5
	lsl.b	#4,d5
	or.b	d0,d5		; anim_ID (2) in both nybbles
	move.b	(a2)+,d0
	move.b	d0,d1
	lsr.b	#4,d1		; anim_frame
	tst.b	d4		; are the anim_IDs equal?
	beq.s	+
	moveq	#0,d0
	moveq	#0,d1		; reset d0,d1 if anim_IDs not equal
+
	andi.b	#$F,d0		; timer until next anim_frame
	subi.b	#1,d0
	bpl.s	loc_2D67C	; timer not yet at 0, and anim_IDs are equal

	add.w	d2,d2		; anim_ID (2)
	adda.w	(a1,d2.w),a1	; address of animation data with this ID
	move.b	(a1),d0		; animation speed
	move.b	1(a1,d1.w),d2	; mapping_frame of first/next anim_frame
	bmi.s	AnimateBoss_CmdParam	; if animation command parameter, branch

loc_2D672:
	andi.b	#$7F,d2
	move.b	d2,(a3)		; store mapping_frame to OST of object
	addi.b	#1,d1		; anim_frame

loc_2D67C:
	lsl.b	#4,d1
	or.b	d1,d0
	move.b	d0,-1(a2)	; (2nd byte) anim_frame and anim_timer
	move.b	d5,-2(a2)	; (1st byte) anim_ID (both nybbles)
	adda.w	#6,a3		; mapping_frame of next subobject
	dbf	d6,AnimateBoss_Loop

return_2D690:
	rts
; ----------------------------------------------------------------------------
;loc_2D692:
AnimateBoss_CmdParam:	; parameter $FF - reset animation to first frame
	addq.b	#1,d2
	bne.s	+
	move.b	#0,d1
	move.b	1(a1),d2
	bra.s	loc_2D672
; ----------------------------------------------------------------------------
+		; parameter $FE - increase boss routine
	addq.b	#1,d2
	bne.s	+
	addi.b	#2,angle(a0)	; boss routine
	rts
; ----------------------------------------------------------------------------
+		; parameter $FD - change anim_ID to byte after parameter
	addq.b	#1,d2
	bne.s	+
	andi.b	#$F0,d5		; keep anim_ID (1)
	or.b	2(a1,d1.w),d5	; set anim_ID (2)
	bra.s	loc_2D67C
; ----------------------------------------------------------------------------
+		; parameter $FC - jump back to anim_frame d1
	addq.b	#1,d2
	bne.s	+	; rts
	moveq	#0,d3
	move.b	2(a1,d1.w),d1	; anim_frame
	move.b	1(a1,d1.w),d2	; mapping_frame
	bra.s	loc_2D672
; ----------------------------------------------------------------------------
+		; parameter $80-$FB
	rts
; ===========================================================================

;loc_2D6CC:
Boss_LoadExplosion:
	move.b	(Vint_runcount+3).w,d0
	andi.b	#7,d0
	bne.s	return_2D712
	jsr	(SingleObjLoad).l
	bne.s	return_2D712
	move.w	#objroutine(Obj58),id(a1) ; load obj58
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	jsr	(RandomNumber).l
	move.w	d0,d1
	moveq	#0,d1
	move.b	d0,d1
	lsr.b	#2,d1
	subi.w	#$20,d1
	add.w	d1,x_pos(a1)
	lsr.w	#8,d0
	lsr.b	#2,d0
	subi.w	#$20,d0
	add.w	d0,y_pos(a1)

return_2D712:
	rts

JmpTo42_DisplaySprite
JmpTo33_DisplaySprite
	jmp	(DisplaySprite).l

JmpTo50_DeleteObject
	jmp	(DeleteObject).l

JmpTo4_LoadPLC
	jmp	(LoadPLC).l

JmpTo_AddPoints
	jmp	(AddPoints).l

; ===========================================================================
; ----------------------------------------------------------------------------
; Object 10 - Final Special Stage Boss
; ----------------------------------------------------------------------------
; Sprite_347EC:
Obj10:
	moveq	#0,d0
	move.b	$26(a0),d0
	move.w	Obj10_Index(pc,d0.w),d1
	jsr		Obj10_Index(pc,d1.w)
	jmp		DisplaySprite
; ---------------------------------------------------
Obj10_Index:
	dc.w	Obj10_FlyingBattle-Obj10_Index
; ---------------------------------------------------
Obj10_FlyingBattle:
	moveq	#0,d0
	move.b	$24(a0),d0
	move.w	Obj10FB_Index(pc,d0.w),d1
	jmp	Obj10FB_Index(pc,d1.w)
; ----------------------------------------------------
Obj10FB_Index:
	dc.w	Obj10FB_Init-Obj10FB_Index
	dc.w	Obj10FB_Wings-Obj10FB_Index
	dc.w	Obj10FB_Projectile-Obj10FB_Index
	dc.w	Obj10FB_ChooseFight-Obj10FB_Index
; ----------------------------------------------------
Obj10FB_Init:
	move.b	#4,1(a0)
	move.w	#$2370,2(a0)
	move.l	#GiantBirdMaps,4(a0)
	move.b	#2,$18(a0)
	move.b	#$BB,$19(a0)
	addq.b	#6,$24(a0)
	moveq	#1,d1
	moveq	#0,d2
	moveq	#1,d3

-	jsr	SingleObjLoad
	bne.s	+
	move.b	#$10,(a1)
	move.b	#4,1(a1)
	move.w	#$2370,2(a1)
	move.l	#GiantBirdMaps,4(a1)
	move.l	a0,$3C(a1)
	move.b	d2,$27(a1)
	move.b	d3,$1A(a1)
	move.b	#$90,$19(a1)
	move.b	#2,$24(a1)
	move.b	#3,$18(a1)
	move.w	#40,$28(a1)
	move.w	#$100,$34(a1)
	addq.b	#1,d2
	addq.b	#1,d3
	dbf	d1,-
+
	rts
Obj10FB_Wings:
	tst.w	$28(a0)
	beq.s	Obj10FBW_Destroyed
	movea.l	$3C(a0),a1
	move.w	8(a1),8(a0)
	move.w	$C(a1),$C(a0)
	sub.w	#$40,$C(a0)
	tst.b	$27(a0)
	bne.s	+
	add.w	#$80,$C(a0)
+
	cmp.w	#$104,8(a0)
	bgt.s	+
	bra.w	Obj10FBW_Hurt
+
	rts
Obj10FBW_Destroyed:
	movea.l	$3C(a0),a1
	tst.b	$27(a1)
	beq.s	+
	addq.b	#2,$27(a1)
+
	sub.w	#1,$34(a0)
	beq.w	++
	sub.b	#1,$38(a0)
	bpl.w	+
	jsr	SingleObjLoad
	bne.w	++
	move.b	#$58,(a1)
	move.w	8(a0),d2
	sub.w	#$10,d2
	jsr	RandomNumber
	and.w	#$7F,d0
	add.w	d2,d0
	move.w	d0,8(a1)
	move.w	$C(a0),d2
	sub.w	#$10,d2
	jsr	RandomNumber
	and.w	#$3F,d0
	add.w	d2,d0
	move.w	d0,$C(a1)
	move.b	#4,$38(a0)
+
	tst.b	1(a0)
	bpl.s	+++
	rts
+
	jsr	BreakObjectToPieces
	tst.b	$23(a0)
	bne.s	Return
	movea.l	$3C(a0),a1
	tst.b	$27(a1)
	beq.s	+
	move.b	#2,$27(a1)
	move.b	#1,$23(a0)
	bra.s	Return
+
	move.b	#1,$27(a1)
	move.b	#1,$23(a0)
	rts
+
	jmp	DeleteObject
Return
	rts
Obj10FBW_Hurt:
	tst.b	$20(a0)
	bne.w	+
	sub.b	#1,$3A(a0)
	bmi.s	++
	tst.b	$2F(a0)
	bne.s	+
	move.w  #$AC,d0
	jsr     (PlaySound).l
	move.b	#1,$2F(a0)
+
	rts
+
	move.b	#$33,$20(a0)
	move.b	#$1A,$3A(a0)
	clr.b	$2F(a0)
	rts
Obj10FB_Projectile:
	jsr	ObjectMove
	move.w	8(a0),d1
	move.w	(Camera_Min_X_pos).w,d2
	cmp.w	d2,d1
	ble.s	+
	move.w	$C(a0),d1
	move.w	(Camera_Min_Y_pos).w,d2
	cmp.w	d2,d1
	ble.s	+
	move.w	(Camera_Max_Y_pos).w,d2
	add.w	#$E0,d2
	cmp.w	d2,d1
	bge.s	+
	rts
+
	jmp	DeleteObject
Obj10FB_ChooseFight:
	cmp.b	#2,$27(a0)
	bge.w	Obj10FB_Defeated
	cmp.b	#0,$27(a0)
	blt.w	Obj10FB_Defeated
	cmp.w	#$100,8(a0)
	ble.s	+
	move.w	#-$100,$10(a0)
	jsr	ObjectMove
	rts
+
	move.w	#0,$10(a0)
	move.w	#$60,$12(a0)
	move.w	$C(a0),d2
	sub.w	($FFFFB00C).w,d2
	tst.w	d2
	beq.s	++
	bmi.s	+
	move.w	#-$60,$12(a0)
+
	jsr	ObjectMove

+
	moveq	#0,d0
	move.b	$25(a0),d0
	move.w	Obj10FBCF_Index(pc,d0.w),d1
	jmp	Obj10FBCF_Index(pc,d1.w)
; -------------------------------------------
Obj10FBCF_Index:
	dc.w	Obj10FBCF_Init-Obj10FBCF_Index
	dc.w	Obj10FBCF_LeftShotArea-Obj10FBCF_Index
	dc.w	Obj10FBCF_ShotArea-Obj10FBCF_Index
	dc.w	Obj10FBCF_ShotRandom-Obj10FBCF_Index
; ----------------------------------------------------
Obj10FB_Defeated:
	cmp.b	#2,$27(a0)
	bne.s	+
	move.w	#-$180,$10(a0)
	move.w	#$100,$12(a0)
	jsr	ObjectMove
+
	sub.b	#1,$3E(a0)
	bpl.w	+
	jsr	SingleObjLoad
	bne.w	+
	move.b	#$58,(a1)
	move.w	8(a0),d2
	sub.w	#$10,d2
	jsr	RandomNumber
	and.w	#$7F,d0
	add.w	d2,d0
	move.w	d0,8(a1)
	move.w	$C(a0),d2
	sub.w	#$10,d2
	jsr	RandomNumber
	and.w	#$3F,d0
	add.w	d2,d0
	move.w	d0,$C(a1)
	move.b	#4,$3E(a0)
+
	tst.b	1(a0)
	bmi.s	+
	jmp	DeleteObject
+
	rts

Obj10FBCF_Init:
+
	sub.b	#1,$36(a0)
	bmi.w	+
	rts
+
	jsr	RandomNumber
	and.b	#3,d0
	beq.w	+
	add.b	d0,d0
	add.b	d0,$25(a0)
+
	rts
Obj10FBCF_LeftShotArea:
	cmp.b	#$4,$29(a0)
	beq.w	Obj10FB_ReturnRoutine
	sub.w	#1,$3C(a0)
	bpl.w	+
	moveq	#7,d3
	moveq	#0,d0
	moveq	#0,d4
	move.b	#$40,d4
	move.w	#$60,$3C(a0)
	add.b	#1,$29(a0)
Obj10FBCFLSA_Fire:
	jsr	SingleObjLoad
	bne.s	+
	move.b	#$10,(a1)
	move.b	#4,1(a1)
	move.w	#$2370,2(a1)
	move.l	#GiantBirdMaps,4(a1)
	move.b	#$86,$20(a1)
	move.b	#4,$24(a1)
	move.b	#1,$18(a1)
	move.w	8(a0),8(a1)
	move.w	$C(a0),$C(a1)
	move.b	d4,d0
	jsr	Calcsine
	asl.l	#2,d0
	move.w	d0,$12(a1)
	asl.l	#2,d1
	move.w	d1,$10(a1)
	add.w	#$10,d4
	move.b	#3,$1A(a1)
	dbf	d3,Obj10FBCFLSA_Fire
+
	rts
Obj10FBCF_ShotArea:
	sub.w	#1,$3C(a0)
	bpl.w	+
	add.b	#1,$29(a0)
	cmp.b	#$20,$29(a0)
	beq.w	Obj10FB_ReturnRoutine
	jsr	SingleObjLoad
	bne.s	+
	move.b	#$10,(a1)
	move.b	#4,1(a1)
	move.w	#$2370,2(a1)
	move.l	#GiantBirdMaps,4(a1)
	move.b	#$86,$20(a1)
	move.b	#4,$24(a1)
	move.b	#1,$18(a1)
	move.w	8(a0),8(a1)
	move.w	$C(a0),$C(a1)
	move.b	$34(a0),d0
	jsr	Calcsine

	move.w	d0,$12(a1)
	move.w	#-$600,$10(a1)
	add.b	#$10,$34(a0)
	move.b	#3,$1A(a1)
	move.w	#$8,$3C(a0)
+
	rts
Obj10FB_ReturnRoutine:
	move.b	#0,$25(a0)
	clr.w	$3C(a0)
	clr.b	$29(a0)
	move.b	#$20,$36(a0)
Obj10FB_Locret:
	rts
Obj10FBCF_ShotRandom:
	sub.w	#1,$3C(a0)
	bpl.w	Obj10FB_Locret
	add.b	#1,$29(a0)
	cmp.b	#$40,$29(a0)
	beq.w	Obj10FB_ReturnRoutine
	jsr	SingleObjLoad
	bne.w	Obj10FB_Locret
	move.b	#$10,(a1)
	move.b	#4,1(a1)
	move.w	#$2370,2(a1)
	move.l	#GiantBirdMaps,4(a1)
	move.b	#$86,$20(a1)
	move.b	#4,$24(a1)
	move.b	#1,$18(a1)
	move.w	8(a0),8(a1)
	move.w	$C(a0),$C(a1)
	jsr	RandomNumber
	and.l	#$3FF,d0
	tst.b	$35(a0)
	beq.s	+
	neg.w	d0
	move.b	#0,$35(a0)
	bra.s	++
+
	move.b	#1,$35(a0)
+
	move.w	d0,$12(a1)
	jsr	RandomNumber
	and.w	#$3FF,d0
	tst.w	d0
	bmi.s	+
	neg.w	d0
+
	move.w	d0,$10(a1)
	move.b	#3,$1A(a1)
	move.w	#$8,$3C(a0)
+
	rts
