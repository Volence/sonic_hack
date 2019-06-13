; ===========================================================================
; ----------------------------------------------------------------------------
; Sonic
; ----------------------------------------------------------------------------
	;Sonic_Init	; 0
	;Sonic_Control	; 2
	;Sonic_Hurt	; 4
	;Sonic_Dead	; 6
	;Sonic_Gone	; 8
	;Sonic_Respawning	;$A
; ===========================================================================	
Sonic:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+			; if not, branch
	jmp		(DebugMode).l
+	move.w	#objroutine(Sonic_Control),(a0)	; => Sonic_Control
	tst.b	(SonicSSFlag).w
	beq.s	+
	move.w	#20,$3A(a0)
+
	move.b	#$26,height_pixels(a0) ; this sets Sonic's collision height (2*pixels)
	move.b	#18,width_pixels(a0)
	move.l	#Mapunc_Sonic,mappings(a0)
	move.w	#$100,priority(a0)
	move.b	#$18,width_pixels(a0)
	move.b	#4,render_flags(a0)
	move.w	#$600,(Sonic_top_speed).w	; set Sonic's top speed
	move.w	#$C,(Sonic_acceleration).w	; set Sonic's acceleration
	move.w	#$80,(Sonic_deceleration).w	; set Sonic's deceleration
	tst.b	(Last_star_pole_hit).w
	bne.s	Sonic_Init_Continued
	; only happens when not starting at a checkpoint:
	move.w	#$780,art_tile(a0)
	move.b	#$C,layer(a0)
	move.b	#$D,layer_plus(a0)
	move.w	x_pos(a0),(Saved_x_pos).w
	move.w	y_pos(a0),(Saved_y_pos).w
	move.w	art_tile(a0),(Saved_art_tile).w
	move.w	layer(a0),(Saved_layer).w

Sonic_Init_Continued:
	move.b	#0,flips_remaining(a0)
	move.b	#4,flip_speed(a0)
	move.b	#$1E,air_left(a0)
	subi.w	#$20,x_pos(a0)
	addi.w	#4,y_pos(a0)
	move.w	#0,(Sonic_Pos_Record_Index).w

	move.w	#$3F,d2
-	bsr.w	Sonic_RecordPos
	subq.w	#4,a1
	move.l	#0,(a1)
	dbf	d2,-

	addi.w	#$20,x_pos(a0)
	subi.w	#4,y_pos(a0)

; ---------------------------------------------------------------------------
; Normal state for Sonic
; ---------------------------------------------------------------------------
; loc_1A030: Obj_01_Sub_2:
Sonic_Control:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+			; if not, branch
	jmp		(DebugMode).l
+
	;tst.w	(Debug_mode_flag).w	; is debug cheat enabled?
	;beq.s	+			; if not, branch
	btst	#button_B,(Ctrl_1_Press).w	; is button B pressed?
	beq.s	+			; if not, branch
	move.w	#1,(Debug_placement_mode).w	; change Sonic into a ring/item
	clr.b	(Control_Locked).w		; unlock control
	rts
; -----------------------------------------------------------------------
+	
	tst.b	(Control_Locked).w	; are controls locked?
	bne.s	+			; if yes, branch
	move.w	(Ctrl_1).w,(Ctrl_1_Logical).w	; copy new held buttons, to enable joypad control
+
	btst	#s3b_lock_motion,status3(a0)	; is Sonic interacting with another object that holds him in place or controls his movement somehow?
	bne.s	+			; if yes, branch to skip Sonic's control
	tst.b	(SonicFlyingFlag).w
	bne.w	SonicIsFlying
	moveq	#0,d0
	move.b	status(a0),d0
	andi.w	#6,d0	; %0000 %0110
	move.w	Sonic_Modes(pc,d0.w),d1
	jsr	Sonic_Modes(pc,d1.w)	; run Sonic's movement control code
+
	cmpi.w	#-$100,(Camera_Min_Y_pos).w	; is vertical wrapping enabled?
	bne.s	+				; if not, branch
	andi.w	#$7FF,y_pos(a0) 		; perform wrapping of Sonic's y position
	bra.s	+
SonicIsFlying:
	bsr.w	SonicFly
+
	bsr.w	Player_Display
	bsr.w	Sonic_Super
	bsr.w	Sonic_RecordPos
	bsr.w	Player_Water
	move.b	($FFFFF768).w,next_tilt(a0)
	move.b	($FFFFF76A).w,tilt(a0)
	tst.b	(WindTunnel_flag).w
	beq.s	SonicDisplayStuff
	tst.b	anim(a0)
	bne.s	SonicDisplayStuff
	move.b	next_anim(a0),anim(a0)
SonicDisplayStuff:
	bsr.w	Sonic_Animate
	btst	#s3b_lock_jumping,status3(a0)
	bne.s	+
	jsr	(TouchResponse).l
+	bra.w	LoadSonicDynPLC

; ============== JUMP TABLE =================================================
; secondary states under state Sonic_Control
; off_1A0BE:
Sonic_Modes:
	dc.w	Sonic_MdNormal_Checks - Sonic_Modes	; not airborne or rolling
	dc.w	Sonic_MdAir - Sonic_Modes		; airborne
	dc.w	Sonic_MdRoll - Sonic_Modes		; rolling
	dc.w	Sonic_MdJump - Sonic_Modes		; jumping
; ============== END JUMP TABLE =============================================
SonicFly:
	clr.w	$10(a0)
	clr.w	$12(a0)
	move.b	#2,anim(a0)
	btst	#button_up,(Ctrl_1_Held_Logical).w
	beq.s	+
	move.w	#-$400,$12(a0)
+
	btst	#button_down,(Ctrl_1_Held_Logical).w
	beq.s	+
	move.w	#$400,$12(a0)
+
	btst	#button_left,(Ctrl_1_Held_Logical).w
	beq.s	+
	move.w	#-$400,$10(a0)
+
	btst	#button_right,(Ctrl_1_Held_Logical).w
	beq.s	+
	move.w	#$400,$10(a0)
+
	tst.b	$39(a0)
	beq.s	+
	sub.b	#1,$39(a0)
	bra.s	SOnicObjectMove
+
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	beq.w	SOnicObjectMove

SonicLoadProjectile:
	jsr	SingleObjLoad
	bne.w	SOnicObjectMove
	;move.w	#objroutine(Obj0C),(a1)
	move.b	#5,mapping_frame(a1)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	#$800,x_vel(a1)
	move.b	#8,$39(a0)
SOnicObjectMove:
	move.l	x_pos(a0),d1
	move.w	x_vel(a0),d0
	ext.l	d0
	asl.l	#8,d0
	add.l	d0,d1
	swap	d1
	move.w	(Camera_Min_X_pos).w,d0
	addi.w	#$10,d0
	cmp.w	d1,d0			; has Sonic touched the left boundary?
	bhi.s	Sonic_Boundary_Sides1	; if yes, branch
	move.w	(Camera_Max_X_pos).w,d0
	addi.w	#$128,d0
	cmp.w	d1,d0			; has Sonic touched the right boundary?
	bls.s	Sonic_Boundary_Sides1	; if yes, branch

; loc_1A9A6:
Sonic_Boundary_CheckBottom2:
	move.w	(Camera_Min_Y_pos).w,d0
	add.w	#$10,d0
	cmp.w	y_pos(a0),d0		; has Sonic touched the bottom boundary?
	bge.s	Sonic_Boundary_Bottom21	; if yes, branch
	move.w	(Camera_Max_Y_pos).w,d0
	add.w	#$E0,d0
	sub.w	#$10,d0
	cmp.w	y_pos(a0),d0		; has Sonic touched the bottom boundary?
	ble.s	Sonic_Boundary_Bottom22	; if yes, branch
	jmp	ObjectMove

; loc_1A9BA:
Sonic_Boundary_Sides1:
	clr.w	$10(a0)
	bra.s	Sonic_Boundary_CheckBottom2
Sonic_Boundary_Bottom21:
	tst.w	$12(a0)
	bpl.s	+
	clr.w	$12(a0)
+
	jmp	ObjectMove
Sonic_Boundary_Bottom22:
	tst.w	$12(a0)
	bmi.s	+
	clr.w	$12(a0)
+
	jmp	ObjectMove
; ---------------------------------------------------------------------------
; Subroutine to record Sonic's previous positions for invincibility stars
; and input/status flags for Tails' AI to follow
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A15C:
Sonic_RecordPos:
	move.w	(Sonic_Pos_Record_Index).w,d0
	lea		(Sonic_Pos_Record_Buf).w,a1
	lea		(a1,d0.w),a1
	move.w	x_pos(a0),(a1)+
	move.w	y_pos(a0),(a1)+
	addq.b	#4,(Sonic_Pos_Record_Index+1).w

	lea	(Sonic_Stat_Record_Buf).w,a1
	lea	(a1,d0.w),a1
	move.w	(Ctrl_1_Logical).w,(a1)+
	move.w	status(a0),(a1)+

	rts
; End of subroutine Sonic_RecordPos

; ===========================================================================
SonicShoot:
	tst.b	(SonicSSFlag).w
	beq.w	return_1A2DE
	btst	#button_A,(Ctrl_1_Held_Logical).w
	beq.w	SSLocret
	tst.b	$39(a0)
	bpl.s	SSLocret
	jsr	SingleObjLoad
	bne.w	SOnicObjectMove
	;move.w	#objroutine(Obj0C),(a1)
	move.b	#5,mapping_frame(a1)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.b	#8,$39(a0)
	bra.s	+
SSLocret:
	sub.b	#1,$39(a0)
	rts
+
	btst	#button_up,(Ctrl_1_Held_Logical).w
	beq.s	+
	move.w	#-$800,$12(a1)
+
	btst	#0,render_flags(a0)
	bne.s	SSLeft
	tst.w	$12(a1)
	beq.s	+
	btst	#button_right,(Ctrl_1_Held_Logical).w
	beq.s	+++
+
	move.w	#$800,$10(a1)
	rts
SSLeft:
	tst.w	$12(a1)
	beq.s	+
	btst	#button_left,(Ctrl_1_Held_Logical).w
	beq.s	++
+
	move.w	#-$800,$10(a1)
+
	rts

; ---------------------------------------------------------------------------
; Start of subroutine Sonic_MdNormal
; Called if Sonic is neither airborne nor rolling this frame
; ---------------------------------------------------------------------------
; loc_1A26E:
Sonic_MdNormal_Checks:
	bsr.w	SonicShoot
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	bne.s	Sonic_MdNormal
	cmpi.b	#$A,anim(a0)
	beq.s	return_1A2DE
	cmpi.b	#$B,anim(a0)
	beq.s	return_1A2DE
	cmpi.b	#5,anim(a0)
	bne.s	Sonic_MdNormal
	cmpi.b	#$1E,anim_frame(a0)
	blo.s	Sonic_MdNormal
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_up_mask|button_down_mask|button_left_mask|button_right_mask|button_B_mask|button_C_mask|button_A_mask,d0
	beq.s	return_1A2DE
	move.b	#$A,anim(a0)
	cmpi.b	#$AC,anim_frame(a0)
	blo.s	return_1A2DE
	move.b	#$B,anim(a0)
	bra.s	return_1A2DE
; ---------------------------------------------------------------------------
; loc_1A2B8:
Sonic_MdNormal:
	jsr	Sonic_BounceRecoil
	bsr.w	ClearInstaShield_Ground
	bsr.w	Sonic_CheckSpindash
	bsr.w	Sonic_Jump
	bsr.w	Sonic_SlopeResist
	bsr.w	Sonic_Move
	bsr.w	Sonic_Roll
	bsr.w	Sonic_LevelBound
	jsr	Sonic_DoubleJump2
	jsr	(ObjectMove).l
	bsr.w	AnglePos
	bsr.w	Sonic_SlopeRepel

return_1A2DE:
	rts
; End of subroutine Sonic_MdNormal
; ===========================================================================
; Start of subroutine Sonic_MdAir
; Called if Sonic is airborne, but not in a ball (thus, probably not jumping)
; loc_1A2E0: Sonic_MdJump
Sonic_MdAir:
	bsr.w	SonicShoot
	bsr.w	ClearInstaShield_Air
	bsr.w	Sonic_JumpHeight
	bsr.w	Sonic_ChgJumpDir
	bsr.w	Sonic_LevelBound
	jsr	(ObjectMoveAndFall).l
	btst	#6,status(a0)	; is Sonic underwater?
	beq.s	+		; if not, branch
	subi.w	#$28,y_vel(a0)	; reduce gravity by $28 ($38-$28=$10)
+
	bsr.w	Sonic_JumpAngle
	bsr.w	Sonic_DoLevelCollision
	rts
; End of subroutine Sonic_MdAir
; ===========================================================================
; Start of subroutine Sonic_MdRoll
; Called if Sonic is in a ball, but not airborne (thus, probably rolling)
; loc_1A30A:
Sonic_MdRoll:
	tst.b	(SonicSSFlag).w
	bne.w	+
	btst	#s3b_spindash,status3(a0)
	bne.s	++
+
	bsr.w	Sonic_Jump
+
	bsr.w	Sonic_RollRepel
	bsr.w	Sonic_RollSpeed
	bsr.w	Sonic_LevelBound
	jsr	(ObjectMove).l
	bsr.w	AnglePos
	bsr.w	Sonic_SlopeRepel
	rts
; End of subroutine Sonic_MdRoll
; ===========================================================================
; Start of subroutine Sonic_MdJump
; Called if Sonic is in a ball and airborne (he could be jumping but not necessarily)
; Notes: This is identical to Sonic_MdAir, at least at this outer level.
;        Why they gave it a separate copy of the code, I don't know.
; loc_1A330: Sonic_MdJump2:
Sonic_MdJump:
	tst.b	(SonicSSFlag).w
	bne.w	+
	bsr.w	ClearInstaShield_Air
+
	bsr.w	Sonic_JumpHeight
	bsr.w	Sonic_ChgJumpDir
	bsr.w	Sonic_LevelBound
	tst.b	(SonicSSFlag).w
	bne.w	+
	jsr	Sonic_DoubleJump2
+
	jsr	(ObjectMoveAndFall).l
	btst	#6,status(a0)	; is Sonic underwater?
	beq.s	+		; if not, branch
	subi.w	#$28,y_vel(a0)	; reduce gravity by $28 ($38-$28=$10)
+
	bsr.w	Sonic_JumpAngle
	bsr.w	Sonic_DoLevelCollision
	rts
; End of subroutine Sonic_MdJump
; ---------------------------------------------------------------------------
; Subroutine to make Sonic walk/run
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
; loc_1A35A:
Sonic_Move:
	move.w	(Sonic_top_speed).w,d6
	move.w	(Sonic_acceleration).w,d5
	move.w	(Sonic_deceleration).w,d4
	tst.b	status2(a0)
	bmi.w	Sonic_Traction
	tst.w	move_lock(a0)
	bne.w	Sonic_ResetScr
	btst	#button_left,(Ctrl_1_Held_Logical).w	; is left being pressed?
	beq.s	Sonic_NotLeft			; if not, branch
	bsr.w	Sonic_MoveLeft

; loc_1A382:
Sonic_NotLeft:
	btst	#button_right,(Ctrl_1_Held_Logical).w	; is right being pressed?
	beq.s	Sonic_NotRight			; if not, branch
	bsr.w	Sonic_MoveRight

; loc_1A38E:
Sonic_NotRight:
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0		; is Sonic on a slope?
	bne.w	Sonic_ResetScr	; if yes, branch
	tst.w	inertia(a0)	; is Sonic moving?
	bne.w	Sonic_ResetScr	; if yes, branch
	bclr	#5,status(a0)
	move.b	#5,anim(a0)	; use "standing" animation
	btst	#3,status(a0)
	beq.w	Sonic_Balance
	moveq	#-1,d0
	move.w	interact_obj(a0),d0
	movea.l	d0,a1
	tst.b	status(a1)
	bmi.w	Sonic_Lookup
	moveq	#0,d1
	move.b	width_pixels(a1),d1
	move.w	d1,d2
	add.w	d2,d2
	subq.w	#2,d2
	add.w	x_pos(a0),d1
	sub.w	x_pos(a1),d1
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	bne.w	SuperSonic_Balance
	cmpi.w	#2,d1
	blt.s	Sonic_BalanceOnObjLeft
	cmp.w	d2,d1
	bge.s	Sonic_BalanceOnObjRight
	bra.w	Sonic_Lookup
; ---------------------------------------------------------------------------
; loc_1A3FE:
SuperSonic_Balance:
	cmpi.w	#2,d1
	blt.w	SuperSonic_BalanceOnObjLeft
	cmp.w	d2,d1
	bge.w	SuperSonic_BalanceOnObjRight
	bra.w	Sonic_Lookup
; ---------------------------------------------------------------------------
; balancing checks for when you're on the right edge of an object
; loc_1A410:
Sonic_BalanceOnObjRight:
	btst	#0,status(a0)
	bne.s	+
	move.b	#6,anim(a0)
	addq.w	#6,d2
	cmp.w	d2,d1
	blt.w	Sonic_ResetScr
	move.b	#$C,anim(a0)
	bra.w	Sonic_ResetScr
	; on right edge of object but facing left:
+	move.b	#$1D,anim(a0)
	addq.w	#6,d2
	cmp.w	d2,d1
	blt.w	Sonic_ResetScr
	move.b	#$1E,anim(a0)
	bclr	#0,status(a0)
	bra.w	Sonic_ResetScr
; ---------------------------------------------------------------------------
; balancing checks for when you're on the left edge of an object
; loc_1A44E:
Sonic_BalanceOnObjLeft:
	btst	#0,status(a0)
	beq.s	+
	move.b	#6,anim(a0)
	cmpi.w	#-4,d1
	bge.w	Sonic_ResetScr
	move.b	#$C,anim(a0)
	bra.w	Sonic_ResetScr
	; on left edge of object but facing right:
+	move.b	#$1D,anim(a0)
	cmpi.w	#-4,d1
	bge.w	Sonic_ResetScr
	move.b	#$1E,anim(a0)
	bset	#0,status(a0)
	bra.w	Sonic_ResetScr
; ---------------------------------------------------------------------------
; balancing checks for when you're on the edge of part of the level
; loc_1A48C:
Sonic_Balance:
	jsr	(ChkFloorEdge).l
	cmpi.w	#$C,d1
	blt.w	Sonic_Lookup
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	bne.w	SuperSonic_Balance2
	cmpi.b	#3,next_tilt(a0)
	bne.s	Sonic_BalanceLeft
	btst	#0,status(a0)
	bne.s	+
	move.b	#6,anim(a0)
	move.w	x_pos(a0),d3
	subq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Sonic_ResetScr
	move.b	#$C,anim(a0)
	bra.w	Sonic_ResetScr
	; on right edge but facing left:
+	move.b	#$1D,anim(a0)
	move.w	x_pos(a0),d3
	subq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Sonic_ResetScr
	move.b	#$1E,anim(a0)
	bclr	#0,status(a0)
	bra.w	Sonic_ResetScr
; ---------------------------------------------------------------------------
Sonic_BalanceLeft:
	cmpi.b	#3,tilt(a0)
	bne.s	Sonic_Lookup
	btst	#0,status(a0)
	beq.s	+
	move.b	#6,anim(a0)
	move.w	x_pos(a0),d3
	addq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Sonic_ResetScr
	move.b	#$C,anim(a0)
	bra.w	Sonic_ResetScr
	; on left edge but facing right:
+	move.b	#$1D,anim(a0)
	move.w	x_pos(a0),d3
	addq.w	#6,d3
	jsr	(ChkFloorEdge_Part2).l
	cmpi.w	#$C,d1
	blt.w	Sonic_ResetScr
	move.b	#$1E,anim(a0)
	bset	#0,status(a0)
	bra.w	Sonic_ResetScr
; ---------------------------------------------------------------------------
; loc_1A55E:
SuperSonic_Balance2:
	cmpi.b	#3,next_tilt(a0)
	bne.s	loc_1A56E

; loc_1A566:
SuperSonic_BalanceOnObjRight:
	bclr	#0,status(a0)
	bra.s	loc_1A57C
; ---------------------------------------------------------------------------
loc_1A56E:
	cmpi.b	#3,tilt(a0)
	bne.s	Sonic_Lookup

; loc_1A576:
SuperSonic_BalanceOnObjLeft:
	bset	#0,status(a0)

loc_1A57C:
	move.b	#6,anim(a0)
	bra.s	Sonic_ResetScr
; ---------------------------------------------------------------------------
; loc_1A584:
Sonic_Lookup:
	btst	#button_up,(Ctrl_1_Held_Logical).w	; is up being pressed?
	beq.s	Sonic_Duck			; if not, branch
	move.b	#7,anim(a0)			; use "looking up" animation
	addq.w	#1,(Sonic_Look_delay_counter).w
	cmpi.w	#$78,(Sonic_Look_delay_counter).w
	blo.s	Sonic_ResetScr_Part2
	move.w	#$78,(Sonic_Look_delay_counter).w
	cmpi.w	#$C8,(Camera_Y_pos_bias).w
	beq.s	Sonic_UpdateSpeedOnGround
	addq.w	#2,(Camera_Y_pos_bias).w
	bra.s	Sonic_UpdateSpeedOnGround
; ---------------------------------------------------------------------------
; loc_1A5B2:
Sonic_Duck:
	btst	#button_down,(Ctrl_1_Held_Logical).w	; is down being pressed?
	beq.s	Sonic_ResetScr			; if not, branch
	move.b	#8,anim(a0)			; use "ducking" animation
	addq.w	#1,(Sonic_Look_delay_counter).w
	cmpi.w	#$78,(Sonic_Look_delay_counter).w
	blo.s	Sonic_ResetScr_Part2
	move.w	#$78,(Sonic_Look_delay_counter).w
	cmpi.w	#8,(Camera_Y_pos_bias).w
	beq.s	Sonic_UpdateSpeedOnGround
	subq.w	#2,(Camera_Y_pos_bias).w
	bra.s	Sonic_UpdateSpeedOnGround

; ===========================================================================
; moves the screen back to its normal position after looking up or down
; loc_1A5E0:
Sonic_ResetScr:
	move.w	#0,(Sonic_Look_delay_counter).w
; loc_1A5E6:
Sonic_ResetScr_Part2:
	cmpi.w	#$60,(Camera_Y_pos_bias).w	; is screen in its default position?
	beq.s	Sonic_UpdateSpeedOnGround	; if yes, branch.
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias).w	; or subtract 2

; ---------------------------------------------------------------------------
; updates Sonic's speed on the ground
; ---------------------------------------------------------------------------
; sub_1A5F8:
Sonic_UpdateSpeedOnGround:
	tst.b	(SonicSSFlag).w
	beq.w	+
	btst	#button_up,(Ctrl_1_Held_Logical).w
	beq.s	+
	btst	#button_c,(Ctrl_1_Held_Logical).w
	bne.s	+
	move.w	#0,d0
	move.b	#$22,anim(a0)
	bra.s	+++
+
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.w	+
	move.w	#$C,d5
+
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_left_mask|button_right_mask,d0 ; is left/right pressed?
	bne.s	Sonic_Traction	; if yes, branch
	move.w	inertia(a0),d0
	beq.s	Sonic_Traction
	bmi.s	Sonic_SettleLeft

; slow down when facing right and not pressing a direction
; Sonic_SettleRight:
	sub.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)
	bra.s	Sonic_Traction
; ---------------------------------------------------------------------------
; slow down when facing left and not pressing a direction
; loc_1A624:
Sonic_SettleLeft:
	add.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)

; increase or decrease speed on the ground
; loc_1A630:
Sonic_Traction:
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	inertia(a0),d1
	asr.l	#8,d1
	move.w	d1,x_vel(a0)
	muls.w	inertia(a0),d0
	asr.l	#8,d0
	move.w	d0,y_vel(a0)

; stops Sonic from running through walls that meet the ground
; loc_1A64E:
Sonic_CheckWallsOnGround:
	move.b	angle(a0),d0
	addi.b	#$40,d0
	bmi.s	return_1A6BE
	move.b	#$40,d1
	tst.w	inertia(a0)
	beq.s	return_1A6BE
	bmi.s	+
	neg.w	d1
+
	move.b	angle(a0),d0
	add.b	d1,d0
	move.w	d0,-(sp)
	bsr.w	CalcRoomInFront
	move.w	(sp)+,d0
	tst.w	d1
	bpl.s	return_1A6BE
	asl.w	#8,d1
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	loc_1A6BA
	cmpi.b	#$40,d0
	beq.s	loc_1A6A8
	cmpi.b	#$80,d0
	beq.s	loc_1A6A2
	add.w	d1,x_vel(a0)
	bset	#5,status(a0)
	move.w	#0,inertia(a0)
	rts
; ---------------------------------------------------------------------------
loc_1A6A2:
	sub.w	d1,y_vel(a0)
	rts
; ---------------------------------------------------------------------------
loc_1A6A8:
	sub.w	d1,x_vel(a0)
	bset	#5,status(a0)
	move.w	#0,inertia(a0)
	rts
; ---------------------------------------------------------------------------
loc_1A6BA:
	add.w	d1,y_vel(a0)

return_1A6BE:
	rts
; End of subroutine Sonic_Move


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A6C0:
Sonic_MoveLeft:
	move.w	inertia(a0),d0
	beq.s	+
	bpl.s	Sonic_TurnLeft ; if Sonic is already moving to the right, branch
+
	bset	#0,status(a0)
	bne.s	+
	bclr	#5,status(a0)
	move.b	#1,next_anim(a0)
+
	sub.w	d5,d0	; add acceleration to the left
	move.w	d6,d1
	neg.w	d1
	cmp.w	d1,d0	; compare new speed with top speed
	bgt.s	+	; if new speed is less than the maximum, branch
	add.w	d5,d0	; remove this frame's acceleration change
	cmp.w	d1,d0	; compare speed with top speed
	ble.s	+	; if speed was already greater than the maximum, branch
	move.w	d1,d0	; limit speed on ground going left
+
	move.w	d0,inertia(a0)
	move.b	#0,anim(a0)	; use walking animation
	rts
; ---------------------------------------------------------------------------
; loc_1A6FA:
Sonic_TurnLeft:
	sub.w	d4,d0
	bcc.s	+
	move.w	#-$80,d0
+
	move.w	d0,inertia(a0)
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	bne.s	return_1A744
	cmpi.w	#$400,d0
	blt.s	return_1A744
	move.b	#$D,anim(a0)	; use "stopping" animation
	bclr	#0,status(a0)
	move.w	#SndID_Skidding,d0
	jsr	(PlaySound).l
	cmpi.b	#$C,air_left(a0)
	blo.s	return_1A744	; if he's drowning, branch to not make dust
	move.w	#objroutine(Water_Splash_Object_CheckSkid),Sonic_Dust
	move.b	#$15,(Sonic_Dust+mapping_frame).w

return_1A744:
	rts
; End of subroutine Sonic_MoveLeft


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A746:
Sonic_MoveRight:
	move.w	inertia(a0),d0
	bmi.s	Sonic_TurnRight	; if Sonic is already moving to the left, branch
	bclr	#0,status(a0)
	beq.s	+
	bclr	#5,status(a0)
	move.b	#1,next_anim(a0)
+
	add.w	d5,d0	; add acceleration to the right
	cmp.w	d6,d0	; compare new speed with top speed
	blt.s	+	; if new speed is less than the maximum, branch
	sub.w	d5,d0	; remove this frame's acceleration change
	cmp.w	d6,d0	; compare speed with top speed
	bge.s	+	; if speed was already greater than the maximum, branch
	move.w	d6,d0	; limit speed on ground going right
+
	move.w	d0,inertia(a0)
	move.b	#0,anim(a0)	; use walking animation
	rts
; ---------------------------------------------------------------------------
; loc_1A77A:
Sonic_TurnRight:
	add.w	d4,d0
	bcc.s	+
	move.w	#$80,d0
+
	move.w	d0,inertia(a0)
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	bne.s	return_1A7C4
	cmpi.w	#-$400,d0
	bgt.s	return_1A7C4
	move.b	#$D,anim(a0)	; use "stopping" animation
	bset	#0,status(a0)
	move.w	#SndID_Skidding,d0	; use "stopping" sound
	jsr	(PlaySound).l
	cmpi.b	#$C,air_left(a0)
	blo.s	return_1A7C4	; if he's drowning, branch to not make dust
	move.w	#objroutine(Water_Splash_Object_CheckSkid),Sonic_Dust
	move.b	#$15,(Sonic_Dust+mapping_frame).w

return_1A7C4:
	rts
; End of subroutine Sonic_MoveRight

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's speed as he rolls
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A7C6:
Sonic_RollSpeed:
	move.w	(Sonic_top_speed).w,d6
	asl.w	#1,d6
	move.w	(Sonic_acceleration).w,d5
	asr.w	#1,d5	; natural roll deceleration = 1/2 normal acceleration
	move.w	#$20,d4	; controlled roll deceleration... interestingly,
			; this should be Sonic_deceleration/4 according to Tails_RollSpeed,
			; which means Sonic is much better than Tails at slowing down his rolling when he's underwater
	tst.b	status2(a0)
	bmi.w	Sonic_Roll_ResetScr
	tst.w	move_lock(a0)
	bne.s	Sonic_ApplyRollSpeed
	btst	#button_left,(Ctrl_1_Held_Logical).w	; is left being pressed?
	beq.s	+				; if not, branch
	bsr.w	Sonic_RollLeft
+
	btst	#button_right,(Ctrl_1_Held_Logical).w	; is right being pressed?
	beq.s	Sonic_ApplyRollSpeed		; if not, branch
	bsr.w	Sonic_RollRight

; loc_1A7FC:
Sonic_ApplyRollSpeed:
	move.w	inertia(a0),d0
	beq.s	Sonic_CheckRollStop
	bmi.s	Sonic_ApplyRollSpeedLeft

; Sonic_ApplyRollSpeedRight:
	sub.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)
	bra.s	Sonic_CheckRollStop
; ---------------------------------------------------------------------------
; loc_1A812:
Sonic_ApplyRollSpeedLeft:
	add.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)

; loc_1A81E:
Sonic_CheckRollStop:
	tst.w	inertia(a0)
	bne.s	Sonic_Roll_ResetScr
	tst.b	(SonicSSFlag).w
	bne.w	+
	btst	#s3b_spindash,status3(a0) ; note: the spindash flag has a different meaning when Sonic's already rolling -- it's used to mean he's not allowed to stop rolling
	bne.s	Sonic_KeepRolling
+
	bclr	#2,status(a0)
	move.b	#$26,height_pixels(a0)
	move.b	#18,width_pixels(a0)
	move.b	#5,anim(a0)
	subq.w	#5,y_pos(a0)
	bra.s	Sonic_Roll_ResetScr

; ---------------------------------------------------------------------------
; magically gives Sonic an extra push if he's going to stop rolling where it's not allowed
; (such as in an S-curve in HTZ or a stopper chamber in CNZ)
; loc_1A848:
Sonic_KeepRolling:
	move.w	#$400,inertia(a0)
	btst	#0,status(a0)
	beq.s	Sonic_Roll_ResetScr
	neg.w	inertia(a0)

; resets the screen to normal while rolling, like Sonic_ResetScr
; loc_1A85A:
Sonic_Roll_ResetScr:
	cmpi.w	#$60,(Camera_Y_pos_bias).w	; is screen in its default position?
	beq.s	Sonic_SetRollSpeeds		; if yes, branch
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias).w	; or subtract 2

; loc_1A86C:
Sonic_SetRollSpeeds:
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	inertia(a0),d0
	asr.l	#8,d0
	move.w	d0,y_vel(a0)	; set y velocity based on $14 and angle
	muls.w	inertia(a0),d1
	asr.l	#8,d1
	cmpi.w	#$1000,d1
	ble.s	+
	move.w	#$1000,d1	; limit Sonic's speed rolling right
+
	cmpi.w	#-$1000,d1
	bge.s	+
	move.w	#-$1000,d1	; limit Sonic's speed rolling left
+
	move.w	d1,x_vel(a0)	; set x velocity based on $14 and angle
	bra.w	Sonic_CheckWallsOnGround
; End of function Sonic_RollSpeed


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


; loc_1A8A2:
Sonic_RollLeft:
	move.w	inertia(a0),d0
	beq.s	+
	bpl.s	Sonic_BrakeRollingRight
+
	bset	#0,status(a0)
	move.b	#2,anim(a0)	; use "rolling" animation
	rts
; ---------------------------------------------------------------------------
; loc_1A8B8:
Sonic_BrakeRollingRight:
	sub.w	d4,d0	; reduce rightward rolling speed
	bcc.s	+
	move.w	#-$80,d0
+
	move.w	d0,inertia(a0)
	rts
; End of function Sonic_RollLeft


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


; loc_1A8C6:
Sonic_RollRight:
	move.w	inertia(a0),d0
	bmi.s	Sonic_BrakeRollingLeft
	bclr	#0,status(a0)
	move.b	#2,anim(a0)	; use "rolling" animation
	rts
; ---------------------------------------------------------------------------
; loc_1A8DA:
Sonic_BrakeRollingLeft:
	add.w	d4,d0	; reduce leftward rolling speed
	bcc.s	+
	move.w	#$80,d0
+
	move.w	d0,inertia(a0)
	rts
; End of subroutine Sonic_RollRight


; ---------------------------------------------------------------------------
; Subroutine for moving Sonic left or right when he's in the air
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A8E8:
Sonic_ChgJumpDir:
	move.w	(Sonic_top_speed).w,d6
	move.w	(Sonic_acceleration).w,d5
	asl.w	#1,d5
	btst	#4,status(a0)		; did Sonic jump from rolling?
	bne.s	Sonic_Jump_ResetScr	; if yes, branch to skip midair control
	move.w	x_vel(a0),d0
	btst	#button_left,(Ctrl_1_Held_Logical).w
	beq.s	+	; if not holding left, branch

	bset	#0,status(a0)
	sub.w	d5,d0	; add acceleration to the left
	move.w	d6,d1
	neg.w	d1
	cmp.w	d1,d0	; compare new speed with top speed
	bgt.s	+	; if new speed is less than the maximum, branch
	move.w	d1,d0	; limit speed in air going left, even if Sonic was already going faster (speed limit/cap)
+
	btst	#button_right,(Ctrl_1_Held_Logical).w
	beq.s	+	; if not holding right, branch

	bclr	#0,status(a0)
	add.w	d5,d0	; accelerate right in the air
	cmp.w	d6,d0	; compare new speed with top speed
	blt.s	+	; if new speed is less than the maximum, branch
	move.w	d6,d0	; limit speed in air going right, even if Sonic was already going faster (speed limit/cap)
; Sonic_JumpMove:
+	move.w	d0,x_vel(a0)

; loc_1A932: Sonic_ResetScr2:
Sonic_Jump_ResetScr:
	cmpi.w	#$60,(Camera_Y_pos_bias).w	; is screen in its default position?
	beq.s	Sonic_JumpPeakDecelerate	; if yes, branch
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias).w	; or subtract 2

; loc_1A944:
Sonic_JumpPeakDecelerate:
	cmpi.w	#-$400,y_vel(a0)	; is Sonic moving faster than -$400 upwards?
	blo.s	return_1A972		; if yes, return
	move.w	x_vel(a0),d0
	move.w	d0,d1
	asr.w	#5,d1		; d1 = x_velocity / 32
	beq.s	return_1A972	; return if d1 is 0
	bmi.s	Sonic_JumpPeakDecelerateLeft	; branch if moving left

; Sonic_JumpPeakDecelerateRight:
	sub.w	d1,d0	; reduce x velocity by d1
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,x_vel(a0)
	rts
;-------------------------------------------------------------
; loc_1A966:
Sonic_JumpPeakDecelerateLeft:
	sub.w	d1,d0	; reduce x velocity by d1
	bcs.s	+
	move.w	#0,d0
+
	move.w	d0,x_vel(a0)

return_1A972:
	rts
; End of subroutine Sonic_ChgJumpDir
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to prevent Sonic from leaving the boundaries of a level
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A974:
Sonic_LevelBound:
	move.l	x_pos(a0),d1
	move.w	x_vel(a0),d0
	ext.l	d0
	asl.l	#8,d0
	add.l	d0,d1
	swap	d1
	move.w	(Camera_Min_X_pos).w,d0
	addi.w	#$10,d0
	cmp.w	d1,d0			; has Sonic touched the left boundary?
	bhi.s	Sonic_Boundary_Sides	; if yes, branch
	move.w	(Camera_Max_X_pos).w,d0
	addi.w	#$128,d0
	tst.b	(Current_Boss_ID).w
	bne.s	+
	addi.w	#$40,d0
+
	cmp.w	d1,d0			; has Sonic touched the right boundary?
	bls.s	Sonic_Boundary_Sides	; if yes, branch

; loc_1A9A6:
Sonic_Boundary_CheckBottom:
	move.w	(Camera_Max_Y_pos_now).w,d0
	addi.w	#$E0,d0
	cmp.w	y_pos(a0),d0		; has Sonic touched the bottom boundary?
	blt.s	Sonic_Boundary_Bottom	; if yes, branch
	rts
; ---------------------------------------------------------------------------
Sonic_Boundary_Bottom: ;;
	bra.w	JmpTo_KillCharacter
; ===========================================================================

; loc_1A9BA:
Sonic_Boundary_Sides:
	move.w	d0,x_pos(a0)
	move.w	#0,2+x_pos(a0) ; subpixel x
	move.w	#0,x_vel(a0)
	move.w	#0,inertia(a0)
	bra.s	Sonic_Boundary_CheckBottom
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to start rolling when he's moving
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1A9D2:
Sonic_Roll:
	tst.b	status2(a0)
	bmi.s	Sonic_NoRoll
	mvabs.w	inertia(a0),d0
	cmpi.w	#$80,d0		; is Sonic moving at $80 speed or faster?
	blo.s	Sonic_NoRoll	; if not, branch
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_left_mask|button_right_mask,d0 ; is left/right being pressed?
	bne.s	Sonic_NoRoll	; if yes, branch
	btst	#button_down,(Ctrl_1_Held_Logical).w ; is down being pressed?
	bne.s	Sonic_ChkRoll			; if yes, branch
; return_1A9F8:
Sonic_NoRoll:
	rts

; ---------------------------------------------------------------------------
; loc_1A9FA:
Sonic_ChkRoll:
	btst	#2,status(a0)	; is Sonic already rolling?
	beq.s	Sonic_DoRoll	; if not, branch
	rts

; ---------------------------------------------------------------------------
; loc_1AA04:
Sonic_DoRoll:
	bset	#2,status(a0)
	move.b	#$1C,height_pixels(a0)
	move.b	#14,width_pixels(a0)
	move.b	#2,anim(a0)	; use "rolling" animation
	addq.w	#5,y_pos(a0)
	move.w	#SndID_Roll,d0
	jsr	(PlaySound).l	; play rolling sound
	tst.w	inertia(a0)
	bne.s	return_1AA36
	move.w	#$200,inertia(a0)

return_1AA36:
	rts
; End of function Sonic_Roll


; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to jump
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AA38:
Sonic_Jump:
	tst.b	(SonicSSFlag).w
	bne.s	+
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0 ; is A, B or C pressed?
	beq.w	return_1AAE6	; if not, return
	bra.w	++
+
	btst	#button_C,(Ctrl_1_Held_Logical).w
	beq.w	return_1AAE6

+
	moveq	#0,d0
	move.b	angle(a0),d0
	addi.b	#$80,d0
	bsr.w	CalcRoomOverHead
	cmpi.w	#6,d1			; does Sonic have enough room to jump?
	blt.w	return_1AAE6		; if not, branch
	move.w	#$680,d2
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.s	+
	move.w	#$800,d2	; set higher jump speed if super
+
	btst	#6,status(a0)	; Test if underwater
	beq.s	+
	move.w	#$380,d2	; set lower jump speed if under
+
	moveq	#0,d0
	move.b	angle(a0),d0
	subi.b	#$40,d0
	jsr	(CalcSine).l
	muls.w	d2,d1
	asr.l	#8,d1
	add.w	d1,x_vel(a0)	; make Sonic jump (in X... this adds nothing on level ground)
	muls.w	d2,d0
	asr.l	#8,d0
	add.w	d0,y_vel(a0)	; make Sonic jump (in Y)
	bset	#1,status(a0)
	bclr	#5,status(a0)
	addq.l	#4,sp
	bset	#s3b_jumping,status3(a0)
	bclr	#s3b_stick_convex,status3(a0)
	move.w	#SndID_Jump,d0
	jsr	(PlaySound).l	; play jumping sound
	move.b	#$26,height_pixels(a0)
	move.b	#18,width_pixels(a0)
	btst	#2,status(a0)
	bne.s	Sonic_RollJump
	move.b	#$1C,height_pixels(a0)
	move.b	#14,width_pixels(a0)
	move.b	#2,anim(a0)	; use "jumping" animation
	bset	#2,status(a0)
	addq.w	#5,y_pos(a0)

return_1AAE6:
	rts
; ---------------------------------------------------------------------------
; loc_1AAE8:
Sonic_RollJump:
	bset	#4,status(a0)	; set the rolling+jumping flag
	rts
; End of function Sonic_Jump


; ---------------------------------------------------------------------------
; Subroutine letting Sonic control the height of the jump
; when the jump button is released
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; ===========================================================================
; loc_1AAF0:
Sonic_JumpHeight:
	btst	#s3b_jumping,status3(a0)	; is Sonic jumping?
	beq.s	Sonic_UpVelCap	; if not, branch

	move.w	#-$400,d1
	btst	#6,status(a0)	; is Sonic underwater?
	beq.s	+		; if not, branch
	move.w	#-$200,d1
+
	cmp.w	y_vel(a0),d1	; is Sonic going up faster than d1?
	ble.s	+		; if not, branch
	move.b	(Ctrl_1_Held_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0 ; is a jump button pressed?
	bne.s	+		; if yes, branch
	move.w	d1,y_vel(a0)	; immediately reduce Sonic's upward speed to d1
+
	move.b	($FFFFF603).w,d0 ; Move	Data from Source to Destination
	andi.b	#$70,d0	; 'p'   ; AND Immediate
	bne.s	Sonic_CheckGoSuper
	rts
; ---------------------------------------------------------------------------
; loc_1AB22:
Sonic_UpVelCap:
	tst.b	(SonicSSFlag).w
	bne.w	+
	btst	#s3b_spindash,status3(a0)	; is Sonic charging a spindash or in a rolling-only area?
	bne.s	return_1AB36		; if yes, return
+
	cmpi.w	#-$FC0,y_vel(a0)	; is Sonic moving up really fast?
	bge.s	return_1AB36		; if not, return
	move.w	#-$FC0,y_vel(a0)	; cap upward speed

return_1AB36:
	rts
; End of subroutine Sonic_JumpHeight

; ---------------------------------------------------------------------------
; Subroutine called at the peak of a jump that transforms Sonic into Super Sonic
; if he has enough rings and emeralds
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AB38: test_set_SS:
Sonic_CheckGoSuper:
	btst	#s2b_3,status2(a0)	; is Sonic already super or hyper?
	bne.s	return_1ABA4		; if yes, branch
	cmpi.b	#7,(Emerald_count).w	; does Sonic have exactly 7 emeralds?
	bne.s	return_1ABA4		; if not, branch
	cmpi.w	#50,(Ring_count).w	; does Sonic have at least 50 rings?
	blo.s	return_1ABA4		; if not, branch

	move.b	#1,(Super_Sonic_palette).w
	move.b	#$F,(Palette_timer).w
	ori.b	#lock_mask,status3(a0)
	move.b	#$1F,anim(a0)			; use transformation animation
	move.w	#0,invincibility_time(a0)
	andi.b	#power_del,status2(a0)	; make Sonic super
	ori.b	#power_super,status2(a0)
	bsr.w	ChooseShield
	bsr.w	ChooseSpeeds
	move.w	#SndID_SuperTransform,d0
	jsr	(PlaySound).l	; Play transformation sound effect.
	move.w	#MusID_SuperSonic,d0
	jmp	(PlayMusic).l	; load the Super Sonic song and return

; ---------------------------------------------------------------------------
return_1ABA4:
	rts
; End of subroutine Sonic_CheckGoSuper


; ---------------------------------------------------------------------------
; Subroutine doing the extra logic for Super Sonic
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||
Tails_Super:				; Tails	super flag
		tst.b	(Super_Tails_flag).w
		beq.w	return_1AC3C
		bra.s	loc_11B3A

; loc_1ABA6:
Sonic_Super:
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.w	return_1AC3C			; if not, return
loc_11B3A:
	tst.b	(Update_HUD_timer).w
	beq.s	Sonic_RevertToNormal ; ?
	subq.w	#1,(Super_Sonic_frame_count).w
	bpl.w	return_1AC3C
	move.w	#60,(Super_Sonic_frame_count).w	; Reset frame counter to 60
	tst.w	(Ring_count).w
	beq.s	Sonic_RevertToNormal
	ori.b	#1,(Update_HUD_rings).w
	cmpi.w	#1,(Ring_count).w
	beq.s	+
	cmpi.w	#10,(Ring_count).w
	beq.s	+
	cmpi.w	#100,(Ring_count).w
	bne.s	++
+
	ori.b	#$80,(Update_HUD_rings).w
+
	subq.w	#1,(Ring_count).w
	bne.s	return_1AC3C
; loc_1ABF2:
Sonic_RevertToNormal:
	move.b	#2,(Super_Sonic_palette).w	; Remove rotating palette
	move.w	#$28,(Palette_frame).w
	andi.b	#power_del,status2(a0)	; remove power
	bsr.w	ChooseShield
	move.b	#1,next_anim(a0)		; Change animation back to normal ?
	move.w	#1,invincibility_time(a0)	; Remove invincibility
	move.w	#$600,(Sonic_top_speed).w
	move.w	#$C,(Sonic_acceleration).w
	move.w	#$80,(Sonic_deceleration).w
	btst	#6,status(a0)			; Check if underwater, return if not
	beq.s	return_1AC3C
	move.w	#$300,(Sonic_top_speed).w
	move.w	#6,(Sonic_acceleration).w
	move.w	#$40,(Sonic_deceleration).w

return_1AC3C:
	rts
; End of subroutine Sonic_Super

; ---------------------------------------------------------------------------
; Subroutine to check for starting to charge a spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AC3E:
Sonic_CheckSpindash:
	tst.b	(SonicSSFlag).w
	bne.w	return_1AC8C
	btst	#s3b_spindash,status3(a0)
	bne.s	Sonic_UpdateSpindash
	cmpi.b	#8,anim(a0)
	bne.s	return_1AC8C
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	beq.w	return_1AC8C
	move.b	#9,anim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound).l
	addq.l	#4,sp
	bset	#s3b_spindash,status3(a0)
	move.w	#0,spindash_counter(a0)
	cmpi.b	#$C,air_left(a0)	; if he's drowning, branch to not make dust
	blo.s	+
	move.b	#2,(Sonic_Dust+anim).w
+
	bsr.w	Sonic_LevelBound
	bsr.w	AnglePos

return_1AC8C:
	rts
; End of subroutine Sonic_CheckSpindash


; ---------------------------------------------------------------------------
; Subrouting to update an already-charging spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AC8E:
Sonic_UpdateSpindash:
	tst.b	(SonicSSFlag).w
	bne.w	return_1AC8C
	move.b	(Ctrl_1_Held_Logical).w,d0
	btst	#button_down,d0
	bne.w	Sonic_ChargingSpindash

	; unleash the charged spindash and start rolling quickly:
	move.b	#$1C,height_pixels(a0)
	move.b	#14,width_pixels(a0)
	move.b	#2,anim(a0)
	addq.w	#5,y_pos(a0)	; add the difference between Sonic's rolling and standing heights
	bclr	#s3b_spindash,status3(a0)
	moveq	#0,d0
	move.b	spindash_counter(a0),d0
	add.w	d0,d0
	move.w	SpindashSpeeds(pc,d0.w),inertia(a0)
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.s	+
	move.w	SpindashSpeedsSuper(pc,d0.w),inertia(a0)
+
	move.w	inertia(a0),d0
	subi.w	#$800,d0
	add.w	d0,d0
	andi.w	#$1F00,d0
	neg.w	d0
	addi.w	#$2000,d0
	move.w	d0,(Horiz_scroll_delay_val).w
	btst	#0,status(a0)
	beq.s	+
	neg.w	inertia(a0)
+
	bset	#2,status(a0)
	move.b	#0,(Sonic_Dust+anim).w
	move.w	#SndID_SpindashRelease,d0	; spindash zoom sound
	jsr	(PlaySound).l
	bra.s	Sonic_Spindash_ResetScr
; ===========================================================================
; word_1AD0C:
SpindashSpeeds:
	dc.w  $800	; 0
	dc.w  $880	; 1
	dc.w  $900	; 2
	dc.w  $980	; 3
	dc.w  $A00	; 4
	dc.w  $A80	; 5
	dc.w  $B00	; 6
	dc.w  $B80	; 7
	dc.w  $C00	; 8
; word_1AD1E:
SpindashSpeedsSuper:
	dc.w  $B00	; 0
	dc.w  $B80	; 1
	dc.w  $C00	; 2
	dc.w  $C80	; 3
	dc.w  $D00	; 4
	dc.w  $D80	; 5
	dc.w  $E00	; 6
	dc.w  $E80	; 7
	dc.w  $F00	; 8
; ===========================================================================
; loc_1AD30:
Sonic_ChargingSpindash:			; If still charging the dash...
	tst.b	(SonicSSFlag).w
	bne.w	return_1AC8C
	tst.w	spindash_counter(a0)
	beq.s	+
	move.w	spindash_counter(a0),d0
	lsr.w	#5,d0
	sub.w	d0,spindash_counter(a0)
	bcc.s	+
	move.w	#0,spindash_counter(a0)
+
	move.b	(Ctrl_1_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	beq.w	Sonic_Spindash_ResetScr
	move.w	#$900,anim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound).l
	addi.w	#$200,spindash_counter(a0)
	cmpi.w	#$800,spindash_counter(a0)
	blo.s	Sonic_Spindash_ResetScr
	move.w	#$800,spindash_counter(a0)

; loc_1AD78:
Sonic_Spindash_ResetScr:
	addq.l	#4,sp
	cmpi.w	#$60,(Camera_Y_pos_bias).w
	beq.s	loc_1AD8C
	bhs.s	+
	addq.w	#4,(Camera_Y_pos_bias).w
+	subq.w	#2,(Camera_Y_pos_bias).w

loc_1AD8C:
	bsr.w	Sonic_LevelBound
	bsr.w	AnglePos
	rts
; End of subroutine Sonic_UpdateSpindash


; ---------------------------------------------------------------------------
; Subroutine to slow Sonic walking up a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AD96:
Sonic_SlopeResist:
	move.b	angle(a0),d0
	addi.b	#$60,d0
	cmpi.b	#$C0,d0
	bhs.s	return_1ADCA
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	#$20,d0
	asr.l	#8,d0
	tst.w	inertia(a0)
	beq.s	return_1ADCA
	bmi.s	loc_1ADC6
	tst.w	d0
	beq.s	+
	add.w	d0,inertia(a0)	; change Sonic's $14
+
	rts
; ---------------------------------------------------------------------------

loc_1ADC6:
	add.w	d0,inertia(a0)

return_1ADCA:
	rts
; End of subroutine Sonic_SlopeResist

; ---------------------------------------------------------------------------
; Subroutine to push Sonic down a slope while he's rolling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1ADCC:
Sonic_RollRepel:
	move.b	angle(a0),d0
	addi.b	#$60,d0
	cmpi.b	#-$40,d0
	bhs.s	return_1AE06
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	#$50,d0
	asr.l	#8,d0
	tst.w	inertia(a0)
	bmi.s	loc_1ADFC
	tst.w	d0
	bpl.s	loc_1ADF6
	asr.l	#2,d0

loc_1ADF6:
	add.w	d0,inertia(a0)
	rts
; ===========================================================================

loc_1ADFC:
	tst.w	d0
	bmi.s	loc_1AE02
	asr.l	#2,d0

loc_1AE02:
	add.w	d0,inertia(a0)

return_1AE06:
	rts
; End of function Sonic_RollRepel

; ---------------------------------------------------------------------------
; Subroutine to push Sonic down a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AE08:
Sonic_SlopeRepel:
	nop
	btst	#s3b_stick_convex,status3(a0)
	bne.s	return_1AE42
	tst.w	move_lock(a0)
	bne.s	loc_1AE44
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	return_1AE42
	mvabs.w	inertia(a0),d0
	cmpi.w	#$280,d0
	bhs.s	return_1AE42
	clr.w	inertia(a0)
	bset	#1,status(a0)
	move.w	#$1E,move_lock(a0)

return_1AE42:
	rts
; ===========================================================================

loc_1AE44:
	subq.w	#1,move_lock(a0)
	rts
; End of function Sonic_SlopeRepel

; ---------------------------------------------------------------------------
; Subroutine to return Sonic's angle to 0 as he jumps
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AE4A:
Sonic_JumpAngle:
	move.b	angle(a0),d0	; get Sonic's angle
	beq.s	Sonic_JumpFlip	; if already 0, branch
	bpl.s	loc_1AE5A	; if higher than 0, branch

	addq.b	#2,d0		; increase angle
	bcc.s	BranchTo_Sonic_JumpAngleSet
	moveq	#0,d0

BranchTo_Sonic_JumpAngleSet
	bra.s	Sonic_JumpAngleSet
; ===========================================================================

loc_1AE5A:
	subq.b	#2,d0		; decrease angle
	bcc.s	Sonic_JumpAngleSet
	moveq	#0,d0

; loc_1AE60:
Sonic_JumpAngleSet:
	move.b	d0,angle(a0)
; End of function Sonic_JumpAngle
	; continue straight to Sonic_JumpFlip

; ---------------------------------------------------------------------------
; Updates Sonic's secondary angle if he's tumbling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AE64:
Sonic_JumpFlip:
	move.b	flip_angle(a0),d0
	beq.s	return_1AEA8
	tst.w	inertia(a0)
	bmi.s	Sonic_JumpLeftFlip
; loc_1AE70:
Sonic_JumpRightFlip:
	move.b	flip_speed(a0),d1
	add.b	d1,d0
	bcc.s	BranchTo_Sonic_JumpFlipSet
	subq.b	#1,flips_remaining(a0)
	bcc.s	BranchTo_Sonic_JumpFlipSet
	move.b	#0,flips_remaining(a0)
	moveq	#0,d0

BranchTo_Sonic_JumpFlipSet
	bra.s	Sonic_JumpFlipSet
; ===========================================================================
; loc_1AE88:
Sonic_JumpLeftFlip:
	btst	#s3b_flip_turned,status3(a0)
	bne.s	Sonic_JumpRightFlip
	move.b	flip_speed(a0),d1
	sub.b	d1,d0
	bcc.s	Sonic_JumpFlipSet
	subq.b	#1,flips_remaining(a0)
	bcc.s	Sonic_JumpFlipSet
	move.b	#0,flips_remaining(a0)
	moveq	#0,d0
; loc_1AEA4:
Sonic_JumpFlipSet:
	move.b	d0,flip_angle(a0)

return_1AEA8:
	rts
; End of function Sonic_JumpFlip

; ---------------------------------------------------------------------------
; Subroutine for Sonic to interact with the floor and walls when he's in the air
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1AEAA: Sonic_Floor:
Sonic_DoLevelCollision:
	move.l	#Primary_Collision,(Collision_addr).w
	cmpi.b	#$C,layer(a0)
	beq.s	+
	move.l	#Secondary_Collision,(Collision_addr).w
+
	move.b	layer_plus(a0),d5
	move.w	x_vel(a0),d1
	move.w	y_vel(a0),d2
	jsr	(CalcAngle).l
	subi.b	#$20,d0
	andi.b	#$C0,d0
	cmpi.b	#$40,d0
	beq.w	Sonic_HitLeftWall
	cmpi.b	#$80,d0
	beq.w	Sonic_HitCeilingAndWalls
	cmpi.b	#-$40,d0
	beq.w	Sonic_HitRightWall
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
+
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
+
	bsr.w	Sonic_CheckFloor
	tst.w	d1
	bpl.s	return_1AF8A
	move.b	y_vel(a0),d2
	addq.b	#8,d2
	neg.b	d2
	cmp.b	d2,d1
	bge.s	+
	cmp.b	d2,d0
	blt.s	return_1AF8A
+
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	Sonic_ResetOnFloor
	move.b	d3,d0
	addi.b	#$20,d0
	andi.b	#$40,d0
	bne.s	loc_1AF68
	move.b	d3,d0
	addi.b	#$10,d0
	andi.b	#$20,d0
	beq.s	loc_1AF5A
	asr	y_vel(a0)
	bra.s	loc_1AF7C
; ===========================================================================

loc_1AF5A:
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)
	bsr.w	Sonic_ResetOnFloor
	rts
; ===========================================================================

loc_1AF68:
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
	cmpi.w	#$FC0,y_vel(a0)
	ble.s	loc_1AF7C
	move.w	#$FC0,y_vel(a0)

loc_1AF7C:
	bsr.w	Sonic_ResetOnFloor
	move.w	y_vel(a0),inertia(a0)
	tst.b	d3
	bpl.s	return_1AF8A
	neg.w	inertia(a0)

return_1AF8A:
	rts
; ===========================================================================
; loc_1AF8C:
Sonic_HitLeftWall:
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	Sonic_HitCeiling ; branch if distance is positive (not inside wall)
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
	move.w	y_vel(a0),inertia(a0)
	rts
; ===========================================================================
; loc_1AFA6:
Sonic_HitCeiling:
	bsr.w	CheckCeilingDist
	tst.w	d1
	bpl.s	Sonic_HitFloor ; branch if distance is positive (not inside ceiling)
	sub.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	return_1AFBE
	move.w	#0,y_vel(a0) ; stop Sonic in y since he hit a ceiling

return_1AFBE:
	rts
; ===========================================================================
; loc_1AFC0:
Sonic_HitFloor:
	tst.w	y_vel(a0)
	bmi.s	return_1AFE6
	bsr.w	Sonic_CheckFloor
	tst.w	d1
	bpl.s	return_1AFE6
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)
	bsr.w	Sonic_ResetOnFloor

return_1AFE6:
	rts
; ===========================================================================
; loc_1AFE8:
Sonic_HitCeilingAndWalls:
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Sonic since he hit a wall
+
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Sonic since he hit a wall
+
	bsr.w	CheckCeilingDist
	tst.w	d1
	bpl.s	return_1B042
	sub.w	d1,y_pos(a0)
	move.b	d3,d0
	addi.b	#$20,d0
	andi.b	#$40,d0
	bne.s	loc_1B02C
	move.w	#0,y_vel(a0) ; stop Sonic in y since he hit a ceiling
	rts
; ===========================================================================

loc_1B02C:
	move.b	d3,angle(a0)
	bsr.w	Sonic_ResetOnFloor
	move.w	y_vel(a0),inertia(a0)
	tst.b	d3
	bpl.s	return_1B042
	neg.w	inertia(a0)

return_1B042:
	rts
; ===========================================================================
; loc_1B044:
Sonic_HitRightWall:
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	Sonic_HitCeiling2
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0) ; stop Sonic since he hit a wall
	move.w	y_vel(a0),inertia(a0)
	rts
; ===========================================================================
; identical to Sonic_HitCeiling...
; loc_1B05E:
Sonic_HitCeiling2:
	bsr.w	CheckCeilingDist
	tst.w	d1
	bpl.s	Sonic_HitFloor2
	sub.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	return_1B076
	move.w	#0,y_vel(a0) ; stop Sonic in y since he hit a ceiling

return_1B076:
	rts
; ===========================================================================
; identical to Sonic_HitFloor...
; loc_1B078:
Sonic_HitFloor2:
	tst.w	y_vel(a0)
	bmi.s	return_1B09E
	bsr.w	Sonic_CheckFloor
	tst.w	d1
	bpl.s	return_1B09E
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	Sonic_ResetOnFloor
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)

return_1B09E:
	rts
; End of function Sonic_DoLevelCollision



; ---------------------------------------------------------------------------
; Subroutine to reset Sonic's mode when he lands on the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B0A0:
Sonic_ResetOnFloor:
	clr.w	(Chain_Bonus_counter).w
	bclr	#s2b_doublejump,status2(a0)	; clear the double jump flag
	tst.b	(SonicSSFlag).w
	bne.w	+
	btst	#s3b_spindash,status3(a0)
	bne.s	Sonic_ResetOnFloor_Part3
+
	move.b	#0,anim(a0)

; loc_1B0AC:
Sonic_ResetOnFloor_Part2:
	cmpa.w	#MainCharacter,a0		; is this the main character?
	bne.w	Tails_ResetOnFloor_Part2	; if not, branch to the Tails version of this code
	cmpi.w	#2,Player_mode			; are we playing as Tails?
	beq.w	Tails_ResetOnFloor_Part2	; if so, branch to the Tails version of this code
	btst	#2,status(a0)
	beq.s	Sonic_ResetOnFloor_Part3
	bclr	#2,status(a0)
	move.b	#$26,height_pixels(a0) ; increases Sonic's collision height to standing
	move.b	#18,width_pixels(a0)
	move.b	#0,anim(a0)	; use running/walking/standing animation
	subq.w	#5,y_pos(a0)	; move Sonic up 5 pixels so the increased height doesn't push him into the ground
; loc_1B0DA:
Sonic_ResetOnFloor_Part3:
        bclr	#1,status(a0)
	bclr	#5,status(a0)
	bclr	#4,status(a0)
	bclr	#s3b_jumping,status3(a0)
	move.b	#0,flip_angle(a0)
	bclr	#s3b_flip_turned,status3(a0)
	move.b	#0,flips_remaining(a0)
	move.w	#0,(Sonic_Look_delay_counter).w
	cmpi.b	#$14,anim(a0)
	bne.s	+
	move.b	#0,anim(a0)
+
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic when he gets hurt
; ---------------------------------------------------------------------------
; loc_1B120: Obj_01_Sub_4:
Sonic_Hurt:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+			; if not, branch
	jmp		(DebugMode).l
+
	tst.w	(Debug_mode_flag).w
	beq.s	Sonic_Hurt_Normal
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	Sonic_Hurt_Normal
	move.w	#1,(Debug_placement_mode).w
	clr.b	(Control_Locked).w
	rts
; ---------------------------------------------------------------------------
; loc_1B13A:
Sonic_Hurt_Normal:
	tst.b	(SonicFlyingFlag).w
	bne.w	Sonic_HurtInstantRecover
	jsr	(ObjectMove).l
	addi.w	#$30,y_vel(a0)
	btst	#6,status(a0)
	beq.s	+
	subi.w	#$20,y_vel(a0)
+
	cmpi.w	#-$100,(Camera_Min_Y_pos).w
	bne.s	+
	andi.w	#$7FF,y_pos(a0)
+
	bsr.w	Sonic_HurtStop
	bsr.w	Sonic_LevelBound
	bsr.w	Sonic_RecordPos
	bsr.w	Sonic_Animate
	bsr.w	LoadSonicDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================
; loc_1B184:
Sonic_HurtStop:
	move.w	(Camera_Max_Y_pos_now).w,d0
	addi.w	#$E0,d0
	cmp.w	y_pos(a0),d0
	blt.w	JmpTo_KillCharacter
	bsr.w	Sonic_DoLevelCollision
	btst	#1,status(a0)
	bne.s	return_1B1C8
	moveq	#0,d0
	move.w	d0,y_vel(a0)
	move.w	d0,x_vel(a0)
	move.w	d0,inertia(a0)
	andi.b	#lock_del,status3(a0)
	move.b	#0,anim(a0)
	move.w	#objroutine(Sonic_Control),(a0)	; => Sonic_Control
	move.w	#$78,invulnerable_time(a0)
	tst.b	(SonicSSFlag).w
	bne.w	return_1B1C8
	bclr	#s3b_spindash,status3(a0)
	bsr.w	Sonic_ResetOnFloor

return_1B1C8:
	rts
; ===========================================================================
; makes Sonic recover control after being hurt before landing
; seems to be unused
; loc_1B1CA:
Sonic_HurtInstantRecover:
	move.b	#2,anim(a0)
	move.w	#objroutine(Sonic_Control),(a0)	; => Sonic_Control
	bsr.w	Sonic_RecordPos
	bsr.w	Sonic_Animate
	bsr.w	LoadSonicDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================

; ---------------------------------------------------------------------------
; Sonic when he dies
; ...poor Sonic
; ---------------------------------------------------------------------------

; loc_1B1E6: Obj_01_Sub_6:
Sonic_Dead:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+			; if not, branch
	jmp		(DebugMode).l
+
	tst.w	(Debug_mode_flag).w
	beq.s	+
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	+
	move.w	#1,(Debug_placement_mode).w
	clr.b	(Control_Locked).w
	rts
+
	bsr.w	CheckGameOver
	jsr	(ObjectMoveAndFall).l
	bsr.w	Sonic_RecordPos
	bsr.w	Sonic_Animate
	bsr.w	LoadSonicDynPLC
	jmp	(DisplaySprite).l

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B21C:
CheckGameOver:
	move.b	#1,(Scroll_lock).w
	bclr	#s3b_spindash,status3(a0)
	move.w	(Camera_Max_Y_pos_now).w,d0
	addi.w	#$100,d0
	cmp.w	y_pos(a0),d0
	bge.w	return_1B31A
	move.w	#objroutine(Sonic_Gone),(a0)	; => Sonic_Gone
	move.w	#$3C,spindash_counter(a0)
	addq.b	#1,(Update_HUD_lives).w	; update lives counter
	subq.b	#1,(Life_count).w	; subtract 1 from number of lives
	bne.s	Sonic_ResetLevel	; if it's not a game over, branch
	move.w	#0,spindash_counter(a0)
	;move.w	#objroutine(Obj39),(GameOver_GameText+id).w ; load Obj39 (game over text)
	;move.w	#objroutine(Obj39),(GameOver_OverText+id).w ; load Obj39 (game over text)
	;move.b	#1,(GameOver_OverText+mapping_frame).w
	;move.w	a0,(GameOver_GameText+parent).w
	clr.b	(Time_Over_flag).w
; loc_1B26E:
Sonic_Finished:
	clr.b	(Update_HUD_timer).w
	move.w	#objroutine(Sonic_Gone),(a0)	; => Sonic_Gone
	move.w	#MusID_GameOver,d0
	jsr	(PlayMusic).l
	moveq	#PLCID_GameOver,d0
	jmp	(LoadPLC).l
; End of function CheckGameOver

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic when the level is restarted
; ---------------------------------------------------------------------------
; loc_1B28E:
Sonic_ResetLevel:
	tst.b	(Time_Over_flag).w
	beq.s	Sonic_ResetLevel_Part2
	move.w	#0,spindash_counter(a0)
	;move.w	#objroutine(Obj39),(TimeOver_TimeText+id).w ; load Obj39
	;move.w	#objroutine(Obj39),(TimeOver_OverText+id).w ; load Obj39
	;move.b	#2,(TimeOver_TimeText+mapping_frame).w
	;move.b	#3,(TimeOver_OverText+mapping_frame).w
	move.w	a0,(TimeOver_TimeText+parent).w
	bra.s	Sonic_Finished
; ---------------------------------------------------------------------------
Sonic_ResetLevel_Part2:
	tst.w	(Two_player_mode).w
	beq.s	return_1B31A
	move.b	#0,(Scroll_lock).w
	move.w	#objroutine(Sonic_Respawning),(a0)	; => Sonic_Respawning
	move.w	(Saved_x_pos).w,x_pos(a0)
	move.w	(Saved_y_pos).w,y_pos(a0)
	move.w	(Saved_art_tile).w,art_tile(a0)
	move.w	(Saved_layer).w,layer(a0)
	clr.w	(Ring_count).w
	clr.b	(Extra_life_flags).w
	andi.b	#lock_del,status3(a0)
	move.b	#5,anim(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#2,status(a0)
	move.w	#0,move_lock(a0)
	move.w	#0,spindash_counter(a0)

return_1B31A:
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic when he's offscreen and waiting for the level to restart
; ---------------------------------------------------------------------------
; loc_1B31C: Obj_01_Sub_8:
Sonic_Gone:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+			; if not, branch
	jmp		(DebugMode).l
+
	tst.b	(SonicSSFlag).w
	bne.w	+
	tst.w	spindash_counter(a0)
	beq.s	++
	subq.w	#1,spindash_counter(a0)
	bne.s	++
+
	move.w	#1,(Level_Inactive_flag).w
+
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic when he's waiting for the camera to scroll back to where he respawned
; ---------------------------------------------------------------------------
; loc_1B330: Obj_01_Sub_A:
Sonic_Respawning:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+			; if not, branch
	jmp		(DebugMode).l
+
	tst.w	(Camera_X_pos_diff).w
	bne.s	+
	tst.w	(Camera_Y_pos_diff).w
	bne.s	+
	move.w	#objroutine(Sonic_Control),(a0)	; => Sonic_Control
+
	bsr.w	Sonic_Animate
	bsr.w	LoadSonicDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to animate Sonic's sprites
; See also: AnimateSprite
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B350:
Sonic_Animate:
	lea	(SonicAniData).l,a1
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.s	+
	lea	(SuperSonicAniData).l,a1
+
	moveq	#0,d0
	move.b	anim(a0),d0
	cmp.b	next_anim(a0),d0	; has animation changed?
	beq.s	SAnim_Do		; if not, branch
	move.b	d0,next_anim(a0)	; set to next animation
	move.b	#0,anim_frame(a0)	; reset animation frame
	move.b	#0,anim_frame_duration(a0)	; reset frame duration
	bclr	#5,status(a0)
; loc_1B384:
SAnim_Do:
	add.w	d0,d0
	adda.w	(a1,d0.w),a1	; calculate address of appropriate animation script
	move.b	(a1),d0
	bmi.s	SAnim_WalkRun	; if animation is walk/run/roll/jump, branch
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.s	SAnim_Delay			; if time remains, branch
	move.b	d0,anim_frame_duration(a0)	; load frame duration
; loc_1B3AA:
SAnim_Do2:
	moveq	#0,d1
	move.b	anim_frame(a0),d1	; load current frame number
	move.b	1(a1,d1.w),d0		; read sprite number from script
	cmpi.b	#$F0,d0
	bhs.s	SAnim_End_FF		; if animation is complete, branch
; loc_1B3BA:
SAnim_Next:
	move.b	d0,mapping_frame(a0)	; load sprite number
	addq.b	#1,anim_frame(a0)	; go to next frame
; return_1B3C2:
SAnim_Delay:
	rts
; ===========================================================================
; loc_1B3C4:
SAnim_End_FF:
	addq.b	#1,d0		; is the end flag = $FF ?
	bne.s	SAnim_End_FE	; if not, branch
	move.b	#0,anim_frame(a0)	; restart the animation
	move.b	1(a1),d0	; read sprite number
	bra.s	SAnim_Next
; ===========================================================================
; loc_1B3D4:
SAnim_End_FE:
	addq.b	#1,d0		; is the end flag = $FE ?
	bne.s	SAnim_End_FD	; if not, branch
	move.b	2(a1,d1.w),d0	; read the next byte in the script
	sub.b	d0,anim_frame(a0)	; jump back d0 bytes in the script
	sub.b	d0,d1
	move.b	1(a1,d1.w),d0	; read sprite number
	bra.s	SAnim_Next
; ===========================================================================
; loc_1B3E8:
SAnim_End_FD:
	addq.b	#1,d0			; is the end flag = $FD ?
	bne.s	SAnim_End		; if not, branch
	move.b	2(a1,d1.w),anim(a0)	; read next byte, run that animation
; return_1B3F2:
SAnim_End:
	rts
; ===========================================================================
; loc_1B3F4:
SAnim_WalkRun:
	addq.b	#1,d0		; is the start flag = $FF ?
	bne.w	SAnim_Roll	; if not, branch
	moveq	#0,d0		; is animation walking/running?
	move.b	flip_angle(a0),d0	; if not, branch
	bne.w	SAnim_Tumble
	moveq	#0,d1
	move.b	angle(a0),d0	; get Sonic's angle
	bmi.s	+
	beq.s	+
	subq.b	#1,d0
+
	move.b	status(a0),d2
	andi.b	#1,d2		; is Sonic mirrored horizontally?
	bne.s	+		; if yes, branch
	not.b	d0		; reverse angle
+
	addi.b	#$10,d0		; add $10 to angle
	bpl.s	+		; if angle is $0-$7F, branch
	moveq	#3,d1
+
	andi.b	#$FC,render_flags(a0)
	eor.b	d1,d2
	or.b	d2,render_flags(a0)
	btst	#5,status(a0)
	bne.w	SAnim_Push
	lsr.b	#4,d0		; divide angle by 16
	andi.b	#6,d0		; angle must be 0, 2, 4 or 6
	mvabs.w	inertia(a0),d2	; get Sonic's "speed" for animation purposes
	tst.b	status2(a0)
	bpl.w	+
	add.w	d2,d2
+
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	bne.s	SAnim_Super
	lea	(SonAni_Run).l,a1	; use running animation
	cmpi.w	#$600,d2		; is Sonic at running speed?
	bhs.s	+			; use running animation
	lea	(SonAni_Walk).l,a1	; if yes, branch
	add.b	d0,d0
+
	add.b	d0,d0
	move.b	d0,d3
	moveq	#0,d1
	move.b	anim_frame(a0),d1
	move.b	1(a1,d1.w),d0
	cmpi.b	#-1,d0
	bne.s	+
	move.b	#0,anim_frame(a0)
	move.b	1(a1),d0
+
	move.b	d0,mapping_frame(a0)
	add.b	d3,mapping_frame(a0)
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	return_1B4AC
	neg.w	d2
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)	; modify frame duration
	addq.b	#1,anim_frame(a0)		; modify frame number

return_1B4AC:
	rts
; ===========================================================================
; loc_1B4AE:
SAnim_Super:
	lea	(SupSonAni_Run).l,a1	; use fast animation
	cmpi.w	#$800,d2		; is Sonic moving fast?
	bhs.s	SAnim_SuperRun		; if yes, branch
	lea	(SupSonAni_Walk).l,a1	; use slower animation
	add.b	d0,d0
	add.b	d0,d0
	bra.s	SAnim_SuperWalk
; ---------------------------------------------------------------------------
; loc_1B4C6:
SAnim_SuperRun:
	lsr.b	#1,d0
; loc_1B4C8:
SAnim_SuperWalk:
	move.b	d0,d3
	moveq	#0,d1
	move.b	anim_frame(a0),d1
	move.b	1(a1,d1.w),d0
	cmpi.b	#-1,d0
	bne.s	+
	move.b	#0,anim_frame(a0)
	move.b	1(a1),d0
+
	move.b	d0,mapping_frame(a0)
	add.b	d3,mapping_frame(a0)
	move.b	(Timer_frames+1).w,d1
	andi.b	#3,d1
	bne.s	+
	cmpi.b	#-$4B,mapping_frame(a0)
	bhs.s	+
	addi.b	#$20,mapping_frame(a0)
+
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	return_1B51E
	neg.w	d2
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)
	addq.b	#1,anim_frame(a0)

return_1B51E:
	rts
; ===========================================================================
; loc_1B520:
SAnim_Tumble:
	move.b	flip_angle(a0),d0
	moveq	#0,d1
	move.b	status(a0),d2
	andi.b	#1,d2
	bne.s	SAnim_Tumble_Left

	andi.b	#$FC,render_flags(a0)
	addi.b	#$B,d0
	divu.w	#$16,d0
	addi.b	#$5F,d0
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts
; ===========================================================================
; loc_1B54E:
SAnim_Tumble_Left:
	andi.b	#$FC,render_flags(a0)
	btst	#s3b_flip_turned,status3(a0)
	beq.s	loc_1B566
	ori.b	#1,render_flags(a0)
	addi.b	#$B,d0
	bra.s	loc_1B572
; ===========================================================================

loc_1B566:
	ori.b	#3,render_flags(a0)
	neg.b	d0
	addi.b	#$8F,d0

loc_1B572:
	divu.w	#$16,d0
	addi.b	#$5F,d0
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts
; ===========================================================================
; loc_1B586:
SAnim_Roll:
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.w	SAnim_Delay			; if time remains, branch
	addq.b	#1,d0		; is the start flag = $FE ?
	bne.s	SAnim_Push	; if not, branch
	mvabs.w	inertia(a0),d2
	lea	(SonAni_Roll2).l,a1
	cmpi.w	#$600,d2
	bhs.s	+
	lea	(SonAni_Roll).l,a1
+
	neg.w	d2
	addi.w	#$400,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	bra.w	SAnim_Do2
; ===========================================================================

SAnim_Push:
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.w	SAnim_Delay			; if time remains, branch
	move.w	inertia(a0),d2
	bmi.s	+
	neg.w	d2
+
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#6,d2
	move.b	d2,anim_frame_duration(a0)
	lea	(SonAni_Push).l,a1
	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.s	+
	lea	(SupSonAni_Push).l,a1
+
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	bra.w	SAnim_Do2
; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1B848:
LoadSonicDynPLC:
	moveq	#0,d0
	move.b	mapping_frame(a0),d0	; load frame number
; loc_1B84E:
LoadSonicDynPLC_Part2:
	cmp.b	($FFFFF766).w,d0
	beq.s	return_1B89A
	move.b	d0,($FFFFF766).w
	lea	(MapRUnc_Sonic).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	return_1B89A
	move.w	#-$1000,d4
; loc_1B86E:
SPLC_ReadEntry:
	moveq	#0,d1
	move.w	(a2)+,d1
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	addi.l	#ArtUnc_Sonic,d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,SPLC_ReadEntry	; repeat for number of entries

return_1B89A:
	rts
; ===========================================================================

JmpTo_KillCharacter
	jmp	(KillCharacter).l
; ===========================================================================

ClearInstaShield_Ground:
	cmpi.w	#objroutine(InstaShield),(Sonic_Shield).w	; is instashield still loaded?
	beq.b	ClearInstaShield_Return			; if so, return
	move.b	#$26,height_pixels(a0)				; restore normal hitbox
	move.b	#18,width_pixels(a0)

ClearInstaShield_Return:
	rts

ClearInstaShield_Air:
	cmpi.w	#objroutine(InstaShield),(Sonic_Shield).w	; is instashield still loaded?
	beq.b	ClearInstaShield_Return			; if so, return
	move.b	#$1C,height_pixels(a0)				; restore normal hitbox
	move.b	#18,width_pixels(a0)
	rts
; ===========================================================================

Sonic_DoubleJump2:					; controls the shield attacks
	move.b	(Ctrl_1_Press_Logical).w,d0		; get button presses
	andi.b	#$70,d0					; is A, B or C pressed?
	beq.b	Sonic_DoubleJump2_Return		; if not, return
	bset	#s2b_doublejump,status2(a0)	; set the double jump flag
	bne.b	Sonic_DoubleJump2_Return		; if it was already set, return
	bclr	#4,status(a0)				; clear uncontrolled jump flag
	moveq	#0,d0
	move.b	status2(a0),d0			; get the secondary status
	move.w	d0,d1
	andi.b	#power_mask,d0				; does Sonic have invincibility?
	bne.b	Sonic_Flash				; if so, check for Hyper Sonic
	andi.b	#shield_mask,d1				; get shield type
	add.w	d1,d1					; do corresponding action
	move.w	Sonic_DoubleJumpActions(pc,d1.w),d1
	jmp	Sonic_DoubleJumpActions(pc,d1.w)
; ===========================================================================

Sonic_DoubleJumpActions:
	dc.w	Sonic_InstaShield-Sonic_DoubleJumpActions
	dc.w	Sonic_BubbleBounce-Sonic_DoubleJumpActions
	dc.w	Sonic_FireDash-Sonic_DoubleJumpActions
	dc.w	Sonic_LightningJump-Sonic_DoubleJumpActions
; ===========================================================================

Sonic_Flash:
	cmpi.b	#power_hyper,d0				; is Sonic hyper?
	bne.b	Sonic_Flash_Return			; if not, branch
	; TODO: Hyper Sonic Flash code
	nop

Sonic_Flash_Return:
	rts

Sonic_InstaShield:
	move.w  #objroutine(InstaShield),(Sonic_Shield).w     ; Load Instashield
	move.b	#$2C,height_pixels(a0)				; set larger hitbox
	move.b	#$22,width_pixels(a0)
	move.b	#$E5,d0					; play fire dash sound
	jmp	PlaySound

Sonic_DoubleJump2_Return:
	rts
; ===========================================================================

Sonic_FireDash:
	move.b	#1,(Sonic_Shield+anim).w
	move.w	#$800,d0
	btst	#0,status(a0)
	beq.s	+
	neg.w	d0				; If Sonic is facing left
+	move.w	d0,x_vel(a0)
	move.w	d0,inertia(a0)
	move.w	#0,y_vel(a0)
	move.w	#$2000,($FFFFEED0).w
	move.w	#$3F,d2
-	bsr.w	Sonic_RecordPos
	subq.w	#4,a1
	move.l	#0,(a1)
	dbf	d2,-
	move.b	#$E2,d0				; play fire dash sound
	jsr	PlaySound

return_11A14:
	rts
; ===========================================================================
SparkVelocities:
       dc.w  $FE00, $FE00
       dc.w   $200, $FE00
       dc.w  $FE00,  $200
       dc.w   $200,  $200
; ===========================================================================

Sonic_LightningJump:
	move.w	#-$600,y_vel(a0)			; move Sonic upwards
	move.b	#2,anim(a0)			; use "bouncing" animation
	move.b	#$E3,d0				; play lightning jump sound
	jsr	PlaySound
	moveq	#1,d2
	lea	SparkVelocities(pc),a2
	moveq	#3,d1
-	jsr	(SingleObjLoad).l
	bne.s	return_19862
	move.w	#objroutine(Lightning_Shield_Spark),(a1)		; Load object E1 (lightning shield spark)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.l	#Map_LighteningShield,mappings(a1)
	move.w	#$4D5,art_tile(a1)
	move.b	#4,render_flags(a1)
	move.w	#$80,priority(a1)
	move.b	#8,width_pixels(a1)
	move.b	#1,anim(a1)
	move.w	(a2)+,x_vel(a1)
	move.w	(a2)+,y_vel(a1)
	dbf	d1,-

return_19862:
	rts
; ===========================================================================

Sonic_BubbleBounce:
	bset	#5,status3(a0)
	move.w	#$780,y_vel(a0)
	cmp.b	#1,($FFFFF730).w
	bne.s	+
	btst	#6,status(a0)
	beq.s	+
	move.w	#$3C0,y_vel(a0)
+	clr.w	x_vel(a0)
	move.b	#1,air_action(a0)
	move.b	#1,($FFFFD180+$2F).w
	move.b	#$E4,d0
	jmp	(playsound).w

Sonic_BounceRecoil:
	cmp.b	#1,air_action(a0)
	bne.s	+
	bra.s	BounceRecoil
+	rts

BounceRecoil:
	move.b	#0,($FFFFD180+$2F).w
	move.b	#2,air_action(a0)
	bclr	#4,status(a0)
	moveq	#0,d0
	move.b	$26(a0),d0
	addi.b	#$80,d0
	jsr	CalcRoomOverHead
	cmp.w	#6,d1
	blt.w	BounceRecoil_Return
	move.w	#$780,d2
	cmp.b	#1,($FFFFF730).w
	bne.s	+
	btst	#6,status(a0)
	beq.s	+
	move.w	#$3C0,d2
+	moveq	#0,d0
	move.b	angle(a0),d0
	subi.b	#$40,d0
	jsr	(CalcSine).w
	muls.w	d2,d1
	asr.l	#8,d1
	add.w	d1,x_vel(a0)
	muls.w	d2,d0
	asr.l	#8,d0
	add.w	d0,y_vel(a0)
	bset	#1,status(a0)
	bclr	#5,status(a0)
	addq.l	#4,sp
	bset	#5,status3(a0)
	clr.b	interact_obj(a0)
	move.w	#$E4,d0
	jsr	(playsound).l
	move.b	#$E,height_pixels(a0)
	move.b	#7,width_pixels(a0)
	move.b	#2,anim(a0)
	bset	#2,status(a0)
	addq.w	#5,y_pos(a0)
	clr.b	air_action(a0)

BounceRecoil_Return:
	rts
; ===========================================================================
; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Player_Display:
	move.w	invulnerable_time(a0),d0
	beq.s	+
	subq.w	#1,invulnerable_time(a0)
	lsr.w	#3,d0
	bcc.s	Player_ChkInvin
+	jsr	DisplaySprite		; display sprite only if not invisible from flashing

Player_ChkInvin:			; Checks if invincibility has expired and disables it if it has.
	move.b	status2(a0),d0
	andi.b	#power_mask,d0
	beq.s	Player_ChkShoes
	tst.w	invincibility_time(a0)
	beq.s	Player_ChkShoes		; If there wasn't any time left, that means we're in Super Sonic mode.
	subq.w	#1,invincibility_time(a0)
	bne.s	Player_ChkShoes
	tst.b	(Current_Boss_ID).w	; Don't change music if in a boss fight
	bne.s	Player_RmvInvin
	cmpi.b	#$C,air_left(a0)	; Don't change music if drowning
	blo.s	Player_RmvInvin
	move.w	(Level_Music).w,d0
	jsr	(PlayMusic).l

Player_RmvInvin:
	andi.b	#power_del,status2(a0)
	bsr.w	ChooseShield

Player_ChkShoes:		; Checks if Speed Shoes have expired and disables them if they have.
	btst	#s2b_speedshoes,status2(a0)
	beq.s	Sonic_ExitChk
	tst.w	speedshoes_time(a0)
	beq.s	Sonic_ExitChk
	subq.w	#1,speedshoes_time(a0)
	bne.s	Sonic_ExitChk
	bclr	#s2b_speedshoes,status2(a0)	; unset speed shoes flag
	move.w	#MusID_SlowDown,d0			; Slow down tempo
	jsr	(PlayMusic).l
	bra.w	ChooseSpeeds

Sonic_ExitChk:
	rts

; End of subroutine Player_Display
; ===========================================================================

ChooseShield:
	moveq	#0,d0
	moveq	#bytestoLcnt(object_size*4),d1
	lea	Sonic_Shield-MainCharacter(a0),a1
-	move.l	d0,(a1)+			; clear any existing shield/stars
	dbf	d1,-
	move.b	status2(a0),d0
	btst	#s2b_3,d0			; is player super/hyper?
	bne.b	ChooseShield_Super		; if so, branch
	btst	#s2b_2,d0			; is player invincible?
	bne.b	ChooseShield_Invincible		; if so, branch
	andi.b	#shield_mask,d0			; get the type of shield
	beq.b	ChooseShield_None		; if no shield, branch
	add.w	d0,d0				; load corresponding object
	move.w	ChooseShield_Objects-2(pc,d0.w),Sonic_Shield-MainCharacter(a0)

ChooseShield_None:
	rts
; ===========================================================================

ChooseShield_Objects:
	dc.w	objroutine(Bubble_Shield)
	dc.w	objroutine(Fire_Shield)
	dc.w	objroutine(Lightning_Shield)
; ===========================================================================

ChooseShield_Super:				; load super stars
	move.w	#objroutine(SS_Stars),Sonic_Shield-MainCharacter(a0)
	rts

ChooseShield_Invincible:			; load invincibility stars
	move.w	#objroutine(Invincibility_Stars),Sonic_Shield-MainCharacter(a0)
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine for Sonic when he's underwater
; ---------------------------------------------------------------------------

Player_Water:
	tst.b	(Water_flag).w	; does level have water?
	bne.s	Player_InWater	; if yes, branch

return_1A18C:
	rts

Player_InWater:
	move.w	(Water_Level_1).w,d0
	cmp.w	y_pos(a0),d0	; is Sonic above the water?
	bge.s	Player_OutWater	; if yes, branch
	bset	#6,status(a0)	; set underwater flag
	bne.s	return_1A18C	; if already underwater, branch
	movea.l	a0,a1
	bsr.w	ResumeMusic
	bsr.w	ChooseSpeeds
	lea	Sonic_BreathingBubbles-MainCharacter(a0),a1
	move.w	#objroutine(Small_Bubbles),(a1) ; load Small_Bubbles (sonic's breathing bubbles) at $FFFFD080
	move.b	#$81,subtype(a1)
	move.l	a0,$3C(a1)
	asr.w	x_vel(a0)
	asr.w	y_vel(a0)	; memory operands can only be shifted one bit at a time
	asr.w	y_vel(a0)
	beq.s	return_1A18C
	move.w	#$100,Sonic_Dust-MainCharacter+anim(a0)	; splash animation
	move.w	#SndID_Splash,d0			; splash sound
	jmp	(PlaySound).l
+	rts	

Player_OutWater:
	bclr	#6,status(a0)	; unset underwater flag
	beq.s	return_1A18C	; if already above water, branch
	movea.l	a0,a1
	bsr.w	ResumeMusic
	bsr.w	ChooseSpeeds
	cmpi.w	#objroutine(Sonic_Hurt),(a0)	; is Sonic falling back from getting hurt?
	beq.s	+		; if yes, branch
	asl	y_vel(a0)
+	tst.w	y_vel(a0)
	beq.w	return_1A18C
	move.w	#$100,Sonic_Dust-MainCharacter+anim(a0)	; splash animation
	movea.l	a0,a1
	bsr.w	ResumeMusic
	cmpi.w	#-$1000,y_vel(a0)
	bgt.s	+
	move.w	#-$1000,y_vel(a0)	; limit upward y velocity exiting the water
+
	move.w	#SndID_Splash,d0	; splash sound
	jmp	(PlaySound).l
; ===========================================================================

ChooseSpeeds:
	moveq	#0,d0
	btst	#s2b_3,status2(a0)		; is the player super or hyper?
	beq.b	ChooseSpeeds_NotSuper			; if not, branch
	addi.w	#Speeds_SuperSonic-Speeds_Normal,d0	; use Super Sonic speeds
	cmpa.w	MainCharacter,a0			; is this the second player?
	bne.b	ChooseSpeeds_SuperTails			; if so, branch
	cmpi.b	#2,(Player_mode).w			; are we playing Tails alone?
	bne.b	ChooseSpeeds_ChkWater			; if not, branch

ChooseSpeeds_SuperTails:
	addi.w	#Speeds_SuperTails-Speeds_SuperSonic,d0	; use Super Tails speeds
	bra.b	ChooseSpeeds_ChkWater

ChooseSpeeds_NotSuper:
	btst	#s2b_speedshoes,status2(a0)	; does the player have speed shoes?
	beq.b	ChooseSpeeds_ChkWater			; if not, branch
	addi.w	#Speeds_Shoes-Speeds_Normal,d0		; use speed shoes speeds

ChooseSpeeds_ChkWater:
	btst	#s1b_water,status(a0)			; is the player underwater?
	beq.b	ChooseSpeeds_Finish			; if not, branch
	addi.w	#Speeds_Water-Speeds_Normal,d0		; use underwater speeds

ChooseSpeeds_Finish:
	lea	Speeds_Normal,a1
	adda.l	d0,a1
	cmpa.w	MainCharacter,a0			; is this the second player?
	bne.b	ChooseSpeeds_Finish_Tails		; if so, branch
	move.w	(a1)+,(Sonic_top_speed).w
	move.w	(a1)+,(Sonic_acceleration).w
	move.w	(a1)+,(Sonic_deceleration).w
	rts

ChooseSpeeds_Finish_Tails:
	move.w	(a1)+,(Tails_top_speed).w
	move.w	(a1)+,(Tails_acceleration).w
	move.w	(a1)+,(Tails_deceleration).w
	rts

Speeds_Normal:		dc.w	$0600, $000C, $0080, 0
Speeds_Water:		dc.w	$0300, $0006, $0040, 0
Speeds_Shoes:		dc.w	$0C00, $0018, $0080, 0
Speeds_ShoesW:		dc.w	$0A00, $0014, $0060, 0
Speeds_SuperSonic:	dc.w	$0A00, $0030, $0100, 0
Speeds_SuperSonicW:	dc.w	$0500, $0018, $0080, 0
Speeds_SuperTails:	dc.w	$0800, $0018, $00C0, 0
Speeds_SuperTailsW:	dc.w	$0400, $000C, $0060, 0
