; ===========================================================================
; ----------------------------------------------------------------------------
; Object DA - Continue text
; ----------------------------------------------------------------------------
; loc_7A68:
ObjDA: ; (screen-space obj)
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	+(pc,d0.w),d1
	jmp	+(pc,d1.w)
; ===========================================================================
; Obj_DA_subtbl:
/	dc.w ObjDA_Init - (-)
	dc.w JmpTo2_DisplaySprite - (-)	; 1
	dc.w loc_7AD0 - (-)	; 2
	dc.w loc_7B46 - (-)	; 3
; ===========================================================================
; loc_7A7E:
ObjDA_Init:
	addq.b	#2,routine(a0)
	move.l	#ObjDA_MapUnc_7CB6,mappings(a0)
	move.w	#$8500,art_tile(a0)
	move.b	#0,render_flags(a0)
	move.b	#$3C,width_pixels(a0)
	move.w	#$120,x_pixel(a0)
	move.w	#$C0,y_pixel(a0)

JmpTo2_DisplaySprite
	jmp	(DisplaySprite).l
; ===========================================================================
word_7AB2:
	dc.w  $116, $12A, $102,	$13E,  $EE, $152,  $DA,	$166
	dc.w   $C6, $17A,  $B2,	$18E,  $9E, $1A2,  $8A;	8
; ===========================================================================

loc_7AD0:
	movea.l	a0,a1
	lea	word_7AB2(pc),a2
	moveq	#0,d1
	move.b	(Continue_count).w,d1
	subq.b	#2,d1
	bcc.s	+
	jmp	(DeleteObject).l
; ===========================================================================
+
	moveq	#1,d3
	cmpi.b	#$E,d1
	blo.s	+
	moveq	#0,d3
	moveq	#$E,d1
+
	move.b	d1,d2
	andi.b	#1,d2

-	move.w	#objroutine(ObjDA),id(a1) ; load objDA
	move.w	(a2)+,x_pixel(a1)
	tst.b	d2
	beq.s	+
	subi.w	#$A,x_pixel(a1)
+
	move.w	#$D0,y_pixel(a1)
	move.b	#4,mapping_frame(a1)
	move.b	#6,routine(a1)
	move.l	#$7CB6,mappings(a1)
	move.w	#$8524,art_tile(a1)
	move.b	#0,render_flags(a1)
	lea	next_object(a1),a1 ; load obj addr
	dbf	d1,-

	lea	-next_object(a1),a1 ; load obj addr
	move.b	d3,subtype(a1)

loc_7B46:
	tst.b	subtype(a0)
	beq.s	+
	cmpi.b	#4,(MainCharacter+routine).w
	blo.s	+
	move.b	(Vint_runcount+3).w,d0
	andi.b	#1,d0
	bne.s	+
	tst.w	(MainCharacter+x_vel).w
	bne.s	JmpTo2_DeleteObject
	rts
; ===========================================================================
+
	move.b	(Vint_runcount+3).w,d0
	andi.b	#$F,d0
	bne.s	JmpTo3_DisplaySprite
	bchg	#0,mapping_frame(a0)

JmpTo3_DisplaySprite
	jmp	(DisplaySprite).l
; ===========================================================================

JmpTo2_DeleteObject
	jmp	(DeleteObject).l
; ===========================================================================
; ----------------------------------------------------------------------------
; Object DB - Sonic lying down or Tails nagging (on the continue screen)
; ----------------------------------------------------------------------------
; Sprite_7B82:
ObjDB:
	; a0=character
	moveq	#0,d0
	move.b	routine(a0),d0
	move.w	+(pc,d0.w),d1
	jsr	+(pc,d1.w)
	jmp	(DisplaySprite).l
; ===========================================================================
; off_7B96: ObjDB_States:
/	dc.w ObjDB_Sonic_Init - (-)	; 0
	dc.w ObjDB_Sonic_Wait - (-)	; 2
	dc.w ObjDB_Sonic_Run - (-)	; 4
	dc.w ObjDB_Tails_Init - (-)	; 6
	dc.w ObjDB_Tails_Wait - (-)	; 8
	dc.w ObjDB_Tails_Run - (-)	;$A
; ===========================================================================
; loc_7BA2:
ObjDB_Sonic_Init:
	addq.b	#2,routine(a0) ; => ObjDB_Sonic_Wait
	move.w	#$9C,x_pos(a0)
	move.w	#$19C,y_pos(a0)
	move.l	#Mapunc_Sonic,mappings(a0)
	move.w	#$780,art_tile(a0)
	move.b	#4,render_flags(a0)
	move.w	#$100,priority(a0)
	move.b	#$20,anim(a0)

; loc_7BD2:
ObjDB_Sonic_Wait:
	tst.b	(Ctrl_1_Press).w	; is start pressed?
	bmi.s	ObjDB_Sonic_StartRunning ; if yes, branch
	jsr	(Sonic_Animate).l
	jmp	(LoadSonicDynPLC).l
; ---------------------------------------------------------------------------
; loc_7BE4:
ObjDB_Sonic_StartRunning:
	addq.b	#2,routine(a0) ; => ObjDB_Sonic_Run
	move.b	#$21,anim(a0)
	clr.w	inertia(a0)
	move.b	#$E0,d0 ; super peel-out sound
	jsr	PlaySound

; loc_7BFA:
ObjDB_Sonic_Run:
	cmpi.w	#$800,inertia(a0)
	bne.s	+
	move.w	#$1000,x_vel(a0)
	bra.s	++
; ---------------------------------------------------------------------------
+
	addi.w	#$20,inertia(a0)
+
	jsr	(ObjectMove).l
	jsr	(Sonic_Animate).l
	jmp	(LoadSonicDynPLC).l
; ===========================================================================
; loc_7C22:
ObjDB_Tails_Init:
	addq.b	#2,routine(a0) ; => ObjDB_Tails_Wait
	move.w	#$B8,x_pos(a0)
	move.w	#$1A0,y_pos(a0)
	move.l	#ObjDA_MapUnc_7CB6,mappings(a0)
	move.w	#$500,art_tile(a0)
	move.b	#4,render_flags(a0)
	move.w	#$100,priority(a0)
	move.b	#0,anim(a0)

; loc_7C52:
ObjDB_Tails_Wait:
	tst.b	(Ctrl_1_Press).w	; is start pressed?
	bmi.s	ObjDB_Tails_StartRunning ; if yes, branch
	lea	(Ani_objDB).l,a1
	jmp	(AnimateSprite).l
; ---------------------------------------------------------------------------
; loc_7C64:
ObjDB_Tails_StartRunning:
	addq.b	#2,routine(a0) ; => ObjDB_Tails_Run
	move.l	#MapUnc_Tails,mappings(a0)
	move.w	#$7A0,art_tile(a0)
	move.b	#0,anim(a0)
	clr.w	inertia(a0)
	move.b	#$E0,d0 ; super peel-out sound
	jsr	PlaySound

; loc_7C88:
ObjDB_Tails_Run:
	cmpi.w	#$720,inertia(a0)
	bne.s	+
	move.w	#$1000,x_vel(a0)
	bra.s	++
; ---------------------------------------------------------------------------
+
	addi.w	#$18,inertia(a0)
+
	jsr	(ObjectMove).l
	jsr	(Tails_Animate).l
	jmp	(LoadTailsDynPLC).l
