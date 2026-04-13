; ---------------------------------------------------------------------------
; Object touch response subroutine - $20(a0) in the object RAM
; collides Sonic with most objects (enemies, rings, monitors...) in the level
; ---------------------------------------------------------------------------
; a0 - whatever's calling this, most of the time it's the character
; d0 - Main Object X Pos
; d1 - Main Object Y Pos
; d2 - Secondary Object Width/Height
; d3 - Secondary Object X Pos/Y Pos
; d4 - Main Object Width
; d5 - Main Object Height

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

TouchResponse:
	moveq	#0,d6
	jsr		(Touch_Rings).l ; Check ring collision
    moveq   #0,d6 
	lea		(Dynamic_Object_RAM).w,a1 ; Load object address
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d6 ; Get how many objects there are
	move.w	x_pos(a0),d0
	move.w	y_pos(a0),d1
	move.b	width_pixels(a0),d4
	move.b	height_pixels(a0),d5	
	ext.w	d4
	ext.w	d5

TouchResponse__ObjectLoop:        
	lea     $40(a1),a1	; load the next object
    tst.b   collision_response(a1)	; check if it has any collision flags
    bne.s   TouchResponse__WidthCheck	; if it does, branch
    dbf		d6,TouchResponse__ObjectLoop	; if not, repeat the loop and subtract 1 from the amount of objects
    rts

; Checks if the main object 
TouchResponse__WidthCheck:
	sub.w	#1,d6	; Lower the object count by 1
	move.b	width_pixels(a1),d2
	ext.w	d2
	move.w	x_pos(a1),d3

TouchResponse__WidthCheckRight:	
	sub.w	d0,d3	; d3 = obj_x - char_x
	bhs.s	TouchResponse__WidthCheckLeft ; if char_x <= obj_x, branch
	lsl.w	#1,d2
	add.w	d2,d3
	bcs.s	TouchResponse__HeightCheck
	bra.s	TouchResponse__ObjectLoop

TouchResponse__WidthCheckLeft:
	add.w	d4,d2			; d2 = obj_width + char_width (expanded left zone)
	cmp.w	d2,d3			; d2 is safe to modify, reloaded at HeightCheck
	bhi.w	TouchResponse__ObjectLoop

TouchResponse__HeightCheck:
	move.b	height_pixels(a1),d2
	ext.w	d2
	move.w	y_pos(a1),d3

TouchResponse__HeightCheckAbove:
	sub.w	d1,d3	; d3 = obj_y - char_y
	bcc.s	TouchResponse__HeightCheckBelow ; if char_y <= obj_y, branch
	lsl.w	#1,d2
	add.w	d2,d3
	bcs.s	TouchResponse__InitTouchedObject
	bra.w	TouchResponse__ObjectLoop

TouchResponse__HeightCheckBelow:
	cmp.w	d5,d3
	bhi.w	TouchResponse__ObjectLoop

TouchResponse__InitTouchedObject:
	bset	#7,mappings(a1)
	moveq	#$00,d1
	move.b	collision_response(a1),d1
	ext.w	d1
	add.w	d1,d1
	add.w	d1,d1
	jmp	TouchResponse__ResponseTypeTable(pc,d1.w)
	
TouchResponse__ResponseTypeTable:
	bra.w		Touch_Enemy		; 0
	bra.w		Touch_Enemy		; 1
	bra.w		Touch_Boss		; 2
	bra.w		Touch_ChkHurt	; 3
	bra.w		Touch_Monitor	; 4
	bra.w		Touch_Ring		; 5
	bra.w		Touch_Bubble	; 6
	bra.w		Touch_Projectile	; 7
	bra.w		Touch_Solid		; 8 - Solid object
	bra.w		Touch_SolidBreakable	; 9 - Solid, but breakable when spinning/jumping
	bra.w		Touch_Spring		; 10 - Spring (solid + directional bounce)
; ===========================================================================

; ---------------------------------------------------------------------------
; Touch_Spring - Spring collision response (type 10)
; ---------------------------------------------------------------------------
; Solid object that bounces the character from its active face.
; Reads orientation from subtype(a1) bits 3-5:
;   0=up, 2=side, 4=down, 6/8=diagonal (falls through to Touch_Solid)
; Spring force is in objoff_30(a1).
; Facing direction for side springs is status(a1) bit 0.
;
; Input (from TouchResponse dispatcher):
;   a0 = character (Sonic/Tails/Knuckles)
;   a1 = spring object
;   d6 = loop counter (MUST BE PRESERVED)
; ---------------------------------------------------------------------------
; --- Data table for spring routine changes (placed before handler) ---
	bra.w	Touch_Spring_Start
Touch_Spring_CtrlTable:
	dc.w	objroutine(Sonic_Control)
	dc.w	objroutine(Sonic_Control)
	dc.w	objroutine(Tails_Control)
	dc.w	objroutine(Knuckles_Control)

Touch_Spring_Start:
Touch_Spring:
	bclr	#7,mappings(a1)
	; Get spring orientation from subtype bits 3-5
	move.b	subtype(a1),d0
	lsr.w	#3,d0
	andi.w	#$E,d0
	
	tst.w	d0
	beq.s	.spring_up_check
	cmpi.w	#2,d0
	beq.w	.spring_side_check
	cmpi.w	#4,d0
	beq.w	.spring_down_check
	bra.w	Touch_Solid

; --- UP ---
.spring_up_check:
	move.w	y_pos(a0),d1
	cmp.w	y_pos(a1),d1
	bge.w	Touch_Solid
	tst.w	y_vel(a0)
	bmi.w	Touch_Solid
	move.w	#$100,anim(a1)		; spring bounce animation
	addq.w	#8,y_pos(a0)		; nudge down
	move.w	objoff_30(a1),y_vel(a0)
	bset	#1,status(a0)
	bclr	#3,status(a0)
	move.b	#$10,anim(a0)		; spring bounce char animation
	; Reset character control routine
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	lea	Touch_Spring_CtrlTable(pc),a2
	move.w	(a2,d0.w),(a0)
	move.w	#SndID_Spring,d0
	jmp	(PlaySound).l

; --- SIDE ---
.spring_side_check:
	move.w	x_pos(a0),d1
	sub.w	x_pos(a1),d1
	btst	#0,status(a1)
	bne.s	.side_face_left
	tst.w	d1
	ble.w	Touch_Solid
	bra.s	.do_side_bounce
.side_face_left:
	tst.w	d1
	bge.w	Touch_Solid
.do_side_bounce:
	move.w	objoff_30(a1),x_vel(a0)	; starts negative
	btst	#0,status(a1)
	bne.s	.side_skip_neg		; bit 0=1 (left-facing) - keep negative
	neg.w	x_vel(a0)		; bit 0=0 (right-facing) - negate to positive
.side_skip_neg:
	move.w	x_vel(a0),inertia(a0)
	move.w	#SndID_Spring,d0
	jmp	(PlaySound).l

; --- DOWN ---
.spring_down_check:
	move.w	y_pos(a0),d1
	cmp.w	y_pos(a1),d1
	ble.w	Touch_Solid
	tst.w	y_vel(a0)
	bpl.w	Touch_Solid
	move.w	objoff_30(a1),y_vel(a0)
	neg.w	y_vel(a0)
	bset	#1,status(a0)
	bclr	#3,status(a0)
	move.w	#SndID_Spring,d0
	jmp	(PlaySound).l

; ---------------------------------------------------------------------------
; Touch_SolidBreakable - Solid object that breaks when character is in ball form
; ---------------------------------------------------------------------------
; If character is spinning (anim == 2), trigger break via ckhit mechanism.
; Otherwise, fall through to Touch_Solid for normal solid behavior.
; ---------------------------------------------------------------------------
Touch_SolidBreakable:
	cmpi.b	#2,anim(a0)		; is character in ball form?
	bne.w	Touch_Solid		; if not, handle as normal solid
	; Character is spinning - trigger break
	; Reverse character's Y velocity (bounce off)
	neg.w	y_vel(a0)
	; Set the object's break flag (bit 7 of mappings) 
	; so the object's ckhit macro will trigger on the next frame
	bset	#7,mappings(a1)
	; Store which character broke it
	move.w	a0,parent(a1)
	rts

; ---------------------------------------------------------------------------
; Touch_Solid - Handle collision with solid object
; ---------------------------------------------------------------------------
; Input (from TouchResponse dispatcher):
;   a0 = character (Sonic/Tails/Knuckles)
;   a1 = object being collided with
;   d6 = loop counter (MUST BE PRESERVED)
; 
; This routine determines which side of the object was hit and responds:
;   - Left/Right: Stop momentum, set pushing flags if grounded
;   - Top: Land on object, exit ball form if needed
;   - Bottom: Bump head, reverse upward velocity
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; Touch_Solid - Solid object collision handler (collision_response = 8)
; ---------------------------------------------------------------------------
; This routine handles collision between characters and solid objects.
; It is called by TouchResponse when the character's AABB overlaps the object.
;
; ARCHITECTURE:
; Touch_Solid handles collision detection and response WHILE the character
; is within the object's TouchResponse AABB. However, edge detection (for
; walking/rolling off platforms) must be handled by the OBJECT ITSELF in
; its main loop, because when a character leaves the AABB, TouchResponse
; no longer calls Touch_Solid.
;
; For proper edge detection, objects should implement the PlatformObject
; pattern in their main loop (see Monitor's ObjMonitor_EdgeCheck):
;   1. Check if character's in-air bit is SET -> fall off
;   2. Check if character is within X bounds -> stay on or fall off
;
; COLLISION TYPES:
; - Top: Character lands on object (y_vel > 0, feet overlap top)
; - Bottom: Character hits head on object (y_vel < 0, head overlaps bottom)
; - Side: Character pushed left or right based on position
;
; REGISTERS:
;   a0 = Character (Sonic/Tails)
;   a1 = Object being collided with
;   d6 = Loop counter from TouchResponse (preserved)
; ---------------------------------------------------------------------------

Touch_Solid:
	; Preserve all registers we'll use (critical for dispatcher loop)
	movem.l	d0-d5,-(sp)
	
	; Clear the "touched" bit that TouchResponse sets - this prevents
	; the rendering engine from hiding the object and prevents ckhit from
	; triggering object-specific break logic on side collisions
	bclr	#7,mappings(a1)
	
	; =================================================================
	; Step 1: Calculate edges and overlaps
	; =================================================================
	; Calculate object edges (full dimensions stored in SST)
	moveq	#0,d4
	move.b	width_pixels(a1),d4	; obj half-width
	lsr.w	#1,d4
	moveq	#0,d5
	move.b	height_pixels(a1),d5	; obj half-height
	lsr.w	#1,d5
	
	; Object edges
	move.w	x_pos(a1),d0
	move.w	d0,d2
	sub.w	d4,d0			; d0 = obj left edge
	add.w	d4,d2			; d2 = obj right edge
	
	move.w	y_pos(a1),d1
	move.w	d1,d3
	sub.w	d5,d1			; d1 = obj top edge
	add.w	d5,d3			; d3 = obj bottom edge
	
	; Get character edges
	moveq	#0,d4
	move.b	width_pixels(a0),d4	; char half-width
	lsr.w	#1,d4
	moveq	#0,d5
	move.b	height_pixels(a0),d5	; char half-height
	lsr.w	#1,d5
	
	; Character edges
	move.w	x_pos(a0),a2		; use a2 temporarily for char_x
	move.w	a2,d4
	; char left = x_pos - half_width, char right = x_pos + half_width
	; We need: push amounts for each side
	
	; =================================================================
	; Step 2: Determine collision side using velocity priority
	; =================================================================
	; Key insight: Use velocity to prioritize collision type
	; - If moving horizontally and grounded: side collision
	; - If falling: top collision possible
	; - If rising: bottom collision possible
	
	; Check if character is in the air
	btst	#1,status(a0)
	beq.w	.ts_grounded
	
	; --- CHARACTER IN AIR ---
	; Prioritize vertical collisions based on y_vel
	tst.w	y_vel(a0)
	bmi.w	.ts_air_rising		; Rising - check bottom collision
	beq.w	.ts_air_stationary	; y_vel = 0 - might be rolling on object
	
	; Falling (y_vel > 0) - check for top collision
	; Don't interrupt active insta-shield/double jump
	btst	#s2b_doublejump,status2(a0)
	bne.w	.ts_exit		; Double jump/insta-shield active - don't land
	
	; Is character above the object's top?
	move.w	y_pos(a0),d4
	moveq	#0,d5
	move.b	height_pixels(a0),d5
	lsr.w	#1,d5
	add.w	d5,d4			; d4 = char bottom edge
	cmp.w	d1,d4			; compare to obj top
	blt.w	.ts_exit		; char is above, no collision yet
	
	; Character overlaps Y - check if also within X bounds before landing
	; (Prevent landing when to the side of the object)
	; Use relative position: char_x - obj_x, compare to half-width
	move.w	x_pos(a0),d4
	sub.w	x_pos(a1),d4		; d4 = char_x - obj_x (relative)
	moveq	#0,d5
	move.b	width_pixels(a1),d5
	lsr.w	#1,d5			; d5 = obj half-width
	
	; Check if character is within [-half_width, +half_width] of obj center
	move.w	d5,d3
	neg.w	d3			; d3 = -half_width
	cmp.w	d3,d4
	blt.w	.ts_exit		; char left of object - no collision
	cmp.w	d5,d4
	bgt.w	.ts_exit		; char right of object - no collision
	
	; Within X bounds - do top landing
	bra.w	.ts_do_top

.ts_air_stationary:
	; y_vel = 0 but in "air" - this can happen when rolling on an object
	; Use position-based detection instead of relying on bit 3
	; (bit 3 might be cleared when entering ball form)
	
	; Get object top edge
	move.w	y_pos(a1),d4
	moveq	#0,d5
	move.b	height_pixels(a1),d5
	lsr.w	#1,d5
	sub.w	d5,d4			; d4 = obj top edge
	
	; Get character feet position
	move.w	y_pos(a0),d5
	moveq	#0,d3
	move.b	height_pixels(a0),d3
	lsr.w	#1,d3
	add.w	d3,d5			; d5 = char feet position
	
	; Check if feet are at the top surface (within 15 pixels to be safe)
	sub.w	d4,d5			; d5 = feet - obj_top
	cmpi.w	#15,d5
	bgt.w	.ts_exit		; Feet too far below - not on object
	cmpi.w	#-5,d5
	blt.w	.ts_exit		; Feet too far above - not on object
	
	; Character feet are on top - go directly to X bounds check
	bra.w	.ts_check_x_bounds

.ts_air_rising:
	; Rising - check for bottom collision (head bump)
	move.w	y_pos(a0),d4
	moveq	#0,d5
	move.b	height_pixels(a0),d5
	lsr.w	#1,d5
	sub.w	d5,d4			; d4 = char top edge
	cmp.w	d3,d4			; compare to obj bottom
	bgt.w	.ts_exit		; char is below, no collision
	
	; Character overlaps Y - check X bounds before head bump
	move.w	x_pos(a0),d4
	sub.w	x_pos(a1),d4		; d4 = char_x - obj_x (relative)
	moveq	#0,d5
	move.b	width_pixels(a1),d5
	lsr.w	#1,d5			; d5 = obj half-width
	
	; Check if within [-half_width, +half_width] of obj center
	move.w	d5,d3
	neg.w	d3			; d3 = -half_width
	cmp.w	d3,d4
	blt.w	.ts_exit		; char left of object - no collision
	cmp.w	d5,d4
	bgt.w	.ts_exit		; char right of object - no collision
	
	; Within X bounds - head bump
	bra.w	.ts_do_bottom

.ts_grounded:
	; --- CHARACTER ON GROUND ---
	; Use position-based detection for all cases (walking, rolling, etc.)
	; First check if character is positioned ON TOP of the object
	
	; Get object top edge
	move.w	y_pos(a1),d4
	moveq	#0,d5
	move.b	height_pixels(a1),d5
	lsr.w	#1,d5
	sub.w	d5,d4			; d4 = obj top edge
	
	; Get character feet position (y_pos + half-height)
	move.w	y_pos(a0),d5
	moveq	#0,d3
	move.b	height_pixels(a0),d3
	lsr.w	#1,d3
	add.w	d3,d5			; d5 = char feet position
	
	; Check if feet are at the top surface (within 10 pixels)
	; If so, we're on top of the object, not beside it
	sub.w	d4,d5			; d5 = feet - obj_top
	cmpi.w	#10,d5
	ble.s	.ts_check_x_bounds	; Feet near top - might be standing on it
	
	; Feet are below the top - check if we actually overlap vertically
	; for side collision (character body overlaps object body)
	; Get object bottom
	move.w	y_pos(a1),d4
	moveq	#0,d5
	move.b	height_pixels(a1),d5
	lsr.w	#1,d5
	add.w	d5,d4			; d4 = obj bottom
	
	; Get character head position
	move.w	y_pos(a0),d5
	moveq	#0,d3
	move.b	height_pixels(a0),d3
	lsr.w	#1,d3
	sub.w	d3,d5			; d5 = char head (top)
	
	; If char head is below obj bottom, no side collision (walking past behind)
	cmp.w	d4,d5
	bgt.w	.ts_exit		; char head below obj bottom - no collision
	
	; Character overlaps object vertically - do side collision
	bra.w	.ts_do_side_collision
	
	; Character feet are ON TOP of the object
.ts_check_x_bounds:
	; Check X bounds for fall-off
	; Account for character width - stay on as long as collision boxes overlap
	moveq	#0,d5
	move.b	width_pixels(a1),d5
	lsr.w	#1,d5			; d5 = obj half-width
	moveq	#0,d3
	move.b	width_pixels(a0),d3
	lsr.w	#1,d3			; d3 = char half-width
	
	move.w	x_pos(a1),d4		; obj center x
	move.w	d4,d1			; save for right edge
	sub.w	d5,d4
	sub.w	d3,d4			; d4 = obj left edge - char half (leftmost char center)
	add.w	d5,d1
	add.w	d3,d1			; d1 = obj right edge + char half (rightmost char center)
	
	move.w	x_pos(a0),d5
	cmp.w	d4,d5
	blt.s	.ts_fall_off		; char right edge past obj left edge
	cmp.w	d1,d5
	bgt.s	.ts_fall_off		; char left edge past obj right edge
	
	; On top and within bounds
	; Always reposition Y on top of object every frame
	bset	#3,status(a1)		; Sonic standing on me (object status)
	btst	#3,status(a0)
	beq.s	.ts_first_land		; First time - do full landing setup
	
	; Already standing - reposition Y to stay snapped on top
	move.w	y_pos(a1),d4		; obj center y
	moveq	#0,d5
	move.b	height_pixels(a1),d5
	lsr.w	#1,d5
	sub.w	d5,d4			; d4 = obj top edge
	move.w	#19,d5			; standing half-height
	sub.w	d5,d4			; d4 = where char center should be
	move.w	d4,y_pos(a0)		; snap Y on top
	bra.w	.ts_exit
	
.ts_first_land:
	; First time landing - set character flags too
	bset	#3,status(a0)		; on object (character status)
	bclr	#1,status(a0)		; not in air
	move.w	a1,interact_obj(a0)
	bra.w	.ts_exit

.ts_fall_off:
	; Character walked/rolled off the edge - put them in the air
	bclr	#3,status(a0)		; Clear "on object" bit
	bset	#1,status(a0)		; Set "in air" bit
	clr.w	interact_obj(a0)	; Clear interact object
	move.w	#$80,y_vel(a0)		; Initial downward velocity
	; Clear the object's "being stood on" bit
	movem.l	(sp)+,d0-d5
	movem.l	d6,-(sp)
	moveq	#3,d4			; bit 3 for main character
	bclr	d4,status(a1)
	movem.l	(sp)+,d6
	rts

.ts_do_side_collision:
	; Calculate penetration delta using object width only
	; d0 = offset from object left edge to character center
	move.w	x_pos(a0),d0		; char_x
	sub.w	x_pos(a1),d0		; char_x - obj_x
	move.b	width_pixels(a1),d1
	ext.w	d1			; d1 = obj half-width
	add.w	d1,d0			; d0 = offset from obj left edge to char center
	
	; Get character half-width for boundary calculations
	moveq	#0,d4
	move.b	width_pixels(a0),d4
	lsr.w	#1,d4			; d4 = char half-width
	
	; Entry check: d0 + char_half represents char RIGHT edge position
	; If char right edge is left of obj left edge (d0 + char_half < 0), exit
	move.w	d0,d5
	add.w	d4,d5			; d5 = d0 + char_half
	bmi.w	.ts_exit		; char right edge is left of obj left edge
	
	; d3 = full object width
	move.w	d1,d3
	add.w	d3,d3			; d3 = obj full width
	cmp.w	d3,d0
	bhi.w	.ts_exit		; char center is right of object right edge
	
	; Character overlaps object - determine which side
	; If d0 < half_width (center in left half), push left
	; If d0 >= half_width (center in right half), push right
	cmp.w	d0,d1
	bhi.s	.ts_push_left
	
.ts_push_right:
	; Push character to the right
	; delta = full_width - d0
	sub.w	d0,d3			; d3 = delta
	beq.s	.ts_exit_no_push	; delta = 0, no actual collision
	add.w	d3,x_pos(a0)
	clr.w	2+x_pos(a0)		; clear sub-pixel to prevent drift
	bra.s	.ts_side_common

.ts_push_left:
	; Push character so right edge aligns with object's left visual edge
	; Visual left edge = obj_x - obj_width/2 (true half)
	; Target: char_x + char_half = obj_x - obj_width/2
	; In handler coords: target d0 = obj_width/2 - char_half
	; Push amount = d0 - target = d0 - obj_width/2 + char_half
	move.w	d0,d5
	add.w	d4,d5			; d5 = d0 + char_half
	move.w	d1,d3
	lsr.w	#1,d3			; d3 = obj_width/2 (true half-width)
	sub.w	d3,d5			; d5 = d0 + char_half - obj_half = push amount
	ble.s	.ts_exit_no_push	; delta <= 0, already at or past edge
	sub.w	d5,x_pos(a0)		; push left by delta
	clr.w	2+x_pos(a0)		; clear sub-pixel to prevent drift

.ts_side_common:
	clr.w	x_vel(a0)
	clr.w	inertia(a0)
	
	; Set pushing if grounded
	btst	#1,status(a0)
	bne.w	.ts_exit
	bset	#5,status(a0)
	
	movem.l	(sp)+,d0-d5
	movem.l	d6,-(sp)
	addq.b	#2,d6
	bset	d6,status(a1)
	movem.l	(sp)+,d6
	rts

.ts_exit_no_push:
	; Character is at boundary edge with zero push delta
	; Only block movement if character is pressing INTO the object
	; d0 = offset from left edge, d1 = obj_width (both preserved)
	cmp.w	d1,d0
	bhs.s	.ts_np_right		; d0 >= d1 → character on right side
	; Left side: only block if pressing rightward (into object)
	tst.w	inertia(a0)
	ble.w	.ts_exit		; inertia <= 0 → moving away or stopped, let go
	bra.s	.ts_np_block
.ts_np_right:
	; Right side: only block if pressing leftward (into object)
	tst.w	inertia(a0)
	bge.w	.ts_exit		; inertia >= 0 → moving away or stopped, let go
.ts_np_block:
	clr.w	x_vel(a0)
	clr.w	inertia(a0)
	clr.w	2+x_pos(a0)		; clear sub-pixel to prevent drift
	btst	#1,status(a0)
	bne.w	.ts_exit		; in air, don't set pushing
	bset	#5,status(a0)		; set pushing flag to prevent velocity gain
	bra.w	.ts_exit

.ts_do_top:
	; Land character on top of object
	; First, calculate the object's top edge
	move.w	y_pos(a1),d4		; obj center y
	moveq	#0,d5
	move.b	height_pixels(a1),d5
	lsr.w	#1,d5
	sub.w	d5,d4			; d4 = obj top edge
	
	; Use standing half-height (19) for position calculation
	; This ensures consistent landing whether in ball form or not
	; (we'll exit ball form after landing anyway)
	move.w	#19,d5			; $26/2 = 19 (standing half-height)
	sub.w	d5,d4			; d4 = where char center should be
	move.w	d4,y_pos(a0)		; Set position
	
	; Set up standing on object
	clr.w	y_vel(a0)
	move.w	x_vel(a0),inertia(a0)
	clr.b	angle(a0)
	bset	#3,status(a0)		; on object
	bclr	#1,status(a0)		; not in air
	bclr	#5,status(a0)		; not pushing
	move.w	a1,interact_obj(a0)
	
	; Exit ball form if needed (position already calculated for standing)
	btst	#2,status(a0)
	beq.s	.ts_top_done
	bclr	#2,status(a0)
	bclr	#4,status(a0)
	move.b	#$26,height_pixels(a0)
	move.b	#18,width_pixels(a0)
	clr.b	anim(a0)

.ts_top_done:
	bclr	#s3b_jumping,status3(a0)
	bclr	#s2b_doublejump,status2(a0)
	
	movem.l	(sp)+,d0-d5
	movem.l	d6,-(sp)
	addq.b	#2,d6
	bset	d6,status(a1)
	movem.l	(sp)+,d6
	rts

.ts_do_bottom:
	; Head bump - push character down
	move.w	y_pos(a1),d4		; obj center y
	moveq	#0,d5
	move.b	height_pixels(a1),d5
	lsr.w	#1,d5
	add.w	d5,d4			; d4 = obj bottom edge
	moveq	#0,d5
	move.b	height_pixels(a0),d5
	lsr.w	#1,d5
	add.w	d5,d4			; d4 = where char center should be
	addq.w	#1,d4			; 1 pixel below
	move.w	d4,y_pos(a0)
	clr.w	y_vel(a0)

.ts_exit:
	movem.l	(sp)+,d0-d5
	rts

; ===========================================================================

Touch_Enemy:
	move.b	status2(a0),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	loc_3F7A6			; if so, branch
    cmpi.b	#2,anim(a0)
    bne.w	Touch_ChkHurt

loc_3F7A6:
	neg.w	y_vel(a0)
	move.b	#0,collision_response(a1)

Touch_KillEnemy:
	bset	#7,status(a1)
	moveq	#0,d0
	move.w	(Chain_Bonus_counter).w,d0
	addq.w	#2,(Chain_Bonus_counter).w	; add 2 to chain bonus counter
	cmpi.w	#6,d0
	blo.s	loc_3F802
	moveq	#6,d0

loc_3F802:
	move.w	Enemy_Points(pc,d0.w),d0
	cmpi.w	#$20,(Chain_Bonus_counter).w	; have 16 enemies been destroyed?
	blo.s	loc_3F81C			; if not, branch
	move.w	#1000,d0			; fix bonus to 10000 points

loc_3F81C:
	movea.w	a0,a3
	move.w	#objroutine(Explosion_FromEnemy),(a1)
	tst.w	y_vel(a0)
	bmi.s	loc_3F844
	move.w	y_pos(a0),d0
	cmp.w	y_pos(a1),d0
	bhs.s	loc_3F84C
	neg.w	y_vel(a0)
	rts

loc_3F844:
	addi.w	#$100,y_vel(a0)
	rts

loc_3F84C:
	subi.w	#$100,y_vel(a0)
	rts

; ===========================================================================
Enemy_Points:	dc.w 10, 20, 50, 100
; ===========================================================================

loc_3F85C:
	bset	#7,status(a1)
; ===========================================================================

Touch_Boss:
	rts

; ---------------------------------------------------------------------------
; Subroutine for checking if Sonic/Tails should be hurt and hurting them if so
; note: sonic or tails must be at a0
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

Touch_Projectile:
	move.b	status2(a0),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	Touch_NoHurt			; if so, branch
	move.b	status2(a0),d0
	andi.b	#shield_mask,d0		; does the player have a shield?
	beq.w	Touch_ChkHurt	; if not, branch

Reverse_Projectile:
	move.w	x_pos(a0),d0
	cmp.w	x_pos(a1),d0
	bgt.s	Deflect_ProjectileRight

Deflect_ProjectileLeft:
	move.w	#$600,x_vel(a1)
	bra.s	deflectright2

Deflect_ProjectileRight:
	move.w	#-$600,x_vel(a1)

deflectright2:
	move.w	#-$600,y_vel(a1)	; Send the projectile upwards
	rts

Touch_ChkHurt:
	move.b	status2(a0),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	Touch_NoHurt			; if so, branch
	move.b	status2(a0),d0
	andi.b	#shield_mask|(1<<s2b_doublejump),d0
	cmpi.b	#1<<s2b_doublejump,d0			; is Sonic using the instashield?
	beq.s	Touch_NoHurt
	bra.s	Touch_Hurt				; if not, branch

Touch_NoHurt:
	moveq	#-1,d0
	rts

Touch_Hurt:
	tst.w	invulnerable_time(a0)
	bne.s	Touch_NoHurt
	movea.l	a1,a2
	bra.w	HurtCharacter

; End of function TouchResponse
; continue straight to HurtCharacter

; ===========================================================================
Touch_Monitor:
	tst.w	y_vel(a0)		; is Sonic moving upwards?
	bpl.s	Touch_Monitor_ChkBreak	; if not, branch
	move.w	y_pos(a0),d0
	subi.w	#$10,d0
	cmp.w	y_pos(a1),d0
	blo.s	Touch_Monitor_No
	neg.w	y_vel(a0)		; reverse Sonic's y-motion
	move.w	#-$180,y_vel(a1)
	bset	#6,mappings(a1)		; set the monitor's nudge flag
	rts

Touch_Monitor_ChkBreak:
;	cmpa.w	#MainCharacter,a0
;	beq.s	+
	cmpi.b	#2,anim(a0)
	bne.s	Touch_Monitor_No
	neg.w	y_vel(a0)		; reverse Sonic's y-motion
	bset	#7,mappings(a1)	
	move.w	#objroutine(ObjMonitor_Break),(a1)
	move.w	a0,parent(a1)
	rts

Touch_Monitor_No:
	bclr	#7,mappings(a1)		; unset the object's touched flag so the monitor doesn't break
	rts
; ===========================================================================	
Touch_Ring:
	move.w	#objroutine(ObjRing_Collect),(a1)
	rts
; ===========================================================================		
Touch_Bubble:	
	btst	#s3b_lock_motion,status3(a0)
	bne.w	ResumeMusic2_Loc
	cmpi.b	#$C,air_left(a0)		; has countdown started yet?
	bhi.s	ResumeMusic2_Done		; if not, branch
	cmpa.w	#MainCharacter,a0		; is it player 1?
	bne.s	ResumeMusic2_Done		; if not, branch
	move.w	(Level_Music).w,d0		; prepare to play current level's music
	btst	#s2b_2,status2(a0)	; is Sonic invincible?
	beq.s	+				; if not, branch
	move.w	#MusID_Invincible,d0		; prepare to play invincibility music
+	btst	#s2b_3,status2(a0)	; is Sonic super or hyper?
	beq.w	+				; if not, branch
	move.w	#MusID_SuperSonic,d0		; prepare to play super sonic music
+	tst.b	(Current_Boss_ID).w		; are we in a boss?
	beq.s	+				; if not, branch
	move.w	#MusID_Boss,d0			; prepare to play boss music
+	jsr	(PlayMusic).l

ResumeMusic2_Done:
	move.w	#SndID_InhalingBubble,d0	; play inhale bubble sound
	jsr	(PlaySound).l
	clr.w	x_vel(a0)			; make the player stop moving
	clr.w	y_vel(a0)
	clr.w	inertia(a0)
	move.b	#$15,anim(a0)			; set player to inhaling animation
	move.w	#$23,move_lock(a0)		; lock movement for 23 frames
	bclr	#s3b_jumping,status3(a0)			; unset player's jumping flag
	bclr	#5,status(a0)
	bclr	#4,status(a0)
	bclr	#2,status(a0)			; clear other jumping flag
	beq.b	ResumeMusic2_Loc		; if we weren't jumping anyway, branch
	;bne.b	Bubbles_Base_CheckPlayer_UnrollTails	; if so, branch
	move.b	#$26,height_pixels(a0)
	move.b	#18,width_pixels(a0)
	subq.w	#5,y_pos(a0)	
+	addq.b	#3,anim(a0)
	move.w	#objroutine(Bubbles_Base_BubbleCollected),(a1)
ResumeMusic2_Loc:
	move.b	#$1E,air_left(a0)	; reset air to full	
	rts
; ===========================================================================	
; ---------------------------------------------------------------------------
; Hurting Sonic/Tails subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

HurtCharacter:
	move.w	(Ring_count).w,d1
	cmpa.w	#MainCharacter,a0
	beq.s	loc_3F88C
	tst.w	(Two_player_mode).w
	beq.s	Hurt_Sidekick
	move.w	(Ring_count_2P).w,d1

loc_3F88C:
	move.b	status2(a0),d0
	andi.b	#shield_mask,d0
	beq.b	Hurt_NoShield
	andi.b	#shield_del,status2(a0) ; remove shield
	bsr.w	ChooseShield
	bra.b	Hurt_Sidekick

Hurt_NoShield:
	tst.b	SonicSSFlag
	bne.w	Hurt_SS
	tst.w	d1
	beq.w	KillCharacter
	jsr	SingleObjLoad
	bne.s	Hurt_Sidekick
	move.w	#objroutine(Hurt_Rings),id(a1) ; load obj
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)
	move.w	a0,parent(a1)

Hurt_Sidekick:
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	move.w	Hurt_Character_Options(pc,d0.w),(a0)
	bsr.w	JmpTo_Sonic_ResetOnFloor_Part2
	bset	#1,status(a0)
	move.w	#-$400,y_vel(a0) ; make Sonic bounce away from the object
	move.w	#-$200,x_vel(a0)
	btst	#6,status(a0)	; underwater?
	beq.s	Hurt_Reverse	; if not, branch
	move.w	#-$200,y_vel(a0) ; bounce slower
	move.w	#-$100,x_vel(a0)

Hurt_Reverse:
	move.w	x_pos(a0),d0
	cmp.w	x_pos(a2),d0
	blo.s	Hurt_ChkSpikes	; if Sonic is left of the object, branch
	neg.w	x_vel(a0)	; if Sonic is right of the object, reverse

Hurt_ChkSpikes:
	move.w	#0,inertia(a0)
	move.b	#$1A,anim(a0)
	move.w	#$78,invulnerable_time(a0)
	move.w	#SndID_Hurt,d0	; load normal damage sound
	cmpi.b	#$36,(a2)	; was damage caused by spikes?
	bne.s	Hurt_Sound	; if not, branch
	move.w	#SndID_HurtBySpikes,d0	; load spikes damage sound

Hurt_Sound:
	jsr	(PlaySound).l
	moveq	#-1,d0
	rts
Hurt_Character_Options:
	dc.w	objroutine(Sonic_Hurt)
	dc.w	objroutine(Sonic_Hurt)
	dc.w	objroutine(Tails_Hurt)
	dc.w	objroutine(Knuckles_Hurt)
Hurt_SS:
	sub.w	#1,$3A(a0)
	bne.b	Hurt_Sidekick

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to kill Sonic or Tails
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_3F926: KillSonic:
KillCharacter:
	clr.b 	$21(a0)
	tst.w	(Debug_placement_mode).w
	bne.s	loc_3F972
	clr.b	status2(a0)
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	move.w	Dead_Character_Options(pc,d0.w),(a0)
	bsr.w	JmpTo_Sonic_ResetOnFloor_Part2
	bset	#1,status(a0)
	move.w	#-$700,y_vel(a0)
	move.w	#0,x_vel(a0)
	move.w	#0,inertia(a0)
	move.b	#$18,anim(a0)
	bset	#7,art_tile(a0)
	move.w	#SndID_Hurt,d0
	cmpi.b	#$36,(a2)
	bne.s	loc_3F96C
	move.w	#SndID_HurtBySpikes,d0

loc_3F96C:
	jsr	(PlaySound).l

loc_3F972:
	moveq	#-1,d0
	rts
	
Dead_Character_Options:
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Sonic_Dead)
		dc.w	objroutine(Tails_Dead)
		dc.w	objroutine(Knuckles_Dead)
; ===========================================================================
JmpTo_Sonic_ResetOnFloor_Part2
	jmp	(Sonic_ResetOnFloor_Part2).l
; ===========================================================================

; ---------------------------------------------------------------------------
; Solid object subroutines (includes spikes, blocks, rocks etc)
; These check collision of Sonic/Tails with objects on the screen
;
; input variables:
; d1 = object width
; d2 = object height / 2 (when jumping)
; d3 = object height / 2 (when walking)
; d4 = object x-axis position
;
; address registers:
; a0 = the object to check collision with
; a1 = sonic or tails (set inside these subroutines)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_19718:
SolidObject:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)	; store input registers
	bsr.s	+	; first check collision with Sonic
	movem.l	(sp)+,d1-d4	; restore input registers
	lea	(Sidekick).w,a1 ; a1=character ; now check collision with Tails
	tst.b	render_flags(a1)
	bpl.w	return_19776	; return if no Tails
	addq.b	#1,d6
+
	btst	d6,status(a0)
	beq.w	SolidObject_cont
	move.w	d1,d2
	add.w	d2,d2			; d2 = full obj width
	btst	#1,status(a1)
	bne.s	loc_1975A
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0			; d0 += obj half-width
	moveq	#0,d3
	move.b	width_pixels(a1),d3
	lsr.w	#1,d3
	add.w	d3,d0			; d0 += char half-width
	bmi.s	loc_1975A
	add.w	d3,d2
	add.w	d3,d2			; d2 += full char width
	cmp.w	d2,d0
	blo.s	loc_1976E

loc_1975A:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_1976E:
	move.w	d4,d2
	bsr.w	MvSonicOnPtfm
	moveq	#0,d4

return_19776:
	rts

; ===========================================================================
; there are a few slightly different SolidObject functions
; specialized for certain objects, in this case, obj74 and obj30
; loc_19778:
SolidObject74_30:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	loc_1978E
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

loc_1978E:
	btst	d6,status(a0)
	beq.w	SolidObject2
	move.w	d1,d2
	add.w	d2,d2			; d2 = full obj width
	btst	#1,status(a1)
	bne.s	loc_197B2
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0			; d0 += obj half-width
	moveq	#0,d3
	move.b	width_pixels(a1),d3
	lsr.w	#1,d3
	add.w	d3,d0			; d0 += char half-width
	bmi.s	loc_197B2
	add.w	d3,d2
	add.w	d3,d2			; d2 += full char width
	cmp.w	d2,d0
	blo.s	loc_197C6

loc_197B2:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_197C6:
	move.w	d4,d2
	bsr.w	MvSonicOnPtfm
	moveq	#0,d4
	rts

; ===========================================================================
; loc_197D0:
SolidObject86_30:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	SolidObject_Simple
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

; this gets called from a few more places...
; loc_197E6:
SolidObject_Simple:
	btst	d6,status(a0)
	beq.w	SolidObject86_30_alt
	move.w	d1,d2
	add.w	d2,d2			; d2 = full obj width
	btst	#1,status(a1)
	bne.s	loc_1980A
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0			; d0 += obj half-width
	moveq	#0,d3
	move.b	width_pixels(a1),d3
	lsr.w	#1,d3
	add.w	d3,d0			; d0 += char half-width
	bmi.s	loc_1980A
	add.w	d3,d2
	add.w	d3,d2			; d2 += full char width
	cmp.w	d2,d0
	blo.s	loc_1981E

loc_1980A:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_1981E:
	move.w	d4,d2
	bsr.w	loc_19BCC
	moveq	#0,d4
	rts

; ===========================================================================
; unused/dead code for some SolidObject check
; SolidObject_Unk: loc_19828:
	; a0=object
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	+
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6
+
	btst	d6,status(a0)
	beq.w	SolidObject_Unk_cont
	move.w	d1,d2
	add.w	d2,d2
	btst	#1,status(a1)
	bne.s	loc_19862
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_19862
	cmp.w	d2,d0
	blo.s	loc_19876

loc_19862:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_19876:
	move.w	d4,d2
	bsr.w	loc_19C0E
	moveq	#0,d4
	rts

; ===========================================================================
; loc_19880:
SolidObject45:
	lea	(MainCharacter).w,a1 ; a1=character
	moveq	#3,d6
	movem.l	d1-d4,-(sp)
	bsr.s	loc_19896
	movem.l	(sp)+,d1-d4
	lea	(Sidekick).w,a1 ; a1=character
	addq.b	#1,d6

loc_19896:
	btst	d6,status(a0)
	beq.w	SolidObject45_alt
	btst	#1,status(a1)
	bne.s	loc_198B8
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.s	loc_198B8
	add.w	d1,d1
	cmp.w	d1,d0
	blo.s	loc_198CC

loc_198B8:
	bclr	#3,status(a1)
	bset	#1,status(a1)
	bclr	d6,status(a0)
	moveq	#0,d4
	rts
; ---------------------------------------------------------------------------
loc_198CC:
	move.w	y_pos(a0),d0
	sub.w	d2,d0
	add.w	d3,d0
	moveq	#0,d1
	move.b	height_pixels(a1),d1
	lsr.b	#1,d1
	sub.w	d1,d0
	move.w	d0,y_pos(a1)
	sub.w	x_pos(a0),d4
	sub.w	d4,x_pos(a1)
	moveq	#0,d4
	rts
; ===========================================================================
; loc_198EC:
SolidObject45_alt:
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	loc_19AC4
	move.w	d1,d4
	add.w	d4,d4
	cmp.w	d4,d0
	bhi.w	loc_19AC4
	move.w	y_pos(a0),d5
	add.w	d3,d5
	move.b	height_pixels(a1),d3
	lsr.b	#1,d3
	ext.w	d3
	add.w	d3,d2
	move.w	y_pos(a1),d3
	sub.w	d5,d3
	addq.w	#4,d3
	add.w	d2,d3
	bmi.w	loc_19AC4
	move.w	d2,d4
	add.w	d4,d4
	cmp.w	d4,d3
	bhs.w	loc_19AC4
	bra.w	loc_19A2E
; ===========================================================================
; loc_1992E:
SolidObject86_30_alt:
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	loc_19AC4
	move.w	d1,d3
	add.w	d3,d3
	cmp.w	d3,d0
	bhi.w	loc_19AC4
	move.w	d0,d5
	btst	#0,render_flags(a0)
	beq.s	+
	not.w	d5
	add.w	d3,d5
+
	lsr.w	#1,d5
	move.b	(a2,d5.w),d3
	sub.b	(a2),d3
	ext.w	d3
	move.w	y_pos(a0),d5
	sub.w	d3,d5
	move.b	height_pixels(a1),d3
	lsr.b	#1,d3
	ext.w	d3
	add.w	d3,d2
	move.w	y_pos(a1),d3
	sub.w	d5,d3
	addq.w	#4,d3
	add.w	d2,d3
	bmi.w	loc_19AC4
	move.w	d2,d4
	add.w	d4,d4
	cmp.w	d4,d3
	bhs.w	loc_19AC4
	bra.w	loc_19A2E
; ===========================================================================
; seems to be unused
; loc_19988:
SolidObject_Unk_cont:
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	loc_19AC4
	move.w	d1,d3
	add.w	d3,d3
	cmp.w	d3,d0
	bhi.w	loc_19AC4
	move.w	d0,d5
	btst	#0,render_flags(a0)
	beq.s	+
	not.w	d5
	add.w	d3,d5
+
	andi.w	#$FFFE,d5
	move.b	(a2,d5.w),d3
	move.b	1(a2,d5.w),d2
	ext.w	d2
	ext.w	d3
	move.w	y_pos(a0),d5
	sub.w	d3,d5
	move.w	y_pos(a1),d3
	sub.w	d5,d3
	move.b	height_pixels(a1),d5
	lsr.b	#1,d5
	ext.w	d5
	add.w	d5,d3
	addq.w	#4,d3
	bmi.w	loc_19AC4
	add.w	d5,d2
	move.w	d2,d4
	add.w	d5,d4
	cmp.w	d4,d3
	bhs.w	loc_19AC4
	bra.w	loc_19A2E
; ===========================================================================
; loc_199E8:
SolidObject_cont:
SolidObject2:
; ---------------------------------------------------------------------------
; SolidObject2 - Check collision between character and solid object
; ---------------------------------------------------------------------------
; Input:
;   a0 = object
;   a1 = character
;   d1.w = object half-width
;   d2.w = object half-height
;   d3.w = (unused, often same as d2)
;   d4.w = object x_pos
;   d6.b = character index (3=Sonic, 4=Tails) for status bits
; Output:
;   d4.w = -1 (top), 1 (side), -2 (bottom), 0 (no collision)
;   Sets appropriate status bits on a0 and a1
; ---------------------------------------------------------------------------

	; Step 1: Check if object is on-screen
	tst.b	render_flags(a0)
	bpl.w	.no_collision

	; Step 2: Calculate horizontal overlap
	; d0 = character_x - object_x + half_width
	; This gives offset from left edge of object
	move.w	x_pos(a1),d0
	sub.w	x_pos(a0),d0
	add.w	d1,d0
	bmi.w	.no_collision		; Character is to the left of object
	
	move.w	d1,d3
	add.w	d3,d3			; d3 = full width
	cmp.w	d3,d0
	bhi.w	.no_collision		; Character is to the right of object
	
	; Step 3: Calculate vertical overlap
	; Add character's half-height to object's half-height
	move.b	height_pixels(a1),d3
	lsr.b	#1,d3
	ext.w	d3
	add.w	d3,d2			; d2 = combined half-heights
	
	; d3 = character_y - object_y + 4 + combined_heights
	move.w	y_pos(a1),d3
	sub.w	y_pos(a0),d3
	addq.w	#4,d3
	add.w	d2,d3
	bmi.w	.no_collision		; Character is above object
	
	andi.w	#$7FF,d3		; Mask to prevent wraparound issues
	move.w	d2,d4
	add.w	d4,d4			; d4 = full combined height
	cmp.w	d4,d3
	bhs.w	.no_collision		; Character is below object
	
	; Step 4: Check if character is dead/gone/respawning
loc_19A2E:
	btst	#s3b_lock_jumping,status3(a1)
	bne.w	.no_collision
	
	; Save collision registers before dead/gone check
	movem.l	d0-d4,-(sp)
	
	move.w	(MainCharacter).w,d5
	move.w	(Player_mode).w,d0
	add.w	d0,d0
	lea	.CheckTables(pc),a2
	move.w	(a2,d0.w),d1		; Dead check
	cmp.w	d1,d5
	beq.w	.restore_exit
	move.w	6(a2,d0.w),d1		; Gone check
	cmp.w	d1,d5
	beq.w	.restore_exit
	move.w	12(a2,d0.w),d1		; Respawning check
	cmp.w	d1,d5
	beq.w	.restore_exit
	tst.w	(Debug_placement_mode).w
	bne.w	.restore_exit
	
	; Restore registers and continue
	movem.l	(sp)+,d0-d4
	
	; Step 5: Determine which side was hit
	; d0 = x offset from left edge
	; d3 = y offset from top edge  
	; d1 = half-width (reload it)
	move.b	width_pixels(a0),d1
	ext.w	d1
	
	; Calculate x distance from center
	; If d0 < half_width, character is on left side
	; If d0 >= half_width, character is on right side
	move.w	d0,d5
	sub.w	d1,d5			; d5 = offset from center (negative=left, positive=right)
	bpl.s	.right_of_center
	neg.w	d5			; d5 = absolute x distance from center
	bra.s	.calc_y_dist
	
.right_of_center:
	; d5 already positive
	
.calc_y_dist:
	; Calculate y distance from center
	; d2 = combined half-heights
	; d3 = y offset from top + combined heights
	; y distance from center = d3 - d2 (if < half, above center)
	move.w	d3,d1
	sub.w	d2,d1			; d1 = offset from object y center
	bpl.s	.below_center
	neg.w	d1			; d1 = absolute y distance from center
	bra.s	.compare_distances
	
.below_center:
	; d1 already positive (distance below center)
	
.compare_distances:
	; Compare x distance (d5) with y distance (d1)
	; If x < y, hit from side (left or right)
	; If x >= y, hit from top or bottom
	cmp.w	d1,d5
	blo.w	.vertical_collision
	
	; ----- HORIZONTAL (SIDE) COLLISION -----
.side_collision:
	; d0 = x offset from left edge
	; Determine if hit from left or right
	move.b	width_pixels(a0),d1
	ext.w	d1
	cmp.w	d0,d1			; Is d0 < half_width?
	bhi.s	.hit_from_left
	
.hit_from_right:
	; Push character to the right
	add.w	d1,d1			; full width
	sub.w	d0,d1			; distance to push right
	add.w	d1,x_pos(a1)
	bra.s	.side_common
	
.hit_from_left:
	; Push character to the left 
	neg.w	d0
	add.w	d1,d0			; distance to push left (negative)
	add.w	d0,x_pos(a1)
	
.side_common:
	; Zero velocity
	move.w	#0,inertia(a1)
	move.w	#0,x_vel(a1)
	
	; Check if in air
	btst	#1,status(a1)
	bne.s	.side_in_air
	
	; On ground - set pushing flags
	move.l	d6,d4
	addq.b	#2,d4
	bset	d4,status(a0)		; Set object's "being pushed by character X" bit
	bset	#5,status(a1)		; Set character's pushing bit
	moveq	#1,d4			; Return side collision
	rts

.side_in_air:
	; In air - clear pushing flags and return
	bsr.s	.clear_push_flags
	moveq	#1,d4
	rts

	; ----- VERTICAL COLLISION -----
.vertical_collision:
	; d3 = y offset from top + combined heights
	; d2 = combined half-heights
	; If d3 < d2, character is above center (top collision)
	; If d3 >= d2, character is below center (bottom collision)
	cmp.w	d2,d3
	bhs.s	.bottom_collision
	
	; ----- TOP COLLISION (landing on object) -----
.top_collision:
	; Check if moving downward
	tst.w	y_vel(a1)
	bmi.s	.no_collision_d4	; Moving up, no top collision
	
	; Calculate how much to push character up
	subq.w	#4,d3			; Undo the +4 offset
	sub.w	d2,d3			; d3 = how far into object (negative = above surface)
	sub.w	d3,y_pos(a1)
	subq.w	#1,y_pos(a1)		; Extra pixel to ensure standing on top
	
	; Set up standing on object
	bsr.w	loc_19E14
	
	; Set standing bit in return value
	move.w	d6,d4
	addi.b	#$11,d4
	bset	d4,d6
	moveq	#-1,d4			; Return top collision
	rts

	; ----- BOTTOM COLLISION (hitting head) -----
.bottom_collision:
	; Check if moving upward
	tst.w	y_vel(a1)
	beq.s	.bottom_stationary
	bpl.s	.bottom_return		; Moving down, just return
	
	; Moving up - push character down
	subq.w	#4,d3
	sub.w	d4,d3			; d3 = how far past bottom
	neg.w	d3
	add.w	d3,y_pos(a1)
	move.w	#0,y_vel(a1)
	
.bottom_return:
	move.w	d6,d4
	addi.b	#$F,d4
	bset	d4,d6
	moveq	#-2,d4			; Return bottom collision
	rts

.bottom_stationary:
	; Character stationary, check if should land on top instead
	btst	#1,status(a1)
	bne.s	.bottom_return		; In air, return bottom
	; On ground near object - treat as side collision
	bra.w	.side_collision

.no_collision_d4:
	moveq	#0,d4
	rts

	; ----- EXIT PATHS -----
.restore_exit:
	movem.l	(sp)+,d0-d4
	; Fall through to no_collision
	
loc_19AC4:
.no_collision:
	; Check if we were previously pushing this object
	move.l	d6,d4
	addq.b	#2,d4
	btst	d4,status(a0)
	beq.s	.no_collision_return
	
	; Was pushing - switch to walking animation
	cmpi.b	#2,anim(a1)
	beq.s	.clear_push_flags
	move.w	#1,anim(a1)

.clear_push_flags:
	move.l	d6,d4
	addq.b	#2,d4
	bclr	d4,status(a0)
	bclr	#5,status(a1)

.no_collision_return:
	moveq	#0,d4
	rts

; ---------------------------------------------------------------------------
; Data tables for dead/gone/respawning checks (OUTSIDE CODE FLOW)
; ---------------------------------------------------------------------------
.CheckTables:
	; Dead check (offset 0)
	dc.w	objroutine(Sonic_Dead)
	dc.w	objroutine(Sonic_Dead)
	dc.w	objroutine(Tails_Dead)
	dc.w	objroutine(Knuckles_Dead)
	; Gone check (offset 8)
	dc.w	objroutine(Sonic_Gone)
	dc.w	objroutine(Sonic_Gone)
	dc.w	objroutine(Tails_Gone)
	dc.w	objroutine(Knuckles_Gone)
	; Respawning check (offset 16)
	dc.w	objroutine(Sonic_Respawning)
	dc.w	objroutine(Sonic_Respawning)
	dc.w	objroutine(Tails_Respawning)
	dc.w	objroutine(Knuckles_Respawning)

