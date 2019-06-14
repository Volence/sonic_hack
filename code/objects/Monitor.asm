; ===========================================================================
; ----------------------------------------------------------------------------
; Object 02 - Monitor
; ----------------------------------------------------------------------------

Monitor:
	lea		Monitor_Data(pc),a2
	jsr		Load_Object2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	beq.s	+
	lea		(Object_Respawn_Table).w,a2
	bclr	#7,2(a2,d0.w)
	btst	#0,2(a2,d0.w)		; if this bit is set it means the monitor is already broken
	beq.s	+
	lea		Monitor_Broken_Data,a2
	jsr		Load_Object4
	bra.w	ObjMonitor_Display
+
	move.b	subtype(a0),anim(a0)	; subtype = icon to display
	tst.w	(Two_player_mode).w	; is it two player mode?
	beq.s	ObjMonitor_Main		; if not, branch
	move.b	#9,anim(a0)		; use '?' icon

ObjMonitor_Main:
	btst	#6,mappings(a0)		; is the monitor nudge flag set?
	beq.s	ObjMonitor_Solid	; if not, branch
	bclr	#7,mappings(a0)		; clear the monitor break flag
	jsr	ObjectMoveAndFall
	jsr	ObjCheckFloorDist
	tst.w	d1			; is monitor in the ground?
	bpl.w	ObjMonitor_Solid	; if not, branch
	add.w	d1,y_pos(a0)		; move monitor out of the ground
	clr.w	y_vel(a0)
	bclr	#6,mappings(a0)		; stop monitor from falling

ObjMonitor_Solid:
	ckhit.w	ObjMonitor_Break
	move.w	#$1A,d1			; monitor's width
	move.w	#$F,d2			; height/2
	move.w	d2,d3
	addq.w	#1,d3
	move.w	x_pos(a0),d4
	lea	(MainCharacter).w,a1	; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.w	ObjMonitor_Solid_Sonic
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1		; a1=character
	moveq	#4,d6
	bsr.w	ObjMonitor_Solid_Tails

ObjMonitor_Display:
	lea	(Ani_Monitor).l,a1
	jsr	AnimateSprite
	jmp	MarkObjGone

ObjMonitor_Solid_Sonic:
	btst	d6,status(a0)		; is Sonic standing on the monitor?
	bne.s	ObjMonitor_ChkOverEdge	; if yes, branch
	cmpi.b	#2,anim(a1)		; is Sonic spinning?
	beq.b	locret_12756		; if so, rMonitors_Brokenturn
	jmp	SolidObject2		; if not, branch

ObjMonitor_Solid_Tails:
	btst	d6,status(a0)		; is Tails standing on the monitor?
	bne.s	ObjMonitor_ChkOverEdge	; if yes, branch
	tst.w	(Two_player_mode).w	; is it two player mode?
	beq.b	+			; if not, branch
	; in one player mode monitors always behave as solid for Tails
	cmpi.b	#2,anim(a1)		; is Tails spinning?
	beq.b	locret_12756		; if so, return
+	jmp	SolidObject2		; if not, branch

locret_12756:
	rts

; ---------------------------------------------------------------------------
; Checks if the player has walked over the edge of the monitor.
; ---------------------------------------------------------------------------

ObjMonitor_ChkOverEdge:
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)	; is the character in the air?
	bne.s	+		; if yes, branch
	; check, if character is standing on
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	+	; branch, if character is behind the left edge of the monitor
	cmp.w	d2,d0
	blo.s	ObjMonitor_CharStandOn	; branch, if character is not beyond the right edge of the monitor
+
	; if the character isn't standing on the monitor
	bclr	#3,status(a1)	; clear 'on object' bit
	bset	#1,status(a1)	; set 'in air' bit
	bclr	d6,status(a0)	; clear 'standing on' bit for the current character
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------

ObjMonitor_CharStandOn:
	move.w	d4,d2
	jsr	MvSonicOnPtfm
	moveq	#0,d4
	rts
; ===========================================================================

ObjMonitor_Break:
	move.b	status(a0),d0
	andi.b	#%01111000,d0				; is someone touching the monitor?
	beq.s	Monitor_SpawnIcon				; if not, branch
	move.b	d0,d1
	andi.b	#%00101000,d1				; is it the main character?
	beq.s	+					; if not, branch
	andi.b	#%11010111,(MainCharacter+status).w
	ori.b	#2,(MainCharacter+status).w		; prevent Sonic from walking in the air
+	andi.b	#%01010000,d0				; is it the sidekick?
	beq.s	Monitor_SpawnIcon				; if not, branch
	andi.b	#%11010111,(Sidekick+status).w
	ori.b	#2,(Sidekick+status).w			; prevent Tails from walking in the air

Monitor_SpawnIcon:
	clr.b	status(a0)
	move.w	#objroutine(ObjMonitor_Display),(a0)
	move.b	#0,collision_response(a0)
	jsr	SingleObjLoad
	bne.s	Monitor_SpawnSmoke
	move.w	#objroutine(ObjMonitor_Icon),id(a1)	; load ObjMonitor_Icon
	move.w	x_pos(a0),x_pos(a1)			; set icon's position
	move.w	y_pos(a0),y_pos(a1)
	move.b	anim(a0),anim(a1)
	move.w	parent(a0),parent(a1)			; parent gets the item

Monitor_SpawnSmoke:
	jsr	SingleObjLoad
	bne.s	+
	move.w	#objroutine(Explosion_Alone),(a1)		; load explosion object alone
	move.w	x_pos(a0),x_pos(a1)			; copy position
	move.w	y_pos(a0),y_pos(a1)
+	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d0
	move.b	respawn_index(a0),d0
	bset	#0,2(a2,d0.w)				; mark monitor as destroyed
	move.b	#1,anim(a0)				; switch to broken frame
	jmp	DisplaySprite

ObjMonitor_Icon:
	move.w	#objroutine(ObjMonitor_Icon_Raise),(a0)
	move.w	#$8680,art_tile(a0)
	move.b	#$24,render_flags(a0)
	move.w	#$180,priority(a0)
	move.b	#8,width_pixels(a0)
	move.w	#-$300,y_vel(a0)
	moveq	#0,d0
	move.b	anim(a0),d0

	tst.w	(Two_player_mode).w	; is it two player mode?
	beq.s	loc_128C6		; if not, branch
	; give 'random' item in two player mode
	move.w	(Timer_frames).w,d0	; use the timer to determine which item
	andi.w	#7,d0	; and 7 means there are 8 different items
	addq.w	#1,d0	; add 1 to prevent getting the static monitor
	tst.w	(Two_player_items).w	; are monitors set to 'teleport only'?
	beq.s	+			; if not, branch
	moveq	#8,d0			; force contents to be teleport
+	; keep teleport monitor from causing unwanted effects
	cmpi.w	#8,d0	; teleport?
	bne.s	+	; if not, branch
	move.b	(Update_HUD_timer).w,d1
	add.b	(Update_HUD_timer_2P).w,d1
	cmpi.b	#2,d1	; is either player done with the act?
	beq.s	+	; if not, branch
	moveq	#7,d0	; give invincibility, instead
+
	move.b	d0,anim(a0)

loc_128C6:			; Determine correct mappings offset.
	;addq.b	#1,d0
	move.b	d0,mapping_frame(a0)
	movea.l	#Monitor_MapUnc_12D36,a1
	add.b	d0,d0
	adda.w	(a1,d0.w),a1
	addq.w	#2,a1
	move.l	a1,mappings(a0)

ObjMonitor_Icon_Raise:
	tst.w	y_vel(a0)	; is icon still floating up?
	bpl.w	+		; if not, branch
	jsr	ObjectMove	; update position
	addi.w	#$18,y_vel(a0)	; reduce upward speed
	jmp	DisplaySprite
+	move.w	#objroutine(ObjMonitor_Icon_Wait),(a0)
	move.b	#$1D,anim_frame_duration(a0)
	movea.w	parent(a0),a1 ; a1=character
	lea	(Monitors_Broken).w,a2
	cmpa.w	#MainCharacter,a1	; did Sonic break the monitor?
	beq.s	+			; if yes, branch
	lea	(Monitors_Broken_2P).w,a2
+	moveq	#0,d0
	move.b	anim(a0),d0
	add.w	d0,d0
	move.w	ObjMonitor_Icon_Types(pc,d0.w),d0
	jsr	ObjMonitor_Icon_Types(pc,d0.w)
	jmp	DisplaySprite

; ============== RELATIVE POINTER LIST     ==================================
ObjMonitor_Icon_Types:
	dc.w ObjMonitor_Null - ObjMonitor_Icon_Types		; 0 - Null
	dc.w ObjMonitor_Broken - ObjMonitor_Icon_Types		; 1 - Broken
	dc.w ObjMonitor_Sonic - ObjMonitor_Icon_Types		; 2 - Sonic 1 - up
	dc.w ObjMonitor_Tails - ObjMonitor_Icon_Types		; 3 - Tails 1 - up
	dc.w ObjMonitor_Robotnik - ObjMonitor_Icon_Types	; 4 - Robotnik
	dc.w ObjMonitor_Rings - ObjMonitor_Icon_Types		; 5 - Super Ring
	dc.w ObjMonitor_Shoes - ObjMonitor_Icon_Types		; 6 - Speed Shoes
	dc.w ObjMonitor_Invincible - ObjMonitor_Icon_Types	; 7 - Invincibility
	dc.w ObjMonitor_SuperSonic - ObjMonitor_Icon_Types	; 8 - SuperSonic
	dc.w ObjMonitor_Bubble - ObjMonitor_Icon_Types		; 9 - Bubble Shield
	dc.w ObjMonitor_Lightning - ObjMonitor_Icon_Types	; A - Lightning Shield
	dc.w ObjMonitor_Fire - ObjMonitor_Icon_Types		; B - Fire Shield
	dc.w ObjMonitor_Wind - ObjMonitor_Icon_Types		; C - Wind Shield
; ============== END RELATIVE POINTER LIST ==================================
; Robotnik Monitor
; hurts the player
ObjMonitor_Broken:
ObjMonitor_SuperSonic:
ObjMonitor_Null:
	rts

ObjMonitor_Robotnik:
	addq.w	#1,(a2)
	bra.w	Touch_ChkHurt2
; ===========================================================================
; Sonic 1up Monitor
; gives Sonic an extra life, or Tails in a 'Tails alone' game

ObjMonitor_Sonic:
	addq.w	#1,(a2)
	addq.b	#1,(Life_count).w
	addq.b	#1,(Update_HUD_lives).w
	move.w	#MusID_ExtraLife,d0
	jmp	(PlayMusic).l	; Play extra life music
; ===========================================================================
; Tails 1up Monitor
; gives Tails an extra life in two player mode

ObjMonitor_Tails:
	addq.w	#1,(Monitors_Broken_2P).w
	addq.b	#1,(Life_count_2P).w
	addq.b	#1,(Update_HUD_lives_2P).w
	move.w	#MusID_ExtraLife,d0
	jmp	(PlayMusic).l	; Play extra life music
; ===========================================================================
; Super Ring Monitor
; gives the player 10 rings

ObjMonitor_Rings:
	addq.w	#1,(a2)
	lea	(Ring_count).w,a2
	lea	(Update_HUD_rings).w,a3
	lea	(Extra_life_flags).w,a4
	lea	(Rings_Collected).w,a5
	cmpa.w	#MainCharacter,a1
	beq.s	+
	lea	(Ring_count_2P).w,a2
	lea	(Update_HUD_rings_2P).w,a3
	lea	(Extra_life_flags_2P).w,a4
	lea	(Rings_Collected_2P).w,a5
+	addi.w	#10,(a5)
	cmpi.w	#999,(a5)
	blo.s	+
	move.w	#999,(a5)
+	addi.w	#10,(a2)
	cmpi.w	#999,(a2)
	blo.s	+
	move.w	#999,(a2)
+	ori.b	#1,(a3)
	cmpi.w	#100,(a2)
	blo.s	+		; branch, if player has less than 100 rings
	bset	#1,(a4)		; set flag for first 1up
	beq.s	ChkPlayer_1up	; branch, if not yet set
	cmpi.w	#200,(a2)
	blo.s	+		; branch, if player has less than 200 rings
	bset	#2,(a4)		; set flag for second 1up
	beq.s	ChkPlayer_1up	; branch, if not yet set
+	move.w	#SndID_Ring,d0
	jmp	(PlayMusic).l

ChkPlayer_1up:
	; give 1up to correct player
	cmpa.w	#MainCharacter,a1
	beq.w	ObjMonitor_Sonic
	bra.w	ObjMonitor_Tails
; ===========================================================================
; Super Sneakers Monitor
; speeds the player up temporarily

ObjMonitor_Shoes:
	addq.w	#1,(a2)
	bset	#2,status2(a1)	; give super sneakers status
	move.w	#$4B0,speedshoes_time(a1)
	move.w	a0,-(sp)
	move.w	a1,a0
	bsr.w	ChooseSpeeds
	move.w	(sp)+,a0
	move.w	#MusID_SpeedUp,d0
	jmp	(PlayMusic).l	; Speed up tempo
; ===========================================================================
; Shield Monitor
; gives the player a shield that absorbs one hit

ObjMonitor_Fire:
	addq.w 	#1,(a2)
	move.b	#0,shields(a1)	; remove any current shield
	move.b	#shield_fire,shields(a1)	; give player a fire shield
	move.b	#$F5,d0					; play the fire shield get sound
	jsr	PlaySound
	bra.b	ObjMonitor_ChooseShield
; ===========================================================================
; Invincibility Monitor
; makes the player temporarily invincible

ObjMonitor_Invincible:
	addq.w	#1,(a2)
	move.b	status2(a1),d0
	andi.b	#power_mask,d0			; is the player already invincible?
	bne.s	ObjMonitor_Invincible_Return	; if so, return
	ori.b	#power_invincible,status2(a1)
	move.w	#20*60,invincibility_time(a1)	; 20 seconds
	tst.b	(Current_Boss_ID).w		; don't change music during boss battles
	bne.s	ObjMonitor_ChooseShield
	cmpi.b	#$C,air_left(a1)		; or when drowning
	bls.s	ObjMonitor_ChooseShield
	move.w	#MusID_Invincible,d0
	jsr	(PlayMusic).l

ObjMonitor_ChooseShield:
	move.w	a0,-(sp)
	move.w	a1,a0
	bsr.w	ChooseShield
	move.w	(sp)+,a0

ObjMonitor_Invincible_Return:
	rts
; ===========================================================================
; Lightning Shield

ObjMonitor_Lightning:
	addq.w 	#1,(a2)
	move.b	#0,shields(a1)	; remove any current shield
	move.b	#shield_lightning,shields(a1)	; give player a lightning shield
	move.b	#$F6,d0					; play the lightning shield get sound
	jsr	PlaySound
	bra.b	ObjMonitor_ChooseShield
; ===========================================================================
; Bubble Shield

ObjMonitor_Bubble:
	addq.w 	#1,(a2)
	move.b	#0,shields(a1)	; remove any current shield
	move.b	#shield_water,shields(a1)	; give player a water shield
	move.b	#$F7,d0					; play the water shield get sound
	jsr	PlaySound
	bra.b	ObjMonitor_ChooseShield
; ===========================================================================
; Wind Shield

ObjMonitor_Wind:
	addq.w 	#1,(a2)
	move.b	#0,shields(a1)	; remove any current shield
	move.b	#shield_wind,shields(a1)	; give player a wind shield
	move.b	#$F7,d0					; play the water shield get sound
	jsr	PlaySound
	bra.b	ObjMonitor_ChooseShield
; ---------------------------------------------------------------------------
; Holds icon in place for a while, then destroys it
; ---------------------------------------------------------------------------

ObjMonitor_Icon_Wait:
	subq.b	#1,anim_frame_duration(a0)
	bpl.b	+
	jmp	DeleteObject
+	jmp	DisplaySprite

Monitor_Data:
		dc.w	objroutine(ObjMonitor_Main)
		dc.l	Monitor_MapUnc_12D36		; Mappings
		dc.w	$680						; Art Tile
		dc.b	4							; Render Flags
		dc.b	4							; Collision Response
		dc.w	$180						; Priority
		dc.b	$1A							; Width Pixels
		dc.b	$1E							; Height Pixels
		dc.b	0							; Animation
		dc.b	0							; Mapping Frame
		
Monitor_Broken_Data:
		dc.w	objroutine(ObjMonitor_Display)
		dc.b	$B	;Mapping
		dc.b	$A	;Animation
		