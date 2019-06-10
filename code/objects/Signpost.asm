; ===========================================================================
; ----------------------------------------------------------------------------
; Object 08 - End of level sign post
; ----------------------------------------------------------------------------
; OST:
SignPost_spinframe		= $21	; frame in spin
SignPost_sparkletimer	= $22	; time to next sparkle generated
SignPost_sparkleframe	= $23	; position at which to load sparkle
SignPost_finalanim		= $24	; 4 if Tails only, 3 otherwise (determines what character to show)
; ----------------------------------------------------------------------------

SignPost:
	tst.w	(Two_player_mode).w			; are we playing a two-player game?
	beq.s	ObjSignpost_1P				; if not, branch
	move.l	#SignPost_MapUnc_19656,mappings(a0)	; load alternate mappings
	move.w	#$5E8,art_tile(a0)			; set alternate art offset
	move.b	#-1,($FFFFFFCA).w			; ???
	moveq	#0,d1
	move.w	#$1020,d1
	move.w	#-$80,d4
	moveq	#0,d5
	bsr.w	ObjSignpost_Display2
	bra.s	ObjSignpost_Init2

ObjSignpost_1P:
	move.l	#SignPost_MapUnc_195BE,mappings(a0)	; load normal mappings
	move.w	#$434,art_tile(a0)			; set normal art offset

ObjSignpost_Init2:
	move.w	#objroutine(ObjSignpost_Main),(a0)	; go to routine ObjSignpost_Main
	move.b	#4,render_flags(a0)			; align to the level
	move.b	#$18,width_pixels(a0)			; set width
	move.w	#$200,priority(a0)				; set priority
	move.w	#$3C3C,(Loser_Time_Left).w

ObjSignpost_Main:
	tst.b	(Update_HUD_timer).w			; is the timer stopped?
	beq.w	ObjSignpost_Display			; if so, branch
	lea	(MainCharacter).w,a1
	move.w	x_pos(a1),d0				; get player's x-position
	sub.w	x_pos(a0),d0				; is the player to the left of us?
	bcs.w	ObjSignpost_Display			; if so, branch
	cmpi.w	#$20,d0					; is the player further than $20 pixels to the right of us?
	bhs.w	ObjSignpost_Display			; if so, branch
	move.w	#SndID_Signpost,d0			; play spinning sound
	jsr	(PlayMusic).l
	clr.b	(Update_HUD_timer).w			; stop the timer
	move.w	#1,anim(a0)				; use animation 1
	move.b	#0,SignPost_spinframe(a0)
	move.w	Camera_Max_X_pos,Camera_Min_X_pos	; lock screen
	move.w	#objroutine(ObjSignpost_Spin),(a0)	; go to routine ObjSignpost_Spin
	cmpi.b	#$C,(Loser_Time_Left).w
	bhi.s	+
	move.w	(Level_Music).w,d0
	jsr	(PlayMusic).l				; play zone music
+	tst.b	SignPost_finalanim(a0)			; did we already set the target frame?
	bne.w	ObjSignpost_Spin			; if so, branch
	move.b	#3,SignPost_finalanim(a0)			; set the target frame to Sonic
	cmpi.w	#2,(Player_mode).w			; are we playing Tails alone?
	bne.s	ObjSignpost_Spin			; if not, branch
	move.b	#4,SignPost_finalanim(a0)			; set the target frame to Tails

ObjSignpost_Spin:
	subq.b	#1,SignPost_spinframe(a0)			; subtract one from spin frame
	bpl.s	ObjSignpost_Spin2			; if not fully spun, branch
	move.b	#$3C,SignPost_spinframe(a0)		; reset spin frame to start
	addq.b	#1,anim(a0)				; increment number of spins
	cmpi.b	#3,anim(a0)				; have we spun thrice?
	bne.s	ObjSignpost_Spin2			; if not, branch
	move.w	#objroutine(ObjSignpost_Done_1P),(a0)
	move.b	SignPost_finalanim(a0),anim(a0)		; use the target frame
	tst.w	(Two_player_mode).w			; are we in two-player mode?
	beq.s	ObjSignpost_Spin2			; if not, branch
	move.w	#objroutine(ObjSignpost_Done_2P),(a0)

ObjSignpost_Spin2:
	subq.b	#1,SignPost_sparkletimer(a0)		; subtract 1 from sparkle timer
	bpl.w	ObjSignpost_Display			; if not ready for next sparkle, branch
	move.b	#$B,SignPost_sparkletimer(a0)		; reset sparkle counter
	moveq	#0,d0
	move.b	SignPost_sparkleframe(a0),d0
	addq.b	#2,SignPost_sparkleframe(a0)
	andi.b	#$E,SignPost_sparkleframe(a0)
	lea	SignPost_RingSparklePositions(pc,d0.w),a2	; get position to load sparkle in
	jsr	SingleObjLoad
	bne.w	ObjSignpost_Display
	move.w	#objroutine(ObjRing_Sparkle),id(a1)	; load a ring sparkle object
	move.b	(a2)+,d0
	ext.w	d0
	add.w	x_pos(a0),d0
	move.w	d0,x_pos(a1)				; set x-position
	move.b	(a2)+,d0
	ext.w	d0
	add.w	y_pos(a0),d0
	move.w	d0,y_pos(a1)				; set y-position
	move.l	#Basic_Ring_MapUnc_12382,mappings(a1)	; set mappings
	move.w	#$26BC,art_tile(a1)			; set art offset
	move.b	#4,render_flags(a1)			; align to the level
	move.w	#$100,priority(a1)				; set priority
	move.b	#8,width_pixels(a1)			; set width

return_19406:
	bra.w	ObjSignpost_Display
; ===========================================================================
; byte_19408:
SignPost_RingSparklePositions:
	dc.b -24,-16	; 1
	dc.b   8,  8	; 3
	dc.b -16,  0	; 5
	dc.b  24, -8	; 7
	dc.b   0, -8	; 9
	dc.b  16,  0	; 11
	dc.b -24,  8	; 13
	dc.b  24, 16	; 15
; ===========================================================================
; loc_19418:
ObjSignpost_Done_1P:
	tst.w	(Debug_placement_mode).w		; is debug mode in use?
	bne.w	return_194D0				; if so, return
	lea	(MainCharacter).w,a1
	jsr	EndOfAct_LockControls			; lock the controls

loc_1944C:
	move.w	#objroutine(ObjSignpost_Display),(a0)
	jsr	GotThroughAct
	bra.w	ObjSignpost_Display

GotThroughAct:
	clr.b	status2(a1)
	clr.b	(Update_HUD_timer).w
	jsr	SingleObjLoad
	;bne.s	+
	;move.w	#objroutine(Obj3A),id(a1) ; load obj3A (end of level results screen)
+
	moveq	#PLCID_Results,d0
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	moveq	#PLCID_ResultsTails,d0
+
	jsr	(LoadPLC2).l
	move.b	#1,(Update_Bonus_score).w
	moveq	#0,d0
	move.b	(Timer_minute).w,d0
	mulu.w	#$3C,d0
	moveq	#0,d1
	move.b	(Timer_second).w,d1
	add.w	d1,d0
	divu.w	#$F,d0
	moveq	#$14,d1
	cmp.w	d1,d0
	blo.s	+
	move.w	d1,d0
+
	add.w	d0,d0
	move.w	TimeBonuses(pc,d0.w),(Bonus_Countdown_1).w
	move.w	(Ring_count).w,d0
	mulu.w	#$A,d0
	move.w	d0,(Bonus_Countdown_2).w
	clr.w	($FFFFFF8E).w
	clr.w	($FFFFFF92).w
	tst.w	(Perfect_rings_left).w
	bne.s	+
	move.w	#5000,($FFFFFF92).w
+
	move.w	#MusID_EndLevel,d0
	jsr	(PlayMusic).l

return_194D0:
	rts

EndOfAct_LockControls:
	clr.b	$39(a1)		; Charging spindash/forced roll	flag
	clr.w	$10(a1)		; X vel
	clr.w	$12(a1)		; Y vel
	clr.w	$14(a1)		; Momentum/inertia/whatever
	bclr	#5,$22(a1)	; Pushing flag
	bclr	#7,$2B(a1)
	move.b	#1,(Control_Locked).w
;	move.b	#$13,$1C(a1)	; End of act pose
	move.b	#7,(Current_Boss_ID).w
	rts

; End of function EndOfAct_LockControls
; ===========================================================================
; word_194D2:
TimeBonuses:
	dc.w 5000, 5000, 1000, 500, 400, 400, 300, 300
	dc.w  200,  200,  200, 200, 100, 100, 100, 100
	dc.w   50,   50,   50,  50,   0
; ===========================================================================
; loc_194FC:
ObjSignpost_Done_2P:
	subq.b	#1,SignPost_spinframe(a0)
	bpl.s	ObjSignpost_Display
	tst.b	(Time_Over_flag).w
	bne.s	ObjSignpost_Display
	tst.b	(Update_HUD_timer).w
	bne.s	ObjSignpost_Display
	lea	(MainCharacter).w,a1
	jsr	EndOfAct_LockControls
	move.b	#0,(Last_star_pole_hit).w
	move.b	#0,(Last_star_pole_hit_2P).w

ObjSignpost_Display:
	lea	(Ani_SignPost).l,a1
	jsr	AnimateSprite
	tst.w	(Two_player_mode).w
	beq.s	return_1958C
	moveq	#0,d0
	move.b	mapping_frame(a0),d0
	cmp.b	($FFFFFFCA).w,d0
	beq.s	return_1958C
	move.b	d0,($FFFFFFCA).w
	lea	(SignPost_MapUnc_196EE).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	return_1958C
	move.w	#$BD00,d4
-	moveq	#0,d1
	move.w	(a2)+,d1

ObjSignpost_Display2:
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	addi.l	#ArtUnc_Signpost,d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,-

return_1958C:
	rts

; ===========================================================================
; ----------------------------------------------------------------------------
; Object 09 - Egg prison
; ----------------------------------------------------------------------------

Egg_Prison_Data:
	dc.w	objroutine(Egg_Prison_Main)
	dc.b	  0
	dc.b	$20
	dc.w	$200
	dc.b	0
	dc.w	objroutine(Egg_Prison_Button)
	dc.b	$28
	dc.b	$10
	dc.w	$280
	dc.b	4
	dc.w	objroutine(JmpTo40_MarkObjGone)
	dc.b	$18
	dc.b	8
	dc.w	$180
	dc.b	5
	dc.w	objroutine(return_3F404)
	dc.b	  0
	dc.b	$20
	dc.w	$200
	dc.b	0
; ===========================================================================

Egg_Prison:
	movea.l	a0,a1
	lea	objoff_38(a0),a3
	lea	Egg_Prison_Data(pc),a2
	moveq	#3,d1
	bra.s	+
-	jsr	SingleObjLoad
	bne.s	Egg_Prison_Return
	move.w	a1,(a3)+
+	move.w	(a2)+,(a1) ; load obj
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	y_pos(a0),objoff_30(a1)
	move.l	#Egg_Prison_MapUnc_3F436,mappings(a1)
	move.w	#$2680,art_tile(a1)
	move.b	#$84,render_flags(a1)
	moveq	#0,d0
	move.b	(a2)+,d0
	sub.w	d0,y_pos(a1)
	move.w	y_pos(a1),objoff_30(a1)
	move.b	(a2)+,width_pixels(a1)
	move.w	(a2)+,priority(a1)
	move.b	(a2)+,mapping_frame(a1)
	dbf	d1,-

Egg_Prison_Return:
	rts
; ===========================================================================

Egg_Prison_Main:
	movea.w	objoff_38(a0),a1		; load address of button
	tst.w	objoff_32(a1)			; has button been pressed?
	beq.w	Egg_Prison_Solid			; if not, branch
	movea.w	objoff_3A(a0),a2		; load address of blinker
	move.w	#objroutine(Egg_Prison_Blinker),(a2)	; make blinker fly away
	move.w	#-$400,y_vel(a2)
	move.w	#$800,x_vel(a2)
	jsr	(SingleObjLoad).l
	bne.s	+
	move.w	#objroutine(Explosion_Alone),(a1)	; load explosion object alone
	move.w	x_pos(a2),x_pos(a1)
	move.w	y_pos(a2),y_pos(a1)
+	move.w	#$1D,objoff_34(a0)
	move.w	#objroutine(Egg_Prison_Explode),(a0)	; go to routine Explode
	bra.b	Egg_Prison_Solid
; ===========================================================================

Egg_Prison_Explode:
	subq.w	#1,objoff_34(a0)
	bpl.s	Egg_Prison_Solid
	move.b	#1,anim(a0)
	moveq	#7,d6
	move.w	#$9A,d5
	moveq	#-$1C,d4
-	jsr	(SingleObjLoad).l
	bne.s	+
	move.w	#objroutine(Animal_From_Badnik),id(a1)	; load animal object
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	add.w	d4,x_pos(a1)
	move.b	#1,objoff_38(a1)
	addq.w	#7,d4
	move.w	d5,objoff_36(a1)
	subq.w	#8,d5
	dbf	d6,-
+	movea.w	objoff_3C(a0),a2 ; a2=object
	move.w	#$B4,anim_frame_duration(a2)
	move.w	#objroutine(Egg_Prison_Animals),(a2)	; make animals jump out
	move.w	#objroutine(Egg_Prison_Solid),(a0)	; go to routine Solid
; ===========================================================================

Egg_Prison_Solid:
	move.w	#$2B,d1
	move.w	#$18,d2
	move.w	#$18,d3
	move.w	x_pos(a0),d4
	jsr	(SolidObject).l
	lea	(Ani_Egg_Prison).l,a1
	jsr	(AnimateSprite).l
	jmp	(MarkObjGone).l
; ===========================================================================

Egg_Prison_Button:
	move.w	#$1B,d1
	move.w	#8,d2
	move.w	#8,d3
	move.w	x_pos(a0),d4
	jsr	(SolidObject).l
	move.w	objoff_30(a0),y_pos(a0)
	move.b	status(a0),d0
	andi.b	#$18,d0
	beq.s	JmpTo40_MarkObjGone
	addq.w	#8,y_pos(a0)
	clr.b	(Update_HUD_timer).w
	move.w	#1,objoff_32(a0)

JmpTo40_MarkObjGone
	jmp	(MarkObjGone).l
; ===========================================================================

Egg_Prison_Blinker:
	tst.b	render_flags(a0)
	bpl.w	+
	jsr	(ObjectMoveAndFall).l
	jmp	(MarkObjGone).l
+	jmp	(DeleteObject).l
; ===========================================================================

Egg_Prison_Animals:
	move.b	(Vint_runcount+3).w,d0
	andi.b	#7,d0
	bne.s	loc_3F3F4
	jsr	(SingleObjLoad).l
	bne.s	loc_3F3F4
	move.w	#objroutine(Animal_From_Badnik),id(a1) ; load obj
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	jsr	(RandomNumber).l
	andi.w	#$1F,d0
	subq.w	#6,d0
	tst.w	d1
	bpl.s	+
	neg.w	d0
+	add.w	d0,x_pos(a1)
	move.b	#1,objoff_38(a1)
	move.w	#$C,objoff_36(a1)

loc_3F3F4:
	subq.w	#1,anim_frame_duration(a0)
	bne.s	return_3F404
	move.w	#objroutine(Egg_Prison_Animals_Wait),(a0)
	move.w	#$B4,anim_frame_duration(a0)

return_3F404:
	rts
; ===========================================================================

Egg_Prison_Animals_Wait:
	tst.b	(AnimalsCounter).w
	beq.b	+
	rts
+	jsr	(GotThroughAct).l
	jmp	(DeleteObject).l

; ===========================================================================
; ----------------------------------------------------------------------------
; Object 04 - Star pole / starpost / checkpoint
; ----------------------------------------------------------------------------

CheckPoint:
	move.w	#objroutine(CheckPoint_Main),(a0)		; go to routine Main
	move.l	#CheckPoint_MapUnc_1F424,mappings(a0)
	move.w	#$490,art_tile(a0)
	move.b	#4,render_flags(a0)
	move.b	#8,width_pixels(a0)
	move.w	#$280,priority(a0)
	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	bclr	#7,2(a2,d0.w)
	btst	#0,2(a2,d0.w)
	bne.s	loc_1F120
	move.b	(Last_star_pole_hit).w,d1
	andi.b	#$7F,d1
	move.b	subtype(a0),d2
	andi.b	#$7F,d2
	cmp.b	d2,d1
	blo.s	CheckPoint_Main

loc_1F120:
	bset	#0,2(a2,d0.w)
	move.b	#2,anim(a0)

CheckPoint_Main:
	tst.w	(Debug_placement_mode).w
	bne.w	CheckPoint_Animate
	lea	(MainCharacter).w,a3 ; a3=character
	move.b	(Last_star_pole_hit).w,d1
	bsr.s	CheckPoint_CheckActivation
	tst.w	(Two_player_mode).w
	beq.w	CheckPoint_Animate
	lea	(Sidekick).w,a3 ; a3=character
	move.b	(Last_star_pole_hit_2P).w,d1
	bsr.s	CheckPoint_CheckActivation
	bra.w	CheckPoint_Animate
; ---------------------------------------------------------------------------

CheckPoint_CheckActivation:
	andi.b	#$7F,d1
	move.b	subtype(a0),d2
	andi.b	#$7F,d2
	cmp.b	d2,d1
	bhs.w	loc_1F222
	move.w	x_pos(a3),d0
	sub.w	x_pos(a0),d0
	addi.w	#8,d0
	cmpi.w	#$10,d0
	bhs.w	return_1F220
	move.w	y_pos(a3),d0
	sub.w	y_pos(a0),d0
	addi.w	#$40,d0
	cmpi.w	#$68,d0
	bhs.w	return_1F220
	move.w	#SndID_Checkpoint,d0 ; checkpoint ding-dong sound
	jsr	(PlaySound).l
	jsr	(SingleObjLoad).l
	bne.s	+
	move.w	#objroutine(CheckPoint_Dongle),(a1)	; load dongle object
	move.w	x_pos(a0),objoff_30(a1)
	move.w	y_pos(a0),objoff_32(a1)
	subi.w	#$14,objoff_32(a1)
	move.l	mappings(a0),mappings(a1)
	move.w	art_tile(a0),art_tile(a1)
	move.b	#4,render_flags(a1)
	move.b	#8,width_pixels(a1)
	move.w	#$200,priority(a1)
	move.b	#2,mapping_frame(a1)
	move.w	#$20,objoff_36(a1)
	move.w	a0,parent(a1)
;	tst.w	(Two_player_mode).w
;	bne.s	loc_1F206
;	cmpi.b	#7,(Emerald_count).w
;	beq.s	loc_1F206
;	cmpi.w	#50,(Ring_count).w
;	blo.s	loc_1F206
;	bsr.w	CheckPoint_MakeSpecialStars
+	move.b	#1,anim(a0)
	bsr.w	CheckPoint_SaveData
	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	bset	#0,2(a2,d0.w)

return_1F220:
	rts
; ===========================================================================

loc_1F222:
	tst.b	anim(a0)
	bne.s	return_1F22E
	move.b	#2,anim(a0)

return_1F22E:
	rts
; ===========================================================================

CheckPoint_Animate:
	lea	(Ani_CheckPoint).l,a1
	jsr	AnimateSprite
	jmp	(MarkObjGone).l
; ===========================================================================

CheckPoint_Dongle:
	subq.w	#1,objoff_36(a0)
	bpl.s	CheckPoint_MoveDonglyThing
	movea.w	parent(a0),a1 ; a1=object
	cmpi.b	#$79,(a1)
	bne.s	+
	move.b	#2,anim(a1)
	move.b	#0,mapping_frame(a1)
+	jmp	(DeleteObject).l
; ===========================================================================

CheckPoint_MoveDonglyThing:
	move.b	angle(a0),d0
	subi.b	#$10,angle(a0)
	subi.b	#$40,d0
	jsr	(CalcSine).l
	muls.w	#$C00,d1
	swap	d1
	add.w	objoff_30(a0),d1
	move.w	d1,x_pos(a0)
	muls.w	#$C00,d0
	swap	d0
	add.w	objoff_32(a0),d0
	move.w	d0,y_pos(a0)
	jmp	(MarkObjGone).l
; ===========================================================================
; hit a starpost / save checkpoint

CheckPoint_SaveData:
	cmpa.w	#MainCharacter,a3	; is it player 1?
	bne.w	CheckPoint_SaveDataPlayer2	; if not, branch
	move.b	subtype(a0),(Last_star_pole_hit).w
	move.b	(Last_star_pole_hit).w,(Saved_Last_star_pole_hit).w
	move.w	x_pos(a0),(Saved_x_pos).w
	move.w	y_pos(a0),(Saved_y_pos).w
	move.w	(MainCharacter+art_tile).w,(Saved_art_tile).w
	move.w	(MainCharacter+layer).w,(Saved_layer).w
	move.w	(Ring_count).w,(Saved_Ring_count).w
	move.b	(Extra_life_flags).w,(Saved_Extra_life_flags).w
	move.l	(Timer).w,(Saved_Timer).w
	move.b	(Dynamic_Resize_Routine).w,(Saved_Dynamic_Resize_Routine).w
	move.w	(Camera_Max_Y_pos_now).w,(Saved_Camera_Max_Y_pos).w
	move.w	(Camera_X_pos).w,(Saved_Camera_X_pos).w
	move.w	(Camera_Y_pos).w,(Saved_Camera_Y_pos).w
	move.w	(Camera_BG_X_pos).w,(Saved_Camera_BG_X_pos).w
	move.w	(Camera_BG_Y_pos).w,(Saved_Camera_BG_Y_pos).w
	move.w	(Camera_BG2_X_pos).w,(Saved_Camera_BG2_X_pos).w
	move.w	(Camera_BG2_Y_pos).w,(Saved_Camera_BG2_Y_pos).w
	;move.w	(Camera_BG3_X_pos).w,(Saved_Camera_BG3_X_pos).w
	;move.w	(Camera_BG3_Y_pos).w,(Saved_Camera_BG3_Y_pos).w
	move.w	(Water_Level_2).w,(Saved_Water_Level).w
	move.b	(Water_routine).w,(Saved_Water_routine).w
	move.b	(Water_fullscreen_flag).w,(Saved_Water_move).w
	rts
; ===========================================================================
; second player hit a checkpoint in 2-player mode

CheckPoint_SaveDataPlayer2:
	move.b	subtype(a0),(Last_star_pole_hit_2P).w
	move.b	(Last_star_pole_hit_2P).w,(Saved_Last_star_pole_hit_2P).w
	move.w	x_pos(a0),(Saved_x_pos_2P).w
	move.w	y_pos(a0),(Saved_y_pos_2P).w
	move.w	(Sidekick+art_tile).w,(Saved_art_tile_2P).w
	move.w	(Sidekick+layer).w,(Saved_layer_2P).w
	move.w	(Ring_count_2P).w,(Saved_Ring_count_2P).w
	move.b	(Extra_life_flags_2P).w,(Saved_Extra_life_flags_2P).w
	move.l	(Timer_2P).w,(Saved_Timer_2P).w
	rts
; ===========================================================================
; continue from a starpost / load checkpoint

CheckPoint_LoadData:
	move.b	(Saved_Last_star_pole_hit).w,(Last_star_pole_hit).w
	move.w	(Saved_x_pos).w,(MainCharacter+x_pos).w
	move.w	(Saved_y_pos).w,(MainCharacter+y_pos).w
	move.w	(Saved_Ring_count).w,(Ring_count).w
	move.b	(Saved_Extra_life_flags).w,(Extra_life_flags).w
	clr.w	(Ring_count).w
	clr.b	(Extra_life_flags).w
	move.l	(Saved_Timer).w,(Timer).w
	move.b	#59,(Timer_frame).w
	subq.b	#1,(Timer_second).w
	move.w	(Saved_art_tile).w,(MainCharacter+art_tile).w
	move.w	(Saved_layer).w,(MainCharacter+layer).w
	move.b	(Saved_Dynamic_Resize_Routine).w,(Dynamic_Resize_Routine).w
	move.b	(Saved_Water_routine).w,(Water_routine).w
	move.w	(Saved_Camera_Max_Y_pos).w,(Camera_Max_Y_pos_now).w
	move.w	(Saved_Camera_Max_Y_pos).w,(Camera_Max_Y_pos).w
	move.w	(Saved_Camera_X_pos).w,(Camera_X_pos).w
	move.w	(Saved_Camera_Y_pos).w,(Camera_Y_pos).w
	move.w	(Saved_Camera_BG_X_pos).w,(Camera_BG_X_pos).w
	move.w	(Saved_Camera_BG_Y_pos).w,(Camera_BG_Y_pos).w
	move.w	(Saved_Camera_BG2_X_pos).w,(Camera_BG2_X_pos).w
	move.w	(Saved_Camera_BG2_Y_pos).w,(Camera_BG2_Y_pos).w
	;move.w	(Saved_Camera_BG3_X_pos).w,(Camera_BG3_X_pos).w
	;move.w	(Saved_Camera_BG3_Y_pos).w,(Camera_BG3_Y_pos).w
	tst.b	(Water_flag).w	; does the level have water?
	beq.s	+		; if not, branch to skip loading water stuff
	move.w	(Saved_Water_Level).w,(Water_Level_2).w
	move.b	(Saved_Water_routine).w,(Water_routine).w
	move.b	(Saved_Water_move).w,(Water_fullscreen_flag).w
+
	tst.b	(Last_star_pole_hit).w
	bpl.s	return_1F412
	move.w	(Saved_x_pos).w,d0
	subi.w	#$A0,d0
	move.w	d0,(Camera_Min_X_pos).w

return_1F412:
	rts
; ===========================================================================

CheckPoint_MakeSpecialStars:
	moveq	#4-1,d1 ; execute the loop 4 times (1 for each star)
	moveq	#0,d2

-	jsr	SingleObjLoad2
	bne.s	+	; rts
	move.w	#objroutine(CheckPoint_Star),(a1)	; load star object
	move.l	#CheckPoint_MapUnc_1F4A0,mappings(a1)
	move.w	#$490,art_tile(a1)
	move.b	#4,render_flags(a1)
	move.w	x_pos(a0),d0
	move.w	d0,x_pos(a1)
	move.w	d0,objoff_30(a1)
	move.w	y_pos(a0),d0
	subi.w	#$30,d0
	move.w	d0,y_pos(a1)
	move.w	d0,objoff_32(a1)
	move.w	priority(a0),priority(a1)
	move.b	#8,width_pixels(a1)
	move.b	#1,mapping_frame(a1)
	move.w	#-$400,x_vel(a1)
	move.w	#0,y_vel(a1)
	move.w	d2,objoff_34(a1) ; set the angle
	addi.w	#$40,d2 ; increase the angle for next time
	dbf	d1,- ; loop
+
	rts
; ===========================================================================

CheckPoint_Star:
	move.b	collision_response(a0),d0
	beq.w	loc_1F554
	andi.b	#1,d0
	beq.s	+
	move.b	#1,($FFFFF7CD).w
;	move.b	#GameModeID_SpecialStage,(Game_Mode).w ; => SpecialStage
+
	clr.b	collision_response(a0)

loc_1F554:
	addi.w	#$A,objoff_34(a0)
	move.w	objoff_34(a0),d0
	andi.w	#$FF,d0
	jsr	(CalcSine).l
	asr.w	#5,d0
	asr.w	#3,d1
	move.w	d1,d3
	move.w	objoff_34(a0),d2
	andi.w	#$3E0,d2
	lsr.w	#5,d2
	moveq	#2,d5
	moveq	#0,d4
	cmpi.w	#$10,d2
	ble.s	+
	neg.w	d1
+
	andi.w	#$F,d2
	cmpi.w	#8,d2
	ble.s	loc_1F594
	neg.w	d2
	andi.w	#7,d2

loc_1F594:
	lsr.w	#1,d2
	beq.s	+
	add.w	d1,d4
+
	asl.w	#1,d1
	dbf	d5,loc_1F594

	asr.w	#4,d4
	add.w	d4,d0
	addq.w	#1,objoff_36(a0)
	move.w	objoff_36(a0),d1
	cmpi.w	#$80,d1
	beq.s	loc_1F5BE
	bgt.s	loc_1F5C4

loc_1F5B4:
	muls.w	d1,d0
	muls.w	d1,d3
	asr.w	#7,d0
	asr.w	#7,d3
	bra.s	loc_1F5D6
; ===========================================================================

loc_1F5BE:
	move.b	#$D8,collision_response(a0) ; COLLISION CHANGE

loc_1F5C4:
	cmpi.w	#$180,d1
	ble.s	loc_1F5D6
	neg.w	d1
	addi.w	#$200,d1
	bpl.b	loc_1F5B4
	jmp	DeleteObject
; ===========================================================================

loc_1F5D6:
	move.w	objoff_30(a0),d2
	add.w	d3,d2
	move.w	d2,x_pos(a0)
	move.w	objoff_32(a0),d2
	add.w	d0,d2
	move.w	d2,y_pos(a0)
	addq.b	#1,anim_frame(a0)
	move.b	anim_frame(a0),d0
	andi.w	#6,d0
	lsr.w	#1,d0
	cmpi.b	#3,d0
	bne.s	+
	moveq	#1,d0
+
	move.b	d0,mapping_frame(a0)
	jmp	MarkObjGone
