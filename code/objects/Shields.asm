; ===========================================================================
; ----------------------------------------------------------------------------
; Plain Shield
; ----------------------------------------------------------------------------

Plain_Shield:
	lea	Plain_Shield_Data(pc),a2
	jsr	(Load_Object3).l

Plain_Shield_Shield:
	lea	MainCharacter-Sonic_Shield(a0),a2
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	move.b	status(a2),status(a0)
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	Plain_Shield_Display
	ori.w	#$8000,art_tile(a0)

Plain_Shield_Display:
	lea	(Ani_Plain_Shield).l,a1
	jsr	(AnimateSprite).l
	jmp	(DisplaySprite).l

JmpTo7_DeleteObject
	jmp	(DeleteObject).l

; ===========================================================================
; ----------------------------------------------------------------------------
; Invincibility Stars
; ----------------------------------------------------------------------------

Invincibility_Stars_off34 = $34
Invincibility_Stars_off35 = $35
Invincibility_Stars_off36 = $36
Invincibility_Stars_off38 = $37

Invincibility_Stars:
	move.l	#ArtUnc_InvStars,d1
	move.w	#$97C0,d2		; VRAM transfer location
	move.w	#$220,d3		; Transfer length
	jsr	(QueueDMATransfer).l
	moveq	#0,d2
	lea	Invincibility_Stars_Data2-2(pc),a2
	lea	(a0),a1
	moveq	#3,d1
-	move.w	#objroutine(Invincibility_Stars_Run2),(a1)
	move.l	#Invincibility_Stars_MapUnc_1DCBC,mappings(a1)
	move.w	#$4BE,art_tile(a1)
	move.b	#$44,render_flags(a1)
	move.b	#$10,width_pixels(a1)
	move.b	#2,$20(a1)
	move.b	d2,Invincibility_Stars_off36(a1)
	addq.w	#1,d2
	move.w	(a2)+,Invincibility_Stars_off34(a1)
	lea	next_object(a1),a1
	dbf	d1,-
	move.w	#objroutine(Invincibility_Stars_Run1),(a0)
	move.b	#4,Invincibility_Stars_off36(a0)

Invincibility_Stars_Run1:
	lea	MainCharacter-Sonic_Shield(a0),a1
	move.w	x_pos(a1),x_pos(a0)
	move.w	y_pos(a1),y_pos(a0)
	lea	$21(a0),a2
	lea	byte_1DB82(pc),a3
	moveq	#0,d5
-	moveq	#0,d2
	move.b	Invincibility_Stars_off38(a0),d2
	move.b	(a3,d2.w),d5
	bpl.s	+
	clr.b	Invincibility_Stars_off38(a0)
	bra.s	-
+	addq.b	#1,Invincibility_Stars_off38(a0)
	lea	byte_1DB42(pc),a6
	move.b	Invincibility_Stars_off36(a0),d6
	andi.w	#$3E,d6
	move.b	(a6,d6.w),(a2)+
	move.b	1(a6,d6.w),(a2)+
	move.b	d5,(a2)+
	bchg	#5,d6
	move.b	(a6,d6.w),(a2)+
	move.b	1(a6,d6.w),(a2)+
	move.b	d5,(a2)+
	moveq	#$12,d0
	btst	#0,status(a1)
	beq.s	+
	neg.w	d0
+	add.b	d0,Invincibility_Stars_off36(a0)
	move.w	#$80,d0
	jmp	DisplaySprite3
; ===========================================================================

Invincibility_Stars_Run2:
	lea	MainCharacter-Sonic_Shield(a0),a1
	cmpi.w	#2,(Player_mode).w
	beq.b	Invincibility_Stars_Run2_Tails
	lea	(Sonic_Pos_Record_Index).w,a5
	lea	(Sonic_Pos_Record_Buf).w,a6
	bra.b	Invincibility_Stars_Run2_Continue

; ===========================================================================
Invincibility_Stars_Data1:
	dc.l byte_1DB8F, byte_1DBA4, byte_1DBBD
Invincibility_Stars_Data2:
	dc.w $000B, $160D, $2C0D
; ===========================================================================

Invincibility_Stars_Run2_Tails:
	lea	(Tails_Pos_Record_Index).w,a5
	lea	(Tails_Pos_Record_Buf).w,a6

Invincibility_Stars_Run2_Continue:
	moveq	#0,d1
	move.b	Invincibility_Stars_off36(a0),d1
	lsl.w	#2,d1
	movea.l	Invincibility_Stars_Data1-4(pc,d1.w),a3
	move.w	d1,d2
	add.w	d1,d1
	add.w	d2,d1
	move.w	(a5),d0
	sub.b	d1,d0
	lea	(a6,d0.w),a2
	move.w	(a2)+,d0
	move.w	(a2)+,d1
	move.w	d0,x_pos(a0)
	move.w	d1,y_pos(a0)
	lea	$21(a0),a2
-	moveq	#0,d2
	move.b	Invincibility_Stars_off38(a0),d2
	move.b	(a3,d2.w),d5
	bpl.s	+
	clr.b	Invincibility_Stars_off38(a0)
	bra.s	-
+	swap	d5
	add.b	Invincibility_Stars_off35(a0),d2
	move.b	(a3,d2.w),d5
	addq.b	#1,Invincibility_Stars_off38(a0)
	lea	byte_1DB42(pc),a6
	move.b	Invincibility_Stars_off34(a0),d6
	andi.w	#$3E,d6
	move.b	(a6,d6.w),(a2)+
	move.b	1(a6,d6.w),(a2)+
	move.b	d5,(a2)+
	bchg	#5,d6
	swap	d5
	move.b	(a6,d6.w),(a2)+
	move.b	1(a6,d6.w),(a2)+
	move.b	d5,(a2)+
	moveq	#2,d0
	btst	#0,status(a1)
	beq.s	+
	neg.w	d0
+	add.b	d0,Invincibility_Stars_off34(a0)
	move.w	#$80,d0
	jmp	DisplaySprite3
; ===========================================================================
; unknown
byte_1DB42:	dc.b	$0F, $00, $0F, $03, $0E, $06, $0D, $08, $0B, $0B, $08, $0D, $06, $0E, $03, $0F
		dc.b	$00, $10, $FC, $0F, $F9, $0E, $F7, $0D, $F4, $0B, $F2, $08, $F1, $06, $F0, $03
		dc.b	$F0, $00, $F0, $FC, $F1, $F9, $F2, $F7, $F4, $F4, $F7, $F2, $F9, $F1, $FC, $F0
		dc.b	$FF, $F0, $03, $F0, $06, $F1, $08, $F2, $0B, $F4, $0D, $F7, $0E, $F9, $0F, $FC

byte_1DB82:	dc.b   8,  5,  7,  6,  6,  7,  5,  8,  6,  7,  7,  6,$FF
byte_1DB8F:	dc.b   8,  7,  6,  5,  4,  3,  4,  5,  6,  7,$FF
		dc.b   3,  4,  5,  6,  7,  8,  7,  6,  5,  4
byte_1DBA4:	dc.b   8,  7,  6,  5,  4,  3,  2,  3,  4,  5,  6,  7,$FF
		dc.b   2,  3,  4,  5,  6,  7,  8,  7,  6,  5,  4,  3
byte_1DBBD:	dc.b   7,  6,  5,  4,  3,  2,  1,  2,  3,  4,  5,  6,$FF
		dc.b   1,  2,  3,  4,  5,  6,  7,  6,  5,  4,  3,  2
; ===========================================================================
; ----------------------------------------------------------------------------
; Super Sonic's stars
; ----------------------------------------------------------------------------

SS_Stars:
	lea	SS_Stars_Data(pc),a2
	jsr	(Load_Object3).l
	btst	#7,(MainCharacter+art_tile).w
	beq.s	SS_Stars_Main
	bset	#7,art_tile(a0)

SS_Stars_Main:
	tst.b	objoff_30(a0)
	beq.s	loc_1E188
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	+
	move.b	#1,anim_frame_duration(a0)
	addq.b	#1,mapping_frame(a0)
	cmpi.b	#6,mapping_frame(a0)
	blo.s	+
	move.b	#0,mapping_frame(a0)
	move.b	#0,objoff_30(a0)
	move.b	#1,objoff_31(a0)
	rts
+	tst.b	objoff_31(a0)
	bne.s	JmpTo6_DisplaySprite

loc_1E176:
	move.w	(MainCharacter+x_pos).w,x_pos(a0)
	move.w	(MainCharacter+y_pos).w,y_pos(a0)

JmpTo6_DisplaySprite
	jmp	(DisplaySprite).l

loc_1E188:
	btst	#s3b_lock_motion,(MainCharacter+status3).w
	bne.s	loc_1E189
	mvabs.w	(MainCharacter+inertia).w,d0
	cmpi.w	#$800,d0
	blo.s	loc_1E189
	move.b	#0,mapping_frame(a0)
	move.b	#1,objoff_30(a0)
	bra.s	loc_1E176

loc_1E189:
	move.b	#0,objoff_30(a0)
	move.b	#0,objoff_31(a0)
	rts

JmpTo8_DeleteObject
	jmp	(JmpTo7_DeleteObject).l
; ===========================================================================
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
	btst	#6,status(a2)    ; Underwater
	bne.s	Fire_Shield_Underwater
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	tst.b	anim(a0)
	bne.s	Fire_Shield_Display
	move.b	status(a2),status(a0)
	andi.b	#1,status(a0)    ; Only orientation flag
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	Fire_Shield_Display
	ori.w	#$8000,art_tile(a0)

Fire_Shield_Display:
	lea	(Ani_FireShield).l,a1
	jsr	(AnimateSprite).l
	move.w	#$80,priority(a0)
	cmp.b	#$F,mapping_frame(a0)
	bcs.s	+
	move.w	#$200,priority(a0)
+	bsr.w	LoadShieldsDynPLC
	jmp	(DisplaySprite).l
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
	btst	#6,status(a2)		; is Underwater flag on?
	bne.s	Lightning_Shield_Underwater	; if "yes", branch
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	move.b	status(a2),status(a0)
	andi.b	#1,status(a0)		; Only orientation flag is kept
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	Lightning_Shield_Display
	ori.w	#$8000,art_tile(a0)

Lightning_Shield_Display:
	lea	(Ani_LightningShield).l,a1
	jsr	(AnimateSprite).l
	move.w	#$80,priority(a0)
	cmp.b	#$E,mapping_frame(a0)
	bcs.s	+
	move.w	#$200,priority(a0)
+	jsr	LoadShieldsDynPLC
	jmp	DisplaySprite
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
	jmp	(JmpTo7_DeleteObject).l

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
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	move.b	status(a2),status(a0)
	andi.b	#1,status(a0)		; Only orientation flag is kept
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	Wind_Shield_Display
	ori.w	#$8000,art_tile(a0)

Wind_Shield_Display:
	lea	(Ani_LightningShield).l,a1
	jsr	(AnimateSprite).l
	move.w	#$80,priority(a0)
	cmp.b	#$E,mapping_frame(a0)
	bcs.s	+
	move.w	#$200,priority(a0)
+	jsr	LoadShieldsDynPLC
	jmp	DisplaySprite
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
	move.w	x_pos(a2),x_pos(a0)
	move.w	y_pos(a2),y_pos(a0)
	move.b	status(a2),status(a0)
	andi.b	#1,status(a0)
	andi.w	#$7FFF,art_tile(a0)
	tst.w	art_tile(a2)
	bpl.s	Bubble_Shield_Display
	ori.w	#$8000,art_tile(a0)

Bubble_Shield_Display:
	lea	(Ani_BubbleShield).l,a1
	jsr	(AnimateSprite).l
	bsr.w	LoadShieldsDynPLC
	jmp	(DisplaySprite).l

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


Shield_Load	
	move.w	(a2)+,(a0)
	move.l	(a2)+,mappings(a0)
	move.w	(a2)+,art_tile(a0)	
	move.b	(a2)+,render_flags(a0)
	move.w	(a2)+,priority(a0)	
	move.b	(a2)+,width_pixels(a0)
	move.b	(a2)+,height_pixels(a0)	
	move.w	(a2)+,anim(a0)	
	move.l	(a2)+,shield_dplc(a0)
	move.l	(a2)+,shield_art(a0)
	move.b	(a2)+,shield_prev_frame(a0)	
	rts
; ====================================================================================================================	
; ----------------------------------------------------------------------------
; Shield Data
; ----------------------------------------------------------------------------
Plain_Shield_Data:
		dc.w	objroutine(Plain_Shield_Shield)
		dc.l	Plain_Shield_MapUnc_1DBE4
		dc.w	$4BE
		dc.b	4
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.b	0
		even

SS_Stars_Data:
		dc.w	objroutine(SS_Stars_Main)
		dc.l	SS_Stars_MapUnc_1E1BE
		dc.w	$5F2
		dc.b	4
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.b	0
		even
		
InstaShield_Data:
		dc.w	objroutine(Obj_InstaShield_Main)
		dc.l	Map_InstaShield
		dc.w	$4BE
		dc.b	4	
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
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	1		
		dc.l	DPLC_FireShield
		dc.l	ArtUnc_FireShield	
		dc.b	-1
		even		
		
Fire_Shield_Explosion_Data:
		dc.w	objroutine(Fire_Shield_Explosion_Main)
		dc.l	Explosion_MapUnc_21120
		dc.w	$5A4
		dc.b	4
		dc.b	0
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
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	1
		dc.l	DPLC_LighteningShield
		dc.l	ArtUnc_LighteningShield
		dc.b	-1
		even

Wind_Shield_Data:
		dc.w	objroutine(Wind_Shield_Main)
		dc.l	Map_WindShield
		dc.w	$4BE
		dc.b	4
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	1
		dc.l	DPLC_WindShield
		dc.l	ArtUnc_WindShield
		dc.b	-1
		even
		
Bubble_Shield_Data:
		dc.w	objroutine(Bubble_Shield_Main)
		dc.l	Map_BubbleShield
		dc.w	$4BE
		dc.b	4
		dc.w	$80
		dc.b	$18
		dc.b	$18
		dc.w	1
		dc.l	DPLC_BubbleShield
		dc.l	ArtUnc_BubbleShield
		dc.b	-1
		even
		