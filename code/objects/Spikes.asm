; ===========================================================================
ObjSpikes_Data:
	dc.b $20, $20	; 0
	dc.b $40, $20	; 1
	dc.b $60, $20	; 2
	dc.b $80, $20	; 3
	dc.b $20, $20	; 4
	dc.b $20, $40	; 5
	dc.b $20, $60	; 6
	dc.b $20, $80	; 7
; ===========================================================================
; ----------------------------------------------------------------------------
; Object 36 - Vertical spikes
; ----------------------------------------------------------------------------

Spikes:
	move.l	#Spikes_MapUnc_15B68,mappings(a0)	; set mappings
	move.w	#$2480,art_tile(a0)			; set art offset
	ori.b	#4,render_flags(a0)			; align to level
	move.w	#$200,priority(a0)				; set priority
	move.b	subtype(a0),d0				; get subtype
	andi.b	#$F,subtype(a0)				; remove upper nybble from stored subtype
	andi.w	#$F0,d0					; remove lower nybble from fetched subtype
	lea	ObjSpikes_Data(pc),a1
	lsr.w	#3,d0
	adda.w	d0,a1					; get address to spike data
	move.b	(a1)+,width_pixels(a0)			; set width
	move.b	(a1)+,height_pixels(a0)			; set height
	lsr.w	#1,d0
	move.b	d0,mapping_frame(a0)			; set frame
	move.w	x_pos(a0),objoff_30(a0)			; back up x-position
	move.w	y_pos(a0),objoff_32(a0)			; back up y-position
	cmpi.b	#4,d0					; are the spikes vertical?
	bhi.w	ObjSpikes_WallsP			; if so, branch
	btst	#1,status(a0)				; are the spikes on the ceiling?
	bne.w	ObjSpikes_CeilingP			; if so, branch
	move.w	#objroutine(ObjSpikes_Ground),(a0)	; go to routine Ground

ObjSpikes_Ground:
	bsr.w	ObjSpikes_Move
	moveq	#0,d1
	move.b	width_pixels(a0),d1
	lsr.b	#1,d1
	addi.w	#$B,d1
	moveq	#0,d2
	move.b	height_pixels(a0),d2
	lsr.b	#1,d2
	move.w	d2,d3
	addq.w	#1,d3
	move.w	x_pos(a0),d4
	jsr	SolidObject
	move.b	status(a0),d6
	andi.b	#$18,d6
	beq.s	ObjSpikes_Done
	move.b	d6,d0
	andi.b	#8,d0
	beq.s	+
	lea	(MainCharacter).w,a1 ; a1=character
	bsr.w	Touch_ChkHurt2
+	andi.b	#$10,d6
	beq.s	ObjSpikes_Done
	lea	(Sidekick).w,a1 ; a1=character
	bsr.w	Touch_ChkHurt2

ObjSpikes_Done:
	move.w	objoff_30(a0),d0
	jmp	MarkObjGone2
; ===========================================================================

ObjSpikes_WallsP:
	move.w	#$2488,art_tile(a0)			; set alternate art offset
	move.w	#objroutine(ObjSpikes_Walls),(a0)	; go to routine Walls

ObjSpikes_Walls:
	move.w	x_pos(a0),-(sp)
	bsr.w	ObjSpikes_Move
	moveq	#0,d1
	move.b	width_pixels(a0),d1
	lsr.b	#1,d1
	addi.w	#$B,d1
	moveq	#0,d2
	move.b	height_pixels(a0),d2
	lsr.b	#1,d2
	move.w	d2,d3
	addq.w	#1,d3
	move.w	(sp)+,d4
	jsr	SolidObject
	swap	d6
	andi.w	#3,d6
	beq.s	ObjSpikes_Done
	move.b	d6,d0
	andi.b	#1,d0
	beq.s	+
	lea	(MainCharacter).w,a1 ; a1=character
	bsr.w	Touch_ChkHurt2
	bclr	#5,status(a0)
+	andi.b	#2,d6
	beq.s	ObjSpikes_Done
	lea	(Sidekick).w,a1 ; a1=character
	bsr.w	Touch_ChkHurt2
	bclr	#6,status(a0)
	bra.w	ObjSpikes_Done
; ===========================================================================

ObjSpikes_CeilingP:
	move.w	#objroutine(ObjSpikes_Ceiling),(a0)	; go to routine Ceiling

ObjSpikes_Ceiling:
	bsr.w	ObjSpikes_Move
	moveq	#0,d1
	move.b	width_pixels(a0),d1
	lsr.b	#1,d1	
	addi.w	#$B,d1
	moveq	#0,d2
	move.b	height_pixels(a0),d2
	lsr.b	#1,d2
	move.w	d2,d3
	addq.w	#1,d3
	move.w	x_pos(a0),d4
	jsr	SolidObject
	swap	d6
	andi.w	#$C,d6
	beq.w	ObjSpikes_Done
	move.b	d6,d0
	andi.b	#4,d0
	beq.s	+
	lea	(MainCharacter).w,a1 ; a1=character
	bsr.w	Touch_ChkHurt2
+	andi.b	#8,d6
	beq.w	ObjSpikes_Done
	lea	(Sidekick).w,a1 ; a1=character
	bsr.w	Touch_ChkHurt2
	bra.w	ObjSpikes_Done

; ---------------------------------------------------------------------------
; Subroutine for checking if Sonic/Tails should be hurt and hurting them if so
; unlike Touch_ChkHurt, the character is at a1 instead of a0
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Touch_ChkHurt2:
	move.b	status2(a1),d0
	andi.b	#power_mask,d0				; is Sonic invincible?
	bne.s	Touch_ChkHurt2_Return			; if so, branch
	tst.w	invulnerable_time(a1)			; is Sonic invulnerable?
	bne.s	Touch_ChkHurt2_Return			; if so, branch
	move.w	(a1),d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Spikes_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	Touch_ChkHurt2_Return
	move.w	Spikes_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	Touch_ChkHurt2_Return
	move.w	Spikes_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	Touch_ChkHurt2_Return
	move.w	Spikes_Check4(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	Touch_ChkHurt2_Return	
	move.l	y_pos(a1),d3
	move.w	y_vel(a1),d0
	ext.l	d0
	asl.l	#8,d0
	sub.l	d0,d3
	move.l	d3,y_pos(a1)
	movea.l	a0,a2
	movea.l	a1,a0
	jsr	(HurtCharacter).l
	movea.l	a2,a0

Touch_ChkHurt2_Return:
	rts
; End of function Touch_ChkHurt2
Spikes_Check:
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Tails_Hurt)
		dc.w	objroutine(Knuckles_Hurt)	
		
Spikes_Check2:		
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

Spikes_Check3:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)

Spikes_Check4:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)				

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


ObjSpikes_Move:

	moveq	#0,d0
	move.b	subtype(a0),d0
	add.w	d0,d0
	move.w	off_15AD6(pc,d0.w),d1
	jmp	off_15AD6(pc,d1.w)
; End of function ObjSpikes_Move

; ===========================================================================
off_15AD6:
	dc.w return_15ADC - off_15AD6
	dc.w loc_15ADE - off_15AD6; 1
	dc.w loc_15AF2 - off_15AD6; 2
; ===========================================================================

return_15ADC:
	rts
; ===========================================================================

loc_15ADE:
	bsr.w	sub_15B06
	moveq	#0,d0
	move.b	objoff_34(a0),d0
	add.w	objoff_32(a0),d0
	move.w	d0,y_pos(a0)
	rts
; ===========================================================================

loc_15AF2:
	bsr.w	sub_15B06
	moveq	#0,d0
	move.b	objoff_34(a0),d0
	add.w	objoff_30(a0),d0
	move.w	d0,x_pos(a0)
	rts

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_15B06:

	tst.w	objoff_38(a0)
	beq.s	loc_15B24
	subq.w	#1,objoff_38(a0)
	bne.s	return_15B66
	tst.b	render_flags(a0)
	bpl.s	return_15B66
	move.w	#SndID_SpikesMove,d0
	jsr	(PlaySound).l
	bra.s	return_15B66
; ===========================================================================

loc_15B24:
	tst.w	objoff_36(a0)
	beq.s	loc_15B46
	subi.w	#$800,objoff_34(a0)
	bcc.s	return_15B66
	move.w	#0,objoff_34(a0)
	move.w	#0,objoff_36(a0)
	move.w	#$3C,objoff_38(a0)
	bra.s	return_15B66
; ===========================================================================

loc_15B46:
	addi.w	#$800,objoff_34(a0)
	cmpi.w	#$2000,objoff_34(a0)
	blo.s	return_15B66
	move.w	#$2000,objoff_34(a0)
	move.w	#1,objoff_36(a0)
	move.w	#$3C,objoff_38(a0)

return_15B66:
	rts
; End of function sub_15B06

