; ---------------------------------------------------------------------------
; Single Object Load Routines Overview
;
; These helpers scan the dynamic object table for free slots, but differ
; in *where* they begin searching and *how far* they search:
;
;  SingleObjLoad   – Scans the entire object table from the beginning
;                    (Dynamic_Object_RAM .. End). Returns first free slot.
;
;  SingleObjLoad2  – Scans only AFTER the current object (a0),
;                    up to the end of the object zone (Tails_Tails).
;                    Returns first free slot beyond a0.
;
;  SingleObjLoad3  – Scans a *local window* of up to 12 slots
;                    starting at or after a3. Returns first free slot
;                    in that limited region.
;
;  SingleObjLoad4  – Scans the entire object table (like SingleObjLoad),
;                    but if no free slot is found it falls through to
;                    DeleteObject (tail-call) instead of just returning.
;
; Together these provide variants depending on whether the caller wants:
;   – the first free slot in the whole table
;   – the next free slot after a specific object
;   – a bounded “nearby” slot search
;   – or a fallback behavior if no slot is found.
; ---------------------------------------------------------------------------


; ---------------------------------------------------------------------------
; Single object loading subroutine
; Scans the dynamic object table for a free (zeroed) slot.
;
; Contract / Conventions:
;   In:
;     (none)
;   Out:
;     a1 -> first free object slot (if found); otherwise a1 ends just past the
;           last slot scanned.
;     CCR.Z is not guaranteed/used by callers (unchanged from original logic).
;   Trashes:
;     d0, a1
;
; Assumptions:
;   - Each object slot is 'object_size' bytes.
;   - A slot is considered free if its first word is 0.
;   - Dynamic_Object_RAM .. Dynamic_Object_RAM_End is contiguous.
; ---------------------------------------------------------------------------

SingleObjLoad:
	; Point a1 at the start of the dynamic object table
	lea	(Dynamic_Object_RAM).w,a1          ; a1 = current slot address

	; Set loop counter to (#slots - 1). Using a down-counter lets us DBF/DBRA.
	; (#slots) = (end - start) / object_size
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1, d0

SingleObjLoad__MainLoop:
	; Test the first word of the slot. Zero means the slot is free.
	tst.w	(a1)                               ; free if == 0?
	beq.s	+                                   ; yes -> return with a1 at this slot

	; Not free: advance to next slot and keep scanning
	lea	next_object(a1), a1                  ; a1 += object_size
	dbf	d0, SingleObjLoad__MainLoop          ; loop until counter underflows

+	; Found a free slot (or we ran out; a1 will then point just past end).
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Single object loading subroutine
; Find an empty object array AFTER the current one in the table
;   - Starts scanning at the *next* slot after a0
;   - Returns with a1 -> first free slot found, or a1 at end if none
;   - Trashes: d0, d1, a1
; Assumptions:
;   - Each slot is 'object_size' bytes (2^object_align)
;   - A slot is free if its first word == 0
;   - Tails_Tails marks the end (exclusive) of the object zone
; ---------------------------------------------------------------------------

SingleObjLoad2:
	; Start from the slot *after* the current one (per routine comment)
	lea     next_object(a0), a1             ; a1 = first slot to check (after a0)

	; Compute remaining slots to scan (in LONG to avoid 16-bit wrap):
	;   d0 = (Tails_Tails - a1) >> object_align
	; Then subtract 1 so DBF scans exactly that many slots.
	move.l  a1, d1                          ; d1 = a1 (current scan ptr)
	move.l  #Tails_Tails, d0                ; d0 = end of object zone (exclusive)
	sub.l   d1, d0                          ; d0 = bytes remaining to end
	lsr.l   #object_align, d0               ; d0 = slots remaining
	subq.l  #1, d0                          ; d0 = loop counter for DBF
	bcs.s   +                                ; if no slots to scan, return

SingleObjLoad2__MainLoop:
	tst.w   (a1)                            ; free slot?
	beq.s   +                               ; yes -> return with a1 on this slot
	lea     next_object(a1), a1             ; advance to next slot
	dbf     d0, SingleObjLoad2__MainLoop    ; keep scanning while slots remain
+
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Single object loading subroutine
; Find an empty object at or within < 12 slots after a3
;   - Scan window: [a3, a3 + 11 * object_size]
;   - Returns with a1 -> first free slot found within the 12-slot window.
;     If none found, a1 ends one slot past the window (a3 + 12 * object_size).
;   - Trashes: d0, a1
;   - A slot is considered free if its first word == 0.
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_18016:
SingleObjLoad3:
	movea.l	a3, a1                          ; a1 = starting slot address (may be a3)
	moveq   #$0B, d0                        ; 12 checks total (DBF counts N+1)

SingleObjLoad3__MainLoop:
	tst.w	(a1)                            ; free slot?
	beq.s	+                               ; yes -> return with a1 on this slot
	lea     next_object(a1), a1             ; advance to next slot
	dbf     d0, SingleObjLoad3__MainLoop    ; scan up to 12 slots total
+
	rts
; ===========================================================================		
; ---------------------------------------------------------------------------
; SingleObjLoad4
; Scan the dynamic object table for the first free slot (word == 0).
; If found:  return with a1 -> free slot and exit.
; If none:   tail-call DeleteObject (note: relies on caller/context for a0).
;
; In:
;   (none)
; Out (on success):
;   a1 -> first free slot
;   (returns via RTS)
; Out (on failure):
;   Jumps to DeleteObject (non-returning tail call)
; Trashes:
;   d0, a1
;
; Assumptions:
;   - Object slots are 'object_size' bytes, with first word == 0 meaning "free".
;   - Dynamic_Object_RAM .. Dynamic_Object_RAM_End is contiguous.
;   - DeleteObject expects a0 to already be set appropriately by the caller.
; ---------------------------------------------------------------------------

SingleObjLoad4:
	lea     (Dynamic_Object_RAM).w, a1                      ; a1 = start of table
	; d0 = (#slots - 1); (#slots) = (end - start) / object_size
	move.w  #(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1, d0

SingleObjLoad4__Loop:
	tst.w   (a1)                                            ; free slot?
	beq.s   +                                               ; yes -> return with a1 here
	lea     next_object(a1), a1                             ; advance to next slot
	dbf     d0, SingleObjLoad4__Loop                        ; keep scanning while slots remain

	; No free slot found in the entire table:
	; Fall through to a tail call that clears an object (per original logic).
	; NOTE: DeleteObject uses a0 internally (moves a0 -> a1), so ensure
	;       the caller has a0 pointing at the object to clear BEFORE calling this.
	jmp     DeleteObject

+
	rts

; ===========================================================================	
; ---------------------------------------------------------------------------
; BadnikWeaponLoad
; Purpose:
;   Find a free dynamic object slot and initialize it from a template stream
;   pointed to by a2 (mixed-size fields in a fixed order). If no free slot
;   is available, tail-calls DeleteObject (caller must have a0 set properly).
;
; Inputs:
;   a0 = parent badnik object (used for facing/mirroring & spawn position)
;   a2 -> weapon template data stream in this order:
;         word   (object ID)
;         long   (mappings pointer)
;         word   (art_tile)
;         byte   (render_flags)
;         byte   (collision_response)
;         word   (priority)
;         byte   (width_pixels)
;         byte   (height_pixels)
;         word   (x_vel)
;         word   (y_vel)
;         byte   (anim)
;         byte   (mapping_frame)
;
; Outputs (on success):
;   a1 -> initialized weapon object
;   a2 advanced past the template fields read
;   RTS
;
; Failure behavior:
;   Scans entire table; if none free, JMP DeleteObject (non-returning).
;   NOTE: DeleteObject uses a0 internally; ensure caller set a0 as needed.
;
; Trashes: d0, a1 (also a2 is advanced)
; Assumptions:
;   - Free slot detected when first word of slot == 0.
;   - object_size == next_object - current slot base.
;   - Dynamic_Object_RAM .. Dynamic_Object_RAM_End contiguous.
;   - Bit #0 of parent render_flags(a0) indicates horizontal flip.
; ---------------------------------------------------------------------------

BadnikWeaponLoad:
	lea     (Dynamic_Object_RAM).w, a1
	move.w  #(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1, d0

BadnikWeaponLoad__Loop:
	tst.w   (a1)                                ; free slot?
	beq.s   BadnikWeaponLoad__LoadObjectData    ; yes -> init here
	lea     next_object(a1), a1                 ; advance to next slot
	dbf     d0, BadnikWeaponLoad__Loop          ; keep scanning
	jmp     DeleteObject                         ; none free -> tail-call clear

; ---- Initialize weapon object from template stream in a2 --------------------

BadnikWeaponLoad__LoadObjectData:
	move.w  (a2)+, (a1)                         ; id / routine / whatever first word is
	move.l  (a2)+, mappings(a1)                 ; mappings pointer
	move.w  (a2)+, art_tile(a1)
	move.b  (a2)+, render_flags(a1)
	move.b  (a2)+, collision_response(a1)
	move.w  (a2)+, priority(a1)
	move.b  (a2)+, width_pixels(a1)
	move.b  (a2)+, height_pixels(a1)
	move.w  (a2)+, x_vel(a1)
	move.w  (a2)+, y_vel(a1)
	move.b  (a2)+, anim(a1)
	move.b  (a2)+, mapping_frame(a1)

	; Mirror horizontal velocity if parent is flipped (bit 0 set)
	btst    #0, render_flags(a0)
	beq.s   +
	neg.w   x_vel(a1)
+
	; Spawn at parent position
	move.w  x_pos(a0), x_pos(a1)
	move.w  y_pos(a0), y_pos(a1)
	rts
; ===========================================================================

; ===========================================================================
; Load_Object1 — Load a *moving* object from a template stream
; In:
;   a0 -> target object slot
;   a2 -> template stream in this exact order:
;         word  id/routine
;         long  mappings ptr
;         word  art_tile
;         byte  render_flags
;         byte  collision_response
;         word  priority
;         byte  width_pixels
;         byte  height_pixels
;         word  x_vel
;         word  y_vel
;         byte  mapping_frame
; Out:
;   a0 initialized; a2 advanced past all fields; RTS
; Trashes: (a2)
; Notes:
;   - Includes velocities (moving object).
; ---------------------------------------------------------------------------
Load_Object1:
	move.w	(a2)+,(a0)                ; object id / routine word
	move.l	(a2)+,mappings(a0)        ; mappings pointer
	move.w	(a2)+,art_tile(a0)        ; VRAM tile index / art base
	move.b	(a2)+,render_flags(a0)    ; render flags (incl. flips/visibility)
	move.b	(a2)+,collision_response(a0) ; collision behavior
	move.w	(a2)+,priority(a0)        ; draw/logic priority
	move.b	(a2)+,width_pixels(a0)    ; bounding box width  (pixels)
	move.b	(a2)+,height_pixels(a0)   ; bounding box height (pixels)
	move.w	(a2)+,x_vel(a0)           ; initial X velocity
	move.w	(a2)+,y_vel(a0)           ; initial Y velocity
	move.b	(a2)+,mapping_frame(a0)   ; initial frame index
	rts

; ===========================================================================
; Load_Object2 — Load a *nonmoving* object (with collision) from a template
; In (order is identical to Load_Object1 until velocities are omitted):
;   a0 -> target object slot
;   a2 -> word id, long mappings, word art_tile, byte render_flags,
;         byte collision_response, word priority, byte width, byte height,
;         byte mapping_frame
; Out: a0 initialized; a2 advanced; RTS
; Notes:
;   - No velocities. Caller must ensure x_vel/y_vel are already zero if required.
; ---------------------------------------------------------------------------
Load_Object2:
	move.w	(a2)+,(a0)
	move.l	(a2)+,mappings(a0)
	move.w	(a2)+,art_tile(a0)
	move.b	(a2)+,render_flags(a0)
	move.b	(a2)+,collision_response(a0)
	move.w	(a2)+,priority(a0)
	move.b	(a2)+,width_pixels(a0)
	move.b	(a2)+,height_pixels(a0)
	move.b	(a2)+,mapping_frame(a0)
	rts

; ===========================================================================
; Load_Object3 — Load a *nonmoving, no-collision* object
; In (collision field omitted vs Load_Object2):
;   a0 -> target object slot
;   a2 -> word id, long mappings, word art_tile, byte render_flags,
;         word priority, byte width, byte height, byte mapping_frame
; Out: a0 initialized; a2 advanced; RTS
; Notes:
;   - Skips collision_response entirely.
;   - No velocities.
; ---------------------------------------------------------------------------
Load_Object3:
	move.w	(a2)+,(a0)
	move.l	(a2)+,mappings(a0)
	move.w	(a2)+,art_tile(a0)
	move.b	(a2)+,render_flags(a0)
	move.w	(a2)+,priority(a0)
	move.b	(a2)+,width_pixels(a0)
	move.b	(a2)+,height_pixels(a0)
	move.b	(a2)+,mapping_frame(a0)
	rts

; ===========================================================================
; Load_Object4 — Load *secondary properties* (e.g., a broken monitor state)
; In:
;   a0 -> target object slot
;   a2 -> word id, byte mapping_frame, byte anim
; Out: a0 updated; a2 advanced; RTS
; Notes:
;   - Minimal update: swaps routine/id + visual/anim state only.
; ---------------------------------------------------------------------------
Load_Object4:
	move.w	(a2)+,(a0)                ; new id / routine step
	move.b	(a2)+,mapping_frame(a0)   ; forced frame
	move.b	(a2)+,anim(a0)            ; forced animation
	rts
