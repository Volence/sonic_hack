; --------------------------------------------------------------------------------------
; CHARACTER START LOCATION ARRAY
; 2 entries per act, corresponding to the X and Y start positions.
; Reserved zone slots use OJZ act 1 start position as fallback.
; --------------------------------------------------------------------------------------
WrdArr_StartLocSonic: zoneOffsetTable 2,4
	zoneTableEntry.w	$47,    $33C	; $00 - OJZ act 1
	zoneTableEntry.w	$60,	$2AF	;      OJZ act 2
	zoneTableEntry.w	$47,	$33C	; $01 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $02 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $03 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $04 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $05 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $06 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $07 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $08 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $09 - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $0A - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $0B - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $0C - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $0D - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $0E - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $0F - reserved
	zoneTableEntry.w	$47,	$33C
	zoneTableEntry.w	$47,	$33C	; $10 - reserved
	zoneTableEntry.w	$47,	$33C
    zoneTableEnd
	
