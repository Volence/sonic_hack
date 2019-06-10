	dc.w byte_12CE4 - Ani_Monitor	; frame 0
	dc.w byte_12CE8 - Ani_Monitor	; 1
	dc.w byte_12CF0 - Ani_Monitor	; 2
	dc.w byte_12CF8 - Ani_Monitor	; 3
	dc.w byte_12D00 - Ani_Monitor	; 4
	dc.w byte_12D08 - Ani_Monitor	; 5
	dc.w byte_12D10 - Ani_Monitor	; 6
	dc.w byte_12D18 - Ani_Monitor	; 7
	dc.w byte_12D20 - Ani_Monitor	; 8
	dc.w byte_12D28 - Ani_Monitor	; 9
	dc.w byte_12D30 - Ani_Monitor	; 10
byte_12CE4:
	dc.b	$01	; duration
	dc.b	$00	; frame number (which sprite table to use)
	dc.b	$01	; frame number
	dc.b	$FF	; terminator
byte_12CE8:	dc.b   1,  0,  2,  2,  1,  2,  2,$FF
byte_12CF0:	dc.b   1,  0,  3,  3,  1,  3,  3,$FF
byte_12CF8:	dc.b   1,  0,  4,  4,  1,  4,  4,$FF
byte_12D00:	dc.b   1,  0,  5,  5,  1,  5,  5,$FF
byte_12D08:	dc.b   1,  0,  6,  6,  1,  6,  6,$FF
byte_12D10:	dc.b   1,  0,  7,  7,  1,  7,  7,$FF
byte_12D18:	dc.b   1,  0,  8,  8,  1,  8,  8,$FF
byte_12D20:	dc.b   1,  0,  9,  9,  1,  9,  9,$FF
byte_12D28:	dc.b   1,  0, $A, $A,  1, $A, $A,$FF
byte_12D30:	dc.b   2,  0,  1, $B,$FE,  1