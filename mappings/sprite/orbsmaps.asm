; --------------------------------------------------------------------------------
; Sprite mappings - output from SonMapEd - Sonic 2 format
; --------------------------------------------------------------------------------

SME_EZvxz:	
		dc.w SME_EZvxz_8-SME_EZvxz, SME_EZvxz_12-SME_EZvxz	
		dc.w SME_EZvxz_1C-SME_EZvxz, SME_EZvxz_26-SME_EZvxz	
SME_EZvxz_8:	dc.b 0, 1	
		dc.b $FC, 0, 0, 0, 0, 0, $FF, $FC	
SME_EZvxz_12:	dc.b 0, 1	
		dc.b $F8, 5, 0, 1, 0, 0, $FF, $F8	
SME_EZvxz_1C:	dc.b 0, 1	
		dc.b $F0, $F, 0, 5, 0, 2, $FF, $F0	
SME_EZvxz_26:	dc.b 0, 4	
		dc.b $E0, $F, 0, $15, 0, $A, $FF, $E0	
		dc.b 0, $F, 0, $25, 0, $12, $FF, $E0	
		dc.b $E0, $F, 0, $35, 0, $1A, 0, 0	
		dc.b 0, $F, 0, $45, 0, $22, 0, 0	
		even