	dc.w Monitor__Blank - Ani_Monitor	; 0 Blank
	dc.w Monitor__Broken - Ani_Monitor	; 1 Broken
	dc.w Monitor__Sonic - Ani_Monitor	; 2 Sonic
	dc.w Monitor__Tails - Ani_Monitor	; 3 Tails
	dc.w Monitor__Robotnik - Ani_Monitor	; 4 Robotnik
	dc.w Monitor__Ring - Ani_Monitor	; 5 Rings
	dc.w Monitor__Shoe - Ani_Monitor	; 6 Shoes
	dc.w Monitor__Invincible - Ani_Monitor	; 7 Invincible
	dc.w Monitor__SuperSonic - Ani_Monitor	; 8 SuperSonic
	dc.w Monitor__Bubble - Ani_Monitor	; 9 Bubble
	dc.w Monitor__Lightning - Ani_Monitor	; A Lightning
	dc.w Monitor__Fire - Ani_Monitor	; B Fire
	dc.w Monitor__Wind - Ani_Monitor	; C Wind

Monitor__Blank:
	dc.b	$01	; duration
	dc.b	$00	; frame number (which sprite table to use)
	dc.b	$01	; frame number
	dc.b	$FF	; terminator
Monitor__Sonic:			dc.b   1,  0,  2,  2,  0,  2,  2,$FF
Monitor__Tails:			dc.b   1,  0,  3,  3,  0,  3,  3,$FF
Monitor__Robotnik:		dc.b   1,  0,  4,  4,  0,  4,  4,$FF
Monitor__Ring:			dc.b   1,  0,  5,  5,  0,  5,  5,$FF
Monitor__Shoe:			dc.b   1,  0,  6,  6,  0,  6,  6,$FF
Monitor__Invincible:	dc.b   1,  0,  7,  7,  0,  7,  7,$FF
Monitor__SuperSonic:	dc.b   1,  0,  8,  8,  0,  8,  8,$FF
Monitor__Bubble:		dc.b   1,  0,  9,  9,  0,  9,  9,$FF
Monitor__Lightning:		dc.b   1,  0, $A, $A,  0, $A, $A,$FF
Monitor__Fire:			dc.b   1,  0, $B, $B,  0, $B, $B,$FF
Monitor__Wind:			dc.b   1,  0, $C, $C,  0, $C, $C,$FF
Monitor__Broken:		dc.b   2,  0,  1, 1,$FE,  1