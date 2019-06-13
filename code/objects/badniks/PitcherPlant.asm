; Object Offsets
PitcherPlant__Timer = $24

; Value Variables
PitcherPlant__WaitTime = $40
PitcherPlant__DistanceFromSonicToAttack = $60
PitcherPlant__BulletYSpeed = $300
PitcherPlant__BulletXSpeed = $100
PitcherPlant__Gravity = $20

; ===========================================================================
; ----------------------------------------------------------------------------
; Object 0B - Pitcher Plant Badnik
; ----------------------------------------------------------------------------
PitcherPlant:
	lea	PitcherPlant__Data(pc),a2
	jsr	Load_Object2

PitcherPlant__WaitSonic:
	tst.b	PitcherPlant__Timer(a0)
	bmi.b	+
	subq.b	#1,PitcherPlant__Timer(a0)
	bra.b	PitcherPlant__Display
+	lea		MainCharacter,a1
	move.w	x_pos(a1),d2
	move.w	x_pos(a0),d3
	sub.w	d2,d3
	btst	#0,render_flags(a0)
	bne.w	+
	bmi.w	PitcherPlant__Display
	cmp.w	#PitcherPlant__DistanceFromSonicToAttack,d3
	bge.w	PitcherPlant__Display
	move.w	#objroutine(PitcherPlant__ShootLeft),(a0)
	move.b	#$28,PitcherPlant__Timer(a0)
	bra.w	PitcherPlant__Display
+	bpl.w	PitcherPlant__Display
	cmp.w	#-PitcherPlant__DistanceFromSonicToAttack,d3
	ble.w	PitcherPlant__Display
	move.w	#objroutine(PitcherPlant__ShootLeft),(a0)
	move.b	#$28,PitcherPlant__Timer(a0)

PitcherPlant__Display:
	lea	PitcherPlant__Animate,a1
	jsr	AnimateSprite
	jsr	MarkObjGone
	jmp	DisplaySprite

PitcherPlant__ShootLeft:
	move.b	#2,anim(a0)
	subq.b	#1,PitcherPlant__Timer(a0)
	cmp.b	#16,PitcherPlant__Timer(a0)
	beq.s	PitcherPlant__BulletLoad
	tst.b	PitcherPlant__Timer(a0)
	bne.b	PitcherPlant__Display
	move.b	#PitcherPlant__WaitTime,PitcherPlant__Timer(a0)
	move.w	#objroutine(PitcherPlant__WaitSonic),(a0)
	move.b	#0,anim(a0)
	bra.b	PitcherPlant__Display

PitcherPlant__BulletLoad:
	lea	PitcherPlant__BulletData(pc),a2
	jsr	BadnikWeaponLoad
	sub.w	#$4,y_pos(a1)
	sub.w	#$10,x_pos(a1)
	btst	#0,render_flags(a0)
	beq.w	PitcherPlant__Display
	add.w	#$20,x_pos(a1)
	bra.w	PitcherPlant__Display

PitcherPlant__Bullet:
	cmpi.w	#$6F0,y_pos(a0)		; if below boundary, delete
	ble.b	+
	jmp	DeleteObject
+	addi.w	#PitcherPlant__Gravity,y_vel(a0)		; apply gravity (less than normal)
	jsr	ObjectMove
	jmp	DisplaySprite

PitcherPlant__Data:
		dc.w	objroutine(PitcherPlant__WaitSonic)
		dc.l	map_ppbadnik				; Mappings
		dc.w	$3A0						; Art Tile
		dc.b	4							; Render Flags
		dc.b	1							; Collision Response
		dc.w	$180						; Priority
		dc.b	$A							; Width Pixels
		dc.b	$12							; Height Pixels
		dc.b	0							; Animation
		dc.b	0							; Mapping Frame
	
PitcherPlant__BulletData:
		dc.w	objroutine(PitcherPlant__Bullet)	; Routine
		dc.l	map_ppbadnik				; Mappings
		dc.w	$3A0						; Art Tile
		dc.b	4							; Render Flags
		dc.b	7							; Collision Response
		dc.w	$100						; Priority
		dc.b	3							; Width Pixels
		dc.b	3							; Height Pixels
		dc.w	-PitcherPlant__BulletXSpeed						; X Velocity
		dc.w	-PitcherPlant__BulletYSpeed						; Y Velocity
		dc.b	1							; Animation
		dc.b	5							; Mapping Frame