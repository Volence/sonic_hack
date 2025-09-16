; ---------------------------------------------------------------------------
; OBJECT DEBUG LISTS
; Jump table is indexed by level ID.
; Metropolis’ list is repeated to cover its third act.
; Hidden Palace reuses Oil Ocean’s list.
; ---------------------------------------------------------------------------

JmpTbl_DbgObjLists: zoneOffsetTable 2,1
    zoneTableEntry.w DbgObjList_EHZ - JmpTbl_DbgObjLists ; 0
    zoneTableEntry.w DbgObjList_Def - JmpTbl_DbgObjLists ; 1
    zoneTableEnd

; ---------------------------------------------------------------------------
; Debug-list header macro
; Usage: must share the same line as the list label and have a matching _End
; ---------------------------------------------------------------------------
dbglistheader macro {INTLABEL}
__LABEL__ label *
    dc.w ((__LABEL___End - __LABEL__ - 2) >> 3) ; (#entries) = bytes/8
    endm

; ---------------------------------------------------------------------------
; Debug-list entry macro
;   obj     : object ID (byte, placed in high byte of long)
;   mapaddr : mappings pointer (24-bit, packed into low 3 bytes of long)
;   decl    : subtype/descriptor (high byte of word)
;   frame   : mapping frame (low byte of word)
;   flags   : attribute flags (upper 4 bits of word)
;   vram    : VRAM tile index (low 12 bits of word)
; ---------------------------------------------------------------------------
dbglistobj macro   obj, mapaddr,  decl, frame, flags, vram
    dc.l obj<<24|mapaddr
    dc.w decl<<8|frame
    dc.w flags<<12|vram
    endm

; ======================= Default debug object list =========================
DbgObjList_Def: dbglistheader
    dbglistobj 1, Basic_Ring_MapUnc_12382,  0,   0,  2, $6BC
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   3,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   5,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   6,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   7,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   8,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $A,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $B,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $C,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $D,  0, $680
DbgObjList_Def_End

; ======================= Emerald Hill Zone list ============================
DbgObjList_EHZ: dbglistheader
    dbglistobj 1, Basic_Ring_MapUnc_12382,  0,   0,  2, $6BC
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   3,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   5,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   6,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   7,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,   8,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $A,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $B,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $C,  0, $680
    dbglistobj 2, Monitor_MapUnc_12D36,     8,  $D,  0, $680
DbgObjList_EHZ_End
