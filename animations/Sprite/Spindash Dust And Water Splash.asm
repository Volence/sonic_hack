	dc.w Water_Splash_ObjectAni_Null - Ani_Water_Splash_Object	; 0
	dc.w Water_Splash_ObjectAni_Splash - Ani_Water_Splash_Object	; 1
	dc.w Water_Splash_ObjectAni_Dash - Ani_Water_Splash_Object	; 2
	dc.w Water_Splash_ObjectAni_Skid - Ani_Water_Splash_Object	; 3
Water_Splash_ObjectAni_Null:	dc.b $1F,  0,$FF
Water_Splash_ObjectAni_Splash:dc.b   3,  1,  2,  3,  4,  5,  6,  7,  8,  9,$FD,  0
Water_Splash_ObjectAni_Dash:	dc.b   1, $A, $B, $C, $D, $E, $F,$10,$FF
Water_Splash_ObjectAni_Skid:	dc.b   3,$11,$12,$13,$14,$FC