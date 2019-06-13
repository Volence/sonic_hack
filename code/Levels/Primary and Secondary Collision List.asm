; ---------------------------------------------------------------------------
; Pointers to primary collision indexes

; Contains an array of pointers to the primary collision index data for each
; level. 1 pointer for each level, pointing the primary collision index.
; ---------------------------------------------------------------------------
Off_ColP: zoneOffsetTable 4,1
	zoneTableEntry.l ColP_EHZ
	zoneTableEntry.l ColP_WFZ	; 1
	zoneTableEntry.l ColP_L	; 2
	zoneTableEntry.l ColP_L	; 3
	zoneTableEntry.l ColP_L	; 4
	zoneTableEntry.l ColP_L	; 5
	zoneTableEntry.l ColP_L	; 6
	zoneTableEntry.l ColP_L	; 7
	zoneTableEntry.l ColP_L	; 8
	zoneTableEntry.l ColP_L	; 9
	zoneTableEntry.l ColP_L	; 10
	zoneTableEntry.l ColP_L	; 11
	zoneTableEntry.l ColP_L	; 12
	zoneTableEntry.l ColP_L	; 13
	zoneTableEntry.l ColP_L	; 14
	zoneTableEntry.l ColP_L	; 15
	zoneTableEntry.l ColP_L	; 16
    zoneTableEnd

; ---------------------------------------------------------------------------
; Pointers to secondary collision indexes

; Contains an array of pointers to the secondary collision index data for
; each level. 1 pointer for each level, pointing the secondary collision
; index.
; ---------------------------------------------------------------------------
Off_ColS: zoneOffsetTable 4,1
	zoneTableEntry.l ColS_EHZ
	zoneTableEntry.l ColS_WFZ	; 1
	zoneTableEntry.l ColS_L	; 2
	zoneTableEntry.l ColS_L	; 3
	zoneTableEntry.l ColS_L	; 4
	zoneTableEntry.l ColS_L	; 5
	zoneTableEntry.l ColS_L	; 6
	zoneTableEntry.l ColS_L	; 7
	zoneTableEntry.l ColS_L	; 8
	zoneTableEntry.l ColS_L	; 9
	zoneTableEntry.l ColS_L	; 10
	zoneTableEntry.l ColS_L	; 11
	zoneTableEntry.l ColS_L	; 12
	zoneTableEntry.l ColS_L	; 13
	zoneTableEntry.l ColS_L	; 14
	zoneTableEntry.l ColS_L	; 15
	zoneTableEntry.l ColS_L	; 16
    zoneTableEnd
	
;---------------------------------------------------------------------------------------
; EHZ and HTZ primary 16x16 collision index (Kosinski compression)
ColP_EHZ:	BINCLUDE	"collision/EHZ primary 16x16 collision index.bin"
;---------------------------------------------------------------------------------------
; EHZ and HTZ secondary 16x16 collision index (Kosinski compression)
ColS_EHZ:	BINCLUDE	"collision/EHZ secondary 16x16 collision index.bin"
;---------------------------------------------------------------------------------------
ColS_L:	BINCLUDE	"collision/EHZ primary 16x16 collision index.bin"
ColP_L:	BINCLUDE	"collision/EHZ secondary 16x16 collision index.bin"

ColP_WFZ:	BINCLUDE	"collision/WFZ and SCZ primary 16x16 collision index.bin"
ColS_WFZ:	BINCLUDE	"collision/WFZ and SCZ secondary 16x16 collision index.bin"
