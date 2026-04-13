; ---------------------------------------------------------------------------
; JUMP TABLE FOR SOFTWARE SCROLL MANAGERS
;
; "Software scrolling" is my term for what Nemesis (and by extension, the rest
; of the world) calls "rasterized layer deformation".* Software scroll managers
; are needed to achieve certain special camera effects - namely, locking the
; screen for a boss fight and defining the limits of said screen lock.
; They are also used for things like controlling the parallax scrolling and
; water ripple effects in OJZ.
; ---------------------------------------------------------------------------
JmpTbl_SwScrlMgr: zoneOffsetTable 2,1
	zoneTableEntry.w SwScrl_OJZ - JmpTbl_SwScrlMgr		; $00
; Dead zone deformation entries removed (WFZ)
    zoneTableEnd
; ===========================================================================
