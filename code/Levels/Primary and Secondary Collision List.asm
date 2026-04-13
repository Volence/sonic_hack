; ---------------------------------------------------------------------------
; Pointers to primary collision indexes
; Reserved zone slots point to OJZ collision data.
; ---------------------------------------------------------------------------
Off_ColP: zoneOffsetTable 4,1
	zoneTableEntry.l ColP_OJZ	; 0 - OJZ
	zoneTableEntry.l ColP_OJZ	; 1 - reserved
	zoneTableEntry.l ColP_OJZ	; 2 - reserved
	zoneTableEntry.l ColP_OJZ	; 3 - reserved
	zoneTableEntry.l ColP_OJZ	; 4 - reserved
	zoneTableEntry.l ColP_OJZ	; 5 - reserved
	zoneTableEntry.l ColP_OJZ	; 6 - reserved
	zoneTableEntry.l ColP_OJZ	; 7 - reserved
	zoneTableEntry.l ColP_OJZ	; 8 - reserved
	zoneTableEntry.l ColP_OJZ	; 9 - reserved
	zoneTableEntry.l ColP_OJZ	; 10 - reserved
	zoneTableEntry.l ColP_OJZ	; 11 - reserved
	zoneTableEntry.l ColP_OJZ	; 12 - reserved
	zoneTableEntry.l ColP_OJZ	; 13 - reserved
	zoneTableEntry.l ColP_OJZ	; 14 - reserved
	zoneTableEntry.l ColP_OJZ	; 15 - reserved
	zoneTableEntry.l ColP_OJZ	; 16 - reserved
    zoneTableEnd

; ---------------------------------------------------------------------------
; Pointers to secondary collision indexes
; Reserved zone slots point to OJZ collision data.
; ---------------------------------------------------------------------------
Off_ColS: zoneOffsetTable 4,1
	zoneTableEntry.l ColS_OJZ	; 0 - OJZ
	zoneTableEntry.l ColS_OJZ	; 1 - reserved
	zoneTableEntry.l ColS_OJZ	; 2 - reserved
	zoneTableEntry.l ColS_OJZ	; 3 - reserved
	zoneTableEntry.l ColS_OJZ	; 4 - reserved
	zoneTableEntry.l ColS_OJZ	; 5 - reserved
	zoneTableEntry.l ColS_OJZ	; 6 - reserved
	zoneTableEntry.l ColS_OJZ	; 7 - reserved
	zoneTableEntry.l ColS_OJZ	; 8 - reserved
	zoneTableEntry.l ColS_OJZ	; 9 - reserved
	zoneTableEntry.l ColS_OJZ	; 10 - reserved
	zoneTableEntry.l ColS_OJZ	; 11 - reserved
	zoneTableEntry.l ColS_OJZ	; 12 - reserved
	zoneTableEntry.l ColS_OJZ	; 13 - reserved
	zoneTableEntry.l ColS_OJZ	; 14 - reserved
	zoneTableEntry.l ColS_OJZ	; 15 - reserved
	zoneTableEntry.l ColS_OJZ	; 16 - reserved
    zoneTableEnd
	
;---------------------------------------------------------------------------------------
; OJZ primary 16x16 collision index (Kosinski compression)
ColP_OJZ:	BINCLUDE	"collision/OJZ primary 16x16 collision index.bin"
;---------------------------------------------------------------------------------------
; OJZ secondary 16x16 collision index (Kosinski compression)
ColS_OJZ:	BINCLUDE	"collision/OJZ secondary 16x16 collision index.bin"
; Dead zone collision data removed (WFZ/SCZ, L/duplicate)
