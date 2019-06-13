Path_Swapper_off32 = $32
Path_Swapper_off34 = $34
Path_Swapper_off35 = $35

; ===========================================================================
; ----------------------------------------------------------------------------
; Object 03 - Collision plane/layer switcher
; ----------------------------------------------------------------------------

Path_Swapper:
	move.l	#Path_Swapper_MapUnc_1FFB8,mappings(a0)
	move.w	#$26BC,art_tile(a0)
	ori.b	#4,render_flags(a0)
	move.b	#$10,width_pixels(a0)
	move.w	#$280,priority(a0)
	move.b	subtype(a0),d0
	btst	#2,d0
	beq.s	Path_Swapper_Init_CheckX

	andi.w	#7,d0
	move.b	d0,mapping_frame(a0)
	andi.w	#3,d0
	add.w	d0,d0
	move.w	word_1FD68(pc,d0.w),Path_Swapper_off32(a0)
	move.w	y_pos(a0),d1
	lea	(MainCharacter).w,a1 ; a1=character
	cmp.w	y_pos(a1),d1
	bhs.s	+
	move.b	#1,Path_Swapper_off34(a0)
+	lea	(Sidekick).w,a1 ; a1=character
	cmp.w	y_pos(a1),d1
	bhs.s	+
	move.b	#1,Path_Swapper_off35(a0)
+	move.w	#objroutine(Path_Swapper_MainY),(a0)
	bra.w	Path_Swapper_MainY
; ===========================================================================
word_1FD68:
	dc.w   $20
	dc.w   $40	; 1
	dc.w   $80	; 2
	dc.w  $100	; 3
; ===========================================================================

Path_Swapper_Init_CheckX:
	andi.w	#3,d0
	move.b	d0,mapping_frame(a0)
	add.w	d0,d0
	move.w	word_1FD68(pc,d0.w),Path_Swapper_off32(a0)
	move.w	x_pos(a0),d1
	lea	(MainCharacter).w,a1 ; a1=character
	cmp.w	x_pos(a1),d1
	bhs.s	+
	move.b	#1,Path_Swapper_off34(a0)
+	lea	(Sidekick).w,a1 ; a1=character
	cmp.w	x_pos(a1),d1
	bhs.s	+
	move.b	#1,Path_Swapper_off35(a0)
+	move.w	#objroutine(Path_Swapper_MainX),(a0)


Path_Swapper_MainX:
	tst.w	(Debug_placement_mode).w
	bne.w	return_1FEAC
	move.w	x_pos(a0),d1
	lea	Path_Swapper_off34(a0),a2
	lea	(MainCharacter).w,a1 ; a1=character
	bsr.s	+
	lea	(Sidekick).w,a1 ; a1=character

+	tst.b	(a2)+
	bne.s	Path_Swapper_MainX_Alt
	cmp.w	x_pos(a1),d1
	bhi.w	return_1FEAC
	move.b	#1,-1(a2)
	move.w	y_pos(a0),d2
	move.w	d2,d3
	move.w	Path_Swapper_off32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	y_pos(a1),d4
	cmp.w	d2,d4
	blt.w	return_1FEAC
	cmp.w	d3,d4
	bge.w	return_1FEAC
	move.b	subtype(a0),d0
	bpl.s	+
	btst	#1,status(a1)
	bne.w	return_1FEAC
+
	btst	#0,render_flags(a0)
	bne.s	+
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)
	btst	#3,d0
	beq.s	+
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)
+
	andi.w	#$7FFF,art_tile(a1)
	btst	#5,d0
	beq.s	return_1FEAC
	ori.w	#$8000,art_tile(a1)
	bra.s	return_1FEAC
; ===========================================================================

Path_Swapper_MainX_Alt:
	cmp.w	x_pos(a1),d1
	bls.w	return_1FEAC
	move.b	#0,-1(a2)
	move.w	y_pos(a0),d2
	move.w	d2,d3
	move.w	Path_Swapper_off32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	y_pos(a1),d4
	cmp.w	d2,d4
	blt.w	return_1FEAC
	cmp.w	d3,d4
	bge.w	return_1FEAC
	move.b	subtype(a0),d0
	bpl.s	+
	btst	#1,status(a1)
	bne.w	return_1FEAC
+
	btst	#0,render_flags(a0)
	bne.s	+
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)
	btst	#4,d0
	beq.s	+
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)
+
	andi.w	#$7FFF,art_tile(a1)
	btst	#6,d0
	beq.s	return_1FEAC
	ori.w	#$8000,art_tile(a1)

return_1FEAC:
	jmp	(MarkObjGone3).l
; ===========================================================================

Path_Swapper_MainY:
	tst.w	(Debug_placement_mode).w
	bne.w	return_1FFB6
	move.w	y_pos(a0),d1
	lea	Path_Swapper_off34(a0),a2
	lea	(MainCharacter).w,a1 ; a1=character
	bsr.s	+
	lea	(Sidekick).w,a1 ; a1=character

+	tst.b	(a2)+
	bne.s	Path_Swapper_MainY_Alt
	cmp.w	y_pos(a1),d1
	bhi.w	return_1FFB6
	move.b	#1,-1(a2)
	move.w	x_pos(a0),d2
	move.w	d2,d3
	move.w	Path_Swapper_off32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	x_pos(a1),d4
	cmp.w	d2,d4
	blt.w	return_1FFB6
	cmp.w	d3,d4
	bge.w	return_1FFB6
	move.b	subtype(a0),d0
	bpl.s	+
	btst	#1,status(a1)
	bne.w	return_1FFB6
+
	btst	#0,render_flags(a0)
	bne.s	+
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)
	btst	#3,d0
	beq.s	+
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)
+
	andi.w	#$7FFF,art_tile(a1)
	btst	#5,d0
	beq.s	return_1FFB6
	ori.w	#$8000,art_tile(a1)
	bra.s	return_1FFB6
; ===========================================================================

Path_Swapper_MainY_Alt:
	cmp.w	y_pos(a1),d1
	bls.w	return_1FFB6
	move.b	#0,-1(a2)
	move.w	x_pos(a0),d2
	move.w	d2,d3
	move.w	Path_Swapper_off32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	x_pos(a1),d4
	cmp.w	d2,d4
	blt.w	return_1FFB6
	cmp.w	d3,d4
	bge.w	return_1FFB6
	move.b	subtype(a0),d0
	bpl.s	+
	btst	#1,status(a1)
	bne.w	return_1FFB6
+
	btst	#0,render_flags(a0)
	bne.s	+
	move.b	#$C,layer(a1)
	move.b	#$D,layer_plus(a1)
	btst	#4,d0
	beq.s	+
	move.b	#$E,layer(a1)
	move.b	#$F,layer_plus(a1)
+
	andi.w	#$7FFF,art_tile(a1)
	btst	#6,d0
	beq.s	return_1FFB6
	ori.w	#$8000,art_tile(a1)

return_1FFB6:
	jmp	(MarkObjGone3).l
