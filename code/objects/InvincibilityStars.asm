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
	move.w	#VRAM_Shield,art_tile(a1)
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
