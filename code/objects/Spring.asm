; ===========================================================================
; ----------------------------------------------------------------------------
; Object 06 - Spring
; ----------------------------------------------------------------------------
; Sprite_18888:
Spring:
	move.l	#Spring_MapUnc_1901C,mappings(a0)
	move.w	#$460,art_tile(a0)
	ori.b	#4,render_flags(a0)
	move.b	#$10,width_pixels(a0)
	move.w	#$200,priority(a0)	
	move.b	subtype(a0),d0
	lsr.w	#3,d0
	andi.w	#$E,d0
	move.w	off_188DE(pc,d0.w),d0
	jmp	off_188DE(pc,d0.w)
; ===========================================================================
off_188DE:
	dc.w ObjSpring_UpP - off_188DE ; (0) up
	dc.w ObjSpring_SideP - off_188DE ; (2) horizontal
	dc.w ObjSpring_DownP - off_188DE ; (4) down
	dc.w ObjSpring_DiagUpP - off_188DE ; (6) diagonally up
	dc.w ObjSpring_DiagDownP - off_188DE ; (8) diagonally down
; ===========================================================================
word_1897C:
	dc.w $F000
	dc.w $F600
; ===========================================================================

ObjSpring_CheckColor:	; checks color of spring
	move.b	subtype(a0),d0
	andi.w	#2,d0
	move.w	word_1897C(pc,d0.w),objoff_30(a0)
	btst	#1,d0
	beq.s	+
	bset	#5,art_tile(a0)
	move.l	#Spring_MapUnc_19032,mappings(a0)
+	rts
; ===========================================================================

ObjSpring_UpP:
	bsr.w	ObjSpring_CheckColor
	move.w	#objroutine(ObjSpring_Up),(a0)

ObjSpring_Up:
	move.w	#$1B,d1
	move.w	#8,d2
	move.w	#$10,d3
	move.w	x_pos(a0),d4
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	jsr	loc_1978E
	btst	#3,status(a0)
	beq.s	loc_189A8
	bsr.s	loc_189CA

loc_189A8:
	movem.l	(sp)+,d1-d4
	lea		(Sidekick).w,a1 ; a1=character
	moveq	#4,d6
	jsr	loc_1978E
	btst	#4,status(a0)
	beq.s	loc_189C0
	bsr.s	loc_189CA

loc_189C0:
	lea		(Ani_Spring).l,a1
	jsr	AnimateSprite
	jmp	MarkObjGone
; ===========================================================================

loc_189CA:
	move.w	#$100,anim(a0)
	addq.w	#8,y_pos(a1)
	move.w	objoff_30(a0),y_vel(a1)
        clr.b   Flying_Flag
        clr.b   Flying_Frame_Counter
	clr.b	Flying_carrying_sonic_flag
	bset	#1,status(a1)
	bclr	#3,status(a1)
	move.b	#$10,anim(a1)
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Spring_Change_Routine(pc,d0.w),(a1)
	bra.s	+
	
Spring_Change_Routine:
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Tails_Control)
		dc.w	objroutine(Knuckles_Control)	
	
+	move.b	subtype(a0),d0
	bpl.s	loc_189FE
	move.w	#0,x_vel(a1)

loc_189FE:
	btst	#0,d0
	beq.s	loc_18A3E
	move.w	#1,inertia(a1)
	move.b	#1,flip_angle(a1)
	move.b	#0,anim(a1)
	move.b	#0,flips_remaining(a1)
	move.b	#4,flip_speed(a1)
	btst	#1,d0
	bne.s	loc_18A2E
	move.b	#1,flips_remaining(a1)

loc_18A2E:
	btst	#0,status(a1)
	beq.s	loc_18A3E
	neg.b	flip_angle(a1)
	neg.w	inertia(a1)

loc_18A3E:
	andi.b	#$C,d0
	cmpi.b	#4,d0
	bne.s	loc_18A54
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)

loc_18A54:
	cmpi.b	#8,d0
	bne.s	loc_18A66
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)

loc_18A66:
	move.w	#SndID_Spring,d0
	jmp	PlaySound
	

; ===========================================================================

ObjSpring_SideP:
	move.b	#2,anim(a0)
	move.b	#3,mapping_frame(a0)
	move.w	#$474,art_tile(a0)
	move.b	#8,width_pixels(a0)
	bsr.w	ObjSpring_CheckColor
	move.w	#objroutine(ObjSpring_Side),(a0)

ObjSpring_Side:
	move.w	#$13,d1
	move.w	#$E,d2
	move.w	#$F,d3
	move.w	x_pos(a0),d4
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	jsr	loc_1978E
	btst	#5,status(a0)
	beq.s	loc_18AB0
	move.b	status(a0),d1
	move.w	x_pos(a0),d0
	sub.w	x_pos(a1),d0
	bcs.s	loc_18AA8
	eori.b	#1,d1

loc_18AA8:
	andi.b	#1,d1
	bne.s	loc_18AB0
	bsr.s	loc_18AEE

loc_18AB0:
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	moveq	#4,d6
	jsr	loc_1978E
	btst	#6,status(a0)
	beq.s	loc_18AE0
	move.b	status(a0),d1
	move.w	x_pos(a0),d0
	sub.w	x_pos(a1),d0
	bcs.s	loc_18AD8
	eori.b	#1,d1

loc_18AD8:
	andi.b	#1,d1
	bne.s	loc_18AE0
	bsr.s	loc_18AEE

loc_18AE0:
	bsr.w	loc_18BC6
	lea	(Ani_Spring).l,a1
	jsr	AnimateSprite
	jmp	MarkObjGone
; ===========================================================================

loc_18AEE:
	move.w	#$300,anim(a0)
	move.w	objoff_30(a0),x_vel(a1)
	addq.w	#8,x_pos(a1)
	bset	#0,status(a1)
	btst	#0,status(a0)
	bne.s	loc_18B1C
	bclr	#0,status(a1)
	subi.w	#$10,x_pos(a1)
	neg.w	x_vel(a1)

loc_18B1C:
	move.w	#$F,move_lock(a1)
	move.w	x_vel(a1),inertia(a1)
	btst	#2,status(a1)
	bne.s	loc_18B36
	move.b	#0,anim(a1)

loc_18B36:
	move.b	subtype(a0),d0
	bpl.s	loc_18B42
	move.w	#0,y_vel(a1)

loc_18B42:
	btst	#0,d0
	beq.s	loc_18B82
	move.w	#1,inertia(a1)
	move.b	#1,flip_angle(a1)
	move.b	#0,anim(a1)
	move.b	#1,flips_remaining(a1)
	move.b	#8,flip_speed(a1)
	btst	#1,d0
	bne.s	loc_18B72
	move.b	#3,flips_remaining(a1)

loc_18B72:
	btst	#0,status(a1)
	beq.s	loc_18B82
	neg.b	flip_angle(a1)
	neg.w	inertia(a1)

loc_18B82:
	andi.b	#$C,d0
	cmpi.b	#4,d0
	bne.s	loc_18B98
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)

loc_18B98:
	cmpi.b	#8,d0
	bne.s	loc_18BAA
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)

loc_18BAA:
	bclr	#5,status(a0)
	bclr	#6,status(a0)
	bclr	#5,status(a1)
	move.w	#SndID_Spring,d0
	jmp	PlaySound
; ===========================================================================

loc_18BC6:
	cmpi.b	#3,anim(a0)
	beq.w	return_18C7E
	move.w	x_pos(a0),d0
	move.w	d0,d1
	addi.w	#$28,d1
	btst	#0,status(a0)
	beq.s	loc_18BE8
	move.w	d0,d1
	subi.w	#$28,d0

loc_18BE8:
	move.w	y_pos(a0),d2
	move.w	d2,d3
	subi.w	#$18,d2
	addi.w	#$18,d3
	lea	(MainCharacter).w,a1 ; a1=character
	btst	#1,status(a1)
	bne.s	loc_18C3C
	move.w	inertia(a1),d4
	btst	#0,status(a0)
	beq.s	loc_18C10
	neg.w	d4

loc_18C10:
	tst.w	d4
	bmi.s	loc_18C3C
	move.w	x_pos(a1),d4
	cmp.w	d0,d4
	blo.w	loc_18C3C
	cmp.w	d1,d4
	bhs.w	loc_18C3C
	move.w	y_pos(a1),d4
	cmp.w	d2,d4
	blo.w	loc_18C3C
	cmp.w	d3,d4
	bhs.w	loc_18C3C
	move.w	d0,-(sp)
	bsr.w	loc_18AEE
	move.w	(sp)+,d0

loc_18C3C:
	lea	(Sidekick).w,a1 ; a1=character
	btst	#1,status(a1)
	bne.s	return_18C7E
	move.w	inertia(a1),d4
	btst	#0,status(a0)
	beq.s	loc_18C56
	neg.w	d4

loc_18C56:
	tst.w	d4
	bmi.s	return_18C7E
	move.w	x_pos(a1),d4
	cmp.w	d0,d4
	blo.w	return_18C7E
	cmp.w	d1,d4
	bhs.w	return_18C7E
	move.w	y_pos(a1),d4
	cmp.w	d2,d4
	blo.w	return_18C7E
	cmp.w	d3,d4
	bhs.w	return_18C7E
	bsr.w	loc_18AEE

return_18C7E:
	rts
; ===========================================================================

ObjSpring_DownP:
	move.b	#6,mapping_frame(a0)
	bset	#1,status(a0)
	bsr.w	ObjSpring_CheckColor
	move.w	#objroutine(ObjSpring_Down),(a0)

ObjSpring_Down:
	move.w	#$1B,d1
	move.w	#8,d2
	move.w	#$10,d3
	move.w	x_pos(a0),d4
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	jsr	loc_1978E
	cmpi.w	#-2,d4
	bne.s	loc_18CA6
	bsr.s	loc_18CC6

loc_18CA6:
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	moveq	#4,d6
	jsr	loc_1978E
	cmpi.w	#-2,d4
	bne.s	loc_18CBC
	bsr.s	loc_18CC6

loc_18CBC:
	lea	(Ani_Spring).l,a1
	jsr	AnimateSprite
	jmp	MarkObjGone
; ===========================================================================

loc_18CC6:
	move.w	#$100,anim(a0)
	subq.w	#8,y_pos(a1)
	move.w	objoff_30(a0),y_vel(a1)
	neg.w	y_vel(a1)
	move.b	subtype(a0),d0
	bpl.s	loc_18CE6
	move.w	#0,x_vel(a1)

loc_18CE6:
	btst	#0,d0
	beq.s	loc_18D26
	move.w	#1,inertia(a1)
	move.b	#1,flip_angle(a1)
	move.b	#0,anim(a1)
	move.b	#0,flips_remaining(a1)
	move.b	#4,flip_speed(a1)
	btst	#1,d0
	bne.s	loc_18D16
	move.b	#1,flips_remaining(a1)

loc_18D16:
	btst	#0,status(a1)
	beq.s	loc_18D26
	neg.b	flip_angle(a1)
	neg.w	inertia(a1)

loc_18D26:
	andi.b	#$C,d0
	cmpi.b	#4,d0
	bne.s	loc_18D3C
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)

loc_18D3C:
	cmpi.b	#8,d0
	bne.s	loc_18D4E
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)

loc_18D4E:
	bset	#1,status(a1)
	bclr	#3,status(a1)
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Spring_Change_Routine2(pc,d0.w),(a1)
	move.w	#SndID_Spring,d0
	jmp	(PlaySound).l
	
Spring_Change_Routine2:
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Tails_Control)
		dc.w	objroutine(Knuckles_Control)	
; ===========================================================================

ObjSpring_DiagUpP:
	move.b	#4,anim(a0)
	move.b	#7,mapping_frame(a0)
	move.w	#$440,art_tile(a0)
	bsr.w	ObjSpring_CheckColor
	move.w	#objroutine(ObjSpring_DiagUp),(a0)

ObjSpring_DiagUp:
	move.w	#$1B,d1
	move.w	#$10,d2
	move.w	x_pos(a0),d4
	lea	byte_18FAA(pc),a2
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	jsr	SolidObject_Simple
	btst	#3,status(a0)
	beq.s	loc_18D92
	bsr.s	loc_18DB4

loc_18D92:
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	moveq	#4,d6
	jsr	SolidObject_Simple
	btst	#4,status(a0)
	beq.s	loc_18DAA
	bsr.s	loc_18DB4

loc_18DAA:
	lea	(Ani_Spring).l,a1
	jsr	AnimateSprite
	jmp	MarkObjGone
; ===========================================================================

loc_18DB4:
	btst	#0,status(a0)
	bne.s	loc_18DCA
	move.w	x_pos(a0),d0
	subq.w	#4,d0
	cmp.w	x_pos(a1),d0
	blo.s	loc_18DD8
	rts
; ===========================================================================

loc_18DCA:
	move.w	x_pos(a0),d0
	addq.w	#4,d0
	cmp.w	x_pos(a1),d0
	bhs.s	loc_18DD8
	rts
; ===========================================================================

loc_18DD8:
	move.w	#$500,anim(a0)
	move.w	objoff_30(a0),y_vel(a1)
	move.w	objoff_30(a0),x_vel(a1)
	addq.w	#6,y_pos(a1)
	addq.w	#6,x_pos(a1)
	bset	#0,status(a1)
	btst	#0,status(a0)
	bne.s	loc_18E10
	bclr	#0,status(a1)
	subi.w	#$C,x_pos(a1)
	neg.w	x_vel(a1)

loc_18E10:
	bset	#1,status(a1)
	bclr	#3,status(a1)
	move.b	#$10,anim(a1)
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Spring_Change_Routine3(pc,d0.w),(a1)
	bra.s	+
	
Spring_Change_Routine3:
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Tails_Control)
		dc.w	objroutine(Knuckles_Control)		
	
+	move.b	subtype(a0),d0
	btst	#0,d0
	beq.s	loc_18E6C
	move.w	#1,inertia(a1)
	move.b	#1,flip_angle(a1)
	move.b	#0,anim(a1)
	move.b	#1,flips_remaining(a1)
	move.b	#8,flip_speed(a1)
	btst	#1,d0
	bne.s	loc_18E5C
	move.b	#3,flips_remaining(a1)

loc_18E5C:
	btst	#0,status(a1)
	beq.s	loc_18E6C
	neg.b	flip_angle(a1)
	neg.w	inertia(a1)

loc_18E6C:
	andi.b	#$C,d0
	cmpi.b	#4,d0
	bne.s	loc_18E82
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)

loc_18E82:
	cmpi.b	#8,d0
	bne.s	loc_18E94
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)

loc_18E94:
	move.w	#SndID_Spring,d0
	jmp	(PlaySound).l
	
; ===========================================================================

ObjSpring_DiagDownP:
	move.b	#4,anim(a0)
	move.b	#$A,mapping_frame(a0)
	move.w	#$440,art_tile(a0)
	bset	#1,status(a0)
	bsr.w	ObjSpring_CheckColor
	move.w	#objroutine(ObjSpring_DiagDown),(a0)

ObjSpring_DiagDown:
	move.w	#$1B,d1
	move.w	#$10,d2
	move.w	x_pos(a0),d4
	lea	byte_18FC6(pc),a2
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	jsr	SolidObject_Simple
	cmpi.w	#-2,d4
	bne.s	loc_18EC4
	bsr.s	loc_18EE6

loc_18EC4:
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	moveq	#4,d6
	jsr	SolidObject_Simple
	cmpi.w	#-2,d4
	bne.s	loc_18EDA
	bsr.s	loc_18EE6

loc_18EDA:
	lea	(Ani_Spring).l,a1
	jsr	AnimateSprite
	jmp	MarkObjGone
; ===========================================================================

loc_18EE6:
	move.w	#$500,anim(a0)
	move.w	objoff_30(a0),y_vel(a1)
	neg.w	y_vel(a1)
	move.w	objoff_30(a0),x_vel(a1)
	subq.w	#6,y_pos(a1)
	addq.w	#6,x_pos(a1)
	bset	#0,status(a1)
	btst	#0,status(a0)
	bne.s	loc_18F22
	bclr	#0,status(a1)
	subi.w	#$C,x_pos(a1)
	neg.w	x_vel(a1)

loc_18F22:
	bset	#1,status(a1)
	bclr	#3,status(a1)
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Spring_Change_Routine4(pc,d0.w),(a1)
	bra.s	+
	
Spring_Change_Routine4:
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Sonic_Control)
		dc.w	objroutine(Tails_Control)
		dc.w	objroutine(Knuckles_Control)	
		
+	move.b	subtype(a0),d0
	btst	#0,d0
	beq.s	loc_18F78
	move.w	#1,inertia(a1)
	move.b	#1,flip_angle(a1)
	move.b	#0,anim(a1)
	move.b	#1,flips_remaining(a1)
	move.b	#8,flip_speed(a1)
	btst	#1,d0
	bne.s	loc_18F68
	move.b	#3,flips_remaining(a1)

loc_18F68:
	btst	#0,status(a1)
	beq.s	loc_18F78
	neg.b	flip_angle(a1)
	neg.w	inertia(a1)

loc_18F78:
	andi.b	#$C,d0
	cmpi.b	#4,d0
	bne.s	loc_18F8E
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)

loc_18F8E:
	cmpi.b	#8,d0
	bne.s	loc_18FA0
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)

loc_18FA0:
	move.w	#SndID_Spring,d0
	jmp	(PlaySound).l
	
; ===========================================================================
byte_18FAA:
	dc.b $10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10,$10, $E, $C, $A,  8
	dc.b   6,  4,  2,  0,$FE,$FC,$FC,$FC,$FC,$FC,$FC,$FC; 16
byte_18FC6:
	dc.b $F4,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F2,$F4,$F6,$F8
	dc.b $FA,$FC,$FE,  0,  2,  4,  4,  4,  4,  4,  4,  4; 16
; off_18FE2:
; ===========================================================================
