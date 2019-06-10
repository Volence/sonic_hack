; ----------------------------------------------------------------------------
; Knuckles
; ----------------------------------------------------------------------------
	;Knuckles_Init	; 0
	;Knuckles_Control	; 2
	;Knuckles_Hurt	; 4
	;Knuckles_Dead	; 6
	;Knuckles_Gone	; 8
	;Knuckles_Respawning	; $A
; ===========================================================================
Knuckles:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
		move.w	#objroutine(Knuckles_Control),(a0)
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		move.l	#Map_Knux,mappings(a0)
		move.w	#$100,priority(a0)
		move.b	#$18,width_pixels(a0)
		move.b	#4,render_flags(a0)
		move.w	#$600,($FFFFF760).w
		move.w	#$C,($FFFFF762).w
		move.w	#$80,($FFFFF764).w ; '�'
		tst.b	($FFFFFE30).w
		bne.s	loc_9537C
		cmpi.w	#$6,($FFFFFF72).w
		beq.w	KnucklesArtSwitch
		move.w	#$780,art_tile(a0)
		bra.w	Knuckles_ArtEnd
KnucklesArtSwitch:
		move.w	#$2560,art_tile(a0)
Knuckles_ArtEnd:
		move.b	#$C,layer(a0)
		move.b	#$D,layer_plus(a0)
		move.w	x_pos(a0),($FFFFFE32).w
		move.w	y_pos(a0),($FFFFFE34).w
		move.w	art_tile(a0),($FFFFFE3C).w
		move.w	layer(a0),($FFFFFE3E).w

loc_9537C:
		move.b	#0,flips_remaining(a0)
		move.b	#4,flip_speed(a0)
		move.b	#0,($FFFFFE19).w
		move.b	#$1E,air_left(a0)
		subi.w	#$20,x_pos(a0) ; ' '
		addi.w	#4,y_pos(a0)
		move.w	#0,($FFFFEED2).w
		move.w	#$3F,d2	; '?'

loc_953AA:
		bsr.w	sub_954FA
		subq.w	#4,a1
		move.l	#0,(a1)
		dbf	d2,loc_953AA
		addi.w	#$20,x_pos(a0) ; ' '
		subi.w	#4,y_pos(a0)

Knuckles_Control:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	;tst.w	(Debug_mode_flag).w	; is debug cheat enabled?
	;beq.s	loc_953E0			; if not, branch
	btst	#button_B,(Ctrl_1_Press).w	; is button B pressed?
	beq.s	loc_953E0			; if not, branch
	move.w	#1,(Debug_placement_mode).w	; change Sonic into a ring/item
	clr.b	(Control_Locked).w		; unlock control
	rts
; ===========================================================================

loc_953E0:									; Knuckles_Init+C6j
		tst.b	($FFFFF7CC).w
		bne.s	loc_953EC
		move.w	($FFFFF604).w,($FFFFF602).w

loc_953EC:
		btst	#s3b_lock_motion,status3(a0)
		beq.s	loc_953FC
		move.b	#0,air_action(a0)
		bra.s	loc_9540E
; ===========================================================================

loc_953FC:
		moveq	#0,d0
		move.b	status(a0),d0
		andi.w	#6,d0
		move.w	off_9545C(pc,d0.w),d1
		jsr	off_9545C(pc,d1.w)

loc_9540E:
		cmpi.w	#$FF00,($FFFFEECC).w
		bne.s	loc_9541C
		andi.w	#$7FF,y_pos(a0)

loc_9541C:
		bsr.w	Player_Display
		bsr.w	sub_965F0
		bsr.w	sub_954FA
		bsr.w	Player_Water
		move.b	($FFFFF768).w,next_tilt(a0)
		move.b	($FFFFF76A).w,tilt(a0)
		tst.b	($FFFFF7C7).w
		beq.s	loc_95448
		tst.b	anim(a0)
		bne.s	loc_95448
		move.b	next_anim(a0),anim(a0)

loc_95448:
					; Knuckles_Init+134j
		bsr.w	Knuckles_Animate
		btst	#s3b_lock_jumping,status3(a0)
		bne.s	loc_95458
		jsr	(TouchResponse).l

loc_95458:
		bra.w	LoadKnucklesDynPLC
; End of function Knuckles_Init

; ===========================================================================
off_9545C:	dc.w loc_9560C-off_9545C ; DATA	XREF: ROM:off_9545Co
					; ROM:0009545Eo ...
		dc.w loc_95634-off_9545C
		dc.w loc_95D5A-off_9545C
		dc.w loc_95D80-off_9545C
; ===========================================================================
; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_954FA:
					; Knuckles_Init+116p ...
		move.w	($FFFFEED2).w,d0
		lea	($FFFFE500).w,a1
		lea	(a1,d0.w),a1
		move.w	x_pos(a0),(a1)+
		move.w	y_pos(a0),(a1)+
		addq.b	#4,($FFFFEED3).w
		lea	($FFFFE400).w,a1
		lea	(a1,d0.w),a1
		move.w	($FFFFF602).w,(a1)+
		move.w	status(a0),(a1)+
		rts
; End of function sub_954FA
; ===========================================================================

loc_9560C:
		bsr.w	sub_96688
		bsr.w	sub_963FC
		bsr.w	sub_967E0
		bsr.w	sub_95DAA
		bsr.w	sub_96396
		bsr.w	sub_96336
		jsr	ObjectMove
		bsr.w	sub_97652
		bsr.w	sub_96852
		rts
; ===========================================================================

loc_95634:
		tst.b	air_action(a0)
		bne.s	loc_95664
		bsr.w	sub_964B4
		bsr.w	sub_9628E
		bsr.w	sub_96336
		jsr	ObjectMoveAndFall
		btst	#6,status(a0)
		beq.s	loc_9565A
		subi.w	#$28,y_vel(a0) ; '('

loc_9565A:
		bsr.w	sub_96894
		bsr.w	sub_96A9E
		rts
; ===========================================================================

loc_95664:
		bsr.w	sub_95C88
		bsr.w	sub_96336
		jsr	ObjectMove
		bsr.w	sub_95678
; START	OF FUNCTION CHUNK FOR sub_95678

locret_95676:
		rts
; END OF FUNCTION CHUNK	FOR sub_95678

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_95678:

; FUNCTION CHUNK AT 00095676 SIZE 00000002 BYTES
; FUNCTION CHUNK AT 00095BFE SIZE 0000003C BYTES

		move.b	air_action(a0),d0
		beq.s	locret_95676
		cmpi.b	#2,d0
		beq.w	loc_95858
		cmpi.b	#3,d0
		beq.w	loc_958C0
		cmpi.b	#4,d0
		beq.w	loc_95966
		cmpi.b	#5,d0
		beq.w	loc_95BFE
		move.b	#$14,height_pixels(a0)
		move.b	#$14,width_pixels(a0)
		bsr.w	sub_968F4
		btst	#5,($FFFFF7AC).w
		bne.w	loc_9576C
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		btst	#1,($FFFFF7AC).w
		beq.s	loc_9570E
		move.b	($FFFFF602).w,d0
		andi.b	#$70,d0	; 'p'
		bne.s	loc_9570A
		move.b	#2,air_action(a0)
		move.b	#$21,anim(a0) ; '!'
		bclr	#0,status(a0)
		tst.w	x_vel(a0)
		bpl.s	loc_956F4
		bset	#0,status(a0)

loc_956F4:
		asr	x_vel(a0)
		asr	x_vel(a0)
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		rts
; ===========================================================================

loc_9570A:
		bra.w	sub_95C3A
; ===========================================================================

loc_9570E:
		bclr	#0,status(a0)
		tst.w	x_vel(a0)
		bpl.s	loc_95720
		bset	#0,status(a0)

loc_95720:
		move.b	angle(a0),d0
		addi.b	#$20,d0	; ' '
		andi.b	#$C0,d0
		beq.s	loc_9573E
		move.w	inertia(a0),x_vel(a0)
		move.w	#0,y_vel(a0)
		bra.w	sub_96CA0
; ===========================================================================

loc_9573E:
		move.b	#3,air_action(a0)
		move.b	#$CC,mapping_frame(a0)
		move.b	#$7F,anim_frame_duration(a0) ; ''
		move.b	#0,anim_frame(a0)
		cmpi.b	#$C,air_left(a0)
		bcs.s	locret_9576A
		move.b	#6,($FFFFD124).w
		move.b	#$15,($FFFFD11A).w

locret_9576A:
		rts
; ===========================================================================

loc_9576C:
		tst.b	($FFFFF7AD).w
		bmi.w	loc_95838
		move.b	layer_plus(a0),d5
		move.b	knuckles_unk(a0),d0
		addi.b	#$40,d0	; '@'
		bpl.s	loc_95796
		bset	#0,status(a0)
		bsr.w	sub_97658
		or.w	d0,d1
		bne.s	loc_957FA
		addq.w	#1,x_pos(a0)
		bra.s	loc_957A6
; ===========================================================================

loc_95796:
		bclr	#0,status(a0)
		bsr.w	sub_9765E
		or.w	d0,d1
		bne.w	loc_95828

loc_957A6:
					; sub_95678+1ACj
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		tst.b	($FFFFFE19).w
		beq.s	loc_957C2
		cmpi.w	#$480,inertia(a0)
		bcs.s	loc_957C2
		nop

loc_957C2:
					; sub_95678+146j
		move.w	#0,inertia(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.b	#4,air_action(a0)
		move.b	#$B7,mapping_frame(a0)
		move.b	#$7F,anim_frame_duration(a0) ; ''
		move.b	#0,anim_frame(a0)
		move.b	#3,knuckles_unk(a0)
		move.w	x_pos(a0),$A(a0)
        	move.w  #$74,d0		; Change $F5 to whatever ID you set for the sound.
        	jsr    (PlaySound).l	; play sound
    		rts
; ===========================================================================

loc_957FA:
		move.w	x_pos(a0),d3
		move.b	height_pixels(a0),d0
		lsr.b	#1,d0
		ext.w	d0
		sub.w	d0,d3
		subq.w	#1,d3

loc_95808:
		move.w	y_pos(a0),d2
		subi.w	#$B,d2
		jsr	loc_1ED68
		tst.w	d1
		bmi.s	loc_95838
		cmpi.w	#$C,d1
		bcc.s	loc_95838
		add.w	d1,y_pos(a0)
		bra.w	loc_957A6
; ===========================================================================

loc_95828:
		move.w	x_pos(a0),d3
		move.b	height_pixels(a0),d0
		lsr.b	#1,d0
		ext.w	d0
		add.w	d0,d3
		addq.w	#1,d3
		bra.s	loc_95808
; ===========================================================================

loc_95838:
					; sub_95678+1A0j ...
		move.b	#2,air_action(a0)
		move.b	#$21,anim(a0) ; '!'
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		bset	#1,($FFFFF7AC).w
		rts
; ===========================================================================

loc_95858:
		bsr.w	sub_9628E
		addi.w	#$38,y_vel(a0) ; '8'
		btst	#6,status(a0)
		beq.s	loc_95870
		subi.w	#$28,y_vel(a0) ; '('

loc_95870:
		bsr.w	sub_968F4
		btst	#1,($FFFFF7AC).w
		bne.s	locret_958BE
		move.w	#0,inertia(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.b	height_pixels(a0),d0
		lsr.b	#1,d0
		subi.b	#$13,d0
		ext.w	d0
		add.w	d0,y_pos(a0)
		move.b	angle(a0),d0
		addi.b	#$20,d0	; ' '
		andi.b	#$C0,d0
		beq.s	loc_958AE
		bra.w	sub_96CA0
; ===========================================================================

loc_958AE:
		bsr.w	sub_96CA0
		move.w	#$F,move_lock(a0)
		move.b	#$23,anim(a0) ; '#'

locret_958BE:
		rts
; ===========================================================================

loc_958C0:
		move.b	($FFFFF602).w,d0
		andi.b	#$70,d0	; 'p'
		beq.s	loc_958E4
		tst.w	x_vel(a0)
		bpl.s	loc_958DC
		addi.w	#$20,x_vel(a0) ; ' '
		bmi.s	loc_958DA
		bra.s	loc_958E4
; ===========================================================================

loc_958DA:
		bra.s	loc_95916
; ===========================================================================

loc_958DC:
		subi.w	#$20,x_vel(a0) ; ' '
		bpl.s	loc_95916

loc_958E4:
					; sub_95678+260j
		move.w	#0,inertia(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.b	height_pixels(a0),d0
		lsr.b	#1,d0
		subi.b	#$13,d0
		ext.w	d0
		add.w	d0,y_pos(a0)
		bsr.w	sub_96CA0
		move.w	#$F,move_lock(a0)
		move.b	#$22,anim(a0) ; '"'
		rts
; ===========================================================================

loc_95916:
					; sub_95678+26Aj
		move.b	#$14,height_pixels(a0)
		move.b	#$14,width_pixels(a0)
		bsr.w	sub_968F4
		bsr.w	sub_97664
		cmpi.w	#$E,d1
		bge.s	loc_95946
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		rts
; ===========================================================================

loc_95946:
		move.b	#2,air_action(a0)
		move.b	#$21,anim(a0) ; '!'
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		bset	#1,($FFFFF7AC).w
		rts
; ===========================================================================

loc_95966:
		tst.b	($FFFFF7AD).w
		bmi.w	loc_95B6C
		move.w	x_pos(a0),d0
		cmp.w	$A(a0),d0
		bne.w	loc_95B6C
		btst	#3,status(a0)
		bne.w	loc_95B6C
		move.w	#0,inertia(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.l	#$FFFFD600,($FFFFF796).w
		cmpi.b	#$D,layer_plus(a0)
		beq.s	loc_959AE
		move.l	#$FFFFD900,($FFFFF796).w

loc_959AE:
		move.b	layer_plus(a0),d5
		move.b	#$14,height_pixels(a0)
		move.b	#$14,width_pixels(a0)
		moveq	#0,d1
		btst	#0,($FFFFF602).w
		beq.w	loc_95A34
		move.w	y_pos(a0),d2
		subi.w	#$B,d2
		bsr.w	sub_95BE0
		cmpi.w	#4,d1
		bge.w	loc_95B54
		tst.w	d1
		bne.w	loc_95AEE
		move.b	layer_plus(a0),d5
		move.w	y_pos(a0),d2
		subq.w	#8,d2
		move.w	x_pos(a0),d3
		bsr.w	sub_9766A
		tst.w	d1
		bpl.s	loc_95A04
		sub.w	d1,y_pos(a0)
		moveq	#1,d1
		bra.w	loc_95AC2
; ===========================================================================

loc_95A04:
		subq.w	#1,y_pos(a0)
		tst.b	($FFFFFE19).w
		beq.s	loc_95A12
		subq.w	#1,y_pos(a0)

loc_95A12:
		moveq	#1,d1
		move.w	($FFFFEECC).w,d0
		cmpi.w	#$FF00,d0
		beq.w	loc_95AC2
		addi.w	#$10,d0
		cmp.w	y_pos(a0),d0
		ble.w	loc_95AC2
		move.w	d0,y_pos(a0)
		bra.w	loc_95AC2
; ===========================================================================

loc_95A34:
		btst	#1,($FFFFF602).w
		beq.w	loc_95AC2
		cmpi.b	#$BD,mapping_frame(a0)
		bne.s	loc_95A60
		move.b	#$B7,mapping_frame(a0)
		addq.w	#3,y_pos(a0)
		subq.w	#3,x_pos(a0)
		btst	#0,status(a0)
		beq.s	loc_95A60
		addq.w	#6,x_pos(a0)

loc_95A60:
					; sub_95678+3E2j
		move.w	y_pos(a0),d2
		addi.w	#$B,d2
		bsr.w	sub_95BE0
		tst.w	d1
		bne.w	loc_95B6C
		move.b	layer(a0),d5
		move.w	y_pos(a0),d2
		addi.w	#9,d2
		move.w	x_pos(a0),d3
		bsr.w	sub_97670
		tst.w	d1
		bpl.s	loc_95AB2
		add.w	d1,y_pos(a0)
		move.b	($FFFFF768).w,angle(a0)
		move.w	#0,inertia(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		bsr.w	sub_96CA0
		move.b	#5,anim(a0)
		rts
; ===========================================================================

loc_95AB2:
		addq.w	#1,y_pos(a0)
		tst.b	($FFFFFE19).w
		beq.s	loc_95AC0
		addq.w	#1,y_pos(a0)

loc_95AC0:
		moveq	#-$1,d1

loc_95AC2:
					; sub_95678+3A4j ...
		tst.w	d1
		beq.s	loc_95AEE
		subq.b	#1,knuckles_unk(a0)
		bpl.s	loc_95AEE
		move.b	#3,knuckles_unk(a0)
		add.b	mapping_frame(a0),d1
		cmpi.b	#$B7,d1
		bcc.s	loc_95AE0
		move.b	#$BC,d1

loc_95AE0:
		cmpi.b	#$BC,d1
		bls.s	loc_95AEA
		move.b	#$B7,d1

loc_95AEA:
		move.b	d1,mapping_frame(a0)

loc_95AEE:
					; sub_95678+44Cj ...
		move.b	#$20,anim_frame_duration(a0) ; ' '
		move.b	#0,anim_frame(a0)
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		move.w	($FFFFF602).w,d0
		andi.w	#$70,d0	; 'p'
		beq.s	locret_95B52
		move.w	#$FC80,y_vel(a0)
		move.w	#$400,x_vel(a0)
		bchg	#0,status(a0)
		bne.s	loc_95B28
		neg.w	x_vel(a0)

loc_95B28:
		bset	#1,status(a0)
		bset	#s3b_jumping,status3(a0)
		move.b	#$1C,height_pixels(a0)
		move.b	#14,width_pixels(a0)
		move.b	#2,anim(a0)
		bset	#2,status(a0)
		move.b	#0,air_action(a0)

locret_95B52:
		rts
; ===========================================================================

loc_95B54:
		move.b	#5,air_action(a0)
		cmpi.b	#$BD,mapping_frame(a0)
		beq.s	locret_95B6A
		move.b	#0,knuckles_unk(a0)
		bsr.s	sub_95B98

locret_95B6A:
		rts
; ===========================================================================

loc_95B6C:
					; sub_95678+2FEj ...
		move.b	#2,air_action(a0)
		move.w	#$2121,anim(a0)
		move.b	#$CB,mapping_frame(a0)
		move.b	#7,anim_frame_duration(a0)
		move.b	#1,anim_frame(a0)
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		rts
; End of function sub_95678


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_95B98:
					; sub_95678+58Cp
		moveq	#0,d0
		move.b	knuckles_unk(a0),d0
		lea	word_95BD0(pc,d0.w),a1
		move.b	(a1)+,mapping_frame(a0)
		move.b	(a1)+,d0
		ext.w	d0
		btst	#0,status(a0)
		beq.s	loc_95BB4
		neg.w	d0

loc_95BB4:
		add.w	d0,x_pos(a0)
		move.b	(a1)+,d1
		ext.w	d1
		add.w	d1,y_pos(a0)
		move.b	(a1)+,anim_frame_duration(a0)
		addq.b	#4,knuckles_unk(a0)
		move.b	#0,anim_frame(a0)
		rts
; End of function sub_95B98

; ===========================================================================
word_95BD0:	dc.w $BD03
		dc.w $FD06
		dc.w $BE08
		dc.w $F606
		dc.w $BFF8
		dc.w $F406
		dc.w $D208
		dc.w $FB06

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_95BE0:
					; sub_95678+3F0p

; FUNCTION CHUNK AT 00097676 SIZE 00000004 BYTES
; FUNCTION CHUNK AT 0009767C SIZE 00000004 BYTES
; FUNCTION CHUNK AT 000976E6 SIZE 0000002A BYTES
; FUNCTION CHUNK AT 00097716 SIZE 0000000E BYTES

		move.b	layer_plus(a0),d5
		btst	#0,status(a0)
		bne.s	loc_95BF4
		move.w	x_pos(a0),d3
		bra.w	loc_97676
; ===========================================================================

loc_95BF4:
		move.w	x_pos(a0),d3
		subq.w	#1,d3
		bra.w	loc_9767C
; End of function sub_95BE0

; ===========================================================================
; START	OF FUNCTION CHUNK FOR sub_95678

loc_95BFE:
		tst.b	anim_frame_duration(a0)
		bne.s	locret_95C38
		bsr.w	sub_95B98
		cmpi.b	#$10,knuckles_unk(a0)
		bne.s	locret_95C38
		move.w	#0,inertia(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		btst	#0,status(a0)
		beq.s	loc_95C2E
		subq.w	#1,x_pos(a0)

loc_95C2E:
		bsr.w	sub_96CA0
		move.b	#5,anim(a0)

locret_95C38:
					; sub_95678+596j
		rts
; END OF FUNCTION CHUNK	FOR sub_95678

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_95C3A:
					; sub_964B4+D8p
		move.b	#$20,anim_frame_duration(a0) ; ' '
		move.b	#0,anim_frame(a0)
		move.w	#$2020,anim(a0)
		bclr	#5,status(a0)
		bclr	#0,status(a0)
		moveq	#0,d0
		move.b	knuckles_unk(a0),d0
		addi.b	#$10,d0
		lsr.w	#5,d0
		move.b	loc_95C80(pc,d0.w),d1
		move.b	d1,mapping_frame(a0)
		cmpi.b	#$C4,d1
		bne.s	locret_95C7E
		bset	#0,status(a0)
		move.b	#$C0,mapping_frame(a0)

locret_95C7E:
		rts
; End of function sub_95C3A

; ===========================================================================

loc_95C80:				; Unsigned Multiply
		mulu.w	d1,d0
		mulu.w	d3,d1		; Unsigned Multiply
		mulu.w	d3,d2		; Unsigned Multiply
		mulu.w	d1,d1		; Unsigned Multiply

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_95C88:
		cmpi.b	#1,air_action(a0)
		bne.w	loc_95D46
		move.w	inertia(a0),d0
		cmpi.w	#$400,d0
		bcc.s	loc_95CA0
		addq.w	#8,d0
		bra.s	loc_95CBA
; ===========================================================================

loc_95CA0:
		cmpi.w	#$1800,d0
		bcc.s	loc_95CBA
		move.b	knuckles_unk(a0),d1
		andi.b	#$7F,d1	; ''
		bne.s	loc_95CBA
		addq.w	#4,d0
		tst.b	($FFFFFE19).w
		beq.s	loc_95CBA
		addq.w	#8,d0

loc_95CBA:
					; sub_95C88+1Cj ...
		move.w	d0,inertia(a0)
		move.b	knuckles_unk(a0),d0
		btst	#2,($FFFFF602).w
		beq.s	loc_95CDA
		cmpi.b	#$80,d0
		beq.s	loc_95CDA
		tst.b	d0
		bpl.s	loc_95CD6
		neg.b	d0

loc_95CD6:
		addq.b	#2,d0
		bra.s	loc_95CF8
; ===========================================================================

loc_95CDA:
					; sub_95C88+46j
		btst	#3,($FFFFF602).w
		beq.s	loc_95CEE
		tst.b	d0
		beq.s	loc_95CEE
		bmi.s	loc_95CEA
		neg.b	d0

loc_95CEA:
		addq.b	#2,d0
		bra.s	loc_95CF8
; ===========================================================================

loc_95CEE:
					; sub_95C88+5Cj
		move.b	d0,d1
		andi.b	#$7F,d1	; ''
		beq.s	loc_95CF8
		addq.b	#2,d0

loc_95CF8:
					; sub_95C88+64j ...
		move.b	d0,knuckles_unk(a0)
		move.b	knuckles_unk(a0),d0
		jsr	(CalcSine).l
		muls.w	inertia(a0),d1
		asr.l	#8,d1
		move.w	d1,x_vel(a0)
		cmpi.w	#$80,y_vel(a0) ; '�'
		blt.s	loc_95D20
		subi.w	#$20,y_vel(a0) ; ' '
		bra.s	loc_95D26
; ===========================================================================

loc_95D20:
		addi.w	#$20,y_vel(a0) ; ' '

loc_95D26:
		move.w	($FFFFEECC).w,d0
		cmpi.w	#$FF00,d0
		beq.w	loc_95D46
		addi.w	#$10,d0
		cmp.w	y_pos(a0),d0
		ble.w	loc_95D46
		asr	x_vel(a0)
		asr	inertia(a0)

loc_95D46:
					; sub_95C88+A6j ...
		cmpi.w	#$60,($FFFFEED8).w ; '`'
		beq.s	locret_95D58
		bcc.s	loc_95D54
		addq.w	#4,($FFFFEED8).w

loc_95D54:
		subq.w	#2,($FFFFEED8).w

locret_95D58:
		rts
; End of function sub_95C88

; ===========================================================================

loc_95D5A:
		btst	#s3b_spindash,status3(a0)
		bne.s	loc_95D64
		bsr.w	sub_963FC

loc_95D64:
		bsr.w	sub_96816
		bsr.w	sub_9616C
		bsr.w	sub_96336
		jsr	ObjectMove
		bsr.w	sub_97652
		bsr.w	sub_96852
		rts
; ===========================================================================

loc_95D80:
		bsr.w	sub_964B4
		bsr.w	sub_9628E
		bsr.w	sub_96336
		jsr	ObjectMoveAndFall
		btst	#6,status(a0)
		beq.s	loc_95DA0
		subi.w	#$28,y_vel(a0) ; '('

loc_95DA0:
		bsr.w	sub_96894
		bsr.w	sub_96A9E
		rts

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_95DAA:
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		move.w	($FFFFF764).w,d4
		tst.b	status2(a0)
		bmi.w	loc_95FC6
		tst.w	move_lock(a0)
		bne.w	loc_95F78
		btst	#2,($FFFFF602).w
		beq.s	loc_95DD2
		bsr.w	sub_96066

loc_95DD2:
		btst	#3,($FFFFF602).w
		beq.s	loc_95DDE
		bsr.w	sub_960EC

loc_95DDE:
		move.b	angle(a0),d0
		addi.b	#$20,d0	; ' '
		andi.b	#$C0,d0
		bne.w	loc_95F78
		tst.w	inertia(a0)
		bne.w	loc_95F78
		bclr	#5,status(a0)
		move.b	#5,anim(a0)
		btst	#3,status(a0)
		beq.w	loc_95EA2
		moveq	#-1,d0
		move.w	interact_obj(a0),d0
		movea.l	d0,a1
		tst.b	$22(a1)
		bmi.w	loc_95F1C
		moveq	#0,d1
		move.b	$19(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#2,d2
		add.w	x_pos(a0),d1
		sub.w	8(a1),d1
		cmpi.w	#2,d1
		blt.s	loc_95E74
		cmp.w	d2,d1
		bge.s	loc_95E46
		bra.w	loc_95F1C
; ===========================================================================

loc_95E46:
		btst	#0,status(a0)
		bne.s	loc_95E58
		move.b	#6,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95E58:
		bclr	#0,status(a0)
		move.b	#0,anim_frame_duration(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95E74:
		btst	#0,status(a0)
		beq.s	loc_95E86
		move.b	#6,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95E86:
		bset	#0,status(a0)
		move.b	#0,anim_frame_duration(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95EA2:
		jsr	ChkFloorEdge
		cmpi.w	#$C,d1
		blt.w	loc_95F1C
		cmpi.b	#3,next_tilt(a0)
		bne.s	loc_95EE6
		btst	#0,status(a0)
		bne.s	loc_95ECA
		move.b	#6,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95ECA:
		bclr	#0,status(a0)
		move.b	#0,anim_frame_duration(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95EE6:
		cmpi.b	#3,tilt(a0)
		bne.s	loc_95F1C
		btst	#0,status(a0)
		beq.s	loc_95F00
		move.b	#6,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95F00:
		bset	#0,status(a0)
		move.b	#0,anim_frame_duration(a0)
		move.b	#4,anim_frame(a0)
		move.w	#$606,anim(a0)
		bra.w	loc_95F78
; ===========================================================================

loc_95F1C:
					; sub_95DAA+98j ...
		btst	#0,($FFFFF602).w
		beq.s	loc_95F4A
		move.b	#7,anim(a0)
		addq.w	#1,($FFFFF66C).w
		cmpi.w	#$78,($FFFFF66C).w ; 'x'
		bcs.s	loc_95F7E
		move.w	#$78,($FFFFF66C).w ; 'x'
		cmpi.w	#$C8,($FFFFEED8).w ; '�'
		beq.s	loc_95F90
		addq.w	#2,($FFFFEED8).w
		bra.s	loc_95F90
; ===========================================================================

loc_95F4A:
		btst	#1,($FFFFF602).w
		beq.s	loc_95F78
		move.b	#8,anim(a0)
		addq.w	#1,($FFFFF66C).w
		cmpi.w	#$78,($FFFFF66C).w ; 'x'
		bcs.s	loc_95F7E
		move.w	#$78,($FFFFF66C).w ; 'x'
		cmpi.w	#8,($FFFFEED8).w
		beq.s	loc_95F90
		subq.w	#2,($FFFFEED8).w
		bra.s	loc_95F90
; ===========================================================================

loc_95F78:
					; sub_95DAA+40j ...
		move.w	#0,($FFFFF66C).w

loc_95F7E:
					; sub_95DAA+1B8j
		cmpi.w	#$60,($FFFFEED8).w ; '`'
		beq.s	loc_95F90
		bcc.s	loc_95F8C
		addq.w	#4,($FFFFEED8).w

loc_95F8C:
		subq.w	#2,($FFFFEED8).w

loc_95F90:
					; sub_95DAA+19Ej ...
		tst.b	(Super_Tails_flag).w
		beq.s	loc_95F9A
		move.w	#$C,d5

loc_95F9A:
		move.b	($FFFFF602).w,d0
		andi.b	#$C,d0
		bne.s	loc_95FC6
		move.w	inertia(a0),d0
		beq.s	loc_95FC6
		bmi.s	loc_95FBA
		sub.w	d5,d0
		bcc.s	loc_95FB4
		move.w	#0,d0

loc_95FB4:
		move.w	d0,inertia(a0)
		bra.s	loc_95FC6
; ===========================================================================

loc_95FBA:
		add.w	d5,d0
		bcc.s	loc_95FC2
		move.w	#0,d0

loc_95FC2:
		move.w	d0,inertia(a0)

loc_95FC6:
					; sub_95DAA+1F8j ...
		move.b	angle(a0),d0
		jsr	(CalcSine).l
		muls.w	inertia(a0),d1
		asr.l	#8,d1
		move.w	d1,x_vel(a0)
		muls.w	inertia(a0),d0
		asr.l	#8,d0
		move.w	d0,y_vel(a0)
; End of function sub_95DAA

; START	OF FUNCTION CHUNK FOR sub_9616C

loc_95FE4:
		move.b	angle(a0),d0
		addi.b	#$40,d0	; '@'
		bmi.s	locret_96064
		move.b	#$40,d1	; '@'
		tst.w	inertia(a0)
		beq.s	locret_96064
		bmi.s	loc_95FFC
		neg.w	d1

loc_95FFC:
		move.b	angle(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	sub_97682
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_96064
		asl.w	#8,d1
		addi.b	#$20,d0	; ' '
		andi.b	#$C0,d0
		beq.s	loc_96060
		cmpi.b	#$40,d0	; '@'
		beq.s	loc_96046
		cmpi.b	#$80,d0
		beq.s	loc_96040
		add.w	d1,x_vel(a0)
		move.w	#0,inertia(a0)
		btst	#0,status(a0)
		bne.s	locret_9603E
		bset	#5,status(a0)

locret_9603E:
					; sub_9616C-116j
		rts
; ===========================================================================

loc_96040:
		sub.w	d1,y_vel(a0)
		rts
; ===========================================================================

loc_96046:
		sub.w	d1,x_vel(a0)
		move.w	#0,inertia(a0)
		btst	#0,status(a0)
		beq.s	locret_9603E
		bset	#5,status(a0)
		rts
; ===========================================================================

loc_96060:
		add.w	d1,y_vel(a0)

locret_96064:
					; sub_9616C-176j ...
		rts
; END OF FUNCTION CHUNK	FOR sub_9616C

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96066:
		move.w	inertia(a0),d0
		beq.s	loc_9606E
		bpl.s	loc_960A0

loc_9606E:
		bset	#0,status(a0)
		bne.s	loc_96082
		bclr	#5,status(a0)
		move.b	#1,next_anim(a0)

loc_96082:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_96094
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s	loc_96094
		move.w	d1,d0

loc_96094:
					; sub_96066+2Aj
		move.w	d0,inertia(a0)
		move.b	#0,anim(a0)
		rts
; ===========================================================================

loc_960A0:
		sub.w	d4,d0
		bcc.s	loc_960A8
		move.w	#$FF80,d0

loc_960A8:
		move.w	d0,inertia(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1	; ' '
		andi.b	#$C0,d1
		bne.s	locret_960EA
		cmpi.w	#$400,d0
		blt.s	locret_960EA
		move.b	#$D,anim(a0)
		bclr	#0,status(a0)
		move.w	#$A4,d0	; '�'
		jsr	(PlaySound).l
		cmpi.b	#$C,air_left(a0)
		bcs.s	locret_960EA
		move.b	#6,($FFFFD124).w
		move.b	#$15,($FFFFD11A).w

locret_960EA:
					; sub_96066+58j ...
		rts
; End of function sub_96066


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_960EC:
		move.w	inertia(a0),d0
		bmi.s	loc_96120
		bclr	#0,status(a0)
		beq.s	loc_96106
		bclr	#5,status(a0)
		move.b	#1,next_anim(a0)

loc_96106:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_96114
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_96114
		move.w	d6,d0

loc_96114:
					; sub_960EC+24j
		move.w	d0,inertia(a0)
		move.b	#0,anim(a0)
		rts
; ===========================================================================

loc_96120:
		add.w	d4,d0
		bcc.s	loc_96128
		move.w	#$80,d0	; '�'

loc_96128:
		move.w	d0,inertia(a0)
		move.b	angle(a0),d1
		addi.b	#$20,d1	; ' '
		andi.b	#$C0,d1
		bne.s	locret_9616A
		cmpi.w	#$FC00,d0
		bgt.s	locret_9616A
		move.b	#$D,anim(a0)
		bset	#0,status(a0)
		move.w	#$A4,d0	; '�'
		jsr	(PlaySound).l
		cmpi.b	#$C,air_left(a0)
		bcs.s	locret_9616A
		move.b	#6,($FFFFD124).w
		move.b	#$15,($FFFFD11A).w

locret_9616A:
					; sub_960EC+52j ...
		rts
; End of function sub_960EC


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_9616C:

; FUNCTION CHUNK AT 00095FE4 SIZE 00000082 BYTES

		move.w	($FFFFF760).w,d6
		asl.w	#1,d6
		move.w	($FFFFF762).w,d5
		asr.w	#1,d5
		tst.b	(Super_Tails_flag).w
		beq.s	+
		move.w	#6,d5
+
		move.w	#$20,d4	; ' '
		tst.b	status2(a0)
		bmi.w	loc_96200
		tst.w	move_lock(a0)
		bne.s	loc_961A2
		btst	#2,($FFFFF602).w
		beq.s	loc_96196
		bsr.w	sub_96248

loc_96196:
		btst	#3,($FFFFF602).w
		beq.s	loc_961A2
		bsr.w	sub_9626C

loc_961A2:
					; sub_9616C+30j
		move.w	inertia(a0),d0
		beq.s	loc_961C4
		bmi.s	loc_961B8
		sub.w	d5,d0
		bcc.s	loc_961B2
		move.w	#0,d0

loc_961B2:
		move.w	d0,inertia(a0)
		bra.s	loc_961C4
; ===========================================================================

loc_961B8:
		add.w	d5,d0
		bcc.s	loc_961C0
		move.w	#0,d0

loc_961C0:
		move.w	d0,inertia(a0)

loc_961C4:
					; sub_9616C+4Aj
		tst.w	inertia(a0)
		bne.s	loc_96200
		btst	#s3b_spindash,status3(a0)
		bne.s	loc_961EE
		bclr	#2,status(a0)
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		move.b	#5,anim(a0)
		subq.w	#5,y_pos(a0)
		bra.s	loc_96200
; ===========================================================================

loc_961EE:
		move.w	#$400,inertia(a0)
		btst	#0,status(a0)
		beq.s	loc_96200
		neg.w	inertia(a0)

loc_96200:
					; sub_9616C+5Cj ...
		cmpi.w	#$60,($FFFFEED8).w ; '`'
		beq.s	loc_96212
		bcc.s	loc_9620E
		addq.w	#4,($FFFFEED8).w

loc_9620E:
		subq.w	#2,($FFFFEED8).w

loc_96212:
		move.b	angle(a0),d0
		jsr	(CalcSine).l
		muls.w	inertia(a0),d0
		asr.l	#8,d0
		move.w	d0,y_vel(a0)
		muls.w	inertia(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	loc_96236
		move.w	#$1000,d1

loc_96236:
		cmpi.w	#$F000,d1
		bge.s	loc_96240
		move.w	#$F000,d1

loc_96240:
		move.w	d1,x_vel(a0)
		bra.w	loc_95FE4
; End of function sub_9616C


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96248:
		move.w	inertia(a0),d0
		beq.s	loc_96250
		bpl.s	loc_9625E

loc_96250:
		bset	#0,status(a0)
		move.b	#2,anim(a0)
		rts
; ===========================================================================

loc_9625E:
		sub.w	d4,d0
		bcc.s	loc_96266
		move.w	#$FF80,d0

loc_96266:
		move.w	d0,inertia(a0)
		rts
; End of function sub_96248


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_9626C:
		move.w	inertia(a0),d0
		bmi.s	loc_96280
		bclr	#0,status(a0)
		move.b	#2,anim(a0)
		rts
; ===========================================================================

loc_96280:
		add.w	d4,d0
		bcc.s	loc_96288
		move.w	#$80,d0	; '�'

loc_96288:
		move.w	d0,inertia(a0)
		rts
; End of function sub_9626C


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_9628E:
					; sub_95678:loc_95858p	...
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		asl.w	#1,d5
		btst	#4,status(a0)
		bne.s	loc_962F4
		move.w	x_vel(a0),d0
		btst	#2,($FFFFF602).w
		beq.s	loc_962CC
		bset	#0,status(a0)
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_962CC
		tst.w	($FFFFFFD0).w
		bne.w	loc_962CA
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s	loc_962CC

loc_962CA:
		move.w	d1,d0

loc_962CC:
					; sub_9628E+2Cj ...
		btst	#3,($FFFFF602).w
		beq.s	loc_962F0
		bclr	#0,status(a0)
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_962F0
		tst.w	($FFFFFFD0).w
		bne.w	loc_962EE
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_962F0

loc_962EE:
		move.w	d6,d0

loc_962F0:
					; sub_9628E+50j ...
		move.w	d0,x_vel(a0)

loc_962F4:
		cmpi.w	#$60,($FFFFEED8).w ; '`'
		beq.s	loc_96306
		bcc.s	loc_96302
		addq.w	#4,($FFFFEED8).w

loc_96302:
		subq.w	#2,($FFFFEED8).w

loc_96306:
		cmpi.w	#$FC00,y_vel(a0)
		bcs.s	locret_96334
		move.w	x_vel(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_96334
		bmi.s	loc_96328
		sub.w	d1,d0
		bcc.s	loc_96322
		move.w	#0,d0

loc_96322:
		move.w	d0,x_vel(a0)
		rts
; ===========================================================================

loc_96328:
		sub.w	d1,d0
		bcs.s	loc_96330
		move.w	#0,d0

loc_96330:
		move.w	d0,x_vel(a0)

locret_96334:
					; sub_9628E+88j
		rts
; End of function sub_9628E


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96336:
					; ROM:00095642p ...

; FUNCTION CHUNK AT 0003F926 SIZE 00000050 BYTES

		move.l	x_pos(a0),d1
		move.w	x_vel(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	($FFFFEEC8).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0
		bhi.s	loc_9637E
		move.w	($FFFFEECA).w,d0
		addi.w	#$128,d0
		tst.b	($FFFFF7AA).w
		bne.s	loc_96364
		addi.w	#$40,d0	; '@'

loc_96364:
		cmp.w	d1,d0
		bls.s	loc_9637E

loc_96368:
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	; '�'
		cmp.w	y_pos(a0),d0
		blt.s	loc_96378
		rts
; ===========================================================================

loc_96378:
		jmp	KillCharacter
; ===========================================================================

loc_9637E:
					; sub_96336+30j
		move.w	d0,x_pos(a0)
		move.w	#0,$A(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,inertia(a0)
		bra.s	loc_96368
; End of function sub_96336


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96396:
		tst.b	status2(a0)
		bmi.s	locret_963BC
		move.w	inertia(a0),d0
		bpl.s	loc_963A4
		neg.w	d0

loc_963A4:
		cmpi.w	#$80,d0	; '�'
		bcs.s	locret_963BC
		move.b	($FFFFF602).w,d0
		andi.b	#$C,d0
		bne.s	locret_963BC
		btst	#1,($FFFFF602).w
		bne.s	loc_963BE

locret_963BC:
					; sub_96396+12j ...
		rts
; ===========================================================================

loc_963BE:
		btst	#2,status(a0)
		beq.s	loc_963C8
		rts
; ===========================================================================

loc_963C8:
		bset	#2,status(a0)
		move.b	#$1C,height_pixels(a0)
		move.b	#14,width_pixels(a0)
		move.b	#2,anim(a0)
		addq.w	#5,y_pos(a0)
		move.w	#$BE,d0	; '�'
		jsr	(PlaySound).l
		tst.w	inertia(a0)
		bne.s	locret_963FA
		move.w	#$200,inertia(a0)

locret_963FA:
		rts
; End of function sub_96396


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_963FC:
					; ROM:00095D60p
		move.b	($FFFFF603).w,d0
		andi.b	#$70,d0	; 'p'
		beq.w	locret_964AA
		moveq	#0,d0
		move.b	angle(a0),d0
		addi.b	#$80,d0
		bsr.w	sub_97688
		cmpi.w	#6,d1
		blt.w	locret_964AA
		move.w	#$600,d2
		btst	#6,status(a0)
		beq.s	loc_9642E
		move.w	#$300,d2

loc_9642E:
		tst.w	($FFFFFFD0).w
		beq.s	loc_96438
		addi.w	#$80,d2	; '�'

loc_96438:
		moveq	#0,d0
		move.b	angle(a0),d0
		subi.b	#$40,d0	; '@'
		jsr	(CalcSine).l
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,x_vel(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,y_vel(a0)
		bset	#1,status(a0)
		bclr	#5,status(a0)
		addq.l	#4,sp
		bset	#s3b_jumping,status3(a0)
		bclr	#s3b_stick_convex,status3(a0)
		move.w	#$A0,d0	; '�'
		jsr	(PlaySound).l
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		btst	#2,status(a0)
		bne.s	loc_964AC
		move.b	#$1C,height_pixels(a0)
		move.b	#14,width_pixels(a0)
		move.b	#2,anim(a0)
		bset	#2,status(a0)
		addq.w	#5,y_pos(a0)

locret_964AA:
					; sub_963FC+1Ej
		rts
; ===========================================================================

loc_964AC:
		bset	#4,status(a0)
		rts
; End of function sub_963FC


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_964B4:
					; ROM:loc_95D80p
		btst	#s3b_jumping,status3(a0)
		beq.s	loc_964E2
		move.w	#$FC00,d1
		btst	#6,status(a0)
		beq.s	loc_964CA
		move.w	#$FE00,d1

loc_964CA:
		cmp.w	y_vel(a0),d1
		ble.w	loc_964F8
		move.b	($FFFFF602).w,d0
		andi.b	#$70,d0	; 'p'
		bne.s	locret_964E0
		move.w	d1,y_vel(a0)

locret_964E0:
		rts
; ===========================================================================

loc_964E2:
		btst	#s3b_spindash,status3(a0)
		bne.s	locret_964F6
		cmpi.w	#$F040,y_vel(a0)
		bge.s	locret_964F6
		move.w	#$F040,y_vel(a0)

locret_964F6:
					; sub_964B4+3Aj
		rts
; ===========================================================================

loc_964F8:
		tst.w	($FFFFFFD0).w
		nop
		nop
		tst.b	air_action(a0)
		bne.w	locret_96590
		move.b	($FFFFF603).w,d0
		andi.b	#$70,d0	; 'p'
		beq.w	locret_96590
		tst.b	(Super_Tails_flag).w
		bne.s	loc_96530	; If Tails is already super
		cmpi.b	#7,($FFFFFFB1).w
		bcs.s	loc_96530
		cmp.w	#50,(Ring_count).w
		bcs.s	loc_96530
		tst.b	($FFFFFE1E).w
		bne.s	loc_96592

loc_96530:
					; sub_964B4+6Cj ...
		bclr	#2,status(a0)
		move.b	#$14,height_pixels(a0)
		move.b	#$14,width_pixels(a0)
		bclr	#4,status(a0)
		move.b	#1,air_action(a0)
		addi.w	#$200,y_vel(a0)
		bpl.s	loc_9655C
		move.w	#0,y_vel(a0)

loc_9655C:
		moveq	#0,d1
		move.w	#$400,d0
		move.w	d0,inertia(a0)
		btst	#0,status(a0)
		beq.s	loc_96572
		neg.w	d0
		moveq	#-$80,d1

loc_96572:
		move.w	d0,x_vel(a0)
		move.b	d1,knuckles_unk(a0)
		move.w	#0,angle(a0)
		move.b	#0,($FFFFF7AC).w
		bset	#1,($FFFFF7AC).w
		bsr.w	sub_95C3A

locret_96590:
					; sub_964B4+5Cj
		rts
; ===========================================================================

loc_96592:
		move.b	#1,($FFFFF65F).w
		move.b	#$F,($FFFFF65E).w
		move.b	#1,(Super_Tails_flag).w
		move.w	#$3C,($FFFFF670).w ; '<'
		ori.b	#lock_mask,status3(a0)
		move.b	#$1F,anim(a0)
		move.b	#$7E,($FFFFD040).w	; Super birds
		move.w	#$800,($FFFFF760).w
		move.w	#$18,($FFFFF762).w
		move.w	#$C0,($FFFFF764).w	; '�'
		move.w	#0,invincibility_time(a0)
		bset	#1,status2(a0)
		move.w	#SndID_SuperTransform,d0
		jsr	(PlaySound).l		; Play transformation sound effect.
		move.w	#MusID_SuperSonic,d0
		jmp	(PlayMusic).l		; load the Super Sonic song and return
; End of function sub_964B4

; ===========================================================================
		dc.b $4E ; N
		dc.b $75 ; u

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_965F0:
		tst.b	($FFFFFE19).w
		beq.w	locret_96686
		tst.b	($FFFFFE1E).w
		beq.s	loc_9663C
		subq.w	#1,($FFFFF670).w
		bpl.w	locret_96686
		move.w	#$3C,($FFFFF670).w ; '<'
		tst.w	($FFFFFE20).w
		beq.s	loc_9663C
		ori.b	#1,($FFFFFE1D).w
		cmpi.w	#1,($FFFFFE20).w
		beq.s	loc_96630
		cmpi.w	#$A,($FFFFFE20).w
		beq.s	loc_96630
		cmpi.w	#$64,($FFFFFE20).w ; 'd'
		bne.s	loc_96636

loc_96630:
					; sub_965F0+36j
		ori.b	#$80,($FFFFFE1D).w

loc_96636:
		subq.w	#1,($FFFFFE20).w
		bne.s	locret_96686

loc_9663C:
					; sub_965F0+20j
		move.b	#2,($FFFFF65F).w
		move.w	#$28,($FFFFF65C).w ; '('
		move.b	#0,($FFFFFE19).w
		move.b	#1,next_anim(a0)
		move.w	#1,invincibility_time(a0)
		move.w	#$600,($FFFFF760).w
		move.w	#$C,($FFFFF762).w
		move.w	#$80,($FFFFF764).w ; '�'
		btst	#6,status(a0)
		beq.s	locret_96686
		move.w	#$300,($FFFFF760).w
		move.w	#6,($FFFFF762).w
		move.w	#$40,($FFFFF764).w ; '@'

locret_96686:
					; sub_965F0+12j ...
		rts
; End of function sub_965F0


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96688:
		btst	#s3b_spindash,status3(a0)
		bne.s	loc_966D8
		cmpi.b	#8,anim(a0)
		bne.s	locret_966D6
		move.b	($FFFFF603).w,d0
		andi.b	#$70,d0	; 'p'
		beq.w	locret_966D6
		move.b	#9,anim(a0)
		move.w	#$E0,d0	; '�'
		jsr	(PlaySound).l
		addq.l	#4,sp
		bset	#s3b_spindash,status3(a0)
		move.w	#0,spindash_counter(a0)
		cmpi.b	#$C,air_left(a0)
		bcs.s	loc_966CE
		move.b	#2,($FFFFD11C).w

loc_966CE:
		bsr.w	sub_96336
		bsr.w	sub_97652

locret_966D6:
					; sub_96688+16j
		rts
; ===========================================================================

loc_966D8:
		move.b	($FFFFF602).w,d0
		btst	#1,d0
		bne.w	loc_9677A
		move.b	#$1C,height_pixels(a0)
		move.b	#14,width_pixels(a0)
		move.b	#2,anim(a0)
		addq.w	#5,y_pos(a0)
		bclr	#s3b_spindash,status3(a0)
		moveq	#0,d0
		move.b	spindash_counter(a0),d0
		add.w	d0,d0
		move.w	word_96756(pc,d0.w),inertia(a0)
		tst.b	($FFFFFE19).w
		beq.s	loc_9671A
		move.w	word_96768(pc,d0.w),inertia(a0)

loc_9671A:
		move.w	inertia(a0),d0
		subi.w	#$800,d0
		add.w	d0,d0
		andi.w	#$1F00,d0
		neg.w	d0
		addi.w	#$2000,d0
		move.w	d0,($FFFFEED0).w
		btst	#0,status(a0)
		beq.s	loc_9673E
		neg.w	inertia(a0)

loc_9673E:
		bset	#2,status(a0)
		move.b	#0,($FFFFD11C).w
		move.w	#$BC,d0	; '�'
		jsr	(PlaySound).l
		bra.s	loc_967C2
; ===========================================================================
word_96756:	dc.w $800
		dc.w $880
		dc.w $900
		dc.w $980
		dc.w $A00
		dc.w $A80
		dc.w $B00
		dc.w $B80
		dc.w $C00
word_96768:	dc.w $B00
		dc.w $B80
		dc.w $C00
		dc.w $C80
		dc.w $D00
		dc.w $D80
		dc.w $E00
		dc.w $E80
		dc.w $F00
; ===========================================================================

loc_9677A:
		tst.w	spindash_counter(a0)
		beq.s	loc_96792
		move.w	spindash_counter(a0),d0
		lsr.w	#5,d0
		sub.w	d0,spindash_counter(a0)
		bcc.s	loc_96792
		move.w	#0,spindash_counter(a0)

loc_96792:
					; sub_96688+102j
		move.b	($FFFFF603).w,d0
		andi.b	#$70,d0	; 'p'
		beq.w	loc_967C2
		move.w	#$900,anim(a0)
		move.w	#$E0,d0	; '�'
		jsr	(PlaySound).l
		addi.w	#$200,spindash_counter(a0)
		cmpi.w	#$800,spindash_counter(a0)
		bcs.s	loc_967C2
		move.w	#$800,spindash_counter(a0)

loc_967C2:
					; sub_96688+112j ...
		addq.l	#4,sp
		cmpi.w	#$60,($FFFFEED8).w ; '`'
		beq.s	loc_967D6
		bcc.s	loc_967D2
		addq.w	#4,($FFFFEED8).w

loc_967D2:
		subq.w	#2,($FFFFEED8).w

loc_967D6:
		bsr.w	sub_96336
		bsr.w	sub_97652
		rts
; End of function sub_96688


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_967E0:
		move.b	angle(a0),d0
		addi.b	#$60,d0	; '`'
		cmpi.b	#$C0,d0
		bcc.s	locret_96814
		move.b	angle(a0),d0
		jsr	(CalcSine).l
		muls.w	#$20,d0	; ' '
		asr.l	#8,d0
		tst.w	inertia(a0)
		beq.s	locret_96814
		bmi.s	loc_96810
		tst.w	d0
		beq.s	locret_9680E
		add.w	d0,inertia(a0)

locret_9680E:
		rts
; ===========================================================================

loc_96810:
		add.w	d0,inertia(a0)

locret_96814:
					; sub_967E0+22j
		rts
; End of function sub_967E0


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96816:
		move.b	angle(a0),d0
		addi.b	#$60,d0	; '`'
		cmpi.b	#$C0,d0
		bcc.s	locret_96850
		move.b	angle(a0),d0
		jsr	(CalcSine).l
		muls.w	#$50,d0	; 'P'
		asr.l	#8,d0
		tst.w	inertia(a0)
		bmi.s	loc_96846
		tst.w	d0
		bpl.s	loc_96840
		asr.l	#2,d0

loc_96840:
		add.w	d0,inertia(a0)
		rts
; ===========================================================================

loc_96846:
		tst.w	d0
		bmi.s	loc_9684C
		asr.l	#2,d0

loc_9684C:
		add.w	d0,inertia(a0)

locret_96850:
		rts
; End of function sub_96816


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96852:
					; ROM:00095D7Ap
		nop
		btst	#s3b_stick_convex,status3(a0)
		bne.s	locret_9688C
		tst.w	move_lock(a0)
		bne.s	loc_9688E
		move.b	angle(a0),d0
		addi.b	#$20,d0	; ' '
		andi.b	#$C0,d0
		beq.s	locret_9688C
		move.w	inertia(a0),d0
		bpl.s	loc_96876
		neg.w	d0

loc_96876:
		cmpi.w	#$280,d0
		bcc.s	locret_9688C
		clr.w	inertia(a0)
		bset	#1,status(a0)
		move.w	#$1E,move_lock(a0)

locret_9688C:
					; sub_96852+1Aj ...
		rts
; ===========================================================================

loc_9688E:
		subq.w	#1,move_lock(a0)
		rts
; End of function sub_96852


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96894:
					; ROM:loc_95DA0p
		move.b	angle(a0),d0
		beq.s	loc_968AE
		bpl.s	loc_968A4
		addq.b	#2,d0
		bcc.s	loc_968A2
		moveq	#0,d0

loc_968A2:
		bra.s	loc_968AA
; ===========================================================================

loc_968A4:
		subq.b	#2,d0
		bcc.s	loc_968AA
		moveq	#0,d0

loc_968AA:
					; sub_96894+12j
		move.b	d0,angle(a0)

loc_968AE:
		move.b	flip_angle(a0),d0
		beq.s	locret_968F2
		tst.w	inertia(a0)
		bmi.s	loc_968D2

loc_968BA:
		move.b	flip_speed(a0),d1
		add.b	d1,d0
		bcc.s	loc_968D0
		subq.b	#1,flips_remaining(a0)
		bcc.s	loc_968D0
		move.b	#0,flips_remaining(a0)
		moveq	#0,d0

loc_968D0:
					; sub_96894+32j
		bra.s	loc_968EE
; ===========================================================================

loc_968D2:
		btst	#s3b_flip_turned,status3(a0)
		bne.s	loc_968BA
		move.b	flip_speed(a0),d1
		sub.b	d1,d0
		bcc.s	loc_968EE
		subq.b	#1,flips_remaining(a0)
		bcc.s	loc_968EE
		move.b	#0,flips_remaining(a0)
		moveq	#0,d0

loc_968EE:
					; sub_96894+4Aj ...
		move.b	d0,flip_angle(a0)

locret_968F2:
		rts
; End of function sub_96894


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_968F4:
					; sub_95678:loc_95870p	...
		move.l	#$FFFFD600,($FFFFF796).w
		cmpi.b	#$C,layer(a0)
		beq.s	loc_9690C
		move.l	#$FFFFD900,($FFFFF796).w

loc_9690C:
		move.b	layer_plus(a0),d5
		move.w	x_vel(a0),d1
		move.w	y_vel(a0),d2
		jsr	(CalcAngle).l
		subi.b	#$20,d0	; ' '
		andi.b	#$C0,d0
		cmpi.b	#$40,d0	; '@'
		beq.w	loc_9698C
		cmpi.b	#$80,d0
		beq.w	loc_96A04
		cmpi.b	#$C0,d0
		beq.w	loc_96A48
		bsr.w	sub_9768E
		tst.w	d1
		bpl.s	loc_96956
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#5,($FFFFF7AC).w

loc_96956:
		bsr.w	sub_97694
		tst.w	d1
		bpl.s	loc_9696E
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#5,($FFFFF7AC).w

loc_9696E:
		bsr.w	sub_97664
		tst.w	d1
		bpl.s	locret_9698A
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		bclr	#1,($FFFFF7AC).w

locret_9698A:
		rts
; ===========================================================================

loc_9698C:
		bsr.w	sub_9768E
		tst.w	d1
		bpl.s	loc_969A4
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#5,($FFFFF7AC).w

loc_969A4:
		bsr.w	sub_9769A
		tst.w	d1
		bpl.s	loc_969E0
		neg.w	d1
		cmpi.w	#$14,d1
		bcc.s	loc_969C6
		add.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_969C4
		move.w	#0,y_vel(a0)

locret_969C4:
		rts
; ===========================================================================

loc_969C6:
		bsr.w	sub_97694
		tst.w	d1
		bpl.s	locret_969DE
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#5,($FFFFF7AC).w

locret_969DE:
		rts
; ===========================================================================

loc_969E0:
		tst.w	y_vel(a0)
		bmi.s	locret_96A02
		bsr.w	sub_97664
		tst.w	d1
		bpl.s	locret_96A02
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		bclr	#1,($FFFFF7AC).w

locret_96A02:
					; sub_968F4+F8j
		rts
; ===========================================================================

loc_96A04:
		bsr.w	sub_9768E
		tst.w	d1
		bpl.s	loc_96A1C
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#5,($FFFFF7AC).w

loc_96A1C:
		bsr.w	sub_97694
		tst.w	d1
		bpl.s	loc_96A34
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#5,($FFFFF7AC).w

loc_96A34:
		bsr.w	sub_9769A
		tst.w	d1
		bpl.s	locret_96A46
		sub.w	d1,y_pos(a0)
		move.w	#0,y_vel(a0)

locret_96A46:
		rts
; ===========================================================================

loc_96A48:
		bsr.w	sub_97694
		tst.w	d1
		bpl.s	loc_96A60
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		bset	#5,($FFFFF7AC).w

loc_96A60:
		bsr.w	sub_9769A
		tst.w	d1
		bpl.s	loc_96A7A
		sub.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_96A78
		move.w	#0,y_vel(a0)

locret_96A78:
		rts
; ===========================================================================

loc_96A7A:
		tst.w	y_vel(a0)
		bmi.s	locret_96A9C
		bsr.w	sub_97664
		tst.w	d1
		bpl.s	locret_96A9C
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		move.w	#0,y_vel(a0)
		bclr	#1,($FFFFF7AC).w

locret_96A9C:
					; sub_968F4+192j
		rts
; End of function sub_968F4


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96A9E:
					; ROM:00095DA4p ...
		move.l	#$FFFFD600,($FFFFF796).w
		cmpi.b	#$C,layer(a0)
		beq.s	loc_96AB6
		move.l	#$FFFFD900,($FFFFF796).w

loc_96AB6:
		move.b	layer_plus(a0),d5
		move.w	x_vel(a0),d1
		move.w	y_vel(a0),d2
		jsr	(CalcAngle).l
		subi.b	#$20,d0	; ' '
		andi.b	#$C0,d0
		cmpi.b	#$40,d0	; '@'
		beq.w	loc_96B80
		cmpi.b	#$80,d0
		beq.w	loc_96BDC
		cmpi.b	#$C0,d0
		beq.w	loc_96C38
		bsr.w	sub_9768E
		tst.w	d1
		bpl.s	loc_96AFA
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_96AFA:
		bsr.w	sub_97694
		tst.w	d1
		bpl.s	loc_96B0C
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_96B0C:
		bsr.w	sub_97664
		tst.w	d1
		bpl.s	locret_96B7E
		move.b	y_vel(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_96B24
		cmp.b	d2,d0
		blt.s	locret_96B7E

loc_96B24:
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		bsr.w	sub_96C94
		move.b	d3,d0
		addi.b	#$20,d0	; ' '
		andi.b	#$40,d0	; '@'
		bne.s	loc_96B5C
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0	; ' '
		beq.s	loc_96B4E
		asr	y_vel(a0)
		bra.s	loc_96B70
; ===========================================================================

loc_96B4E:
		move.w	#0,y_vel(a0)
		move.w	x_vel(a0),inertia(a0)
		rts
; ===========================================================================

loc_96B5C:
		move.w	#0,x_vel(a0)
		cmpi.w	#$FC0,y_vel(a0)
		ble.s	loc_96B70
		move.w	#$FC0,y_vel(a0)

loc_96B70:
					; sub_96A9E+CAj
		move.w	y_vel(a0),inertia(a0)
		tst.b	d3
		bpl.s	locret_96B7E
		neg.w	inertia(a0)

locret_96B7E:
					; sub_96A9E+84j ...
		rts
; ===========================================================================

loc_96B80:
		bsr.w	sub_9768E
		tst.w	d1
		bpl.s	loc_96B9A
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		move.w	y_vel(a0),inertia(a0)
		rts
; ===========================================================================

loc_96B9A:
		bsr.w	sub_9769A
		tst.w	d1
		bpl.s	loc_96BB4
		sub.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_96BB2
		move.w	#0,y_vel(a0)

locret_96BB2:
		rts
; ===========================================================================

loc_96BB4:
		tst.w	y_vel(a0)
		bmi.s	locret_96BDA
		bsr.w	sub_97664
		tst.w	d1
		bpl.s	locret_96BDA
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		bsr.w	sub_96C94
		move.w	#0,y_vel(a0)
		move.w	x_vel(a0),inertia(a0)

locret_96BDA:
					; sub_96A9E+122j
		rts
; ===========================================================================

loc_96BDC:
		bsr.w	sub_9768E
		tst.w	d1
		bpl.s	loc_96BEE
		sub.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_96BEE:
		bsr.w	sub_97694
		tst.w	d1
		bpl.s	loc_96C00
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)

loc_96C00:
		bsr.w	sub_9769A
		tst.w	d1
		bpl.s	locret_96C36
		sub.w	d1,y_pos(a0)
		move.b	d3,d0
		addi.b	#$20,d0	; ' '
		andi.b	#$40,d0	; '@'
		bne.s	loc_96C20
		move.w	#0,y_vel(a0)
		rts
; ===========================================================================

loc_96C20:
		move.b	d3,angle(a0)
		bsr.w	sub_96C94
		move.w	y_vel(a0),inertia(a0)
		tst.b	d3
		bpl.s	locret_96C36
		neg.w	inertia(a0)

locret_96C36:
					; sub_96A9E+192j
		rts
; ===========================================================================

loc_96C38:
		bsr.w	sub_97694
		tst.w	d1
		bpl.s	loc_96C52
		add.w	d1,x_pos(a0)
		move.w	#0,x_vel(a0)
		move.w	y_vel(a0),inertia(a0)
		rts
; ===========================================================================

loc_96C52:
		bsr.w	sub_9769A
		tst.w	d1
		bpl.s	loc_96C6C
		sub.w	d1,y_pos(a0)
		tst.w	y_vel(a0)
		bpl.s	locret_96C6A
		move.w	#0,y_vel(a0)

locret_96C6A:
		rts
; ===========================================================================

loc_96C6C:
		tst.w	y_vel(a0)
		bmi.s	locret_96C92
		bsr.w	sub_97664
		tst.w	d1
		bpl.s	locret_96C92
		add.w	d1,y_pos(a0)
		move.b	d3,angle(a0)
		bsr.w	sub_96C94
		move.w	#0,y_vel(a0)
		move.w	x_vel(a0),inertia(a0)

locret_96C92:
					; sub_96A9E+1DAj
		rts
; End of function sub_96A9E


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96C94:
					; sub_96A9E+12Cp ...
		btst	#s3b_spindash,status3(a0)
		bne.s	loc_96CCE
		move.b	#0,anim(a0)
; End of function sub_96C94


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96CA0:
					; sub_95678+232j ...
		move.b	height_pixels(a0),d0
		lsr.b	#1,d0
		move.b	#$26,height_pixels(a0)
		move.b	#18,width_pixels(a0)
		btst	#2,status(a0)
		beq.s	loc_96CCE
		bclr	#2,status(a0)
		move.b	#0,anim(a0)
		subi.b	#$13,d0
		ext.w	d0
		add.w	d0,y_pos(a0)

loc_96CCE:
					; sub_96CA0+16j
           	bclr    #1,status(a0)
           	bclr    #5,status(a0)
           	bclr    #4,status(a0)
           	bclr	#s3b_jumping,status3(a0)
           	move.w  #0,($FFFFF7D0).w
           	move.b  #0,flip_angle(a0)
           	bclr	#s3b_flip_turned,status3(a0)
           	move.b  #0,flips_remaining(a0)
           	move.w  #0,($FFFFF66C).w
     		tst.b 	air_action(a0)
     		beq 	Knuckles_NoLand
     		cmp.b 	#$CC,mapping_frame(a0)
     		beq 	Knuckles_NoLand
           	move.w  #$73,d0			; Change $F4 to the ID of the sound
           	jsr    	(PlaySound).l		; play sound
     		move.b  #0,air_action(a0)
Knuckles_NoLand:
           	cmpi.b  #$20,anim(a0); ' '
           	bcc.s   loc_96D1A
           	cmpi.b  #$14,anim(a0)
           	bne.s   locret_96D20

loc_96D1A:
		move.b	#0,anim(a0)

locret_96D20:
		rts
; End of function sub_96CA0


; ��������������� S U B	R O U T	I N E ���������������������������������������


Knuckles_Hurt:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	tst.w	(Debug_mode_flag).w
	beq.s	Knuckles_Hurt_Normal
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	Knuckles_Hurt_Normal
	move.w	#1,(Debug_placement_mode).w
	clr.b	(Control_Locked).w
	rts
; ===========================================================================

Knuckles_Hurt_Normal:
		jsr	ObjectMove
		addi.w	#$30,y_vel(a0) ; '0'
		btst	#6,status(a0)
		beq.s	loc_96D5E
		subi.w	#$20,y_vel(a0) ; ' '

loc_96D5E:
		cmpi.w	#$FF00,($FFFFEECC).w
		bne.s	loc_96D6C
		andi.w	#$7FF,y_pos(a0)

loc_96D6C:
		bsr.w	sub_96D86
		bsr.w	sub_96336
		bsr.w	sub_954FA
		bsr.w	Knuckles_Animate
		bsr.w	LoadKnucklesDynPLC
		jmp	DisplaySprite
; End of function Knuckles_Hurt


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96D86:
		move.w	($FFFFEECE).w,d0
		addi.w	#$E0,d0	; '�'
		cmp.w	y_pos(a0),d0
		blt.w	loc_96DCC
		bsr.w	sub_96A9E
		btst	#1,status(a0)
		bne.s	locret_96DCA
		moveq	#0,d0
		move.w	d0,y_vel(a0)
		move.w	d0,x_vel(a0)
		move.w	d0,inertia(a0)
		andi.b	#lock_del,status3(a0)
		move.b	#0,anim(a0)
		move.w	#objroutine(Knuckles_Control),(a0)
		move.w	#$78,invulnerable_time(a0) ; 'x'
		bclr	#s3b_spindash,status3(a0)

locret_96DCA:
		rts
; ===========================================================================

loc_96DCC:
		jmp	KillCharacter
; End of function sub_96D86

; ===========================================================================
; START	OF FUNCTION CHUNK FOR Knuckles_Hurt

loc_96DD2:
		move.w	#objroutine(Knuckles_Control),(a0)
		bsr.w	sub_954FA
		bsr.w	Knuckles_Animate
		bsr.w	LoadKnucklesDynPLC
		jmp	DisplaySprite
; END OF FUNCTION CHUNK	FOR Knuckles_Hurt

; ��������������� S U B	R O U T	I N E ���������������������������������������


Knuckles_Dead:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
	tst.w	(Debug_mode_flag).w
	beq.s	+
	btst	#button_B,(Ctrl_1_Press).w
	beq.s	+
	move.w	#1,(Debug_placement_mode).w
	clr.b	(Control_Locked).w
	rts
+	bsr.w	CheckGameOver
	jsr	(ObjectMoveAndFall).l
		bsr.w	sub_954FA
		bsr.w	Knuckles_Animate
		bsr.w	LoadKnucklesDynPLC
		jmp	DisplaySprite
; End of function Knuckles_Dead


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_96E24:

; FUNCTION CHUNK AT 0000161E SIZE 00000032 BYTES

		move.b	#1,($FFFFEEBE).w
		bclr	#s3b_spindash,status3(a0)
		move.w	($FFFFEECE).w,d0
		addi.w	#$100,d0
		cmp.w	y_pos(a0),d0
		bge.w	locret_96F22
		move.w	#objroutine(Knuckles_Gone),(a0)
		move.w	#$3C,spindash_counter(a0) ; '<'
		addq.b	#1,($FFFFFE1C).w
		subq.b	#1,($FFFFFE12).w
		bne.s	loc_96E96
		move.w	#0,spindash_counter(a0)
		move.b	#$39,($FFFFB080).w ; '9'
		move.b	#$39,($FFFFB0C0).w ; '9'
		move.b	#1,($FFFFB0DA).w
		move.w	a0,($FFFFB0BE).w
		clr.b	($FFFFFE1A).w

loc_96E76:
		clr.b	($FFFFFE1E).w
		clr.b	($FFFFFECA).w
		move.w	#objroutine(Knuckles_Gone),(a0)
		move.w	#$9B,d0	; '�'
		jsr	(PlayMusic).l
		moveq	#3,d0
		jmp	(LoadPLC).l
; ===========================================================================

loc_96E96:
		tst.b	($FFFFFE1A).w
		beq.s	loc_96EC0
		move.w	#0,spindash_counter(a0)
		move.b	#$39,($FFFFB080).w ; '9'
		move.b	#$39,($FFFFB0C0).w ; '9'
		move.b	#2,($FFFFB09A).w
		move.b	#3,($FFFFB0DA).w
		move.w	a0,($FFFFB0BE).w
		bra.s	loc_96E76
; ===========================================================================

loc_96EC0:
		tst.w	($FFFFFFDC).w
		beq.s	locret_96F22
		move.b	#0,($FFFFEEBE).w
		move.w	#objroutine(Knuckles_Respawning),(a0)
		move.w	($FFFFFE32).w,x_pos(a0)
		move.w	($FFFFFE34).w,y_pos(a0)
		move.w	($FFFFFE3C).w,art_tile(a0)
		move.w	($FFFFFE3E).w,layer(a0)
		clr.w	($FFFFFE20).w
		clr.b	($FFFFFE1B).w
		andi.b	#lock_del,status3(a0)
		move.b	#5,anim(a0)
		move.w	#0,x_vel(a0)
		move.w	#0,y_vel(a0)
		move.w	#0,inertia(a0)
		move.b	#2,status(a0)
		move.w	#0,move_lock(a0)
		move.w	#0,spindash_counter(a0)

locret_96F22:
					; sub_96E24+A0j
		rts
; End of function sub_96E24


; ��������������� S U B	R O U T	I N E ���������������������������������������


Knuckles_Gone:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
		tst.w	spindash_counter(a0)
		beq.s	locret_96F36
		subq.w	#1,spindash_counter(a0)
		bne.s	locret_96F36
		move.w	#1,($FFFFFE02).w

locret_96F36:
		rts
; End of function Knuckles_Gone


; ��������������� S U B	R O U T	I N E ���������������������������������������


Knuckles_Respawning:
	tst.w	(Debug_placement_mode).w	; is debug mode being used?
	beq.s	+				; if not, branch
	jmp	(DebugMode).l
+
		tst.w	($FFFFEEB0).w
		bne.s	loc_96F4A
		tst.w	($FFFFEEB2).w
		bne.s	loc_96F4A
		move.w	#objroutine(Knuckles_Control),(a0)

loc_96F4A:
		bsr.w	Knuckles_Animate
		bsr.w	LoadKnucklesDynPLC
		jmp	DisplaySprite
; End of function Knuckles_Respawning


; ��������������� S U B	R O U T	I N E ���������������������������������������


Knuckles_Animate:
		lea	(AniKnux).l,a1
		moveq	#0,d0
		move.b	anim(a0),d0
		cmp.b	next_anim(a0),d0
		beq.s	loc_96F80
		move.b	d0,next_anim(a0)
		move.b	#0,anim_frame(a0)
		move.b	#0,anim_frame_duration(a0)
		bclr	#5,status(a0)

loc_96F80:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1
		move.b	(a1),d0
		bmi.s	loc_96FF0
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,render_flags(a0)
		or.b	d1,render_flags(a0)
		subq.b	#1,anim_frame_duration(a0)
		bpl.s	locret_96FBE
		move.b	d0,anim_frame_duration(a0)

loc_96FA6:
					; Knuckles_Animate+234j
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#$FC,d0
		bcc.s	loc_96FC0

loc_96FB6:
					; Knuckles_Animate+8Aj
		move.b	d0,mapping_frame(a0)
		addq.b	#1,anim_frame(a0)

locret_96FBE:
					; Knuckles_Animate+1B6j ...
		rts
; ===========================================================================

loc_96FC0:
		addq.b	#1,d0
		bne.s	loc_96FD0
		move.b	#0,anim_frame(a0)
		move.b	1(a1),d0
		bra.s	loc_96FB6
; ===========================================================================

loc_96FD0:
		addq.b	#1,d0
		bne.s	loc_96FE4
		move.b	2(a1,d1.w),d0
		sub.b	d0,anim_frame(a0)
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0
		bra.s	loc_96FB6
; ===========================================================================

loc_96FE4:
		addq.b	#1,d0
		bne.s	locret_96FEE
		move.b	2(a1,d1.w),anim(a0)

locret_96FEE:
		rts
; ===========================================================================

loc_96FF0:
		addq.b	#1,d0
		bne.w	loc_9710A
		moveq	#0,d0
		move.b	flip_angle(a0),d0
		bne.w	loc_970A4
		moveq	#0,d1
		move.b	angle(a0),d0
		bmi.s	loc_9700C
		beq.s	loc_9700C
		subq.b	#1,d0

loc_9700C:
					; Knuckles_Animate+B0j
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_97018
		not.b	d0

loc_97018:
		addi.b	#$10,d0
		bpl.s	loc_97020
		moveq	#3,d1

loc_97020:
		andi.b	#$FC,render_flags(a0)
		eor.b	d1,d2
		or.b	d2,render_flags(a0)
		btst	#5,status(a0)
		bne.w	loc_97156
		lsr.b	#4,d0
		andi.b	#6,d0
		move.w	inertia(a0),d2
		bpl.s	loc_97044
		neg.w	d2

loc_97044:
		tst.b	status2(a0)
		bpl.w	loc_9704E
		add.w	d2,d2

loc_9704E:
		lea	(byte_971E4).l,a1
		cmpi.w	#$600,d2
		bcc.s	loc_97062
		lea	(byte_971DA).l,a1
		add.b	d0,d0

loc_97062:
		add.b	d0,d0
		move.b	d0,d3
		moveq	#0,d1
		move.b	anim_frame(a0),d1
		move.b	1(a1,d1.w),d0
		cmpi.b	#$FF,d0
		bne.s	loc_97080
		move.b	#0,anim_frame(a0)
		move.b	1(a1),d0

loc_97080:
		move.b	d0,mapping_frame(a0)
		add.b	d3,mapping_frame(a0)
		subq.b	#1,anim_frame_duration(a0)
		bpl.s	locret_970A2
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_97098
		moveq	#0,d2

loc_97098:
		lsr.w	#8,d2
		move.b	d2,anim_frame_duration(a0)
		addq.b	#1,anim_frame(a0)

locret_970A2:
		rts
; ===========================================================================

loc_970A4:
		move.b	flip_angle(a0),d0
		moveq	#0,d1
		move.b	status(a0),d2
		andi.b	#1,d2
		bne.s	loc_970D2
		andi.b	#$FC,render_flags(a0)
		addi.b	#$B,d0
		divu.w	#$16,d0
		addi.b	#$31,d0	; '1'
		move.b	d0,mapping_frame(a0)
		move.b	#0,anim_frame_duration(a0)
		rts
; ===========================================================================

loc_970D2:
		andi.b	#$FC,render_flags(a0)
		btst	#s3b_flip_turned,status3(a0)
		beq.s	loc_970EA
		ori.b	#1,render_flags(a0)
		addi.b	#$B,d0
		bra.s	loc_970F6
; ===========================================================================

loc_970EA:
		ori.b	#3,render_flags(a0)
		neg.b	d0
		addi.b	#$8F,d0

loc_970F6:
		divu.w	#$16,d0
		addi.b	#$31,d0	; '1'
		move.b	d0,mapping_frame(a0)
		move.b	#0,anim_frame_duration(a0)
		rts
; ===========================================================================

loc_9710A:
		subq.b	#1,anim_frame_duration(a0)
		bpl.w	locret_96FBE
		addq.b	#1,d0
		bne.s	loc_97156
		move.w	inertia(a0),d2
		bpl.s	loc_9711E
		neg.w	d2

loc_9711E:
		lea	(byte_971F8).l,a1
		cmpi.w	#$600,d2
		bcc.s	loc_97130
		lea	(byte_971EE).l,a1

loc_97130:
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_9713A
		moveq	#0,d2

loc_9713A:
		lsr.w	#8,d2
		move.b	d2,anim_frame_duration(a0)
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,render_flags(a0)
		or.b	d1,render_flags(a0)
		bra.w	loc_96FA6
; ===========================================================================

loc_97156:
					; Knuckles_Animate+1BCj
		subq.b	#1,anim_frame_duration(a0)
		bpl.w	locret_96FBE
		move.w	inertia(a0),d2
		bmi.s	loc_97166
		neg.w	d2

loc_97166:
		addi.w	#$800,d2
		bpl.s	loc_9716E
		moveq	#0,d2

loc_9716E:
		lsr.w	#8,d2
		move.b	d2,anim_frame_duration(a0)
		lea	(byte_97202).l,a1
		move.b	status(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,render_flags(a0)
		or.b	d1,render_flags(a0)
		bra.w	loc_96FA6
; End of function Knuckles_Animate

; ===========================================================================
; ��������������� S U B	R O U T	I N E ���������������������������������������

LoadKnucklesDynPLC:

	moveq	#0,d0
	move.b	mapping_frame(a0),d0	; load frame number
; loc_1B84E:
LoadKnucklesDynPLC_Part2:
	cmp.b	($FFFFF766).w,d0
	beq.s	return_1B89C
	move.b	d0,($FFFFF766).w
	lea	(SK_PLC_Knuckles).l,a2
	add.w	d0,d0
	adda.w	(a2,d0.w),a2
	move.w	(a2)+,d5
	subq.w	#1,d5
	bmi.s	return_1B89C
	move.w	#-$1000,d4
; loc_1B86E:
KPLC_ReadEntry:
	moveq	#0,d1
	move.w	(a2)+,d1
	move.w	d1,d3
	lsr.w	#8,d3
	andi.w	#$F0,d3
	addi.w	#$10,d3
	andi.w	#$FFF,d1
	lsl.l	#5,d1
	addi.l	#SK_ArtUnc_Knux,d1
	move.w	d4,d2
	add.w	d3,d4
	add.w	d3,d4
	jsr	(QueueDMATransfer).l
	dbf	d5,KPLC_ReadEntry	; repeat for number of entries
return_1B89C:
	rts

; ===========================================================================
byte_974FE:	dc.b 0,	6, 5, 3, 2, 4, $C, $D, $E, $F, $A, $B, 7, 8, 9,	1

		dc.b $60, $66, $65, $63, $62, $64, $6C,	$6D, $6E, $6F, $6A, $6B, $67, $68, $69,	$61
		dc.b $50, $56, $55, $53, $52, $54, $5C,	$5D, $5E, $5F, $5A, $5B, $57, $58, $59,	$51
		dc.b $30, $36, $35, $33, $32, $34, $3C,	$3D, $3E, $3F, $3A, $3B, $37, $38, $39,	$31
		dc.b $20, $26, $25, $23, $22, $24, $2C,	$2D, $2E, $2F, $2A, $2B, $27, $28, $29,	$21
		dc.b $40, $46, $45, $43, $42, $44, $4C,	$4D, $4E, $4F, $4A, $4B, $47, $48, $49,	$41
		dc.b $C0, $C6, $C5, $C3, $C2, $C4, $CC,	$CD, $CE, $CF, $CA, $CB, $C7, $C8, $C9,	$C1
		dc.b $D0, $D6, $D5, $D3, $D2, $D4, $DC,	$DD, $DE, $DF, $DA, $DB, $D7, $D8, $D9,	$D1
		dc.b $E0, $E6, $E5, $E3, $E2, $E4, $EC,	$ED, $EE, $EF, $EA, $EB, $E7, $E8, $E9,	$E1
		dc.b $F0, $F6, $F5, $F3, $F2, $F4, $FC,	$FD, $FE, $FF, $FA, $FB, $F7, $F8, $F9,	$F1
		dc.b $A0, $A6, $A5, $A3, $A2, $A4, $AC,	$AD, $AE, $AF, $AA, $AB, $A7, $A8, $A9,	$A1
		dc.b $B0, $B6, $B5, $B3, $B2, $B4, $BC,	$BD, $BE, $BF, $BA, $BB, $B7, $B8, $B9,	$B1
		dc.b $70, $76, $75, $73, $72, $74, $7C,	$7D, $7E, $7F, $7A, $7B, $77, $78, $79,	$71
		dc.b $80, $86, $85, $83, $82, $84, $8C,	$8D, $8E, $8F, $8A, $8B, $87, $88, $89,	$81
		dc.b $90, $96, $95, $93, $92, $94, $9C,	$9D, $9E, $9F, $9A, $9B, $97, $98, $99,	$91
		dc.b $10, $16, $15, $13, $12, $14, $1C,	$1D, $1E, $1F, $1A, $1B, $17, $18, $19,	$11


; ===========================================================================

; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97652:
					; ROM:00095D76p ...
		jmp	AnglePos
; End of function sub_97652


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97658:
		jmp	CheckLeftCeilingDist
; End of function sub_97658


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_9765E:
		jmp	CheckRightCeilingDist
; End of function sub_9765E


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97664:
					; sub_968F4:loc_9696Ep	...
		jmp	Sonic_CheckFloor
; End of function sub_97664


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_9766A:
		bra.w	sub_976A6
; End of function sub_9766A

; ===========================================================================
		rts

; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97670:
		bra.w	sub_976B6
; End of function sub_97670

; ===========================================================================
		rts
; ===========================================================================
; START	OF FUNCTION CHUNK FOR sub_95BE0

loc_97676:
		bra.w	loc_976E6
; END OF FUNCTION CHUNK	FOR sub_95BE0
; ===========================================================================
		rts
; ===========================================================================
; START	OF FUNCTION CHUNK FOR sub_95BE0

loc_9767C:
		bra.w	loc_97716
; END OF FUNCTION CHUNK	FOR sub_95BE0
; ===========================================================================
		rts

; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97682:
		jmp	CalcRoomInFront
; End of function sub_97682


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97688:
		jmp	CalcRoomOverHead
; End of function sub_97688


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_9768E:
					; sub_968F4:loc_9698Cp	...
		jmp	CheckLeftWallDist
; End of function sub_9768E


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97694:
					; sub_968F4:loc_969C6p	...
		jmp	CheckRightWallDist
; End of function sub_97694


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_9769A:
					; sub_968F4:loc_96A34p	...
		jmp	CheckCeilingDist
; End of function sub_9769A


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_976A6:
		move.b	width_pixels(a0),d0
		lsr.b	#1,d0
		ext.w	d0
		sub.w	d0,d2
		jmp	loc_1EFA2
; End of function sub_976A6

; ===========================================================================
		dc.b   0
		dc.b   0

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_976B6:
		move.b	width_pixels(a0),d0
		lsr.b	#1,d0
		ext.w	d0
		add.w	d0,d2
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	sub_976E0
		move.b	#0,d2
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_976DE
		move.b	d2,d3

locret_976DE:
		rts
; End of function sub_976B6


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_976E0:
		jmp	FindWall
; End of function sub_976E0

; ===========================================================================
; START	OF FUNCTION CHUNK FOR sub_95BE0

loc_976E6:
		move.b	width_pixels(a0),d0
		lsr.b	#1,d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		bsr.w	sub_97710
		move.b	#$C0,d2
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_9770E
		move.b	d2,d3

locret_9770E:
		rts
; END OF FUNCTION CHUNK	FOR sub_95BE0

; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97710:
		jmp	FindWall
; End of function sub_97710

; ===========================================================================
; START	OF FUNCTION CHUNK FOR sub_95BE0

loc_97716:
		move.b	width_pixels(a0),d0
		lsr.b	#1,d0
		ext.w	d0
		sub.w	d0,d3
		jmp	loc_1F06A
; END OF FUNCTION CHUNK	FOR sub_95BE0
; ===========================================================================
		dc.w 0


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_97C48:
		cmpi.b	#$F,d0
		bne.s	locret_97C62
		moveq	#0,d0
		move.b	($FFFFF7AA).w,d0
		beq.s	locret_97C62
		subq.w	#1,d0
		add.w	d0,d0
		move.w	off_97C64(pc,d0.w),d0
		jmp	off_97C64(pc,d0.w)
; ===========================================================================

locret_97C62:
		rts
; End of function sub_97C48

; ===========================================================================
off_97C64:	dc.w loc_97C76-off_97C64 ; DATA	XREF: ROM:off_97C64o
					; ROM:00097C66o ...
		dc.w loc_97C76-off_97C64
		dc.w loc_97C7C-off_97C64
		dc.w loc_97CE4-off_97C64
		dc.w loc_97D1A-off_97C64
		dc.w loc_97DA6-off_97C64
		dc.w loc_97DE0-off_97C64
		dc.w loc_97DE6-off_97C64
		dc.w locret_97C7A-off_97C64
; ===========================================================================

loc_97C76:
					; ROM:00097C66o
		move.b	$20(a1),d0

locret_97C7A:
		rts
; ===========================================================================

loc_97C7C:
		tst.b	($FFFFF73F).w
		bne.s	loc_97C84
		rts
; ===========================================================================

loc_97C84:
		move.w	d7,-(sp)
		moveq	#0,d1
		move.b	$15(a1),d1
		subq.b	#2,d1
		cmpi.b	#7,d1
		bgt.s	loc_97CC4
		move.w	d1,d7
		add.w	d7,d7
		move.w	8(a1),d0
		btst	#0,1(a1)
		beq.s	loc_97CAA
		add.w	word_97CCC(pc,d7.w),d0
		bra.s	loc_97CAE
; ===========================================================================

loc_97CAA:
		sub.w	word_97CCC(pc,d7.w),d0

loc_97CAE:
		move.b	loc_97CDC(pc,d1.w),d1
		ori.l	#$40000,d1
		move.w	$C(a1),d7
		subi.w	#$1C,d7
		bsr.w	sub_97E68

loc_97CC4:
		move.w	(sp)+,d7
		move.b	$20(a1),d0
		rts
; ===========================================================================
word_97CCC:	dc.w $1C
		dc.w $20
		dc.w $28
		dc.w $34
		dc.w $3C
		dc.w $44
		dc.w $60
		dc.w $70
; ===========================================================================

loc_97CDC:
		subi.b	#$C,d4
		move.b	(a4)+,d2
		move.l	a0,d2

loc_97CE4:
		move.w	d7,-(sp)
		move.w	8(a1),d0
		move.w	$C(a1),d7
		tst.b	($FFFFF73F).w
		beq.s	loc_97D12
		addi.w	#4,d7
		subi.w	#$50,d0	; 'P'
		btst	#0,1(a1)
		beq.s	loc_97D08
		addi.w	#$A0,d0	; '�'

loc_97D08:
		move.l	#$140010,d1
		bsr.w	sub_97E68

loc_97D12:
		move.w	(sp)+,d7
		move.b	$20(a1),d0
		rts
; ===========================================================================

loc_97D1A:
		sf	$38(a1)
		cmpi.b	#1,($FFFFF73F).w
		blt.s	loc_97D62
		move.w	d7,-(sp)
		move.w	8(a1),d0
		move.w	$C(a1),d7
		addi.w	#4,d7
		subi.w	#$30,d0	; '0'
		btst	#0,1(a1)
		beq.s	loc_97D44
		addi.w	#$60,d0	; '`'

loc_97D44:
		move.l	#$40004,d1
		bsr.w	sub_97E68
		move.w	(sp)+,d7
		move.b	$20(a1),d0
		cmpi.w	#$78,invulnerable_time(a0) ; 'x'
		bne.s	locret_97D60
		st	$38(a1)

locret_97D60:
		rts
; ===========================================================================

loc_97D62:
		move.w	d7,-(sp)
		movea.w	#$14,a5
		movea.w	#0,a4

loc_97D6C:
		move.w	8(a1),d0
		move.w	$C(a1),d7
		subi.w	#$20,d7	; ' '
		add.w	a5,d0
		move.l	#$100004,d1
		bsr.w	sub_97E68
		movea.w	#$FFEC,a5
		adda.w	#1,a4
		cmpa.w	#1,a4
		beq.s	loc_97D6C
		move.w	(sp)+,d7
		move.b	$20(a1),d0
		cmpi.w	#$78,invulnerable_time(a0) ; 'x'
		bne.s	locret_97DA4
		st	$38(a1)

locret_97DA4:
		rts
; ===========================================================================

loc_97DA6:
		tst.b	($FFFFF73F).w
		beq.s	loc_97DDA
		move.w	d7,-(sp)
		move.w	8(a1),d0
		move.w	$C(a1),d7
		addi.w	#$28,d7	; '('
		move.l	#$80010,d1
		cmpi.b	#1,($FFFFF73F).w
		beq.s	loc_97DD4
		move.w	#$20,d1	; ' '
		subi.w	#8,d7
		addi.w	#4,d0

loc_97DD4:
		bsr.w	sub_97E68
		move.w	(sp)+,d7

loc_97DDA:
		move.b	$20(a1),d0
		rts
; ===========================================================================

loc_97DE0:
		move.b	$20(a1),d0
		rts
; ===========================================================================

loc_97DE6:
		cmpi.b	#1,($FFFFF73F).w
		blt.s	loc_97E62
		beq.s	loc_97E38
		move.w	d7,-(sp)
		move.w	8(a1),d0
		move.w	$C(a1),d7
		moveq	#0,d1
		move.b	$B(a1),d1
		subq.b	#2,d1
		add.w	d1,d1
		btst	#0,1(a1)
		beq.s	loc_97E12
		add.w	word_97E2C(pc,d1.w),d0
		bra.s	loc_97E16
; ===========================================================================

loc_97E12:
		sub.w	word_97E2C(pc,d1.w),d0

loc_97E16:
		sub.w	word_97E2E(pc,d1.w),d7
		move.l	#$60008,d1
		bsr.w	sub_97E68
		move.w	(sp)+,d7
		move.w	#0,d0
		rts
; ===========================================================================
word_97E2C:	dc.w $14
word_97E2E:	dc.w 0
		dc.w $10
		dc.w $10
		dc.w $10
		dc.w $FFF0
; ===========================================================================

loc_97E38:
		move.w	d7,-(sp)
		move.w	8(a1),d0
		move.w	$C(a1),d7
		moveq	#$10,d1
		btst	#0,1(a1)
		beq.s	loc_97E4E
		neg.w	d1

loc_97E4E:
		sub.w	d1,d0
		move.l	#$8000C,d1
		bsr.w	sub_97E96
		move.w	(sp)+,d7
		move.b	#0,d0
		rts
; ===========================================================================

loc_97E62:
		move.b	$20(a1),d0
		rts

; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_97E68:
					; ROM:00097D0Ep ...
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.s	loc_97E76
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	loc_97E7A

locret_97E74:
					; sub_97E68+22j ...
		rts
; ===========================================================================

loc_97E76:
		cmp.w	d4,d0
		bhi.s	locret_97E74

loc_97E7A:
		swap	d1
		sub.w	d1,d7
		sub.w	d3,d7
		bcc.s	loc_97E8C
		add.w	d1,d1
		add.w	d1,d7
		bcs.w	Touch_ChkHurt
		bra.s	locret_97E74
; ===========================================================================

loc_97E8C:
		cmp.w	d5,d7
		bhi.w	locret_97E74
		bra.w	Touch_ChkHurt
; End of function sub_97E68


; ��������������� S U B	R O U T	I N E ���������������������������������������


sub_97E96:
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.s	loc_97EA4
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	loc_97EA8

locret_97EA2:
					; sub_97E96+22j ...
		rts
; ===========================================================================

loc_97EA4:
		cmp.w	d4,d0
		bhi.s	locret_97EA2

loc_97EA8:
		swap	d1
		sub.w	d1,d7
		sub.w	d3,d7
		bcc.s	loc_97EBA
		add.w	d1,d1
		add.w	d1,d7
		bcs.w	loc_97EC0
		bra.s	locret_97EA2
; ===========================================================================

loc_97EBA:
		cmp.w	d5,d7
		bhi.w	locret_97EA2

loc_97EC0:
		neg.w	x_vel(a0)
		neg.w	y_vel(a0)
		rts
; End of function sub_97E96


; ��������������� S U B	R O U T	I N E ���������������������������������������

; Attributes: thunk

sub_97ECA:
		jmp	AddPoints
; End of function sub_97ECA
