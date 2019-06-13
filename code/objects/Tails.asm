; ===========================================================================
; ----------------------------------------------------------------------------
; Tails
; ----------------------------------------------------------------------------
	;Tails_Init	; 0
	;Tails_Control	; 2
	;Tails_Hurt	; 4
	;Tails_Dead	; 6
	;Tails_Gone	; 8
	;Tails_Respawning	;$A
; ===========================================================================	
Tails:
	tst.w	(Player_Option).w
	beq.s	+
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	move.w	(Camera_Min_X_pos).w,(Tails_Min_X_pos).w
	move.w	(Camera_Max_X_pos).w,(Tails_Max_X_pos).w
	move.w	(Camera_Max_Y_pos_now).w,(Tails_Max_Y_pos).w
+
	move.w	#objroutine(Tails_Control),(a0)	; => Tails_Normal
	move.b	#$1E,height_pixels(a0) ; this sets Tails' collision height (2*pixels) to less than Sonic's height
	move.b	#18,width_pixels(a0)
	move.l	#MapUnc_Tails,mappings(a0)
	move.w	#$100,priority(a0)
	move.b	#$18,width_pixels(a0)
	move.b	#$84,render_flags(a0) ; render_flags(Tails) = $80 | initial render_flags(Sonic)
	move.w	#$600,(Tails_top_speed).w	; set Tails' top speed
	move.w	#$C,(Tails_acceleration).w	; set Tails' acceleration
	move.w	#$80,(Tails_deceleration).w	; set Tails' deceleration
	tst.b	(Last_star_pole_hit).w
	bne.s	Tails_Init_Continued
	; only happens when not starting at a checkpoint:
	move.w	#$7A0,art_tile(a0)
	move.b	#$C,layer(a0)
	move.b	#$D,layer_plus(a0)
	move.w	x_pos(a0),(Saved_x_pos).w
	move.w	y_pos(a0),(Saved_y_pos).w
	move.w	art_tile(a0),(Saved_art_tile).w
	move.w	layer(a0),(Saved_layer).w
	bra.s	Tails_Init_Continued
; ===========================================================================
; loc_1B952:
Tails_Init_2Pmode:
	move.w	#$7A0,art_tile(a0)
	move.w	(MainCharacter+layer).w,layer(a0)
	tst.w	(MainCharacter+art_tile).w
	bpl.s	Tails_Init_Continued
	ori.w	#$8000,art_tile(a0)
; loc_1B96E:
Tails_Init_Continued:
	move.w	x_pos(a0),(Saved_x_pos_2P).w
	move.w	y_pos(a0),(Saved_y_pos_2P).w
	move.w	art_tile(a0),(Saved_art_tile_2P).w
	move.b	#0,(Super_Tails_flag).w
	move.w	layer(a0),(Saved_layer_2P).w
	move.b	#0,flips_remaining(a0)
	move.b	#4,flip_speed(a0)
	move.b	#$1E,air_left(a0)
	move.w	#0,(Tails_CPU_routine).w	; set AI state to TailsCPU_Init
	move.w	#0,(Tails_control_counter).w
	move.w	#0,(Tails_respawn_counter).w
	move.w	#objroutine(Tails_Tails_Init),(Tails_Tails+id).w ; load Tails_Tails (Tails' Tails) at $FFFFD000
	move.w	a0,(Tails_Tails+parent).w ; set its parent object to this

; ---------------------------------------------------------------------------
; Normal state for Tails
; ---------------------------------------------------------------------------
; loc_1B9B4:
Tails_Control:
	tst.w	(Player_Option).w
	beq.s	+
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	move.w	(Camera_Min_X_pos).w,(Tails_Min_X_pos).w
	move.w	(Camera_Max_X_pos).w,(Tails_Max_X_pos).w
	move.w	(Camera_Max_Y_pos_now).w,(Tails_Max_Y_pos).w
+
	tst.w	(Debug_mode_flag).w
	beq.s	+
	btst	#button_B,(Ctrl_1_Press).w	; is button B pressed?
	beq.s	+			; if not, branch
	cmp.w	#2,(Player_Mode).w
	bne.s	+
	move.w	#1,(Debug_placement_mode).w	; change Sonic into a ring/item
	rts
+
	cmpa.w	#MainCharacter,a0
	bne.s	Tails_Control_Joypad2
	move.w	(Ctrl_1_Logical).w,(Ctrl_2_Logical).w
	tst.b	(Control_Locked).w	; are controls locked?
	bne.s	Tails_Control_Part2	; if yes, branch
	move.w	(Ctrl_1).w,(Ctrl_2_Logical).w	; copy new held buttons, to enable joypad control
	move.w	(Ctrl_1).w,(Ctrl_1_Logical).w
	bra.s	Tails_Control_Part2
; ---------------------------------------------------------------------------
; loc_1B9D4:
Tails_Control_Joypad2:
	tst.b	($FFFFF7CF).w
	bne.s	+
	move.w	(Ctrl_2).w,(Ctrl_2_Logical).w
+
	tst.w	(Two_player_mode).w
	bne.s	Tails_Control_Part2
	bsr.w	TailsCPU_Control
; loc_1B9EA:
Tails_Control_Part2:
	btst	#s3b_lock_motion,status3(a0)	; is Tails flying, or interacting with another object that holds him in place or controls his movement somehow?
	bne.s	+			; if yes, branch to skip Tails' control
	moveq	#0,d0
	move.b	status(a0),d0
	andi.w	#6,d0	; %0000 %0110
	move.w	Tails_Modes(pc,d0.w),d1
	jsr	Tails_Modes(pc,d1.w)	; run Tails' movement control code
+
	cmpi.w	#-$100,(Camera_Min_Y_pos).w	; is vertical wrapping enabled?
	bne.s	+                               ; if not, branch
	andi.w	#$7FF,y_pos(a0)                 ; perform wrapping of Sonic's y position
+
	bsr.w	Player_Display
	bsr.w	Tails_Super	; Super	player_off24
	bsr.w	Tails_RecordPos
	bsr.w	Player_Water
	move.b	($FFFFF768).w,next_tilt(a0)
	move.b	($FFFFF76A).w,tilt(a0)
	tst.b	(WindTunnel_flag).w
	beq.s	+
	tst.b	anim(a0)
	bne.s	+
	move.b	next_anim(a0),anim(a0)
+
	bsr.w	Tails_Animate
	btst	#s3b_lock_jumping,status3(a0)
	bne.s	+
	jsr	(TouchResponse).l
+
	bra.w	LoadTailsDynPLC

; ===========================================================================
; secondary states under state Tails_Normal
; off_1BA4E:
Tails_Modes:
	dc.w Tails_MdNormal - Tails_Modes	; not airborne or rolling
	dc.w Tails_MdAir - Tails_Modes		; airborne
	dc.w Tails_MdRoll - Tails_Modes		; rolling
	dc.w Tails_MdJump - Tails_Modes		; jumping
; ===========================================================================
; ---------------------------------------------------------------------------
; Tails' AI code for the Sonic and Tails mode 1-player game
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1BAD4:
TailsCPU_Control: ; a0=Tails
	move.b	(Ctrl_2_Held).w,d0	; did the real player 2 hit something?
	andi.b	#button_up_mask|button_down_mask|button_left_mask|button_right_mask|button_B_mask|button_C_mask|button_A_mask,d0
	beq.s	+			; if not, branch
	move.w	#600,(Tails_control_counter).w ; give player 2 control for 10 seconds (minimum)
+
	lea	(MainCharacter).w,a1 ; a1=character ; a1=Sonic
	move.w	(Tails_CPU_routine).w,d0
	move.w	TailsCPU_States(pc,d0.w),d0
	jmp	TailsCPU_States(pc,d0.w)
; ===========================================================================
; off_1BAF4:
TailsCPU_States:
	dc.w TailsCPU_Init - TailsCPU_States	; 0
	dc.w TailsCPU_Spawning - TailsCPU_States; 2
	dc.w TailsCPU_Flying - TailsCPU_States	; 4
	dc.w TailsCPU_Normal - TailsCPU_States	; 6
	dc.w TailsCPU_Panic - TailsCPU_States	; 8

; ===========================================================================
; initial AI State
; ---------------------------------------------------------------------------
; loc_1BAFE:
TailsCPU_Init:
	move.w	#6,(Tails_CPU_routine).w	; => TailsCPU_Normal
	andi.b	#lock_del,status3(a0)
	move.b	#0,anim(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#0,status(a0)
	move.w	#0,(Tails_respawn_counter).w
	rts

; ===========================================================================
; AI State where Tails is waiting to respawn
; ---------------------------------------------------------------------------
; loc_1BB30:
TailsCPU_Spawning:
	move.b	(Ctrl_2_Held_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask|button_start_mask,d0
	bne.s	TailsCPU_Respawn
	move.w	(Timer_frames).w,d0
	andi.w	#$3F,d0
	bne.s	return_1BB88
	btst	#s3b_lock_motion,status3(a1)
	bne.s	return_1BB88
	move.b	status(a1),d0
	andi.b	#$D2,d0
	bne.s	return_1BB88
; loc_1BB54:
TailsCPU_Respawn:
	move.w	#4,(Tails_CPU_routine).w	; => TailsCPU_Flying
	move.w	x_pos(a1),d0
	move.w	d0,x_pos(a0)
	move.w	d0,(Tails_CPU_target_x).w
	move.w	y_pos(a1),d0
	move.w	d0,(Tails_CPU_target_y).w
	subi.w	#$C0,d0
	move.w	d0,y_pos(a0)
	ori.w	#$8000,art_tile(a0)
	bclr	#s3b_spindash,status3(a0)
	move.w	#0,spindash_counter(a0)

return_1BB88:
	rts

; ===========================================================================
; AI State where Tails pretends to be a helicopter
; ---------------------------------------------------------------------------
; loc_1BB8A:
TailsCPU_Flying:
	tst.b	render_flags(a0)
	bmi.s	TailsCPU_FlyingOnscreen
	addq.w	#1,(Tails_respawn_counter).w
	cmpi.w	#$12C,(Tails_respawn_counter).w
	blo.s	TailsCPU_Flying_Part2
	move.w	#0,(Tails_respawn_counter).w
	move.w	#2,(Tails_CPU_routine).w	; => TailsCPU_Spawning
	ori.b	#lock_mask,status3(a0)
	move.b	#2,status(a0)
	move.w	#0,x_pos(a0)
	move.w	#0,y_pos(a0)
	move.b	#$20,anim(a0)
	rts
; ---------------------------------------------------------------------------
; loc_1BBC8:
TailsCPU_FlyingOnscreen:
	move.w	#0,(Tails_respawn_counter).w
; loc_1BBCE:
TailsCPU_Flying_Part2:
	lea	(Sonic_Pos_Record_Buf).w,a2
	move.w	#$10,d2
	lsl.b	#2,d2
	addq.b	#4,d2
	move.w	(Sonic_Pos_Record_Index).w,d3
	sub.b	d2,d3
	move.w	(a2,d3.w),(Tails_CPU_target_x).w
	move.w	2(a2,d3.w),(Tails_CPU_target_y).w
	tst.b	(Water_flag).w
	beq.s	+
	move.w	(Water_Level_1).w,d0
	subi.w	#$10,d0
	cmp.w	(Tails_CPU_target_y).w,d0
	bge.s	+
	move.w	d0,(Tails_CPU_target_y).w
+
	move.w	x_pos(a0),d0
	sub.w	(Tails_CPU_target_x).w,d0
	beq.s	loc_1BC54
	mvabs.w	d0,d2
	lsr.w	#4,d2
	cmpi.w	#$C,d2
	blo.s	+
	moveq	#$C,d2
+
	mvabs.b	x_vel(a1),d1
	add.b	d1,d2
	addq.w	#1,d2
	tst.w	d0
	bmi.s	loc_1BC40
	bset	#0,status(a0)
	cmp.w	d0,d2
	blo.s	+
	move.w	d0,d2
	moveq	#0,d0
+
	neg.w	d2
	bra.s	loc_1BC50
; ---------------------------------------------------------------------------

loc_1BC40:
	bclr	#0,status(a0)
	neg.w	d0
	cmp.w	d0,d2
	blo.s	loc_1BC50
	move.b	d0,d2
	moveq	#0,d0

loc_1BC50:
	add.w	d2,x_pos(a0)

loc_1BC54:
	moveq	#1,d2
	move.w	y_pos(a0),d1
	sub.w	(Tails_CPU_target_y).w,d1
	beq.s	loc_1BC68
	bmi.s	loc_1BC64
	neg.w	d2

loc_1BC64:
	add.w	d2,y_pos(a0)

loc_1BC68:
	lea	(Sonic_Stat_Record_Buf).w,a2
	move.b	2(a2,d3.w),d2
	andi.b	#$D2,d2
	bne.s	return_1BCDE
	or.w	d0,d1
	bne.s	return_1BCDE
	move.w	#6,(Tails_CPU_routine).w	; => TailsCPU_Normal
	andi.b	#lock_del,status3(a0)
	move.b	#0,anim(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#2,status(a0)
	move.w	#0,move_lock(a0)
	andi.w	#$7FFF,art_tile(a0)
	tst.b	art_tile(a1)
	bpl.s	+
	ori.w	#$8000,art_tile(a0)
+
	move.b	layer(a1),layer(a0)
	move.b	layer_plus(a1),layer_plus(a0)
	cmpi.b	#9,anim(a1)
	beq.s	return_1BCDE
	btst	#s3b_spindash,status3(a0)
	beq.s	return_1BCDE
	bset	#s3b_spindash,status3(a1)
	bsr.w	loc_212C4

return_1BCDE:
	rts
loc_212C4:
	btst	#2,status(a1)
	beq.s	+
	rts
; ---------------------------------------------------------------------------
+	bset	#2,status(a1)
	move.b	#$1C,height_pixels(a1)
	move.b	#14,width_pixels(a1)
	move.b	#2,anim(a1)
	addq.w	#5,y_pos(a1)
	move.w	#SndID_Roll,d0
	jsr	(PlaySound).l
	rts
; ===========================================================================
; AI State where Tails follows the player normally
; ---------------------------------------------------------------------------
; loc_1BCE0:
TailsCPU_Normal:
	move.w	(MainCharacter).w,d2	; is Sonic dead
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Tails_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	+
	move.w	Tails_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	+	
	move.w	Tails_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	+	
	bra.s	TailsCPU_Normal_SonicOK		; if not, branch
	; Sonic's dead; fly down to his corpse
+	move.w	#4,(Tails_CPU_routine).w	; => TailsCPU_Flying
	bclr	#s3b_spindash,status3(a0)
	move.w	#0,spindash_counter(a0)
	ori.b	#lock_mask,status3(a0)
	move.b	#2,status(a0)
	move.b	#$20,anim(a0)
	rts
	
Tails_Check:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

Tails_Check2:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)

Tails_Check3:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)		
; ---------------------------------------------------------------------------
; loc_1BD0E:
TailsCPU_Normal_SonicOK:
	bsr.w	TailsCPU_CheckDespawn
	tst.w	(Tails_control_counter).w	; if CPU has control
	bne.w	TailsCPU_Normal_HumanControl		; (if not, branch)
	btst	#s3b_lock_jumping,status3(a0)			; and Tails isn't fully object controlled (&$80)
	bne.w	TailsCPU_Normal_HumanControl		; (if not, branch)
	tst.w	move_lock(a0)			; and Tails' movement is locked (usually because he just fell down a slope)
	beq.s	+					; (if not, branch)
	tst.w	inertia(a0)			; and Tails is stopped, then...
	bne.s	+					; (if not, branch)
	move.w	#8,(Tails_CPU_routine).w	; => TailsCPU_Panic
+
	lea	(Sonic_Pos_Record_Buf).w,a1
	move.w	#$10,d1
	lsl.b	#2,d1
	addq.b	#4,d1
	move.w	(Sonic_Pos_Record_Index).w,d0
	sub.b	d1,d0
	move.w	(a1,d0.w),d2	; d2 = earlier x position of Sonic
	move.w	2(a1,d0.w),d3	; d3 = earlier y position of Sonic
	lea	(Sonic_Stat_Record_Buf).w,a1
	move.w	(a1,d0.w),d1	; d1 = earlier input of Sonic
	move.b	2(a1,d0.w),d4	; d4 = earlier status of Sonic
	move.w	d1,d0
	btst	#5,status(a0)	; is Tails pushing against something?
	beq.s	+		; if not, branch
	btst	#5,d4		; was Sonic pushing against something?
	beq.w	TailsCPU_Normal_FilterAction_Part2 ; if not, branch elsewhere

; either Tails isn't pushing, or Tails and Sonic are both pushing
+	sub.w	x_pos(a0),d2
	beq.s	TailsCPU_Normal_Stand ; branch if Tails is already lined up horizontally with Sonic
	bpl.s	TailsCPU_Normal_FollowRight
	neg.w	d2

; Tails wants to go left because that's where Sonic is
; loc_1BD76: TailsCPU_Normal_FollowLeft:
	cmpi.w	#$10,d2
	blo.s	+
	andi.w	#$F3F3,d1 ; %1111001111110011
	ori.w	#$0404,d1 ; %0000010000000100
+
	tst.w	inertia(a0)
	beq.s	TailsCPU_Normal_FilterAction
	btst	#0,status(a0)
	beq.s	TailsCPU_Normal_FilterAction
	subq.w	#1,x_pos(a0)
	bra.s	TailsCPU_Normal_FilterAction
; ===========================================================================
; Tails wants to go right because that's where Sonic is
; loc_1BD98:
TailsCPU_Normal_FollowRight:
	cmpi.w	#$10,d2
	blo.s	+
	andi.w	#$F3F3,d1 ; %1111001111110011
	ori.w	#$0808,d1 ; %0000100000001000
+
	tst.w	inertia(a0)
	beq.s	TailsCPU_Normal_FilterAction
	btst	#0,status(a0)
	bne.s	TailsCPU_Normal_FilterAction
	addq.w	#1,x_pos(a0)
	bra.s	TailsCPU_Normal_FilterAction
; ===========================================================================
; Tails is happy where he is
; loc_1BDBA:
TailsCPU_Normal_Stand:
	bclr	#0,status(a0)
	move.b	d4,d0
	andi.b	#1,d0
	beq.s	TailsCPU_Normal_FilterAction
	bset	#0,status(a0)

; Filter the action we chose depending on a few things
; loc_1BDCE:
TailsCPU_Normal_FilterAction:
	tst.b	($FFFFF70F).w
	beq.s	+
	ori.w	#$7000,d1
	btst	#1,status(a0)
	bne.s	TailsCPU_Normal_SendAction
	move.b	#0,($FFFFF70F).w
+
	move.w	(Timer_frames).w,d0
	andi.w	#$FF,d0
	beq.s	+
	cmpi.w	#$40,d2
	bhs.s	TailsCPU_Normal_SendAction
+
	sub.w	y_pos(a0),d3
	beq.s	TailsCPU_Normal_SendAction
	bpl.s	TailsCPU_Normal_SendAction
	neg.w	d3
	cmpi.w	#$20,d3
	blo.s	TailsCPU_Normal_SendAction
; loc_1BE06:
TailsCPU_Normal_FilterAction_Part2:
	move.b	(Timer_frames+1).w,d0
	andi.b	#$3F,d0
	bne.s	TailsCPU_Normal_SendAction
	cmpi.b	#8,anim(a0)
	beq.s	TailsCPU_Normal_SendAction
	ori.w	#((button_B_mask|button_C_mask|button_A_mask)<<8)|(button_B_mask|button_C_mask|button_A_mask),d1
	move.b	#1,($FFFFF70F).w

; Send the action we chose by storing it into player 2's input
; loc_1BE22:
TailsCPU_Normal_SendAction:
	move.w	d1,(Ctrl_2_Logical).w
	rts

; ===========================================================================
; Follow orders from controller 2
; and decrease the counter to when the CPU will regain control
; loc_1BE28:
TailsCPU_Normal_HumanControl:
	tst.w	(Tails_control_counter).w
	beq.s	+	; don't decrease if it's already 0
	subq.w	#1,(Tails_control_counter).w
+
	rts

; ===========================================================================
; loc_1BE34:
TailsCPU_Despawn:
	move.w	#0,(Tails_control_counter).w
	move.w	#0,(Tails_respawn_counter).w
	move.w	#2,(Tails_CPU_routine).w	; => TailsCPU_Spawning
	ori.b	#lock_mask,status3(a0)
	move.b	#2,status(a0)
	move.w	#$4000,x_pos(a0)
	move.w	#0,y_pos(a0)
	move.b	#$20,anim(a0)
	rts
; ===========================================================================
; sub_1BE66:
TailsCPU_CheckDespawn:
	tst.b	render_flags(a0)
	bmi.s	TailsCPU_ResetRespawnTimer
	btst	#3,status(a0)
	beq.s	TailsCPU_TickRespawnTimer

	moveq	#-1,d0
	move.w	interact_obj(a0),d0
	movea.l	d0,a3	; a3=object
	move.b	(Tails_interact_ID).w,d0
	cmp.b	(a3),d0
	bne.s	BranchTo_TailsCPU_Despawn

; loc_1BE8C:
TailsCPU_TickRespawnTimer:
	addq.w	#1,(Tails_respawn_counter).w
	cmpi.w	#$12C,(Tails_respawn_counter).w
	blo.s	TailsCPU_UpdateObjInteract

BranchTo_TailsCPU_Despawn
	bra.w	TailsCPU_Despawn
; ===========================================================================
; loc_1BE9C:
TailsCPU_ResetRespawnTimer:
	move.w	#0,(Tails_respawn_counter).w
; loc_1BEA2:
TailsCPU_UpdateObjInteract:
	moveq	#-1,d0
	move.w	interact_obj(a0),d0
	movea.l	d0,a3	; a3=object
	move.b	(a3),(Tails_interact_ID).w
	rts

; ===========================================================================
; AI State where Tails stops, drops, and spindashes in Sonic's direction
; ---------------------------------------------------------------------------
; loc_1BEB8:
TailsCPU_Panic:
	bsr.w	TailsCPU_CheckDespawn
	tst.w	(Tails_control_counter).w
	bne.w	return_1BF36
	tst.w	move_lock(a0)
	bne.s	return_1BF36
	btst	#s3b_spindash,status3(a0)
	bne.s	TailsCPU_Panic_ChargingDash

	tst.w	inertia(a0)
	bne.s	return_1BF36
	bclr	#0,status(a0)
	move.w	x_pos(a0),d0
	sub.w	x_pos(a1),d0
	bcs.s	+
	bset	#0,status(a0)
+
	move.w	#(button_down_mask<<8)|button_down_mask,(Ctrl_2_Logical).w
	move.b	(Timer_frames+1).w,d0
	andi.b	#$7F,d0
	beq.s	TailsCPU_Panic_ReleaseDash

	cmpi.b	#8,anim(a0)
	bne.s	return_1BF36
	move.w	#((button_down_mask|button_B_mask|button_C_mask|button_A_mask)<<8)|(button_down_mask|button_B_mask|button_C_mask|button_A_mask),(Ctrl_2_Logical).w
	rts
; ---------------------------------------------------------------------------
; loc_1BF0C:
TailsCPU_Panic_ChargingDash:
	move.w	#(button_down_mask<<8)|button_down_mask,(Ctrl_2_Logical).w
	move.b	(Timer_frames+1).w,d0
	andi.b	#$7F,d0
	bne.s	TailsCPU_Panic_RevDash

; loc_1BF1C:
TailsCPU_Panic_ReleaseDash:
	move.w	#0,(Ctrl_2_Logical).w
	move.w	#6,(Tails_CPU_routine).w	; => TailsCPU_Normal
	rts
; ---------------------------------------------------------------------------
; loc_1BF2A:
TailsCPU_Panic_RevDash:
	andi.b	#$1F,d0
	bne.s	return_1BF36
	ori.w	#((button_B_mask|button_C_mask|button_A_mask)<<8)|(button_B_mask|button_C_mask|button_A_mask),(Ctrl_2_Logical).w

return_1BF36:
	rts
; End of function TailsCPU_Control


; ---------------------------------------------------------------------------
; Subroutine to record Tails' previous positions for invincibility stars
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1BF38:
Tails_RecordPos:
	move.w	(Tails_Pos_Record_Index).w,d0
	lea	(Tails_Pos_Record_Buf).w,a1
	lea	(a1,d0.w),a1
	move.w	x_pos(a0),(a1)+
	move.w	y_pos(a0),(a1)+
	addq.b	#4,(Tails_Pos_Record_Index+1).w

	rts
; End of subroutine Tails_RecordPos

; ===========================================================================
; ---------------------------------------------------------------------------
; Start of subroutine Tails_MdNormal
; Called if Tails is neither airborne nor rolling this frame
; ---------------------------------------------------------------------------
; loc_1C00A:
Tails_MdNormal:
        clr.b   Flying_Flag
        clr.b   Flying_Frame_Counter
	clr.b	Flying_carrying_sonic_flag
	bsr.w	Tails_CheckSpindash
	bsr.w	Tails_Jump
	bsr.w	Tails_SlopeResist
	bsr.w	Tails_Move
	bsr.w	Tails_Roll
	bsr.w	Tails_LevelBound
	jsr	(ObjectMove).l
	bsr.w	AnglePos
	bsr.w	Tails_SlopeRepel
	rts
; End of subroutine Tails_MdNormal
; ===========================================================================
; Start of subroutine Tails_MdAir
; Called if Tails is airborne, but not in a ball (thus, probably not jumping)
; loc_1C032: Tails_MdJump
Tails_MdAir:
	tst.w	($FFFFFF72).w
	bne.s	+
	tst.w	(Tails_control_counter).w
	bne.s	+
	bra.s	++
	rts
+
        tst.b    Flying_flag
          bne.s   Tails_MdFlight; Branch if Flying
+
	bsr.w	Tails_JumpHeight
	bsr.w	Tails_ChgJumpDir
	bsr.w	Tails_LevelBound
	jsr	(ObjectMoveAndFall).l
	btst	#6,status(a0)	; is Tails underwater?
	beq.s	+		; if not, branch
	subi.w	#$28,y_vel(a0)	; reduce gravity by $28 ($38-$28=$10)
+
	bsr.w	Tails_JumpAngle
	bsr.w	Tails_DoLevelCollision
	rts
; ---------------------------------------------------------------------------
; Tails Flying Code
; ---------------------------------------------------------------------------

; EQUATES - should be added to main RAM equates section
Tails_Min_Y_pos =		ramaddr( $FFFFEEFC )

Flying_flag =			ramaddr( $FFFFFEB0 ) ; not 0 means Tails is flying. If 1, Tails will have gravity applied, otherwise he won't. Maximum value is $1F, after which it returns to 1.
Flying_frame_counter =		ramaddr( $FFFFFEB1 ) ; Flying frames left / 2. Starts off at $F0 (240)
Flying_carrying_sonic_flag =	ramaddr( $FFFFFEB2 ) ; The byte after this one (referenced as 1(a2) in Flying_CarrySonic) is a counter which does not allow Tails to pick Sonic up if it's not equal to 0.
Flying_tails_X_vel =		ramaddr( $FFFFFEB4 )
Flying_tails_Y_vel =		ramaddr( $FFFFFEB6 )

Tails_MdFlight:
	bsr.s	Flying_Main	; Main flying code
	bsr.w	Tails_ChgJumpDir
	bsr.w	Tails_LevelBound
	jsr	ObjectMove
	bsr.w	Tails_JumpAngle
	movem.l	a4-a6,-(sp)
	bsr.w	Tails_DoLevelCollision
	movem.l	(sp)+,a4-a6

	tst.w	(Player_mode).w	; Are Sonic and Tails together?
	bne.s	return_15438	; If not, branch
	lea	(Flying_carrying_sonic_flag).w,a2
	lea	(MainCharacter).w,a1
	move.w	(Ctrl_1_Logical).w,d0	; P1 controls
	;bsr.w	Flying_CarrySonic	; Tails picking up Sonic code
	bra.w	Flying_CarrySonic	; Changed to a bra.w since it's followed by an rts anyway
; ---------------------------------------------------------------------------

return_15438:
	rts
; ===========================================================================

Flying_Main:
	move.b	(Timer_frames+1).w,d0	; 2nd byte of timer frames
	andi.b	#1,d0	; Is it odd or even?
	beq.s	+	; Branch if it's even
	tst.b	(Flying_frame_counter).w	; Is Tails tired?
	beq.s	+	; Branch if he is
	subq.b	#1,(Flying_frame_counter).w

+	cmpi.b	#1,(Flying_flag).w
	beq.s	Flying_ButtonCheck
	cmpi.w	#-$100,y_vel(a0)	; Is Tails' Y speed less than -100?
	blt.s	+	; Branch if it is (cap Tails' Y speed)
	subi.w	#$20,y_vel(a0)	; Give Tails some upthrust
	addq.b	#1,(Flying_flag).w
	cmpi.b	#$20,(Flying_flag).w	; prevent it from becoming over $1F
	bne.s	++

+	move.b	#1,(Flying_flag).w

+	bra.s	Flying_Boundary_CheckTop	; Skip the controller check and gravity player_off24
; ---------------------------------------------------------------------------

Flying_ButtonCheck:
	;move.b	(Ctrl_1_Press_Logical).w,d0
	;tst.w	(Player_mode).w
	;bne.s	$$tailsalone
	;move.b	(Ctrl_2_Press).w,d0
	move.b	(Ctrl_2_Press_Logical).w,d0	; applies for Tails in both 1P and 2P mode
	andi.b	#$70,d0	; Is A or B or C pressed?
	beq.s	Flying_Gravity	; If not, branch
	cmpi.w	#-$100,y_vel(a0)	; Is Tails' Y speed less than -100?
	blt.s	Flying_Gravity	; Branch to the adding gravity player_off24 if it is
	tst.b	(Flying_frame_counter).w	; Is Tails tired?
	beq.s	Flying_Gravity	; Branch to the adding gravity player_off24 if he is
	btst	#6,status(a0)	; Is Tails underwater?
	beq.s	+	; Branch if he isn't
	tst.b	(Flying_carrying_sonic_flag).w	; Is Tails carrying Sonic?
	bne.s	Flying_Gravity	; Prevent Tails from going into gravity-less swimming if he's underwater and trying to carry Sonic

+	move.b	#2,(Flying_flag).w

Flying_Gravity:
	addi.w	#8,y_vel(a0)	; Give Tails gravity

Flying_Boundary_CheckTop:
	move.w	(Tails_Min_Y_pos).w,d0
	addi.w	#$10,d0
	cmp.w	y_pos(a0),d0	; Has Tails touched the top of the screen?
	blt.w	Flying_SetAnimation	; If he hasn't, branch
	tst.w	y_vel(a0)	; Is Tails already falling down?
	bpl.w	Flying_SetAnimation	; Branch if he is
	clr.w	y_vel(a0)	; Stop Tails from going over the top of the screen
	bra.w	Flying_SetAnimation	; My own addition, but doing it this way seems to make more sense
; ===========================================================================

Tails_CheckStartFlying:
	tst.w	($FFFFFF72).w
	bne.s	+
	tst.w	(Tails_control_counter).w
	bne.s	+
	rts
;+
		;tst.w	($FFFFFF72).w
		;bne.s	+


+
	;move.b	($FFFFF603).w,d0 ; Move	Data from Source to Destination
	;andi.b	#$70,d0	; 'p'   ; AND Immediate
	move.b	(Ctrl_2_Press_Logical).w,d0	; applies for Tails in both 1P and 2P mode
	andi.b	#$70,d0	; Is A or B or C pressed?
	beq.w	return_15CDA
		tst.b	(Super_Tails_flag).w
		bne.s	+
		cmp.b	#7,($FFFFFFB1).w
		bcs.s	+
		cmp.w	#50,(Ring_count).w
		bcs.s	+
		tst.b	(Update_HUD_timer).w
			bne.w	Tails_TransformToSuper
+
	tst.b	(Flying_flag).w	; Is Tails already flying?
	bne.s	return_15CDA	; Return if he is
	;move.b	(Ctrl_1_Press_Logical).w,d0
	;tst.w	(Player_mode).w
	;bne.s	$$tailsalone
	;move.b	(Ctrl_2_Press).w,d0
	move.b	(Ctrl_2_Press_Logical).w,d0	; applies for Tails in both 1P and 2P mode
	andi.b	#$70,d0	; Is A or B or C is pressed?
	beq.w	return_15CDA	; If not, branch
	; The following code would have tested if Tails was under CPU control
	; Since this code can only be reached if he isn't, there's no point of the check
	;bra.s	loc_15C9C
	;dc.w	$60fe
	;tst.w	(Tails_control_counter).w
	;beq.s	return_15CDA

	; Set flying flags
	btst	#2,status(a0)	; Is Tails rolling?
	beq.s	+	; If he isn't, branch
	bclr	#2,status(a0)	; Clear the rolling flag
	move.b	height_pixels(a0),d1
	lsr.b	#1,d1
	move.b	#$1E,height_pixels(a0)
	move.b	#14,width_pixels(a0)
	sub.b	#$f,d1
	ext.w	d1
	add.w	d1,y_pos(a0)	; Raise Tails up a bit when he starts the flight

+	bclr	#4,status(a0)	; Clear the uncontrolled jump flag
	move.b	#1,(Flying_flag).w
	move.b	#$F0,(Flying_frame_counter).w
	;bsr.w	Flying_SetAnimation
	bra.s	Flying_SetAnimation	; Changed to a bra since it's followed by an rts anyway
; ---------------------------------------------------------------------------

return_15CDA:
	rts
; ===========================================================================

Flying_SetAnimation:
	btst	#6,status(a0)	; Is Tails underwater?
	bne.s	Swimming_SetAnimation	; If he is, branch
	moveq	#$20,d0
	; In Sonic 3, I guess the 2P Tails only had one sort of flying animation
	; Since Sonic 2's 2P Tails is just a squashed 1P tails, there's no point limiting it to 1 animation
	;tst.w	(Two_player_mode).w
	;bne.s	loc_1550C
	tst.w	y_vel(a0)	; Is Tails moving downwards?
	bpl.s	+	; If he is, branch
	moveq	#$21,d0

;+	tst.b	(Flying_carrying_sonic_flag).w	; Is Tails carrying Sonic?
;	beq.s	+	; If he isn't, branch
;	addq.b	#2,d0

+	tst.b	(Flying_frame_counter).w	; Is Tails tired?
	bne.s	+	; If he isn't, branch
	moveq	#$24,d0
	; Commented out major code duplication
	; moveq	#$20,d0; '$'
	;move.b	d0,anim(a0)	; Set animation to $24 (tired)
	;tst.b	render_flags(a0)	; Is Tails on-screen?
	;bpl.s	locret_1550A	; If he isn't, branch
	;move.b	(Timer_frames+1).w,d0	; Second byte of timer frames
	;addq.b	#8,d0
	;andi.b	#$F,d0
	;bne.s	locret_1550A	; Only play the sound once every $10 frames
	;move.l	#$4F+$80,d0
	;jsr	(PlayMusic).l
	;jmp	(PlaySound).l	; Changed to a jmp since it's followed by an rts anyway

	;moveq	#$20,d0 ; dbg
+	move.b	d0,anim(a0)	; Set the relevant animation
	tst.b	render_flags(a0)	; Is Tails on-screen?
	bpl.s	return_1552A	; If he isn't, branch
	move.b	(Timer_frames+1).w,d0	; 2nd byte of timer frames
	addq.b	#8,d0
	andi.b	#$F,d0
	bne.s	return_1552A	; Only play the sound once every $10 frames
	tst.b	(Flying_frame_counter).w
	beq.s	Tails_Tired_FlyingSound
	move.b	#$F1,d0
	;jsr	(PlayMusic).l
	jmp	(PlaySound).l	; Changed to a jmp since it's followed by an rts anyway
; ---------------------------------------------------------------------------
Tails_Tired_FlyingSound:
	move.b	#$F2,d0
	jmp	(PlaySound).l
return_1552A:
	rts
; ===========================================================================

Swimming_SetAnimation:
	moveq	#$25,d0
	tst.w	y_vel(a0)	; Is Tails moving downwards?
	bpl.s	+	; If he is, branch
	moveq	#$26,d0

+	tst.b	(Flying_carrying_sonic_flag).w	; Is Tails carrying Sonic?
	beq.s	+	; If he isn't, branch
	moveq	#$27,d0

+	tst.b	(Flying_frame_counter).w	; Is Tails tired?
	bne.s	+	; If he isn't, branch
	moveq	#$28,d0

	; moveq	#$20,d0; dbg
+	move.b	d0,anim(a0)	; Set the relevant animation
	rts
; ===========================================================================

Flying_CarrySonic:
	; a1 = $B000 = Sonic SST, a2 = $FEB2 = Tails picking up Sonic flag
	; d0 = $F602 and $F603 = P1 controller buttons held/pressed
	tst.b	(a2)	; Is Tails carrying Sonic?
	beq.w	Flying_CheckPickUpSonic	; If he isn't, branch
	cmpi.w	#objroutine(Sonic_Hurt),(a1)	; Is Sonic hurt/dead?
	beq.w	Flying_ReleaseSonic3	; If he is, branch
	cmpi.w	#objroutine(Sonic_Dead),(a1)	; Is Sonic hurt/dead?
	beq.w	Flying_ReleaseSonic3	; If he is, branch	
	btst	#1,status(a1)	; Is Sonic in the air?
	beq.w	Flying_ReleaseSonic1	; If he isn't, branch
	move.w	(Flying_tails_X_vel).w,d1
	cmp.w	x_vel(a1),d1	; Is Sonic's X velocity equal to Tails' X velocity?
	bne.s	Flying_ReleaseSonic1	; If it isn't, branch
	move.w	(Flying_tails_Y_vel).w,d1
	cmp.w	y_vel(a1),d1	; Is Sonic's Y velocity equal to Tails' Y velocity?
	bne.s	Flying_ReleaseSonic2	; If it isn't, branch
	btst	#s3b_lock_jumping,status3(a1)	; Is Sonic under the complete control of another object? (for example a spin tube)
	bne.s	Flying_ReleaseSonic4	; Branch if he is
	andi.b	#$70,d0	; Is A or B or C pressed?
	beq.w	Flying_UpdateSonicPosition	; If not, branch

	; The following code is for Sonic jumping out of Tails
	andi.b	#lock_del,status3(a1)	; Clear the control flag
	clr.b	(a2)	; Clear the Tails picking up Sonic flag
	move.b	#$12,1(a2)	; Some sort of timer
	andi.w	#$F00,d0	; Any directional buttons held?
	;beq.w	loc_15096	; If not, branch
	beq.s	++	; If no directional buttons are held, we might as well skip left and right held checks
	move.b	#$3C,1(a2)

	btst	#$A,d0	; Is left held?
	beq.s	+	; If not, branch
	move.w	#-$200,x_vel(a1)

+	btst	#$B,d0	; Is right held?
	beq.s	+	; If not, branch
	move.w	#$200,x_vel(a1)

+	move.w	#-$380,y_vel(a1)
	bset	#1,status(a1)	; Set the Sonic in air flag
	bset	#s3b_jumping,status3(a1)
	move.b	#$1C,height_pixels(a1)
	move.b	#14,width_pixels(a1)
	move.b	#2,anim(a1)	; Use jumping animation
	bset	#2,status(a1)	; Set rolling flag
	bclr	#4,status(a1)	; Clear uncontrolled jump flag
	rts
; ---------------------------------------------------------------------------

; The following four routines are for a forced release of Sonic (i.e. a release not caused by him jumping out)
Flying_ReleaseSonic1:
	move.w	#-$100,y_vel(a1)

Flying_ReleaseSonic2:
	bclr	#s3b_jumping,status3(a1)

Flying_ReleaseSonic3:
	andi.b	#lock_del,status3(a1)	; Clear the control flag

Flying_ReleaseSonic4:
	clr.b	(a2)	; Clear the Tails picking up Sonic flag
	move.b	#$3C,1(a2)
	rts
; ===========================================================================

Flying_UpdateSonicPosition:
	move.w	x_pos(a0),x_pos(a1)	; Move Tails' X position to Sonic's X position
	move.w	y_pos(a0),y_pos(a1)	; Move Tails' Y position to Sonic's Y position
	addi.w	#$1C,y_pos(a1)	; Lower Sonic slightly
	;andi.b	#$FC,render_flags(a1)	; Clear X and Y mirroring flag
	andi.b	#$FE,status(a1)	; Clear X orientation flag
	move.b	status(a0),d0
	andi.b	#1,d0	; We're only interested in the X orientation flag
	;or.b	d0,render_flags(a1)	; Make Sonic's X mirroring match Tails'
	or.b	d0,status(a1)	; Make Sonic's X orientation match Tails'

	; I'm commenting out the below code because I have no idea what it does (besides the obvious fact that it's something animation related) and because doing so doesn't seem to make any difference
	; It also seems strange to do stuff like this manually when there are whole dedicated animation routines
	;subq.b	#1,anim_frame_duration(a1)
	;bpl.s	loc_15166
	;move.b	#$B,anim_frame_duration(a1)
	;moveq	#0,d1
	;move.b	anim_frame(a1),d1
	;addq.b	#1,anim_frame(a1)
	;move.b	byte_15190(pc,d1.w),d0
	;cmpi.b	#-1,d0
	;bne.s	loc_15152
	;move.b	#0,anim_frame(a1)
	;move.b	byte_15190,d0

;loc_15152:
	;move.b	d0,mapping_frame(a1)
	;moveq	#0,d0
	;move.b	mapping_frame(a1),d0
	;;move.l	a2,-(sp)	; Original S3 code
	;movem.l	a0-a2,-(sp)
	;lea	(MainCharacter).w,a0
	;;jsr	sub_13A82	; Original S3 code
	;;movea.l	(sp)+,a2	; Original S3 code
	;jsr	(LoadSonicDynPLC_Part2).l
	;movem.l	(sp)+,a0-a2

	move.w	x_vel(a0),(MainCharacter+x_vel).w	; Make Sonic's X speed identical to Tails'
	move.w	x_vel(a0),(Flying_tails_X_vel).w
	move.w	y_vel(a0),(MainCharacter+y_vel).w	; Make Sonic's Y speed identical to Tails'
	move.w	y_vel(a0),(Flying_tails_Y_vel).w
	movem.l	d0-a6,-(sp)
	lea	(MainCharacter).w,a0
	bsr.w	Sonic_DoLevelCollision
	movem.l	(sp)+,d0-a6
	rts
; ---------------------------------------------------------------------------

; Commeting this out because I commented out the code that depended on it
;byte_15190:
;	dc.b	$91
;	dc.b	$91
;	dc.b	$90
;	dc.b	$90
;	dc.b	$90
;	dc.b	$90
;	dc.b	$90
;	dc.b	$90
;	dc.b	$92
;	dc.b	$92
;	dc.b	$92
;	dc.b	$92
;	dc.b	$92
;	dc.b	$92
;	dc.b	$91
;	dc.b	$91
;	dc.b	$FF
;	dc.b	0
; ===========================================================================

Flying_CheckPickUpSonic:
	tst.b	1(a2)	; Is the timer 0?
	beq.s	+	; If it is, branch
	subq.b	#1,1(a2)	; Subtract 1
	bne.w	return_15200	; If it's still not 0, Tails can't pick up Sonic, so return

+	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	addi.w	#$10,d0
	cmpi.w	#$20,d0	; X position check
	bcc.w	return_15200	; Return if it failed
	move.w	y_pos(a1),d1
	sub.w	y_pos(a0),d1
	subi.w	#$20,d1
	cmpi.w	#$10,d1	; Y position check
	bcc.w	return_15200	; Return if it failed
	btst	#s3b_lock_motion,status3(a1)	; Is Sonic completely free from external control?
	bne.w	return_15200	; If he isn't, return
	cmpi.w	#objroutine(Sonic_Hurt),(a1)	; Is Sonic hurt/dead?
	beq.w	return_15200	; If he is, branch
	cmpi.w	#objroutine(Sonic_Dead),(a1)	; Is Sonic hurt/dead?
	beq.w	return_15200	; If he is, branch	
	tst.w	(Debug_placement_mode).w	; Is object placement mode on?
	bne.w	return_15200	; If it is, return
	btst	#s3b_spindash,status3(a1)	; Is Sonic spindashing or in a forced roll?
	bne.s	return_15200	; If he is, return
	;bsr.s	sub_15202	; Execute the Tails picking up Sonic player_off24

	; Inlining the Tails picking up Sonic routine because it's called only once
	clr.w	x_vel(a1)
	clr.w	y_vel(a1)
	clr.w	inertia(a1)
	clr.w	angle(a1)
	move.w	x_pos(a0),x_pos(a1)	; Move Tails' X position to Sonic's X position
	move.w	y_pos(a0),y_pos(a1)	; Move Tails' Y position to Sonic's Y position
	addi.w	#$1C,y_pos(a1)	; Push Sonic down slightly
	;move.w	#$2200,anim(a1)	; Set Sonic's animation
	move.b	#$14,anim(a1)	; I'm using the Sonic 2 hanging animation
	;move.b	#0,anim_frame_duration(a1)
	;move.b	#0,anim_frame(a1)
	bset	#s3b_lock_motion,status3(a1)	; Set the Sonic under control of another object flag
	bset	#1,status(a1)	; Set the Sonic in air flag
	bclr	#4,status(a1)	; Clear the uncontrolled jump flag
	bclr	#s3b_spindash,status3(a1)	; Clear the spindash flag
	;andi.b	#$FC,render_flags(a1)	; Clear X and Y mirroring flag
	andi.b	#$FE,status(a1)	; Clear X orientation flag
	move.b	status(a0),d0
	andi.b	#1,d0	; We're only interested in the X orientation flag
	;or.b	d0,render_flags(a1)	; Make Sonic's X mirroring match Tails'
	or.b	d0,status(a1)	; Make Sonic's X orientation match Tails'
	move.w	x_vel(a0),(Flying_tails_X_vel).w
	move.w	x_vel(a0),x_vel(a1)	; Make Sonic's X speed identical to Tails'
	move.w	y_vel(a0),(Flying_tails_Y_vel).w
	move.w	y_vel(a0),y_vel(a1)	; Make Sonic's Y speed identical to Tails'

	moveq	#$4A+$80,d0
	jsr	(PlaySound).l
	move.b	#1,(a2)	; Set the Tails picking up Sonic flag

return_15200:
	rts
; ---------------------------------------------------------------------------
; End of Tails Flying Code
; ---------------------------------------------------------------------------
; End of subroutine Tails_MdAir
; ===========================================================================
; Start of subroutine Tails_MdRoll
; Called if Tails is in a ball, but not airborne (thus, probably rolling)
; loc_1C05C:
Tails_MdRoll:
	btst	#s3b_spindash,status3(a0)
	bne.s	+
	bsr.w	Tails_Jump
+
	bsr.w	Tails_RollRepel
	bsr.w	Tails_RollSpeed
	bsr.w	Tails_LevelBound
	jsr	(ObjectMove).l
	bsr.w	AnglePos
	bsr.w	Tails_SlopeRepel
	rts
; End of subroutine Tails_MdRoll
; ===========================================================================
; Start of subroutine Tails_MdJump
; Called if Tails is in a ball and airborne (he could be jumping but not necessarily)
; Notes: This is identical to Tails_MdAir, at least at this outer level.
;        Why they gave it a separate copy of the code, I don't know.
; loc_1C082: Tails_MdJump2:
Tails_MdJump:

	bsr.w	Tails_JumpHeight
	bsr.w	Tails_ChgJumpDir
	bsr.w	Tails_LevelBound
	jsr	(ObjectMoveAndFall).l
	btst	#6,status(a0)	; is Tails underwater?
	beq.s	+		; if not, branch
	subi.w	#$28,y_vel(a0)	; reduce gravity by $28 ($38-$28=$10)
+
	bsr.w	Tails_JumpAngle
	bsr.w	Tails_DoLevelCollision
	rts
; End of subroutine Tails_MdJump

; ---------------------------------------------------------------------------
; Subroutine to make Tails walk/run
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C0AC:
Tails_Move:
	move.w	(Tails_top_speed).w,d6
	move.w	(Tails_acceleration).w,d5
	move.w	(Tails_deceleration).w,d4
	tst.b	status2(a0)
	bmi.w	Tails_Traction
	tst.w	move_lock(a0)
	bne.w	Tails_ResetScr
	btst	#button_left,(Ctrl_2_Held_Logical).w	; is left being pressed?
	beq.s	Tails_NotLeft			; if not, branch
	bsr.w	Tails_MoveLeft
; loc_1C0D4:
Tails_NotLeft:
	btst	#button_right,(Ctrl_2_Held_Logical).w	; is right being pressed?
	beq.s	Tails_NotRight			; if not, branch
	bsr.w	Tails_MoveRight
; loc_1C0E0:
Tails_NotRight:
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0		; is Tails on a slope?
	bne.w	Tails_ResetScr	; if yes, branch
	tst.w	inertia(a0)	; is Tails moving?
	bne.w	Tails_ResetScr	; if yes, branch
	bclr	#5,status(a0)
	move.b	#5,anim(a0)	; use "standing" animation
	btst	#3,status(a0)
	beq.s	Tails_Balance
	moveq	#-1,d0
	move.w	interact_obj(a0),d0
	movea.l	d0,a1
	tst.b	status(a1)
	bmi.s	Tails_Lookup
	moveq	#0,d1
	move.b	width_pixels(a1),d1
	move.w	d1,d2
	add.w	d2,d2
	subq.w	#4,d2
	add.w	x_pos(a0),d1
	sub.w	x_pos(a1),d1
	cmpi.w	#4,d1
	blt.s	Tails_BalanceOnObjLeft
	cmp.w	d2,d1
	bge.s	Tails_BalanceOnObjRight
	bra.s	Tails_Lookup
; ---------------------------------------------------------------------------
; balancing checks for Tails
; loc_1C142:
Tails_Balance:
	jsr	(ChkFloorEdge).l
	cmpi.w	#$C,d1
	blt.s	Tails_Lookup
	cmpi.b	#3,next_tilt(a0)
	bne.s	Tails_BalanceLeft
; loc_1C156:
Tails_BalanceOnObjRight:
	bclr	#0,status(a0)
	bra.s	Tails_BalanceDone
; ---------------------------------------------------------------------------
; loc_1C15E:
Tails_BalanceLeft:
	cmpi.b	#3,tilt(a0)
	bne.s	Tails_Lookup
; loc_1C166:
Tails_BalanceOnObjLeft:
	bset	#0,status(a0)
; loc_1C16C:
Tails_BalanceDone:
	move.b	#6,anim(a0)
	bra.s	Tails_ResetScr
; ---------------------------------------------------------------------------
; loc_1C174:
Tails_Lookup:
	btst	#button_up,(Ctrl_2_Held_Logical).w	; is up being pressed?
	beq.s	Tails_Duck			; if not, branch
	move.b	#7,anim(a0)			; use "looking up" animation
	addq.w	#1,(Tails_Look_delay_counter).w
	cmpi.w	#$78,(Tails_Look_delay_counter).w
	blo.s	Tails_ResetScr_Part2
	move.w	#$78,(Tails_Look_delay_counter).w
	cmpi.w	#$C8,(Camera_Y_pos_bias_P2).w
	beq.s	Tails_UpdateSpeedOnGround
	addq.w	#2,(Camera_Y_pos_bias_P2).w
	bra.s	Tails_UpdateSpeedOnGround
; ---------------------------------------------------------------------------
; loc_1C1A2:
Tails_Duck:
	btst	#button_down,(Ctrl_2_Held_Logical).w	; is down being pressed?
	beq.s	Tails_ResetScr			; if not, branch
	move.b	#8,anim(a0)			; use "ducking" animation
	addq.w	#1,(Tails_Look_delay_counter).w
	cmpi.w	#$78,(Tails_Look_delay_counter).w
	blo.s	Tails_ResetScr_Part2
	move.w	#$78,(Tails_Look_delay_counter).w
	cmpi.w	#8,(Camera_Y_pos_bias_P2).w
	beq.s	Tails_UpdateSpeedOnGround
	subq.w	#2,(Camera_Y_pos_bias_P2).w
	bra.s	Tails_UpdateSpeedOnGround

; ===========================================================================
; moves the screen back to its normal position after looking up or down
; loc_1C1D0:
Tails_ResetScr:
	move.w	#0,(Tails_Look_delay_counter).w
; loc_1C1D6:
Tails_ResetScr_Part2:
	cmpi.w	#$60,(Camera_Y_pos_bias_P2).w	; is screen in its default position?
	beq.s	Tails_UpdateSpeedOnGround	; if yes, branch.
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias_P2).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias_P2).w	; or subtract 2
+
		tst.b	(Super_Tails_flag).w
		beq.s	Tails_UpdateSpeedOnGround
		move.w	#$C,d5

; ---------------------------------------------------------------------------
; updates Tails' speed on the ground
; ---------------------------------------------------------------------------
; loc_1C1E8:
Tails_UpdateSpeedOnGround:
	move.b	(Ctrl_2_Held_Logical).w,d0
	andi.b	#button_left_mask|button_right_mask,d0		; is left/right pressed?
	bne.s	Tails_Traction	; if yes, branch
	move.w	inertia(a0),d0
	beq.s	Tails_Traction
	bmi.s	Tails_SettleLeft

; slow down when facing right and not pressing a direction
; Tails_SettleRight:
	sub.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)
	bra.s	Tails_Traction
; ---------------------------------------------------------------------------
; slow down when facing left and not pressing a direction
; loc_1C208:
Tails_SettleLeft:
	add.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)

; increase or decrease speed on the ground
; loc_1C214:
Tails_Traction:
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	inertia(a0),d1
	asr.l	#8,d1
	move.w	d1,x_vel(a0)
	muls.w	inertia(a0),d0
	asr.l	#8,d0
	move.w	d0,y_vel(a0)

; stops Tails from running through walls that meet the ground
; loc_1C232:
Tails_CheckWallsOnGround:
	move.b	angle(a0),d0
	addi.b	#$40,d0
	bmi.s	return_1C2A2
	move.b	#$40,d1
	tst.w	inertia(a0)
	beq.s	return_1C2A2
	bmi.s	+
	neg.w	d1
+
	move.b	angle(a0),d0
	add.b	d1,d0
	move.w	d0,-(sp)
	bsr.w	CalcRoomInFront
	move.w	(sp)+,d0
	tst.w	d1
	bpl.s	return_1C2A2
	asl.w	#8,d1
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	loc_1C29E
	cmpi.b	#$40,d0
	beq.s	loc_1C28C
	cmpi.b	#$80,d0
	beq.s	loc_1C286
	add.w	d1,x_vel(a0)
	bset	#5,status(a0)
	move.w	#0,inertia(a0)
	rts
; ---------------------------------------------------------------------------

loc_1C286:
	sub.w	d1,y_vel(a0)
	rts
; ---------------------------------------------------------------------------

loc_1C28C:
	sub.w	d1,x_vel(a0)
	bset	#5,status(a0)
	move.w	#0,inertia(a0)
	rts
; ---------------------------------------------------------------------------
loc_1C29E:
	add.w	d1,y_vel(a0)

return_1C2A2:
	rts
; End of subroutine Tails_Move


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C2A4:
Tails_MoveLeft:
	move.w	inertia(a0),d0
	beq.s	+
	bpl.s	Tails_TurnLeft	; if Tails is already moving to the right, branch
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
; loc_1C2DE:
Tails_TurnLeft:
	sub.w	d4,d0
	bcc.s	+
	move.w	#-$80,d0
+
	move.w	d0,inertia(a0)
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	bne.s	return_1C328
	cmpi.w	#$400,d0
	blt.s	return_1C328
	move.b	#$D,anim(a0)	; use "stopping" animation
	bclr	#0,status(a0)
	move.w	#SndID_Skidding,d0
	jsr	(PlaySound).l
	cmpi.b	#$C,air_left(a0)
	blo.s	return_1C328	; if he's drowning, branch to not make dust
	move.w	#objroutine(Water_Splash_Object_CheckSkid),Tails_Dust
	move.b	#$15,(Tails_Dust+mapping_frame).w

return_1C328:
	rts
; End of subroutine Tails_MoveLeft


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C32A:
Tails_MoveRight:
	move.w	inertia(a0),d0
	bmi.s	Tails_TurnRight
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
; loc_1C35E:
Tails_TurnRight:
	add.w	d4,d0
	bcc.s	+
	move.w	#$80,d0
+
	move.w	d0,inertia(a0)
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	bne.s	return_1C3A8
	cmpi.w	#-$400,d0
	bgt.s	return_1C3A8
	move.b	#$D,anim(a0)	; use "stopping" animation
	bset	#0,status(a0)
	move.w	#SndID_Skidding,d0	; use "stopping" sound
	jsr	(PlaySound).l
	cmpi.b	#$C,air_left(a0)
	blo.s	return_1C3A8	; if he's drowning, branch to not make dust
	move.w	#objroutine(Water_Splash_Object_CheckSkid),Tails_Dust
	move.b	#$15,(Tails_Dust+mapping_frame).w

return_1C3A8:
	rts
; End of subroutine Tails_MoveRight

; ---------------------------------------------------------------------------
; Subroutine to change Tails' speed as he rolls
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C3AA:
Tails_RollSpeed:
	move.w	(Tails_top_speed).w,d6
	asl.w	#1,d6
	move.w	(Tails_acceleration).w,d5
	asr.w	#1,d5	; natural roll deceleration = 1/2 normal acceleration
		tst.b	(Super_Tails_flag).w
		beq.s	+
		move.w	#6,d5
+
	move.w	(Tails_deceleration).w,d4
	asr.w	#2,d4	; controlled roll deceleration...
			; interestingly, Tails is much worse at this than Sonic when underwater
	tst.b	status2(a0)
	bmi.w	Tails_Roll_ResetScr
	tst.w	move_lock(a0)
	bne.s	Tails_ApplyRollSpeed
	btst	#button_left,(Ctrl_2_Held_Logical).w	; is left being pressed?
	beq.s	+				; if not, branch
	bsr.w	Tails_RollLeft
+
	btst	#button_right,(Ctrl_2_Held_Logical).w	; is right being pressed?
	beq.s	Tails_ApplyRollSpeed		; if not, branch
	bsr.w	Tails_RollRight

; loc_1C3E2:
Tails_ApplyRollSpeed:
	move.w	inertia(a0),d0
	beq.s	Tails_CheckRollStop
	bmi.s	Tails_ApplyRollSpeedLeft

; Tails_ApplyRollSpeedRight:
	sub.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)
	bra.s	Tails_CheckRollStop
; ---------------------------------------------------------------------------
; loc_1C3F8:
Tails_ApplyRollSpeedLeft:
	add.w	d5,d0
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,inertia(a0)

; loc_1C404
Tails_CheckRollStop:
	tst.w	inertia(a0)
	bne.s	Tails_Roll_ResetScr
	btst	#s3b_spindash,status3(a0)  ; note: the spindash flag has a different meaning when Tails is already rolling -- it's used to mean he's not allowed to stop rolling
	bne.s	Tails_KeepRolling
	bclr	#2,status(a0)
	move.b	#$1E,height_pixels(a0) ; sets standing height to only slightly higher than rolling height, unlike Sonic
	move.b	#18,width_pixels(a0)
	move.b	#5,anim(a0)
	subq.w	#1,y_pos(a0)
	bra.s	Tails_Roll_ResetScr

; ---------------------------------------------------------------------------
; magically gives Tails an extra push if he's going to stop rolling where it's not allowed
; (such as in an S-curve in HTZ or a stopper chamber in CNZ)
; loc_1C42E:
Tails_KeepRolling:
	move.w	#$400,inertia(a0)
	btst	#0,status(a0)
	beq.s	Tails_Roll_ResetScr
	neg.w	inertia(a0)

; resets the screen to normal while rolling, like Tails_ResetScr
; loc_1C440:
Tails_Roll_ResetScr:
	cmpi.w	#$60,(Camera_Y_pos_bias_P2).w	; is screen in its default position?
	beq.s	Tails_SetRollSpeed		; if yes, branch
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias_P2).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias_P2).w	; or subtract 2

; loc_1C452:
Tails_SetRollSpeed:
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	inertia(a0),d0
	asr.l	#8,d0
	move.w	d0,y_vel(a0)	; set y velocity based on $14 and angle
	muls.w	inertia(a0),d1
	asr.l	#8,d1
	cmpi.w	#$1000,d1
	ble.s	+
	move.w	#$1000,d1	; limit Tails' speed rolling right
+
	cmpi.w	#-$1000,d1
	bge.s	+
	move.w	#-$1000,d1	; limit Tails' speed rolling left
+
	move.w	d1,x_vel(a0)	; set x velocity based on $14 and angle
	bra.w	Tails_CheckWallsOnGround
; End of function Tails_RollSpeed


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


; loc_1C488:
Tails_RollLeft:
	move.w	inertia(a0),d0
	beq.s	+
	bpl.s	Tails_BrakeRollingRight
+
	bset	#0,status(a0)
	move.b	#2,anim(a0)	; use "rolling" animation
	rts
; ---------------------------------------------------------------------------
; loc_1C49E:
Tails_BrakeRollingRight:
	sub.w	d4,d0	; reduce rightward rolling speed
	bcc.s	+
	move.w	#-$80,d0
+
	move.w	d0,inertia(a0)
	rts
; End of function Tails_RollLeft


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


; loc_1C4AC:
Tails_RollRight:
	move.w	inertia(a0),d0
	bmi.s	Tails_BrakeRollingLeft
	bclr	#0,status(a0)
	move.b	#2,anim(a0)	; use "rolling" animation
	rts
; ---------------------------------------------------------------------------
; loc_1C4C0:
Tails_BrakeRollingLeft:
	add.w	d4,d0		; reduce leftward rolling speed
	bcc.s	+
	move.w	#$80,d0
+
	move.w	d0,inertia(a0)
	rts
; End of subroutine Tails_RollRight


; ---------------------------------------------------------------------------
; Subroutine for moving Tails left or right when he's in the air
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C4CE:
Tails_ChgJumpDir:
	move.w	(Tails_top_speed).w,d6
	move.w	(Tails_acceleration).w,d5
	asl.w	#1,d5
	btst	#4,status(a0)		; did Tails jump from rolling?
	bne.s	Tails_Jump_ResetScr	; if yes, branch to skip midair control
	move.w	x_vel(a0),d0
	btst	#button_left,(Ctrl_2_Held_Logical).w
	beq.s	+	; if not holding left, branch

	bset	#0,status(a0)
	sub.w	d5,d0	; add acceleration to the left
	move.w	d6,d1
	neg.w	d1
	cmp.w	d1,d0	; compare new speed with top speed
	bgt.s	+	; if new speed is less than the maximum, branch
	move.w	d1,d0	; limit speed in air going left, even if Tails was already going faster (speed limit/cap)
+
	btst	#button_right,(Ctrl_2_Held_Logical).w
	beq.s	+	; if not holding right, branch

	bclr	#0,status(a0)
	add.w	d5,d0	; accelerate right in the air
	cmp.w	d6,d0	; compare new speed with top speed
	blt.s	+	; if new speed is less than the maximum, branch
	move.w	d6,d0	; limit speed in air going right, even if Tails was already going faster (speed limit/cap)
; Tails_JumpMove:
+	move.w	d0,x_vel(a0)

; loc_1C518: Tails_ResetScr2:
Tails_Jump_ResetScr:
	cmpi.w	#$60,(Camera_Y_pos_bias_P2).w	; is screen in its default position?
	beq.s	Tails_JumpPeakDecelerate			; if yes, branch
	bhs.s	+				; depending on the sign of the difference,
	addq.w	#4,(Camera_Y_pos_bias_P2).w	; either add 2
+	subq.w	#2,(Camera_Y_pos_bias_P2).w	; or subtract 2

; loc_1C52A:
Tails_JumpPeakDecelerate:
	cmpi.w	#-$400,y_vel(a0)	; is Tails moving faster than -$400 upwards?
	blo.s	return_1C558		; if yes, return
	move.w	x_vel(a0),d0
	move.w	d0,d1
	asr.w	#5,d1		; d1 = x_velocity / 32
	beq.s	return_1C558	; return if d1 is 0
	bmi.s	Tails_JumpPeakDecelerateLeft

; Tails_JumpPeakDecelerateRight:
	sub.w	d1,d0	; reduce x velocity by d1
	bcc.s	+
	move.w	#0,d0
+
	move.w	d0,x_vel(a0)
	rts
; ---------------------------------------------------------------------------
; loc_1C54C:
Tails_JumpPeakDecelerateLeft:
	sub.w	d1,d0	; reduce x velocity by d1
	bcs.s	+
	move.w	#0,d0
+
	move.w	d0,x_vel(a0)

return_1C558:
	rts
; End of subroutine Tails_ChgJumpDir
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to prevent Tails from leaving the boundaries of a level
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C55A:
Tails_LevelBound:
	move.l	x_pos(a0),d1
	move.w	x_vel(a0),d0
	ext.l	d0
	asl.l	#8,d0
	add.l	d0,d1
	swap	d1
	move.w	(Tails_Min_X_pos).w,d0
	addi.w	#$10,d0
	cmp.w	d1,d0			; has Tails touched the left boundary?
	bhi.s	Tails_Boundary_Sides	; if yes, branch
	move.w	(Tails_Max_X_pos).w,d0
	addi.w	#$128,d0
	tst.b	(Current_Boss_ID).w
	bne.s	+
	addi.w	#$40,d0
+
	cmp.w	d1,d0			; has Tails touched the right boundary?
	bls.s	Tails_Boundary_Sides	; if yes, branch

; loc_1C58C:
Tails_Boundary_CheckBottom:
	move.w	(Tails_Max_Y_pos).w,d0
	addi.w	#$E0,d0
	cmp.w	y_pos(a0),d0		; has Tails touched the bottom boundary?
	blt.s	Tails_Boundary_Bottom	; if yes, branch
	rts
; ---------------------------------------------------------------------------
Tails_Boundary_Bottom: ;;
	bra.w	JmpTo2_KillCharacter
; ===========================================================================

; loc_1C5A0:
Tails_Boundary_Sides:
	move.w	d0,x_pos(a0)
	move.w	#0,2+x_pos(a0) ; subpixel x
	move.w	#0,x_vel(a0)
	move.w	#0,inertia(a0)
	bra.s	Tails_Boundary_CheckBottom
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine allowing Tails to start rolling when he's moving
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C5B8:
Tails_Roll:
	tst.b	status2(a0)
	bmi.s	Tails_NoRoll
	mvabs.w	inertia(a0),d0
	cmpi.w	#$80,d0		; is Tails moving at $80 speed or faster?
	blo.s	Tails_NoRoll	; if not, branch
	move.b	(Ctrl_2_Held_Logical).w,d0
	andi.b	#button_left_mask|button_right_mask,d0		; is left/right being pressed?
	bne.s	Tails_NoRoll	; if yes, branch
	btst	#button_down,(Ctrl_2_Held_Logical).w	; is down being pressed?
	bne.s	Tails_ChkRoll			; if yes, branch
; return_1C5DE:
Tails_NoRoll:
	rts

; ---------------------------------------------------------------------------
; loc_1C5E0:
Tails_ChkRoll:
	btst	#2,status(a0)	; is Tails already rolling?
	beq.s	Tails_DoRoll	; if not, branch
	rts

; ---------------------------------------------------------------------------
; loc_1C5EA:
Tails_DoRoll:
	bset	#2,status(a0)
	move.b	#$1C,height_pixels(a0)
	move.b	#14,width_pixels(a0)
	move.b	#2,anim(a0)	; use "rolling" animation
	addq.w	#1,y_pos(a0)
	move.w	#SndID_Roll,d0
	jsr	(PlaySound).l	; play rolling sound
	tst.w	inertia(a0)
	bne.s	return_1C61C
	move.w	#$200,inertia(a0)

return_1C61C:
	rts
; End of function Tails_Roll


; ---------------------------------------------------------------------------
; Subroutine allowing Tails to jump
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C61E:
Tails_Jump:
	move.b	(Ctrl_2_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0 ; is A, B or C pressed?
	beq.w	return_1C6C2	; if not, return
	moveq	#0,d0
	move.b	angle(a0),d0
	addi.b	#$80,d0
	bsr.w	CalcRoomOverHead
	cmpi.w	#6,d1		; does Tails have enough room to jump?
	blt.w	return_1C6C2	; if not, branch
	move.w	#$680,d2
	btst	#6,status(a0)	; Test if underwater
	beq.s	+
	move.w	#$380,d2	; set lower jump speed if underwater
+
	moveq	#0,d0
	move.b	angle(a0),d0
	subi.b	#$40,d0
	jsr	(CalcSine).l
	muls.w	d2,d1
	asr.l	#8,d1
	add.w	d1,x_vel(a0)	; make Tails jump (in X... this adds nothing on level ground)
	muls.w	d2,d0
	asr.l	#8,d0
	add.w	d0,y_vel(a0)	; make Tails jump (in Y)
	bset	#1,status(a0)
	bclr	#5,status(a0)
	addq.l	#4,sp
	bset	#s3b_jumping,status3(a0)
	bclr	#s3b_stick_convex,status3(a0)
	move.w	#SndID_Jump,d0
	jsr	(PlaySound).l	; play jumping sound
	move.b	#$1E,height_pixels(a0)
	move.b	#18,width_pixels(a0)
	btst	#2,status(a0)
	bne.s	Tails_RollJump
	move.b	#$1C,height_pixels(a0)
	move.b	#14,width_pixels(a0)
	move.b	#2,anim(a0)	; use "jumping" animation
	bset	#2,status(a0)
	addq.w	#1,y_pos(a0)

return_1C6C2:
	rts
; ---------------------------------------------------------------------------
; loc_1C6C4:
Tails_RollJump:
	bset	#4,status(a0) ; set the rolling+jumping flag
	rts
; End of function Tails_Jump


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; ===========================================================================
; loc_1C6CC:
Tails_JumpHeight:
	btst	#s3b_jumping,status3(a0)	; is Tails jumping?
	beq.s	Tails_UpVelCap	; if not, branch

	move.w	#-$400,d1
	btst	#6,status(a0)	; is Tails underwater?
	beq.s	+		; if not, branch
	move.w	#-$200,d1

+

	cmp.w	y_vel(a0),d1	; is Tails going up faster than d1?
	ble.w	Tails_CheckStartFlying		; if not, branch
	move.b	(Ctrl_2_Held_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0 ; is a jump button pressed?
	bne.s	+		; if yes, branch
	move.w	d1,y_vel(a0)	; immediately reduce Tails's upward speed to d1

+
	rts
; ---------------------------------------------------------------------------
; loc_1C6F8:
Tails_UpVelCap:
	btst	#s3b_spindash,status3(a0)	; is Tails charging a spindash or in a rolling-only area?
	bne.s	return_1C70C		; if yes, return
	cmpi.w	#-$FC0,y_vel(a0)	; is Tails moving up really fast?
	bge.s	return_1C70C		; if not, return
	move.w	#-$FC0,y_vel(a0)	; cap upward speed

return_1C70C:
	rts
; End of subroutine Tails_JumpHeight

; ---------------------------------------------------------------------------
; Subroutine to check for starting to charge a spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C70E:
Tails_CheckSpindash:
	btst	#s3b_spindash,status3(a0)
	bne.w	Tails_UpdateSpindash
	cmpi.b	#8,anim(a0)
	bne.s	return_1C75C
	move.b	(Ctrl_2_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	beq.w	return_1C75C
	move.b	#9,anim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound).l
	addq.l	#4,sp
	bset	#s3b_spindash,status3(a0)
	move.w	#0,spindash_counter(a0)
	cmpi.b	#$C,air_left(a0)	; if he's drowning, branch to not make dust
	blo.s	loc_1C754
	move.b	#2,(Tails_Dust+anim).w

loc_1C754:
	bsr.w	Tails_LevelBound
	bsr.w	AnglePos

return_1C75C:
	rts
; End of subroutine Tails_CheckSpindash

Tails_TransformToSuper:
		move.b	#1,($FFFFF65F).w
		move.b	#$F,($FFFFF65E).w
		move.b	#1,(Super_Tails_flag).w
		move.w	#60,($FFFFF670).w
		move.b	#-$7F,$2A(a0)
		move.b	#$29,$1C(a0)
		;move.l	#Obj_SuperTailsBirds,(FFFFCD7C).w	;d040
		move.w	#$800,(Tails_top_speed).w
		move.w	#$18,(Tails_acceleration).w
		move.w	#$C0,(Tails_deceleration).w
		move.b	#0,$32(a0)
		bset	#1,$2B(a0)
	move.w	#SndID_SuperTransform,d0
	jsr	(PlaySound).l	; Play transformation sound effect.
	move.w	#MusID_SuperSonic,d0
	jmp	(PlayMusic).l	; load the Super Sonic song and return
; End of function Tails_JumpHeight
; ---------------------------------------------------------------------------
; Subrouting to update an already-charging spindash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C75E:
Tails_UpdateSpindash:
	move.b	(Ctrl_2_Held_Logical).w,d0
	btst	#button_down,d0
	bne.w	Tails_ChargingSpindash

	; unleash the charged spindash and start rolling quickly:
	move.b	#$1C,height_pixels(a0)
	move.b	#14,width_pixels(a0)
	move.b	#2,anim(a0)
	addq.w	#1,y_pos(a0)	; add the difference between Tails' rolling and standing heights
	bclr	#s3b_spindash,status3(a0)
	moveq	#0,d0
	move.b	spindash_counter(a0),d0
	add.w	d0,d0
	move.w	Tails_SpindashSpeeds(pc,d0.w),inertia(a0)
		tst.b	(Super_Tails_flag).w
		beq.s	+
		move.w	word_15320(pc,d0.w),inertia(a0)
+
	move.w	inertia(a0),d0
	subi.w	#$800,d0
	add.w	d0,d0
	andi.w	#$1F00,d0
	neg.w	d0
	addi.w	#$2000,d0
	move.w	d0,(Horiz_scroll_delay_val_P2).w
	btst	#0,status(a0)
	beq.s	+
	neg.w	inertia(a0)
+
	bset	#2,status(a0)
	move.b	#0,(Tails_Dust+anim).w
	move.w	#SndID_SpindashRelease,d0	; spindash zoom sound
	jsr	(PlaySound).l
	bra.s	loc_1C828
; ===========================================================================
; word_1C7CE:
Tails_SpindashSpeeds:
	dc.w  $800	; 0
	dc.w  $880	; 1
	dc.w  $900	; 2
	dc.w  $980	; 3
	dc.w  $A00	; 4
	dc.w  $A80	; 5
	dc.w  $B00	; 6
	dc.w  $B80	; 7
	dc.w  $C00	; 8
word_15320:	dc.w $A00
		dc.w $A80
		dc.w $B00
		dc.w $B80
		dc.w $C00
		dc.w $C80
		dc.w $D00
		dc.w $D80
		dc.w $E00
; ===========================================================================
; loc_1C7E0:
Tails_ChargingSpindash:			; If still charging the dash...
	tst.w	spindash_counter(a0)
	beq.s	loc_1C7F8
	move.w	spindash_counter(a0),d0
	lsr.w	#5,d0
	sub.w	d0,spindash_counter(a0)
	bcc.s	loc_1C7F8
	move.w	#0,spindash_counter(a0)

loc_1C7F8:
	move.b	(Ctrl_2_Press_Logical).w,d0
	andi.b	#button_B_mask|button_C_mask|button_A_mask,d0
	beq.w	loc_1C828
	move.w	#$900,anim(a0)
	move.w	#SndID_SpindashRev,d0
	jsr	(PlaySound).l
	addi.w	#$200,spindash_counter(a0)
	cmpi.w	#$800,spindash_counter(a0)
	blo.s	loc_1C828
	move.w	#$800,spindash_counter(a0)

loc_1C828:
	addq.l	#4,sp
	cmpi.w	#$60,(Camera_Y_pos_bias_P2).w
	beq.s	loc_1C83C
	bhs.s	+
	addq.w	#4,(Camera_Y_pos_bias_P2).w
+	subq.w	#2,(Camera_Y_pos_bias_P2).w

loc_1C83C:
	bsr.w	Tails_LevelBound
	bsr.w	AnglePos
	rts
; End of subroutine Tails_UpdateSpindash


; ---------------------------------------------------------------------------
; Subroutine to slow Tails walking up a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C846:
Tails_SlopeResist:
	move.b	angle(a0),d0
	addi.b	#$60,d0
	cmpi.b	#$C0,d0
	bhs.s	return_1C87A
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	#$20,d0
	asr.l	#8,d0
	tst.w	inertia(a0)
	beq.s	return_1C87A
	bmi.s	loc_1C876
	tst.w	d0
	beq.s	+
	add.w	d0,inertia(a0)	; change Tails' $14
+
	rts
; ---------------------------------------------------------------------------

loc_1C876:
	add.w	d0,inertia(a0)

return_1C87A:
	rts
; End of subroutine Tails_SlopeResist

; ---------------------------------------------------------------------------
; Subroutine to push Tails down a slope while he's rolling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C87C:
Tails_RollRepel:
	move.b	angle(a0),d0
	addi.b	#$60,d0
	cmpi.b	#-$40,d0
	bhs.s	return_1C8B6
	move.b	angle(a0),d0
	jsr	(CalcSine).l
	muls.w	#$50,d0
	asr.l	#8,d0
	tst.w	inertia(a0)
	bmi.s	loc_1C8AC
	tst.w	d0
	bpl.s	loc_1C8A6
	asr.l	#2,d0

loc_1C8A6:
	add.w	d0,inertia(a0)
	rts
; ===========================================================================

loc_1C8AC:
	tst.w	d0
	bmi.s	loc_1C8B2
	asr.l	#2,d0

loc_1C8B2:
	add.w	d0,inertia(a0)

return_1C8B6:
	rts
; End of function Tails_RollRepel

; ---------------------------------------------------------------------------
; Subroutine to push Tails down a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C8B8:
Tails_SlopeRepel:
	nop
	btst	#s3b_stick_convex,status3(a0)
	bne.s	return_1C8F2
	tst.w	move_lock(a0)
	bne.s	loc_1C8F4
	move.b	angle(a0),d0
	addi.b	#$20,d0
	andi.b	#$C0,d0
	beq.s	return_1C8F2
	move.w	inertia(a0),d0
	bpl.s	loc_1C8DC
	neg.w	d0

loc_1C8DC:
	cmpi.w	#$280,d0
	bhs.s	return_1C8F2
	clr.w	inertia(a0)
	bset	#1,status(a0)
	move.w	#$1E,move_lock(a0)

return_1C8F2:
	rts
; ===========================================================================

loc_1C8F4:
	subq.w	#1,move_lock(a0)
	rts
; End of function Tails_SlopeRepel

; ---------------------------------------------------------------------------
; Subroutine to return Tails' angle to 0 as he jumps
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C8FA:
Tails_JumpAngle:
	move.b	angle(a0),d0	; get Tails' angle
	beq.s	Tails_JumpFlip	; if already 0, branch
	bpl.s	loc_1C90A	; if higher than 0, branch

	addq.b	#2,d0		; increase angle
	bcc.s	BranchTo_Tails_JumpAngleSet
	moveq	#0,d0

BranchTo_Tails_JumpAngleSet
	bra.s	Tails_JumpAngleSet
; ===========================================================================

loc_1C90A:
	subq.b	#2,d0		; decrease angle
	bcc.s	Tails_JumpAngleSet
	moveq	#0,d0

; loc_1C910:
Tails_JumpAngleSet:
	move.b	d0,angle(a0)
; End of function Tails_JumpAngle
	; continue straight to Tails_JumpFlip

; ---------------------------------------------------------------------------
; Updates Tails' secondary angle if he's tumbling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C914:
Tails_JumpFlip:
	move.b	flip_angle(a0),d0
	beq.s	return_1C958
	tst.w	inertia(a0)
	bmi.s	Tails_JumpLeftFlip
; loc_1C920:
Tails_JumpRightFlip:
	move.b	flip_speed(a0),d1
	add.b	d1,d0
	bcc.s	BranchTo_Tails_JumpFlipSet
	subq.b	#1,flips_remaining(a0)
	bcc.s	BranchTo_Tails_JumpFlipSet
	move.b	#0,flips_remaining(a0)
	moveq	#0,d0

BranchTo_Tails_JumpFlipSet
	bra.s	Tails_JumpFlipSet
; ===========================================================================
; loc_1C938:
Tails_JumpLeftFlip:
	btst	#s3b_flip_turned,status3(a0)
	bne.s	Tails_JumpRightFlip
	move.b	flip_speed(a0),d1
	sub.b	d1,d0
	bcc.s	Tails_JumpFlipSet
	subq.b	#1,flips_remaining(a0)
	bcc.s	Tails_JumpFlipSet
	move.b	#0,flips_remaining(a0)
	moveq	#0,d0
; loc_1C954:
Tails_JumpFlipSet:
	move.b	d0,flip_angle(a0)

return_1C958:
	rts
; End of function Tails_JumpFlip

; ---------------------------------------------------------------------------
; Subroutine for Tails to interact with the floor and walls when he's in the air
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1C95A: Tails_Floor:
Tails_DoLevelCollision:
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
	beq.w	Tails_HitLeftWall
	cmpi.b	#$80,d0
	beq.w	Tails_HitCeilingAndWalls
	cmpi.b	#-$40,d0
	beq.w	Tails_HitRightWall
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Tails since he hit a wall
+
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Tails since he hit a wall
+
	bsr.w	Sonic_CheckFloor
	tst.w	d1
	bpl.s	return_1CA3A
	move.b	y_vel(a0),d2
	addq.b	#8,d2
	neg.b	d2
	cmp.b	d2,d1
	bge.s	+
	cmp.b	d2,d0
	blt.s	return_1CA3A
+
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	Tails_ResetOnFloor
	move.b	d3,d0
	addi.b	#$20,d0
	andi.b	#$40,d0
	bne.s	loc_1CA18
	move.b	d3,d0
	addi.b	#$10,d0
	andi.b	#$20,d0
	beq.s	loc_1CA0A
	asr	y_vel(a0)
	bra.s	loc_1CA2C
; ===========================================================================

loc_1CA0A:
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)
	rts
; ===========================================================================

loc_1CA18:
	move.w	#0,x_vel(a0)	; stop Tails since he hit a wall
	cmpi.w	#$FC0,y_vel(a0)
	ble.s	loc_1CA2C
	move.w	#$FC0,y_vel(a0)

loc_1CA2C:
	move.w	y_vel(a0),inertia(a0)
	tst.b	d3
	bpl.s	return_1CA3A
	neg.w	inertia(a0)

return_1CA3A:
	rts
; ===========================================================================
; loc_1CA3C:
Tails_HitLeftWall:
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	Tails_HitCeiling ; branch if distance is positive (not inside wall)
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Tails since he hit a wall
	move.w	y_vel(a0),inertia(a0)
	rts
; ===========================================================================
; loc_1CA56:
Tails_HitCeiling:
	bsr.w	CheckCeilingDist
	tst.w	d1
	bpl.s	Tails_HitFloor	; branch if distance is positive (not inside ceiling)
	sub.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	return_1CA6E
	move.w	#0,y_vel(a0)	; stop Tails in y since he hit a ceiling

return_1CA6E:
	rts
; ===========================================================================
; loc_1CA70:
Tails_HitFloor:
	tst.w	y_vel(a0)
	bmi.s	return_1CA96
	bsr.w	Sonic_CheckFloor
	tst.w	d1
	bpl.s	return_1CA96
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	Tails_ResetOnFloor
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)

return_1CA96:
	rts
; ===========================================================================
; loc_1CA98:
Tails_HitCeilingAndWalls:
	bsr.w	CheckLeftWallDist
	tst.w	d1
	bpl.s	+
	sub.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Tails since he hit a wall
+
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	+
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Tails since he hit a wall
+
	bsr.w	CheckCeilingDist
	tst.w	d1
	bpl.s	return_1CAF2
	sub.w	d1,y_pos(a0)
	move.b	d3,d0
	addi.b	#$20,d0
	andi.b	#$40,d0
	bne.s	loc_1CADC
	move.w	#0,y_vel(a0)	; stop Tails in y since he hit a ceiling
	rts
; ===========================================================================

loc_1CADC:
	move.b	d3,angle(a0)
	bsr.w	Tails_ResetOnFloor
	move.w	y_vel(a0),inertia(a0)
	tst.b	d3
	bpl.s	return_1CAF2
	neg.w	inertia(a0)

return_1CAF2:
	rts
; ===========================================================================
; loc_1CAF4:
Tails_HitRightWall:
	bsr.w	CheckRightWallDist
	tst.w	d1
	bpl.s	Tails_HitCeiling2
	add.w	d1,x_pos(a0)
	move.w	#0,x_vel(a0)	; stop Tails since he hit a wall
	move.w	y_vel(a0),inertia(a0)
	rts
; ===========================================================================
; identical to Tails_HitCeiling...
; loc_1CB0E:
Tails_HitCeiling2:
	bsr.w	CheckCeilingDist
	tst.w	d1
	bpl.s	Tails_HitFloor2
	sub.w	d1,y_pos(a0)
	tst.w	y_vel(a0)
	bpl.s	return_1CB26
	move.w	#0,y_vel(a0)	; stop Tails in y since he hit a ceiling

return_1CB26:
	rts
; ===========================================================================
; identical to Tails_HitFloor...
; loc_1CB28:
Tails_HitFloor2:
	tst.w	y_vel(a0)
	bmi.s	return_1CB4E
	bsr.w	Sonic_CheckFloor
	tst.w	d1
	bpl.s	return_1CB4E
	add.w	d1,y_pos(a0)
	move.b	d3,angle(a0)
	bsr.w	Tails_ResetOnFloor
	move.w	#0,y_vel(a0)
	move.w	x_vel(a0),inertia(a0)

return_1CB4E:
	rts
; End of function Tails_DoLevelCollision



; ---------------------------------------------------------------------------
; Subroutine to reset Tails' mode when he lands on the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1CB50:
Tails_ResetOnFloor:
	btst	#s3b_spindash,status3(a0)
	bne.s	Tails_ResetOnFloor_Part3
	move.b	#0,anim(a0)
; loc_1B0AC:
Tails_ResetOnFloor_Part2:
	btst	#2,status(a0)
	beq.s	Tails_ResetOnFloor_Part3
	bclr	#2,status(a0)
;	move.b	#$13,y_radius(a0) ; increases Shadow's collision height to standing
	move.b	#18,width_pixels(a0)
	move.b	#0,$21(a0)	; Clear Double Jump Flag
	move.b	#0,anim(a0)	; use running/walking/standing animation
;	subq.w	#5,y_pos(a0)	; move Tails up 5 pixels so the increased height doesn't push him into the ground
; loc_1B0DA:
Tails_ResetOnFloor_Part3:
	bclr	#1,status(a0)
	bclr	#5,status(a0)
	bclr	#4,status(a0)
	bclr	#s3b_jumping,status3(a0)
	move.w	#0,(Chain_Bonus_counter).w
	move.b	#0,flip_angle(a0)
	bclr	#s3b_flip_turned,status3(a0)
	move.b	#0,flips_remaining(a0)
	move.w	#0,(Tails_Look_delay_counter).w
	cmpi.b	#$14,anim(a0)
	bne.s	+
	move.b	#0,anim(a0)
+
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Tails when he gets hurt
; ---------------------------------------------------------------------------
; loc_1CBC6:
Tails_Hurt:
	tst.w	(Player_Option).w
	beq.s	+
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	move.w	(Camera_Min_X_pos).w,(Tails_Min_X_pos).w
	move.w	(Camera_Max_X_pos).w,(Tails_Max_X_pos).w
	move.w	(Camera_Max_Y_pos_now).w,(Tails_Max_Y_pos).w
+
	tst.w	(Debug_mode_flag).w
	beq.s	+
	btst	#button_B,(Ctrl_1_Press).w	; is button B pressed?
	beq.s	+			; if not, branch
	move.w	#1,(Debug_placement_mode).w	; change Sonic into a ring/item
	clr.b	(Control_Locked).w
	rts
+
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
	bsr.w	Tails_HurtStop
	bsr.w	Tails_LevelBound
	bsr.w	Tails_RecordPos
	bsr.w	Tails_Animate
	bsr.w	LoadTailsDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================
; loc_1CC08:
Tails_HurtStop:
	move.w	(Tails_Max_Y_pos).w,d0
	addi.w	#$E0,d0
	cmp.w	y_pos(a0),d0
	blt.w	JmpTo2_KillCharacter
	bsr.w	Tails_DoLevelCollision
	btst	#1,status(a0)
	bne.s	return_1CC4E
	moveq	#0,d0
	move.w	d0,y_vel(a0)
	move.w	d0,x_vel(a0)
	move.w	d0,inertia(a0)
	andi.b	#lock_del,status3(a0)
	move.b	#0,anim(a0)
	move.w	#objroutine(Tails_Control),(a0)	; => Tails_Control
	move.w	#$78,invulnerable_time(a0)
	bclr	#s3b_spindash,status3(a0)

return_1CC4E:
	rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Tails when he dies
; .
; ---------------------------------------------------------------------------

; loc_1CC50:
Tails_Dead:
	tst.w	(Player_Option).w
	beq.s	+
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	move.w	(Camera_Min_X_pos).w,(Tails_Min_X_pos).w
	move.w	(Camera_Max_X_pos).w,(Tails_Max_X_pos).w
	move.w	(Camera_Max_Y_pos_now).w,(Tails_Max_Y_pos).w
+
	tst.w	(Debug_mode_flag).w
	beq.s	+
	btst	#button_B,(Ctrl_1_Press).w	; is button B pressed?
	beq.s	+			; if not, branch
	move.w	#1,(Debug_placement_mode).w	; change Sonic into a ring/item
	clr.b	(Control_Locked).w
	rts
+
	bsr.w	Tails_CheckGameOver
	jsr	(ObjectMoveAndFall).l
	bsr.w	Tails_RecordPos
	bsr.w	Tails_Animate
	bsr.w	LoadTailsDynPLC
	jmp	(DisplaySprite).l

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1CC6C:
Tails_CheckGameOver:
	cmpi.w	#2,(Player_mode).w	; is it a Tails Alone game?
	beq.w	CheckGameOver		; if yes, branch... goodness, code reuse
	move.b	#1,(Scroll_lock_P2).w
	bclr	#s3b_spindash,status3(a0)
	move.w	(Tails_Max_Y_pos).w,d0
	addi.w	#$100,d0
	cmp.w	y_pos(a0),d0
	bge.w	return_1CD8E
	move.w	#objroutine(Tails_Control),(a0)
	tst.w	(Two_player_mode).w
	bne.s	Tails_CheckGameOver_2Pmode
	bra.w	TailsCPU_Despawn
; ---------------------------------------------------------------------------
; loc_1CCA2:
Tails_CheckGameOver_2Pmode:
	addq.b	#1,(Update_HUD_lives_2P).w
	subq.b	#1,(Life_count_2P).w
	bne.s	Tails_ResetLevel
	move.w	#0,spindash_counter(a0)
	;move.w	#objroutine(Obj39),(GameOver_GameText+id).w ; load Obj39
	;move.w	#objroutine(Obj39),(GameOver_OverText+id).w ; load Obj39
	;move.b	#1,(GameOver_OverText+mapping_frame).w
	;move.w	a0,(GameOver_GameText+parent).w
	clr.b	(Time_Over_flag_2P).w
; loc_1CCCC:
Tails_Finished:
	clr.b	(Update_HUD_timer).w
	clr.b	(Update_HUD_timer_2P).w
	move.w	#objroutine(Tails_Gone),(a0)
	move.w	#MusID_GameOver,d0
	jsr	(PlayMusic).l
	moveq	#PLCID_GameOver,d0
	jmp	(LoadPLC).l
; End of function Tails_CheckGameOver

; ===========================================================================
; ---------------------------------------------------------------------------
; Tails when the level is restarted
; ---------------------------------------------------------------------------
; loc_1CCEC:
Tails_ResetLevel:
	tst.b	(Time_Over_flag).w
	beq.s	Tails_ResetLevel_Part2
	tst.b	(Time_Over_flag_2P).w
	beq.s	Tails_ResetLevel_Part3
	move.w	#0,spindash_counter(a0)
	clr.b	(Update_HUD_timer).w
	clr.b	(Update_HUD_timer_2P).w
	move.w	#objroutine(Tails_Gone),(a0)
	rts
; ---------------------------------------------------------------------------
Tails_ResetLevel_Part2:
	tst.b	(Time_Over_flag_2P).w
	beq.s	Tails_ResetLevel_Part3
	move.w	#0,spindash_counter(a0)
	;move.w	#objroutine(Obj39),(TimeOver_TimeText+id).w ; load Obj39
	;move.w	#objroutine(Obj39),(TimeOver_OverText+id).w ; load Obj39
	;move.b	#2,(TimeOver_TimeText+mapping_frame).w
	;move.b	#3,(TimeOver_OverText+mapping_frame).w
	move.w	a0,(TimeOver_TimeText+parent).w
	bra.s	Tails_Finished
; ---------------------------------------------------------------------------
Tails_ResetLevel_Part3:
	move.b	#0,(Scroll_lock_P2).w
	move.w	#objroutine(Tails_Respawning),(a0)	; => Tails_Respawning
	move.w	(Saved_x_pos_2P).w,x_pos(a0)
	move.w	(Saved_y_pos_2P).w,y_pos(a0)
	move.w	(Saved_art_tile_2P).w,art_tile(a0)
	move.w	(Saved_layer_2P).w,layer(a0)
	clr.w	(Ring_count_2P).w
	clr.b	(Extra_life_flags_2P).w
	andi.b	#lock_del,status3(a0)
	move.b	#5,anim(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,y_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#2,status(a0)
	move.w	#0,move_lock(a0)

return_1CD8E:
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Tails when he's offscreen and waiting for the level to restart
; ---------------------------------------------------------------------------
; loc_1CD90:
Tails_Gone:
	tst.w	(Player_Option).w
	beq.s	+
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	move.w	(Camera_Min_X_pos).w,(Tails_Min_X_pos).w
	move.w	(Camera_Max_X_pos).w,(Tails_Max_X_pos).w
	move.w	(Camera_Max_Y_pos_now).w,(Tails_Max_Y_pos).w
+
	tst.w	spindash_counter(a0)
	beq.s	+
	subq.w	#1,spindash_counter(a0)
	bne.s	+
	move.w	#1,(Level_Inactive_flag).w
+
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Tails when he's waiting for the camera to scroll back to where he respawned
; ---------------------------------------------------------------------------
; loc_1CDA4:
Tails_Respawning:
	tst.w	(Player_Option).w
	beq.s	+
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	cmpi.w	#2,(Player_mode).w
	bne.s	+
	move.w	(Camera_Min_X_pos).w,(Tails_Min_X_pos).w
	move.w	(Camera_Max_X_pos).w,(Tails_Max_X_pos).w
	move.w	(Camera_Max_Y_pos_now).w,(Tails_Max_Y_pos).w
+
	tst.w	(Camera_X_pos_diff_P2).w
	bne.s	+
	tst.w	(Camera_Y_pos_diff_P2).w
	bne.s	+
	move.w	#objroutine(Tails_Control),(a0)
+
	bsr.w	Tails_Animate
	bsr.w	LoadTailsDynPLC
	jmp	(DisplaySprite).l
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to animate Tails' sprites
; See also: AnimateSprite and Sonic_Animate
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1CDC4:
Tails_Animate:
	lea	(TailsAniData).l,a1
; loc_1CDCA:
Tails_Animate_Part2:
	moveq	#0,d0
	move.b	anim(a0),d0
	cmp.b	next_anim(a0),d0	; has animation changed?
	beq.s	TAnim_Do		; if not, branch
	move.b	d0,next_anim(a0)	; set to next animation
	move.b	#0,anim_frame(a0)	; reset animation frame
	move.b	#0,anim_frame_duration(a0)	; reset frame duration
	bclr	#5,status(a0)
; loc_1CDEC:
TAnim_Do:
	add.w	d0,d0
	adda.w	(a1,d0.w),a1	; calculate address of appropriate animation script
	move.b	(a1),d0
	bmi.s	TAnim_WalkRunZoom	; if animation is walk/run/roll/jump, branch
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from frame duration
	bpl.s	TAnim_Delay			; if time remains, branch
	move.b	d0,anim_frame_duration(a0)	; load frame duration
; loc_1CE12:
TAnim_Do2:
	moveq	#0,d1
	move.b	anim_frame(a0),d1	; load current frame number
	move.b	1(a1,d1.w),d0		; read sprite number from script
	cmpi.b	#$F0,d0
	bhs.s	TAnim_End_FF		; if animation is complete, branch
; loc_1CE22:
TAnim_Next:
	move.b	d0,mapping_frame(a0)
	addq.b	#1,anim_frame(a0)
; return_1CE2A:
TAnim_Delay:
	rts
; ===========================================================================
; loc_1CE2C:
TAnim_End_FF:
	addq.b	#1,d0			; is the end flag = $FF ?
	bne.s	TAnim_End_FE		; if not, branch
	move.b	#0,anim_frame(a0)	; restart the animation
	move.b	1(a1),d0        	; read sprite number
	bra.s	TAnim_Next
; ===========================================================================
; loc_1CE3C:
TAnim_End_FE:
	addq.b	#1,d0			; is the end flag = $FE ?
	bne.s	TAnim_End_FD		; if not, branch
	move.b	2(a1,d1.w),d0		; read the next byte in the script
	sub.b	d0,anim_frame(a0)	; jump back d0 bytes in the script
	sub.b	d0,d1
	move.b	1(a1,d1.w),d0		; read sprite number
	bra.s	TAnim_Next
; ===========================================================================
; loc_1CE50:
TAnim_End_FD:
	addq.b	#1,d0			; is the end flag = $FD ?
	bne.s	TAnim_End		; if not, branch
	move.b	2(a1,d1.w),anim(a0)	; read next byte, run that animation
; return_1CE5A:
TAnim_End:
	rts
; ===========================================================================
; loc_1CE5C:
TAnim_WalkRunZoom: ; a0=character
	; note: for some reason SAnim_WalkRun doesn't need to do this here...
	subq.b	#1,anim_frame_duration(a0)	; subtract 1 from Tails' frame duration
	bpl.s	TAnim_Delay			; if time remains, branch

	addq.b	#1,d0		; is the end flag = $FF ?
	bne.w	TAnim_Roll	; if not, branch
	moveq	#0,d0		; is animation walking/running?
	move.b	flip_angle(a0),d0	; if not, branch
	bne.w	loc_1CF08
	moveq	#0,d1
	move.b	angle(a0),d0	; get Tails' angle
	bmi.s	+
	beq.s	+
	subq.b	#1,d0
+
	move.b	status(a0),d2
	andi.b	#1,d2		; is Tails mirrored horizontally?
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
	bne.w	loc_1CFB2
	lsr.b	#4,d0		; divide angle by 16
	andi.b	#6,d0		; make it 0, 2, 4 or 6
	mvabs.w	inertia(a0),d2	; get Tails' "speed" for animation purposes
	tst.b	status2(a0)
	bpl.w	+
	add.w	d2,d2
+
	move.b	d0,d3
	add.b	d3,d3
	add.b	d3,d3
	lea	(TailsAni_Walk).l,a1

	cmpi.w	#$600,d2		; is Tails going pretty fast?
	blo.s	TAnim_SpeedSelected	; if not, branch
	lea	(TailsAni_Run).l,a1
	move.b	d0,d1
	lsr.b	#1,d1
	add.b	d1,d0
	add.b	d0,d0
	move.b	d0,d3

	cmpi.w	#$700,d2		; is Tails going really fast?
	blo.s	TAnim_SpeedSelected	; if not, branch
	lea	(TailsAni_HaulAss).l,a1

; loc_1CEEE:
TAnim_SpeedSelected:
	neg.w	d2
	addi.w	#$800,d2
	bpl.s	+
	moveq	#0,d2
+
	lsr.w	#8,d2
	move.b	d2,anim_frame_duration(a0)
	bsr.w	TAnim_Do2
	add.b	d3,mapping_frame(a0)
	rts
; ===========================================================================

loc_1CF08:
	move.b	flip_angle(a0),d0
	moveq	#0,d1
	move.b	status(a0),d2
	andi.b	#1,d2
	bne.s	loc_1CF36
	andi.b	#$FC,render_flags(a0)
	addi.b	#$B,d0
	divu.w	#$16,d0
	addi.b	#$75,d0
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts
; ===========================================================================

loc_1CF36:
	andi.b	#$FC,render_flags(a0)
	btst	#s3b_flip_turned,status3(a0)
	beq.s	loc_1CF4E
	ori.b	#1,render_flags(a0)
	addi.b	#$B,d0
	bra.s	loc_1CF5A
; ===========================================================================

loc_1CF4E:
	ori.b	#3,render_flags(a0)
	neg.b	d0
	addi.b	#-$71,d0

loc_1CF5A:
	divu.w	#$16,d0
	addi.b	#$75,d0
	move.b	d0,mapping_frame(a0)
	move.b	#0,anim_frame_duration(a0)
	rts

; ===========================================================================
; loc_1CF6E:
TAnim_Roll:
	addq.b	#1,d0		; is the end flag = $FE ?
	bne.s	TAnim_Push	; if not, branch
	mvabs.w	inertia(a0),d2
	lea	(TailsAni_Roll2).l,a1
	cmpi.w	#$600,d2
	bhs.s	+
	lea	(TailsAni_Roll).l,a1
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
	bra.w	TAnim_Do2
; ===========================================================================

loc_1CFB2:
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
	lea	(TailsAni_Push).l,a1
	move.b	status(a0),d1
	andi.b	#1,d1
	andi.b	#$FC,render_flags(a0)
	or.b	d1,render_flags(a0)
	bra.w	TAnim_Do2

; ===========================================================================
; loc_1CFE4:
TAnim_Push:
	move.w	x_vel(a2),d1
	move.w	y_vel(a2),d2
	jsr	(CalcAngle).l
	moveq	#0,d1
	move.b	status(a0),d2
	andi.b	#1,d2
	bne.s	loc_1D002
	not.b	d0
	bra.s	loc_1D006
; ===========================================================================

loc_1D002:
	addi.b	#$80,d0

loc_1D006:
	addi.b	#$10,d0
	bpl.s	+
	moveq	#3,d1
+
	andi.b	#$FC,render_flags(a0)
	eor.b	d1,d2
	or.b	d2,render_flags(a0)
	lsr.b	#3,d0
	andi.b	#$C,d0
	move.b	d0,d3
	;lea	(Tails_TailsAni_Directional).l,a1
	move.b	#3,anim_frame_duration(a0)
	bsr.w	TAnim_Do2
	add.b	d3,mapping_frame(a0)
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Tails' Tails pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1D184:
LoadTailsTailsDynPLC:
	moveq	#0,d0
	move.b	mapping_frame(a0),d0
	cmp.b	($FFFFF7DF).w,d0
	beq.s	return_1D1FE
	move.b	d0,($FFFFF7DF).w
	lea	(MapRUnc_Tails).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	return_1D1FE
	move.w	#-$A00,d4
	bra.s	TPLC_ReadEntry

; ---------------------------------------------------------------------------
; Tails pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_1D1AC:
LoadTailsDynPLC:
	moveq	#0,d0
	move.b	mapping_frame(a0),d0	; load frame number
; loc_1D1B2:
LoadTailsDynPLC_Part2:
	cmp.b	($FFFFF7DE).w,d0
	beq.s	return_1D1FE
	move.b	d0,($FFFFF7DE).w
	lea	(MapRUnc_Tails).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	return_1D1FE
	move.w	#-$C00,d4
; loc_1D1D2:
TPLC_ReadEntry:
	moveq	#0,d1
	move.w	(a2)+,d1
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	addi.l	#ArtUnc_Tails,d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,TPLC_ReadEntry	; repeat for number of entries

return_1D1FE:
	rts

; ===========================================================================
; ----------------------------------------------------------------------------
; Tails' tails
; ----------------------------------------------------------------------------
Tails_Tails_Init:
	move.w	#objroutine(Tails_Tails_Main),(a0)
	move.l	#MapUnc_Tails,mappings(a0)
	move.w	#$7B0,art_tile(a0)
	move.w	#$100,priority(a0)
	move.b	#$18,width_pixels(a0)
	move.b	#4,render_flags(a0)

; loc_1D23A:
Tails_Tails_Main:
	movea.w	parent(a0),a2 ; a2=character
	move.b	angle(a2),angle(a0)
	move.b	status(a2),status(a0)
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	+
	ori.w	#$8000,art_tile(a0)
+
	moveq	#0,d0
	move.b	anim(a2),d0
	btst	#5,status(a2)
	beq.s	+
	moveq	#4,d0
+
	cmp.b	objoff_30(a0),d0
	beq.s	loc_1D288
	move.b	d0,objoff_30(a0)
	move.b	Tails_TailsAniSelection(pc,d0.w),anim(a0)

loc_1D288:
	lea	(Tails_TailsAniData).l,a1
	bsr.w	Tails_Animate_Part2
	bsr.w	LoadTailsTailsDynPLC
	jsr	DisplaySprite
	rts
; ===========================================================================
; animation master script table for the tails
; chooses which animation script to run depending on what Tails is doing
; byte_1D29E:
Tails_TailsAniSelection:
	dc.b	0,0	; TailsAni_Walk,Run	->
	dc.b	3	; TailsAni_Roll		-> Directional
	dc.b	3	; TailsAni_Roll2	-> Directional
	dc.b	9	; TailsAni_Push		-> Pushing
	dc.b	1	; TailsAni_Wait		-> Swish
	dc.b	0	; TailsAni_Balance	-> Blank
	dc.b	2	; TailsAni_LookUp	-> Flick
	dc.b	1	; TailsAni_Duck		-> Swish
	dc.b	7	; TailsAni_Spindash	-> Spindash
	dc.b	0,0,0	; TailsAni_Dummy1,2,3	->
	dc.b	8	; TailsAni_Stop		-> Skidding
	dc.b	0,0	; TailsAni_Float,2	->
	dc.b	0	; TailsAni_Spring	->
	dc.b	0	; TailsAni_Hang		->
	dc.b	0,0	; TailsAni_Blink,2	->
	dc.b	$A	; TailsAni_Hang2	-> Hanging
	dc.b	0	; TailsAni_Bubble	->
	dc.b	0,0,0,0	; TailsAni_Death,2,3,4	->
	dc.b	0,0	; TailsAni_Hurt,Slide	->
	dc.b	0	; TailsAni_Blank	->
	dc.b	0,0	; TailsAni_Dummy4,5	->
	dc.b	0	; TailsAni_HaulAss	->
	dc.b	0	; TailsAni_Fly		->
	even

; ---------------------------------------------------------------------------
; Animation script - Tails' tails
; ---------------------------------------------------------------------------
; off_1D2C0:
Tails_TailsAniData:
	dc.w Tails_TailsAni_Blank - Tails_TailsAniData	; 0
	dc.w Tails_TailsAni_Swish - Tails_TailsAniData	; 1
	dc.w Tails_TailsAni_Flick - Tails_TailsAniData	; 2
	dc.w Tails_TailsAni_Directional - Tails_TailsAniData; 3
	dc.w Tails_TailsAni_DownLeft - Tails_TailsAniData	; 4
	dc.w Tails_TailsAni_Down - Tails_TailsAniData	; 5
	dc.w Tails_TailsAni_DownRight - Tails_TailsAniData	; 6
	dc.w Tails_TailsAni_Spindash - Tails_TailsAniData	; 7
	dc.w Tails_TailsAni_Skidding - Tails_TailsAniData	; 8
	dc.w Tails_TailsAni_Pushing - Tails_TailsAniData	; 9
	dc.w Tails_TailsAni_Hanging - Tails_TailsAniData	;$A
Tails_TailsAni_Blank:		dc.b $20,  0,$FF
Tails_TailsAni_Swish:		dc.b   7,  9, $A, $B, $C, $D,$FF
Tails_TailsAni_Flick:		dc.b   3,  9, $A, $B, $C, $D,$FD,  1
Tails_TailsAni_Directional:	dc.b $FC,$49,$4A,$4B,$4C,$FF ; Tails is moving right
Tails_TailsAni_DownLeft:	dc.b   3,$4D,$4E,$4F,$50,$FF ; Tails is moving up-right
Tails_TailsAni_Down:		dc.b   3,$51,$52,$53,$54,$FF ; Tails is moving up
Tails_TailsAni_DownRight:	dc.b   3,$55,$56,$57,$58,$FF ; Tails is moving up-left
Tails_TailsAni_Spindash:	dc.b   2,$81,$82,$83,$84,$FF
Tails_TailsAni_Skidding:	dc.b   2,$87,$88,$89,$8A,$FF
Tails_TailsAni_Pushing:	dc.b   9,$87,$88,$89,$8A,$FF
Tails_TailsAni_Hanging:	dc.b   9,$81,$82,$83,$84,$FF
	even
