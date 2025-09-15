; ---------------------------------------------------------------------------
; Object touch response subroutine - $20(a0) in the object RAM
; Collides the main character (a0) with most objects in the level.
; Uses symmetric AABB: |dx| <= (wA/2 + wB/2) and |dy| <= (hA/2 + hB/2).
; ---------------------------------------------------------------------------

TouchResponse:
    moveq   #0,d6
    jsr     (Touch_Rings).l              ; ring collision stays first

    lea     (Dynamic_Object_RAM).w,a1    ; start at the *first* object
    move.w  #(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d6

    ; cache main character position & size (words)
    move.w  x_pos(a0),d0
    move.w  y_pos(a0),d1
    move.b  width_pixels(a0),d4
    move.b  height_pixels(a0),d5
    ext.w   d4
    ext.w   d5

; ---- loop over all objects -------------------------------------------------
TouchResponse__ObjectLoop:
    ; Skip objects without any collision flags
    tst.b   collision_response(a1)
    beq.s   TouchResponse__Next

    ; ---------- X overlap: |x_obj - x_main| <= (w_obj/2 + w_main/2)
    move.b  width_pixels(a1),d2
    ext.w   d2
    lsr.w   #1,d2                         ; d2 = half width (obj)

    move.w  d4,d3
    lsr.w   #1,d3                         ; d3 = half width (main)
    add.w   d3,d2                         ; d2 = sum of half widths

    move.w  x_pos(a1),d3
    sub.w   d0,d3                         ; d3 = dx
    mvabs.w d3,d3                         ; macro or inline abs
    cmp.w   d2,d3
    bhi.s   TouchResponse__Next           ; no X overlap

    ; ---------- Y overlap: |y_obj - y_main| <= (h_obj/2 + h_main/2)
    move.b  height_pixels(a1),d2
    ext.w   d2
    lsr.w   #1,d2                         ; d2 = half height (obj)

    move.w  d5,d3
    lsr.w   #1,d3                         ; d3 = half height (main)
    add.w   d3,d2                         ; d2 = sum of half heights

    move.w  y_pos(a1),d3
    sub.w   d1,d3                         ; d3 = dy
    mvabs.w d3,d3
    cmp.w   d2,d3
    bhi.s   TouchResponse__Next           ; no Y overlap

    ; ---------- collision! ----------
; ----------------------------------------
; Touch response dispatch (clean version)
; a0 = Sonic, a1 = touched object
; ----------------------------------------

TouchResponse__InitTouchedObject:
    bset    #7,mappings(a1)

    moveq   #0,d1
    move.b  collision_response(a1),d1
    cmpi.b  #TR_MaxIndex,d1
    bhi.w   TouchResponse__Next

    add.w   d1,d1                           ; word entries -> index*2
    lea     TouchResponse__Dispatch(pc),a2  ; keep a0 = player!
    move.w  (a2,d1.w),d1
    jmp     TouchResponse__Dispatch(pc,d1.w)

; ---------- advance to next object ----------
TouchResponse__Next:
    adda.w  #object_size,a1
    dbf     d6,TouchResponse__ObjectLoop
    rts

; ---------- jump table (word offsets) ----------
TouchResponse__Dispatch:
    dc.w    Touch_Enemy        - TouchResponse__Dispatch   ; 0
    dc.w    Touch_Enemy        - TouchResponse__Dispatch   ; 1
    dc.w    Touch_Boss         - TouchResponse__Dispatch   ; 2
    dc.w    Touch_ChkHurt      - TouchResponse__Dispatch   ; 3
    dc.w    Touch_Monitor      - TouchResponse__Dispatch   ; 4
    dc.w    Touch_Ring         - TouchResponse__Dispatch   ; 5
    dc.w    Touch_Bubble       - TouchResponse__Dispatch   ; 6
    dc.w    Touch_Projectile   - TouchResponse__Dispatch   ; 7

; ---------------------------------------------------------------------------


Touch_Enemy:
	move.b	status2(a0),d0
	andi.b	#power_mask,d0			; is Sonic invincible?
	bne.s	loc_3F7A6			; if so, branch
    cmpi.b	#2,anim(a0)
    bne.w	Touch_ChkHurt

loc_3F7A6:
    neg.w   y_vel(a0)
    bset    #s1b_air,status(a0)      ; now airborne
    bclr    #s1b_onobject,status(a0) ; not standing on a platform
    move.b  #0,collision_response(a1)

Touch_KillEnemy:
    bset    #7,status(a1)
    moveq   #0,d0
    move.w  (Chain_Bonus_counter).w,d0
    addq.w  #2,(Chain_Bonus_counter).w          ; grow chain counter

    ; Clamp index to 0..3 because Enemy_Points has 4 entries
    cmpi.w  #3,d0
    bls.s   loc_in_range_points
    moveq   #3,d0
loc_in_range_points:
    move.w  Enemy_Points(pc,d0.w),d0

    ; Check for big bonus after 16 enemies
    cmpi.w  #$20,(Chain_Bonus_counter).w
    blo.s   loc_no_big_bonus
    move.w  #1000,d0                           ; (comment says 10000, value is 1000)
loc_no_big_bonus:
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
    move.b  status2(a0),d0
    andi.b  #power_mask,d0
    bne.s   Touch_NoHurt
    move.b  shields(a0),d0         ; which shield do we have? 0 = none
    beq.b   Touch_ChkHurt          ; no shield -> hurt as usual

; Player has a shield: knock the projectile AWAY from the player.
Reverse_Projectile:
    move.w  x_pos(a0),d0
    cmp.w   x_pos(a1),d0
    bgt.s   Deflect_Left_AwayFromPlayer       ; player is to the right -> go left

Deflect_Right_AwayFromPlayer:
    move.w  #$0600,x_vel(a1)                  ; rightward
    bra.s   loc_pop_up

Deflect_Left_AwayFromPlayer:
    move.w  #-$0600,x_vel(a1)                 ; leftward

loc_pop_up:
    move.w  #-$0600,y_vel(a1)                 ; also pop upward
    rts

Touch_ChkHurt:
    move.b  status2(a0),d0
    andi.b  #power_mask,d0
    bne.s   Touch_NoHurt
    move.b  status2(a0),d0
    andi.b  #shield_mask|(1<<s2b_doublejump),d0
    cmpi.b  #1<<s2b_doublejump,d0
    beq.s   Touch_NoHurt

    ; we will hurt → unlatch from any platform immediately
    bset    #s1b_air,status(a0)
    bclr    #s1b_onobject,status(a0)

    bra.s   Touch_Hurt

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
    tst.w   y_vel(a0)
    bpl.s   Touch_Monitor_ChkBreak
    move.w  y_pos(a0),d0
    subi.w  #$10,d0
    cmp.w   y_pos(a1),d0
    blo.s   Touch_Monitor_No
    neg.w   y_vel(a0)
    bset    #s1b_air,status(a0)
    bclr    #s1b_onobject,status(a0)
    bset    #6,mappings(a1)
    rts

Touch_Monitor_ChkBreak:
    cmpi.b  #2,anim(a0)
    bne.s   Touch_Monitor_No
    neg.w   y_vel(a0)
    bset    #s1b_air,status(a0)
    bclr    #s1b_onobject,status(a0)
    bset    #7,mappings(a1)
    move.w  #objroutine(ObjMonitor_Break),(a1)
    move.w  a0,parent(a1)
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

; =========================
; SOLID OBJECT COLLISION (unique labels everywhere)
; =========================
; uses bitfields from includes:
;   s1b_left=0, s1b_air=1, s1b_ball=2, s1b_onobject=3, ...
;   s3b_lock_jumping=1, ...

; ---------------------------------------------------------------------------
; Flat top: both chars → entry → full landing logic
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; Solid_Flat — safe wrapper (two passes: Sonic then Tails)
; Stack is always balanced; no early RTS in the wrapper.
; ---------------------------------------------------------------------------

Solid_Flat:
    ; --- pass 1: Sonic ---
    lea     (MainCharacter).w,a1
    moveq   #3,d6
    movem.l d1-d4,-(sp)           ; save inputs for Sonic
    bsr.w   Solid_Flat_CheckOne
    movem.l (sp)+,d1-d4           ; restore

    ; --- pass 2: Tails (skip if not rendered) ---
    lea     (Sidekick).w,a1
    tst.b   render_flags(a1)
    bpl.w   Solid_Flat_Ret        ; Tails not present/visible → done (stack already restored)
    addq.b  #1,d6
    movem.l d1-d4,-(sp)           ; save inputs for Tails
    bsr.w   Solid_Flat_CheckOne
    movem.l (sp)+,d1-d4           ; restore

Solid_Flat_Ret:
    rts


; ---------------------------------------------------------------------------
; Worker used by both passes (no movem here; plain RTS is safe)
; ---------------------------------------------------------------------------
Solid_Flat_CheckOne:
    btst    d6,status(a0)
    beq.w   Solid_Flat_Entry

    move.w  d1,d2
    add.w   d2,d2
    btst    #s1b_air,status(a1)
    bne.w   Solid_Flat_Lost
    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_Flat_Lost
    cmp.w   d2,d0
    blo.w   Solid_Flat_Carry

Solid_Flat_Lost:
    bclr    #s1b_onobject,status(a1)
    bset    #s1b_air,status(a1)
    bclr    d6,status(a0)
    moveq   #0,d4
    rts

Solid_Flat_Carry:
    move.w  d4,d2
    bsr.w   MvSonicOnPtfm
    moveq   #0,d4
    rts


; ---------------------------------------------------------------------------
; Entry/Alt path (unchanged logic)
; ---------------------------------------------------------------------------
Solid_Flat_Entry:
    tst.b   render_flags(a0)
    bpl.w   Solid_NoHit

Solid_Flat_Alt:
    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_NoHit

    move.w  d1,d3
    add.w   d3,d3
    cmp.w   d3,d0
    bhi.w   Solid_NoHit

    moveq   #0,d3
    move.b  height_pixels(a1),d3
    lsr.w   #1,d3
    add.w   d3,d2

    move.w  y_pos(a1),d3
    sub.w   y_pos(a0),d3
    addq.w  #4,d3
    add.w   d2,d3
    bmi.w   Solid_NoHit

    andi.w  #$07FF,d3
    move.w  d2,d4
    add.w   d4,d4
    cmp.w   d4,d3
    bhs.w   Solid_NoHit

    bra.w   Solid_Land



; ---------------------------------------------------------------------------
; Fast carry (MvSonicOnPtfm) quick-path if already latched, else Flat_Alt
; Safe wrapper: stack always balanced; no early RTS in wrapper.
; ---------------------------------------------------------------------------

Solid_FastMv:
    ; --- pass 1: Sonic ---
    lea     (MainCharacter).w,a1
    moveq   #3,d6
    movem.l d1-d4,-(sp)
    bsr.w   Solid_FastMv_Cont
    movem.l (sp)+,d1-d4

    ; --- pass 2: Tails ---
    lea     (Sidekick).w,a1
    addq.b  #1,d6
    movem.l d1-d4,-(sp)
    bsr.w   Solid_FastMv_Cont
    movem.l (sp)+,d1-d4
    rts

; ---------------------------------------------------------------------------
; Worker (no movem here; plain RTS on exits is safe)
; ---------------------------------------------------------------------------
Solid_FastMv_Cont:
    btst    d6,status(a0)
    beq.w   Solid_Flat_Alt

    move.w  d1,d2
    add.w   d2,d2
    btst    #s1b_air,status(a1)
    bne.w   Solid_FastMv_Unlatch
    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_FastMv_Unlatch
    cmp.w   d2,d0
    blo.w   Solid_FastMv_Carry

Solid_FastMv_Unlatch:
    bclr    #s1b_onobject,status(a1)
    bset    #s1b_air,status(a1)
    bclr    d6,status(a0)
    moveq   #0,d4
    rts

Solid_FastMv_Carry:
    move.w  d4,d2
    bsr.w   MvSonicOnPtfm
    ; NEW: legacy top-contact (3/4) for this frame
    move.l  d6,d4
    bset    d4,status(a0)      ; <<<<<< add this
    moveq   #0,d4
    rts


; ---------------------------------------------------------------------------
; Solid_Simple — wrapper calls the worker twice (Sonic then Tails)
; Keeps original labels: Solid_Simple_Cont / _Unlatch / _Carry / _Alt
; ---------------------------------------------------------------------------

Solid_Simple:
    ; --- pass 1: Sonic ---
    lea     (MainCharacter).w,a1
    moveq   #3,d6
    movem.l d1-d4,-(sp)           ; save inputs for this pass
    bsr.w   Solid_Simple_Cont     ; do the work for Sonic
    movem.l (sp)+,d1-d4           ; restore inputs

    ; --- pass 2: Tails ---
    lea     (Sidekick).w,a1
    addq.b  #1,d6
    movem.l d1-d4,-(sp)           ; same inputs for Tails
    bsr.w   Solid_Simple_Cont
    movem.l (sp)+,d1-d4           ; restore (clean exit)
    rts

; ---------------------------------------------------------------------------
; Solid_Simple_Cont — worker used by both passes
; (No movem here; plain RTS on all exits is safe.)
; ---------------------------------------------------------------------------

Solid_Simple_Cont:
    btst    d6,status(a0)
    beq.w   Solid_Simple_Alt

    move.w  d1,d2
    add.w   d2,d2
    btst    #s1b_air,status(a1)
    bne.w   Solid_Simple_Unlatch
    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_Simple_Unlatch
    cmp.w   d2,d0
    blo.w   Solid_Simple_Carry

Solid_Simple_Unlatch:
    bclr    #s1b_onobject,status(a1)
    bset    #s1b_air,status(a1)
    bclr    d6,status(a0)
    moveq   #0,d4
    rts

Solid_Simple_Carry:
    move.w  d4,d2
    bsr.w   loc_19BCC
    moveq   #0,d4
    rts

Solid_Simple_Alt:
    bsr.w   Solid_Flat_Alt
    rts



; ---------------------------------------------------------------------------
; Fast carry with X snap (belt/edge feel) — SAFE WRAPPER
; Stack is always balanced; no early RTS from the wrapper.
; ---------------------------------------------------------------------------

Solid_SnapX:
    ; --- pass 1: Sonic ---
    lea     (MainCharacter).w,a1
    moveq   #3,d6
    movem.l d1-d4,-(sp)
    bsr.w   Solid_SnapX_Cont
    movem.l (sp)+,d1-d4

    ; --- pass 2: Tails ---
    lea     (Sidekick).w,a1
    addq.b  #1,d6
    movem.l d1-d4,-(sp)
    bsr.w   Solid_SnapX_Cont
    movem.l (sp)+,d1-d4
    rts

; ---------------------------------------------------------------------------
; Worker used by both passes (no movem here; plain RTS on exits is safe)
; ---------------------------------------------------------------------------

Solid_SnapX_Cont:
    btst    d6,status(a0)
    beq.w   Solid_SnapX_Alt

    btst    #s1b_air,status(a1)
    bne.w   Solid_SnapX_Unlatch

    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_SnapX_Unlatch
    add.w   d1,d1
    cmp.w   d1,d0
    blo.w   Solid_SnapX_Apply

Solid_SnapX_Unlatch:
    bclr    #s1b_onobject,status(a1)
    bset    #s1b_air,status(a1)
    bclr    d6,status(a0)
    moveq   #0,d4
    rts

Solid_SnapX_Apply:
    move.w  y_pos(a0),d0
    sub.w   d2,d0
    add.w   d3,d0
    moveq   #0,d1
    move.b  height_pixels(a1),d1
    lsr.w   #1,d1
    sub.w   d1,d0
    move.w  d0,y_pos(a1)

    sub.w   x_pos(a0),d4
    sub.w   d4,x_pos(a1)
    moveq   #0,d4
    rts

Solid_SnapX_Alt:
    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_NoHit

    move.w  d1,d4
    add.w   d4,d4
    cmp.w   d4,d0
    bhi.w   Solid_NoHit

    move.w  y_pos(a0),d5
    add.w   d3,d5
    moveq   #0,d3
    move.b  height_pixels(a1),d3
    lsr.w   #1,d3
    add.w   d3,d2
    move.w  y_pos(a1),d3
    sub.w   d5,d3
    addq.w  #4,d3
    add.w   d2,d3
    bmi.w   Solid_NoHit

    move.w  d2,d4
    add.w   d4,d4
    cmp.w   d4,d3
    bhs.w   Solid_NoHit

    bra.w   Solid_Land


; ---------------------------------------------------------------------------
; Heightmap top (1 byte/column; a2 points to table) → Landing
; ---------------------------------------------------------------------------
Solid_Height_Alt:
    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_NoHit

    move.w  d1,d3
    add.w   d3,d3
    cmp.w   d3,d0
    bhi.w   Solid_NoHit

    move.w  d0,d5
    btst    #0,render_flags(a0)
    beq.w   Solid_Height_NoMirror
    not.w   d5
    add.w   d3,d5
Solid_Height_NoMirror:
    lsr.w   #1,d5
    move.b  (a2,d5.w),d3
    sub.b   (a2),d3
    ext.w   d3

    move.w  y_pos(a0),d5
    sub.w   d3,d5
    moveq   #0,d3
    move.b  height_pixels(a1),d3
    lsr.w   #1,d3
    add.w   d3,d2
    move.w  y_pos(a1),d3
    sub.w   d5,d3
    addq.w  #4,d3
    add.w   d2,d3
    bmi.w   Solid_NoHit

    move.w  d2,d4
    add.w   d4,d4
    cmp.w   d4,d3
    bhs.w   Solid_NoHit

    bra.w   Solid_Land


; ---------------------------------------------------------------------------
; Column band (2 bytes/column) — unused, but kept complete
; ---------------------------------------------------------------------------
Solid_ColBand_Alt:
    move.w  x_pos(a1),d0
    sub.w   x_pos(a0),d0
    add.w   d1,d0
    bmi.w   Solid_NoHit

    move.w  d1,d3
    add.w   d3,d3
    cmp.w   d3,d0
    bhi.w   Solid_NoHit

    move.w  d0,d5
    btst    #0,render_flags(a0)
    beq.w   Solid_ColBand_NoMirror
    not.w   d5
    add.w   d3,d5
Solid_ColBand_NoMirror:
    andi.w  #$FFFE,d5
    move.b  (a2,d5.w),d3         ; height
    move.b  1(a2,d5.w),d2        ; thickness
    ext.w   d2
    ext.w   d3

    move.w  y_pos(a0),d5
    sub.w   d3,d5
    move.w  y_pos(a1),d3
    sub.w   d5,d3
    moveq   #0,d5
    move.b  height_pixels(a1),d5
    lsr.w   #1,d5
    add.w   d5,d3
    addq.w  #4,d3
    bmi.w   Solid_NoHit

    add.w   d5,d2
    move.w  d2,d4
    add.w   d5,d4
    cmp.w   d4,d3
    bhs.w   Solid_NoHit

    bra.w   Solid_Land


; ---------------------------------------------------------------------------
; COMMON LANDING / SIDE / KILL HANDLER
; ---------------------------------------------------------------------------
Solid_Land:
    btst    #s3b_lock_jumping,status3(a1)
    bne.w   Solid_NoHit

    move.w  (MainCharacter).w,d2
    move.w  (Player_mode).w,d0
    add.w   d0,d0
    ; ---- table 1
    lea     Solid_Land_Check(pc),a2
    move.w  (a2,d0.w),d1
    cmp.w   d1,d2
    beq.w   Solid_Zero
	; ---- table 2
    lea     Solid_Land_Check2(pc),a2
    move.w  (a2,d0.w),d1
    cmp.w   d1,d2
    beq.w   Solid_Zero
    ; ---- table 3
    lea     Solid_Land_Check3(pc),a2
    move.w  (a2,d0.w),d1
    cmp.w   d1,d2
    beq.w   Solid_Zero
    tst.w   (Debug_placement_mode).w
    bne.w   Solid_Zero

    move.w  d0,d5
    cmp.w   d0,d1
    bhs.w   Solid_Land_HaveD5
    add.w   d1,d1
    sub.w   d1,d0
    move.w  d0,d5
    neg.w   d5
Solid_Land_HaveD5:
    move.w  d3,d1
    cmp.w   d3,d2
    bhs.w   Solid_Land_HaveD1
    subq.w  #4,d3
    sub.w   d4,d3
    move.w  d3,d1
    neg.w   d1
Solid_Land_HaveD1:
    cmp.w   d1,d5
    bhi.w   Solid_Deep

    cmpi.w  #4,d1
    bls.w   Solid_Land_Soft
    tst.w   d0
    beq.w   Solid_Land_StopX
    bmi.w   Solid_Land_FromLeft
    tst.w   x_vel(a1)
    bmi.w   Solid_Land_StopX
    bra.w   Solid_Land_SideOk

Solid_Land_FromLeft:
    tst.w   x_vel(a1)
    bpl.w   Solid_Land_StopX
Solid_Land_SideOk:
    ; fall-through

Solid_Land_StopX:
    move.w  #0,inertia(a1)
    move.w  #0,x_vel(a1)
    sub.w   d0,x_pos(a1)

    btst    #s1b_air,status(a1)
    bne.w   Solid_Land_Soft

    ; landed: clear air, set onobject, latch
    bclr    #s1b_air,status(a1)
    bset    #s1b_onobject,status(a1)

    move.l  d6,d4
    addq.b  #2,d4
    bset    d4,status(a0)          ; keep the d6+2 “latch” bit (5/6)

    move.w  d6,d4
    addi.b  #$0D,d4
    bset    d4,d6

    moveq   #1,d4
    rts

Solid_Land_Soft:
    bsr.w   Solid_Unlatch
    move.w  d6,d4
    addi.b  #$0D,d4
    bset    d4,d6
    moveq   #1,d4
    rts


; ---------------------------------------------------------------------------
; No hit / unlatch / zero result
; ---------------------------------------------------------------------------
Solid_NoHit:
    move.l  d6,d4
    addq.b  #2,d4
    btst    d4,status(a0)
    bne.s   Solid_NoHit_HadLatch
    bclr    d6,status(a0)          ; clear legacy top-contact (#3/#4) ✅
    bra.w   Solid_Zero

Solid_NoHit_HadLatch:
    cmpi.b  #2,anim(a1)
    beq.w   Solid_Unlatch
    move.w  #1,anim(a1)
    bra.w   Solid_Unlatch

Solid_Unlatch:
    move.l  d6,d4
    addq.b  #2,d4
    bclr    d4,status(a0)          ; clear latch (#5/#6)
    bclr    d6,status(a0)          ; clear legacy top-contact (#3/#4) ✅
    bclr    #s1b_onobject,status(a1)
    bset    #s1b_air,status(a1)
Solid_Zero:
    moveq   #0,d4
    rts


; ---------------------------------------------------------------------------
; Deep penetration / vertical fall / kill check
; ---------------------------------------------------------------------------
Solid_Deep:
    tst.w   d3
    bmi.w   Solid_VertFall
    cmpi.w  #$0010,d3
    blo.w   Solid_TopSnap
    cmpi.b  #-$7B,(a0)
    bne.w   Solid_NoHit
    cmpi.w  #$0014,d3
    blo.w   Solid_TopSnap
    bra.w   Solid_NoHit

Solid_VertFall:
    tst.w   y_vel(a1)
    beq.w   Solid_KillChk
    bpl.w   Solid_VertFall_SetFlag
    tst.w   d3
    bpl.w   Solid_VertFall_SetFlag
    sub.w   d3,y_pos(a1)
    move.w  #0,y_vel(a1)
Solid_VertFall_SetFlag:
    move.w  d6,d4
    addi.b  #$0F,d4
    bset    d4,d6
    moveq   #-2,d4
    rts

Solid_KillChk:
    btst    #s1b_air,status(a1)
    bne.w   Solid_VertFall_SetFlag
    mvabs.w d0,d4
    cmpi.w  #$0010,d4
    blo.w   Solid_Land
    move.l  a0,-(sp)
    movea.l a1,a0
    jsr     (KillCharacter).l
    movea.l (sp)+,a0
    move.w  d6,d4
    addi.b  #$0F,d4
    bset    d4,d6
    moveq   #-2,d4
    rts


; ---------------------------------------------------------------------------
; Shallow top snap & land
; ---------------------------------------------------------------------------
Solid_TopSnap:
    subq.w  #4,d3
    moveq   #0,d1
    move.b  width_pixels(a0),d1
    move.w  d1,d2
    add.w   d2,d2
    add.w   x_pos(a1),d1
    sub.w   x_pos(a0),d1
    bmi.w   Solid_TopSnap_No
    cmp.w   d2,d1
    bhs.w   Solid_TopSnap_No
    tst.w   y_vel(a1)
    bmi.w   Solid_TopSnap_No

    sub.w   d3,y_pos(a1)
    subq.w  #1,y_pos(a1)
    bsr.w   loc_19E14

    move.w  d6,d4
    addi.b  #$11,d4
    bset    d4,d6

    ; NEW: mark legacy top-contact (bit 3 for Sonic, 4 for Tails)
    move.l  d6,d4
    bset    d4,status(a0)      ; <<<<<< add this

    moveq   #-1,d4
    rts

Solid_TopSnap_No:
    moveq   #0,d4
    rts


; ---------------------------------------------------------------------------
; Routine tables (unchanged payload)
; ---------------------------------------------------------------------------
Solid_Land_Check:
    dc.w    objroutine(Sonic_Dead)
    dc.w    objroutine(Sonic_Dead)
    dc.w    objroutine(Tails_Dead)
    dc.w    objroutine(Knuckles_Dead)

Solid_Land_Check2:
    dc.w    objroutine(Sonic_Gone)
    dc.w    objroutine(Sonic_Gone)
    dc.w    objroutine(Tails_Gone)
    dc.w    objroutine(Knuckles_Gone)

Solid_Land_Check3:
    dc.w    objroutine(Sonic_Respawning)
    dc.w    objroutine(Sonic_Respawning)
    dc.w    objroutine(Tails_Respawning)
    dc.w    objroutine(Knuckles_Respawning)



; ===========================================================================
; Side-stop / latch helpers (formerly loc_19A7E/84/90 + 19AB6)
; ===========================================================================

SO_SideStop_CheckXVel:            ; was loc_19A7E
    tst.w   x_vel(a1)
    bpl.w   SO_SideStop_Latch

SO_SideStop_ZeroX:                ; was loc_19A84
    move.w  #0,inertia(a1)
    move.w  #0,x_vel(a1)

SO_SideStop_Latch:                ; was loc_19A90
    sub.w   d0,x_pos(a1)
    btst    #s1b_air,status(a1)
    bne.w   SO_Land_SoftReturn
    move.l  d6,d4
    addq.b  #2,d4
    bset    d4,status(a0)         ; mark object latched
    bset    #s1b_onobject,status(a1) ; standing on object
    move.w  d6,d4
    addi.b  #$0D,d4
    bset    d4,d6
    moveq   #1,d4
    rts

SO_Land_SoftReturn:               ; was loc_19AB6 (called after soft land)
    bsr.w   SO_Unlatch
    move.w  d6,d4
    addi.b  #$0D,d4
    bset    d4,d6
    moveq   #1,d4
    rts


; ===========================================================================
; No hit / unlatch / zero (replaces duplicated Solid_NoHit/Solid_Zero blocks)
; ===========================================================================

SO_NoHit:
    move.l  d6,d4
    addq.b  #2,d4
    btst    d4,status(a0)
    beq.w   SO_Zero
    cmpi.b  #2,anim(a1)
    beq.w   SO_Unlatch
    move.w  #1,anim(a1)

SO_Unlatch:
    move.l  d6,d4
    addq.b  #2,d4
    bclr    d4,status(a0)
    bclr    #s1b_onobject,status(a1)
    bset    #s1b_air,status(a1)
    bclr    d6,status(a0)          ; NEW: clear legacy contact (3/4)

SO_Zero:
    moveq   #0,d4
    rts


; ===========================================================================
; Deep / vertical fall / kill check (renamed, no .s branches)
; ===========================================================================

SO_Deep:
    tst.w   d3
    bmi.w   SO_VertFall
    cmpi.w  #$0010,d3
    blo.w   SO_TopSnap
    cmpi.b  #-$7B,(a0)
    bne.w   SO_NoHit
    cmpi.w  #$0014,d3
    blo.w   SO_TopSnap
    bra.w   SO_NoHit

SO_VertFall:
    tst.w   y_vel(a1)
    beq.w   SO_KillChk
    bpl.w   SO_VertFall_SetFlag
    tst.w   d3
    bpl.w   SO_VertFall_SetFlag
    sub.w   d3,y_pos(a1)
    move.w  #0,y_vel(a1)
SO_VertFall_SetFlag:              ; was loc_19B1C
    move.w  d6,d4
    addi.b  #$0F,d4
    bset    d4,d6
    moveq   #-2,d4
    rts

SO_KillChk:
    btst    #s1b_air,status(a1)
    bne.w   SO_VertFall_SetFlag
    mvabs.w d0,d4
    cmpi.w  #$0010,d4
    blo.w   Solid_Land           ; was blo.w loc_19A6A (landing path)
    move.l  a0,-(sp)
    movea.l a1,a0
    jsr     (KillCharacter).l
    movea.l (sp)+,a0
    move.w  d6,d4
    addi.b  #$0F,d4
    bset    d4,d6
    moveq   #-2,d4
    rts


; ===========================================================================
; Top snap (renamed, no .s branches)
; ===========================================================================

SO_TopSnap:
    subq.w  #4,d3
    moveq   #0,d1
    move.b  width_pixels(a0),d1
    move.w  d1,d2
    add.w   d2,d2
    add.w   x_pos(a1),d1
    sub.w   x_pos(a0),d1
    bmi.w   SO_Zero
    cmp.w   d2,d1
    bhs.w   SO_Zero
    tst.w   y_vel(a1)
    bmi.w   SO_Zero
    sub.w   d3,y_pos(a1)
    subq.w  #1,y_pos(a1)
    bsr.w   loc_19E14
    move.w  d6,d4
    addi.b  #$11,d4
    bset    d4,d6
    moveq   #-1,d4
    rts

; ---------------------------------------------------------------
; Helpers: Prepare d1..d4 for Solid_* routines against player a1
;   a0 = object, a1 = player
;   out:
;     d1 = sum_half_widths (obj + player)
;     d2 = obj_half_height
;     d3 = obj_half_height (optionally +1 for “walking” pad)
;     d4 = x_pos(a0)  (unless using _KeepD4 variant)
; ---------------------------------------------------------------

PrepSolid_Player:
    ; d1 = halfwidth(obj) + halfwidth(player)
    moveq   #0,d1
    move.b  width_pixels(a0),d1
    lsr.w   #1,d1
    moveq   #0,d0
    move.b  width_pixels(a1),d0
    lsr.w   #1,d0
    add.w   d0,d1

    ; d2 = halfheight(obj)
    moveq   #0,d2
    move.b  height_pixels(a0),d2
    lsr.w   #1,d2

    ; d3 = d2 + 1  (walking pad like original spike code)
    move.w  d2,d3
    addq.w  #1,d3

    ; d4 = object X (default)
    move.w  x_pos(a0),d4
    rts

PrepSolid_Player_NoPad:
    ; Same as above but d3 = d2 (no +1)
    moveq   #0,d1
    move.b  width_pixels(a0),d1
    lsr.w   #1,d1
    moveq   #0,d0
    move.b  width_pixels(a1),d0
    lsr.w   #1,d0
    add.w   d0,d1

    moveq   #0,d2
    move.b  height_pixels(a0),d2
    lsr.w   #1,d2

    move.w  d2,d3            ; no extra pad
    move.w  x_pos(a0),d4
    rts

PrepSolid_Player_KeepD4:
    ; Like PrepSolid_Player but preserves d4 (caller preloads d4)
    moveq   #0,d1
    move.b  width_pixels(a0),d1
    lsr.w   #1,d1
    moveq   #0,d0
    move.b  width_pixels(a1),d0
    lsr.w   #1,d0
    add.w   d0,d1

    moveq   #0,d2
    move.b  height_pixels(a0),d2
    lsr.w   #1,d2

    move.w  d2,d3
    addq.w  #1,d3
    rts
