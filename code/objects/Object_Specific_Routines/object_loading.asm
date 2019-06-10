; ---------------------------------------------------------------------------
; Single object loading subroutine
; Find an empty object array of $40 bytes
; ---------------------------------------------------------------------------

SingleObjLoad:
	lea	(Dynamic_Object_RAM).w,a1 ; a1=object
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d0 ; search to end of table

loc_17FEC:
	tst.w	(a1)			; is object RAM slot empty?
	beq.s	return_17FF8
	lea	next_object(a1),a1	; load obj address ; goto next object RAM slot
	dbf	d0,loc_17FEC		; repeat until end

return_17FF8:
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Single object loading subroutine
; Find an empty object array AFTER the current one in the table
; ---------------------------------------------------------------------------

SingleObjLoad2:
	movea.l	a0,a1
	move.w	#Tails_Tails,d0		; $D000
	sub.w	a0,d0			; subtract current object location
	lsr.w	#object_align,d0	; divide by $40
	subq.w	#1,d0			; keep from going over the object zone
	bcs.s	return_18014

loc_18008:
	tst.w	(a1)			; is object RAM slot empty?
	beq.s	return_18014		; if yes, branch
	lea	next_object(a1),a1	; load obj address ; goto next object RAM slot
	dbf	d0,loc_18008		; repeat until end

return_18014:
	rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Single object loading subroutine
; Find an empty object at or within < 12 slots after a3
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_18016:
SingleObjLoad3:
	movea.l	a3,a1
	move.w	#$B,d0

loc_1801C:
	tst.w	(a1)	; is object RAM slot empty?
	beq.s	return_18028	; if yes, branch
	lea	next_object(a1),a1 ; load obj address ; goto next object RAM slot
	dbf	d0,loc_1801C	; repeat until end

return_18028:
	rts

; ===========================================================================		
SingleObjLoad4:
	lea	(Dynamic_Object_RAM).w,a1 ; a1=object
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d0 ; search to end of table

SOJ4_Loop:
	tst.w	(a1)			; is object RAM slot empty?
	beq.s	+
	lea	next_object(a1),a1	; load obj address ; goto next object RAM slot
	dbf	d0,SOJ4_Loop		; repeat until end
	jmp	DeleteObject	
+
	rts	
; ===========================================================================	
BadnikWeaponLoad:	
	lea	(Dynamic_Object_RAM).w,a1 ; a1=object
	move.w	#(Dynamic_Object_RAM_End-Dynamic_Object_RAM)/object_size-1,d0 ; search to end of table

BWL_Loop:
	tst.w	(a1)			; is object RAM slot empty?
	beq.s	+
	lea	next_object(a1),a1	; load obj address ; goto next object RAM slot
	dbf	d0,BWL_Loop		; repeat until end
	jmp	DeleteObject
+	
	move.w	(a2)+,(a1)
	move.l	(a2)+,mappings(a1)
	move.w	(a2)+,art_tile(a1)
	move.b	(a2)+,render_flags(a1)
	move.b	(a2)+,collision_response(a1)
	move.w	(a2)+,priority(a1)
	move.b	(a2)+,width_pixels(a1)
	move.b	(a2)+,height_pixels(a1)
	move.w	(a2)+,x_vel(a1)
	move.w	(a2)+,y_vel(a1)
	move.b	(a2)+,anim(a1)
	move.b	(a2)+,mapping_frame(a1)
	btst	#0,render_flags(a0)
	beq.w	+
	neg.w	x_vel(a1)
+	
	move.w	x_pos(a0),x_pos(a1)
	move.w	y_pos(a0),y_pos(a1)

BWL_Loc:
	rts
; ===========================================================================
; Load up a moving object
Load_Object1:
	move.w	(a2)+,(a0)
	move.l	(a2)+,mappings(a0)
	move.w	(a2)+,art_tile(a0)
	move.b	(a2)+,render_flags(a0)
	move.b	(a2)+,collision_response(a0)
	move.w	(a2)+,priority(a0)
	move.b	(a2)+,width_pixels(a0)
	move.b	(a2)+,height_pixels(a0)
	move.w	(a2)+,x_vel(a0)
	move.w	(a2)+,y_vel(a0)
	move.b	(a2)+,mapping_frame(a0)
	rts
; Load up nonmoving object	
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
; Load up nonmoving object with no collision	
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
; Load up secondary properties (eg- a broken monitor)	
Load_Object4:
	move.w	(a2)+,(a0)
	move.b	(a2)+,mapping_frame(a0)
	move.b	(a2)+,anim(a0)
	rts