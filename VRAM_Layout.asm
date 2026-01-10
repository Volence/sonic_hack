; ===========================================================================
; VRAM LAYOUT MAP & CONSTANTS
; ===========================================================================
; Genesis VDP has 64KB VRAM = 2048 tiles ($000-$7FF)
; Each tile = 32 bytes, so tile_index = byte_address / 32
;
; MEMORY MAP:
; ---------------------------------------------------------------------------
;   $000-$23F : Level foreground art (Kosinski) - varies by zone (max ~$240)
;   $240-$39F : [FREE POOL A] Zone-specific objects (badniks, gimmicks)
;   $3A0-$3FF : Zone objects (PitcherPlant=$3A0, WaterSurface=$400, etc)
;   $400-$4FF : Springs, hazards, checkpoint, numbers, shield
;   $500-$5FF : Effects (animals, explosion, dust, bubbles, stars)
;   $600-$67F : [RESERVED - Scroll plane tiles]
;   $680-$6CF : Core UI (Powerups=$680, Ring=$6BC, HUD=$6CA)
;   $6D0-$77F : Shared pool (signpost, boss, title card, results)
;   $780-$7FF : Character sprites (Sonic/Knux=$780, Tails=$7A0)
; ===========================================================================

; ---------------------------------------------------------------------------
; HELPER MACROS
; ---------------------------------------------------------------------------
; tile_to_bytes: Convert tile index to VDP byte address
; Usage: dc.w tile_to_bytes(VRAM_Ring)
vram_bytes function tile,((tile&$7FF)<<5)

; vram_art: Create art_tile word from tile index + palette + priority
; Usage: move.w #vram_art(VRAM_Explosion,0,0), art_tile(a0)
vram_art function tile,pal,pri,((pri&1)<<15)|((pal&3)<<13)|(tile&$7FF)

; ---------------------------------------------------------------------------
; LEVEL FOREGROUND ART
; ---------------------------------------------------------------------------
VRAM_LevelArt         = $000   ; Level art starts at tile 0
VRAM_LevelArt_MaxEHZ  = $225   ; EHZ uses $225 tiles
VRAM_LevelArt_MaxARZ  = $23F   ; ARZ uses $23F tiles (largest)

; ---------------------------------------------------------------------------
; FREE POOL A: Zone-specific objects ($240-$39F = 352 tiles)
; ---------------------------------------------------------------------------
; Use this space for zone-specific badniks and gimmicks.
; Example allocations:
VRAM_FreePool_Start   = $240
VRAM_FreePool_End     = $39F
; Your custom object here: VRAM_MyBadnik = $250 (then add PLC entry)

; ---------------------------------------------------------------------------
; ZONE-SPECIFIC OBJECTS ($3A0-$43F)
; ---------------------------------------------------------------------------
VRAM_PitcherPlant     = $3A0   ; $7400 bytes - EHZ badnik
VRAM_WaterSurface     = $400   ; $8000 bytes
VRAM_BigBubbles       = $418   ; $8300 bytes
VRAM_DignlSprng       = $440   ; $8800 bytes

; ---------------------------------------------------------------------------
; SPRINGS & HAZARDS ($460-$4FF)
; ---------------------------------------------------------------------------
VRAM_VrtclSprng       = $460   ; $8C00 bytes
VRAM_HrzntlSprng      = $474   ; $8E80 bytes
VRAM_Spikes           = $480   ; $9000 bytes
VRAM_HorizSpike       = $488   ; $9100 bytes
VRAM_Checkpoint       = $490   ; $9200 bytes
VRAM_Numbers          = $4AC   ; $9580 bytes
VRAM_Shield           = $4BE   ; after Numbers
VRAM_LightningSpark   = $4D5   ; $9AA0 bytes - lightning sparks
VRAM_Game_Over        = $4DE   ; $9BC0 bytes
VRAM_Perfect          = $4DE   ; shares with Game_Over

; ---------------------------------------------------------------------------
; EFFECTS & ANIMALS ($580-$5FF)
; ---------------------------------------------------------------------------
VRAM_Animal_1         = $580   ; $B000 bytes (squirrel slot)
VRAM_Animal_2         = $594   ; $B280 bytes (bird slot)
VRAM_Explosion        = $5A4   ; $B480 bytes
VRAM_SonicDust        = $5D0   ; dust effects
VRAM_TailsDust        = $5DA
VRAM_Bubbles          = $5E8   ; $BD00 bytes
VRAM_Invincible_stars = $5F2   ; $BE40 bytes
VRAM_SuperSonic_stars = $5F2   ; shares with Invincible

; ---------------------------------------------------------------------------
; CORE UI ($600-$6CF)
; ---------------------------------------------------------------------------
VRAM_Ring             = $600   ; $C000 bytes - moved to avoid Powerups overlap
VRAM_Powerups         = $680   ; $D000 bytes - monitors (up to ~$6BC)
VRAM_HUD              = $6CA   ; $D940 bytes

; ---------------------------------------------------------------------------
; SHARED POOL ($6D0-$77F) - Mutually exclusive assets
; ---------------------------------------------------------------------------
VRAM_SharedPool       = $6D0
VRAM_Signpost         = $6D0   ; end of act signpost
VRAM_Capsule          = $6D0   ; egg prison
VRAM_TitleCard        = $6D0   ; level title card
VRAM_FieryExplosion   = $6D0   ; boss explosion
VRAM_ResultsText      = $72E   ; end of level results

; ---------------------------------------------------------------------------
; CHARACTER SPRITES ($780-$7FF)
; ---------------------------------------------------------------------------
VRAM_Sonic            = $780   ; $F000 bytes - DMA loaded
VRAM_Knuckles         = $780   ; shares with Sonic
VRAM_Tails            = $7A0   ; $F400 bytes
VRAM_TailsTails       = $7B0   ; $F600 bytes
VRAM_SonicLife        = $7D4   ; $FA80 bytes - life icon
VRAM_TailsLife        = $7D4   ; shares slot
VRAM_KnuxLife         = $7D4   ; shares slot

; ---------------------------------------------------------------------------
; ADDING NEW ART - QUICK GUIDE
; ---------------------------------------------------------------------------
; 1. Find free space in appropriate pool above
; 2. Add constant: VRAM_MyObject = $XXX
; 3. Add PLC entry in "code/Levels/PLC List.asm":
;    plreq vram_bytes(VRAM_MyObject), ArtNem_MyObject
; 4. Use in object code:
;    move.w #vram_art(VRAM_MyObject,0,0), art_tile(a0)
; ---------------------------------------------------------------------------
