; ---------------------------------------------------------------------------
; PATTERN LOAD REQUEST LISTS
;
; Pattern load request lists are simple structures used to load
; Nemesis-compressed art for sprites.
;
; The decompressor predictably moves down the list, so request 0 is processed first, etc.
; This only matters if your addresses are bad and you overwrite art loaded in a previous request.
;
; NOTICE: The load queue buffer can only hold $15 (21) load requests. None of the routines
; that load PLRs into the queue do any bounds checking, so it's possible to create a buffer
; overflow and completely screw up the variables stored directly after the queue buffer.
;
; Of course, this problem is mitigated by the difficulty one will have in finding space
; to load 21 Nemesis-compressed bits of art. It's still something you need to be aware of
; before adding PLRs.
; ---------------------------------------------------------------------------
plrlistheader macro {INTLABEL}
__LABEL__ label *
	dc.w ((__LABEL___End - __LABEL__ - 8) / 6)
    endm

; macro for a pattern load request
plreq macro toVRAMaddr,fromROMaddr
	dc.l	fromROMaddr
	dc.w	toVRAMaddr
    endm
;---------------------------------------------------------------------------------------
; Table of pattern load request lists. Remember to use word-length data when adding lists
; otherwise you'll break the array.
;---------------------------------------------------------------------------------------
; word_42660 ; OffInd_PlrLists:
ArtLoadCues:
PLCptr_Std1:		dc.w PlrList_Std1 - ArtLoadCues	; 0
PLCptr_Std2:		dc.w PlrList_Std2 - ArtLoadCues	; 1
PLCptr_StdWtr:		dc.w PlrList_StdWtr - ArtLoadCues	; 2
PLCptr_GameOver:	dc.w PlrList_GameOver - ArtLoadCues	; 3
PLCptr_Ehz1:		dc.w PlrList_Ehz1 - ArtLoadCues	; 4
PLCptr_Ehz2:		dc.w PlrList_Ehz2 - ArtLoadCues	; 5
PLCptr_Miles1up:	dc.w PLC_6 - ArtLoadCues	; 6
PLCptr_MilesLife:	dc.w PLC_7 - ArtLoadCues	; 7
PLCptr_Tails1up:	dc.w PLC_8 - ArtLoadCues	; 8
PLCptr_TailsLife:	dc.w PLC_9 - ArtLoadCues	; 9
PLCptr_Unused1:		dc.w PlrList_Mtz1 - ArtLoadCues	; 10
PLCptr_Unused2:		dc.w PlrList_Mtz1 - ArtLoadCues	; 11
PLCptr_Mtz1:		dc.w PlrList_Mtz1 - ArtLoadCues	; 12
PLCptr_Mtz2:		dc.w PlrList_Mtz2 - ArtLoadCues	; 13
			dc.w PlrList_Wfz1 - ArtLoadCues	; 14
			dc.w PlrList_Wfz1 - ArtLoadCues	; 15
PLCptr_Wfz1:		dc.w PlrList_Wfz1 - ArtLoadCues	; 16
PLCptr_Wfz2:		dc.w PlrList_Wfz2 - ArtLoadCues	; 17
PLCptr_Htz1:		dc.w PlrList_Htz1 - ArtLoadCues	; 18
PLCptr_Htz2:		dc.w PlrList_Htz2 - ArtLoadCues	; 19
PLCptr_Hpz1:		dc.w PLC_10 - ArtLoadCues	; 20
PLCptr_Hpz2:		dc.w PLC_10 - ArtLoadCues	; 21
PLCptr_Unused3:		dc.w PLC_10 - ArtLoadCues	; 22
PLCptr_Unused4:		dc.w PLC_10 - ArtLoadCues	; 23
PLCptr_Ooz1:		dc.w PLC_10 - ArtLoadCues	; 24
PLCptr_Ooz2:		dc.w PLC_11 - ArtLoadCues	; 25
PLCptr_Mcz1:		dc.w PLC_12 - ArtLoadCues	; 26
PLCptr_Mcz2:		dc.w PLC_13 - ArtLoadCues	; 27
PLCptr_Cnz1:		dc.w PLC_14 - ArtLoadCues	; 28
PLCptr_Cnz2:		dc.w PLC_15 - ArtLoadCues	; 29
PLCptr_Cpz1:		dc.w PLC_16 - ArtLoadCues	; 30
PLCptr_Cpz2:		dc.w PLC_17 - ArtLoadCues	; 31
PLCptr_Dez1:		dc.w PLC_18 - ArtLoadCues	; 32
PLCptr_Dez2:		dc.w PLC_19 - ArtLoadCues	; 33
PLCptr_Arz1:		dc.w PLC_1A - ArtLoadCues	; 34
PLCptr_Arz2:		dc.w PLC_1B - ArtLoadCues	; 35
PLCptr_Scz1:		dc.w PLC_1C - ArtLoadCues	; 36
PLCptr_Scz2:		dc.w PLC_1D - ArtLoadCues	; 37
PLCptr_Results:		dc.w PLC_1E - ArtLoadCues	; 38
PLCptr_Signpost:	dc.w PLC_1F - ArtLoadCues	; 39
PLCptr_CpzBoss:		dc.w PLC_20 - ArtLoadCues	; 40
PLCptr_EhzBoss:		dc.w PLC_21 - ArtLoadCues	; 41
PLCptr_HtzBoss:		dc.w PLC_22 - ArtLoadCues	; 42
PLCptr_ArzBoss:		dc.w PLC_23 - ArtLoadCues	; 43
PLCptr_MczBoss:		dc.w PLC_24 - ArtLoadCues	; 44
PLCptr_CnzBoss:		dc.w PLC_25 - ArtLoadCues	; 45
PLCptr_MtzBoss:		dc.w PLC_26 - ArtLoadCues	; 46
PLCptr_OozBoss:		dc.w PLC_27 - ArtLoadCues	; 47
PLCptr_FieryExplosion:	dc.w PLC_28 - ArtLoadCues	; 48
PLCptr_DezBoss:		dc.w PLC_29 - ArtLoadCues	; 49
PLCptr_EhzAnimals:	dc.w PLC_2A - ArtLoadCues	; 50
PLCptr_MczAnimals:	dc.w PLC_2B - ArtLoadCues	; 51
PLCptr_HtzAnimals:
PLCptr_MtzAnimals:
PLCptr_WfzAnimals:	dc.w PLC_2C - ArtLoadCues	; 52
PLCptr_DezAnimals:	dc.w PLC_2D - ArtLoadCues	; 53
PLCptr_HpzAnimals:	dc.w PLC_2E - ArtLoadCues	; 54
PLCptr_OozAnimals:	dc.w PLC_2F - ArtLoadCues	; 55
PLCptr_SczAnimals:	dc.w PLC_30 - ArtLoadCues	; 56
PLCptr_CnzAnimals:	dc.w PLC_31 - ArtLoadCues	; 57
PLCptr_CpzAnimals:	dc.w PLC_32 - ArtLoadCues	; 58
PLCptr_ArzAnimals:	dc.w PLC_33 - ArtLoadCues	; 59
PLCptr_SpecialStage:	dc.w PLC_34 - ArtLoadCues	; 60
PLCptr_SpecStageBombs:	dc.w PLC_35 - ArtLoadCues	; 61
PLCptr_WfzBoss:		dc.w PLC_36 - ArtLoadCues	; 62
PLCptr_Tornado:		dc.w PLC_37 - ArtLoadCues	; 63
PLCptr_Capsule:		dc.w PLC_38 - ArtLoadCues	; 64
PLCptr_Explosion:	dc.w PLC_39 - ArtLoadCues	; 65
PLCptr_ResultsTails:	dc.w PLC_3A - ArtLoadCues	; 66
			dc.w 0				; unused
			dc.w PLC_44-ArtLoadCues ; Knux end of Act ( ID 44)
			
; ======================================================================
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Standard 1 - loaded for every level
;---------------------------------------------------------------------------------------
PlrList_Std1: plrlistheader
	plreq $D940, ArtNem_HUD
	plreq $D780, ArtNem_Ring
	plreq $9580, ArtNem_Numbers
PlrList_Std1_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Standard 2 - loaded for every level
;---------------------------------------------------------------------------------------
PlrList_Std2: plrlistheader
	plreq $8C00, ArtNem_VrtclSprng		; was: 8B80
	plreq $8E80, ArtNem_HrzntlSprng		; was: 8E00
	plreq $9000, ArtNem_Spikes		; was: 8680
	plreq $9100, ArtNem_HorizSpike		; was: 8580
	plreq $9200, ArtNem_Checkpoint		; was: 8F80
	plreq $B480, ArtNem_Explosion
	plreq $D000, ArtNem_Powerups
	;plreq $97C0, ArtNem_Shield
	;plreq $9BC0, ArtNem_Invincible_stars
PlrList_Std2_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Aquatic level standard
;---------------------------------------------------------------------------------------
PlrList_StdWtr:	plrlistheader
	plreq $BE40, ArtNem_SuperSonic_stars
	plreq $BD00, ArtNem_Bubbles
PlrList_StdWtr_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Game/Time over
;---------------------------------------------------------------------------------------
PlrList_GameOver: plrlistheader
	plreq $9BC0, ArtNem_Game_Over
PlrList_GameOver_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Emerald Hill Zone primary
;---------------------------------------------------------------------------------------
PlrList_Ehz1: plrlistheader
	plreq $7400, ArtNem_PitcherPlant
	plreq $8000, ArtNem_WaterSurface
	plreq $8300, ArtNem_BigBubbles		; was: AB60
	plreq $8800, ArtNem_DignlSprng		; was: 8780
PlrList_Ehz1_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Emerald Hill Zone secondary
;---------------------------------------------------------------------------------------
PlrList_Ehz2: plrlistheader
	plreq $B000, ArtNem_Squirrel
	plreq $B280, ArtNem_Bird
PlrList_Ehz2_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Sonic life icon
;---------------------------------------------------------------------------------------
PLC_6: plrlistheader
	plreq $FA80, ArtNem_Sonic_life_counter
PLC_6_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Tails life icon
;---------------------------------------------------------------------------------------
PLC_7: plrlistheader
	plreq $FA80, ArtNem_TailsLife
PLC_7_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Knuckles life icon
;---------------------------------------------------------------------------------------
PLC_8: plrlistheader
	plreq $FA80, knuxlifeicon
PLC_8_End
;---------------------------------------------------------------------------------------
; Unused PLC
;---------------------------------------------------------------------------------------
PLC_9: plrlistheader
PLC_9_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Metropolis Zone primary
;---------------------------------------------------------------------------------------
PlrList_Mtz1: plrlistheader
PlrList_Mtz1_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Metropolis Zone secondary
;---------------------------------------------------------------------------------------
PlrList_Mtz2: plrlistheader
PlrList_Mtz2_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Wing Fortress Zone primary
;---------------------------------------------------------------------------------------
PlrList_Wfz1: plrlistheader
	plreq $9000, ArtNem_PitcherPlant	; 7A40
	plreq $6E00, ArtNem_GiantBird
	plreq $A000, ArtNem_FieryExplosion
PlrList_Wfz1_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Wing Fortress Zone secondary
;---------------------------------------------------------------------------------------
PlrList_Wfz2: plrlistheader
PlrList_Wfz2_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Hill Top Zone primary
;---------------------------------------------------------------------------------------
PlrList_Htz1: plrlistheader
PlrList_Htz1_End
;---------------------------------------------------------------------------------------
; PATTERN LOAD REQUEST LIST
; Hill Top Zone secondary
;---------------------------------------------------------------------------------------
PlrList_Htz2: plrlistheader
PlrList_Htz2_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; OOZ Primary
;---------------------------------------------------------------------------------------
PLC_10: plrlistheader
PLC_10_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; OOZ Secondary
;---------------------------------------------------------------------------------------
PLC_11: plrlistheader
PLC_11_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; MCZ Primary
;---------------------------------------------------------------------------------------
PLC_12: plrlistheader
PLC_12_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; MCZ Secondary
;---------------------------------------------------------------------------------------
PLC_13: plrlistheader
PLC_13_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CNZ Primary
;---------------------------------------------------------------------------------------
PLC_14: plrlistheader
PLC_14_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CNZ Secondary
;---------------------------------------------------------------------------------------
PLC_15: plrlistheader
PLC_15_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CPZ Primary
;---------------------------------------------------------------------------------------
PLC_16: plrlistheader
PLC_16_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CPZ Secondary
;---------------------------------------------------------------------------------------
PLC_17: plrlistheader
PLC_17_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; DEZ Primary
;---------------------------------------------------------------------------------------
PLC_18: plrlistheader
PLC_18_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; DEZ Secondary
;---------------------------------------------------------------------------------------
PLC_19: plrlistheader
PLC_19_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; ARZ Primary
;---------------------------------------------------------------------------------------
PLC_1A: plrlistheader
PLC_1A_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; ARZ Secondary
;---------------------------------------------------------------------------------------
PLC_1B: plrlistheader
PLC_1B_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; SCZ Primary
;---------------------------------------------------------------------------------------
PLC_1C: plrlistheader
;	plreq $A000, ArtNem_Tornado
PLC_1C_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; SCZ Secondary
;---------------------------------------------------------------------------------------
PLC_1D: plrlistheader
PLC_1D_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Sonic end of level results screen
;---------------------------------------------------------------------------------------
PLC_1E: plrlistheader
	plreq $B000, ArtNem_TitleCard
	plreq $B600, ArtNem_ResultsText
	plreq $BE80, ArtNem_MiniSonic
	plreq $A800, ArtNem_Perfect
PLC_1E_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; End of level signpost
;---------------------------------------------------------------------------------------
PLC_1F: plrlistheader
	plreq $8680, ArtNem_Signpost
PLC_1F_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CPZ Boss
;---------------------------------------------------------------------------------------
PLC_20: plrlistheader
PLC_20_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; EHZ Boss
;---------------------------------------------------------------------------------------
PLC_21: plrlistheader
PLC_21_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; HTZ Boss
;---------------------------------------------------------------------------------------
PLC_22: plrlistheader
PLC_22_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; ARZ Boss
;---------------------------------------------------------------------------------------
PLC_23: plrlistheader
PLC_23_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; MCZ Boss
;---------------------------------------------------------------------------------------
PLC_24: plrlistheader
PLC_24_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CNZ Boss
;---------------------------------------------------------------------------------------
PLC_25: plrlistheader
PLC_25_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; MTZ Boss
;---------------------------------------------------------------------------------------
PLC_26: plrlistheader
PLC_26_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; OOZ Boss
;---------------------------------------------------------------------------------------
PLC_27: plrlistheader
PLC_27_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Fiery Explosion
;---------------------------------------------------------------------------------------
PLC_28: plrlistheader
	plreq $B000, ArtNem_FieryExplosion
PLC_28_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Death Egg
;---------------------------------------------------------------------------------------
PLC_29: plrlistheader
;	plreq $6600, ArtNem_DEZBoss
PLC_29_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; EHZ Animals
;---------------------------------------------------------------------------------------
PLC_2A: plrlistheader
	plreq $B000, ArtNem_Squirrel
	plreq $B280, ArtNem_Bird
PLC_2A_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; MCZ Animals
;---------------------------------------------------------------------------------------
PLC_2B: plrlistheader
	plreq $B000, ArtNem_Mouse
	plreq $B280, ArtNem_Chicken
PLC_2B_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; HTZ/MTZ/WFZ animals
;---------------------------------------------------------------------------------------
PLC_2C: plrlistheader
	plreq $B000, ArtNem_Beaver
	plreq $B280, ArtNem_Eagle
PLC_2C_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; DEZ Animals
;---------------------------------------------------------------------------------------
PLC_2D: plrlistheader
	plreq $B000, ArtNem_Pig
	plreq $B280, ArtNem_Chicken
PLC_2D_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; HPZ animals
;---------------------------------------------------------------------------------------
PLC_2E: plrlistheader
	plreq $B000, ArtNem_Mouse
	plreq $B280, ArtNem_Seal
PLC_2E_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; OOZ Animals
;---------------------------------------------------------------------------------------
PLC_2F: plrlistheader
	plreq $B000, ArtNem_Penguin
	plreq $B280, ArtNem_Seal
PLC_2F_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; SCZ Animals
;---------------------------------------------------------------------------------------
PLC_30: plrlistheader
	plreq $B000, ArtNem_Turtle
	plreq $B280, ArtNem_Chicken
PLC_30_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CNZ Animals
;---------------------------------------------------------------------------------------
PLC_31: plrlistheader
	plreq $B000, ArtNem_Bear
	plreq $B280, ArtNem_Bird
PLC_31_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; CPZ Animals
;---------------------------------------------------------------------------------------
PLC_32: plrlistheader
	plreq $B000, ArtNem_Rabbit
	plreq $B280, ArtNem_Eagle
PLC_32_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; ARZ Animals
;---------------------------------------------------------------------------------------
PLC_33: plrlistheader
	plreq $B000, ArtNem_Penguin
	plreq $B280, ArtNem_Bird
PLC_33_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Special Stage
;---------------------------------------------------------------------------------------
PLC_34: plrlistheader
PLC_34_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Special Stage Bombs
;---------------------------------------------------------------------------------------
PLC_35: plrlistheader
PLC_35_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; WFZ Boss
;---------------------------------------------------------------------------------------
PLC_36: plrlistheader
PLC_36_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Tornado
;---------------------------------------------------------------------------------------
PLC_37: plrlistheader
PLC_37_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Egg Prison
;---------------------------------------------------------------------------------------
PLC_38: plrlistheader
	plreq $D000, ArtNem_Capsule
PLC_38_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Normal explosion
;---------------------------------------------------------------------------------------
PLC_39: plrlistheader
	plreq $B480, ArtNem_Explosion
PLC_39_End
;---------------------------------------------------------------------------------------
; Pattern load queue
; Tails end of level results screen
;---------------------------------------------------------------------------------------
PLC_3A: plrlistheader
	plreq $B000, ArtNem_TitleCard
	plreq $B600, ArtNem_ResultsText
	plreq $BE80, ArtNem_MiniTails
	plreq $A800, ArtNem_Perfect
PLC_3A_End
;---------------------------------------------------------------------------------------
;Pattern load cue
;
;Knux end of level results screen (44)
;---------------------------------------------------------------------------------------
PLC_44:        dc.w 2; DATA XREF: ROM:00042660o
        dc.l ArtNem_TitleCard
        dc.w $B000
        dc.l Knuxeoatext; Use whatever label you gave it.
        dc.w $B600
        dc.l ArtNem_Perfect
        dc.w $A800			