; ---------------------------------------------------------------------------
; Object touch response subroutine - $20(a0) in the object RAM
; collides Sonic with most objects (enemies, rings, monitors...) in the level
; ---------------------------------------------------------------------------
; a0 - whatever's calling this, most of the time it's the character
; d0 - Main Object X Pos
; d1 - Main Object Y Pos
; d2 - Secondary Object Width/Height
; d3 - Secondary Object X Pos/Y Pos
; d4 - Main Object Width
; d5 - Main Object Height

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

TouchResponse:
	moveq	#0,d6
	jsr		(Touch_Rings).l ; Check ring collision
    moveq   #0,d6 
	lea		(Dynamic_Object_RAM).w,a1 ; Load object address
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d6 ; Get how many objects there are
	move.w	x_pos(a0),d0
	move.w	y_pos(a0),d1
	move.b	width_pixels(a0),d4
	move.b	height_pixels(a0),d5	
	ext.w	d4
	ext.w	d5

TouchResponse__ObjectLoop:        
	lea     $40(a1),a1	; load the next object
    tst.b   collision_response(a1)	; check if it has any collision flags
    bne.s   TouchResponse__WidthCheck	; if it does, branch
    dbf		d6,TouchResponse__ObjectLoop	; if not, repeat the loop and subtract 1 from the amount of objects
    rts

; Checks if the main object 
TouchResponse__WidthCheck:
	sub.w	#1,d6	; Lower the object count by 1
	move.b	width_pixels(a1),d2
	ext.w	d2
	move.w	x_pos(a1),d3

TouchResponse__WidthCheckRight:	
	sub.w	d0,d3	; subtract character's/main item's x position from the x position of the current object
	bhs.s	TouchResponse__WidthCheckLeft ; if the main item's x position is less than or same as the object's x position, branch to check if it's within the width
	;lsl.w	#1,d2	; Doubling the width, I don't think this is needed
	add.w	d2,d3 ; if the width of the object is within the distance of main object, check height
	bcs.s	TouchResponse__HeightCheck
	bra.s	TouchResponse__ObjectLoop ; else skip this object

TouchResponse__WidthCheckLeft:
	cmp.w	d4,d3 ; if main object is as wide as the distance between the two, continue to hight check
	bhi.w	TouchResponse__ObjectLoop ; else skip this object

TouchResponse__HeightCheck:
	move.b	height_pixels(a1),d2
	ext.w	d2
	move.w	y_pos(a1),d3


	sub.w	d1,d3
	bcc.s	OCCHeightCheck2
	lsl.w	#1,d2
	add.w	d2,d3
	bcs.s	OCCjmp1
	bra.w	TouchResponse__ObjectLoop

OCCHeightCheck2:
	cmp.w	d5,d3
	bhi.w	TouchResponse__ObjectLoop

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
