; =============================================================================
; Object Pointer Index
; -----------------------------------------------------------------------------
; Array of object routine pointers (offsets from ObjBase).
; The comment at right shows the pointer index in hex ($01, $02, ...).
; =============================================================================
Obj_Index:
    dc.w Basic_Ring-ObjBase          ; $01  Ring
    dc.w Monitor-ObjBase             ; $02  Monitor
    dc.w Path_Swapper-ObjBase        ; $03  Collision plane/layer switcher
    dc.w CheckPoint-ObjBase          ; $04  Star pole / starpost / checkpoint
    dc.w Bubbles_Base-ObjBase        ; $05  Bubbles
    dc.w Spring-ObjBase              ; $06  Spring
    dc.w Spikes-ObjBase              ; $07  Spikes
    dc.w SignPost-ObjBase            ; $08  Sign Post
    dc.w Egg_Prison-ObjBase          ; $09  Egg Prison
    dc.w 0                           ; $0A  (unused/null)
    dc.w PitcherPlant-ObjBase        ; $0B  Pitcher Plant Badnik
