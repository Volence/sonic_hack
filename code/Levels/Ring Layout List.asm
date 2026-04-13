;--------------------------------------------------------------------------------------
; Offset index of ring locations
; Reserved zone slots point to OJZ ring layouts.
;--------------------------------------------------------------------------------------
Off_Rings: zoneOffsetTable 2,2
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 0 - OJZ act 1
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 1 - OJZ act 2
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 2 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 3
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 4 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 5
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 6 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 7
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 8 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 9
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 10 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 11
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 12 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 13
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 14 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 15
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 16 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 17
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 18 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 19
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 20 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 21
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 22 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 23
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 24 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 25
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 26 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 27
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 28 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 29
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 30 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 31
	zoneTableEntry.w  Rings_OJZ_1 - Off_Rings	; 32 - reserved
	zoneTableEntry.w  Rings_OJZ_2 - Off_Rings	; 33
    zoneTableEnd

Rings_OJZ_1:	BINCLUDE	"level/rings/OJZ_1_INDIVIDUAL.bin"
Rings_OJZ_2:	BINCLUDE	"level/rings/OJZ_2_INDIVIDUAL.bin"
; Dead zone ring layouts removed (01, 02, 03, 09, MTZ, HTZ, HPZ, OOZ, MCZ, CNZ, CPZ, DEZ, WFZ, ARZ, SCZ)