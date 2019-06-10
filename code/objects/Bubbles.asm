; ===========================================================================
; ----------------------------------------------------------------------------
; Small Bubbles - Small bubbles from Sonic's face while underwater
; ----------------------------------------------------------------------------

Small_Bubbles:
	movea.l	objoff_3C(a0),a2			; a2=character
	cmpa.w	#MainCharacter,a2
	bne.s	+					; if it isn't player 1, branch
	btst 	#shield_water,status2(a2)			; does the player have a water shield?
	beq.b	+					; if not, branch
	rts
+	move.w	#objroutine(Small_Bubbles_Animate),(a0)		; go to routine Animate
	move.l	#Bubbles_Base_MapUnc_1FC18,mappings(a0)	; set mappings
	move.w	#$8418,art_tile(a0)			; set art offset
	move.b	#$84,render_flags(a0)			; align to level and force draw
	move.b	#$10,width_pixels(a0)			; set width
	move.b	#$10,height_pixels(a0)	
	move.w	#$80,priority(a0)				; set priority
	move.b	subtype(a0),d0				; get subtype
	bmi.w	Small_Bubbles_CountdownP			; if >= $80, branch
	move.b	d0,anim(a0)				; set animation
	move.w	x_pos(a0),objoff_30(a0)
	move.w	#-$88,y_vel(a0)

Small_Bubbles_Animate:
	lea	(Ani_Small_Bubbles).l,a1
	jsr	(AnimateSprite).l

Small_Bubbles_ChkWater:
	move.w	(Water_Level_1).w,d0
	cmp.w	y_pos(a0),d0				; has bubble reached the water surface?
	blo.s	Small_Bubbles_Wobble				; if not, branch
	; pop the bubble:
	move.w	#objroutine(Small_Bubbles_Display),(a0)		; go to routine Display
	addq.b	#7,anim(a0)
	cmpi.b	#$D,anim(a0)
	bls.s	Small_Bubbles_Display
	move.b	#$D,anim(a0)
	bra.s	Small_Bubbles_Display
; ===========================================================================
Small_Bubbles_Wobble:
	tst.b	(WindTunnel_flag).w
	beq.s	+
	addq.w	#4,objoff_30(a0)
+	move.b	angle(a0),d0
	addq.b	#1,angle(a0)
	andi.w	#$7F,d0
	lea	(Small_Bubbles_WobbleData).l,a1
	move.b	(a1,d0.w),d0
	ext.w	d0
	add.w	objoff_30(a0),d0
	move.w	d0,x_pos(a0)
	bsr.s	Small_Bubbles_ShowNumber
	jsr	(ObjectMove).l
	tst.b	render_flags(a0)
	bpl.s	JmpTo5_DeleteObject
	jmp	(DisplaySprite).l
; ===========================================================================

Small_Bubbles_DisplayNumber:
	tst.b	mappings(a0)
	bmi.b	JmpTo5_DeleteObject
	movea.l	objoff_3C(a0),a2 ; a2=character
	cmpi.b	#$C,air_left(a2)
	bhi.s	JmpTo5_DeleteObject

Small_Bubbles_Display:
	tst.b	mappings(a0)
	bmi.b	JmpTo5_DeleteObject
	bsr.s	Small_Bubbles_ShowNumber
	lea	(Ani_Small_Bubbles).l,a1
	jsr	(AnimateSprite).l
	jmp	(DisplaySprite).l

JmpTo5_DeleteObject:
	jmp	(DeleteObject).l
; ===========================================================================

Small_Bubbles_AirLeft:
	movea.l	objoff_3C(a0),a2			; a2=character
	cmpi.b	#$C,air_left(a2)			; check air remaining
	bhi.s	JmpTo5_DeleteObject			; if higher than $C, branch
	subq.w	#1,objoff_38(a0)
	bne.s	Small_Bubbles_Display2
	move.w	#objroutine(Small_Bubbles_DisplayNumber),(a0)	; go to routine DisplayNumber
	addq.b	#7,anim(a0)
	bra.s	Small_Bubbles_Display
; ===========================================================================

Small_Bubbles_Display2:
	lea	(Ani_Small_Bubbles).l,a1
	jsr	(AnimateSprite).l
	bsr.w	Small_Bubbles_LoadCountdownArt
	tst.b	render_flags(a0)
	bpl.s	JmpTo5_DeleteObject
	jmp	(DisplaySprite).l
; ===========================================================================

Small_Bubbles_ShowNumber:
	tst.w	objoff_38(a0)
	beq.s	Small_Bubbles_ShowNumber_Return
	subq.w	#1,objoff_38(a0)
	bne.s	Small_Bubbles_ShowNumber_Return
	cmpi.b	#7,anim(a0)
	bhs.s	Small_Bubbles_ShowNumber_Return
	move.w	#$F,objoff_38(a0)
	clr.w	y_vel(a0)
	move.b	#$80,render_flags(a0)
	move.w	x_pos(a0),d0
	sub.w	(Camera_X_pos).w,d0
	addi.w	#$80,d0
	move.w	d0,x_pos(a0)
	move.w	y_pos(a0),d0
	sub.w	(Camera_Y_pos).w,d0
	addi.w	#$80,d0
	move.w	d0,objoff_A(a0)
	move.w	#objroutine(Small_Bubbles_AirLeft),(a0)		; go to routine AirLeft

Small_Bubbles_ShowNumber_Return:
	rts
; ===========================================================================
; byte_1D4C0:
Small_Bubbles_WobbleData:
	dc.b  0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2;16
	dc.b  2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3;32
	dc.b  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2;48
	dc.b  2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0;64
	dc.b  0,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,-3,-3,-3,-3,-3;80
	dc.b -3,-3,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4;96
	dc.b -4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-3;112
	dc.b -3,-3,-3,-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1;128
	dc.b  0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2;144
	dc.b  2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3;160
	dc.b  3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2;176
	dc.b  2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0;192
	dc.b  0,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,-3,-3,-3,-3,-3;208
	dc.b -3,-3,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4;224
	dc.b -4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-4,-3;240
	dc.b -3,-3,-3,-3,-3,-3,-2,-2,-2,-2,-2,-1,-1,-1,-1,-1;256
; ===========================================================================
; the countdown numbers go over the dust and splash effect tiles in VRAM

Small_Bubbles_LoadCountdownArt:
	moveq	#0,d1
	move.b	mapping_frame(a0),d1
	cmpi.b	#8,d1
	blo.s	Small_Bubbles_LoadCountdownArt_Return
	cmpi.b	#$E,d1
	bhs.s	Small_Bubbles_LoadCountdownArt_Return
	cmp.b	objoff_2E(a0),d1
	beq.s	Small_Bubbles_LoadCountdownArt_Return
	move.b	d1,objoff_2E(a0)
	subq.w	#8,d1
	move.w	d1,d0
	add.w	d1,d1
	add.w	d0,d1
	lsl.w	#6,d1
	addi.l	#ArtUnc_Countdown,d1
	move.w	#$9380,d2
	tst.b	parent+1(a0)
	beq.s	+
	move.w	#$9180,d2
+	move.w	#$60,d3
	jsr	(QueueDMATransfer).l

Small_Bubbles_LoadCountdownArt_Return:
	rts
; ===========================================================================

Small_Bubbles_CountdownP:
	andi.w	#$7F,d0
	move.b	d0,objoff_33(a0)
	move.w	#objroutine(Small_Bubbles_Countdown),(a0)	; go to routine Countdown

Small_Bubbles_Countdown:
	movea.l	objoff_3C(a0),a2		; a2=character
	tst.w	objoff_2C(a0)
	bne.w	loc_1D708
	move.w	(a2),d2	
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Bubbles_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_1D81C	
	move.w	Bubbles_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_1D81C	
	move.w	Bubbles_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	return_1D81C	
	bra.s	+
Bubbles_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

Bubbles_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)	

Bubbles_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)			
	
+	btst	#6,status(a2)			; is the player underwater?
	beq.w	return_1D81C			; if not, return
	subq.w	#1,objoff_38(a0)		; decrease timer
	bpl.w	loc_1D72C			; if time remains, branch
	move.w	#$3B,objoff_38(a0)		; reset timer
	move.w	#1,objoff_36(a0)
	jsr	(RandomNumber).l
	andi.w	#1,d0				; "flip a coin"
	move.b	d0,objoff_34(a0)		; store it
	moveq	#0,d0
	move.b	air_left(a2),d0			; check air remaining
	cmpi.w	#$19,d0
	beq.s	Small_Bubbles_WarnSound			; play ding sound if air is $19
	cmpi.w	#$14,d0
	beq.s	Small_Bubbles_WarnSound			; play ding sound if air is $14
	cmpi.w	#$F,d0
	beq.s	Small_Bubbles_WarnSound			; play ding sound if air is $F
	cmpi.w	#$C,d0
	bhi.s	Small_Bubbles_ReduceAir			; if air is above $C, branch
	bne.s	+
	tst.b	parent+1(a0)
	bne.s	+
	move.w	#MusID_Countdown,d0		; play countdown music
	jsr	(PlayMusic).l
+	subq.b	#1,objoff_32(a0)		; decrease other timer
	bpl.s	Small_Bubbles_ReduceAir			; if time remains, branch
	move.b	objoff_33(a0),objoff_32(a0)
	bset	#7,objoff_36(a0)
	bra.s	Small_Bubbles_ReduceAir
	
	
Small_Bubbles_WarnSound:
	tst.b	parent+1(a0)
	bne.s	Small_Bubbles_ReduceAir
	move.w	#SndID_WaterWarning,d0		; play "ding-ding" warning sound
	jsr	(PlaySound).l

Small_Bubbles_ReduceAir:
	movea.l	objoff_3C(a0),a2		; a2=character
	cmpa.w	#MainCharacter,a2
	bne.s	+				; if it isn't player 1, branch
	btst 	#3,status2(a2)		; does the player have a water shield?
	beq.b	+				; if not, branch
	rts
+	subq.b	#1,air_left(a2)			; subtract 1 from air remaining
	bcc.w	Small_Bubbles_MakeItem			; if air is above 0, branch
	ori.b	#lock_mask,status3(a2)		; lock controls
	move.w	#SndID_Drown,d0			; play drowning sound
	jsr	(PlaySound).l
	move.b	#$A,objoff_34(a0)
	move.w	#1,objoff_36(a0)
	move.w	#$78,objoff_2C(a0)
	movea.l	a2,a1
	bsr.w	ResumeMusic
	move.l	a0,-(sp)
	movea.l	a2,a0
	bsr.w	Sonic_ResetOnFloor_Part2
	move.b	#$17,anim(a0)			; use Sonic's drowning animation
	bset	#1,status(a0)
	bset	#7,art_tile(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,inertia(a0)
	movea.l	(sp)+,a0			; load obj address ; restore a0 = Small_Bubbles
	cmpa.w	#MainCharacter,a2
	bne.s	+				; if it isn't player 1, branch
	move.b	#1,(Deform_lock).w
+	rts
; ===========================================================================

loc_1D708:
	subq.w	#1,objoff_2C(a0)
	bne.s	+
	move.w	#objroutine(Small_Bubbles_Display),(a0)	; go to routine Display
-	rts
+	move.l	a0,-(sp)
	movea.l	a2,a0
	jsr	(ObjectMove).l
	addi.w	#$10,y_vel(a0)
	movea.l	(sp)+,a0			; load obj address

loc_1D72C:
	tst.w	objoff_36(a0)
	beq.w	-
	subq.w	#1,objoff_3A(a0)	; subtract time to next bubble
	bpl.w	-			; if time remains, return

Small_Bubbles_MakeItem:
	jsr	(RandomNumber).l
	andi.w	#$F,d0
	addq.w	#8,d0
	move.w	d0,objoff_3A(a0)	; set time to next bubble (random between 8 and 23 frames)
	jsr	(SingleObjLoad).l
	bne.w	return_1D81C
	move.w	#objroutine(Bubbles_Base_Bubble),(a1)	; load a bubble
	move.w	x_pos(a2),x_pos(a1)	; match its X position to Sonic
	moveq	#6,d0
	btst	#0,status(a2)		; is the player facing left?
	beq.s	+			; if not, branch
	neg.w	d0
	move.b	#$40,angle(a1)
+	add.w	d0,x_pos(a1)		; set bubble's x-position
	move.w	y_pos(a2),y_pos(a1)
	move.l	objoff_3C(a0),objoff_3C(a1)
	move.b	#0,anim(a1)		; set bubble's subtype to 6
	tst.w	objoff_2C(a0)
	beq.w	Small_Bubbles_MakeNumber
	andi.w	#7,objoff_3A(a0)
	addi.w	#0,objoff_3A(a0)
	move.w	y_pos(a2),d0
	subi.w	#$C,d0
	move.w	d0,y_pos(a1)		; set bubble's y-position
	jsr	(RandomNumber).l
	move.b	d0,angle(a1)		; set random angle for bubble
	move.w	(Timer_frames).w,d0	; get the timer
	andi.b	#3,d0
	bne.s	Small_Bubbles_MakeItem_Finish	; if not every 4th frame, branch
	move.b	#1,anim(a1)		; set bubble's subtype to $E
	bra.s	Small_Bubbles_MakeItem_Finish

Small_Bubbles_MakeNumber:
	btst	#7,objoff_36(a0)	; test some flag
	beq.s	Small_Bubbles_MakeItem_Finish	; if unset, branch
	moveq	#0,d2
	move.b	air_left(a2),d2		; get player's air remaining
	cmpi.b	#$C,d2			; is it higher than 12 seconds?
	bhs.s	Small_Bubbles_MakeItem_Finish	; if so, branch
	move.w	#objroutine(Small_Bubbles),(a1)	; load a bubble
	lsr.w	#1,d2
	move.b	d2,subtype(a1)
	move.w	#$1C,objoff_38(a1)

Small_Bubbles_MakeItem_Finish:
	subq.b	#1,objoff_34(a0)	; reduce some timer
	bpl.s	return_1D81C		; if time remains, branch
	clr.w	objoff_36(a0)

return_1D81C:
	rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to play music after a countdown (when Sonic leaves the water)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1D81E:
ResumeMusic:
	cmpi.b	#$C,air_left(a1)		; has countdown started yet?
	bhi.s	ResumeMusic_Done		; if not, branch
	cmpa.w	#MainCharacter,a1		; is it player 1?
	bne.s	ResumeMusic_Done		; if not, branch
	move.w	(Level_Music).w,d0		; prepare to play current level's music
	btst	#s2b_2,status2(a1)	; is Sonic invincible?
	beq.s	+				; if not, branch
	move.w	#MusID_Invincible,d0		; prepare to play invincibility music
+	btst	#s2b_3,status2(a1)	; is Sonic super or hyper?
	beq.w	+				; if not, branch
	move.w	#MusID_SuperSonic,d0		; prepare to play super sonic music
+	tst.b	(Current_Boss_ID).w		; are we in a boss?
	beq.s	+				; if not, branch
	move.w	#MusID_Boss,d0			; prepare to play boss music
+	jsr	(PlayMusic).l

ResumeMusic_Done:
	move.b	#$1E,air_left(a1)	; reset air to full
	rts

; ===========================================================================
; ----------------------------------------------------------------------------
; Object 05 - Small Patch of Bubbles
; ----------------------------------------------------------------------------
Bubbles_Base:
	lea	Bubbles_BaseData(pc),a2
	jsr	Load_Object1
	move.b	subtype(a0),d0				; get subtype
	andi.w	#$7F,d0
	move.b	d0,objoff_32(a0)			; store subtype twice
	move.b	d0,objoff_33(a0)
	move.b	#6,anim(a0)				; set animation
	move.w	#objroutine(Bubbles_Base_BubbleSource),(a0)	; go to routine BubbleSource

Bubbles_Base_BubbleSource:
	tst.w	objoff_36(a0)
	bne.s	loc_1FA22
	move.w	(Water_Level_1).w,d0
	cmp.w	y_pos(a0),d0				; are we underwater?
	bhs.w	Bubbles_Base_ChkDel				; if not, branch
	tst.b	render_flags(a0)			; are we onscreen?
	bpl.w	Bubbles_Base_ChkDel				; if not, branch
	subq.w	#1,objoff_38(a0)			; decrease some timer
	bpl.w	loc_1FAC2				; if time remains, branch
	move.w	#1,objoff_36(a0)
-	jsr	(RandomNumber).l			; get a random number
	move.w	d0,d1					; copy it
	andi.w	#7,d0
	cmpi.w	#6,d0
	bhs.s	-					; if a 1/4 chance, branch to retry
	move.b	d0,objoff_34(a0)			; store random number 0-5
	andi.w	#$C,d1
	lea	(byte_1FAF0).l,a1
	adda.w	d1,a1
	move.l	a1,objoff_3C(a0)			; store one of 4 random addresses
	subq.b	#1,objoff_32(a0)			; lower some timer
	bpl.s	loc_1FA2A				; if time remains, branch
	move.b	objoff_33(a0),objoff_32(a0)
	bset	#7,objoff_36(a0)
	bra.s	loc_1FA2A

loc_1FA22:
	subq.w	#1,objoff_38(a0)			; lower some other timer
	bpl.w	loc_1FAC2				; if time remains, branch

loc_1FA2A:
	jsr	(RandomNumber).l
	andi.w	#$1F,d0
	move.w	d0,objoff_38(a0)			; set time to next bubble load
	jsr	SingleObjLoad
	bne.s	loc_1FAA6
	move.w	#objroutine(Bubbles_Base_Bubble),(a1)		; load a bubble
	move.w	x_pos(a0),x_pos(a1)
	jsr	(RandomNumber).l
	andi.w	#$F,d0
	subq.w	#8,d0
	add.w	d0,x_pos(a1)				; set random x-position
	move.w	y_pos(a0),y_pos(a1)			; copy y-position
	moveq	#0,d0
	move.b	objoff_34(a0),d0
	movea.l	objoff_3C(a0),a2
	move.b	(a2,d0.w),anim(a1)			; set anim from index
	btst	#7,objoff_36(a0)
	beq.s	loc_1FAA6
	jsr	(RandomNumber).l
	andi.w	#3,d0
	bne.s	+					; if 3/4 chance, branch
	bset	#6,objoff_36(a0)
	bne.s	loc_1FAA6
	move.b	#2,anim(a1)				; set big bubble anim
+	tst.b	objoff_34(a0)
	bne.s	loc_1FAA6
	bset	#6,objoff_36(a0)
	bne.s	loc_1FAA6
	move.b	#2,anim(a1)				; set big bubble anim

loc_1FAA6:
	subq.b	#1,objoff_34(a0)
	bpl.s	loc_1FAC2
	jsr	(RandomNumber).l
	andi.w	#$7F,d0
	addi.w	#$80,d0
	add.w	d0,objoff_38(a0)
	clr.w	objoff_36(a0)

loc_1FAC2:
	lea	(Ani_Bubbles_Base).l,a1
	jsr	(AnimateSprite).l

Bubbles_Base_ChkDel:
	move.w	x_pos(a0),d0
	andi.w	#$FF80,d0
	sub.w	(Camera_X_pos_coarse).w,d0
	cmpi.w	#$280,d0
	bls.b	+
	jmp	DeleteObject
+	move.w	(Water_Level_1).w,d0
	cmp.w	y_pos(a0),d0
	bhs.b	+
	jmp	DisplaySprite
+	rts
; ===========================================================================
byte_1FAF0:
	dc.b   0
	dc.b   1	; 1
	dc.b   0	; 2
	dc.b   0	; 3
	dc.b   0	; 4
	dc.b   0	; 5
	dc.b   1	; 6
	dc.b   0	; 7
	dc.b   0	; 8
	dc.b   0	; 9
	dc.b   0	; 10
	dc.b   1	; 11
	dc.b   0	; 12
	dc.b   1	; 13
	dc.b   0	; 14
	dc.b   0	; 15
	dc.b   1	; 16
	dc.b   0	; 17
; ===========================================================================

Bubbles_Base_Bubble:
	lea	Bubbles_BaseData2(pc),a2
	jsr	Load_Object1
	move.w	x_pos(a0),objoff_30(a0)			; store x-position
	jsr	(RandomNumber).l
	move.b	d0,angle(a0)				; set random angle

Bubbles_Base_BubbleBig:
	;ckhit.b	Bubbles_Base_BubbleBig2
	cmp.b	#2,anim(a0)
	bne.w	+
	lea	(Ani_Bubbles_Base).l,a1
	jsr	(AnimateSprite).l
+	cmpi.b	#6,mapping_frame(a0)		; is frame 6?
	bne.s	Bubbles_Base_BubbleBig2		; if not, branch
	move.b	#1,objoff_2E(a0)
	move.b	#$E,width_pixels(a0)
	move.b	#$E,height_pixels(a0)
	move.w	#objroutine(Bubbles_Base_BubbleBig2),(a0)	
	move.b	#6,collision_response(a0)

Bubbles_Base_BubbleBig2:
	tst.b	render_flags(a0)		; are we onscreen?
	bpl.w	JmpTo13_DeleteObject		; if not, branch to delete
	move.w	(Water_Level_1).w,d0
	cmp.w	y_pos(a0),d0			; are we underwater?
	bhs.w	Bubbles_Base_BubbleCollectedP		; if not, branch
	move.b	angle(a0),d0			; get the angle
	addq.b	#1,angle(a0)			; increase it
	andi.w	#$7F,d0
	lea	(Small_Bubbles_WobbleData).l,a1		; wobble
	move.b	(a1,d0.w),d0
	ext.w	d0
	add.w	objoff_30(a0),d0
	move.w	d0,x_pos(a0)			; change x-position
	bsr.s	JmpTo13_DisplaySprite
	jmp	ObjectMove			; change y-position

Bubbles_Base_CheckPlayer_UnrollTails:
	move.b	#$1E,height_pixels(a1)
	move.b	#18,width_pixels(a1)
	subq.w	#1,y_pos(a1)
	bra.b	Bubbles_Base_BubbleCollectedP

JmpTo13_DisplaySprite:
	jmp	(DisplaySprite).l

JmpTo13_DeleteObject:
	jmp	(DeleteObject).l
; ===========================================================================

Bubbles_Base_BubbleCollectedP:
	addq.b	#3,anim(a0)				; set animation
	move.w	#objroutine(Bubbles_Base_BubbleCollected),(a0)	; go to routine Bubbles_Base_BubbleCollected

Bubbles_Base_BubbleCollected:
	tst.b	mappings(a0)
	bmi.b	JmpTo13_DeleteObject
	lea	(Ani_Bubbles_Base).l,a1
	jsr	(AnimateSprite).l
	tst.b	render_flags(a0)			; are we onscreen?
	bpl.s	JmpTo13_DeleteObject			; if not, branch to delete
	jmp	(DisplaySprite).l
; ===========================================================================

Bubbles_BaseData:
		dc.w	objroutine(Bubbles_Base_BubbleBig)	; Routine
		dc.l	Bubbles_Base_MapUnc_1FC18			; Mappings
		dc.w	$8418								; Art tile
		dc.b	$84									; Render Flags
		dc.b	0									; Collision Response
		dc.w	$80									; Priority
		dc.b	$10									; Width Pixels
		dc.b	$10									; Height Pixels
		dc.w	0									; X Speed
		dc.w	0									; Y Speed
		dc.b	0									; Mapping
		
Bubbles_BaseData2:
		dc.w	objroutine(Bubbles_Base_BubbleBig)	; Routine
		dc.l	Bubbles_Base_MapUnc_1FC18			; Mappings
		dc.w	$8418								; Art tile
		dc.b	$84									; Render Flags
		dc.b	0									; Collision Response
		dc.w	$80									; Priority
		dc.b	$10									; Width Pixels
		dc.b	$10									; Height Pixels
		dc.w	0									; X Speed
		dc.w	-$88								; Y Speed
		dc.b	0									; Mapping		