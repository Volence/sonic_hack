; ===========================================================================
; ----------------------------------------------------------------------------
; Surface of the water - water surface
; ----------------------------------------------------------------------------

Water_Surface:
	move.l	#Water_Surface_MapUnc_20A0E,mappings(a0)
	move.w	#$8400,art_tile(a0)
	move.b	#4,render_flags(a0)
	move.b	#$80,width_pixels(a0)
	move.w	#objroutine(Water_Surface_Action),(a0)	; go to routine Action

Water_Surface_Action:
	move.w	(Water_Level_1).w,d1
	move.w	d1,y_pos(a0)
	tst.b	anim(a0)
	bne.s	Water_Surface_Animate
	btst	#button_start,(Ctrl_1_Press).w	; is Start button pressed?
	beq.s	loc_20962			; if not, branch
	addq.b	#3,mapping_frame(a0)		; use different frames
	move.b	#1,anim(a0)			; stop animation
	bra.s	loc_20962

Water_Surface_Animate:
	tst.w	(Game_paused).w			; is the game paused?
	bne.s	loc_20962			; if yes, branch
	move.b	#0,anim(a0)			; resume animation
	subq.b	#3,mapping_frame(a0)		; use normal frames

loc_20962:
	lea	(Anim_Water_Surface).l,a1
	moveq	#0,d1
	move.b	anim_frame(a0),d1
	move.b	(a1,d1.w),mapping_frame(a0)
	addq.b	#1,anim_frame(a0)
	andi.b	#$3F,anim_frame(a0)
	jmp	DisplaySprite
