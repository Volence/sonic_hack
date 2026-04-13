; ---------------------------------------------------------------------------
; OBJECT DEBUG LISTS
; Reserved zone slots use the default debug object list.
; ---------------------------------------------------------------------------
JmpTbl_DbgObjLists: zoneOffsetTable 2,1
	zoneTableEntry.w DbgObjList_OJZ - JmpTbl_DbgObjLists ; 0 - OJZ
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 1 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 2 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 3 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 4 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 5 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 6 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 7 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 8 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 9 - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; A - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; B - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; C - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; D - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; E - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; F - reserved
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 10 - reserved
    zoneTableEnd

; macro for a debug object list header
; must be on the same line as a label that has a corresponding _End label later
dbglistheader macro {INTLABEL}
__LABEL__ label *
	dc.w ((__LABEL___End - __LABEL__ - 2) >> 3)
    endm

; macro to define debug list object data
dbglistobj macro   obj, mapaddr,  decl, frame, flags, vram
	dc.l obj<<24|mapaddr
	dc.w decl<<8|frame
	dc.w flags<<12|vram
    endm

DbgObjList_Def: dbglistheader
	dbglistobj 1, Basic_Ring_MapUnc_12382,   0,   0,  2, VRAM_Ring
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   3,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   5,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   6,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   7,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   8,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $A,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $B,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $C,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $D,  0, $680
	dbglistobj 6, Spring_MapUnc_1901C,   $10,   0,  0, VRAM_VrtclSprng		; Up spring (red)
	dbglistobj 6, Spring_MapUnc_1901C,   $10,   0,  0, VRAM_VrtclSprng		; Up spring (yellow) - subtype $02
	dbglistobj 6, Spring_MapUnc_19032,   $10,   3,  0, VRAM_HrzntlSprng	; Side spring (red)
	dbglistobj 7, Spikes_MapUnc_15B68,   0,   0,  0, VRAM_Spikes				; Spikes
DbgObjList_Def_End

DbgObjList_OJZ: dbglistheader
	dbglistobj 1, Basic_Ring_MapUnc_12382,   0,   0,  2, VRAM_Ring
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   3,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   5,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   6,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   7,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,   8,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $A,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $B,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $C,  0, $680
	dbglistobj 2, Monitor_MapUnc_12D36,   8,  $D,  0, $680
	dbglistobj 6, Spring_MapUnc_1901C,   $10,   0,  0, VRAM_VrtclSprng		; Up spring (red)
	dbglistobj 6, Spring_MapUnc_1901C,   $10,   0,  0, VRAM_VrtclSprng		; Up spring (yellow) - subtype $02
	dbglistobj 6, Spring_MapUnc_19032,   $10,   3,  0, VRAM_HrzntlSprng	; Side spring (red)
	dbglistobj 7, Spikes_MapUnc_15B68,   0,   0,  0, VRAM_Spikes				; Spikes

DbgObjList_OJZ_End

