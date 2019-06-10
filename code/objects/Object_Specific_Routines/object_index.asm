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
	dc.w Pitcher_Plant_Badnik-ObjBase	; B Pitcher Plant Badnik
	dc.w 0				; C
	dc.w 0				; D
	dc.w 0				; E
	dc.w 0				; F
	dc.w 0				; 10
	dc.w 0				; 11
	dc.w 0				; 12
	dc.w 0				; 13
	dc.w 0				; 14
	dc.w 0				; 15
	dc.w 0				; 16
	dc.w 0				; 17
	dc.w 0				; 18
	dc.w 0				; 19
	dc.w 0				; 1A
	dc.w 0				; 1B
	dc.w 0				; 1C
	dc.w 0				; 1D
	dc.w 0				; 1E
	dc.w 0				; 1F
	dc.w Pitcher_Plant_Badnik-ObjBase	; 20
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w Bubbles_Base-ObjBase	; Bubbles in Aquatic Ruin Zone
	dc.w Basic_Ring-ObjBase	; A ring
	dc.w Monitor-ObjBase	; Monitor
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w Spikes-ObjBase	; Vertical spikes
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w 0
	dc.w Spring-ObjBase	; Spring
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w 0	
	dc.w CheckPoint-ObjBase	; Star pole / starpost / checkpoint

; ===========================================================================