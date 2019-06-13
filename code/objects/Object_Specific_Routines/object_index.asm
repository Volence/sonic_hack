; ---------------------------------------------------------------------------
; OBJECT POINTER ARRAY ; object pointers ; sprite pointers ; object list ; sprite list
;
; This array contains the pointers to all the objects used in the game.
; The item in the comment is the hex pointer index value used by the game
; (and our hacking guides) to reference an object.
; ---------------------------------------------------------------------------
Obj_Index:
	dc.w Basic_Ring-ObjBase		; 1 Ring 
	dc.w Monitor-ObjBase		; 2 Monitor
	dc.w Path_Swapper-ObjBase	; 3 Collision plane/layer switcher
	dc.w CheckPoint-ObjBase		; 4 Star pole / starpost / checkpoint
	dc.w Bubbles_Base-ObjBase	; 5 Bubbles
	dc.w Spring-ObjBase			; 6 Spring
	dc.w Spikes-ObjBase			; 7 Spikes
	dc.w SignPost-ObjBase		; 8 Sign Post
	dc.w Egg_Prison-ObjBase		; 9 Egg Prison
	dc.w 0				; A
	dc.w PitcherPlant-ObjBase	; B Pitcher Plant Badnik


; ===========================================================================