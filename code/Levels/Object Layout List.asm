; --------------------------------------------------------------------------------------
; Offset index of object locations
; Reserved zone slots point to OJZ object layouts.
; --------------------------------------------------------------------------------------
Off_Objects: zoneOffsetTable 2,2
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 0 - OJZ act 1
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 1 - OJZ act 2
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 2 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 3
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 4 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 5
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 6 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 7
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 8 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 9
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 10 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 11
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 12 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 13
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 14 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 15
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 16 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 17
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 18 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 19
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 20 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 21
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 22 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 23
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 24 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 25
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 26 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 27
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 28 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 29
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 30 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 31
	zoneTableEntry.w  Objects_OJZ_1 - Off_Objects	; 32 - reserved
	zoneTableEntry.w  Objects_OJZ_2 - Off_Objects	; 33
    zoneTableEnd

Objects_OJZ_1:	BINCLUDE	"level/objects/OJZ_1.bin"
Objects_OJZ_2:	BINCLUDE	"level/objects/OJZ_2.bin"
Objects_Null3:	BINCLUDE	"level/objects/Null_3.bin"
; Dead zone object layouts removed (MTZ, WFZ, HTZ, HPZ, OOZ, MCZ, CNZ, CPZ, DEZ, ARZ, SCZ)