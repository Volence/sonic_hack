Pitcher_Plant_Badnik_timer = $24

; ===========================================================================
; ----------------------------------------------------------------------------
; Object 0B - Pitcher Plant Badnik
; ----------------------------------------------------------------------------
Pitcher_Plant_Badnik:
	lea	Pitcher_Plant_Badnik_Data(pc),a2
	jsr	Load_Object2

Pitcher_Plant_Badnik_WaitSonic:
	tst.b	Pitcher_Plant_Badnik_timer(a0)
	bmi.b	+
	subq.b	#1,Pitcher_Plant_Badnik_timer(a0)
	bra.b	Pitcher_Plant_Badnik_Display
+	lea	($FFFFB000).w,a1
	move.w	x_pos(a1),d2
	move.w	x_pos(a0),d3
	sub.w	d2,d3
	btst	#0,render_flags(a0)
	bne.w	+
	bmi.w	Pitcher_Plant_Badnik_Display
	cmp.w	#$60,d3
	bge.w	Pitcher_Plant_Badnik_Display
	move.w	#objroutine(Pitcher_Plant_Badnik_ShootLeft),(a0)
	move.b	#$28,Pitcher_Plant_Badnik_timer(a0)
	bra.w	Pitcher_Plant_Badnik_Display
+	bpl.w	Pitcher_Plant_Badnik_Display
	cmp.w	#-$60,d3
	ble.w	Pitcher_Plant_Badnik_Display
	move.w	#objroutine(Pitcher_Plant_Badnik_ShootLeft),(a0)
	move.b	#$28,Pitcher_Plant_Badnik_timer(a0)

Pitcher_Plant_Badnik_Display:
	lea	Pitcher_Plant_Badnik_Animate,a1
	jsr	AnimateSprite
	jsr	MarkObjGone
	jmp	DisplaySprite

Pitcher_Plant_Badnik_ShootLeft:
	move.b	#2,anim(a0)
	subq.b	#1,Pitcher_Plant_Badnik_timer(a0)
	cmp.b	#16,Pitcher_Plant_Badnik_timer(a0)
	beq.s	Pitcher_Plant_Badnik_BulletLoad
	tst.b	Pitcher_Plant_Badnik_timer(a0)
	bne.b	Pitcher_Plant_Badnik_Display
	move.b	#$40,Pitcher_Plant_Badnik_timer(a0)
	move.w	#objroutine(Pitcher_Plant_Badnik_WaitSonic),(a0)
	move.b	#0,anim(a0)
	bra.b	Pitcher_Plant_Badnik_Display

Pitcher_Plant_Badnik_BulletLoad:
	lea	Pitcher_Plant_Badnik_BulletData(pc),a2
	jsr	BadnikWeaponLoad
	sub.w	#$4,y_pos(a1)
	sub.w	#$10,x_pos(a1)
	btst	#0,render_flags(a0)
	beq.w	Pitcher_Plant_Badnik_Display
	add.w	#$20,x_pos(a1)
	bra.w	Pitcher_Plant_Badnik_Display

Pitcher_Plant_Badnik_Bullet:
	cmpi.w	#$6F0,y_pos(a0)		; if below boundary, delete
	ble.b	+
	jmp	DeleteObject
+	addi.w	#$20,y_vel(a0)		; apply gravity (less than normal)
	jsr	ObjectMove
	jmp	DisplaySprite

Pitcher_Plant_Badnik_Data:
		dc.w	objroutine(Pitcher_Plant_Badnik_WaitSonic)
		dc.l	map_ppbadnik				; Mappings
		dc.w	$3A0						; Art Tile
		dc.b	4							; Render Flags
		dc.b	1							; Collision Response
		dc.w	$180						; Priority
		dc.b	$A							; Width Pixels
		dc.b	$12							; Height Pixels
		dc.b	0							; Animation
		dc.b	0							; Mapping Frame
	
Pitcher_Plant_Badnik_BulletData:
		dc.w	objroutine(Pitcher_Plant_Badnik_Bullet)	; Routine
		dc.l	map_ppbadnik				; Mappings
		dc.w	$3A0						; Art Tile
		dc.b	4							; Render Flags
		dc.b	7							; Collision Response
		dc.w	$100						; Priority
		dc.b	3							; Width Pixels
		dc.b	3							; Height Pixels
		dc.w	-$100						; X Velocity
		dc.w	-$300						; Y Velocity
		dc.b	1							; Animation
		dc.b	5							; Mapping Frame