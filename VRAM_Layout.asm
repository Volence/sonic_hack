; ===========================================================================
; VRAM LAYOUT MAP & CONSTANTS
; ===========================================================================
; Genesis VDP has 64KB VRAM = 2048 tiles ($000-$7FF)
; Each tile = 32 bytes, so tile_index = byte_address / 32
;
; MEMORY MAP (Current - matches existing PLCs):
; ---------------------------------------------------------------------------
;   $000-$23F : Level foreground art (Kosinski) - FIXED, varies by zone
;   $240-$3FF : ZONE POOL A - zone-specific objects
;   $400-$5FF : ZONE POOL B - springs, hazards, effects, animals
;   $600-$67F : Scroll plane tiles - FIXED (VDP configured)
;   $680-$77F : Core UI + Shared Pool (monitors, rings, HUD, signpost)
;   $780-$7FF : Character sprites - FIXED (DMA destination)
; ===========================================================================

; ---------------------------------------------------------------------------
; HELPER MACROS
; ---------------------------------------------------------------------------
; vram_bytes: Convert tile index to VDP byte address
; Usage: plreq vram_bytes(VRAM_Ring), ArtNem_Ring
vram_bytes function tile,((tile&$7FF)<<5)

; vram_art: Create art_tile word from tile index + palette + priority
; Usage: move.w #vram_art(VRAM_Explosion,0,0), art_tile(a0)
vram_art function tile,pal,pri,((pri&1)<<15)|((pal&3)<<13)|(tile&$7FF)

; ===========================================================================
; FIXED REGIONS (Cannot be moved - VDP/DMA configured)
; ===========================================================================

; ---------------------------------------------------------------------------
; LEVEL FOREGROUND ART ($000-$23F) - FIXED
; ---------------------------------------------------------------------------
VRAM_LevelArt         = $000
VRAM_LevelArt_End     = $23F

; ---------------------------------------------------------------------------
; SCROLL PLANE TILES ($600-$67F) - FIXED (VDP configured)
; ---------------------------------------------------------------------------
VRAM_ScrollPlane      = $600
VRAM_ScrollPlane_End  = $67F

; ---------------------------------------------------------------------------
; CHARACTER SPRITES ($780-$7FF) - FIXED (DMA destination)
; ---------------------------------------------------------------------------
VRAM_Characters       = $780
VRAM_Sonic            = $780   ; DMA loaded
VRAM_Knuckles         = $780   ; shares with Sonic
VRAM_Tails            = $7A0
VRAM_TailsTails       = $7B0
VRAM_SonicLife        = $7D4   ; life icon
VRAM_TailsLife        = $7D4   ; shares slot
VRAM_KnuxLife         = $7D4   ; shares slot
VRAM_Characters_End   = $7FF

; ===========================================================================
; ZONE POOL A ($240-$3FF) - Zone-specific objects
; ===========================================================================
VRAM_ZonePoolA_Start  = $240
VRAM_ZonePoolA_End    = $3FF

VRAM_PitcherPlant     = $3A0   ; OJZ badnik

; ===========================================================================
; ZONE POOL B ($400-$5FF) - Springs, hazards, effects, animals
; ===========================================================================
VRAM_ZonePoolB_Start  = $400
VRAM_ZonePoolB_End    = $5FF

; --- Water & Bubbles ---
VRAM_WaterSurface     = $400
VRAM_BigBubbles       = $418

; --- Springs ---
VRAM_DignlSprng       = $440
VRAM_VrtclSprng       = $460
VRAM_HrzntlSprng      = $474

; --- Hazards ---
VRAM_Spikes           = $480
VRAM_HorizSpike       = $488

; --- Checkpoint & Numbers ---
VRAM_Checkpoint       = $490
VRAM_Numbers          = $4AC

; --- Shields ---
VRAM_Shield           = $4BE
VRAM_LightningSpark   = $4D5
VRAM_Game_Over        = $4DE
VRAM_Perfect          = $4DE   ; shares with Game_Over

; --- Animals & Effects ---
VRAM_Animal_1         = $580   ; squirrel slot
VRAM_Animal_2         = $594   ; bird slot
VRAM_Explosion        = $5A4
VRAM_SonicDust        = $5D0
VRAM_TailsDust        = $5DA
VRAM_Bubbles          = $5E8
VRAM_Invincible_stars = $5F2
VRAM_SuperSonic_stars = $5F2   ; shares with Invincible

; ===========================================================================
; CORE UI ($680-$6CF) - Always loaded
; ===========================================================================
VRAM_CoreUI_Start     = $680
VRAM_Powerups         = $680   ; Monitors (64 tiles)
VRAM_Ring             = $6C0   ; Rings (~14 tiles)
VRAM_HUD              = $6CA   ; HUD elements
VRAM_CoreUI_End       = $6CF

; ===========================================================================
; SHARED POOL ($6D0-$77F) - Mutually exclusive assets
; ===========================================================================
VRAM_SharedPool_Start = $6D0
VRAM_Signpost         = $6D0   ; End of act signpost
VRAM_Capsule          = $6D0   ; Egg prison (shares)
VRAM_TitleCard        = $6D0   ; Level title card (shares)
VRAM_FieryExplosion   = $6D0   ; Boss explosion (shares)
VRAM_ResultsText      = $72E   ; End of level results
VRAM_SharedPool_End   = $77F

; ===========================================================================
; FREE SPACE SUMMARY
; ===========================================================================
; Zone Pool A: $240-$39F = $160 tiles (352 tiles) mostly free
; Zone Pool B: $400-$57F = varies, some gaps between objects
; After Effects: $5F2-$5FF = $E tiles (14 tiles) free
;
; To add new object art:
; 1. Find gap in Zone Pool A or B
; 2. Add constant: VRAM_MyObject = $XXX
; 3. Add PLC: plreq vram_bytes(VRAM_MyObject), ArtNem_MyObject
; 4. Use: move.w #vram_art(VRAM_MyObject,pal,pri), art_tile(a0)
; ===========================================================================
