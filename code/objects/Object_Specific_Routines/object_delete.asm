; ---------------------------------------------------------------------------
; Subroutine to delete an object
;   DeleteObject  : a0 = object base
;   DeleteObject2 : a1 = object base   (kept for existing callers)
; Clobbers: d0, a1
; ---------------------------------------------------------------------------

DeleteObject:
    movea.l a0,a1
; fall-through

DeleteObject2:
    moveq   #bytesToLcnt(next_object),d0   ; longwords-1 to clear
DeleteObject2_Loop:
    clr.l   (a1)+
    dbf     d0,DeleteObject2_Loop
    rts
