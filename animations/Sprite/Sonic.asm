	dc.w SonAni_Walk - SonicAniData		; 0
	dc.w SonAni_Run - SonicAniData		; 1
	dc.w SonAni_Roll - SonicAniData		; 2
	dc.w SonAni_Roll2 - SonicAniData	; 3
	dc.w SonAni_Push - SonicAniData		; 4
	dc.w SonAni_Wait - SonicAniData		; 5
	dc.w SonAni_Balance - SonicAniData	; 6
	dc.w SonAni_LookUp - SonicAniData	; 7
	dc.w SonAni_Duck - SonicAniData		; 8
	dc.w SonAni_Spindash - SonicAniData	; 9
	dc.w SonAni_Blink - SonicAniData	; 10 ; $A
	dc.w SonAni_GetUp - SonicAniData	; 11 ; $B
	dc.w SonAni_Balance2 - SonicAniData	; 12 ; $C
	dc.w SonAni_Stop - SonicAniData		; 13 ; $D
	dc.w SonAni_Float - SonicAniData	; 14 ; $E
	dc.w SonAni_Float2 - SonicAniData	; 15 ; $F
	dc.w SonAni_Spring - SonicAniData	; 16 ; $10
	dc.w SonAni_Hang - SonicAniData		; 17 ; $11
	dc.w SonAni_Dash2 - SonicAniData	; 18 ; $12
	dc.w SonAni_Dash3 - SonicAniData	; 19 ; $13
	dc.w SonAni_Hang2 - SonicAniData	; 20 ; $14
	dc.w SonAni_Bubble - SonicAniData	; 21 ; $15
	dc.w SonAni_DeathBW - SonicAniData	; 22 ; $16
	dc.w SonAni_Drown - SonicAniData	; 23 ; $17
	dc.w SonAni_Death - SonicAniData	; 24 ; $18
	dc.w SonAni_Hurt - SonicAniData		; 25 ; $19
	dc.w SonAni_Hurt - SonicAniData		; 26 ; $1A
	dc.w SonAni_Slide - SonicAniData	; 27 ; $1B
	dc.w SonAni_Blank - SonicAniData	; 28 ; $1C
	dc.w SonAni_Balance3 - SonicAniData	; 29 ; $1D
	dc.w SonAni_Balance4 - SonicAniData	; 30 ; $1E
	dc.w SupSonAni_Transform - SonicAniData	; 31 ; $1F
	dc.w SonAni_Lying - SonicAniData	; 32 ; $20
	dc.w SonAni_LieDown - SonicAniData	; 33 ; $21
	dc.w SonAni_Shoot - SonicAniData
SonAni_Walk:	dc.b  $FF,   7,	  8,   1,   2,	 3,   4,   5,	6, $FF
SonAni_Run:	dc.b  $FF, $21,	$22, $23, $24, $FF, $FF, $FF, $FF, $FF
SonAni_Roll:	dc.b  $FE, $96,	$97, $96, $98, $96, $99, $96, $9A, $FF
SonAni_Roll2:	dc.b  $FE, $96,	$97, $96, $98, $96, $99, $96, $9A, $FF
SonAni_Push:	dc.b  $FD, $B6,	$B7, $B8, $B9, $FF, $FF, $FF, $FF, $FF
SonAni_Wait:	dc.b	5, $BA,	$BA, $BA, $BA, $BA, $BA, $BA, $BA, $BA,	$BA
			dc.b	$BA, $BA, $BA, $BA, $BA, $BA, $BA,	$BA, $BA, $BA
			dc.b	$BA, $BA, $BA, $BA, $BA,	$BA, $BA, $BA, $BA, $BA, $BA
			dc.b  $BA, $BA,	$BA, $BA, $BA, $BA, $BA, $BA, $BA, $BA,	$BA, $BA, $BA
			dc.b	$BA, $BA, $BA, $BA, $BA,	$BA, $BB, $BC, $BD, $BD, $BD, $BE, $BE, $BE, $BE, $BF, $C0, $C0, $BF
			dc.b  $BE, $BE,	$BF, $C0, $C0, $BF, $BE, $BE, $BF, $C0, $C0, $BF, $BE, $BE, $BF, $C0, $C0, $BF, $BE, $BE
			dc.b	$BE, $BE, $C1, $C2, $C3, $C4, $C5, $C6, $C6, $C6, $C6
			dc.b  $C6, $C6, $C6, $C7, $C7, $C7, $C7, $C7, $C7, $C8, $C9, $BA, $BA, $BA, $BA, $BB, $BC, $FE, $35

SonAni_Balance:	dc.b	7, $A4,	$A5, $A6, $FF
SonAni_LookUp:	dc.b	5, $C3,	$C4, $FE,   1
SonAni_Duck:	dc.b	5, $9B,	$9C, $FE,   1
SonAni_Spindash:	dc.b	0, $86,	$87, $86, $88, $86, $89, $86, $8A, $86,	$8B, $FF
SonAni_Blink:	dc.b	9, $BA,	$C5, $C6, $C6, $C6, $C6, $C6, $C6, $C7,	$C7, $C7, $C7, $C7
				dc.b	 $C7, $C7, $C7, $C7,	$C7, $C7, $C7, $FD,   0
SonAni_GetUp:	dc.b   $F, $8F,	$FF
SonAni_Balance2:	dc.b	5, $A1,	$A2, $A3, $FF
SonAni_Stop:	dc.b	3, $9D,	$9E, $9F, $A0, $FD,   0
SonAni_Float:	dc.b	7, $C8,	$FF
SonAni_Float2:	dc.b	7, $C8,	$C9, $CA, $CB, $CC, $CD, $CE, $CF, $FF
SonAni_Spring:	dc.b  $2F, $8E,	$FD,   0
SonAni_Hang:	dc.b	1, $AA,	$AB, $FF
SonAni_Dash2:	dc.b   $F, $43,	$43, $43, $FE,	 1
SonAni_Dash3:	dc.b	7, $B0,	$B2, $B2, $B2, $B2, $B2, $B2, $B1, $B2,	$B3, $B2, $FE,	 4
SonAni_Hang2:	dc.b  $13, $91,	$FF
SonAni_Bubble:	dc.b   $B, $AC,	$AC,   3,   4, $FD,   0
SonAni_DeathBW:	dc.b  $20, $A8,	$FF
SonAni_Drown:	dc.b  $20, $A9,	$FF
SonAni_Death:	dc.b  $20, $A7,	$FF
SonAni_Hurt:	dc.b	9, $D7,	$D8, $FF
SonAni_Slide:	dc.b  $40, $8D,	$FF
SonAni_Blank:	dc.b	9, $8C,	$8D, $FF
SonAni_Balance3:	dc.b  $77,   0,	$FF
SonAni_Balance4:	dc.b  $13, $D0,	$D1, $FF
SonAni_Lying:	dc.b	3, $CF,	$C8, $C9, $CA, $CB, $FE,   4
SonAni_LieDown:	dc.b	9,   8,	  9, $FF ; DATA	XREF: ROM:00012AA6o
SonAni_12C28:	dc.b	3,   7,	$FD,   0 ; DATA	XREF: ROM:00012AA6o
SonAni_12C2C:	dc.b   $B, $90,	$91, $92, $91, $FF ; DATA XREF:	ROM:00012AA6o
SonAni_12C32:	dc.b   $B, $90,	$91, $92, $91, $FD,   0,   0 ; DATA XREF: ROM:00012AA6o
SonAni_Shoot:	dc.b	5, $BA, $FF