; ---------------------------------------------------------------------------
; JUMP TABLE FOR SOFTWARE SCROLL MANAGERS
;
; "Software scrolling" is my term for what Nemesis (and by extension, the rest
; of the world) calls "rasterized layer deformation".* Software scroll managers
; are needed to achieve certain special camera effects - namely, locking the
; screen for a boss fight and defining the limits of said screen lock, or in
; the case of Sky Chase Zone ($10), moving the camera at a fixed rate through
; a predefined course.
; They are also used for things like controlling the parallax scrolling and
; water ripple effects in EHZ, and moving the clouds in HTZ and the stars in DEZ.
; ---------------------------------------------------------------------------
JmpTbl_SwScrlMgr: zoneOffsetTable 2,1
	zoneTableEntry.w SwScrl_EHZ - JmpTbl_SwScrlMgr		; $00
	zoneTableEntry.w SwScrl_WFZ - JmpTbl_SwScrlMgr	; $01
    zoneTableEnd
; ===========================================================================
