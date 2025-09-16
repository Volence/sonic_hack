; ---------------------------------------------------------------------------
; ObjectMoveAndFall
; Purpose:
;   Move an object using 24.8 fixed-point velocity and apply gravity.
;   - X position advances by x_vel * 256 (8-bit frac).
;   - Y position advances by y_vel * 256 (using the *pre-gravity* velocity),
;     then y_vel is increased by a constant gravity (0x38 per frame).
;
; Conventions:
;   - Positions (x_pos/y_pos) are 24.8 fixed-point (integer<<8 + fractional).
;   - Velocities (x_vel/y_vel) are signed 16-bit integers in pixels/frame.
;   - Gravity is applied to y_vel *after* this frame's Y movement is computed
;     (semi-implicit Euler with “velocity update after position” semantics).
;
; Inputs:
;   a0 -> object
; Clobbers:
;   d0
; ---------------------------------------------------------------------------

ObjectMoveAndFall:
	; ---- X: pos += (signed) x_vel << 8
	move.w  x_vel(a0), d0        ; d0 = x_vel (16-bit, signed)
	ext.l   d0                   ; sign-extend to 32-bit
	lsl.l   #8, d0               ; scale to 24.8 fixed (<< 8)
	add.l   d0, x_pos(a0)        ; x_pos += x_vel<<8

	; ---- Y: pos += (signed) y_vel << 8, then apply gravity to y_vel
	move.w  y_vel(a0), d0        ; d0 = current (pre-gravity) y_vel
	addi.w  #$38, y_vel(a0)      ; y_vel += gravity (0x38 per frame)
	ext.l   d0                   ; sign-extend to 32-bit
	lsl.l   #8, d0               ; scale to 24.8 fixed
	add.l   d0, y_pos(a0)        ; y_pos += old y_vel<<8

	rts
; End of function ObjectMoveAndFall


; ---------------------------------------------------------------------------
; ObjectMove
; Purpose:
;   Translate current velocity into position delta (24.8 fixed-point).
;   - X position advances by x_vel * 256.
;   - Y position advances by y_vel * 256.
;   - No acceleration/gravity applied here (pure integrator).
;
; Conventions:
;   - x_pos/y_pos: 24.8 fixed (integer<<8 + fractional).
;   - x_vel/y_vel: signed 16-bit pixels per frame.
;
; Inputs:
;   a0 -> object
; Clobbers:
;   d0
; ---------------------------------------------------------------------------

ObjectMove:
	; ---- X: pos += (signed) x_vel << 8
	move.w  x_vel(a0), d0        ; d0 = x_vel (16-bit, signed)
	ext.l   d0                   ; sign-extend to 32-bit
	lsl.l   #8, d0               ; scale to 24.8 fixed (<< 8)
	add.l   d0, x_pos(a0)        ; x_pos += x_vel<<8

	; ---- Y: pos += (signed) y_vel << 8
	move.w  y_vel(a0), d0        ; d0 = y_vel (16-bit, signed)
	ext.l   d0                   ; sign-extend to 32-bit
	lsl.l   #8, d0               ; scale to 24.8 fixed
	add.l   d0, y_pos(a0)        ; y_pos += y_vel<<8

	rts
; End of function ObjectMove

; ---------------------------------------------------------------------------
; Subroutine translating object speed to update object position
; (FOR OBJECTS WITH DIFFERENT X & Y POSITION LOCATIONS)
;   - Positions at $08(a0) (X) and $0A(a0) (Y) are 24.8 fixed-point.
;   - Velocities at $10(a0) (X) and $12(a0) (Y) are signed 16-bit pixels/frame.
;   - Adds (vel << 8) to each position.
; Clobbers: d0
; ---------------------------------------------------------------------------

ObjectMove_AltPos:
	; X: posX += (signed) velX << 8
	move.w  $10(a0), d0         ; d0 = velX
	ext.l   d0                  ; sign-extend to 32-bit
	asl.l   #8, d0              ; scale to 24.8 (<< 8)
	add.l   d0, $08(a0)         ; posX += delta

	; Y: posY += (signed) velY << 8
	move.w  $12(a0), d0         ; d0 = velY
	ext.l   d0
	asl.l   #8, d0
	add.l   d0, $0A(a0)         ; posY += delta

	rts