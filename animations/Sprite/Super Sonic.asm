	dc.w SupSonAni_Walk - SuperSonicAniData		; 0
	dc.w SupSonAni_Run - SuperSonicAniData          ; 1
	dc.w SonAni_Roll - SuperSonicAniData            ; 2
	dc.w SonAni_Roll2 - SuperSonicAniData           ; 3
	dc.w SupSonAni_Push - SuperSonicAniData         ; 4
	dc.w SupSonAni_Stand - SuperSonicAniData        ; 5
	dc.w SupSonAni_Balance - SuperSonicAniData      ; 6
	dc.w SonAni_LookUp - SuperSonicAniData          ; 7
	dc.w SupSonAni_Duck - SuperSonicAniData         ; 8
	dc.w SonAni_Spindash - SuperSonicAniData        ; 9
	dc.w SonAni_Blink - SuperSonicAniData           ; 10 ; $A
	dc.w SonAni_GetUp - SuperSonicAniData           ; 11 ; $B
	dc.w SonAni_Balance2 - SuperSonicAniData        ; 12 ; $C
	dc.w SonAni_Stop - SuperSonicAniData            ; 13 ; $D
	dc.w SonAni_Float - SuperSonicAniData           ; 14 ; $E
	dc.w SonAni_Float2 - SuperSonicAniData          ; 15 ; $F
	dc.w SonAni_Spring - SuperSonicAniData          ; 16 ; $10
	dc.w SonAni_Hang - SuperSonicAniData            ; 17 ; $11
	dc.w SonAni_Dash2 - SuperSonicAniData           ; 18 ; $12
	dc.w SonAni_Dash3 - SuperSonicAniData           ; 19 ; $13
	dc.w SonAni_Hang2 - SuperSonicAniData           ; 20 ; $14
	dc.w SonAni_Bubble - SuperSonicAniData          ; 21 ; $15
	dc.w SonAni_DeathBW - SuperSonicAniData         ; 22 ; $16
	dc.w SonAni_Drown - SuperSonicAniData           ; 23 ; $17
	dc.w SonAni_Death - SuperSonicAniData           ; 24 ; $18
	dc.w SonAni_Hurt - SuperSonicAniData            ; 25 ; $19
	dc.w SonAni_Hurt - SuperSonicAniData            ; 26 ; $1A
	dc.w SonAni_Slide - SuperSonicAniData           ; 27 ; $1B
	dc.w SonAni_Blank - SuperSonicAniData           ; 28 ; $1C
	dc.w SonAni_Balance3 - SuperSonicAniData        ; 29 ; $1D
	dc.w SonAni_Balance4 - SuperSonicAniData        ; 30 ; $1E
	dc.w SupSonAni_Transform - SuperSonicAniData    ; 31 ; $1F

SupSonAni_Walk:		dc.b $FF,$77,$78,$79,$7A,$7B,$7C,$75,$76,$FF
SupSonAni_Run:		dc.b $FF,$B5,$B9,$FF,$FF,$FF,$FF,$FF,$FF,$FF
SupSonAni_Push:		dc.b $FD,$BD,$BE,$BF,$C0,$FF,$FF,$FF,$FF,$FF
SupSonAni_Stand:	dc.b   7,$72,$73,$74,$73,$FF
SupSonAni_Balance:	dc.b   9,$C2,$C3,$C4,$C3,$C5,$C6,$C7,$C6,$FF
SupSonAni_Duck:		dc.b   5,$C1,$FF
SupSonAni_Transform:	dc.b   2,$6D,$6D,$6E,$6E,$6F,$70,$71,$70,$71,$70,$71,$70,$71,$FD,  0