;--------------------------------------------------------------------------------------
; Offset index of ring locations
;  The first commented number on each line is an array index; the second is the
;  associated zone.
;--------------------------------------------------------------------------------------
Off_Rings: zoneOffsetTable 2,2
	zoneTableEntry.w  Rings_EHZ_1 - Off_Rings	; 0  $00
	zoneTableEntry.w  Rings_EHZ_2 - Off_Rings	; 1
	zoneTableEntry.w  Rings_WFZ_1 - Off_Rings	; 2 $01
	zoneTableEntry.w  Rings_WFZ_2 - Off_Rings	; 3
	zoneTableEntry.w  Rings_Lev2_1 - Off_Rings	; 4  $02
	zoneTableEntry.w  Rings_Lev2_2 - Off_Rings	; 5
	zoneTableEntry.w  Rings_Lev3_1 - Off_Rings	; 6  $03
	zoneTableEntry.w  Rings_Lev3_2 - Off_Rings	; 7
	zoneTableEntry.w  Rings_MTZ_1 - Off_Rings	; 8  $04
	zoneTableEntry.w  Rings_MTZ_2 - Off_Rings	; 9
	zoneTableEntry.w  Rings_MTZ_3 - Off_Rings	; 10 $05
	zoneTableEntry.w  Rings_MTZ_4 - Off_Rings	; 11
	zoneTableEntry.w  Rings_WFZ_1 - Off_Rings	; 12 $06
	zoneTableEntry.w  Rings_WFZ_2 - Off_Rings	; 13
	zoneTableEntry.w  Rings_HTZ_1 - Off_Rings	; 14 $07
	zoneTableEntry.w  Rings_HTZ_2 - Off_Rings	; 15
	zoneTableEntry.w  Rings_HPZ_1 - Off_Rings	; 16 $08
	zoneTableEntry.w  Rings_HPZ_2 - Off_Rings	; 17
	zoneTableEntry.w  Rings_Lev9_1 - Off_Rings	; 18 $09
	zoneTableEntry.w  Rings_Lev9_2 - Off_Rings	; 19
	zoneTableEntry.w  Rings_OOZ_1 - Off_Rings	; 20 $0A
	zoneTableEntry.w  Rings_OOZ_2 - Off_Rings	; 21
	zoneTableEntry.w  Rings_MCZ_1 - Off_Rings	; 22 $0B
	zoneTableEntry.w  Rings_MCZ_2 - Off_Rings	; 23
	zoneTableEntry.w  Rings_CNZ_1 - Off_Rings	; 24 $0C
	zoneTableEntry.w  Rings_CNZ_2 - Off_Rings	; 25
	zoneTableEntry.w  Rings_CPZ_1 - Off_Rings	; 26 $0D
	zoneTableEntry.w  Rings_CPZ_2 - Off_Rings	; 27
	zoneTableEntry.w  Rings_DEZ_1 - Off_Rings	; 28 $0E
	zoneTableEntry.w  Rings_DEZ_2 - Off_Rings	; 29
	zoneTableEntry.w  Rings_ARZ_1 - Off_Rings	; 30 $0F
	zoneTableEntry.w  Rings_ARZ_2 - Off_Rings	; 31
	zoneTableEntry.w  Rings_SCZ_1 - Off_Rings	; 32 $10
	zoneTableEntry.w  Rings_SCZ_2 - Off_Rings	; 33
    zoneTableEnd

Rings_EHZ_1:	BINCLUDE	"level/rings/EHZ_1_INDIVIDUAL.bin"
Rings_EHZ_2:	BINCLUDE	"level/rings/EHZ_2_INDIVIDUAL.bin"
Rings_Lev1_1:	BINCLUDE	"level/rings/01_1_INDIVIDUAL.bin"
Rings_Lev1_2:	BINCLUDE	"level/rings/01_2_INDIVIDUAL.bin"
Rings_Lev2_1:	BINCLUDE	"level/rings/02_1_INDIVIDUAL.bin"
Rings_Lev2_2:	BINCLUDE	"level/rings/02_2_INDIVIDUAL.bin"
Rings_Lev3_1:	BINCLUDE	"level/rings/03_1_INDIVIDUAL.bin"
Rings_Lev3_2:	BINCLUDE	"level/rings/03_2_INDIVIDUAL.bin"
Rings_MTZ_1:	BINCLUDE	"level/rings/MTZ_1_INDIVIDUAL.bin"
Rings_MTZ_2:	BINCLUDE	"level/rings/MTZ_2_INDIVIDUAL.bin"
Rings_MTZ_3:	BINCLUDE	"level/rings/MTZ_3_INDIVIDUAL.bin"
Rings_MTZ_4:	BINCLUDE	"level/rings/MTZ_4_INDIVIDUAL.bin"
Rings_HTZ_1:	BINCLUDE	"level/rings/HTZ_1_INDIVIDUAL.bin"
Rings_HTZ_2:	BINCLUDE	"level/rings/HTZ_2_INDIVIDUAL.bin"
Rings_HPZ_1:	BINCLUDE	"level/rings/HPZ_1_INDIVIDUAL.bin"
Rings_HPZ_2:	BINCLUDE	"level/rings/HPZ_2_INDIVIDUAL.bin"
Rings_Lev9_1:	BINCLUDE	"level/rings/09_1_INDIVIDUAL.bin"
Rings_Lev9_2:	BINCLUDE	"level/rings/09_2_INDIVIDUAL.bin"
Rings_OOZ_1:	BINCLUDE	"level/rings/OOZ_1_INDIVIDUAL.bin"
Rings_OOZ_2:	BINCLUDE	"level/rings/OOZ_2_INDIVIDUAL.bin"
Rings_MCZ_1:	BINCLUDE	"level/rings/MCZ_1_INDIVIDUAL.bin"
Rings_MCZ_2:	BINCLUDE	"level/rings/MCZ_2_INDIVIDUAL.bin"
Rings_CNZ_1:	BINCLUDE	"level/rings/CNZ_1_INDIVIDUAL.bin"
Rings_CNZ_2:	BINCLUDE	"level/rings/CNZ_2_INDIVIDUAL.bin"
Rings_CPZ_1:	BINCLUDE	"level/rings/CPZ_1_INDIVIDUAL.bin"
Rings_CPZ_2:	BINCLUDE	"level/rings/CPZ_2_INDIVIDUAL.bin"
Rings_DEZ_1:	BINCLUDE	"level/rings/DEZ_1_INDIVIDUAL.bin"
Rings_DEZ_2:	BINCLUDE	"level/rings/DEZ_2_INDIVIDUAL.bin"
Rings_WFZ_1:	BINCLUDE	"level/rings/WFZ_1_INDIVIDUAL.bin"
Rings_WFZ_2:	BINCLUDE	"level/rings/WFZ_2_INDIVIDUAL.bin"
Rings_ARZ_1:	BINCLUDE	"level/rings/ARZ_1_INDIVIDUAL.bin"
Rings_ARZ_2:	BINCLUDE	"level/rings/ARZ_2_INDIVIDUAL.bin"
Rings_SCZ_1:	BINCLUDE	"level/rings/SCZ_1_INDIVIDUAL.bin"
Rings_SCZ_2:	BINCLUDE	"level/rings/SCZ_2_INDIVIDUAL.bin"