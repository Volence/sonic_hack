; ---------------------------------------------------------------------------
; Subroutine to draw the HUD
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_40804:
BuildHUD:
	tst.w	(Ring_count).w
	beq.s	++	; blink ring count if it's 0
	moveq	#0,d1
	btst	#3,(Timer_frames+1).w
	bne.s	+	; only blink on certain frames
	cmpi.b	#9,(Timer_minute).w	; should the minutes counter blink?
	bne.s	+	; if not, branch
	addq.w	#2,d1	; set mapping frame time counter blink
+
	bra.s	++
+
	moveq	#0,d1
	btst	#3,(Timer_frames+1).w
	bne.s	+	; only blink on certain frames
	addq.w	#1,d1	; set mapping frame for ring count blink
	cmpi.b	#9,(Timer_minute).w
	bne.s	+
	addq.w	#2,d1	; set mapping frame for double blink
+
	move.w	#128+16,d3	; set X pos
	move.w	#128+136,d2	; set Y pos
	lea	(HUD_MapUnc_40A9A).l,a1
	movea.w	#$86CA,a3	; set art tile and flags
	add.w	d1,d1
	adda.w	(a1,d1.w),a1
	move.w	(a1)+,d1
	subq.w	#1,d1
	bmi.s	+
	jsr	JmpTo_DrawSprite_Loop	; draw frame
+
	rts
; End of function BuildHUD

; ===========================================================================

; sprite mappings for the HUD
; uses the art in VRAM from $D940 - $FC00
HUD_MapUnc_40A9A:	BINCLUDE "mappings/sprite/hud_a.bin"


HUD_MapUnc_40BEA:	BINCLUDE "mappings/sprite/hud_b.bin"


HUD_MapUnc_40C82:	BINCLUDE "mappings/sprite/hud_c.bin"

; ---------------------------------------------------------------------------
; Add points subroutine
; subroutine to add to Player 1's score
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_40D06:
AddPoints:

	move.b	#1,(Update_HUD_score).w
	lea	(Score).w,a3
	add.l	d0,(a3)	; add d0*10 to the score
	move.l	#999999,d1
	cmp.l	(a3),d1	; is #999999 higher than the score?
	bhi.s	+	; if yes, branch
	move.l	d1,(a3)	; set score to #999999
+
	move.l	(a3),d0
	cmp.l	(Next_Extra_life_score).w,d0
	blo.s	return_40D40
	addi.l	#5000,(Next_Extra_life_score).w
	addq.b	#1,(Life_count).w
	addq.b	#1,(Update_HUD_lives).w
	move.w	#MusID_ExtraLife,d0
	jmp	(PlayMusic).l
; ===========================================================================

return_40D40:
	rts
; End of function AddPoints

; ---------------------------------------------------------------------------
; Subroutine to update the HUD
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_40D8A:
HudUpdate:
	nop
	lea	(VDP_data_port).l,a6
	tst.w	(Two_player_mode).w
	bne.w	loc_40F50
	tst.w	(Debug_mode_flag).w	; is debug mode on?
	bne.w	loc_40E9A	; if yes, branch
	tst.b	(Update_HUD_score).w	; does the score need updating?
	beq.s	Hud_ChkRings	; if not, branch
	clr.b	(Update_HUD_score).w
	move.l	#$5C800003,d0	; set VRAM address
	move.l	(Score).w,d1	; load score
	bsr.w	Hud_Score
; loc_40DBA:
Hud_ChkRings:
	tst.b	(Update_HUD_rings).w	; does the ring counter need updating?
	beq.s	Hud_ChkTime	; if not, branch
	bpl.s	loc_40DC6
	bsr.w	Hud_LoadZero

loc_40DC6:
	clr.b	(Update_HUD_rings).w
	move.l	#$5F400003,d0
	moveq	#0,d1
	move.w	(Ring_count).w,d1
	bsr.w	Hud_Rings
; loc_40DDA:
Hud_ChkTime:
	tst.b	(Update_HUD_timer).w	; does the time need updating?
	beq.s	Hud_ChkLives	; if not, branch
	tst.w	(Game_paused).w	; is the game paused?
	bne.s	Hud_ChkLives	; if yes, branch
	lea	(Timer).w,a1
	cmpi.l	#$93B3B,(a1)+	; is the time 9.59?
	beq.w	loc_40E84	; if yes, branch
	addq.b	#1,-(a1)
	cmpi.b	#60,(a1)
	blo.s	Hud_ChkLives
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#60,(a1)
	blo.s	loc_40E18
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#9,(a1)
	blo.s	loc_40E18
	move.b	#9,(a1)

loc_40E18:

	move.l	#$5E400003,d0
	moveq	#0,d1
	move.b	(Timer_minute).w,d1
	bsr.w	Hud_Mins
	move.l	#$5EC00003,d0
	moveq	#0,d1
	move.b	(Timer_second).w,d1
	bsr.w	Hud_Secs
; loc_40E38:
Hud_ChkLives:

	tst.b	(Update_HUD_lives).w	; does the lives counter need updating?
	beq.s	Hud_ChkBonus	; if not, branch
	clr.b	(Update_HUD_lives).w
	bsr.w	Hud_Lives
; loc_40E46:
Hud_ChkBonus:
	tst.b	(Update_Bonus_score).w	; do time/ring bonus counters need updating?
	beq.s	Hud_End	; if not, branch
	clr.b	(Update_Bonus_score).w
	move.l	#vdpComm($A400,VRAM,WRITE),(VDP_control_port).l
	moveq	#0,d1
	move.w	($FFFFFF8E).w,d1
	bsr.w	Hud_TimeRingBonus
	moveq	#0,d1
	move.w	(Bonus_Countdown_1).w,d1	 ; load time bonus
	bsr.w	Hud_TimeRingBonus
	moveq	#0,d1
	move.w	(Bonus_Countdown_2).w,d1	 ; load ring bonus
	bsr.w	Hud_TimeRingBonus
	moveq	#0,d1
	move.w	($FFFFFF92).w,d1
	bsr.w	Hud_TimeRingBonus
; return_40E82:
Hud_End:
	rts
; ===========================================================================

loc_40E84:
	clr.b	(Update_HUD_timer).w
	lea	(MainCharacter).w,a0 ; a0=character
	movea.l	a0,a2
	jsr	KillCharacter
	move.b	#1,(Time_Over_flag).w
	rts
; ===========================================================================

loc_40E9A:
	bsr.w	HudDb_XY
	tst.b	(Update_HUD_rings).w
	beq.s	loc_40EBE
	bpl.s	loc_40EAA
	bsr.w	Hud_LoadZero

loc_40EAA:
	clr.b	(Update_HUD_rings).w
	move.l	#$5F400003,d0
	moveq	#0,d1
	move.w	(Ring_count).w,d1
	bsr.w	Hud_Rings

loc_40EBE:
	move.l	#$5EC00003,d0
	moveq	#0,d1
	move.b	(Sprite_count).w,d1
	bsr.w	Hud_Secs
	tst.b	(Update_HUD_lives).w
	beq.s	loc_40EDC
	clr.b	(Update_HUD_lives).w
	bsr.w	Hud_Lives

loc_40EDC:
	tst.b	(Update_Bonus_score).w
	beq.s	loc_40F18
	clr.b	(Update_Bonus_score).w
	move.l	#vdpComm($A400,VRAM,WRITE),(VDP_control_port).l
	moveq	#0,d1
	move.w	($FFFFFF8E).w,d1
	bsr.w	Hud_TimeRingBonus
	moveq	#0,d1
	move.w	(Bonus_Countdown_1).w,d1
	bsr.w	Hud_TimeRingBonus
	moveq	#0,d1
	move.w	(Bonus_Countdown_2).w,d1
	bsr.w	Hud_TimeRingBonus
	moveq	#0,d1
	move.w	($FFFFFF92).w,d1
	bsr.w	Hud_TimeRingBonus

loc_40F18:
	tst.w	(Game_paused).w
	bne.s	return_40F4E
	lea	(Timer).w,a1
	cmpi.l	#$93B3B,(a1)+
	nop
	addq.b	#1,-(a1)
	cmpi.b	#$3C,(a1)
	blo.s	return_40F4E
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#$3C,(a1)
	blo.s	return_40F4E
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#9,(a1)
	blo.s	return_40F4E
	move.b	#9,(a1)

return_40F4E:
	rts
; ===========================================================================

loc_40F50:
	tst.w	(Game_paused).w
	bne.w	return_4101A
	tst.b	(Update_HUD_timer).w
	beq.s	loc_40F90
	lea	(Timer).w,a1
	cmpi.l	#$93B3B,(a1)+
	beq.w	TimeOver
	addq.b	#1,-(a1)
	cmpi.b	#$3C,(a1)
	blo.s	loc_40F90
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#$3C,(a1)
	blo.s	loc_40F90
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#9,(a1)
	blo.s	loc_40F90
	move.b	#9,(a1)

loc_40F90:
	tst.b	(Update_HUD_timer_2P).w
	beq.s	loc_40FC8
	lea	(Timer_2P).w,a1
	cmpi.l	#$93B3B,(a1)+
	beq.w	TimeOver2
	addq.b	#1,-(a1)
	cmpi.b	#$3C,(a1)
	blo.s	loc_40FC8
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#$3C,(a1)
	blo.s	loc_40FC8
	move.b	#0,(a1)
	addq.b	#1,-(a1)
	cmpi.b	#9,(a1)
	blo.s	loc_40FC8
	move.b	#9,(a1)

loc_40FC8:
	tst.b	(Update_HUD_lives).w
	beq.s	loc_40FD6
	clr.b	(Update_HUD_lives).w
	bsr.w	Hud_Lives

loc_40FD6:
	tst.b	(Update_HUD_lives_2P).w
	beq.s	loc_40FE4
	clr.b	(Update_HUD_lives_2P).w
	bsr.w	Hud_Lives2

loc_40FE4:
	move.b	(Update_HUD_timer).w,d0
	or.b	(Update_HUD_timer_2P).w,d0
	beq.s	return_4101A
	lea	(Loser_Time_Left).w,a1
	tst.w	(a1)+
	beq.s	return_4101A
	subq.b	#1,-(a1)
	bhi.s	return_4101A
	move.b	#$3C,(a1)
	cmpi.b	#$C,-1(a1)
	bne.s	loc_41010
	move.w	#MusID_Countdown,d0
	jsr	(PlayMusic).l

loc_41010:
	subq.b	#1,-(a1)
	bcc.s	return_4101A
	move.w	#0,(a1)
	bsr.s	TimeOver0

return_4101A:

	rts
; End of function HudUpdate


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4101C:
TimeOver0:
	tst.b	(Update_HUD_timer).w
	bne.s	TimeOver
	tst.b	(Update_HUD_timer_2P).w
	bne.s	TimeOver2
	rts
; ===========================================================================
; loc_4102A:
TimeOver:

	clr.b	(Update_HUD_timer).w
	lea	(MainCharacter).w,a0 ; a0=character
	movea.l	a0,a2
	jsr	KillCharacter
	move.b	#1,(Time_Over_flag).w
	tst.b	(Update_HUD_timer_2P).w
	beq.s	return_41058
; loc_41044:
TimeOver2:

	clr.b	(Update_HUD_timer_2P).w
	lea	(Sidekick).w,a0 ; a0=character
	movea.l	a0,a2
	jsr	KillCharacter
	move.b	#1,(Time_Over_flag_2P).w

return_41058:
	rts
; End of function TimeOver0


; ---------------------------------------------------------------------------
; Subroutine to load "0" on the HUD
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4105A:
Hud_LoadZero:

	move.l	#vdpComm($DF40,VRAM,WRITE),(VDP_control_port).l
	lea	Hud_TilesZero(pc),a2
	move.w	#2,d2
	bra.s	loc_41090

; ---------------------------------------------------------------------------
; Subroutine to load uncompressed HUD patterns ("E", "0", colon)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; loc_4106E:
Hud_Base:
	lea	(VDP_data_port).l,a6
	bsr.w	Hud_Lives
	tst.w	(Two_player_mode).w
	bne.s	loc_410BC
	move.l	#vdpComm($DC40,VRAM,WRITE),(VDP_control_port).l
	lea	Hud_TilesBase(pc),a2
	move.w	#$E,d2

loc_41090:
	lea	Art_Hud(pc),a1

loc_41094:
	move.w	#$F,d1
	move.b	(a2)+,d0
	bmi.s	loc_410B0
	ext.w	d0
	lsl.w	#5,d0
	lea	(a1,d0.w),a3

loc_410A4:
	move.l	(a3)+,(a6)
	dbf	d1,loc_410A4

loc_410AA:
	dbf	d2,loc_41094
	rts
; ===========================================================================

loc_410B0:
	move.l	#0,(a6)
	dbf	d1,loc_410B0
	bra.s	loc_410AA
; End of function Hud_LoadZero

; ===========================================================================

loc_410BC:
	bsr.w	Hud_Lives2
	move.l	#Art_Hud,d1 ; source addreses
	move.w	#$DC40,d2 ; destination VRAM address
	move.w	#$160,d3 ; DMA transfer length
	jmp	(QueueDMATransfer).l
; ===========================================================================
Hud_TilesBase:
	dc.b $16, $FF, $FF, $FF, $FF, $FF, $FF,	0, 0, $14, 0, 0 ; byte_410D4:
Hud_TilesZero:
	dc.b $FF, $FF, 0, 0 ; byte_410E0:
; ---------------------------------------------------------------------------
; Subroutine to load debug mode numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_410E4:
HudDb_XY:
	move.l	#vdpComm($DC40,VRAM,WRITE),(VDP_control_port).l
	move.w	(Camera_X_pos).w,d1
	swap	d1
	move.w	(MainCharacter+x_pos).w,d1
	bsr.s	HudDb_XY2
	move.w	(Camera_Y_pos).w,d1
	swap	d1
	move.w	(MainCharacter+y_pos).w,d1
; loc_41104:
HudDb_XY2:
	moveq	#7,d6
	lea	(Art_Text).l,a1
; loc_4110C:
HudDb_XYLoop:
	rol.w	#4,d1
	move.w	d1,d2
	andi.w	#$F,d2
	cmpi.w	#$A,d2
	blo.s	loc_4111E
	addi.w	#7,d2

loc_4111E:
	lsl.w	#5,d2
	lea	(a1,d2.w),a3
    rept 8
	move.l	(a3)+,(a6)
    endm
	swap	d1
	dbf	d6,HudDb_XYLoop
	rts
; End of function HudDb_XY

; ---------------------------------------------------------------------------
; Subroutine to load rings numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_4113C:
Hud_Rings:
	lea	(Hud_100).l,a2
	moveq	#2,d6
	bra.s	Hud_LoadArt
; End of function Hud_Rings

; ---------------------------------------------------------------------------
; Subroutine to load score numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_41146:
Hud_Score:
	lea	(Hud_100000).l,a2
	moveq	#5,d6
; loc_4114E:
Hud_LoadArt:
	moveq	#0,d4
	lea	Art_Hud(pc),a1
; loc_41154:
Hud_ScoreLoop:
	moveq	#0,d2
	move.l	(a2)+,d3

loc_41158:
	sub.l	d3,d1
	bcs.s	loc_41160
	addq.w	#1,d2
	bra.s	loc_41158
; ===========================================================================

loc_41160:
	add.l	d3,d1
	tst.w	d2
	beq.s	loc_4116A
	move.w	#1,d4

loc_4116A:
	tst.w	d4
	beq.s	loc_41198
	lsl.w	#6,d2
	move.l	d0,4(a6)
	lea	(a1,d2.w),a3
    rept 16
	move.l	(a3)+,(a6)
    endm

loc_41198:
	addi.l	#$400000,d0
	dbf	d6,Hud_ScoreLoop
	rts
; End of function Hud_Score

; ---------------------------------------------------------------------------
; Subroutine to load countdown numbers on the continue screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_411A4:
ContScrCounter:
	move.l	#vdpComm($DF80,VRAM,WRITE),(VDP_control_port).l
	lea	(VDP_data_port).l,a6
	lea	(Hud_10).l,a2
	moveq	#1,d6
	moveq	#0,d4
	lea	Art_Hud(pc),a1
; loc_411C2:
ContScr_Loop:
	moveq	#0,d2
	move.l	(a2)+,d3

loc_411C6:
	sub.l	d3,d1
	bcs.s	loc_411CE
	addq.w	#1,d2
	bra.s	loc_411C6
; ===========================================================================

loc_411CE:
	add.l	d3,d1
	lsl.w	#6,d2
	lea	(a1,d2.w),a3
    rept 16
	move.l	(a3)+,(a6)
    endm
	dbf	d6,ContScr_Loop	; repeat 1 more time
	rts
; End of function ContScrCounter

; ===========================================================================
; ---------------------------------------------------------------------------
; for HUD counter
; ---------------------------------------------------------------------------
				; byte_411FC:
Hud_100000:	dc.l 100000	; byte_41200: ; Hud_10000:
		dc.l 10000	; byte_41204:
Hud_1000:	dc.l 1000	; byte_41208:
Hud_100:	dc.l 100	; byte_4120C:
Hud_10:		dc.l 10		; byte_41210:
Hud_1:		dc.l 1

; ---------------------------------------------------------------------------
; Subroutine to load time numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_41214:
Hud_Mins:
	lea	Hud_1(pc),a2
	moveq	#0,d6
	bra.s	loc_41222
; ===========================================================================
; loc_4121C:
Hud_Secs:
	lea	Hud_10(pc),a2
	moveq	#1,d6

loc_41222:
	moveq	#0,d4
	lea	Art_Hud(pc),a1
; loc_41228:
Hud_TimeLoop:
	moveq	#0,d2
	move.l	(a2)+,d3

loc_4122C:
	sub.l	d3,d1
	bcs.s	loc_41234
	addq.w	#1,d2
	bra.s	loc_4122C
; ===========================================================================

loc_41234:
	add.l	d3,d1
	tst.w	d2
	beq.s	loc_4123E
	move.w	#1,d4

loc_4123E:
	lsl.w	#6,d2
	move.l	d0,4(a6)
	lea	(a1,d2.w),a3
    rept 16
	move.l	(a3)+,(a6)
    endm
	addi.l	#$400000,d0
	dbf	d6,Hud_TimeLoop
	rts
; End of function Hud_Mins

; ---------------------------------------------------------------------------
; Subroutine to load time/ring bonus numbers patterns
; ---------------------------------------------------------------------------

; ===========================================================================
; loc_41274:
Hud_TimeRingBonus:
	lea	Hud_1000(pc),a2
	moveq	#3,d6
	moveq	#0,d4
	lea	Art_Hud(pc),a1
; loc_41280:
Hud_BonusLoop:
	moveq	#0,d2
	move.l	(a2)+,d3

loc_41284:
	sub.l	d3,d1
	bcs.s	loc_4128C
	addq.w	#1,d2
	bra.s	loc_41284
; ===========================================================================

loc_4128C:
	add.l	d3,d1
	tst.w	d2
	beq.s	loc_41296
	move.w	#1,d4

loc_41296:
	tst.w	d4
	beq.s	Hud_ClrBonus
	lsl.w	#6,d2
	lea	(a1,d2.w),a3
    rept 16
	move.l	(a3)+,(a6)
    endm

loc_412C0:
	dbf	d6,Hud_BonusLoop ; repeat 3 more times
	rts
; ===========================================================================
; loc_412C6:
Hud_ClrBonus:
	moveq	#$F,d5
; loc_412C8:
Hud_ClrBonusLoop:
	move.l	#0,(a6)
	dbf	d5,Hud_ClrBonusLoop
	bra.s	loc_412C0

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; ---------------------------------------------------------------------------
; Subroutine to load uncompressed lives counter patterns (Sonic)
; ---------------------------------------------------------------------------

; sub_412D4:
Hud_Lives2:
	move.l	#$5FA00003,d0
	moveq	#0,d1
	move.b	(Life_count_2P).w,d1
	bra.s	loc_412EE
; End of function Hud_Lives2

; ---------------------------------------------------------------------------
; Subroutine to load uncompressed lives counter patterns (Tails)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

; sub_412E2:
Hud_Lives:
	move.l	#$7BA00003,d0
	moveq	#0,d1
	move.b	(Life_count).w,d1

loc_412EE:
	lea	Hud_10(pc),a2
	moveq	#1,d6
	moveq	#0,d4
	lea	Art_LivesNums(pc),a1
; loc_412FA:
Hud_LivesLoop:
	move.l	d0,4(a6)
	moveq	#0,d2
	move.l	(a2)+,d3
-	sub.l	d3,d1
	bcs.s	loc_4130A
	addq.w	#1,d2
	bra.s	-
; ===========================================================================

loc_4130A:
	add.l	d3,d1
	tst.w	d2
	beq.s	loc_41314
	move.w	#1,d4

loc_41314:
	tst.w	d4
	beq.s	Hud_ClrLives

loc_41318:
	lsl.w	#5,d2
	lea	(a1,d2.w),a3
    rept 8
	move.l	(a3)+,(a6)
    endm

loc_4132E:
	addi.l	#$400000,d0
	dbf	d6,Hud_LivesLoop ; repeat 1 more time
	rts
; ===========================================================================
; loc_4133A:
Hud_ClrLives:
	tst.w	d6
	beq.s	loc_41318
	moveq	#7,d5
; loc_41340:
Hud_ClrLivesLoop:
	move.l	#0,(a6)
	dbf	d5,Hud_ClrLivesLoop
	bra.s	loc_4132E
; End of function Hud_Lives


; ===========================================================================
; ArtUnc_4134C:
Art_Hud:	BINCLUDE	"art/uncompressed/Big and small numbers used on counters - 1.bin"
; ArtUnc_4164C:
Art_LivesNums:	BINCLUDE	"art/uncompressed/Big and small numbers used on counters - 2.bin"
; ArtUnc_4178C:
Art_Text:	BINCLUDE	"art/uncompressed/Big and small numbers used on counters - 3.bin"