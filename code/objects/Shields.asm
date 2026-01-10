; ----------------------------------------------------------------------------
; Instashield
; ----------------------------------------------------------------------------

InstaShield:
	lea	InstaShield_Data(pc),a2
	bsr.w	Shield_Load

Obj_InstaShield_Main:
	lea	MainCharacter-Sonic_Shield(a0),a2
	move.b	status2(a2),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	Obj_InstaShield_Delete	; if so, branch
	move.w	x_pos(a2),x_pos(a0)		; copy Sonic's x-position
	move.w	y_pos(a2),y_pos(a0)		; copy Sonic's y-position
	move.b	status(a2),status(a0)		; copy Sonic's status
	andi.b	#1,status(a0)		; ... but only the x-flip bit
	tst.b	($FFFFF7C6).w
	beq.s	+
	ori.b	#2,status(a0)		; flip instashield upside-down
+	bclr	#7,status(a0)		; unset priority flag
	tst.w	status(a2)			; is Sonic's priority flag set?
	bpl.s	+			; if not, branch
	bset	#7,status(a0)		; set priority flag
+	addq.b	#1,mapping_frame(a0)	; increase frame
	cmpi.b	#6,mapping_frame(a0)	; did the visible animation end?
	bcs.b	+			; if not, branch to display
	btst	#4,mapping_frame(a0)	; did the instashield effect end?
	bne.b	Obj_InstaShield_Delete	; if so, branch to delete
	rts
+	bsr.w	LoadShieldsDynPLC
	jmp	DisplaySprite

Obj_InstaShield_Delete:
	jmp	DeleteObject

; ===========================================================================
; ----------------------------------------------------------------------------
; Fire shield
; ----------------------------------------------------------------------------

Fire_Shield:
	lea	Fire_Shield_Data(pc),a2
	bsr.w	Shield_Load

Fire_Shield_Main:
	lea	MainCharacter-Sonic_Shield(a0),a2
	btst	#6,status(a2)			; Underwater?
	bne.s	Fire_Shield_Underwater
	bra.w	Shield_Main_Common
; ===========================================================================

; called when you have a fire shield and go underwater
Fire_Shield_Underwater:
	andi.b	#shield_del,status2(a2)    ; Remove shield
	jsr	(SingleObjLoad).l
	bne.s	Fire_Shield_Destroy
	move.w	#objroutine(Fire_Shield_Explosion),(a1)    ; Load Object DF (fire shield explosion)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)

Fire_Shield_Destroy:
	andi.b	#shield_del,status2(a2)    ; Remove shield
	jmp	DeleteObject

; ===========================================================================
; ----------------------------------------------------------------------------
; Fire shield explosion
; ----------------------------------------------------------------------------

Fire_Shield_Explosion:
	lea	Fire_Shield_Explosion_Data(pc),a2
	jsr	(Load_Object1).l
	move.b	#3,anim_frame_duration(a0)

Fire_Shield_Explosion_Main:
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	Fire_Shield_Explosion_Display
	move.b	#3,anim_frame_duration(a0)
	addq.b	#1,mapping_frame(a0)
	cmpi.b	#5,mapping_frame(a0)
	bne.s	Fire_Shield_Explosion_Display
	jmp	DeleteObject

Fire_Shield_Explosion_Display:
	jmp	DisplaySprite

; ===========================================================================
; ----------------------------------------------------------------------------
; Lightning shield
; ----------------------------------------------------------------------------

Lightning_Shield:
	move.l	#ArtUnc_LighteningShield_Sparks,d1
	move.w	#$9AA0,d2		; VRAM transfer location
	move.w	#$50,d3			; Transfer length
	jsr	(QueueDMATransfer).l
	lea	Lightning_Shield_Data(pc),a2
	bsr.w	Shield_Load

Lightning_Shield_Main:
	lea	MainCharacter-Sonic_Shield(a0),a2
	btst	#6,status(a2)			; is Underwater flag on?
	bne.s	Lightning_Shield_Underwater
	bra.w	Shield_Main_Common
; ===========================================================================

Lightning_Shield_Destroy:
       andi.b	#shield_del,status2(a2)    ; Clear all shield flags
       jmp	DeleteObject
; ===========================================================================

Lightning_Shield_Underwater:
	move.w	#objroutine(Lightning_Shield_Underwater_Destroy),(a0)	; go to routine Underwater_Destroy
	andi.b	#shield_del,status2(a2)    ; Clear all shield flags
	lea	(Underwater_palette).w,a1
	lea	(Underwater_palette_2).w,a2
	move.w	#$1F,d0
-	move.l	(a1),(a2)+
	move.l	#$EEE0EEE,(a1)+
	dbf	d0,-
	move.w	#0,-$40(a1)
	move.b	#3,anim_frame_duration(a0)
	rts
; ===========================================================================

Lightning_Shield_Underwater_Destroy:
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	Lightning_Return
	lea	(Underwater_palette_2).w,a1
	lea	(Underwater_palette).w,a2
	move.w	#$1F,d0
-	move.l	(a1)+,(a2)+
	dbf	d0,-
	jmp	DeleteObject

Lightning_Return:
	rts

; ===========================================================================
; ----------------------------------------------------------------------------
; Lightning shield spark
; ----------------------------------------------------------------------------

Lightning_Shield_Spark:
	tst.b	mappings(a0)
	bmi.b	Lightning_Shield_Spark_Destroy
	jsr	(ObjectMove).l
	addi.w	#$18,y_vel(a0)
	lea	(Ani_LightningShield).l,a1
	jsr	(AnimateSprite).l
	jmp	(DisplaySprite).l

Lightning_Shield_Spark_Destroy:
	jmp	(DeleteObject).l

; ===========================================================================
; ----------------------------------------------------------------------------
; Wind shield
; ----------------------------------------------------------------------------

Wind_Shield:
	lea	Wind_Shield_Data(pc),a2
	bsr.w	Shield_Load
	lea	MainCharacter-Sonic_Shield(a0),a1
	jsr	(ResumeMusic).l

Wind_Shield_Main:
	lea	MainCharacter-Sonic_Shield(a0),a2
	bra.w	Shield_Main_Common
; ===========================================================================

Wind_Shield_Destroy:
       andi.b	#shield_del,status2(a2)    ; Clear all shield flags
       jmp	DeleteObject
; ===========================================================================
; ----------------------------------------------------------------------------
; Bubble shield
; ----------------------------------------------------------------------------

Bubble_Shield:
	lea	Bubble_Shield_Data(pc),a2
	bsr.w	Shield_Load
	lea	MainCharacter-Sonic_Shield(a0),a1
	jsr	(ResumeMusic).l

Bubble_Shield_Main:
	lea	MainCharacter-Sonic_Shield(a0),a2
	bra.w	Shield_Main_Common

LoadShieldsDynPLC:
	moveq	#0,d0
	move.b	mapping_frame(a0),d0
	cmp.b	shield_prev_frame(a0),d0
	beq.s	LSDPLC_Return
	move.b	d0,shield_prev_frame(a0)
	movea.l	shield_dplc(a0),a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	LSDPLC_Return
	move.w	#$97C0,d4

LSDPLC_Loop:
	moveq	#0,d1
	move.w	(a2)+,d1
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	add.l	shield_art(a0),d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,LSDPLC_Loop

LSDPLC_Return:
	rts

; End of function LoadShieldsDynPLC
; ====================================================================================================================

; ---------------------------------------------------------------------------
; Shield_Main_Common - Common main loop for all elemental shields
; Expects a2 = pointer to MainCharacter
; Uses shield_anim and shield_priority_frame from SST
; ---------------------------------------------------------------------------
Shield_Main_Common:
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	tst.b	anim(a0)			; Skip status copying after first frame
	bne.s	Shield_Main_Common_Display
	move.b	status(a2),status(a0)
	andi.b	#1,status(a0)			; Only orientation flag
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	Shield_Main_Common_Display
	ori.w	#$8000,art_tile(a0)
Shield_Main_Common_Display:
	movea.l	shield_anim(a0),a1		; Animation script from SST
	jsr	(AnimateSprite).l
	move.w	#$80,priority(a0)
	move.b	shield_priority_frame(a0),d0	; Priority threshold from SST
	beq.s	Shield_Main_Common_Done		; 0 = no priority change
	cmp.b	mapping_frame(a0),d0
	bhi.s	Shield_Main_Common_Done
	move.w	#$200,priority(a0)
Shield_Main_Common_Done:
	bsr.w	LoadShieldsDynPLC
	jmp	(DisplaySprite).l
; ====================================================================================================================


Shield_Load	
	move.w	(a2)+,(a0)
	move.l	(a2)+,mappings(a0)
	move.w	(a2)+,art_tile(a0)	
	move.b	(a2)+,render_flags(a0)
	tst.b	(a2)+			; skip explicit padding byte after dc.b
	move.w	(a2)+,priority(a0)	
	move.b	(a2)+,width_pixels(a0)
	move.b	(a2)+,height_pixels(a0)	
	move.w	(a2)+,next_anim(a0)	; Write to $1C (even) - this sets both next_anim and anim	
	move.l	(a2)+,shield_dplc(a0)
	move.l	(a2)+,shield_art(a0)
	move.b	(a2)+,shield_prev_frame(a0)
	tst.b	(a2)+			; skip padding
	move.l	(a2)+,shield_anim(a0)		; Animation script pointer
	move.b	(a2)+,shield_priority_frame(a0)	; Priority threshold frame
	rts
; ====================================================================================================================	
; ----------------------------------------------------------------------------
; Shield Data
; ----------------------------------------------------------------------------
InstaShield_Data:
		dc.w	objroutine(Obj_InstaShield_Main)
		dc.l	Map_InstaShield
		dc.w	$4BE
		dc.b	4
		dc.b	0			; explicit padding
		dc.w	$80
		dc.b	$30
		dc.b	$30
		dc.w	1
		dc.l	DPLC_InstaShield
		dc.l	ArtUnc_InstaShield
		dc.b	$FF
		even
		
Fire_Shield_Data:
		dc.w	objroutine(Fire_Shield_Main)
		dc.l	Map_FireShield
		dc.w	$4BE
		dc.b	4
		dc.b	0			; explicit padding
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	0			; anim = 0 (idle rotation animation)
		dc.l	DPLC_FireShield
		dc.l	ArtUnc_FireShield
		dc.b	-1
		dc.b	0			; padding for shield_prev_frame
		dc.l	Ani_FireShield		; shield_anim
		dc.b	$F			; shield_priority_frame
		even		
		
Fire_Shield_Explosion_Data:
		dc.w	objroutine(Fire_Shield_Explosion_Main)
		dc.l	Explosion_MapUnc_21120
		dc.w	$5A4
		dc.b	4
		dc.b	0			; explicit padding
		dc.w	$280
		dc.b	$C
		dc.b	$C
		dc.w	0
		dc.w	0
		dc.b	1		
		even
		

Lightning_Shield_Data:
		dc.w	objroutine(Lightning_Shield_Main)
		dc.l	Map_LighteningShield
		dc.w	$4BE
		dc.b	4
		dc.b	0			; explicit padding
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	0			; anim = 0 (full rotation animation)
		dc.l	DPLC_LighteningShield
		dc.l	ArtUnc_LighteningShield
		dc.b	-1
		dc.b	0			; padding for shield_prev_frame
		dc.l	Ani_LightningShield	; shield_anim
		dc.b	$E			; shield_priority_frame
		even

Wind_Shield_Data:
		dc.w	objroutine(Wind_Shield_Main)
		dc.l	Map_WindShield
		dc.w	$4BE
		dc.b	4
		dc.b	0			; explicit padding
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	0			; anim = 0 (idle animation)
		dc.l	DPLC_WindShield
		dc.l	ArtUnc_WindShield
		dc.b	-1
		dc.b	0			; padding for shield_prev_frame
		dc.l	Ani_LightningShield	; shield_anim (TODO: create Ani_WindShield)
		dc.b	$E			; shield_priority_frame
		even
		
Bubble_Shield_Data:
		dc.w	objroutine(Bubble_Shield_Main)
		dc.l	Map_BubbleShield
		dc.w	$4BE
		dc.b	4
		dc.b	0			; explicit padding
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	0			; anim = 0 (idle animation)
		dc.l	DPLC_BubbleShield
		dc.l	ArtUnc_BubbleShield
		dc.b	-1
		dc.b	0			; padding for shield_prev_frame
		dc.l	Ani_BubbleShield	; shield_anim
		dc.b	0			; shield_priority_frame (0 = no priority change)
		even
		