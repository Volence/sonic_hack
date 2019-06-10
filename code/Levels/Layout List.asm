;---------------------------------------------------------------------------------------
; Offset index of level layouts
; Two entries per zone, pointing to the level layouts for acts 1 and 2 of each zone
; respectively.
;---------------------------------------------------------------------------------------
Off_Level:			zoneOffsetTable 2,2
	zoneTableEntry.w Level_EHZ1 - Off_Level
	zoneTableEntry.w Level_EHZ2 - Off_Level	; 1
	zoneTableEntry.w Level_WFZ - Off_Level	; 2
	zoneTableEntry.w Level_L2 - Off_Level	; 3
	zoneTableEntry.w Level_L1 - Off_Level	; 4
	zoneTableEntry.w Level_L2 - Off_Level	; 5
	zoneTableEntry.w Level_L1 - Off_Level	; 6
	zoneTableEntry.w Level_L2 - Off_Level	; 7
	zoneTableEntry.w Level_L1 - Off_Level	; 8
	zoneTableEntry.w Level_L2 - Off_Level	; 9
	zoneTableEntry.w Level_L1 - Off_Level	; 10
	zoneTableEntry.w Level_L2 - Off_Level	; 11
	zoneTableEntry.w Level_L1 - Off_Level	; 12
	zoneTableEntry.w Level_L2 - Off_Level	; 13
	zoneTableEntry.w Level_L1 - Off_Level	; 14
	zoneTableEntry.w Level_L2 - Off_Level	; 15
	zoneTableEntry.w Level_L1 - Off_Level	; 16
	zoneTableEntry.w Level_L2 - Off_Level	; 17
	zoneTableEntry.w Level_L1 - Off_Level	; 18
	zoneTableEntry.w Level_L2 - Off_Level	; 19
	zoneTableEntry.w Level_L1 - Off_Level	; 20
	zoneTableEntry.w Level_L2 - Off_Level	; 21
	zoneTableEntry.w Level_L1 - Off_Level	; 22
	zoneTableEntry.w Level_L2 - Off_Level	; 23
	zoneTableEntry.w Level_L1 - Off_Level	; 24
	zoneTableEntry.w Level_L2 - Off_Level	; 25
	zoneTableEntry.w Level_L1 - Off_Level	; 26
	zoneTableEntry.w Level_L2 - Off_Level	; 27
	zoneTableEntry.w Level_L1 - Off_Level	; 28
	zoneTableEntry.w Level_L2 - Off_Level	; 29
	zoneTableEntry.w Level_L1 - Off_Level	; 30
	zoneTableEntry.w Level_L2 - Off_Level	; 31
	zoneTableEntry.w Level_L1 - Off_Level	; 32
	zoneTableEntry.w Level_L2 - Off_Level	; 33
    zoneTableEnd
	
	
;---------------------------------------------------------------------------------------
; EHZ act 1 level layout (Kosinski compression)
	even
Level_EHZ1:	BINCLUDE	"level/layout/EHZ_1.bin"
	even
;---------------------------------------------------------------------------------------
; EHZ act 2 level layout (Kosinski compression)
Level_EHZ2:	BINCLUDE	"level/layout/EHZ_2.bin"
	even
;---------------------------------------------------------------------------------------
Level_L1:	BINCLUDE	"level/layout/EHZ_1.bin"
	even
Level_L2:	BINCLUDE	"level/layout/EHZ_2.bin"
	even
Level_WFZ:	BINCLUDE	"level/layout/WFZ1.bin"
	even	