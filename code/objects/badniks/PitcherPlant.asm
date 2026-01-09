; ===========================================================================
; Object 0B - Pitcher Plant Badnik
; ===========================================================================
; A template-quality object demonstrating best practices:
; - Data-driven loading via Load_Object2
; - Named constants for all magic numbers
; - VRAM constants from VRAM_Layout.asm
; - Global constants from S4.constants.asm
; ===========================================================================

; Object-specific RAM offsets (use $23-$3F for custom data)
PitcherPlant__Timer = $24

; Object-specific constants
PitcherPlant__WaitTime = $40                ; Frames to wait before shooting again
PitcherPlant__DistanceToAttack = $60       ; Distance from player to trigger attack
PitcherPlant__BulletYSpeed = $300           ; Initial Y velocity of projectile
PitcherPlant__BulletXSpeed = $100           ; Initial X velocity of projectile
PitcherPlant__Gravity = $20                 ; Gravity applied to projectile

; Animation indices
PitcherPlant__Anim_Idle = 0
PitcherPlant__Anim_Shoot = 2
PitcherPlant__Anim_Bullet = 1

; ===========================================================================
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
	cmp.w	#PitcherPlant__DistanceToAttack,d3
	bge.w	PitcherPlant__Display
	move.w	#objroutine(PitcherPlant__ShootLeft),(a0)
	move.b	#$28,PitcherPlant__Timer(a0)
	bra.w	PitcherPlant__Display
+	bpl.w	PitcherPlant__Display
	cmp.w	#-PitcherPlant__DistanceToAttack,d3
	ble.w	PitcherPlant__Display
	move.w	#objroutine(PitcherPlant__ShootLeft),(a0)
	move.b	#$28,PitcherPlant__Timer(a0)

PitcherPlant__Display:
	lea	PitcherPlant__Animate,a1
	jsr	AnimateSprite
	jsr	MarkObjGone
	jmp	DisplaySprite

PitcherPlant__ShootLeft:
	move.b	#PitcherPlant__Anim_Shoot,anim(a0)
	subq.b	#1,PitcherPlant__Timer(a0)
	cmp.b	#16,PitcherPlant__Timer(a0)
	beq.s	PitcherPlant__BulletLoad
	tst.b	PitcherPlant__Timer(a0)
	bne.b	PitcherPlant__Display
	move.b	#PitcherPlant__WaitTime,PitcherPlant__Timer(a0)
	move.w	#objroutine(PitcherPlant__WaitSonic),(a0)
	move.b	#PitcherPlant__Anim_Idle,anim(a0)
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
	cmpi.w	#LEVEL_BOTTOM_BOUNDARY,y_pos(a0)	; if below level boundary
	ble.b	+
	jmp	DeleteObject
+	addi.w	#PitcherPlant__Gravity,y_vel(a0)	; apply gravity
	jsr	ObjectMove
	jmp	DisplaySprite

; ===========================================================================
; Object Data Block - Format matches Load_Object2
; ===========================================================================
PitcherPlant__Data:
		dc.w	objroutine(PitcherPlant__WaitSonic)	; Routine offset
		dc.l	map_ppbadnik				; Mappings
		dc.w	VRAM_PitcherPlant			; Art tile (uses VRAM constant!)
		dc.b	4					; Render flags
		dc.b	1					; Collision response
		dc.w	$180					; Priority
		dc.b	$A					; Width pixels
		dc.b	$12					; Height pixels
		dc.b	PitcherPlant__Anim_Idle			; Animation
		dc.b	0					; Mapping frame
	
PitcherPlant__BulletData:
		dc.w	objroutine(PitcherPlant__Bullet)	; Routine
		dc.l	map_ppbadnik				; Mappings
		dc.w	VRAM_PitcherPlant			; Art tile (shares with parent)
		dc.b	4					; Render flags
		dc.b	7					; Collision response (projectile)
		dc.w	$100					; Priority
		dc.b	3					; Width pixels
		dc.b	3					; Height pixels
		dc.w	-PitcherPlant__BulletXSpeed		; X velocity
		dc.w	-PitcherPlant__BulletYSpeed		; Y velocity
		dc.b	PitcherPlant__Anim_Bullet		; Animation
		dc.b	5					; Mapping frame