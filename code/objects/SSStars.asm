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
	beq.s	SS_Stars_CheckSpeed
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
	bne.s	SS_Stars_Display

SS_Stars_UpdatePos:
	move.w	(MainCharacter+x_pos).w,x_pos(a0)
	move.w	(MainCharacter+y_pos).w,y_pos(a0)

SS_Stars_Display:
	jmp	(DisplaySprite).l

SS_Stars_CheckSpeed:
	btst	#s3b_lock_motion,(MainCharacter+status3).w
	bne.s	SS_Stars_StopAnim
	mvabs.w	(MainCharacter+inertia).w,d0
	cmpi.w	#$800,d0
	blo.s	SS_Stars_StopAnim
	move.b	#0,mapping_frame(a0)
	move.b	#1,objoff_30(a0)
	bra.s	SS_Stars_UpdatePos

SS_Stars_StopAnim:
	move.b	#0,objoff_30(a0)
	move.b	#0,objoff_31(a0)
	rts

; ===========================================================================
; SS_Stars Data
; ---------------------------------------------------------------------------
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
