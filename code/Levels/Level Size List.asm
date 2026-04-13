; ----------------------------------------------------------------------------
; LEVEL SIZE ARRAY

; This array defines the screen boundaries for each act in the game.
; Reserved zone slots use OJZ act 1 boundaries as fallback.
; ----------------------------------------------------------------------------
;			xstart	xend	ystart	yend	; ZID ; Zone
WrdArr_LvlSize: zoneOffsetTable 2,8
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; OJZ act 1
	zoneTableEntry.w	$0,	$2940,	$0,	$420	; OJZ act 2
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $01 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $02 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $03 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $04 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $05 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $06 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $07 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $08 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $09 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $0A - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $0B - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $0C - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $0D - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $0E - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $0F - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
	zoneTableEntry.w	$0,	$18C0,	0,	$800	; $10 - reserved
	zoneTableEntry.w	$0,	$18C0,	0,	$800
    zoneTableEnd