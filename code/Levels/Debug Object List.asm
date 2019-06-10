; ---------------------------------------------------------------------------
; OBJECT DEBUG LISTS

; The jump table goes by level ID, so Metropolis Zone's list is repeated to
; account for its third act. Hidden Palace Zone uses Oil Ocean Zone's list.
; ---------------------------------------------------------------------------
JmpTbl_DbgObjLists: zoneOffsetTable 2,1
	zoneTableEntry.w DbgObjList_EHZ - JmpTbl_DbgObjLists ; 0
	zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 1
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
	dbglistobj 0, Basic_Ring_MapUnc_12382,   0,   0,  2, $6BC ; Basic_Ring = ring
	dbglistobj 0, Monitor_MapUnc_12D36,   8,   0,  0, $680 ; Monitor = monitor
DbgObjList_Def_End

DbgObjList_EHZ: dbglistheader
	dbglistobj 0, Basic_Ring_MapUnc_12382,   0,   0,  2, $6BC
	dbglistobj 0, Monitor_MapUnc_12D36,   8,   0,  0, $680
DbgObjList_EHZ_End

