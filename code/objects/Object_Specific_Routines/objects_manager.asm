; ---------------------------------------------------------------------------
; Objects Manager
; Subroutine that loads objects from an act's object layout once they are in
; range and keeps track of any objects that need to remember their state, such
; as monitors or enemies.
; Weather an object is in range is determined by its x-position. Objects are
; checked on a per-chunk basis, rather than using the exact camera coordinates.
; An object is out of range when it is either two chunks behind the left edge of
; the screen or two chunks beyond the right edge.
; Every object that remembers its state has its own entry in the object respawn table.
; How this entry is used is up to the object, itself.
; The first two bytes in the respawn table do not belong to any object, instead they
; keep track of how many respawning objects have moved in range from the right
; and how many have moved out of range from the left, respectively.
; ---------------------------------------------------------------------------

ObjectsManager:
	moveq	#0,d0
	move.b	(Obj_placement_routine).w,d0
	move.w	+(pc,d0.w),d0
	jmp	+(pc,d0.w)
; ============== RELATIVE OFFSET LIST     ===================================
/	dc.w ObjectsManager_Init - (-)
	dc.w ObjectsManager_Main - (-); 2
; ============== END RELATIVE OFFSET LIST ===================================
ObjectsManager_Init:
	addq.b	#2,(Obj_placement_routine).w
	move.w	(Current_ZoneAndAct).w,d0 ; If level == $0F01 (ARZ 2)...
	ror.b	#1,d0			; then this yields $0F80...
	lsr.w	#6,d0			; and this yields $003E.
	lea	(Off_Objects).l,a0	; Next, we load the first pointer in the object layout list pointer index,
	movea.l	a0,a1			; then copy it for quicker use later.
	adda.w	(a0,d0.w),a0		; (Point1 * 2) + $003E

	move.l	a0,(Obj_load_addr_0).w
	move.l	a0,(Obj_load_addr_1).w
	move.l	a0,(Obj_load_addr_2).w
	move.l	a0,(Obj_load_addr_3).w
	lea	(Object_Respawn_Table).w,a2	; load respawn list
	move.w	#$101,(a2)+	; the first two bytes are not used as respawn values
	move.w	#$5E,d0		; set loop counter

-
	clr.l	(a2)+		; loop clears all other respawn values
	dbf	d0,-

	lea	(Object_Respawn_Table).w,a2	; reset
	moveq	#0,d2
	move.w	(Camera_X_pos).w,d6
	subi.w	#$80,d6	; pretend the camera is farther left
	bcc.s	+	; if the result was not negative, skip the next instruction
	moveq	#0,d6	; no negative values allowed
+
	andi.w	#$FF80,d6	; limit to increments of $80 (width of a chunk)
	movea.l	(Obj_load_addr_0).w,a0	; load address of object placement list

-	; at the beginning of a level this gives respawn table entries to any object that is one chunk
	; behind the left edge of the screen that needs to remember its state (Monitors, Badniks, etc.)
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17B3E	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	move.b	(a2),d2
	addq.b	#1,(a2)	; number of objects with a respawn table entry, so far
+
	addq.w	#6,a0	; next object
	bra.s	-
; ---------------------------------------------------------------------------

loc_17B3E:
	move.l	a0,(Obj_load_addr_0).w	; remember rightmost object that has been processed, so far (we still need to look forward)
	move.l	a0,(Obj_load_addr_2).w
	movea.l	(Obj_load_addr_1).w,a0	; reset
	subi.w	#$80,d6		; look even farther left (any object behind this is out of range)
	bcs.s	loc_17B62	; branch, if camera position would be behind level's left boundary

-	; count how many objects are behind the screen that are not in range and need to remember their state
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17B62	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	addq.b	#1,1(a2)	; out-of-range number of objects with a respawn table entry

+
	addq.w	#6,a0
	bra.s	-	; continue with next object
; ---------------------------------------------------------------------------

loc_17B62:
	move.l	a0,(Obj_load_addr_1).w	; remember rightmost out-of-range object
	move.l	a0,(Obj_load_addr_3).w
	move.w	#-1,(Camera_X_pos_last).w	; make sure the GoingForward routine is run
	move.w	#-1,($FFFFF78C).w
; ---------------------------------------------------------------------------
; loc_17B84
ObjectsManager_Main:
	move.w	(Camera_X_pos).w,d1
	subi.w	#$80,d1
	andi.w	#$FF80,d1
	move.w	d1,(Camera_X_pos_coarse).w

	lea	(Object_Respawn_Table).w,a2
	moveq	#0,d2
	move.w	(Camera_X_pos).w,d6
	andi.w	#$FF80,d6
	cmp.w	(Camera_X_pos_last).w,d6	; is the X range the same as last time?
	beq.w	ObjectsManager_SameXRange	; if yes, branch
	bge.s	ObjectsManager_GoingForward	; if new pos is greater than old pos, branch
	; if the player is moving back
	move.w	d6,(Camera_X_pos_last).w
	movea.l	(Obj_load_addr_1).w,a0	; get rightmost out-of-range object
	subi.w	#$80,d6		; pretend the camera is farther to the left
	bcs.s	loc_17BE6	; branch, if camera position would be behind level's left boundary

-	; load all objects left of the screen that are now in range
	cmp.w	-6(a0),d6	; is the previous object's X pos less than d6?
	bge.s	loc_17BE6	; if it is, branch
	subq.w	#6,a0
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	subq.b	#1,1(a2)	; out-of-range number of objects with a respawn table entry
	move.b	1(a2),d2	; this will be the object's index in the respawn table
+
	bsr.w	ChkLoadObj	; load object
	bne.s	+		; branch, if SST is full
	subq.w	#6,a0
	bra.s	-	; continue with previous object
; ---------------------------------------------------------------------------

+	; undo a few things, if the object couldn't load
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	addq.b	#1,1(a2)	; since we didn't load the object, undo last decrement
+
	addq.w	#6,a0	; go back to next object

loc_17BE6:
	move.l	a0,(Obj_load_addr_1).w	; remember rightmost out-of-range object
	movea.l	(Obj_load_addr_0).w,a0	; get rightmost in-range object
	addi.w	#$300,d6	; look two chunks beyond the right edge of the screen

-	; subtract number of objects that have been moved out-of-range (from the right side)
	cmp.w	-6(a0),d6	; is the previous object's X pos less than d6?
	bgt.s	loc_17C04	; if it is, branch
	tst.b	-4(a0)	; does the previous object get a respawn table entry?
	bpl.s	+	; if not, branch
	subq.b	#1,(a2)	; number of objects with a respawn table entry
+
	subq.w	#6,a0
	bra.s	-	; continue with previous object
; ---------------------------------------------------------------------------

loc_17C04:
	move.l	a0,(Obj_load_addr_0).w	; remember rightmost in-range object
	rts
; ---------------------------------------------------------------------------

ObjectsManager_GoingForward:
	move.w	d6,(Camera_X_pos_last).w
	movea.l	(Obj_load_addr_0).w,a0	; get rightmost in-range object
	addi.w	#$280,d6	; look two chunks forward

-	; load all objects right of the screen, that are now in range
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17C2A	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	move.b	(a2),d2	; this will be the object's index in the respawn table
	addq.b	#1,(a2)	; number of objects with a respawn table entry
+
	bsr.w	ChkLoadObj	; load object
	beq.s	-	; continue loading objects, if the SST isn't full

loc_17C2A:
	move.l	a0,(Obj_load_addr_0).w	; remember rightmost in-range object
	movea.l	(Obj_load_addr_1).w,a0	; get rightmost out-of-range object
	subi.w	#$300,d6	; look two chunks behind the left edge of the screen
	bcs.s	loc_17C4A	; branch, if camera position would be behind level's left boundary

-	; count number of objects that have been moved out-of-range (from the left)
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	loc_17C4A	; if yes, branch
	tst.b	2(a0)	; does the object get a respawn table entry?
	bpl.s	+	; if not, branch
	addq.b	#1,1(a2)	; out-of-range number of objects with a respawn table entry
+
	addq.w	#6,a0
	bra.s	-	; continue with next object
; ---------------------------------------------------------------------------

loc_17C4A:
	move.l	a0,(Obj_load_addr_1).w	; remember rightmost out-of-range object

ObjectsManager_SameXRange:
	rts

; ===========================================================================
;loc_17F36
ChkLoadObj:
	tst.b	2(a0)			; does the object get a respawn table entry?
	bpl.s	+			; if not, branch
	bset	#7,respawnentry(a2,d2.w)		; mark object as loaded
	beq.s	+			; branch if it wasn't already loaded
	addq.w	#6,a0			; next object
	moveq	#0,d0			; let the objects manager know that it can keep going
	rts
+	moveq	#0,d0
	move.b	4(a0),d0		; get object index
	subq	#1,d0			; is it empty?
	bmi.b	ChkLoadObj_Empty	; if so, branch
	add.w	d0,d0			; form word indices
	move.w	Obj_Index(pc,d0.w),a3	; get object's initial routine
	bsr.w	SingleObjLoad		; find empty slot
	bne.s	ChkLoadObj_Return	; branch, if there is no room left in the SST
	move.w	a3,(a1)			; set object routine pointer
	move.w	(a0)+,x_pos(a1)
	move.w	(a0)+,d0		; there are three things stored in this word
	bpl.s	+			; branch, if the object doesn't get a respawn table entry
	move.b	d2,respawn_index(a1)	; this value is provided by the objects manager
+	move.w	d0,d1			; copy for later
	andi.w	#$FFF,d0		; filter out y-position
	move.w	d0,y_pos(a1)
	rol.w	#3,d1			; adjust bits
	andi.b	#3,d1			; filter lowest two
	move.b	d1,render_flags(a1)
	move.b	d1,status(a1)
	move.w	(a0)+,d0
	move.b	d0,subtype(a1)

ChkLoadObj_Empty:
	moveq	#0,d0

ChkLoadObj_Return:
	rts