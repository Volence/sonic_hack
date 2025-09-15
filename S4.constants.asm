; =============================================================================
; Sonic 4 - Constants & IDs (readability pass: comments, sections, spacing)
; =============================================================================

; -----------------------------------------------------------------------------
; Global tunables & sizes
; -----------------------------------------------------------------------------
Max_Rings               = 511             ; default; max possible is 759
    if Max_Rings > 759
        fatal "Maximum number of rings possible is 759"
    endif

Rings_Space             = (Max_Rings+1)*2

; Size variables (bytes). These are informational and checked elsewhere.
Size_of_DAC_samples     	= $2F00
Size_of_SEGA_sound      	= $6174
Size_of_Snd_driver_guess	= $F64           ; post-compress approx size of Z80 driver

; -----------------------------------------------------------------------------
; Object Status Table (OST) offsets
; Applies to everything declared between Object_RAM and Primary_Collision.
; Keep these offsets stable—objects assume these exact fields/alignments.
; -----------------------------------------------------------------------------
; Universal object fields:
id                      = $00             ; word  : object ID (routine selector)
respawnentry            = $02             ; word  : respawn link
mappings                = $04             ; long  : mappings pointer
art_tile                = $08             ; word  : start of art in VRAM
render_flags            = $0A             ; byte  : bit7 onscreen; bit0 x-mirror; bit1 y-mirror; bit2 coord space
collision_response      = $0B             ; byte  : collision type
priority                = $0C             ; word  : sprite priority
width_pixels            = $0E             ; byte  : sprite width (px)
height_pixels           = $0F             ; byte  : sprite height (px)
x_pos                   = $10             ; word  : world X
x_pixel                 = $12             ; word  : subpixel X (hi-precision)
y_pos                   = $14             ; word  : world Y
y_pixel                 = $16             ; word  : subpixel Y (hi-precision)
x_vel                   = $18             ; word  : horizontal velocity
y_vel                   = $1A             ; word  : vertical velocity
next_anim               = $1C             ; byte  : (legacy; being phased out)
anim                    = $1D             ; byte  : current animation
anim_frame              = $1E             ; byte  : current frame index
anim_frame_duration     = $1F             ; byte  : ticks left for current frame
mapping_frame           = $20             ; byte  : current mapping frame
subtype                 = $21             ; byte  : subtype
respawn_index           = $22             ; word  : set via object manager
; New objects should leave $23..$3F free unless documented below.

; Extra helpers added later (kept exactly as in the source):
knuckles_unk            = subtype         ; TBD usage
shield_art              = $24
shield_dplc             = $28
shield_prev_frame       = $2C

; -----------------------------------------------------------------------------
; Sonic/Tails-specific conventions (Obj01, Obj02, ObjDB)
; Note: $1F, $20, $21 are unused and available.
; -----------------------------------------------------------------------------
wind_hover_time         = $23			  ; byte : rames left of hover, sonic only
inertia                 = $24             ; also uses $15; speed mag (not updated in air)
angle                   = $26             ; Z-axis angle (256==360°)
flip_angle              = $27             ; X-axis angle (256==360°) (twist/tumble)
status                  = $28
status2                 = $29
status3                 = $2A             ; 0 normal; 1 hanging/flipper rest; $81 tube/cage/stopper/flying
air_left                = $2B
flips_remaining         = $2C
flip_speed              = $2D             ; flips per frame / 256
move_lock               = $2E             ; also $2F; decrements to unlock
invulnerable_time       = $30             ; also $31
invincibility_time      = $32             ; also $33
speedshoes_time         = $34             ; also $35
next_tilt               = $36             ; ground angle ahead
tilt                    = $37             ; ground angle underfoot
interact_obj            = $38             ; also $39; last platform object
spindash_counter        = $3A             ; also $3B
shields                 = $3C             ; shield flags
air_action              = $3D             ; bounces, glide, etc
layer                   = $3E             ; collision plane / track switch
layer_plus              = $3F             ; typically layer+1 (collision helper)

; -----------------------------------------------------------------------------
; Conventions followed by several non-player objects
; -----------------------------------------------------------------------------
parent                  = $3E             ; also $3F; owner spawner object address

; -----------------------------------------------------------------------------
; Child-sprite layout (when bit6 of render_flags is set)
; -----------------------------------------------------------------------------
mainspr_mapframe        = $0B
mainspr_width           = $0E
mainspr_childsprites    = $0F
mainspr_height          = $14
sub2_x_pos              = $10             ; overlaps x_vel
sub2_y_pos              = $12             ; overlaps y_vel
sub2_mapframe           = $15
sub3_x_pos              = $16             ; overlaps y_radius
sub3_y_pos              = $18             ; overlaps priority
sub3_mapframe           = $1B             ; overlaps anim_frame
sub4_x_pos              = $1C             ; overlaps anim
sub4_y_pos              = $1E             ; overlaps anim_frame_duration
sub4_mapframe           = $21             ; overlaps collision_property
sub5_x_pos              = $22             ; overlaps status
sub5_y_pos              = $24             ; overlaps routine
sub5_mapframe           = $27

; =============================================================================
; Object Status Table (OST) — Misc/overlap offsets (non-Sonic/Tails specific)
; -----------------------------------------------------------------------------
; These are “floating” offsets that some objects use inconsistently or for
; purposes that overlap with standard fields. Keep them grouped here so that
; when you rearrange canonical fields (x_pos/y_pos/etc.), you know which
; aliases derive from them and may also need space preserved.
;
; NOTE:
; - x_pos / y_pos are the canonical OST base fields.
; - Some engines treat them as longwords (position + subpixel), and a few
;   objects sometimes reuse the upper bytes for unrelated scratch.
; - The enum lines below are just convenience equates for raw byte offsets.
;   Do NOT reorder them; many objects rely on these exact values.
; =============================================================================

; --- Aliases that derive from canonical fields (mind the longword cases) -----
objoff_A        =  2 + x_pos     ; caution: if x_pos is a long, this touches the high word
objoff_B        =  3 + x_pos     ; as above; some objects poke here for scratch
objoff_E        =  2 + y_pos
objoff_F        =  3 + y_pos

; --- Raw byte offsets (absolute positions within an OST) ---------------------
objoff_14       =  $14
objoff_15       =  $15
objoff_1F       =  $1F
objoff_27       =  $27
objoff_28       =  $28           ; overlaps 'subtype' in many objects; some reuse it anyway

; Keep these compact: they’re used all over and match existing object code.
 enum               objoff_29=$29,objoff_2A=$2A,objoff_2B=$2B,objoff_2C=$2C,objoff_2D=$2D,objoff_2E=$2E,objoff_2F=$2F
 enum objoff_30=$30,objoff_31=$31,objoff_32=$32,objoff_33=$33,objoff_34=$34,objoff_35=$35,objoff_36=$36,objoff_37=$37
 enum objoff_38=$38,objoff_39=$39,objoff_3A=$3A,objoff_3B=$3B,objoff_3C=$3C,objoff_3D=$3D,objoff_3E=$3E,objoff_3F=$3F

; =============================================================================
; Universal object sizing/alignment
; -----------------------------------------------------------------------------
; object_align defines the power-of-two size class for each OST entry.
; Most engines expect 64-byte objects (align=6), so object_size = 64.
; next_object is an alias used by some allocators/scanners.
; =============================================================================
object_align    =  6
object_size     =  1 << object_align   ; bytes per object (default: 64)
next_object     =  object_size         ; convenience alias

; =============================================================================
; Player status bitfields (status/status2/status3 in OST)
; -----------------------------------------------------------------------------
; Conventions:
;   - s?b_* symbols are *bit indices* (0..7) within the respective status byte.
;   - Masks below (shield_mask / power_mask / lock_mask) are as provided.
;     They’re used with AND/OR against the full byte.
; =============================================================================

; --- status(a0) bits ---------------------------------------------------------
s1b_left           = 0   ; facing left (1) / right (0)
s1b_air            = 1   ; in air (1) / grounded (0)
s1b_ball           = 2   ; in ball (1) / not (0)
s1b_onobject       = 3   ; standing on object (1) / ground (0)
s1b_rolljump       = 4   ; jumping after roll (1) → no horiz control
s1b_pushing        = 5   ; pushing against object
s1b_water          = 6   ; underwater
s1b_7              = 7   ; spare/engine-specific

; --- status2(a0) bits --------------------------------------------------------
s2b_0              = 0
s2b_1              = 1
s2b_2              = 2
s2b_3              = 3
s2b_4              = 4
s2b_doublejump     = 5
s2b_speedshoes     = 6
s2b_nofriction     = 7

; Lower 2 bits of status2(a0) — shield type
; NOTE: mask/del values kept as in original source.
shield_mask        = 2
shield_del         = $FF - shield_mask

shield_none        = 0
shield_water       = 1
shield_fire        = 2
shield_lightning   = 3
shield_wind        = 4

; Next 2 bits of status2(a0) — power state
; NOTE: mask/del values kept as in original source.
power_mask         = $C
power_del          = $FF - power_mask

power_none         = 0
power_invincible   = 4
power_super        = 8
power_hyper        = $C

; --- status3(a0) bits --------------------------------------------------------
s3b_lock_motion    = 0   ; lock movement
s3b_lock_jumping   = 1   ; lock jumping
s3b_flip_turned    = 2   ; flip/tumble flag
s3b_stick_convex   = 3   ; stick to convex surfaces
s3b_spindash       = 4   ; spindash state
s3b_jumping        = 5   ; jumping state

; Lock sub-mask for status3 (kept as provided)
lock_mask          = 3
lock_del           = $FF - lock_mask


; =============================================================================
; Controller Buttons
; -----------------------------------------------------------------------------
; Bit positions correspond to the logical controller words (Ctrl_?_Held_Logical,
; Ctrl_?_Press_Logical, etc.). A mask is (1 << bit).
; =============================================================================

; --- Button bit indices (0..7) ---
button_up:              EQU 0
button_down:            EQU 1
button_left:            EQU 2
button_right:           EQU 3
button_B:               EQU 4
button_C:               EQU 5
button_A:               EQU 6
button_start:           EQU 7

; --- Button masks (1 << bit) ---
button_up_mask:         EQU 1 << button_up        ; $01
button_down_mask:       EQU 1 << button_down      ; $02
button_left_mask:       EQU 1 << button_left      ; $04
button_right_mask:      EQU 1 << button_right     ; $08
button_B_mask:          EQU 1 << button_B         ; $10
button_C_mask:          EQU 1 << button_C         ; $20
button_A_mask:          EQU 1 << button_A         ; $40
button_start_mask:      EQU 1 << button_start     ; $80

; Common composite masks (kept identical to your original intent)
jump_mask:              EQU button_A_mask | button_B_mask | button_C_mask   ; $70

; (Optional convenience — uncomment if useful)
; dpad_mask:            EQU button_up_mask | button_down_mask | button_left_mask | button_right_mask ; $0F
; face_mask:            EQU button_A_mask | button_B_mask | button_C_mask                                      ; $70
; any_mask:             EQU $FF  ; any button

; =============================================================================
; Touch Response Type IDs
; -----------------------------------------------------------------------------
; Encoded in the “collision_response” / touch field for objects.
; Used by the collision system to branch behavior on contact.
; =============================================================================

TR_Enemy:               EQU 1   ; enemy actors (hurts player, can be destroyed)
TR_Boss:                EQU 2   ; boss actors (special handling/HP)
TR_ChkHurt:             EQU 3   ; conditional hurt (depends on state/angle/etc.)
TR_Monitor:             EQU 4   ; item monitor boxes
TR_Ring:                EQU 5   ; collectible rings
TR_Bubble:              EQU 6   ; air bubbles (underwater)
TR_Projectile:          EQU 7   ; free-flying harmful projectiles

TR_MaxIndex:            EQU 7   ; highest valid type ID

; =============================================================================
; Zone IDs (symbolic) + dynamic compatibility IDs
; -----------------------------------------------------------------------------
; Purpose:
;   - Provide symbolic zone constants (e.g., emerald_hill_zone) instead of
;     hard-coded numeric IDs sprinkled throughout the code.
;   - The "id" scheme used elsewhere lets you remove/reorder entries in tables
;     while keeping code readable. This block specifically preserves the
;     *stock Sonic 2 order* so existing zone offset tables remain correct.
;
; Side effects of the macro:
;   - Each call declares the symbol passed (e.g., emerald_hill_zone) to the
;     numeric value given (e.g., $00).
;   - It also defines zone_id_X symbols (where X is the current stock ID) so
;     “zone offset tables” can stay dynamic/position-independent.
;     Example: first expansion defines zone_id_0, second defines zone_id_1, etc.
;
; IMPORTANT:
;   - The order below MUST match stock Sonic 2 zone ID order. Do not reorder.
;   - Some assemblers require support for dynamic symbol names (zone_id_{...}).
;     If your toolchain does not support this, you’ll need a non-macro fallback.
; =============================================================================

; Running counters for the macro
cur_zone_id  := 0          ; numeric zone ID currently being declared
cur_zone_str := "0"        ; string form of cur_zone_id (for zone_id_<N> alias)

; --- Macro: declare a zone ID and its compatibility alias --------------------
; Usage:
;   <symbol> zoneID <hex_id>
;
; Expands to:
;   __LABEL__ = <hex_id>
;   zone_id_<cur_zone_id> = <hex_id>
;   cur_zone_id++, cur_zone_str updated
;
zoneID macro zoneID,{INTLABEL}
__LABEL__                = zoneID
zone_id_{cur_zone_str}   = zoneID
cur_zone_id             := cur_zone_id + 1
cur_zone_str            := "\{cur_zone_id}"
    endm

; --- Zone IDs (stock Sonic 2 order; DO NOT REORDER) --------------------------
emerald_hill_zone     zoneID  $00
zone_1                zoneID  $01
wood_zone             zoneID  $02
zone_3                zoneID  $03
metropolis_zone       zoneID  $04
metropolis_zone_2     zoneID  $05
wing_fortress_zone    zoneID  $06
hill_top_zone         zoneID  $07
hidden_palace_zone    zoneID  $08
zone_9                zoneID  $09
oil_ocean_zone        zoneID  $0A
mystic_cave_zone      zoneID  $0B
casino_night_zone     zoneID  $0C
chemical_plant_zone   zoneID  $0D
death_egg_zone        zoneID  $0E
aquatic_ruin_zone     zoneID  $0F
sky_chase_zone        zoneID  $10

; (When adding a new zone at the end, append a new line with zoneID $11, $12, …)


; =============================================================================
; Zone tables & Act IDs
; -----------------------------------------------------------------------------
; NOTE: If you want to shift IDs around, set `useFullWaterTables` to 1 in the
;       assembly options (your build system will honor those tables).
; =============================================================================

; Total number of zones defined so far (from the zoneID macro section)
no_of_zones               =  cur_zone_id

; -----------------------------------------------------------------------------
; zoneOffsetTable — table header
; -----------------------------------------------------------------------------
; Declares the start of a per-zone table.
; Parameters:
;   entryLen     — size (in bytes) of one entry (e.g., 2 for .w)
;   zoneEntries  — number of entries per zone
; Side effects:
;   - Captures metadata for safety checks and pointer math.
;   - Resets the running zone counter so entries map 1:1 to stock order.
; Usage:
;   Label: zoneOffsetTable 2,1
;     zoneTableEntry.w  <value>              ; per-zone value(s)
;     ...
;   zoneTableEnd
; -----------------------------------------------------------------------------
zoneOffsetTable macro entryLen, zoneEntries, {INTLABEL}
__LABEL__             label *
; Persist table metadata:
zone_table_name      := "__LABEL__"
zone_table_addr      := *
zone_entry_len       := entryLen
zone_entries         := zoneEntries
zone_entries_left    := 0
; Reset per-table zone enumeration (stock order)
cur_zone_id          := 0
cur_zone_str         := "0"
    endm

; -----------------------------------------------------------------------------
; zoneTableEntry — emit entries for current zone
; -----------------------------------------------------------------------------
; Emits one or more entries for the current zone. When a zone is complete,
; advances the output to the correct slot for the next zone. This macro is
; typically called with an attribute suffix via the assembler (e.g., .b/.w/.l)
; as "dc.ATTRIBUTE value" below relies on the suffix provided by the caller.
; -----------------------------------------------------------------------------
zoneTableEntry macro value
    if "VALUE"<>""                       ; ignore empty expansions
        if zone_entries_left
            dc.ATTRIBUTE value
zone_entries_left := zone_entries_left-1
        else
            !org zone_table_addr + zone_id_{cur_zone_str} * zone_entry_len * zone_entries
            dc.ATTRIBUTE value
zone_entries_left := zone_entries-1
cur_zone_id      := cur_zone_id+1
cur_zone_str     := "\{cur_zone_id}"
        endif
        shift
        zoneTableEntry ALLARGS
    endif
    endm

; -----------------------------------------------------------------------------
; zoneTableEnd — finalize table & sanity-check entry count
; -----------------------------------------------------------------------------
; Verifies that the number of zone rows written matches `no_of_zones` and
; restores the PC to the end of the table. Warning only (during pass 1).
; -----------------------------------------------------------------------------
zoneTableEnd macro
    if (cur_zone_id<>no_of_zones)&&(MOMPASS=1)
        message "Warning: Table \{zone_table_name} has \{cur_zone_id/1.0} entries, but it should have \{(no_of_zones)/1.0} entries"
    endif
    !org zone_table_addr + cur_zone_id * zone_entry_len * zone_entries
    endm

; =============================================================================
; Zone + Act IDs (upper byte = zone, lower byte = act)
; -----------------------------------------------------------------------------
; Keep these aligned to the zone constants defined earlier. Do NOT reorder.
; =============================================================================
emerald_hill_zone_act_1    =  (emerald_hill_zone   << 8) | $00
emerald_hill_zone_act_2    =  (emerald_hill_zone   << 8) | $01

chemical_plant_zone_act_1  =  (chemical_plant_zone << 8) | $00
chemical_plant_zone_act_2  =  (chemical_plant_zone << 8) | $01

aquatic_ruin_zone_act_1    =  (aquatic_ruin_zone   << 8) | $00
aquatic_ruin_zone_act_2    =  (aquatic_ruin_zone   << 8) | $01

casino_night_zone_act_1    =  (casino_night_zone   << 8) | $00
casino_night_zone_act_2    =  (casino_night_zone   << 8) | $01

hill_top_zone_act_1        =  (hill_top_zone       << 8) | $00
hill_top_zone_act_2        =  (hill_top_zone       << 8) | $01

mystic_cave_zone_act_1     =  (mystic_cave_zone    << 8) | $00
mystic_cave_zone_act_2     =  (mystic_cave_zone    << 8) | $01

oil_ocean_zone_act_1       =  (oil_ocean_zone      << 8) | $00
oil_ocean_zone_act_2       =  (oil_ocean_zone      << 8) | $01

metropolis_zone_act_1      =  (metropolis_zone     << 8) | $00
metropolis_zone_act_2      =  (metropolis_zone     << 8) | $01
metropolis_zone_act_3      =  (metropolis_zone_2   << 8) | $00

sky_chase_zone_act_1       =  (sky_chase_zone      << 8) | $00
wing_fortress_zone_act_1   =  (wing_fortress_zone  << 8) | $00
death_egg_zone_act_1       =  (death_egg_zone      << 8) | $00

; Prototypes (leave only if referenced elsewhere)
wood_zone_act_1            =  (wood_zone           << 8) | $00
wood_zone_act_2            =  (wood_zone           << 8) | $01
hidden_palace_zone_act_1   =  (hidden_palace_zone  << 8) | $00
hidden_palace_zone_act_2   =  (hidden_palace_zone  << 8) | $01


; =============================================================================
; Game modes
; -----------------------------------------------------------------------------
; Pointer-table based IDs:
;   - offset  : base label of the pointer table (GameModesArray)
;   - ptrsize : size step used for IDs. If table entries are 4 bytes but you
;               want the *byte offset* as the ID, use 1 (so IDs become 0,4,8,...).
;   - idstart : constant added to all computed IDs (usually 0).
; The `id()` function maps a label within the table to an ID based on these.
; =============================================================================

offset  := GameModesArray   ; start of pointer table
ptrsize := 1                ; 1 → IDs are byte offsets (0,4,8,12,...)
idstart := 0                ; add to all IDs (usually 0)

; NOTE: define this helper exactly once in the whole build.
; If you've already defined `id function` earlier, remove the duplicate.
id      function ptr, ((ptr - offset)/ptrsize + idstart)

; --- Computed game mode IDs (byte offsets into GameModesArray) ---------------
GameModeID_SegaScreen      = id(GameMode_SegaScreen)      ; $00
GameModeID_TitleScreen     = id(GameMode_TitleScreen)     ; $04
GameModeID_Demo            = id(GameMode_Demo)            ; $08
GameModeID_Level           = id(GameMode_Level)           ; $0C
GameModeID_ContinueScreen  = id(GameMode_ContinueScreen)  ; $14
GameModeID_EndingSequence  = id(GameMode_EndingSequence)  ; $20
GameModeID_OptionsMenu     = id(GameMode_OptionsMenu)     ; $24
GameModeID_LevelSelect     = id(GameMode_LevelSelect)     ; $28

; --- Title Card flag (bit and mask) ------------------------------------------
GameModeFlag_TitleCard     = 7                            ; bit number
GameModeID_TitleCard       = 1 << GameModeFlag_TitleCard  ; mask


; =============================================================================
; Palette IDs (pointer-table based)
; -----------------------------------------------------------------------------
; Configure id() for the palette pointer table, then derive stable IDs
; from label positions. Keep comments as reference indices (may be stale).
; =============================================================================

offset  := PalPointers     ; start of palette pointer table
ptrsize := 8               ; bytes per entry (pointers are 8 bytes apart)
idstart := 0               ; base added to all IDs (usually 0)

; --- Core / global palettes --------------------------------------------------
PalID_SEGA        = id(PalPtr_SEGA)       ; 0
PalID_Title       = id(PalPtr_Title)      ; 1
PalID_L1          = id(PalPtr_L1)         ; 2
PalID_BGND        = id(PalPtr_BGND)       ; 3

; --- Zone-specific palettes --------------------------------------------------
PalID_EHZ         = id(PalPtr_EHZ)        ; 4
PalID_WFZ         = id(PalPtr_WFZ)        ; 4   ; note: comment index duplicated per original

; --- Menus / UI --------------------------------------------------------------
PalID_Menu        = id(PalPtr_Menu)       ; 26

; --- Variants / underwater / character --------------------------------------
PalID_ARZ_U       = id(PalPtr_ARZ_U)      ; 17
PalID_Knux        = id(PalPtr_Knux)
PalID_EHZ_Top     = id(PalPtr_EHZ_Top)
PalID_EHZ_U       = id(PalPtr_EHZ_U)


; =============================================================================
; PLC IDs (pointer-table based)
; -----------------------------------------------------------------------------
; Configure id() for the PLC pointer table, then derive stable IDs from
; label positions within ArtLoadCues. Comments on the right reflect the
; original index notes (not enforced here).
; =============================================================================

offset   := ArtLoadCues     ; start of PLC pointer table
ptrsize  := 2               ; distance between pointers (bytes)
idstart  := 0               ; base added to all IDs

; -----------------------------------------------------------------------------
; Standard / UI / Common PLCs
; -----------------------------------------------------------------------------
PLCID_Std1             = id(PLCPtr_Std1)            ; 0
PLCID_Std2             = id(PLCPtr_Std2)            ; 1
PLCID_StdWtr           = id(PLCPtr_StdWtr)          ; 2
PLCID_GameOver         = id(PLCPtr_GameOver)        ; 3
PLCID_Results          = id(PLCPtr_Results)         ; 26
PLCID_ResultsTails     = id(PLCPtr_ResultsTails)    ; 42
PLCID_Signpost         = id(PLCPtr_Signpost)        ; 27
PLCID_Capsule          = id(PLCPtr_Capsule)         ; 40
PLCID_Explosion        = id(PLCPtr_Explosion)       ; 41
PLCID_FieryExplosion   = id(PLCPtr_FieryExplosion)  ; 30
PLCID_Tornado          = id(PLCPtr_Tornado)         ; 3F

; Character icons / lives
PLCID_Miles1up         = id(PLCPtr_Miles1up)        ; 6
PLCID_MilesLife        = id(PLCPtr_MilesLife)       ; 7
PLCID_Tails1up         = id(PLCPtr_Tails1up)        ; 8
PLCID_TailsLife        = id(PLCPtr_TailsLife)       ; 9

; -----------------------------------------------------------------------------
; Per-zone “Act 1/2” PLCs
; -----------------------------------------------------------------------------
PLCID_Ehz1             = id(PLCPtr_Ehz1)            ; 4
PLCID_Ehz2             = id(PLCPtr_Ehz2)            ; 5

PLCID_Mtz1             = id(PLCPtr_Mtz1)            ; C
PLCID_Mtz2             = id(PLCPtr_Mtz2)            ; D

PLCID_Wfz1             = id(PLCPtr_Wfz1)            ; 10
PLCID_Wfz2             = id(PLCPtr_Wfz2)            ; 11

PLCID_Htz1             = id(PLCPtr_Htz1)            ; 12
PLCID_Htz2             = id(PLCPtr_Htz2)            ; 13

PLCID_Hpz1             = id(PLCPtr_Hpz1)            ; 14
PLCID_Hpz2             = id(PLCPtr_Hpz2)            ; 15

PLCID_Ooz1             = id(PLCPtr_Ooz1)            ; 18
PLCID_Ooz2             = id(PLCPtr_Ooz2)            ; 19

PLCID_Mcz1             = id(PLCPtr_Mcz1)            ; 1A
PLCID_Mcz2             = id(PLCPtr_Mcz2)            ; 1B

PLCID_Cnz1             = id(PLCPtr_Cnz1)            ; 1C
PLCID_Cnz2             = id(PLCPtr_Cnz2)            ; 1D

PLCID_Cpz1             = id(PLCPtr_Cpz1)            ; 1E
PLCID_Cpz2             = id(PLCPtr_Cpz2)            ; 1F

PLCID_Dez1             = id(PLCPtr_Dez1)            ; 20
PLCID_Dez2             = id(PLCPtr_Dez2)            ; 21

PLCID_Arz1             = id(PLCPtr_Arz1)            ; 22
PLCID_Arz2             = id(PLCPtr_Arz2)            ; 23

PLCID_Scz1             = id(PLCPtr_Scz1)            ; 24
PLCID_Scz2             = id(PLCPtr_Scz2)            ; 25

; Unused slots (kept for compatibility)
PLCID_Unused1          = id(PLCPtr_Unused1)         ; A
PLCID_Unused2          = id(PLCPtr_Unused2)         ; B
PLCID_Unused3          = id(PLCPtr_Unused3)         ; 16
PLCID_Unused4          = id(PLCPtr_Unused4)         ; 17

; -----------------------------------------------------------------------------
; Boss PLCs
; -----------------------------------------------------------------------------
PLCID_CpzBoss          = id(PLCPtr_CpzBoss)         ; 28
PLCID_EhzBoss          = id(PLCPtr_EhzBoss)         ; 29
PLCID_HtzBoss          = id(PLCPtr_HtzBoss)         ; 2A
PLCID_ArzBoss          = id(PLCPtr_ArzBoss)         ; 2B
PLCID_MczBoss          = id(PLCPtr_MczBoss)         ; 2C
PLCID_CnzBoss          = id(PLCPtr_CnzBoss)         ; 2D
PLCID_MtzBoss          = id(PLCPtr_MtzBoss)         ; 2E
PLCID_OozBoss          = id(PLCPtr_OozBoss)         ; 2F
PLCID_DezBoss          = id(PLCPtr_DezBoss)         ; 31
PLCID_WfzBoss          = id(PLCPtr_WfzBoss)         ; 3E

; -----------------------------------------------------------------------------
; Animals (per-zone rescue sets)
; -----------------------------------------------------------------------------
PLCID_EhzAnimals       = id(PLCPtr_EhzAnimals)      ; 32
PLCID_MczAnimals       = id(PLCPtr_MczAnimals)      ; 33
PLCID_HtzAnimals       = id(PLCPtr_HtzAnimals)      ; 34
PLCID_MtzAnimals       = id(PLCPtr_MtzAnimals)      ; 34  ; note: original comment duplicated
PLCID_WfzAnimals       = id(PLCPtr_WfzAnimals)      ; 34  ; note: original comment duplicated
PLCID_DezAnimals       = id(PLCPtr_DezAnimals)      ; 35
PLCID_HpzAnimals       = id(PLCPtr_HpzAnimals)      ; 36
PLCID_OozAnimals       = id(PLCPtr_OozAnimals)      ; 37
PLCID_SczAnimals       = id(PLCPtr_SczAnimals)      ; 38
PLCID_CnzAnimals       = id(PLCPtr_CnzAnimals)      ; 39
PLCID_CpzAnimals       = id(PLCPtr_CpzAnimals)      ; 3A
PLCID_ArzAnimals       = id(PLCPtr_ArzAnimals)      ; 3B

; -----------------------------------------------------------------------------
; Special Stage
; -----------------------------------------------------------------------------
PLCID_SpecialStage     = id(PLCPtr_SpecialStage)    ; 3C
PLCID_SpecStageBombs   = id(PLCPtr_SpecStageBombs)  ; 3D


; =============================================================================
; Music IDs (pointer-table based)
; -----------------------------------------------------------------------------
; Configure id() for the music pointer table, then derive stable IDs from the
; positions under MusicIndex. idstart is $81 so IDs line up with the driver.
; Keep comments showing the hex IDs for quick reference.
; =============================================================================

offset   := MusicIndex      ; start of music pointer table
ptrsize  := 4               ; distance between pointers (bytes)
idstart  := $81             ; base added to all IDs so first becomes $81

; --- 2P / Results ------------------------------------------------------------
MusID_2PResult      = id(MusPtr_2PResult)     ; 81

; --- Zone BGMs ---------------------------------------------------------------
MusID_EHZ           = id(MusPtr_EHZ)          ; 82
MusID_MCZ_2P        = id(MusPtr_MCZ_2P)       ; 83
MusID_OOZ           = id(MusPtr_OOZ)          ; 84
MusID_MTZ           = id(MusPtr_MTZ)          ; 85
MusID_HTZ           = id(MusPtr_HTZ)          ; 86
MusID_ARZ           = id(MusPtr_ARZ)          ; 87
MusID_CNZ_2P        = id(MusPtr_CNZ_2P)       ; 88
MusID_CNZ           = id(MusPtr_CNZ)          ; 89
MusID_DEZ           = id(MusPtr_DEZ)          ; 8A
MusID_MCZ           = id(MusPtr_MCZ)          ; 8B
MusID_EHZ_2P        = id(MusPtr_EHZ_2P)       ; 8C
MusID_SCZ           = id(MusPtr_SCZ)          ; 8D
MusID_CPZ           = id(MusPtr_CPZ)          ; 8E
MusID_WFZ           = id(MusPtr_WFZ)          ; 8F
MusID_HPZ           = id(MusPtr_HPZ)          ; 90

; --- Menus / Special Stages / Bosses ----------------------------------------
MusID_Options       = id(MusPtr_Options)      ; 91
MusID_SpecStage     = id(MusPtr_SpecStage)    ; 92
MusID_Boss          = id(MusPtr_Boss)         ; 93
MusID_EndBoss       = id(MusPtr_EndBoss)      ; 94
MusID_Ending        = id(MusPtr_Ending)       ; 95

; --- States / Powerups / Jingles --------------------------------------------
MusID_SuperSonic    = id(MusPtr_SuperSonic)   ; 96
MusID_Invincible    = id(MusPtr_Invincible)   ; 97
MusID_ExtraLife     = id(MusPtr_ExtraLife)    ; 98

; --- Title / Flow ------------------------------------------------------------
MusID_Title         = id(MusPtr_Title)        ; 99
MusID_EndLevel      = id(MusPtr_EndLevel)     ; 9A
MusID_GameOver      = id(MusPtr_GameOver)     ; 9B
MusID_Continue      = id(MusPtr_Continue)     ; 9C
MusID_Emerald       = id(MusPtr_Emerald)      ; 9D
MusID_Credits       = id(MusPtr_Credits)      ; 9E
MusID_Countdown     = id(MusPtr_Countdown)    ; 9F

; Boundary marker: next index is the first SFX (SoundA0)
MusID__End          = id(SoundA0)             ; A0


; =============================================================================
; Sound IDs (pointer-table based)
; -----------------------------------------------------------------------------
; Configure id() for the SFX pointer table, then derive stable IDs from
; positions under SoundIndex. idstart is $A0 so the first ID maps to $A0.
; =============================================================================

offset   := SoundIndex      ; start of sound pointer table
ptrsize  := 4               ; distance between pointers (bytes)
idstart  := $A0             ; base added so first entry becomes $A0

; -----------------------------------------------------------------------------
; Player / movement / physics
; -----------------------------------------------------------------------------
SndID_Jump               = id(SndPtr_Jump)               ; A0
SndID_Hurt               = id(SndPtr_Hurt)               ; A3
SndID_Skidding           = id(SndPtr_Skidding)           ; A4
SndID_BlockPush          = id(SndPtr_BlockPush)          ; A5
SndID_HurtBySpikes       = id(SndPtr_HurtBySpikes)       ; A6
SndID_Roll               = id(SndPtr_Roll)               ; BE
SndID_SpindashRelease    = id(SndPtr_SpindashRelease)    ; BC
SndID_SpindashRev        = id(SndPtr_SpindashRev)        ; E0

; -----------------------------------------------------------------------------
; UI / rings / checkpoints / posts
; -----------------------------------------------------------------------------
SndID_Checkpoint         = id(SndPtr_Checkpoint)         ; A1
SndID_Ring               = id(SndPtr_Ring)               ; B5
SndID_RingRight          = id(SndPtr_Ring)               ; B5  ; alias
SndID_RingLeft           = id(SndPtr_RingLeft)           ; CE
SndID_Signpost           = id(SndPtr_Signpost)           ; CF
SndID_Signpost2P         = id(SndPtr_Signpost2P)         ; D3
SndID_TallyEnd           = id(SndPtr_TallyEnd)           ; C5
SndID_RingSpill          = id(SndPtr_RingSpill)          ; C6


; -----------------------------------------------------------------------------
; Water / bubbles / drowning
; -----------------------------------------------------------------------------
SndID_Splash             = id(SndPtr_Splash)             ; AA
SndID_InhalingBubble     = id(SndPtr_InhalingBubble)     ; AD
SndID_WaterWarning       = id(SndPtr_WaterWarning)       ; C2

; -----------------------------------------------------------------------------
; Shields / power / pickups / small FX
; -----------------------------------------------------------------------------
SndID_Shield             = id(SndPtr_Shield)             ; AF
SndID_Sparkle            = id(SndPtr_Sparkle)            ; A7
SndID_Beep               = id(SndPtr_Beep)               ; A8
SndID_Bwoop              = id(SndPtr_Bwoop)              ; A9
SndID_Swish              = id(SndPtr_Swish)              ; AB
SndID_Zap                = id(SndPtr_Zap)                ; B1
SndID_FireBurn           = id(SndPtr_FireBurn)           ; B3
SndID_Fire               = id(SndPtr_Fire)               ; DC
SndID_Error              = id(SndPtr_Error)              ; ED
SndID_SuperTransform     = id(SndPtr_SuperTransform)     ; DF

; -----------------------------------------------------------------------------
; Hazards / arrows / spikes / platforms
; -----------------------------------------------------------------------------
SndID_SpikeSwitch        = id(SndPtr_SpikeSwitch)        ; A2
SndID_ArrowFiring        = id(SndPtr_ArrowFiring)        ; AE
SndID_LavaBall           = id(SndPtr_ArrowFiring)        ; AE  ; alias
SndID_SpikesMove         = id(SndPtr_SpikesMove)         ; B6
SndID_SlowSmash          = id(SndPtr_SlowSmash)          ; CB
SndID_Smash              = id(SndPtr_Smash)              ; B9
SndID_PlatformKnock      = id(SndPtr_PlatformKnock)      ; D7
SndID_ArrowStick         = id(SndPtr_ArrowStick)         ; DD
SndID_PreArrowFiring     = id(SndPtr_PreArrowFiring)     ; DB

; -----------------------------------------------------------------------------
; Boss / explosions / lasers
; -----------------------------------------------------------------------------
SndID_BossHit            = id(SndPtr_BossHit)            ; AC
SndID_Drown              = id(SndPtr_Drown)              ; B2
SndID_Explosion          = id(SndPtr_Explosion)          ; C1
SndID_BossExplosion      = id(SndPtr_BossExplosion)      ; C4
SndID_LaserBeam          = id(SndPtr_LaserBeam)          ; B0
SndID_LaserBurst         = id(SndPtr_LaserBurst)         ; EA
SndID_LaserFloor         = id(SndPtr_Scatter)            ; EB  ; alias of Scatter
SndID_LargeLaser         = id(SndPtr_LargeLaser)         ; EF

; -----------------------------------------------------------------------------
; Zone-specific/mechanics FX
; -----------------------------------------------------------------------------
SndID_Bumper             = id(SndPtr_Bumper)             ; B4
SndID_Rumbling           = id(SndPtr_Rumbling)           ; B7
SndID_DoorSlam           = id(SndPtr_DoorSlam)           ; BB
SndID_Hammer             = id(SndPtr_Hammer)             ; BD
SndID_CasinoBonus        = id(SndPtr_CasinoBonus)        ; C0
SndID_Flamethrower       = id(SndPtr_Flamethrower)       ; C8
SndID_SpecStageEntry     = id(SndPtr_SpecStageEntry)     ; CA
SndID_Spring             = id(SndPtr_Spring)             ; CC
SndID_Blip               = id(SndPtr_Blip)               ; CD
SndID_CNZBossZap         = id(SndPtr_CNZBossZap)         ; D0
SndID_OOZLidPop          = id(SndPtr_OOZLidPop)          ; D4
SndID_SlidingSpike       = id(SndPtr_SlidingSpike)       ; D5
SndID_CNZElevator        = id(SndPtr_CNZElevator)        ; D6
SndID_BonusBumper        = id(SndPtr_BonusBumper)        ; D8
SndID_LargeBumper        = id(SndPtr_LargeBumper)        ; D9
SndID_Gloop              = id(SndPtr_Gloop)              ; DA
SndID_HTZLiftClick       = id(SndPtr_HTZLiftClick)       ; E4
SndID_Leaves             = id(SndPtr_Leaves)             ; E5
SndID_MegaMackDrop       = id(SndPtr_MegaMackDrop)       ; E6
SndID_DrawbridgeMove     = id(SndPtr_DrawbridgeMove)     ; E7
SndID_QuickDoorSlam      = id(SndPtr_QuickDoorSlam)      ; E8
SndID_DrawbridgeDown     = id(SndPtr_DrawbridgeDown)     ; E9
SndID_Scatter            = id(SndPtr_Scatter)            ; EB
SndID_Teleport           = id(SndPtr_Teleport)           ; EC
SndID_MechaSonicBuzz     = id(SndPtr_MechaSonicBuzz)     ; EE
SndID_OilSlide           = id(SndPtr_OilSlide)           ; F0
SndID_CNZLaunch          = id(SndPtr_CNZLaunch)          ; E2
SndID_Flipper            = id(SndPtr_Flipper)            ; E3
SndID_Helicopter         = id(SndPtr_Helicopter)         ; DE
SndID_Rumbling2          = id(SndPtr_Rumbling2)          ; E1

; -----------------------------------------------------------------------------
; Special sound IDs (non-table; direct to sound driver control)
; -----------------------------------------------------------------------------
MusID_StopSFX            = $78 + $80                     ; F8
MusID_FadeOut            = $79 + $80                     ; F9
SndID_SegaSound          = $7A + $80                     ; FA
MusID_SpeedUp            = $7B + $80                     ; FB
MusID_SlowDown           = $7C + $80                     ; FC
MusID_Stop               = $7D + $80                     ; FD
MusID_Pause              = $7E + $80                     ; FE
MusID_Unpause            = $7F + $80                     ; FF

; =============================================================================
; Palette sizes
; -----------------------------------------------------------------------------
; MD/Genesis CRAM is organized as 4 lines × 16 colors (total 64 entries).
; Each color is a 1-word (9-bit BGR packed) entry.
; `palette_line_size` is used throughout to size per-line buffers.
; =============================================================================
palette_line_size   = $10   ; 16 word entries per line (32 bytes)


; =============================================================================
; RAM helpers / policy
; =============================================================================

; I run the main 68k RAM addresses through this function
; to let them work in both 16-bit and 32-bit addressing modes.
ramaddr function x,-(-x)&$FFFFFFFF

; =============================================================================
; RAM variables - General
; =============================================================================
	phase	ramaddr($FFFF0000)	; Pretend we're in the RAM
RAM_Start:

; -----------------------------------------------------------------------------
; Foreground/level caches
; -----------------------------------------------------------------------------
Chunk_Table:			ds.b	$8000	; was "Metablock_Table"
Chunk_Table_End:

Level_Layout:			ds.b	$1000
Level_Layout_End:

Block_Table:			ds.w	$C00
Block_Table_End:

; -----------------------------------------------------------------------------
; Deform/convert/sprite input buffers
; -----------------------------------------------------------------------------
TempArray_LayerDef:		ds.b	$200	; used by some layer deformation routines
Decomp_Buffer:			ds.b	$200
Sprite_Table_Input:		ds.b	$400	; custom format before being converted to SAT buffers
Sprite_Table_Input_End:

; =============================================================================
; Object RAM (Main gameplay)
; =============================================================================
Object_RAM:			; The various objects in the game are loaded in this area.
				; Each game mode uses different objects, so some slots are reused.
				; The section below declares labels for the objects used in main gameplay.
				; Objects for other game modes are declared further down.
Reserved_Object_RAM:
MainCharacter:			; first object (usually Sonic except in a Tails Alone game)
				ds.b	object_size
Sidekick:			; second object (Tails in a Sonic and Tails game)
				ds.b	object_size

; --- Level title / GAME OVER / TIME OVER objects ---
TitleCard:
TitleCard_ZoneName:		; level title card: zone name
GameOver_GameText:		; "GAME" from GAME OVER
TimeOver_TimeText:		; "TIME" from TIME OVER
				ds.b	object_size
TitleCard_Zone:			; level title card: "ZONE"
GameOver_OverText:		; "OVER" from GAME OVER
TimeOver_OverText:		; "OVER" from TIME OVER
				ds.b	object_size
TitleCard_ActNumber:		; level title card: act number
				ds.b	object_size
TitleCard_Background:		; level title card: background
				ds.b	object_size
TitleCard_Bottom:		; level title card: yellow part at the bottom
				ds.b	object_size
TitleCard_Left:			; level title card: red part on the left
				ds.b	object_size

BossObject:			; boss controller, signpost or egg prison
				ds.b	object_size

				; Reserved object RAM, free slots
				ds.b	object_size		; [FREE/RECLAIMABLE SLOT]
				ds.b	object_size		; [FREE/RECLAIMABLE SLOT]
				ds.b	object_size		; [FREE/RECLAIMABLE SLOT]
				ds.b	object_size		; [FREE/RECLAIMABLE SLOT]

; --- Water/foreground overlays used in some zones ---
CPZPylon:			; Pylon in the foreground in CPZ
				ds.b	object_size
WaterSurface1:			; First water surface
Oil:				; Oil at the bottom of OOZ
				ds.b	object_size
WaterSurface2:			; Second water surface
				ds.b	object_size
Reserved_Object_RAM_End:

; --- Dynamic object pool (main gameplay) ---
Dynamic_Object_RAM:		; Dynamic object RAM
				ds.b	$28*object_size
Dynamic_Object_RAM_2P_End:	; SingleObjLoad stops searching here in 2P mode
				ds.b	$48*object_size
Dynamic_Object_RAM_End:

; --- Object RAM reserved for level-only persistent helpers (dust/bubbles/shields) ---
LevelOnly_Object_RAM:
Tails_Tails:			; address of the Tail's Tails object
				ds.b	object_size
				; unused slot (was super sonic stars)
				ds.b	object_size		; [FREE/RECLAIMABLE SLOT]
Sonic_BreathingBubbles:		; Sonic's breathing bubbles
				ds.b	object_size
Tails_BreathingBubbles:		; Tails' breathing bubbles
				ds.b	object_size
Sonic_Dust:			; Sonic's spin dash dust
				ds.b	object_size
Tails_Dust:			; Tails' spin dash dust
				ds.b	object_size
				; 2 unused slots (were sonic and tails' shields)
				ds.b	object_size		; [FREE/RECLAIMABLE SLOT]
				ds.b	object_size		; [FREE/RECLAIMABLE SLOT]

Sonic_Shield:
Sonic_InvincibilityStars:
				ds.b	object_size
				ds.b	object_size
				ds.b	object_size
				ds.b	object_size
Tails_Shield:
Tails_InvincibilityStars:
				ds.b	object_size
				ds.b	object_size
				ds.b	object_size
				ds.b	object_size
LevelOnly_Object_RAM_End:

				ds.b	4*object_size		; headroom for loaders/safety margin
Object_RAM_End:

; =============================================================================
; Palettes (underwater)
; =============================================================================
Underwater_palette:		ds.w	palette_line_size
Underwater_palette_line2:	ds.w	palette_line_size
Underwater_palette_line3:	ds.w	palette_line_size
Underwater_palette_line4:	ds.w	palette_line_size

Underwater_palette_2:		ds.w	palette_line_size
Underwater_palette_2_line2:	ds.w	palette_line_size
Underwater_palette_2_line3:	ds.w	palette_line_size
Underwater_palette_2_line4:	ds.w	palette_line_size

; =============================================================================
; Collision planes
; =============================================================================
Primary_Collision:		ds.b	$300
Secondary_Collision:		ds.b	$300

; =============================================================================
; VDP command queue + slot pointer
; =============================================================================
VDP_Command_Buffer:		ds.w	6*$15	; stores 21 ($15) VDP commands to issue the next time ProcessDMAQueue is called
VDP_Command_Buffer_Slot:	ds.l	1	; address of the next open slot for a queued VDP command

; =============================================================================
; 2P SAT + scroll buffers / time/pos recorders
; =============================================================================
Sprite_Table_2:			ds.b	$300	; Sprite attribute table buffer for the bottom split screen in 2-player mode
Horiz_Scroll_Buf:		ds.b	$400
Sonic_Stat_Record_Buf:		ds.b	$100
Sonic_Pos_Record_Buf:		ds.b	$100
Tails_Pos_Record_Buf:		ds.b	$100

; =============================================================================
; CNZ helpers and unused tail
; =============================================================================
CNZ_saucer_data:		ds.b	$40	; bumper group destroy count (10→500 pts logic)
				ds.b	$C0	; $FFFFE740-$FFFFE7FF ; [FREE/UNUSED as far as I can tell — safe scratch outside CNZ]

; =============================================================================
; Ring positions + ring manager temp/equates (ROM-address mirrors + scratch)
; =============================================================================
Ring_Positions:			ds.b	$600
Ring_start_addr_ROM =        ramaddr( Ring_Positions+Rings_Space )
Ring_end_addr_ROM =        ramaddr( Ring_Positions+Rings_Space+4 )
Ring_start_addr_ROM_P2 =    ramaddr( Ring_Positions+Rings_Space+8 )
Ring_end_addr_ROM_P2 =        ramaddr( Ring_Positions+Rings_Space+12 )
Ring_free_RAM_start =        ramaddr( Ring_Positions+Rings_Space+16 )

; =============================================================================
; Camera RAM
; =============================================================================
Camera_RAM:
Camera_X_pos:			ds.l	1
Camera_Y_pos:			ds.l	1
Camera_BG_X_pos:		ds.l	1	; only used sometimes as the layer deformation makes it sort of redundant
Camera_BG_Y_pos:		ds.l	1
Camera_BG2_X_pos:		ds.l	1	; used in CPZ
Camera_BG2_Y_pos:		ds.l	1	; used in CPZ
Camera_BG3_X_pos:		ds.l	1	; unused (only initialised at beginning of level)?
Camera_BG3_Y_pos:		ds.l	1	; unused (only initialised at beginning of level)?
Camera_X_pos_P2:		ds.l	1
Camera_Y_pos_P2:		ds.l	1
				ds.b	$18	; $FFFFEE28-$FFFFEE3F [FILLER/GAP]
Horiz_block_crossed_flag:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary horizontally
Verti_block_crossed_flag:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary vertically
Horiz_block_crossed_flag_BG:	ds.b	1	; toggles between 0 and $10 when background camera crosses a block boundary horizontally
Verti_block_crossed_flag_BG:	ds.b	1	; toggles between 0 and $10 when background camera crosses a block boundary vertically
Horiz_block_crossed_flag_BG2:	ds.b	1	; used in CPZ
				ds.b	3	; [FILLER/GAP]
Horiz_block_crossed_flag_P2:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary horizontally
Verti_block_crossed_flag_P2:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary vertically
				ds.b	6	; [FILLER/GAP]
Scroll_flags:			ds.w	1	; bitfield ; bit 0 = redraw top row, bit 1 = redraw bottom row, bit 2 = redraw left-most column, bit 3 = redraw right-most column
Scroll_flags_BG:		ds.w	1	; bitfield ; bit 0-3 as above, bit 4-7 unknown (used by some deformation routines)
Scroll_flags_BG2:		ds.w	1	; used in CPZ; bit 0-1 unknown
Scroll_flags_BG3:		ds.w	1	; used in CPZ; bit 0-1 unknown
Scroll_flags_P2:		ds.w	1	; bitfield ; bit 0 = redraw top row, bit 1 = redraw bottom row, bit 2 = redraw left-most column, bit 3 = redraw right-most column
				ds.b	6	; [FILLER/GAP]
Camera_RAM_copy:		ds.l	2	; copied over every V-int
Camera_BG_copy:			ds.l	2	; copied over every V-int
Camera_BG2_copy:		ds.l	2	; copied over every V-int
Camera_BG3_copy:		ds.l	2	; copied over every V-int
Camera_P2_copy:			ds.l	8	; copied over every V-int
Scroll_flags_copy:		ds.w	1	; copied over every V-int
Scroll_flags_BG_copy:		ds.w	1	; copied over every V-int
Scroll_flags_BG2_copy:		ds.w	1	; copied over every V-int
Scroll_flags_BG3_copy:		ds.w	1	; copied over every V-int
Scroll_flags_copy_P2:		ds.l	2	; copied over every V-int
Camera_X_pos_diff:		ds.w	1	; (new X pos - old X pos) * 256
Camera_Y_pos_diff:		ds.w	1	; (new Y pos - old Y pos) * 256
				ds.b	4	; [FILLER/GAP]
Camera_X_pos_diff_P2:		ds.w	1	; (new X pos - old X pos) * 256
Camera_Y_pos_diff_P2:		ds.w	1	; (new Y pos - old Y pos) * 256
Screen_Shaking_Flag_HTZ:	ds.b	1	; activates screen shaking code in HTZ's layer deformation routine
Screen_Shaking_Flag:		ds.b	1	; activates screen shaking code (if existent) in layer deformation routine
Scroll_lock:			ds.b	1	; set to 1 to stop all scrolling for P1
Scroll_lock_P2:			ds.b	1	; set to 1 to stop all scrolling for P2
				ds.b	6	; [FILLER/GAP]
Camera_Max_Y_pos:		ds.w	1
Camera_Min_X_pos:		ds.w	1
Camera_Max_X_pos:		ds.w	1
Camera_Min_Y_pos:		ds.w	1
Camera_Max_Y_pos_now:		ds.w	1	; was "Camera_max_scroll_spd"...
Horiz_scroll_delay_val:		ds.w	1	; if its value is a, where a != 0, X scrolling will be based on the player's X position a-1 frames ago
Sonic_Pos_Record_Index:		ds.w	1	; into Sonic_Pos_Record_Buf and Sonic_Stat_Record_Buf
Horiz_scroll_delay_val_P2:	ds.w	1
Tails_Pos_Record_Index:		ds.w	1	; into Tails_Pos_Record_Buf
Camera_Y_pos_bias:		ds.w	1	; added to y position for lookup/lookdown, $60 is center
Camera_Y_pos_bias_P2:		ds.w	1	; for Tails
Deform_lock:			ds.b	1	; set to 1 to stop all deformation
				ds.b	1	; [FILLER/GAP]
				ds.b	1	; [FILLER/GAP]
Dynamic_Resize_Routine:		ds.b	1
				ds.b	$10	; [FILLER/GAP]
Camera_X_pos_copy:		ds.l	1
Camera_Y_pos_copy:		ds.l	1
Tails_Min_X_pos:		ds.w	1
Tails_Max_X_pos:		ds.w	1
				ds.w	1	; [FILLER/GAP]
Tails_Max_Y_pos:		ds.w	1
Camera_RAM_End:

; -----------------------------------------------------------------------------
; Block cache / ring consumption table
; -----------------------------------------------------------------------------
Block_cache:			ds.b	$80
Ring_consumption_table:		ds.b	$80	; contains RAM addresses of rings currently being consumed

; -----------------------------------------------------------------------------
; Legacy S1 driver region (unused in S2)
; -----------------------------------------------------------------------------
				ds.b	$600	; $FFFFF100-$FFFFF5FF ; [FREE/UNUSED — leftover from Sonic 1 sound driver]
					; (Used by it when you port it to Sonic 2). Safe scratch if S1 driver not present.

; =============================================================================
; Input/system vars, V-INT state, water, palette timers
; =============================================================================
Game_Mode:			ds.w	1	; 1 byte ; see GameModesArray (master level trigger, Mstr_Lvl_Trigger)
Ctrl_1_Logical:					; 2 bytes
Ctrl_1_Held_Logical:		ds.b	1	; 1 byte
Ctrl_1_Press_Logical:		ds.b	1	; 1 byte
Ctrl_1:						; 2 bytes
Ctrl_1_Held:			ds.b	1	; 1 byte ; (pressed and held were switched around before)
Ctrl_1_Press:			ds.b	1	; 1 byte
Ctrl_2:						; 2 bytes
Ctrl_2_Held:			ds.b	1	; 1 byte
Ctrl_2_Press:			ds.b	1	; 1 byte
				ds.b	4	; [FILLER/GAP]
VDP_Reg1_val:			ds.w	1	; normal value of VDP register #1 when display is disabled
				ds.b	6	; [FILLER/GAP]
Demo_Time_left:			ds.w	1	; 2 bytes

Vscroll_Factor:			ds.l	1
				ds.b	8	; $FFFFF61A-$FFFFF621 [FILLER/GAP]
Teleport_timer:			ds.b	1	; timer for teleport effect
Teleport_flag:			ds.b	1	; set when a teleport is in progress
Hint_counter_reserve:		ds.w	1	; Must contain a VDP command word, preferably a write to register $0A. Executed every V-INT.

; --- Palette fade control range ---
Palette_fade_range:				; Range affected by the palette fading routines
Palette_fade_start:		ds.b	1	; Offset from the start of the palette to tell what range of the palette will be affected
Palette_fade_length:		ds.b	1	; Number of entries to change
				ds.b	2	; [FILLER/GAP]
Vint_routine:			ds.b	1	; was "Delay_Time" ; routine counter for V-int
				ds.b	1	; [FILLER/GAP]
Sprite_count:			ds.b	1	; the number of sprites drawn in the current frame
				ds.b	5	; [FILLER/GAP]
PalCycle_Frame:			ds.w	1	; ColorID loaded in PalCycle
PalCycle_Timer:			ds.w	1	; number of frames until next PalCycle call
RNG_seed:			ds.l	1	; used for random number generation
Game_paused:			ds.w	1	
				ds.b	4	; [FILLER/GAP]
DMA_data_thunk:			ds.w	1	; Used as a RAM holder for the final DMA command word (volatile across V-INT)
				ds.w	1	; [FILLER/GAP]
Hint_flag:			ds.w	1	; unless this is 1, H-int won't run

; --- Water control (present when level has water/oil) ---
Water_Level_1:			ds.w	1
Water_Level_2:			ds.w	1
Water_Level_3:			ds.w	1
Water_on:			ds.b	1	; is set based on Water_flag
Water_routine:			ds.b	1
Water_fullscreen_flag:		ds.b	1	; was "Water_move"
				ds.b	1	; [FILLER/GAP]

New_Water_Level:		ds.w	1
Water_change_speed:		ds.w	1

				ds.b	8	; [FILLER/GAP]
Palette_frame:			ds.w	1
Palette_timer:			ds.b	1	; was "Palette_frame_count"
Super_Sonic_palette:		ds.b	1
				ds.b	$A	; [FILLER/GAP]

Ctrl_2_Logical:					; 2 bytes
Ctrl_2_Held_Logical:		ds.b	1	; 1 byte
Ctrl_2_Press_Logical:		ds.b	1	; 1 byte
Sonic_Look_delay_counter:	ds.w	1	; 2 bytes
Tails_Look_delay_counter:	ds.w	1	; 2 bytes
Super_Sonic_frame_count:	ds.w	1
				ds.b	$E	; [FILLER/GAP]

Plc_Buffer:			ds.b	$80	; Pattern load queue
Plc_Buffer_End:

; =============================================================================
; Misc variables (object mgr, boss, wind, bonuses...)
; =============================================================================
Misc_Variables:
Wind_Hover_Div2:       ds.b 1   	; flip-flop used to drain Wind hover every other frame
				ds.b	1	; [UNUSED]

; --- Tails CPU (P2 in 1P) helpers ---
Tails_control_counter:		ds.w	1	; how long until the CPU takes control
Tails_respawn_counter:		ds.w	1
				ds.w	1	; [UNUSED]
Tails_CPU_routine:		ds.w	1
Tails_CPU_target_x:		ds.w	1
Tails_CPU_target_y:		ds.w	1
Tails_interact_ID:		ds.b	1	; object ID of last object stood on
				ds.b	1	; [FILLER/GAP]

; --- Rings manager + init flags ---
Rings_manager_routine:		ds.b	1
Level_started_flag:		ds.b	1
Ring_start_addr_RAM =        ramaddr( $FFFFF712 )
Ring_start_addr_RAM_P2 =    ramaddr( $FFFFF714 )
Ring_start_addr:		ds.w	1
Ring_end_addr:			ds.w	1
Ring_start_addr_P2:		ds.w	1
Ring_end_addr_P2:		ds.w	1
CNZ_Bumper_routine:		ds.b	1
				ds.b	$11	; $FFFFF71B-$FFFFF72B [FILLER/GAP]
Dirty_flag:			ds.b	1	; if whole screen needs to redraw
				ds.b	3	; [FILLER/GAP]
Water_flag:			ds.b	1	; if the level has water or oil
				ds.b	1	; [FILLER/GAP]
Demo_button_index_2P:		ds.w	1	; index into button press demo data, for player 2
Demo_press_counter_2P:		ds.w	1	; frames remaining until next button press, for player 2
				ds.b	$A	; [FILLER/GAP]

; --- Boss shared vars ---
Boss_AnimationArray:		ds.b	$10	; up to $10 bytes; 2 bytes per entry
Boss_X_pos:			ds.w	1
				ds.w	1	; Boss_MoveObject reads a long, others use only the high word
Boss_Y_pos:			ds.w	1
				ds.w	1	; same here
Boss_X_vel:			ds.w	1
Boss_Y_vel:			ds.w	1
				ds.w	1	; [FILLER/GAP]
				ds.w	1	; [UNUSED]

; --- Player physics tuning ---
Sonic_top_speed:		ds.w	1
Sonic_acceleration:		ds.w	1
Sonic_deceleration:		ds.w	1
				ds.w	1	; [FILLER/GAP]
				ds.w	1	; [FILLER/GAP]
				ds.w	1	; [FILLER/GAP]
Obj_placement_routine:		ds.b	1
				ds.b	1	; [FILLER/GAP]
Camera_X_pos_last		dc.w	1	; Camera_X_pos_coarse from the previous frame

; --- Object manager load fences (rightmost in-range/out-of-range) ---
;when the objects manager is fully initialized,
Obj_load_addr_0:		ds.l	1	; address of the rightmost out-of-range object (right side)
Obj_load_addr_1:		ds.l	1	; address of the rightmost out-of-range object (left side)
Obj_load_addr_2:		ds.l	1
Obj_load_addr_3:		ds.l	1
				ds.b	$10	; [FILLER/GAP]

; --- Demo controller (P1) ---
Demo_button_index:		ds.w	1	; index into button press demo data, for player 1
Demo_press_counter:		ds.b	1	; frames remaining until next button press, for player 1
				ds.b	3	; [FILLER/GAP]

Collision_addr:			ds.l	1
				ds.b	$D	; [FILLER/GAP]
Boss_defeated_flag:		ds.b	1
				ds.b	2	; [FILLER/GAP]
Current_Boss_ID:		ds.b	1
				ds.b	$1C	; [FILLER/GAP]
WindTunnel_flag:		ds.b	1
				ds.b	4	; [FILLER/GAP]
Control_Locked:			ds.b	1
				ds.b	3	; [FILLER/GAP]

; --- Bonus/state ---
Chain_Bonus_counter:		ds.w	1	; counts up when you destroy things that give points, resets when you touch the ground
Bonus_Countdown_1:		ds.w	1	; level results time bonus or special stage sonic ring bonus
Bonus_Countdown_2:		ds.w	1	; level results ring bonus or special stage tails ring bonus
Update_Bonus_score:		ds.b	1
				ds.b	3	; [FILLER/GAP]
Camera_X_pos_coarse:		ds.w	1	; (Camera_X_pos - 128) / 256
				ds.b	4	; [FILLER/GAP]

ButtonVine_Trigger:		ds.b	$10	; 16 bytes flag array, #subtype byte set when button/vine of respective subtype activated
				ds.b	$10	; $FFFFF7F0-$FFFFF7FF [FILLER/GAP]
Misc_Variables_End:

; =============================================================================
; SAT buffer (P1) + small overflow guard
; =============================================================================
Sprite_Table:			ds.b	$280	; Sprite attribute table buffer
				ds.b	$80	; [UNUSED by default — SAT can spill here when too many sprites]

; =============================================================================
; Palettes (normal + target/second)
; =============================================================================
Normal_palette:			ds.w	palette_line_size
Normal_palette_line2:		ds.w	palette_line_size
Normal_palette_line3:		ds.w	palette_line_size
Normal_palette_line4:		ds.w	palette_line_size
Second_palette:
Target_palette:			ds.w	palette_line_size
Second_palette_line2:
Target_palette_line2:		ds.w	palette_line_size
Second_palette_line3:
Target_palette_line3:		ds.w	palette_line_size
Second_palette_line4:
Target_palette_line4:		ds.w	palette_line_size

; =============================================================================
; Object respawn table
; =============================================================================
Object_Respawn_Table:		ds.b	$180

; =============================================================================
; System stack
; =============================================================================
				ds.b	$80	; Stack
System_Stack:

; =============================================================================
; Level/session flags and HUD mirrors
; =============================================================================
				ds.w	1	; [FILLER/GAP]
Level_Inactive_flag:		ds.w	1	; (2 bytes)
Timer_frames:			ds.w	1	; (2 bytes)
Debug_object:			ds.b	1
				ds.b	1	; [FILLER/GAP]
Debug_placement_mode:		ds.b	1
				ds.b	1	; whole word is tested; only low byte used by debug mode
				ds.b	1	; [FILLER/GAP]
				ds.b	1	; [FILLER/GAP]
Vint_runcount:			ds.l	1

Current_ZoneAndAct:				; 2 bytes
Current_Zone:			ds.b	1	; 1 byte
Current_Act:			ds.b	1	; 1 byte
Life_count:			ds.b	1
				ds.b	3	; [FILLER/GAP]
Current_Special_Stage:		ds.b	1
				ds.b	1	; [FILLER/GAP]
Continue_count:			ds.b	1
				ds.b	1	; old super sonic flag
Time_Over_flag:			ds.b	1
Extra_life_flags:		ds.b	1

; If set, the respective HUD element will be updated.
Update_HUD_lives:		ds.b	1
Update_HUD_rings:		ds.b	1
Update_HUD_timer:		ds.b	1
Update_HUD_score:		ds.b	1

; --- Timer mirrors ---
Ring_count:			ds.w	1	; 2 bytes
Timer:						; 4 bytes
Timer_minute_word:				; 2 bytes
				ds.b	1	; filler
Timer_minute:			ds.b	1	; 1 byte
Timer_second:			ds.b	1	; 1 byte
Timer_centisecond:				; inaccurate name (the seconds increase when this reaches 60)
Timer_frame:			ds.b	1	; 1 byte

Score:				ds.l	1	; 4 bytes
				ds.b	6	; [FILLER/GAP]
Last_star_pole_hit:		ds.b	1	; max activated starpole ID in this act
Saved_Last_star_pole_hit:	ds.b	1
Saved_x_pos:			ds.w	1
Saved_y_pos:			ds.w	1
Saved_Ring_count:		ds.w	1
Saved_Timer:			ds.l	1
Saved_art_tile:			ds.w	1
Saved_layer:			ds.w	1
Saved_Camera_X_pos:		ds.w	1
Saved_Camera_Y_pos:		ds.w	1
Saved_Camera_BG_X_pos:		ds.w	1
Saved_Camera_BG_Y_pos:		ds.w	1
Saved_Camera_BG2_X_pos:		ds.w	1
Saved_Camera_BG2_Y_pos:		ds.w	1
Saved_Camera_BG3_X_pos:		ds.w	1
Saved_Camera_BG3_Y_pos:		ds.w	1
Saved_Water_Level:		ds.w	1
Saved_Water_routine:		ds.b	1
Saved_Water_move:		ds.b	1
Saved_Extra_life_flags:		ds.b	1
Saved_Extra_life_flags_2P:	ds.b	1	; stored, but never restored
Saved_Camera_Max_Y_pos:		ds.w	1
Saved_Dynamic_Resize_Routine:	ds.b	1

				ds.b	$46	; $FFFFFE59-$FFFFFE9E [FILLER/GAP]

AnimalsCounter:			ds.b	1
Logspike_anim_counter:		ds.b	1
Logspike_anim_frame:		ds.b	1
Rings_anim_counter:		ds.b	1
Rings_anim_frame:		ds.b	1
Unknown_anim_counter:		ds.b	1	; (alpha remnant guess)
Unknown_anim_frame:		ds.b	1
Ring_spill_anim_counter:	ds.b	1	; scattered rings
Ring_spill_anim_frame:		ds.b	1
Ring_spill_anim_accum:		ds.w	1
				ds.b	$16	; [FILLER/GAP]

; =============================================================================
; P2 values (2-player / VS)
; =============================================================================
Tails_top_speed:		ds.w	1	; Tails_max_vel
Tails_acceleration:		ds.w	1
Tails_deceleration:		ds.w	1
Life_count_2P:			ds.b	1
Extra_life_flags_2P:		ds.b	1
Update_HUD_lives_2P:		ds.b	1
Update_HUD_rings_2P:		ds.b	1
Update_HUD_timer_2P:		ds.b	1
Update_HUD_score_2P:		ds.b	1	; mostly unused
Time_Over_flag_2P:		ds.b	1
				ds.b	3	; [FILLER/GAP]
Ring_count_2P:			ds.w	1
Timer_2P:					; 4 bytes
Timer_minute_word_2P:				; 2 bytes
				ds.b	1	; filler
Timer_minute_2P:		ds.b	1	; 1 byte
Timer_second_2P:		ds.b	1	; 1 byte
Timer_centisecond_2P:				; inaccurate name (the seconds increase when this reaches 60)
Timer_frame_2P:			ds.b	1	; 1 byte
Score_2P:			ds.l	1
				ds.b	6	; [FILLER/GAP]
Last_star_pole_hit_2P:		ds.b	1
Saved_Last_star_pole_hit_2P:	ds.b	1
Saved_x_pos_2P:			ds.w	1
Saved_y_pos_2P:			ds.w	1
Saved_Ring_count_2P:		ds.w	1
Saved_Timer_2P:			ds.l	1
Saved_art_tile_2P:		ds.w	1
Saved_layer_2P:			ds.w	1
Rings_Collected:		ds.w	1	; number of rings collected during an act in two player mode
Rings_Collected_2P:		ds.w	1
Monitors_Broken:		ds.w	1	; number of monitors broken during an act in two player mode
Monitors_Broken_2P:		ds.w	1
Loser_Time_Left:				; 2 bytes
				ds.b	1	; seconds
				ds.b	1	; frames

				ds.b	$16	; $FFFFFEFA-$FFFFFF09 [FILLER/GAP]
Results_Screen_2P:		ds.w	1	; 0 = act, 1 = zone, 2 = game, 3 = SS, 4 = SS all
				ds.b	$E	; $FFFFFF12-$FFFFFF1F [FILLER/GAP]

Results_Data_2P:				; $18 (24) bytes
EHZ_Results_2P:			ds.b	6	; 6 bytes
MCZ_Results_2P:			ds.b	6	; 6 bytes
CNZ_Results_2P:			ds.b	6	; 6 bytes
SS_Results_2P:			ds.b	6	; 6 bytes
Results_Data_2P_End:

SS_Total_Won:			ds.b	2	; 2 bytes (player 1 then player 2)
				ds.b	6	; [FILLER/GAP]
Perfect_rings_left:		ds.w	1
				ds.b	$2E	; $FFFFFF42-$FFFFFF6F [FILLER/GAP]

; =============================================================================
; Menus/options/state + sound test
; =============================================================================
Player_mode:			ds.w	1	; 0 = Sonic and Tails, 1 = Sonic, 2 = Tails
Player_option:			ds.w	1	; 0 = Sonic and Tails, 1 = Sonic, 2 = Tails

Two_player_items:		ds.w	1
				ds.b	$C	; $FFFFFF76-$FFFFFF81 [FILLER/GAP]
Level_select_zone:		ds.w	1
Sound_test_sound:		ds.w	1
Title_screen_option:		ds.b	1
				ds.b	1	; [UNUSED]
Current_Zone_2P:		ds.b	1
Current_Act_2P:			ds.b	1
Two_player_mode_copy:		ds.w	1
Options_menu_box:		ds.b	1
				ds.b	3	; [FILLER/GAP]
Level_Music:			ds.w	1
				ds.b	6	; [FILLER/GAP]
Game_Over_2P:			ds.w	1
				ds.b	$16	; $FFFFFF9A-$FFFFFFAF [FILLER/GAP]
Got_Emerald:			ds.b	1
Emerald_count:			ds.b	1
Got_Emeralds_array:		ds.b	7	; 7 bytes
				ds.b	7	; filler
Next_Extra_life_score:		ds.l	1
Next_Extra_life_score_2P:	ds.l	1
Level_Has_Signpost:		ds.w	1	; 1 = signpost, 0 = boss or nothing
				ds.b	6	; [FILLER/GAP]
Level_select_flag:		ds.b	1
Slow_motion_flag:		ds.b	1
Night_mode_flag:		ds.w	1
Correct_cheat_entries:		ds.w	1
Correct_cheat_entries_2:	ds.w	1	; for 14 continues or 7 emeralds codes
Two_player_mode:		ds.w	1	; flag (0 for main game)
				ds.b	6	; [FILLER/GAP]

; --- Values passed to the sound driver during V-INT (playlist indices) ---
Music_to_play:			ds.b	1
SFX_to_play:			ds.b	1	; normal
SFX_to_play_2:			ds.b	1	; alternating stereo
				ds.b	1	; [FILLER/GAP]
Music_to_play_2:		ds.b	1	; alternate (higher priority?) slot
				ds.b	$B	; [FILLER/GAP]

; --- Demo mode flags / numbers ---
Demo_mode_flag:			ds.w	1 ; 1 if a demo is playing (2 bytes)
Demo_number:			ds.w	1 ; which demo will play next (2 bytes)
Ending_demo_number:		ds.w	1 ; zone for the ending demos (2 bytes, unused)
				ds.w	1	; [FILLER/GAP]
Graphics_Flags:			ds.w	1 ; misc. bitfield
Debug_mode_flag:		ds.w	1 ; (2 bytes)
Checksum_fourcc:		ds.l	1 ; (4 bytes)

    if * > 0	; Don't declare more space than the RAM can contain!
	fatal "The RAM variable declarations are too large by $\{*} bytes."
    endif

; =============================================================================
; RAM variables - Mode overlays (these reuse Object_RAM and are free otherwise)
; =============================================================================

; ------------------------------ SEGA screen ---------------------------------
	phase	Object_RAM	; Move back to the object RAM
SegaScr_Object_RAM:
				; Unused slot
				ds.b	object_size	; [FREE when not in SEGA]
SegaScreenObject:		; Sega screen
				ds.b	object_size
SonicOnSegaScreen:		; Sonic on Sega screen
				ds.b	object_size

				ds.b	($80-3)*object_size	; [FREE when not in SEGA]
SegaScr_Object_RAM_End:

; ------------------------------ Title screen --------------------------------
	phase	Object_RAM	; Move back to the object RAM
TtlScr_Object_RAM:
				; Unused slot
				ds.b	object_size	; [FREE when not in TITLE]
IntroStars:			; stars on the title screen
				ds.b	object_size
IntroStars6:
				ds.b	object_size
IntroStars2:
TitleScreenPaletteChanger:
				ds.b	object_size
TitleScreenPaletteChanger3:
				ds.b	object_size
IntroStars3:
				ds.b	object_size
IntroStars4:
				ds.b	object_size
IntroStars5:
				ds.b	object_size
IntroStars8:
				ds.b	object_size
TitleScreenPaletteChanger2:
				ds.b	object_size

				ds.b	6*object_size	; [FREE when not in TITLE]

TitleScreenMenu:
				ds.b	object_size
IntroStars7:
				ds.b	object_size

				ds.b	($70-2)*object_size	; [FREE when not in TITLE]
TtlScr_Object_RAM_End:

; ------------------------------ Special stage -------------------------------
	phase	Object_RAM	; Move back to the object RAM
SS_Object_RAM:
				ds.b	object_size
				ds.b	object_size
SpecialStageHUD:		; HUD in the special stage
				ds.b	object_size
SpecialStageStartBanner:
				ds.b	object_size
SpecialStageNumberOfRings:
				ds.b	object_size
SpecialStageShadow_Sonic:
				ds.b	object_size
SpecialStageShadow_Tails:
				ds.b	object_size
SpecialStageTails_Tails:
				ds.b	object_size
SS_Dynamic_Object_RAM:
				ds.b	$18*object_size
SpecialStageResults:
				ds.b	object_size
				ds.b	$C*object_size
SpecialStageResults2:
				ds.b	object_size
				ds.b	$51*object_size
SS_Dynamic_Object_RAM_End:
				ds.b	object_size
SS_Object_RAM_End:

				; The special stage mode also uses the rest of the RAM for
				; different purposes.
PNT_Buffer:			ds.b	$700	; ??? [OVERLAY-LOCAL]
Horiz_Scroll_Buf_2:		ds.b	$900	; ??? [OVERLAY-LOCAL]

; ------------------------------ Continue screen -----------------------------
	phase	Object_RAM	; Move back to the object RAM
ContScr_Object_RAM:
				ds.b	object_size	; [FREE when not in CONTINUE]
				ds.b	object_size	; [FREE when not in CONTINUE]
ContinueText:			; "CONTINUE" on the Continue screen
				ds.b	object_size
ContinueIcons:			; The icons in the Continue screen
				ds.b	$D*object_size

				; Free slots
				ds.b	$70*object_size	; [FREE when not in CONTINUE]
ContScr_Object_RAM_End:

; ------------------------------ 2P VS results -------------------------------
	phase	Object_RAM	; Move back to the object RAM
VSRslts_Object_RAM:
VSResults_HUD:			; Blinking text at the bottom of the screen
				ds.b	object_size

				; Free slots
				ds.b	$7F*object_size	; [FREE when not in VS RESULTS]
VSRslts_Object_RAM_End:

; ------------------------------ Menu screens --------------------------------
	phase	Object_RAM	; Move back to the object RAM
Menus_Object_RAM:		; No objects are loaded in the menu screens
				ds.b	$80*object_size	; [FREE when not in MENUS]
Menus_Object_RAM_End:

; ------------------------------ Ending sequence -----------------------------
	phase	Object_RAM
EndSeq_Object_RAM:
				ds.b	object_size	; [FREE when not in ENDING]
				ds.b	object_size	; [FREE when not in ENDING]
Tails_Tails_Cutscene:		; Tails' tails on the cut scene
				ds.b	object_size
				ds.b	object_size	; [FREE when not in ENDING]
CutScene:
				ds.b	object_size
				ds.b	($80-5)*object_size	; [FREE when not in ENDING]
EndSeq_Object_RAM_End:

	dephase		; Stop pretending

	!org	0	; Reset the program counter


; =============================================================================
; VDP / PSG hardware ports (68000-mapped)
; -----------------------------------------------------------------------------
; Notes:
; • VDP data port ($C00000): read/write VRAM/CRAM/VSRAM after setting an address
;   via the control port. Use word/long transfers for throughput.
; • VDP control port ($C00004): write VDP command words/longs; read status here.
;   Common pattern: move.w/move.l to set VRAM addr/DMA, move.w to read status.
; • PSG input ($C00011): PSG is write-only and **8-bit only** from 68k. Always
;   use move.b; word/long writes will cause bus garbage.
; =============================================================================

; VDP ports
VDP_data_port      = $C00000   ; VDP data (8/16-bit r/w)
VDP_control_port   = $C00004   ; VDP control/status (8/16-bit r/w)

; PSG port
PSG_input          = $C00011   ; PSG write-only (8-bit)


; =============================================================================
; Z80 + I/O chip addresses (from the 68000 side)
; -----------------------------------------------------------------------------
; Notes / gotchas:
; • Z80 RAM is an 8 KiB window at $A00000–$A01FFF (end below is exclusive).
; • To safely read/write Z80 RAM from 68k you must first request the Z80 bus:
;     - Write 1 to Z80_Bus_Request ($A11100), then poll bit 0 until it reads 1.
;     - Access RAM while you own the bus; release by writing 0 when done.
; • Z80 reset control is at $A11200 bit 0 (0 = reset asserted, 1 = running).
; • I/O chip ($A10000 region) registers are byte-wide; use move.b.
;   Many are on odd addresses; avoid word/long writes there.
; =============================================================================

Z80_RAM                 = $A00000   ; start of Z80 work RAM (8 KiB window)
Z80_RAM_End             = $A02000   ; end of Z80 RAM window (exclusive)

; I/O chip (I/O version + pad/exp port control)
Z80_Version             = $A10001   ; I/O/TMSS version (byte, RO)
Z80_Port_1_Data         = $A10002   ; Port 1 data (joypad)
Z80_Port_1_Control      = $A10008   ; Port 1 control
Z80_Port_2_Control      = $A1000A   ; Port 2 control
Z80_Expansion_Control   = $A1000C   ; Expansion port control

; Z80 bus arbitration + reset
Z80_Bus_Request         = $A11100   ; bit0: 1=request/own bus, 0=release
Z80_Reset               = $A11200   ; bit0: 0=hold in reset, 1=run


; =============================================================================
; Misc hardware / global RAM constants
; =============================================================================

; -----------------------------------------------------------------------------
; TMSS security (write "SEGA" here on TMSS-enabled consoles to unlock VDP)
; -----------------------------------------------------------------------------
Security_Addr            = $A14000     ; TMSS security register (requires "SEGA")

; -----------------------------------------------------------------------------
; Palette / camera rounding helpers (RAM)
; -----------------------------------------------------------------------------
Palette_frame_count      = $FFFFF65E   ; (word) frames since last palette step

Camera_X_pos_rounded     = $FFFFEC12   ; (word) camera X rounded/coarse
Camera_Y_pos_rounded     = $FFFFEC14   ; (word) camera Y rounded/coarse
Camera_X_round_value     = $FFFFEC16   ; (word) X rounding granularity/bias
Camera_Y_round_value     = $FFFFEC18   ; (word) Y rounding granularity/bias

; -----------------------------------------------------------------------------
; Horizontal scroll deltas & derived per-layer offsets
; -----------------------------------------------------------------------------

HScroll_LastX             = $FFFFEEB4  ; (word) last camera X used by Scroll_AccumDeltaWithClamp
HScroll_SmoothDelta       = $FFFFEEB6  ; (word) smoothed/clamped horizontal delta accumulator

FG_HScroll_Offset         = $FFFFEE8C  ; (word) FG layer horizontal scroll offset (fine)
Parallax_Mid_Offset       = $FFFFEEE2  ; (word) mid parallax layer horizontal offset
Parallax_Far_Offset       = $FFFFEEE4  ; (word) far parallax layer horizontal offset

; -----------------------------------------------------------------------------
; Vertical row index used for FG redraw decisions
; -----------------------------------------------------------------------------

FG_RowIndex_Y             = $FFFFEE90  ; (word) row-index accumulator from camera Y (≈ y*5/32 + bias)
FG_RowIndex_Y_Prev        = $FFFFEE96  ; (word) previous rounded row-index (used to detect row changes)

; -----------------------------------------------------------------------------
; Act/level transition + misc flags (RAM)
; -----------------------------------------------------------------------------
ActTransitionStartFlag   = $FFFFEC24   ; (word) nonzero when act transition begins
Next_Camera_Max_X_Pos    = $FFFFEC26   ; (word) next act's camera max X limit

Super_Tails_flag         = $FFFFFE19   ; (byte) Tails “super” state flag
LevelUncLayout           = $FFFFEC30   ; (?)   uncompressed level layout base
SonicFlyingFlag          = $FFFFEC35   ; (byte) Sonic flying (tornado/assist) flag
SonicSSFlag              = $FFFFEC36   ; (byte) Sonic in Special Stage flag
; =============================================================================

