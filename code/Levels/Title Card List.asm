	dc.b TitleCardLetters_EHZ - TitleCardLetters	; 0
	dc.b TitleCardLetters_WFZ - TitleCardLetters	; 1
	dc.b TitleCardLetters_EHZ - TitleCardLetters	; 2
	dc.b TitleCardLetters_EHZ - TitleCardLetters	; 3
	dc.b TitleCardLetters_MTZ - TitleCardLetters	; 4
	dc.b TitleCardLetters_MTZ - TitleCardLetters	; 5
	dc.b TitleCardLetters_WFZ - TitleCardLetters	; 6
	dc.b TitleCardLetters_HTZ - TitleCardLetters	; 7
	dc.b TitleCardLetters_HPZ - TitleCardLetters	; 8
	dc.b TitleCardLetters_EHZ - TitleCardLetters	; 9
	dc.b TitleCardLetters_OOZ - TitleCardLetters	; A
	dc.b TitleCardLetters_MCZ - TitleCardLetters	; B
	dc.b TitleCardLetters_CNZ - TitleCardLetters	; C
	dc.b TitleCardLetters_CPZ - TitleCardLetters	; D
	dc.b TitleCardLetters_DEZ - TitleCardLetters	; E
	dc.b TitleCardLetters_ARZ - TitleCardLetters	; F
	dc.b TitleCardLetters_SCZ - TitleCardLetters	; 10
	
	
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

TitleCardLetters_EHZ:
	titleLetters	"Test"
TitleCardLetters_MTZ:
	titleLetters	"METROPOLIS"
TitleCardLetters_HTZ:
	titleLetters	"HILL TOP"
TitleCardLetters_HPZ:
	titleLetters	"HIDDEN PALACE"
TitleCardLetters_OOZ:
	titleLetters	"OIL OCEAN"
TitleCardLetters_MCZ:
	titleLetters	"MYSTIC CAVE"
TitleCardLetters_CNZ:
	titleLetters	"CASINO NIGHT"
TitleCardLetters_CPZ:
	titleLetters	"CHEMICAL PLANT"
TitleCardLetters_ARZ:
	titleLetters	"AQUATIC RUIN"
TitleCardLetters_SCZ:
	titleLetters	"SKY CHASE"
TitleCardLetters_WFZ:
	titleLetters	"WING FORTRESS"
TitleCardLetters_DEZ:
	titleLetters	"DEATH EGG"

 charset ; revert character set	