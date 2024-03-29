; ----------------------------------------------------------------------------
; Pseudo-object that manages where rings are placed onscreen
; as you move through the level, and otherwise updates them.
; ----------------------------------------------------------------------------

; loc_16F88:
RingsManager:
	moveq	#0,d0
	move.b	($FFFFF710).w,d0
	move.w	RingsManager_States(pc,d0.w),d0
	jmp	RingsManager_States(pc,d0.w)
; ===========================================================================
; off_16F96:
RingsManager_States:
	dc.w RingsManager_Init - RingsManager_States
	dc.w RingsManager_Main - RingsManager_States
; ===========================================================================
; loc_16F9A:
RingsManager_Init:
	addq.b	#2,($FFFFF710).w ; => RingsManager_Main
	bsr.w	RingsManager_Setup
	movea.l	(Ring_start_addr_ROM).w,a1
	lea	(Ring_Positions).w,a2
	move.w	(Camera_X_pos).w,d4
	subq.w	#8,d4
	bhi.s	loc_16FB6
	moveq	#1,d4
	bra.s	loc_16FB6
; ===========================================================================

loc_16FB2:
	addq.w	#4,a1
	addq.w	#2,a2

loc_16FB6:
	cmp.w	(a1),d4
	bhi.s	loc_16FB2
	move.l	a1,(Ring_start_addr_ROM).w
	move.l	a1,(Ring_start_addr_ROM_P2).w
	move.w	a2,(Ring_start_addr_RAM).w
	move.w	a2,(Ring_start_addr_RAM_P2).w
	addi.w	#$150,d4
	bra.s	loc_16FCE
; ===========================================================================

loc_16FCA:
	addq.w	#4,a1

loc_16FCE:
	cmp.w	(a1),d4
	bhi.s	loc_16FCA
	move.l	a1,(Ring_end_addr_ROM).w
	move.l	a1,(Ring_end_addr_ROM_P2).w
	rts
; ===========================================================================
; loc_16FDE:
RingsManager_Main:
	lea	($FFFFEF80).w,a2
	move.w	(a2)+,d1
	subq.w	#1,d1
	bcs.s	loc_17014

loc_16FE8:
	move.w	(a2)+,d0
	beq.s	loc_16FE8
	movea.w	d0,a1
	subq.b	#1,(a1)
	bne.s	loc_17010
	move.b	#6,(a1)
	addq.b	#1,1(a1)
	cmpi.b	#8,1(a1)
	bne.s	loc_17010
	move.w	#-1,(a1)
	move.w	#0,-2(a2)
	subq.w	#1,($FFFFEF80).w

loc_17010:
	dbf	d1,loc_16FE8

loc_17014:
	movea.l	(Ring_start_addr_ROM).w,a1
	movea.w	(Ring_start_addr_RAM).w,a2
	move.w	(Camera_X_pos).w,d4
	subq.w	#8,d4
	bhi.s	loc_17028
	moveq	#1,d4
	bra.s	loc_17028
; ===========================================================================

loc_17024:
	addq.w	#4,a1
	addq.w	#2,a2

loc_17028:
	cmp.w	(a1),d4
	bhi.s	loc_17024
	bra.s	loc_17032
; ===========================================================================

loc_17030:
	subq.w	#4,a1
	subq.w	#2,a2

loc_17032:
	cmp.w	-4(a1),d4
	bls.s	loc_17030
	move.l	a1,(Ring_start_addr_ROM).w
	move.w	a2,(Ring_start_addr_RAM).w
	tst.w	(Two_player_mode).w
	bne.s	+
	move.w	a2,(Ring_start_addr_RAM_P2).w
+
	movea.l	(Ring_end_addr_ROM).w,a2
	addi.w	#$150,d4
	bra.s	loc_1704A
; ===========================================================================

loc_17046:
	addq.w	#4,a2

loc_1704A:
	cmp.w	(a2),d4
	bhi.s	loc_17046
	bra.s	loc_17054
; ===========================================================================

loc_17052:
	subq.w	#4,a2

loc_17054:
	cmp.w	-4(a2),d4
	bls.s	loc_17052
	move.l	a2,(Ring_end_addr_ROM).w
	tst.w	(Two_player_mode).w
	bne.s	loc_1706E
	move.l	a1,(Ring_start_addr_ROM_P2).w
	move.l	a2,(Ring_end_addr_ROM_P2).w
	rts
; ===========================================================================

loc_1706E:
	movea.l	(Ring_start_addr_ROM_P2).w,a1
	movea.w	(Ring_start_addr_RAM_P2).w,a2
	move.w	($FFFFEE20).w,d4
	subq.w	#8,d4
	bhi.s	loc_17082
	moveq	#1,d4
	bra.s	loc_17082
; ===========================================================================

loc_1707E:
	addq.w	#4,a1
	addq.w	#2,a2

loc_17082:
	cmp.w	(a1),d4
	bhi.s	loc_1707E
	bra.s	loc_1708C
; ===========================================================================

loc_1708A:
	subq.w	#4,a1
	subq.w	#2,a2

loc_1708C:
	cmp.w	-4(a1),d4
	bls.s	loc_1708A
	move.l	a1,(Ring_start_addr_ROM_P2).w
	move.w	a2,(Ring_start_addr_RAM_P2).w
	movea.l	(Ring_end_addr_ROM_P2).w,a2
	addi.w	#$150,d4
	bra.s	loc_170A4
; ===========================================================================

loc_170A0:
	addq.w	#4,a2

loc_170A4:
	cmp.w	(a2),d4
	bhi.s	loc_170A0
	bra.s	loc_170AE
; ===========================================================================

loc_170AC:
	subq.w	#4,a2

loc_170AE:
	cmp.w	-4(a2),d4
	bls.s	loc_170AC
	move.l	a2,(Ring_end_addr_ROM_P2).w
	rts
; ===========================================================================

Touch_Rings:
	movea.l	(Ring_start_addr_ROM).w,a1
	movea.l	(Ring_end_addr_ROM).w,a2
	cmpa.w	#MainCharacter,a0
	beq.s	loc_170D0
	movea.l	(Ring_start_addr_ROM_P2).w,a1
	movea.l	(Ring_end_addr_ROM_P2).w,a2

loc_170D0:
	cmpa.l	a1,a2
	beq.w	return_17166
	movea.w	(Ring_start_addr_RAM).w,a4
	cmpa.w	#MainCharacter,a0
	beq.s	+
	movea.w	(Ring_start_addr_RAM_P2).w,a4
+	move.b	status2(a0),d0			; get the secondary status
	andi.b	#shield_mask,d0				; get shield type
	cmpi.b	#shield_lightning,d0			; is it a lightning shield?
	bne.s	Touch_Rings_NoAttraction		; if not, do not attract rings
	move.w	x_pos(a0),d2
	move.w	y_pos(a0),d3
	subi.w	#$40,d2
	subi.w	#$40,d3
	move.w	#6,d1
	move.w	#$C,d6
	move.w	#$80,d4
	move.w	#$80,d5
	bra.s	loc_17112
+

	rts
; ===========================================================================

Touch_Rings_NoAttraction:
	move.w	x_pos(a0),d2
	move.w	y_pos(a0),d3
	subi.w	#8,d2
	moveq	#0,d5
	move.b	height_pixels(a0),d5
	lsr.b	#1,d5
	subq.b	#3,d5
	sub.w	d5,d3
	cmpi.b	#$4D,mapping_frame(a0)
	bne.s	+
	addi.w	#$C,d3
	moveq	#$A,d5
+
	move.w	#6,d1
	move.w	#$C,d6
	move.w	#$10,d4
	add.w	d5,d5

loc_17112:
	tst.w	(a4)
	bne.w	loc_1715C
	move.w	(a1),d0
	sub.w	d1,d0
	sub.w	d2,d0
	bcc.s	loc_1712A
	add.w	d6,d0
	bcs.s	loc_17130
	bra.w	loc_1715C
; ===========================================================================

loc_1712A:
	cmp.w	d4,d0
	bhi.w	loc_1715C

loc_17130:
	move.w	2(a1),d0
	sub.w	d1,d0
	sub.w	d3,d0
	bcc.s	loc_17142
	add.w	d6,d0
	bcs.s	loc_17148
	bra.w	loc_1715C
; ===========================================================================

loc_17142:
	cmp.w	d5,d0
	bhi.w	loc_1715C

loc_17148:
	move.b	status2(a0),d0			; get the secondary status
	andi.b	#shield_mask,d0				; get shield type
	cmpi.b	#shield_lightning,d0			; is it a lightning shield?
	beq.s	AttractRing				; if so, attract the ring

loc_17148_cont:
	move.w	#$604,(a4)
	bsr.s	loc_17168
	lea	($FFFFEF82).w,a3

loc_17152:
	tst.w	(a3)+
	bne.s	loc_17152
	move.w	a4,-(a3)
	addq.w	#1,($FFFFEF80).w

loc_1715C:
	addq.w	#4,a1
	addq.w	#2,a4
	cmpa.l	a1,a2
	bne.w	loc_17112

return_17166:
	rts
; ===========================================================================

loc_17168:
	subq.w	#1,(Perfect_rings_left).w
	;cmpa.w	#MainCharacter,a0
	jmp	CollectRing_Sonic

	;bra.w	CollectRing_Tails
; ===========================================================================

AttractRing:
	movea.l	a1,a3
	jsr	SingleObjLoad
	bne.w	AttractRing_NoFreeSlot
	move.w	#objroutine(Attracted_Ring),(a1)
	move.w	(a3),x_pos(a1)
	move.w	2(a3),y_pos(a1)
	move.w	a0,parent(a1)
	move.w	#-1,(a4)
	rts
; ===========================================================================

AttractRing_NoFreeSlot:
	movea.l	a3,a1
	bra.s	loc_17148_cont
; ===========================================================================

loc_17178:
	movea.l	(Ring_start_addr_ROM).w,a0
	move.l	(Ring_end_addr_ROM).w,d7
	sub.l	a0,d7
	bne.s	loc_17186
	rts
; ===========================================================================

loc_17186:
	movea.w	(Ring_start_addr_RAM).w,a4
	lea	(Camera_X_pos).w,a3

loc_1718A:
	tst.w	(a4)+
	bmi.w	loc_171EC
	move.w	(a0),d3
	sub.w	(a3),d3
	addi.w	#$80,d3
	move.w	2(a0),d2
	sub.w	4(a3),d2
	andi.w	#$7FF,d2
	addi.w	#8,d2
	bmi.s	loc_171EC
	cmpi.w	#$F0,d2
	bge.s	loc_171EC
	addi.w	#$78,d2
	lea	(off_1736A).l,a1
	moveq	#0,d1
	move.b	-1(a4),d1
	bne.s	loc_171C8
	move.b	(Rings_anim_frame).w,d1

loc_171C8:
	add.w	d1,d1
	adda.w	(a1,d1.w),a1
	move.b	(a1)+,d0
	ext.w	d0
	add.w	d2,d0
	move.w	d0,(a2)+
	move.b	(a1)+,(a2)+
	addq.b	#1,d5
	move.b	d5,(a2)+
	move.w	(a1)+,d0
	addi.w	#$26BC,d0
	move.w	d0,(a2)+
	addq.w	#2,a1
	move.w	(a1)+,d0
	add.w	d3,d0
	move.w	d0,(a2)+

loc_171EC:
	addq.w	#4,a0
	subq.w	#4,d7
	bne.w	loc_1718A
	rts
; ===========================================================================

loc_171F8:
	lea	(Camera_X_pos).w,a3
	move.w	#$78,d6
	movea.l	(Ring_start_addr_ROM).w,a0
	move.l	(Ring_end_addr_ROM).w,d7
	movea.w	(Ring_start_addr_RAM).w,a4
	sub.l	a0,d7
	bne.s	loc_17224
	rts
; ===========================================================================

loc_1720E:
	lea	($FFFFEE20).w,a3
	move.w	#$158,d6
	movea.l	(Ring_start_addr_ROM_P2).w,a0
	move.l	(Ring_end_addr_ROM_P2).w,d7
	movea.w	(Ring_start_addr_RAM_P2).w,a4
	sub.l	a0,d7
	bne.s	loc_17224
	rts
; ===========================================================================

loc_17224:
	tst.w	(a4)+
	bmi.w	loc_17288
	move.w	(a0),d3
	sub.w	(a3),d3
	addi.w	#$80,d3
	move.w	2(a0),d2
	sub.w	4(a3),d2
	andi.w	#$7FF,d2
	addi.w	#$88,d2
	bmi.s	loc_17288
	cmpi.w	#$170,d2
	bge.s	loc_17288
	add.w	d6,d2
	lea	(off_1736A).l,a1
	moveq	#0,d1
	move.b	-1(a4),d1
	bne.s	loc_17260
	move.b	(Rings_anim_frame).w,d1

loc_17260:
	add.w	d1,d1
	adda.w	(a1,d1.w),a1
	move.b	(a1)+,d0
	ext.w	d0
	add.w	d2,d0
	move.w	d0,(a2)+
	move.b	(a1)+,d4
	move.b	byte_17294(pc,d4.w),(a2)+
	addq.b	#1,d5
	move.b	d5,(a2)+
	addq.w	#2,a1
	move.w	(a1)+,d0
	addi.w	#$235E,d0
	move.w	d0,(a2)+
	move.w	(a1)+,d0
	add.w	d3,d0
	move.w	d0,(a2)+

loc_17288:
	addq.w	#4,a0
	subq.w	#4,d7
	bne.w	loc_17224
	rts
; ===========================================================================
; unknown
byte_17294:
	dc.b   0,0	; 1
	dc.b   1,1	; 3
	dc.b   4,4	; 5
	dc.b   5,5	; 7
	dc.b   8,8	; 9
	dc.b   9,9	; 11
	dc.b  $C,$C	; 13
	dc.b  $D,$D	; 15
; ===========================================================================

RingsManager_Setup:
	clearRAM Ring_Positions,Rings_Space
	; d0 = 0
	lea	($FFFFEF80).w,a1
	move.w	#bytesToLcnt($80),d1
-	move.l	d0,(a1)+
	dbf	d1,-

	moveq	#0,d5
	moveq	#0,d0
	move.w	(Current_ZoneAndAct).w,d0
	ror.b	#1,d0
	lsr.w	#6,d0
	lea	(Off_Rings).l,a1
	move.w	(a1,d0.w),d0
	lea	(a1,d0.w),a1
	move.l	a1,(Ring_start_addr_ROM).w
	addq.w	#4,a1
	moveq	#0,d5
	move.w	#(Max_Rings-1),d0
-
	tst.l	(a1)+
	bmi.s	+
	addq.w	#1,d5
	dbf	d0,-
+
	move.w	d5,(Perfect_rings_left).w
	move.w	#0,($FFFFFF42).w	; no idea what this is
	rts
; ===========================================================================
off_1736A:
	dc.w byte_1737A-off_1736A
	dc.w byte_17382-off_1736A; 1
	dc.w byte_1738A-off_1736A; 2
	dc.w byte_17392-off_1736A; 3
	dc.w byte_1739A-off_1736A; 4
	dc.w byte_173A2-off_1736A; 5
	dc.w byte_173AA-off_1736A; 6
	dc.w byte_173B2-off_1736A; 7
byte_1737A:
	dc.b $F8
	dc.b   5	; 1
	dc.b   0	; 2
	dc.b   0	; 3
	dc.b   0	; 4
	dc.b   0	; 5
	dc.b $FF	; 6
	dc.b $F8	; 7
byte_17382:
	dc.b $F8
	dc.b   5	; 1
	dc.b   0	; 2
	dc.b   4	; 3
	dc.b   0	; 4
	dc.b   2	; 5
	dc.b $FF	; 6
	dc.b $F8	; 7
byte_1738A:
	dc.b $F8
	dc.b   1	; 1
	dc.b   0	; 2
	dc.b   8	; 3
	dc.b   0	; 4
	dc.b   4	; 5
	dc.b $FF	; 6
	dc.b $FC	; 7
byte_17392:
	dc.b $F8
	dc.b   5	; 1
	dc.b   8	; 2
	dc.b   4	; 3
	dc.b   8	; 4
	dc.b   2	; 5
	dc.b $FF	; 6
	dc.b $F8	; 7
byte_1739A:
	dc.b $F8
	dc.b   5	; 1
	dc.b   0	; 2
	dc.b  $A	; 3
	dc.b   0	; 4
	dc.b   5	; 5
	dc.b $FF	; 6
	dc.b $F8	; 7
byte_173A2:
	dc.b $F8
	dc.b   5	; 1
	dc.b $18	; 2
	dc.b  $A	; 3
	dc.b $18	; 4
	dc.b   5	; 5
	dc.b $FF	; 6
	dc.b $F8	; 7
byte_173AA:
	dc.b $F8
	dc.b   5	; 1
	dc.b   8	; 2
	dc.b  $A	; 3
	dc.b   8	; 4
	dc.b   5	; 5
	dc.b $FF	; 6
	dc.b $F8	; 7
byte_173B2:
	dc.b $F8
	dc.b   5	; 1
	dc.b $10	; 2
	dc.b  $A	; 3
	dc.b $10	; 4
	dc.b   5	; 5
	dc.b $FF	; 6
	dc.b $F8	; 7
	dc.b   0	; 8
	dc.b   0	; 9
; ===========================================================================