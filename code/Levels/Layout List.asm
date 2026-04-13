;---------------------------------------------------------------------------------------
; Offset index of level layouts
; Two entries per zone, pointing to the level layouts for acts 1 and 2 of each zone
; respectively. Reserved zone slots point to OJZ layouts as fallback.
;---------------------------------------------------------------------------------------
Off_Level:			zoneOffsetTable 2,2
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 0 - OJZ act 1
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 1 - OJZ act 2
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 2 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 3
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 4 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 5
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 6 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 7
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 8 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 9
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 10 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 11
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 12 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 13
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 14 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 15
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 16 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 17
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 18 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 19
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 20 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 21
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 22 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 23
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 24 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 25
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 26 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 27
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 28 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 29
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 30 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 31
	zoneTableEntry.w Level_OJZ1 - Off_Level		; 32 - reserved
	zoneTableEntry.w Level_OJZ2 - Off_Level		; 33
    zoneTableEnd
	
	
;---------------------------------------------------------------------------------------
; OJZ act 1 level layout (Kosinski compression)
	even
Level_OJZ1:	BINCLUDE	"level/layout/OJZ_1.bin"
	even
;---------------------------------------------------------------------------------------
; OJZ act 2 level layout (Kosinski compression)
Level_OJZ2:	BINCLUDE	"level/layout/OJZ_2.bin"
	even
; Dead zone layouts removed (WFZ, L1/L2 duplicates)