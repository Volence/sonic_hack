Water_Splash_Object_off3C = $30
Water_Splash_Object_off30 = $32
Water_Splash_Object_off34 = $33

; ===========================================================================
; ----------------------------------------------------------------------------
; Water splash in Aquatic Ruin Zone, Spindash dust
; ----------------------------------------------------------------------------
; Sprite_1DD20:
Water_Splash_Object:
	move.l	#Water_Splash_Object_MapUnc_1DF5E,mappings(a0)
	ori.b	#4,render_flags(a0)
	move.w	#$80,priority(a0)
	move.b	#$10,width_pixels(a0)
	move.w	#$49C,art_tile(a0)
	move.w	#MainCharacter,parent(a0)
	move.w	#$9380,Water_Splash_Object_off3C(a0)
	cmpa.w	#Sonic_Dust,a0
	beq.s	+
	move.b	#1,Water_Splash_Object_off34(a0)
	cmpi.w	#2,(Player_mode).w
	beq.s	+
	move.w	#$48C,art_tile(a0)
	move.w	#Sidekick,parent(a0)
	move.w	#$9180,Water_Splash_Object_off3C(a0)
+	move.w	#objroutine(Water_Splash_Object_Main),(a0)

; loc_1DD90:
Water_Splash_Object_Main:
	tst.b	mappings(a0)
	beq.b	+
	jmp	DeleteObject
+	movea.w	parent(a0),a2 ; a2=character
	moveq	#0,d0
	move.b	anim(a0),d0	; use current animation as a secondary routine counter
	add.w	d0,d0
	move.w	Water_Splash_Object_DisplayModes(pc,d0.w),d1
	jmp	Water_Splash_Object_DisplayModes(pc,d1.w)
; ===========================================================================
; off_1DDA4:
Water_Splash_Object_DisplayModes:
	dc.w Water_Splash_Object_Display - Water_Splash_Object_DisplayModes; 0
	dc.w Water_Splash_Object_MdSplash - Water_Splash_Object_DisplayModes; 1
	dc.w Water_Splash_Object_MdSpindashDust - Water_Splash_Object_DisplayModes; 2
	dc.w Water_Splash_Object_MdSkidDust - Water_Splash_Object_DisplayModes; 3
; ===========================================================================
; loc_1DDAC:
Water_Splash_Object_MdSplash:
	move.w	(Water_Level_1).w,y_pos(a0)
	tst.b	next_anim(a0)
	bne.w	Water_Splash_Object_Display
	move.w	x_pos(a2),x_pos(a0)
	move.b	#0,status(a0)
	andi.w	#$7FFF,art_tile(a0)
	bra.w	Water_Splash_Object_Display
	
; ===========================================================================
; loc_1DDCC:
Water_Splash_Object_MdSpindashDust:
	cmpi.b	#$C,air_left(a2)
	blo.w	Water_Splash_Object_ResetDisplayMode
	move.w	(a2),d2
	move.w	(Player_mode).w,d0
	add.w	d0,d0	
	move.w	Spindash_Routine_Check(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	Water_Splash_Object_ResetDisplayMode	
	move.w	Spindash_Routine_Check2(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	Water_Splash_Object_ResetDisplayMode	
	move.w	Spindash_Routine_Check3(pc,d0.w),d1
	cmp.w	d1,d2
	beq.w	Water_Splash_Object_ResetDisplayMode	
	move.w	Spindash_Routine_Check4(pc,d0.w),d1
	cmp.w	d1,d2	
	beq.w	Water_Splash_Object_ResetDisplayMode
	btst	#s3b_spindash,status3(a2)
	beq.w	Water_Splash_Object_ResetDisplayMode
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	move.b	status(a2),status(a0)
	andi.b	#1,status(a0)
	tst.b	Water_Splash_Object_off34(a0)
	beq.s	+
	subi.w	#4,y_pos(a0)
	bra.s	+
Spindash_Routine_Check:
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Sonic_Hurt)
		dc.w	objroutine(Tails_Hurt)
		dc.w	objroutine(Knuckles_Hurt)	
		
Spindash_Routine_Check2:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)

Spindash_Routine_Check3:
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Sonic_Gone)
		dc.w	objroutine(Tails_Gone)
		dc.w	objroutine(Knuckles_Gone)

Spindash_Routine_Check4:
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Sonic_Respawning)
		dc.w	objroutine(Tails_Respawning)
		dc.w	objroutine(Knuckles_Respawning)	
+
	tst.b	next_anim(a0)
	bne.s	Water_Splash_Object_Display
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	Water_Splash_Object_Display
	ori.w	#$8000,art_tile(a0)
	bra.s	Water_Splash_Object_Display
	
			
; ===========================================================================
; loc_1DE20:
Water_Splash_Object_MdSkidDust:
	cmpi.b	#$C,air_left(a2)
	blo.s	Water_Splash_Object_ResetDisplayMode

; loc_1DE28:
Water_Splash_Object_Display:
	lea	(Ani_Water_Splash_Object).l,a1
	jsr	(AnimateSprite).l
	bsr.w	Water_Splash_Object_LoadDustOrSplashArt
	jmp	(DisplaySprite).l
; ===========================================================================
; loc_1DE3E:
Water_Splash_Object_ResetDisplayMode:
	move.b	#0,anim(a0)
	rts
; ===========================================================================

BranchTo16_DeleteObject
	jmp	DeleteObject
; ===========================================================================
; loc_1DE4A:
Water_Splash_Object_CheckSkid:
	movea.w	parent(a0),a2 ; a2=character
	cmpi.b	#$D,anim(a2)	; SonAni_Stop
	beq.s	Water_Splash_Object_SkidDust
	move.w	#objroutine(Water_Splash_Object_Main),(a0)
	move.b	#0,objoff_32(a0)
	rts
; ===========================================================================
; loc_1DE64:
Water_Splash_Object_SkidDust:
	subq.b	#1,objoff_32(a0)
	bpl.s	loc_1DEE0
	move.b	#3,objoff_32(a0)
	jsr	SingleObjLoad
	bne.s	loc_1DEE0
	move.w	#objroutine(Water_Splash_Object_Main),(a0)
	move.w	x_pos(a2),x_pos(a1)
	move.w	y_pos(a2),y_pos(a1)
	addi.w	#$10,y_pos(a1)
	tst.b	Water_Splash_Object_off34(a0)
	beq.s	+
	subi.w	#4,y_pos(a1)
+
	move.b	#0,status(a1)
	move.b	#3,anim(a1)
	move.l	mappings(a0),mappings(a1)
	move.b	render_flags(a0),render_flags(a1)
	move.w	#$80,priority(a1)
	move.b	#4,width_pixels(a1)
	move.w	art_tile(a0),art_tile(a1)
	move.w	parent(a0),parent(a1)
	andi.w	#$7FFF,art_tile(a1)
	tst.w	art_tile(a2)
	bpl.s	loc_1DEE0
	ori.w	#$8000,art_tile(a1)

loc_1DEE0:
	bsr.s	Water_Splash_Object_LoadDustOrSplashArt
	rts
; ===========================================================================
; loc_1DEE4:
Water_Splash_Object_LoadDustOrSplashArt:
	moveq	#0,d0
	move.b	mapping_frame(a0),d0
	cmp.b	Water_Splash_Object_off30(a0),d0
	beq.s	return_1DF36
	move.b	d0,Water_Splash_Object_off30(a0)
	lea	(Water_Splash_Object_MapRUnc_1E074).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	return_1DF36
	move.w	Water_Splash_Object_off3C(a0),d4

-	moveq	#0,d1
	move.w	(a2)+,d1
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	addi.l	#ArtUnc_Splash,d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,-

return_1DF36:
	rts
