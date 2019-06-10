; ---------------------------------------------------------------------------
; Object touch response subroutine - $20(a0) in the object RAM
; collides Sonic with most objects (enemies, rings, monitors...) in the level
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

TouchResponse:
	moveq	#0,d6
	jsr	(Touch_Rings).l
Touch_Loop:
    moveq   #0,d6 
	lea	(Dynamic_Object_RAM).w,a1
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d6
	move.w	x_pos(a0),d0
	move.w	y_pos(a0),d1
	move.b	width_pixels(a0),d4
	move.b	height_pixels(a0),d5	
	ext.w	d4
	ext.w	d5
OCCNextObj:        
	lea     	$40(a1),a1
    tst.b   	collision_response(a1)
    bne.s   	OCCWidthCheck	
    dbf	d6,OCCNextObj
OCCEndList:
    rts
OCCWidthCheck:
	sub.w	#1,d6
	move.b	width_pixels(a1),d2
	ext.w	d2
	move.w	x_pos(a1),d3	
	sub.w	d0,d3
	bcc.s	OCCWidthCheck2
	lsl.w	#1,d2		
	add.w	d2,d3
	bcs.s	OCCHeightCheck
	bra.w	OCCNextObj
OCCWidthCheck2:
	cmp.w	d4,d3
	bhi.w	OCCNextObj
OCCHeightCheck:
	move.b	height_pixels(a1),d2
	ext.w	d2
	move.w	y_pos(a1),d3
	sub.w	d1,d3
	bcc.s	OCCHeightCheck2
	lsl.w	#1,d2
	add.w	d2,d3
	bcs.s	OCCjmp1
	bra.w	OCCNextObj
OCCHeightCheck2:
	cmp.w	d5,d3
	bhi.w	OCCNextObj
OCCjmp1:
	bset	#7,mappings(a1)
	moveq	#$00,d1
	move.b	collision_response(a1),d1
	ext.w	d1
	add.w	d1,d1
	add.w	d1,d1
	jmp	OCCCheckValue(pc,d1.w)
OCCCheckValue:
	bra.w		Touch_Enemy		; 0
	bra.w		Touch_Enemy		; 1
	bra.w		Touch_Boss		; 2
	bra.w		Touch_ChkHurt	; 3
	bra.w		Touch_Monitor	; 4
	bra.w		Touch_Ring		; 5
	bra.w		Touch_Bubble	; 6
	bra.w		Touch_Projectile	; 7
; ===========================================================================

Touch_Enemy:
	move.b	status2(a0),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	loc_3F7A6			; if so, branch
    cmpi.b	#2,anim(a0)
    bne.w	Touch_ChkHurt

loc_3F7A6:
	neg.w	y_vel(a0)
	move.b	#0,collision_response(a1)

Touch_KillEnemy:
	bset	#7,status(a1)
	moveq	#0,d0
	move.w	(Chain_Bonus_counter).w,d0
	addq.w	#2,(Chain_Bonus_counter).w	; add 2 to chain bonus counter
	cmpi.w	#6,d0
	blo.s	loc_3F802
	moveq	#6,d0

loc_3F802:
	move.w	Enemy_Points(pc,d0.w),d0
	cmpi.w	#$20,(Chain_Bonus_counter).w	; have 16 enemies been destroyed?
	blo.s	loc_3F81C			; if not, branch
	move.w	#1000,d0			; fix bonus to 10000 points

loc_3F81C:
	movea.w	a0,a3
	move.w	#objroutine(Explosion_FromEnemy),(a1)
	tst.w	y_vel(a0)
	bmi.s	loc_3F844
	move.w	y_pos(a0),d0
	cmp.w	y_pos(a1),d0
	bhs.s	loc_3F84C
	neg.w	y_vel(a0)
	rts

loc_3F844:
	addi.w	#$100,y_vel(a0)
	rts

loc_3F84C:
	subi.w	#$100,y_vel(a0)
	rts

; ===========================================================================
Enemy_Points:	dc.w 10, 20, 50, 100
; ===========================================================================

loc_3F85C:
	bset	#7,status(a1)
; ===========================================================================
Touch_Boss:
	rts

; ---------------------------------------------------------------------------
; Subroutine for checking if Sonic/Tails should be hurt and hurting them if so
; note: sonic or tails must be at a0
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Touch_Projectile:
	move.b	status2(a0),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	Touch_NoHurt			; if so, branch
	move.b	status2(a0),d0
	andi.b	#shield_mask,d0		; does the player have a shield?
	beq.w	Touch_ChkHurt	; if not, branch

Reverse_Projectile:
	move.w	x_pos(a0),d0
	cmp.w	x_pos(a1),d0
	bgt.s	Deflect_ProjectileRight

Deflect_ProjectileLeft:
	move.w	#$600,x_vel(a1)
	bra.s	deflectright2

Deflect_ProjectileRight:
	move.w	#-$600,x_vel(a1)

deflectright2:
	move.w	#-$600,y_vel(a1)	; Send the projectile upwards
	rts

Touch_ChkHurt:
	move.b	status2(a0),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	Touch_NoHurt			; if so, branch
	move.b	status2(a0),d0
	andi.b	#shield_mask|(1<<s2b_doublejump),d0
	cmpi.b	#1<<s2b_doublejump,d0			; is Sonic using the instashield?
	beq.s	Touch_NoHurt
	bra.s	Touch_Hurt				; if not, branch

Touch_NoHurt:
	moveq	#-1,d0
	rts

Touch_Hurt:
	tst.w	invulnerable_time(a0)
	bne.s	Touch_NoHurt
	movea.l	a1,a2
	bra.w	HurtCharacter

; End of function TouchResponse
; continue straight to HurtCharacter

; ===========================================================================
Touch_Monitor:
	tst.w	y_vel(a0)		; is Sonic moving upwards?
	bpl.s	Touch_Monitor_ChkBreak	; if not, branch
	move.w	y_pos(a0),d0
	subi.w	#$10,d0
	cmp.w	y_pos(a1),d0
	blo.s	Touch_Monitor_No
	neg.w	y_vel(a0)		; reverse Sonic's y-motion
	move.w	#-$180,y_vel(a1)
	bset	#6,mappings(a1)		; set the monitor's nudge flag
	rts
Touch_Monitor_ChkBreak:
;	cmpa.w	#MainCharacter,a0
;	beq.s	+
	cmpi.b	#2,anim(a0)
	bne.s	Touch_Monitor_No
	neg.w	y_vel(a0)		; reverse Sonic's y-motion
	bset	#7,mappings(a1)	
	move.w	#objroutine(ObjMonitor_Break),(a1)
	move.w	a0,parent(a1)
	rts
Touch_Monitor_No:
	bclr	#7,mappings(a1)		; unset the object's touched flag so the monitor doesn't break
	rts
; ===========================================================================	
Touch_Ring:
	move.w	#objroutine(ObjRing_Collect),(a1)
	rts
; ===========================================================================		
Touch_Bubble:	
	btst	#s3b_lock_motion,status3(a0)
	bne.w	ResumeMusic2_Loc
	cmpi.b	#$C,air_left(a0)		; has countdown started yet?
	bhi.s	ResumeMusic2_Done		; if not, branch
	cmpa.w	#MainCharacter,a0		; is it player 1?
	bne.s	ResumeMusic2_Done		; if not, branch
	move.w	(Level_Music).w,d0		; prepare to play current level's music
	btst	#s2b_2,status2(a0)	; is Sonic invincible?
	beq.s	+				; if not, branch
	move.w	#MusID_Invincible,d0		; prepare to play invincibility music
+	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.w	+				; if not, branch
	move.w	#MusID_SuperSonic,d0		; prepare to play super sonic music
+	tst.b	(Current_Boss_ID).w		; are we in a boss?
	beq.s	+				; if not, branch
	move.w	#MusID_Boss,d0			; prepare to play boss music
+	jsr	(PlayMusic).l

ResumeMusic2_Done:
	move.w	#SndID_InhalingBubble,d0	; play inhale bubble sound
	jsr	(PlaySound).l
	clr.w	x_vel(a0)			; make the player stop moving
	clr.w	y_vel(a0)
	clr.w	inertia(a0)
	move.b	#$15,anim(a0)			; set player to inhaling animation
	move.w	#$23,move_lock(a0)		; lock movement for 23 frames
	bclr	#s3b_jumping,status3(a0)			; unset player's jumping flag
	bclr	#5,status(a0)
	bclr	#4,status(a0)
	bclr	#2,status(a0)			; clear other jumping flag
	beq.b	ResumeMusic2_Loc		; if we weren't jumping anyway, branch
	;bne.b	Bubbles_Base_CheckPlayer_UnrollTails	; if so, branch
	move.b	#$26,height_pixels(a0)
	move.b	#18,width_pixels(a0)
	subq.w	#5,y_pos(a0)	
+	addq.b	#3,anim(a0)
	move.w	#objroutine(Bubbles_Base_BubbleCollected),(a1)
ResumeMusic2_Loc:
	move.b	#$1E,air_left(a0)	; reset air to full	
	rts
; ===========================================================================	
; ---------------------------------------------------------------------------
; Hurting Sonic/Tails subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

HurtCharacter:
	move.w	(Ring_count).w,d1
	cmpa.w	#MainCharacter,a0
	beq.s	loc_3F88C
	tst.w	(Two_player_mode).w
	beq.s	Hurt_Sidekick
	move.w	(Ring_count_2P).w,d1

loc_3F88C:
	move.b	status2(a0),d0
	andi.b	#shield_mask,d0
	beq.b	Hurt_NoShield
	andi.b	#shield_del,status2(a0) ; remove shield
	bsr.w	ChooseShield
	bra.b	Hurt_Sidekick

Hurt_NoShield:
	tst.b	SonicSSFlag
	bne.w	Hurt_SS
	tst.w	d1
	beq.w	KillCharacter
	jsr	SingleObjLoad
	bne.s	Hurt_Sidekick
	move.w	#objroutine(Hurt_Rings),id(a1) ; load obj
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	a0,parent(a1)

Hurt_Sidekick:
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	move.w	Hurt_Character_Options(pc,d0.w),(a0)
	bsr.w	JmpTo_Sonic_ResetOnFloor_Part2
	bset	#1,status(a0)
	move.w	#-$400,y_vel(a0) ; make Sonic bounce away from the object
	move.w	#-$200,x_vel(a0)
	btst	#6,status(a0)	; underwater?
	beq.s	Hurt_Reverse	; if not, branch
	move.w	#-$200,y_vel(a0) ; bounce slower
	move.w	#-$100,x_vel(a0)

Hurt_Reverse:
	move.w	x_pos(a0),d0
	cmp.w	x_pos(a2),d0
	blo.s	Hurt_ChkSpikes	; if Sonic is left of the object, branch
	neg.w	x_vel(a0)	; if Sonic is right of the object, reverse

Hurt_ChkSpikes:
	move.w	#0,inertia(a0)
	move.b	#$1A,anim(a0)
	move.w	#$78,invulnerable_time(a0)
	move.w	#SndID_Hurt,d0	; load normal damage sound
	cmpi.b	#$36,(a2)	; was damage caused by spikes?
	bne.s	Hurt_Sound	; if not, branch
	move.w	#SndID_HurtBySpikes,d0	; load spikes damage sound

Hurt_Sound:
	jsr	(PlaySound).l
	moveq	#-1,d0
	rts
Hurt_Character_Options:
	dc.w	objroutine(Sonic_Hurt)
	dc.w	objroutine(Sonic_Hurt)
	dc.w	objroutine(Tails_Hurt)
	dc.w	objroutine(Knuckles_Hurt)
Hurt_SS:
	sub.w	#1,$3A(a0)
	bne.b	Hurt_Sidekick

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to kill Sonic or Tails
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_3F926: KillSonic:
KillCharacter:
	clr.b 	$21(a0)
	tst.w	(Debug_placement_mode).w
	bne.s	loc_3F972
	clr.b	status2(a0)
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	move.w	Dead_Character_Options(pc,d0.w),(a0)
	bsr.w	JmpTo_Sonic_ResetOnFloor_Part2
	bset	#1,status(a0)
	move.w	#-$700,y_vel(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#$18,anim(a0)
	bset	#7,art_tile(a0)
	move.w	#SndID_Hurt,d0
	cmpi.b	#$36,(a2)
	bne.s	loc_3F96C
	move.w	#SndID_HurtBySpikes,d0

loc_3F96C:
	jsr	(PlaySound).l

loc_3F972:
	moveq	#-1,d0
	rts
	
Dead_Character_Options:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)
; ===========================================================================
JmpTo_Sonic_ResetOnFloor_Part2
	jmp	(Sonic_ResetOnFloor_Part2).l
; ===========================================================================