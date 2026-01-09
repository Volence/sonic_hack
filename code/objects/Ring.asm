; ----------------------------------------------------------------------------
; Object 01 - A ring (usually only placed through placement mode)
; ----------------------------------------------------------------------------

Basic_Ring:
	move.w	#objroutine(ObjRing_Animate),(a0)
	move.l	#Basic_Ring_MapUnc_12382,mappings(a0)
	move.w	#$26BC,art_tile(a0)
	move.b	#4,render_flags(a0)
	move.w	#$100,priority(a0)
	move.b	#8,width_pixels(a0)
	move.b	#8,height_pixels(a0)	
	move.b	#5,collision_response(a0)

ObjRing_Animate:
	ckhit.b	ObjRing_Collect
	move.b	(Rings_anim_frame).w,mapping_frame(a0)
	jmp	MarkObjGone

ObjRing_Collect:
	move.w	#objroutine(ObjRing_Sparkle),(a0)
	move.b	#0,collision_response(a0)
	move.w	#$80,priority(a0)
	bsr.b	CollectRing

ObjRing_Sparkle:
	ckhit.b	ObjRing_Delete
	;tst.b	mappings(a0)
	;bmi.b	Lightning_Shield_Spark_Destroy	
	lea	(Ani_Ring).l,a1
	jsr	AnimateSprite
	jmp	DisplaySprite

ObjRing_Delete:
	jmp	DeleteObject

CollectRing:


CollectRing_Sonic:
	cmpi.w	#999,(Rings_Collected).w ; did Sonic collect 999 or more rings?
	bhs.s	CollectRing_1P		; if yes, branch
	addq.w	#1,(Rings_Collected).w	; add 1 to the number of collected rings

CollectRing_1P:
	move.w	#$B5,d0			; prepare to play the ring sound
	cmpi.w	#999,(Ring_count).w	; does the player 1 have 999 or more rings?
	bhs.s	JmpTo_PlaySoundStereo	; if yes, play the ring sound
	addq.w	#1,(Ring_count).w	; add 1 to the ring count
	ori.b	#1,(Update_HUD_rings).w	; set flag to update the ring counter in the HUD
	cmpi.w	#100,(Ring_count).w	; does the player 1 have less than 100 rings?
	blo.s	JmpTo_PlaySoundStereo	; if yes, play the ring sound
	bset	#1,(Extra_life_flags).w	; test and set the flag for the first extra life
	beq.s	+			; if it was clear before, branch
	cmpi.w	#200,(Ring_count).w	; does the player 1 have less than 200 rings?
	blo.s	JmpTo_PlaySoundStereo	; if yes, play the ring sound
	bset	#2,(Extra_life_flags).w	; test and set the flag for the second extra life
	bne.s	JmpTo_PlaySoundStereo	; if it was set before, play the ring sound
+
	addq.b	#1,(Life_count).w	; add 1 to the life count
	addq.b	#1,(Update_HUD_lives).w	; add 1 to the displayed life count
	move.w	#MusID_ExtraLife,d0	; prepare to play the extra life jingle

JmpTo_PlaySoundStereo
	jmp	(PlaySoundStereo).l

JmpTo2_PlaySoundStereo
	jmp	(PlaySoundStereo).l
; End of function CollectRing

; ===========================================================================
; ----------------------------------------------------------------------------
; Scattering rings (generated when Sonic is hurt and has rings)
; ----------------------------------------------------------------------------

Hurt_Rings:
	movea.l	a0,a1
	moveq	#0,d5
	move.w	(Ring_count).w,d5
	tst.b	parent+1(a0)
	beq.s	+
	move.w	(Ring_count_2P).w,d5
+	moveq	#$20,d0
	cmp.w	d0,d5
	blo.s	+
	move.w	d0,d5
+	subq.w	#1,d5
	move.w	#$288,d4
	bra.s	+
-	jsr	SingleObjLoad
	bne.w	Hurt_Rings_Loaded
+	move.w	#objroutine(ObjRing_Bounce),id(a1)
	move.b	#8,width_pixels(a1)
	move.b	#8,height_pixels(a1)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.l	#Basic_Ring_MapUnc_12382,mappings(a1)
	move.w	#$26BC,art_tile(a1)
	move.b	#$84,render_flags(a1)
	move.w	#$180,priority(a1)
	move.b	#5,collision_response(a1)
	move.b	#-1,(Ring_spill_anim_counter).w
	tst.w	d4
	bmi.s	+
	move.w	d4,d0
	jsr	CalcSine
	move.w	d4,d2
	lsr.w	#8,d2
	asl.w	d2,d0
	asl.w	d2,d1
	move.w	d0,d2
	move.w	d1,d3
	addi.b	#$10,d4
	bcc.s	+
	subi.w	#$80,d4
	bcc.s	+
	move.w	#$288,d4
+	move.w	d2,x_vel(a1)
	move.w	d3,y_vel(a1)
	neg.w	d2
	neg.w	d4
	dbf	d5,-

Hurt_Rings_Loaded:
	move.w	#SndID_RingSpill,d0
	jsr	(PlaySoundStereo).l
	tst.b	parent+1(a0)
	bne.s	+
	move.w	#0,(Ring_count).w
	move.b	#$80,(Update_HUD_rings).w
	move.b	#0,(Extra_life_flags).w
	bra.s	ObjRing_Bounce
+	move.w	#0,(Ring_count_2P).w
	move.b	#$80,(Update_HUD_rings_2P).w
	move.b	#0,(Extra_life_flags_2P).w

ObjRing_Bounce:
	move.b	(Ring_spill_anim_frame).w,mapping_frame(a0)
	jsr	ObjectMove
	addi.w	#$18,y_vel(a0)
	bmi.s	ObjRing_Bounce2
	move.b	(Vint_runcount+3).w,d0
	add.b	d7,d0
	andi.b	#7,d0
	bne.s	ObjRing_Bounce2
	tst.b	render_flags(a0)
	bpl.s	ObjRing_BounceOutside
	jsr	(RingCheckFloorDist).l
	tst.w	d1
	bpl.s	ObjRing_Bounce2
	add.w	d1,y_pos(a0)
	move.w	y_vel(a0),d0
	asr.w	#2,d0
	sub.w	d0,y_vel(a0)
	neg.w	y_vel(a0)

ObjRing_Bounce2:
	tst.b	(Ring_spill_anim_counter).w
	beq.w	ObjRing_Delete
	move.w	(Camera_Max_Y_pos_now).w,d0
	addi.w	#$E0,d0
	cmp.w	y_pos(a0),d0
	blo.w	ObjRing_Delete
	jmp	DisplaySprite

ObjRing_BounceOutside:
	tst.w	(Two_player_mode).w
	bne.w	ObjRing_Delete
	bra.s	ObjRing_Bounce2

; ===========================================================================
; ----------------------------------------------------------------------------
; Attracted ring
; ----------------------------------------------------------------------------

Attracted_Ring:
	move.w	#objroutine(ObjRing_Attract),(a0)	; go to next routine
	move.l	#Basic_Ring_MapUnc_12382,mappings(a0)	; set mappings address
	move.w	#$26BC,art_tile(a0)			; set art offset
	move.b	#4,render_flags(a0)			; align to the level
	move.w	#$100,priority(a0)				; set priority
	move.b	#8,width_pixels(a0)			; set width
	move.b	#8,height_pixels(a0)
	move.b	#5,collision_response(a0)	

ObjRing_Attract:
	bsr.w	ObjRing_Move				; move the ring
	movea.w	parent(a0),a1				; get the parent
	move.b	status2(a1),d0			; get the secondary status
	andi.b	#shield_mask,d0				; get shield type
	cmpi.b	#shield_lightning,d0			; is it a lightning shield?
	beq.s	+					; if so, branch
	move.w	#objroutine(ObjRing_Bounce),(a0)	; change to a scattered ring object
	move.b	#-1,(Ring_spill_anim_counter).w		; reset the scattered rings counter
+	move.b	(Rings_anim_frame).w,mapping_frame(a0)
	jmp	DisplaySprite

ObjRing_Move:
	movea.w	parent(a0),a1
	move.w	#$30,d1
	move.w	x_pos(a1),d0
	cmp.w	x_pos(a0),d0
	bcc.s	+
	neg.w	d1
	tst.w	x_vel(a0)
	bmi.s	ObjRing_MoveHorz
	add.w	d1,d1
	add.w	d1,d1
	bra.s	ObjRing_MoveHorz
+	tst.w	x_vel(a0)
	bpl.s	ObjRing_MoveHorz
	add.w	d1,d1
	add.w	d1,d1

ObjRing_MoveHorz:
	add.w	d1,x_vel(a0)
	move.w	#$30,d1
	move.w	y_pos(a1),d0
	cmp.w	y_pos(a0),d0
	bcc.s	+
	neg.w	d1
	tst.w	y_vel(a0)
	bmi.s	ObjRing_MoveVert
	add.w	d1,d1
	add.w	d1,d1
	bra.s	ObjRing_MoveVert
+	tst.w	y_vel(a0)
	bpl.s	ObjRing_MoveVert
	add.w	d1,d1
	add.w	d1,d1

ObjRing_MoveVert:
	add.w	d1,y_vel(a0)
	jmp	ObjectMove
; ===========================================================================