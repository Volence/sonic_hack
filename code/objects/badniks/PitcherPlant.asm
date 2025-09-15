; =========================
; Pitcher Plant (Object 0B)
; All magic numbers replaced with constants
; =========================

; -------------------------
; Object Offsets
; -------------------------
PitcherPlant__Timer                = $24    ; per-object timer field

; -------------------------
; Timers / distances
; -------------------------
PitcherPlant__WaitTime             = $40    ; frames to wait after firing
PitcherPlant__ShootPrepTime        = $28    ; frames from detection to bullet spawn
PitcherPlant__ShootFrame           = $10    ; when Timer == 16, spawn bullet

PitcherPlant__DistanceFromSonicToAttack = $60

; -------------------------
; Bullet physics
; -------------------------
PitcherPlant__BulletYSpeed         = $300   ; magnitude; sign applied at spawn
PitcherPlant__BulletXSpeed         = $100   ; magnitude; sign applied at spawn
PitcherPlant__Gravity              = $20

; -------------------------
; Spawn offsets
; -------------------------
PitcherPlant__YOffset              = $0004  ; bullet spawn offset upward
PitcherPlant__XOffsetLeft          = $0010  ; bullet spawn offset left
PitcherPlant__XOffsetRight         = $0020  ; bullet spawn offset right

; -------------------------
; Kill bounds
; -------------------------
PitcherPlant__KillYBoundary        = $06F0  ; despawn bullets below this Y

; -------------------------
; Visuals / object data constants
; -------------------------
PitcherPlant__ArtTile              = $03A0
PitcherPlant__Priority             = $0180
PitcherPlant__BulletPriority       = $0100

; Render Flags
PitcherPlant__RenderFlags          = 4
PitcherPlant__BulletRenderFlags    = 4

; Collision Responses
PitcherPlant__CollisionResponse    = TR_Enemy
PitcherPlant__BulletCollision      = TR_Projectile

; Hitbox sizes
PitcherPlant__Width                = $0A
PitcherPlant__Height               = $12
PitcherPlant__BulletWidth          = 3
PitcherPlant__BulletHeight         = 3

; Animations (object)
PitcherPlant__Anim_Idle            = 0
PitcherPlant__Anim_Shoot           = 2
PitcherPlant__InitAnim             = PitcherPlant__Anim_Idle
PitcherPlant__InitMapFrame         = 0

; Animations (bullet)
PitcherPlant__Bullet_Anim          = 1
PitcherPlant__Bullet_MapFrame      = 5

; how far above/below Sonic can be and still trigger (in pixels if $100=1px)
PitcherPlant__VerticalTolerance = $60


; ===========================================================================
; Object 0B - Pitcher Plant Badnik
; ===========================================================================
PitcherPlant:
        lea     PitcherPlant__Data(pc),a2
        jsr     Load_Object2

; -------------------------
; WAIT / SCAN FOR SONIC
; -------------------------
PitcherPlant__WaitSonic:
        tst.b   PitcherPlant__Timer(a0)
        bmi.b   PP__do_scan
        subq.b  #1,PitcherPlant__Timer(a0)
        bra.b   PitcherPlant__Display

PP__do_scan:
        lea     MainCharacter,a1

        ; --- horizontal delta for facing/range ---
        move.w  x_pos(a1),d2
        move.w  x_pos(a0),d3
        sub.w   d2,d3                       ; d3 = plant_x - sonic_x   (sign matters)

        ; --- vertical gate: require |ΔY| <= tolerance ---
        move.w  y_pos(a0),d4
        sub.w   y_pos(a1),d4                ; d4 = plant_y - sonic_y
        bpl.s   .vy_abs
        neg.w   d4
.vy_abs:
        cmp.w   #PitcherPlant__VerticalTolerance,d4
        bgt.w   PitcherPlant__Display       ; too high/low → don't shoot

        ; --- facing / horizontal distance checks (with CCR restored from d3) ---
        btst    #0,render_flags(a0)
        bne.w   PP__facing_right            ; bit set → facing right

        ; ---- facing LEFT ----
        tst.w   d3                          ; restore CCR for d3 sign
        bmi.w   PitcherPlant__Display       ; Sonic to the right -> ignore
        cmp.w   #PitcherPlant__DistanceFromSonicToAttack,d3
        bge.w   PitcherPlant__Display       ; too far to the left -> ignore
        move.w  #objroutine(PitcherPlant__Shoot),(a0)
        move.b  #PitcherPlant__ShootPrepTime,PitcherPlant__Timer(a0)
        bra.w   PitcherPlant__Display

PP__facing_right:
        ; ---- facing RIGHT ----
        tst.w   d3                          ; restore CCR for d3 sign
        bpl.w   PitcherPlant__Display       ; Sonic to the left -> ignore
        cmp.w   #-PitcherPlant__DistanceFromSonicToAttack,d3
        ble.w   PitcherPlant__Display       ; too far to the right -> ignore
        move.w  #objroutine(PitcherPlant__Shoot),(a0)
        move.b  #PitcherPlant__ShootPrepTime,PitcherPlant__Timer(a0)
        ; fall through


; -------------------------
; COMMON DISPLAY
; -------------------------
PitcherPlant__Display:
        lea     PitcherPlant__Animate,a1
        jsr     AnimateSprite
        jsr     MarkObjGone
        jmp     DisplaySprite

; -------------------------
; SHOOT
; -------------------------
PitcherPlant__Shoot:
        move.b  #PitcherPlant__Anim_Shoot,anim(a0)
        subq.b  #1,PitcherPlant__Timer(a0)
        cmpi.b  #PitcherPlant__ShootFrame,PitcherPlant__Timer(a0)
        beq.s   PitcherPlant__BulletLoad

        tst.b   PitcherPlant__Timer(a0)
        bne.b   PitcherPlant__Display
        move.b  #PitcherPlant__WaitTime,PitcherPlant__Timer(a0)
        move.w  #objroutine(PitcherPlant__WaitSonic),(a0)
        move.b  #PitcherPlant__Anim_Idle,anim(a0)
        bra.b   PitcherPlant__Display

; -------------------------
; BULLET SPAWN
; -------------------------
PitcherPlant__BulletLoad:
        lea     PitcherPlant__BulletData(pc),a2
        jsr     BadnikWeaponLoad            ; a1 = bullet

        sub.w   #PitcherPlant__YOffset,y_pos(a1)
        sub.w   #PitcherPlant__XOffsetLeft,x_pos(a1)

        move.w  #-PitcherPlant__BulletYSpeed,y_vel(a1) ; up
        move.w  #-PitcherPlant__BulletXSpeed,x_vel(a1) ; left by default

        btst    #0,render_flags(a0)
        beq.s   PP__spawn_done
        add.w   #PitcherPlant__XOffsetRight,x_pos(a1)
        neg.w   x_vel(a1)                   ; flip to right if parent is flipped
PP__spawn_done:
        bra.w   PitcherPlant__Display

; -------------------------
; BULLET LOGIC
; -------------------------
PitcherPlant__Bullet:
        cmpi.w  #PitcherPlant__KillYBoundary,y_pos(a0)
        ble.b   PP__apply_gravity
        jmp     DeleteObject
PP__apply_gravity:
        addi.w  #PitcherPlant__Gravity,y_vel(a0)
        jsr     ObjectMove
        jmp     DisplaySprite

; ===========================================================================
; DATA BLOCKS
; ===========================================================================
PitcherPlant__Data:
        dc.w    objroutine(PitcherPlant__WaitSonic)
        dc.l    map_ppbadnik
        dc.w    PitcherPlant__ArtTile
        dc.b    PitcherPlant__RenderFlags
        dc.b    PitcherPlant__CollisionResponse
        dc.w    PitcherPlant__Priority
        dc.b    PitcherPlant__Width
        dc.b    PitcherPlant__Height
        dc.b    PitcherPlant__InitAnim
        dc.b    PitcherPlant__InitMapFrame

PitcherPlant__BulletData:
        dc.w    objroutine(PitcherPlant__Bullet)
        dc.l    map_ppbadnik
        dc.w    PitcherPlant__ArtTile
        dc.b    PitcherPlant__BulletRenderFlags
        dc.b    PitcherPlant__BulletCollision
        dc.w    PitcherPlant__BulletPriority
        dc.b    PitcherPlant__BulletWidth
        dc.b    PitcherPlant__BulletHeight
        dc.w    PitcherPlant__BulletXSpeed      ; overwritten at spawn
        dc.w    PitcherPlant__BulletYSpeed      ; overwritten at spawn
        dc.b    PitcherPlant__Bullet_Anim
        dc.b    PitcherPlant__Bullet_MapFrame
