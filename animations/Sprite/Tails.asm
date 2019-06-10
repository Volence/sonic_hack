	dc.w TailsAni_Walk - TailsAniData	; 0
	dc.w TailsAni_Run - TailsAniData	; 1
	dc.w TailsAni_Roll - TailsAniData	; 2
	dc.w TailsAni_Roll2 - TailsAniData	; 3
	dc.w TailsAni_Push - TailsAniData	; 4
	dc.w TailsAni_Wait - TailsAniData	; 5
	dc.w TailsAni_Balance - TailsAniData	; 6
	dc.w TailsAni_LookUp - TailsAniData	; 7
	dc.w TailsAni_Duck - TailsAniData	; 8
	dc.w TailsAni_Spindash - TailsAniData	; 9
	dc.w TailsAni_Dummy1 - TailsAniData	; 10 ; $A
	dc.w TailsAni_Dummy2 - TailsAniData	; 11 ; $B
	dc.w TailsAni_Dummy3 - TailsAniData	; 12 ; $C
	dc.w TailsAni_Stop - TailsAniData	; 13 ; $D
	dc.w TailsAni_Float - TailsAniData	; 14 ; $E
	dc.w TailsAni_Float2 - TailsAniData	; 15 ; $F
	dc.w TailsAni_Spring - TailsAniData	; 16 ; $10
	dc.w TailsAni_Hang - TailsAniData	; 17 ; $11
	dc.w TailsAni_Blink - TailsAniData	; 18 ; $12
	dc.w TailsAni_Blink2 - TailsAniData	; 19 ; $13
	dc.w TailsAni_Hang2 - TailsAniData	; 20 ; $14
	dc.w TailsAni_Bubble - TailsAniData	; 21 ; $15
	dc.w TailsAni_Death3 - TailsAniData	; 22 ; $16
	dc.w TailsAni_Drown - TailsAniData	; 23 ; $17
	dc.w TailsAni_Death - TailsAniData	; 24 ; $18
	dc.w TailsAni_Death2 - TailsAniData	; 25 ; $19
	dc.w TailsAni_Hurt - TailsAniData	; 26 ; $1A
	dc.w TailsAni_Slide - TailsAniData	; 27 ; $1B
	dc.w TailsAni_Blank - TailsAniData	; 28 ; $1C
	dc.w TailsAni_Dummy4 - TailsAniData	; 29 ; $1D
	dc.w TailsAni_Dummy5 - TailsAniData	; 30 ; $1E
	dc.w TailsAni_HaulAss - TailsAniData	; 31 ; $1F
        dc.w TailsAni_Fly-TailsAniData; 32 20
        dc.w TailsAni21-TailsAniData; 33 21
        dc.w TailsAni22-TailsAniData; 33 26
        dc.w TailsAni23-TailsAniData; 33 24
        dc.w TailsAni24-TailsAniData; 33 25
        dc.w TailsAni25-TailsAniData; 33 26
        dc.w TailsAni26-TailsAniData; 33 27
        dc.w TailsAni27-TailsAniData; 33 28
        dc.w TailsAni28-TailsAniData; 32 20
        dc.w TailsAni29-TailsAniData; 32 20

TailsAni_Walk:	dc.b  $FF,   7,	  8,   1,   2,	 3,   4,   5,	6, $FF
TailsAni_Run:	dc.b  $FF, $21,	$22, $23, $24, $FF, $FF, $FF, $FF, $FF
TailsAni_Roll:	dc.b	1, $96,	$97, $98, $FF
TailsAni_Roll2:	dc.b	0, $96,	$97, $98, $FF
TailsAni_Push:	dc.b  $FD, $A9,	$AA, $AB, $AC, $FF, $FF, $FF, $FF, $FF
TailsAni_Wait:	dc.b	7, $AD,	$AD, $AD, $AD, $AD, $AD, $AD, $AD, $AD,	$AD
			dc.b	$AF, $AE, $AD, $AD, $AD, $AD, $AD,	$AD, $AD, $AD, $AF
			dc.b	$AE, $AD, $AD, $AD,	$AD, $AD, $AD, $AD, $AD, $AD
		    dc.b  $B1, $B1,	$B1, $B1, $B1, $B1, $B1, $B1, $B1, $B1,	$B1, $B1
			dc.b	$B1, $B1, $B1, $B1, $B2, $B3,	$B4, $B3, $B4, $B3
			dc.b	$B4, $B3, $B4, $B3,	$B4, $B2, $FF, $1C
TailsAni_Balance:	dc.b	9, $9A,	$9A, $9B, $9B, $9A, $9A, $9B, $9B, $9A,	$9A, $9B
			dc.b	$9B, $9A, $9A, $9B, $9B, $9A,	$9A, $9B, $9B, $9A, $9B, $FF
TailsAni_LookUp:	dc.b  $3F, $B0,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Duck:	dc.b  $3F, $99,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Spindash:	dc.b	0, $86,	$87, $88, $FF ;	DATA XREF: ROM:00015AB0o
TailsAni_Dummy1:	dc.b  $3F, $82,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Dummy2:	dc.b   $F, $8D,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Dummy3:	dc.b	9, $A4,	$9B, $FF ; DATA	XREF: ROM:00015AB0o
TailsAni_Stop:	dc.b	3, $8E,	$8F, $8E, $8F, $FD,   0	; DATA XREF: ROM:00015AB0o
TailsAni_Float:	dc.b	9, $B5,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Float2:	dc.b	9, $B5,	$B6, $B7, $B8, $B9, $BA, $BB, $BC, $FF
TailsAni_Spring:	dc.b	3, $8B,	$8C, $8B, $8C, $8B, $8C, $8B, $8C, $8B,	$8C, $8B, $8C, $FD,   0
TailsAni_Hang:	dc.b	1, $9D,	$9E, $FF ; DATA	XREF: ROM:00015AB0o
TailsAni_Blink:	dc.b   $F,   1,	  2,   3, $FE,	 1 ; DATA XREF:	ROM:00015AB0o
TailsAni_Blink2:	dc.b   $F, $A5,	$A6, $FE,   1 ;	DATA XREF: ROM:00015AB0o
TailsAni_Hang2:	dc.b  $13, $91,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Bubble:	dc.b   $B, $9F,	$9F,   3,   4, $FD,   0	; DATA XREF: ROM:00015AB0o
TailsAni_Death3:	dc.b  $20, $9C,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Drown:	dc.b  $2F, $9C,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Death:	dc.b	3, $9C,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Death2:	dc.b	9, $CB,	$CC, $FF ; DATA	XREF: ROM:00015AB0o
TailsAni_Hurt:	dc.b  $40, $8A,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Slide:	dc.b	9, $89,	$8A, $FF ; DATA	XREF: ROM:00015AB0o
TailsAni_Blank:	dc.b  $77,   0,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni_Dummy4:	dc.b 3,	1, 2, 3, 4, 5, 6, 7, 8,	$FF ; DATA XREF: ROM:00015AB0o
TailsAni_Dummy5:	dc.b	3,   1,	  2,   3,   4,	 5,   6,   7,	8, $FF
TailsAni_HaulAss:	dc.b  $FF, $C3,	$C4, $FF, $FF, $FF, $FF, $FF, $FF, $FF
TailsAni_Fly:	dc.b  $1F, $A0,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni21:	dc.b  $1F, $A0,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni22:	dc.b  $1F, $A2,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni23:	dc.b  $1F, $A1,	$FF	; DATA XREF: ROM:00015AB0o
TailsAni24:	dc.b   $B, $A3,	$A4, $FF ; DATA	XREF: ROM:00015AB0o
TailsAni25:	dc.b	7, $BD,	$BE, $BF, $C0, $C1, $FF	; DATA XREF: ROM:00015AB0o
TailsAni26:	dc.b	3, $BD,	$BE, $BF, $C0, $C1, $FF	; DATA XREF: ROM:00015AB0o
TailsAni27:	dc.b	4, $CF,	$D0, $FF ; DATA	XREF: ROM:00015AB0o
TailsAni28:	dc.b   $B, $C2,	$CD, $CE, $FF ;	DATA XREF: ROM:00015AB0o
TailsAni29:	dc.b	2, $EB,	$EB, $EC, $ED, $EC, $ED, $EC, $ED, $EC,	$ED, $EC, $ED, $FD,   0