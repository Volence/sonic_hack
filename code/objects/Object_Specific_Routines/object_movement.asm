; ---------------------------------------------------------------------------
; Subroutine to make an object move and fall downward increasingly fast
; This moves the object horizontally and vertically
; and also applies gravity to its speed
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_16380: ObjectFall:
ObjectMoveAndFall:
	move.w  x_vel(a0),d0
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,x_pos(a0)
	move.w  y_vel(a0),d0
	addi.w  #$38,y_vel(a0) ; apply gravity
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,y_pos(a0)
	rts
; End of function ObjectMoveAndFall
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

; ---------------------------------------------------------------------------
; Subroutine translating object speed to update object position
; This moves the object horizontally and vertically
; but does not apply gravity to it
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_163AC: SpeedToPos:
ObjectMove:
	move.w  x_vel(a0),d0
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,x_pos(a0)
	move.w  y_vel(a0),d0
	ext.l   d0
	lsl.l   #8,d0
	add.l   d0,y_pos(a0)
	rts
; End of function ObjectMove
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>