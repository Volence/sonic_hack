; --------------------------------------------------------------------------------------
; Offset index of object locations
; --------------------------------------------------------------------------------------
Off_Objects: zoneOffsetTable 2,2
	zoneTableEntry.w  Objects_EHZ_1 - Off_Objects	; 0  $00
	zoneTableEntry.w  Objects_EHZ_2 - Off_Objects	; 1
	zoneTableEntry.w  Objects_WFZ_1 - Off_Objects	; 2 $01
	zoneTableEntry.w  Objects_WFZ_2 - Off_Objects	; 3
	zoneTableEntry.w  Objects_Null3 - Off_Objects	; 4  $02
	zoneTableEntry.w  Objects_Null3 - Off_Objects	; 5
	zoneTableEntry.w  Objects_Null3 - Off_Objects	; 6  $03
	zoneTableEntry.w  Objects_Null3 - Off_Objects	; 7
	zoneTableEntry.w  Objects_MTZ_1 - Off_Objects	; 8  $04
	zoneTableEntry.w  Objects_MTZ_2 - Off_Objects	; 9
	zoneTableEntry.w  Objects_MTZ_3 - Off_Objects	; 10 $05
	zoneTableEntry.w  Objects_MTZ_3 - Off_Objects	; 11
	zoneTableEntry.w  Objects_WFZ_1 - Off_Objects	; 12 $06
	zoneTableEntry.w  Objects_WFZ_2 - Off_Objects	; 13
	zoneTableEntry.w  Objects_HTZ_1 - Off_Objects	; 14 $07
	zoneTableEntry.w  Objects_HTZ_2 - Off_Objects	; 15
	zoneTableEntry.w  Objects_HPZ_1 - Off_Objects	; 16 $08
	zoneTableEntry.w  Objects_HPZ_2 - Off_Objects	; 17
	zoneTableEntry.w  Objects_Null3 - Off_Objects	; 18 $09
	zoneTableEntry.w  Objects_Null3 - Off_Objects	; 19
	zoneTableEntry.w  Objects_OOZ_1 - Off_Objects	; 20 $0A
	zoneTableEntry.w  Objects_OOZ_2 - Off_Objects	; 21
	zoneTableEntry.w  Objects_MCZ_1 - Off_Objects	; 22 $0B
	zoneTableEntry.w  Objects_MCZ_2 - Off_Objects	; 23
	zoneTableEntry.w  Objects_CNZ_1 - Off_Objects	; 24 $0C
	zoneTableEntry.w  Objects_CNZ_2 - Off_Objects	; 25
	zoneTableEntry.w  Objects_CPZ_1 - Off_Objects	; 26 $0D
	zoneTableEntry.w  Objects_CPZ_2 - Off_Objects	; 27
	zoneTableEntry.w  Objects_DEZ_1 - Off_Objects	; 28 $0E
	zoneTableEntry.w  Objects_DEZ_2 - Off_Objects	; 29
	zoneTableEntry.w  Objects_ARZ_1 - Off_Objects	; 30 $0F
	zoneTableEntry.w  Objects_ARZ_2 - Off_Objects	; 31
	zoneTableEntry.w  Objects_SCZ_1 - Off_Objects	; 32 $10
	zoneTableEntry.w  Objects_SCZ_2 - Off_Objects	; 33
    zoneTableEnd

;Objects_Null1: ; unused
		BINCLUDE	"level/objects/Null_1.bin"

Objects_EHZ_1:	BINCLUDE	"level/objects/EHZ_1.bin"
Objects_EHZ_2:	BINCLUDE	"level/objects/EHZ_2.bin"
Objects_MTZ_1:	BINCLUDE	"level/objects/MTZ_1.bin"
Objects_MTZ_2:	BINCLUDE	"level/objects/MTZ_2.bin"
Objects_MTZ_3:	BINCLUDE	"level/objects/MTZ_3.bin"
Objects_WFZ_1:	BINCLUDE	"level/objects/WFZ_1.bin"
Objects_WFZ_2:	BINCLUDE	"level/objects/WFZ_2.bin"
Objects_HTZ_1:	BINCLUDE	"level/objects/HTZ_1.bin"
Objects_HTZ_2:	BINCLUDE	"level/objects/HTZ_2.bin"
Objects_HPZ_1:	BINCLUDE	"level/objects/HPZ_1.bin"
Objects_HPZ_2:	BINCLUDE	"level/objects/HPZ_2.bin"

;Objects_Null2: ; unused
		BINCLUDE	"level/objects/Null_2.bin"

Objects_OOZ_1:	BINCLUDE	"level/objects/OOZ_1.bin"
Objects_OOZ_2:	BINCLUDE	"level/objects/OOZ_2.bin"
Objects_MCZ_1:	BINCLUDE	"level/objects/MCZ_1.bin"
Objects_MCZ_2:	BINCLUDE	"level/objects/MCZ_2.bin"
Objects_CNZ_1:	BINCLUDE	"level/objects/CNZ_1.bin"
Objects_CNZ_2:	BINCLUDE	"level/objects/CNZ_2.bin"
Objects_CPZ_1:	BINCLUDE	"level/objects/CPZ_1.bin"
Objects_CPZ_2:	BINCLUDE	"level/objects/CPZ_2.bin"
Objects_DEZ_1:	BINCLUDE	"level/objects/DEZ_1.bin"
Objects_DEZ_2:	BINCLUDE	"level/objects/DEZ_2.bin"
Objects_ARZ_1:	BINCLUDE	"level/objects/ARZ_1.bin"
Objects_ARZ_2:	BINCLUDE	"level/objects/ARZ_2.bin"
Objects_SCZ_1:	BINCLUDE	"level/objects/SCZ_1.bin"
Objects_SCZ_2:	BINCLUDE	"level/objects/SCZ_2.bin"
Objects_Null3:	BINCLUDE	"level/objects/Null_3.bin"

;Objects_Null4: ; unused
		BINCLUDE	"level/objects/Null_4.bin"
;Objects_Null5: ; unused
		BINCLUDE	"level/objects/Null_5.bin"
;Objects_Null6: ; unused
		BINCLUDE	"level/objects/Null_6.bin"