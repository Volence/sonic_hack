; ----------------------------------------------------------------------------
; Explosion - An explosion, giving off an animal and 100 points
; ----------------------------------------------------------------------------

Explosion_FromEnemy:
	jsr	SingleObjLoad
	bne.s	Explosion_Alone
	move.w	#objroutine(Animal_From_Badnik),(a1) ; load Animal_From_Badnik (Animal)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	parent(a0),parent(a1)

	jsr	SingleObjLoad
	bne.s	Explosion_Alone
	move.w	#objroutine(Points_Text),id(a1) ; load Points_Text (Points)
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	objoff_3E(a0),d0
	lsr.w	#1,d0
	move.b	d0,mapping_frame(a1)	

Explosion_Alone:
	move.l	#Explosion_MapUnc_21120,mappings(a0)
	move.w	#$5A4,art_tile(a0)
	move.b	#4,render_flags(a0)
	move.w	#$80,priority(a0)
	move.b	#0,collision_response(a0)
	move.b	#$C,width_pixels(a0)
	move.b	#3,anim_frame_duration(a0)
	move.b	#0,mapping_frame(a0)
	move.w	#SndID_Explosion,d0
	jsr	(PlaySound).l
	move.w	#objroutine(Explosion_Main),(a0)

Explosion_Main:
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	+
	move.b	#7,anim_frame_duration(a0)
	addq.b	#1,mapping_frame(a0)
	cmpi.b	#5,mapping_frame(a0)
	beq.w	JmpTo18_DeleteObject
+

JmpTo100_DisplaySprite:
	jmp	DisplaySprite

Animal_From_Badnik_Delete:
	subq.b	#1,(AnimalsCounter+objoff_3E).w
	
JmpTo18_DeleteObject:
	jmp	DeleteObject

JmpTo100_ObjectMoveAndFall:
	jmp	ObjectMoveAndFall

JmpTo100_ObjectMove:
	jmp	ObjectMove

; ===========================================================================
; ----------------------------------------------------------------------------
; Animal and the 100 points from a badnik
; ----------------------------------------------------------------------------
animal_ground_routine_base = objoff_30
animal_ground_x_vel = objoff_32
animal_ground_y_vel = objoff_34
animal_routine = objoff_3A

; ===========================================================================
byte_118CE: zoneOffsetTable 1,2
	zoneTableEntry.b (word_118F0_6 - word_118F0) / 8 ; EHZ
	zoneTableEntry.b (word_118F0_5 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_9 - word_118F0) / 8 ; WFZ
	zoneTableEntry.b (word_118F0_7 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_6 - word_118F0) / 8 ; WZ
	zoneTableEntry.b (word_118F0_5 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_6 - word_118F0) / 8 ; Zone 3
	zoneTableEntry.b (word_118F0_5 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_9 - word_118F0) / 8 ; MTZ
	zoneTableEntry.b (word_118F0_7 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_9 - word_118F0) / 8 ; MTZ
	zoneTableEntry.b (word_118F0_7 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_9 - word_118F0) / 8 ; WFZ
	zoneTableEntry.b (word_118F0_7 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_9 - word_118F0) / 8 ; HTZ
	zoneTableEntry.b (word_118F0_7 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_8 - word_118F0) / 8 ; HPZ
	zoneTableEntry.b (word_118F0_3 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_8 - word_118F0) / 8 ; Zone 9
	zoneTableEntry.b (word_118F0_3 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_2 - word_118F0) / 8 ; OOZ
	zoneTableEntry.b (word_118F0_3 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_8 - word_118F0) / 8 ; MCZ
	zoneTableEntry.b (word_118F0_1 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_B - word_118F0) / 8 ; CNZ
	zoneTableEntry.b (word_118F0_5 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_0 - word_118F0) / 8 ; CPZ
	zoneTableEntry.b (word_118F0_7 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_4 - word_118F0) / 8 ; DEZ
	zoneTableEntry.b (word_118F0_1 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_2 - word_118F0) / 8 ; ARZ
	zoneTableEntry.b (word_118F0_5 - word_118F0) / 8
	zoneTableEntry.b (word_118F0_A - word_118F0) / 8 ; SCZ
	zoneTableEntry.b (word_118F0_1 - word_118F0) / 8
    zoneTableEnd

word_118F0:
Animal_From_Badnikdecl macro	xvel,yvel,mappings
	dc.w xvel
	dc.w yvel
	dc.l mappings
    endm

word_118F0_0: Animal_From_Badnikdecl -$200,-$400,Animal_From_Badnik_MapUnc_11EAC
word_118F0_1: Animal_From_Badnikdecl -$200,-$300,Animal_From_Badnik_MapUnc_11E1C
word_118F0_2: Animal_From_Badnikdecl -$180,-$300,Animal_From_Badnik_MapUnc_11EAC
word_118F0_3: Animal_From_Badnikdecl -$140,-$180,Animal_From_Badnik_MapUnc_11E88
word_118F0_4: Animal_From_Badnikdecl -$1C0,-$300,Animal_From_Badnik_MapUnc_11E64
word_118F0_5: Animal_From_Badnikdecl -$300,-$400,Animal_From_Badnik_MapUnc_11E1C
word_118F0_6: Animal_From_Badnikdecl -$280,-$380,Animal_From_Badnik_MapUnc_11E40
word_118F0_7: Animal_From_Badnikdecl -$280,-$300,Animal_From_Badnik_MapUnc_11E1C
word_118F0_8: Animal_From_Badnikdecl -$200,-$380,Animal_From_Badnik_MapUnc_11E40
word_118F0_9: Animal_From_Badnikdecl -$2C0,-$300,Animal_From_Badnik_MapUnc_11E40
word_118F0_A: Animal_From_Badnikdecl -$140,-$200,Animal_From_Badnik_MapUnc_11E40
word_118F0_B: Animal_From_Badnikdecl -$200,-$300,Animal_From_Badnik_MapUnc_11E40

word_11950:
	dc.w -$440
	dc.w -$400	; 1
	dc.w -$440	; 2
	dc.w -$400	; 3
	dc.w -$440	; 4
	dc.w -$400	; 5
	dc.w -$300	; 6
	dc.w -$400	; 7
	dc.w -$300	; 8
	dc.w -$400	; 9
	dc.w -$180	; 10
	dc.w -$300	; 11
	dc.w -$180	; 12
	dc.w -$300	; 13
	dc.w -$140	; 14
	dc.w -$180	; 15
	dc.w -$1C0	; 16
	dc.w -$300	; 17
	dc.w -$200	; 18
	dc.w -$300	; 19
	dc.w -$280	; 20
	dc.w -$380	; 21
off_1197C:
	dc.l Animal_From_Badnik_MapUnc_11E1C
	dc.l Animal_From_Badnik_MapUnc_11E1C	; 1
	dc.l Animal_From_Badnik_MapUnc_11E1C	; 2
	dc.l Animal_From_Badnik_MapUnc_11EAC	; 3
	dc.l Animal_From_Badnik_MapUnc_11EAC	; 4
	dc.l Animal_From_Badnik_MapUnc_11EAC	; 5
	dc.l Animal_From_Badnik_MapUnc_11EAC	; 6
	dc.l Animal_From_Badnik_MapUnc_11E88	; 7
	dc.l Animal_From_Badnik_MapUnc_11E64	; 8
	dc.l Animal_From_Badnik_MapUnc_11E1C	; 9
	dc.l Animal_From_Badnik_MapUnc_11E40	; 10
word_119A8:
	dc.w  $5A5
	dc.w  $5A5	; 1
	dc.w  $5A5	; 2
	dc.w  $553	; 3
	dc.w  $553	; 4
	dc.w  $573	; 5
	dc.w  $573	; 6
	dc.w  $585	; 7
	dc.w  $593	; 8
	dc.w  $565	; 9
	dc.w  $5B3	; 10
; ===========================================================================

Animal_From_Badnik:
	move.w	#objroutine(Animal_From_Badnik_Main),(a0)
	addq.b	#1,(AnimalsCounter).w
	tst.b	subtype(a0)
	beq.w	Animal_From_Badnik_InitRandom
	moveq	#0,d0
	move.b	subtype(a0),d0
	add.w	d0,d0
	move.b	d0,animal_routine(a0)
	subi.w	#$14,d0
	move.w	word_119A8(pc,d0.w),art_tile(a0)
	add.w	d0,d0
	move.l	off_1197C(pc,d0.w),mappings(a0)
	lea	word_11950(pc),a1
	move.w	(a1,d0.w),animal_ground_x_vel(a0)
	move.w	(a1,d0.w),x_vel(a0)
	move.w	2(a1,d0.w),animal_ground_y_vel(a0)
	move.w	2(a1,d0.w),y_vel(a0)
	move.b	#$18,height_pixels(a0)
	move.b	#4,render_flags(a0)
	bset	#0,render_flags(a0)
	move.w	#$300,priority(a0)
	move.b	#8,width_pixels(a0)
	move.b	#7,anim_frame_duration(a0)
	bra.w	JmpTo100_DisplaySprite

Animal_From_Badnik_InitRandom:
	addq.b	#2,animal_routine(a0)
	jsr	RandomNumber
	move.w	#$580,art_tile(a0)
	andi.w	#1,d0
	beq.s	+
	move.w	#$594,art_tile(a0)
+	moveq	#0,d1
	move.b	(Current_Zone).w,d1
	add.w	d1,d1
	add.w	d0,d1
	lea	byte_118CE(pc),a1
	move.b	(a1,d1.w),d0
	move.b	d0,animal_ground_routine_base(a0)
	lsl.w	#3,d0
	lea	word_118F0(pc),a1
	adda.w	d0,a1
	move.w	(a1)+,animal_ground_x_vel(a0)
	move.w	(a1)+,animal_ground_y_vel(a0)
	move.l	(a1)+,mappings(a0)
	move.b	#$18,height_pixels(a0)
	move.b	#4,render_flags(a0)
	bset	#0,render_flags(a0)
	move.w	#$300,priority(a0)
	move.b	#16,width_pixels(a0)
	move.b	#7,anim_frame_duration(a0)
	move.b	#2,mapping_frame(a0)
	move.w	#-$400,y_vel(a0)
	tst.b	objoff_38(a0)
	beq.s	+
	move.b	#$1C,animal_routine(a0)
	clr.w	x_vel(a0)
+	bra.w	JmpTo100_DisplaySprite
; ===========================================================================
Animal_From_Badnik_Main:
	moveq	#0,d0
	move.b	animal_routine(a0),d0
	move.w	Animal_From_Badnik_States(pc,d0.w),d1
	jmp	Animal_From_Badnik_States(pc,d1.w)
; ===========================================================================
Animal_From_Badnik_States:
	dc.w 0
	dc.w loc_11ADE - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B74 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B74 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B74 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11B38 - Animal_From_Badnik_States
	dc.w loc_11BF4 - Animal_From_Badnik_States
	dc.w loc_11C14 - Animal_From_Badnik_States
	dc.w loc_11C14 - Animal_From_Badnik_States
	dc.w loc_11C34 - Animal_From_Badnik_States
	dc.w loc_11C6E - Animal_From_Badnik_States
	dc.w loc_11CC8 - Animal_From_Badnik_States
	dc.w loc_11CE6 - Animal_From_Badnik_States
	dc.w loc_11CC8 - Animal_From_Badnik_States
	dc.w loc_11CE6 - Animal_From_Badnik_States
	dc.w loc_11CC8 - Animal_From_Badnik_States
	dc.w loc_11D24 - Animal_From_Badnik_States
	dc.w loc_11C8A - Animal_From_Badnik_States
; ===========================================================================

loc_11ADE:
	tst.b	render_flags(a0)
	bpl.w	Animal_From_Badnik_Delete
	bsr.w	JmpTo100_ObjectMoveAndFall
	tst.w	y_vel(a0)
	bmi.s	+
	jsr	(ObjCheckFloorDist).l
	tst.w	d1
	bpl.s	+
	add.w	d1,y_pos(a0)
	move.w	animal_ground_x_vel(a0),x_vel(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
	move.b	#1,mapping_frame(a0)
	move.b	animal_ground_routine_base(a0),d0
	add.b	d0,d0
	addq.b	#4,d0
	move.b	d0,animal_routine(a0)
	tst.b	objoff_38(a0)
	beq.s	+
	btst	#4,(Vint_runcount+3).w
	beq.s	+
	neg.w	x_vel(a0)
	bchg	#0,render_flags(a0)
+	bra.w	JmpTo100_DisplaySprite
; ===========================================================================

loc_11B38:

	bsr.w	JmpTo100_ObjectMoveAndFall
	move.b	#1,mapping_frame(a0)
	tst.w	y_vel(a0)
	bmi.s	+
	move.b	#0,mapping_frame(a0)
	jsr	(ObjCheckFloorDist).l
	tst.w	d1
	bpl.s	+
	add.w	d1,y_pos(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
+
	tst.b	subtype(a0)
	bne.s	loc_11BD8
	tst.b	render_flags(a0)
	bpl.w	Animal_From_Badnik_Delete
	bra.w	JmpTo100_DisplaySprite
; ===========================================================================

loc_11B74:

	bsr.w	JmpTo100_ObjectMove
	addi.w	#$18,y_vel(a0)
	tst.w	y_vel(a0)
	bmi.s	+
	jsr	(ObjCheckFloorDist).l
	tst.w	d1
	bpl.s	+
	add.w	d1,y_pos(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
	tst.b	subtype(a0)
	beq.s	+
	cmpi.b	#$A,subtype(a0)
	beq.s	+
	neg.w	x_vel(a0)
	bchg	#0,render_flags(a0)
+
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	+
	move.b	#1,anim_frame_duration(a0)
	addq.b	#1,mapping_frame(a0)
	andi.b	#1,mapping_frame(a0)
+
	tst.b	subtype(a0)
	bne.s	loc_11BD8
	tst.b	render_flags(a0)
	bpl.w	Animal_From_Badnik_Delete
	bra.w	JmpTo100_DisplaySprite
; ===========================================================================

loc_11BD8:

	move.w	x_pos(a0),d0
	sub.w	(MainCharacter+x_pos).w,d0
	bcs.s	+
	subi.w	#$180,d0
	bpl.s	+
	tst.b	render_flags(a0)
	bpl.w	Animal_From_Badnik_Delete
+	bra.w	JmpTo100_DisplaySprite
; ===========================================================================

loc_11BF4:
	tst.b	render_flags(a0)
	bpl.w	Animal_From_Badnik_Delete
	subq.w	#1,objoff_36(a0)
	bne.w	+
	move.b	#2,animal_routine(a0)
	move.w	#$80,priority(a0)
+	bra.w	JmpTo100_DisplaySprite
; ===========================================================================

loc_11C14:
	bsr.w	sub_11DB8
	bcc.s	+
	move.w	animal_ground_x_vel(a0),x_vel(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
	move.b	#$E,animal_routine(a0)
	bra.w	loc_11B74
; ===========================================================================
+	bra.w	loc_11BD8
; ===========================================================================

loc_11C34:
	bsr.w	sub_11DB8
	bpl.s	+
	clr.w	x_vel(a0)
	clr.w	animal_ground_x_vel(a0)
	bsr.w	JmpTo100_ObjectMove
	addi.w	#$18,y_vel(a0)
	bsr.w	sub_11D78
	bsr.w	sub_11DA0
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	+
	move.b	#1,anim_frame_duration(a0)
	addq.b	#1,mapping_frame(a0)
	andi.b	#1,mapping_frame(a0)
+	bra.w	loc_11BD8
; ===========================================================================

loc_11C6E:
	bsr.w	sub_11DB8
	bpl.s	++
	move.w	animal_ground_x_vel(a0),x_vel(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
	move.b	#4,animal_routine(a0)
	bra.w	loc_11B38
; ===========================================================================

loc_11C8A:
	bsr.w	JmpTo100_ObjectMoveAndFall
	move.b	#1,mapping_frame(a0)
	tst.w	y_vel(a0)
	bmi.s	++
	move.b	#0,mapping_frame(a0)
	jsr	(ObjCheckFloorDist).l
	tst.w	d1
	bpl.s	++
	not.b	objoff_29(a0)
	bne.s	+
	neg.w	x_vel(a0)
	bchg	#0,render_flags(a0)
+
	add.w	d1,y_pos(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
+	bra.w	loc_11BD8
; ===========================================================================

loc_11CC8:
	bsr.w	sub_11DB8
	bpl.s	+
	clr.w	x_vel(a0)
	clr.w	animal_ground_x_vel(a0)
	bsr.w	JmpTo100_ObjectMoveAndFall
	bsr.w	sub_11D78
	bsr.w	sub_11DA0
+	bra.w	loc_11BD8
; ===========================================================================

loc_11CE6:
	bsr.w	sub_11DB8
	bpl.s	+
	bsr.w	JmpTo100_ObjectMoveAndFall
	move.b	#1,mapping_frame(a0)
	tst.w	y_vel(a0)
	bmi.s	+
	move.b	#0,mapping_frame(a0)
	jsr	(ObjCheckFloorDist).l
	tst.w	d1
	bpl.s	+
	neg.w	x_vel(a0)
	bchg	#0,render_flags(a0)
	add.w	d1,y_pos(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
+	bra.w	loc_11BD8
; ===========================================================================

loc_11D24:
	bsr.w	sub_11DB8
	bpl.s	+++
	bsr.w	JmpTo100_ObjectMove
	addi.w	#$18,y_vel(a0)
	tst.w	y_vel(a0)
	bmi.s	++
	jsr	(ObjCheckFloorDist).l
	tst.w	d1
	bpl.s	++
	not.b	objoff_29(a0)
	bne.s	+
	neg.w	x_vel(a0)
	bchg	#0,render_flags(a0)
+
	add.w	d1,y_pos(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
+
	subq.b	#1,anim_frame_duration(a0)
	bpl.s	+
	move.b	#1,anim_frame_duration(a0)
	addq.b	#1,mapping_frame(a0)
	andi.b	#1,mapping_frame(a0)
+	bra.w	loc_11BD8

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_11D78:

	move.b	#1,mapping_frame(a0)
	tst.w	y_vel(a0)
	bmi.s	+	; rts
	move.b	#0,mapping_frame(a0)
	jsr	(ObjCheckFloorDist).l
	tst.w	d1
	bpl.s	+	; rts
	add.w	d1,y_pos(a0)
	move.w	animal_ground_y_vel(a0),y_vel(a0)
+	rts
; End of function sub_11D78


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_11DA0:

	bset	#0,render_flags(a0)
	move.w	x_pos(a0),d0
	sub.w	(MainCharacter+x_pos).w,d0
	bcc.s	+	; rts
	bclr	#0,render_flags(a0)
+	rts
; End of function sub_11DA0


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


sub_11DB8:

	move.w	(MainCharacter+x_pos).w,d0
	sub.w	x_pos(a0),d0
	subi.w	#$B8,d0
	rts
; End of function sub_11DB8

; ===========================================================================
; ----------------------------------------------------------------------------
; "100 points" text
; ----------------------------------------------------------------------------

Points_Text:
	move.l	#Points_Text_MapUnc_11ED0,mappings(a0)
	move.w	#$84AC,art_tile(a0)
	move.b	#4,render_flags(a0)
	move.w	#$80,priority(a0)
	move.b	#16,width_pixels(a0)
	move.w	#-$300,y_vel(a0)	; set initial speed (upwards)
	move.w	#objroutine(Points_Text_Main),(a0)

Points_Text_Main:
	tst.w	y_vel(a0)		; test speed
	bpl.w	JmpTo18_DeleteObject	; if it's positive (>= 0), delete the object
	bsr.w	JmpTo100_ObjectMove	; move the points
	addi.w	#$18,y_vel(a0)		; slow down
	bra.w	JmpTo100_DisplaySprite
