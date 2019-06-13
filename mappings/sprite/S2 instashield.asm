; --------------------------------------------------------------------------------
; Sprite mappings - output from SonMapEd - Sonic 2 format
; --------------------------------------------------------------------------------

SME_MCFnX:	
		dc.w SME_MCFnX_10-SME_MCFnX, SME_MCFnX_2A-SME_MCFnX	
		dc.w SME_MCFnX_44-SME_MCFnX, SME_MCFnX_56-SME_MCFnX	
		dc.w SME_MCFnX_70-SME_MCFnX, SME_MCFnX_8A-SME_MCFnX	
		dc.w SME_MCFnX_A4-SME_MCFnX, SME_MCFnX_A6-SME_MCFnX	
SME_MCFnX_10:	dc.b 0, 3	
		dc.b $E8, 8, 0, 0, 0, 0, $FF, $F0	
		dc.b $F0, 4, 0, $10, 0, 8, $FF, $F8	
		dc.b $F8, 0, 0, 5, 0, 2, 0, 0	
SME_MCFnX_2A:	dc.b 0, 3	
		dc.b $F0, 4, 0, 0, 0, 0, 0, 8	
		dc.b $F8, 8, 0, $10, 0, 8, 0, 0	
		dc.b 0, 4, 0, $B, 0, 5, 0, 0	
SME_MCFnX_44:	dc.b 0, 2	
		dc.b 0, 9, 0, 0, 0, 0, 0, 0	
		dc.b $10, $C, 0, $10, 0, 8, $FF, $F8	
SME_MCFnX_56:	dc.b 0, 3	
		dc.b $F0, $C, 0, 0, 0, 0, $FF, $E8	
		dc.b $F8, 8, 0, 4, 0, 2, $FF, $E8	
		dc.b 0, 6, 0, 7, 0, 3, $FF, $E8	
SME_MCFnX_70:	dc.b 0, 3	
		dc.b $E8, 4, 0, $D, 0, 6, $FF, $F0	
		dc.b $E8, $B, 0, $F, 0, 7, 0, 0	
		dc.b 8, 4, 0, $1B, 0, $D, 0, 8	
SME_MCFnX_8A:	dc.b 0, 3	
		dc.b $F0, 4, $18, $1B, $18, $D, $FF, $E8	
		dc.b $F8, $B, $18, $F, $18, 7, $FF, $E8	
		dc.b $10, 4, $18, $D, $18, 6, 0, 0	
SME_MCFnX_A4:	dc.b 0, 0	
SME_MCFnX_A6:	dc.b 0, 0	
		even