	dc.w Monitor__Data - Ani_Monitor	; frame 0
	dc.w Monitor__Sonic - Ani_Monitor	; 1 Sonic
	dc.w Monitor__Tails - Ani_Monitor	; 2 Tails
	dc.w Monitor__Robotnik - Ani_Monitor	; 3 Robotnik
	dc.w Monitor__Ring - Ani_Monitor	; 4 Rings
	dc.w Monitor__Shoe - Ani_Monitor	; 5 Shoes
	dc.w Monitor__Bubble - Ani_Monitor	; 6 Bubble
	dc.w Monitor__Invincible - Ani_Monitor	; 7 Invincible
	dc.w Monitor__Broken - Ani_Monitor	; 8 Null
	dc.w Monitor__SuperSonic - Ani_Monitor	; 9 SuperSonic
	dc.w Monitor__Broken - Ani_Monitor	; A Broken
	dc.w Monitor__Lightning - Ani_Monitor	; B Fire
	dc.w Monitor__Fire - Ani_Monitor	; C Lightning

Monitor__Data:
	dc.b	$01	; duration
	dc.b	$00	; frame number (which sprite table to use)
	dc.b	$01	; frame number
	dc.b	$FF	; terminator
Monitor__Sonic:			dc.b   1,  0,  2,  2,  1,  2,  2,$FF
Monitor__Tails:			dc.b   1,  0,  3,  3,  1,  3,  3,$FF
Monitor__Robotnik:		dc.b   1,  0,  4,  4,  1,  4,  4,$FF
Monitor__Ring:			dc.b   1,  0,  5,  5,  1,  5,  5,$FF
Monitor__Shoe:			dc.b   1,  0,  6,  6,  1,  6,  6,$FF
Monitor__Bubble:		dc.b   1,  0,  7,  7,  1,  7,  7,$FF
Monitor__Invincible:	dc.b   1,  0,  8,  8,  1,  8,  8,$FF
Monitor__SlowShoe:		dc.b   1,  0,  9,  9,  1,  9,  9,$FF
Monitor__SuperSonic:	dc.b   1,  0, $A, $A,  1, $A, $A,$FF
Monitor__Lightning:		dc.b   1,  0, $C, $C,  1, $C, $C,$FF
Monitor__Fire:			dc.b   1,  0, $D, $D,  1, $D, $D,$FF
Monitor__Broken:		dc.b   2,  0,  1, $B,$FE,  1