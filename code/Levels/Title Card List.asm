	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 0 - OJZ
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 1 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 2 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 3 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 4 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 5 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 6 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 7 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 8 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 9 - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; A - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; B - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; C - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; D - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; E - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; F - reserved
	dc.b TitleCardLetters_OJZ - TitleCardLetters	; 10 - reserved
	
	
 ; temporarily remap characters to title card letter format
 ; Characters are encoded as Aa, Bb, Cc, etc. through a macro
 charset 'A',0	; can't have an embedded 0 in a string
 charset 'B',"\4\8\xC\4\x10\x14\x18\x1C\x1E\x22\x26\x2A\4\4\x30\x34\x38\x3C\x40\x44\x48\x4C\x52\x56\4"
 charset 'a',"\4\4\4\4\4\4\4\4\2\4\4\4\6\4\4\4\4\4\4\4\4\4\6\4\4"

; Defines which letters load for each title card
; Each letter occurs only once, and  the letters ENOZ (i.e. ZONE) aren't loaded here
; However, this is hidden by the titleLetters macro, and normal titles can be used
; (the macro is defined near ContinueScreen_AdditionalLetters, which uses it before here)

; word_15832:
TitleCardLetters:

TitleCardLetters_OJZ:
	titleLetters	"ORACLE JUNGLE"
; Dead zone title card letters removed (MTZ, HTZ, HPZ, OOZ, MCZ, CNZ, CPZ, ARZ, SCZ, WFZ, DEZ)

 charset ; revert character set	