Max_Rings = 511 ; default. maximum number possible is 759
    if Max_Rings > 759
    fatal "Maximum number of rings possible is 759"
    endif
 
Rings_Space = (Max_Rings+1)*2
; ---------------------------------------------------------------------------
; size variables - you'll get an informational error if you need to change these...
; they are all in units of bytes
Size_of_DAC_samples =		$2F00
Size_of_SEGA_sound =		$6174
Size_of_Snd_driver_guess =	$F64 ; approximate post-compressed size of the Z80 sound driver

; ---------------------------------------------------------------------------
; Object Status Table offsets (for everything between Object_RAM and Primary_Collision)
; ---------------------------------------------------------------------------
; universally followed object conventions:
id =					0		; word, object ID (the routine it's located at)
respawnentry =			2		; word, if it's spawned
mappings =				4		; long, mappings
art_tile =				8 		; word, start of sprite's art
render_flags =			$A 		; byte, bitfield ; bit 7 = onscreen flag, bit 0 = x mirror, bit 1 = y mirror, bit 2 = coordinate system
collision_response =	$B		; byte, what type of collision the object will have
priority =				$C 		; word, sprite priority (to be upgraded to s3k's for speed)
width_pixels =			$E		; byte, width of object
height_pixels =			$F		; byte, height of object
x_pos =			  		$10 	; word, x position of object
x_pixel =				$12		; word, x position for objects needing extra accuracy
y_pos =			 		$14 	; word, y position of object
y_pixel =				$16 	; word, y position for objects needing extra accuracy
x_vel =					$18 	; word, horizontal velocity
y_vel =					$1A 	; word, vertical velocity
next_anim =		  		$1C 	; byte, working on BEING REMOVED
anim =					$1D		; byte, current animation being displayed
anim_frame =			$1E		; byte, current frame in animation being displayed
anim_frame_duration =	$1F		; byte, how long each animation frame should be
mapping_frame =			$20		; current mapping being displayed
subtype =		 		$21		; byte, subtype of object
respawn_index =		  	$22		; byte, handled via object manager
;	For new objects $23 - $3F should be unused


; ---------------------------------------------------------------------------


; ---------------------------------------------------------------------------
; seem to have been added by Malevolence
knuckles_unk =		subtype ; will probably change when we know what it actually is
shield_art =            $24
shield_dplc =           $28
shield_prev_frame =     $2C
; ---------------------------------------------------------------------------
; conventions specific to sonic/tails (Obj01, Obj02, and ObjDB):
; note: $1F, $20, and $21 are unused and available
inertia =				$24 ; and $15 ; directionless representation of speed... not updated in the air
angle =					$26 ; angle about the z=0 axis (360 degrees = 256)
flip_angle =			$27 ; angle about the x=0 axis (360 degrees = 256) (twist/tumble)
status =				$28 ; note: exact meaning depends on the object... 
status2 =				$29
status3 =				$2A ; 0 for normal, 1 for hanging or for resting on a flipper, $81 for going through CNZ/OOZ/MTZ tubes or stopped in CNZ cages or stoppers or flying if Tails
air_left =				$2B
flips_remaining =		$2C ; number of flip revolutions remaining
flip_speed =			$2D ; number of flip revolutions per frame / 256
move_lock =				$2E ; and $2F ; horizontal control lock, counts down to 0
invulnerable_time =		$30 ; and $31 ; time remaining until you stop blinking
invincibility_time =	$32 ; and $33 ; remaining
speedshoes_time =		$34 ; and $35 ; remaining
next_tilt =				$36 ; angle on ground in front of sprite
tilt =					$37 ; angle on ground
interact_obj =			$38 ; and $39 ; RAM address of the last object Sonic stood on
spindash_counter =		$3A ; and $3B
shields =				$3C ; shield flag
air_action =			$3D ; used by Sonic's bubble bounce and Knuckles' gliding
layer =					$3E ; collision plane, track switching...
layer_plus =			$3F ; always same as layer+1 ?? used for collision somehow
; ---------------------------------------------------------------------------
; conventions followed by several objects but NOT sonic/tails:

parent =		$3E ; and $3F ; address of object that owns or spawned this one, if applicable
; ---------------------------------------------------------------------------
; conventions followed by some/most bosses:
boss_subtype		= $A
boss_invulnerable_time	= $14
boss_routine		= $26	;angle
boss_defeated		= $2C
boss_hitcount2		= $32
boss_hurt_sonic		= $38	; flag set by collision response routine when sonic has just been hurt (by boss?)
; ---------------------------------------------------------------------------
; when childsprites are activated (i.e. bit #6 of render_flags set)
mainspr_mapframe	= $B
mainspr_width		= $E
mainspr_childsprites 	= $F	; amount of child sprites
mainspr_height		= $14
sub2_x_pos		= $10	;x_vel
sub2_y_pos		= $12	;y_vel
sub2_mapframe		= $15
sub3_x_pos		= $16	;y_radius
sub3_y_pos		= $18	;priority
sub3_mapframe		= $1B	;anim_frame
sub4_x_pos		= $1C	;anim
sub4_y_pos		= $1E	;anim_frame_duration
sub4_mapframe		= $21	;collision_property
sub5_x_pos		= $22	;status
sub5_y_pos		= $24	;routine
sub5_mapframe		= $27
; ---------------------------------------------------------------------------
; unknown or inconsistently used offsets that are not applicable to sonic/tails:
; (provided because rearrangement of the above values sometimes requires making space in here too)
objoff_A =		2+x_pos ; note: x_pos can be 4 bytes, but sometimes the last 2 bytes of x_pos are used for other unrelated things
objoff_B =		3+x_pos
objoff_E =		2+y_pos
objoff_F =		3+y_pos
objoff_14 =		$14
objoff_15 =		$15
objoff_1F =		$1F
objoff_27 =		$27
objoff_28 =		$28 ; overlaps subtype, but a few objects use it for other things anyway
 enum               objoff_29=$29,objoff_2A=$2A,objoff_2B=$2B,objoff_2C=$2C,objoff_2D=$2D,objoff_2E=$2E,objoff_2F=$2F
 enum objoff_30=$30,objoff_31=$31,objoff_32=$32,objoff_33=$33,objoff_34=$34,objoff_35=$35,objoff_36=$36,objoff_37=$37
 enum objoff_38=$38,objoff_39=$39,objoff_3A=$3A,objoff_3B=$3B,objoff_3C=$3C,objoff_3D=$3D,objoff_3E=$3E,objoff_3F=$3F
; ---------------------------------------------------------------------------
; property of all objects:
object_align =		6
object_size =		1<<object_align ; the size of an object
next_object =		object_size

; ---------------------------------------------------------------------------
; bitfields
; for status(a0) for player characters
s1b_left		= 0	; set if facing left, clear if facing right
s1b_air			= 1	; set if in the air, clear if on the ground
s1b_ball		= 2	; set if in a ball, clear otherwise
s1b_onobject		= 3	; set if standing on an object (as opposed to the ground)
s1b_rolljump		= 4	; set if jumping after rolling (thus cannot control horizontal movement)
s1b_pushing		= 5	; set if pushing on an object
s1b_water		= 6	; set if underwater
s1b_7			= 7

; for status2(a0) for player characters
s2b_0			= 0
s2b_1			= 1
s2b_2			= 2
s2b_3			= 3
s2b_4			= 4
s2b_doublejump		= 5
s2b_speedshoes		= 6
s2b_nofriction		= 7

; lower 2 bits of status2(a0)
shield_mask		= 3
shield_del		= $FF-shield_mask

shield_none		= 0
shield_water		= 1
shield_fire		= 2
shield_lightning	= 3
shield_wind		= 4

; next 2 bits of status2(a0)
power_mask		= $C
power_del		= $FF-power_mask

power_none		= 0
power_invincible	= 4
power_super		= 8
power_hyper		= $C

; for status3(a0) for player characters
s3b_lock_motion		= 0
s3b_lock_jumping	= 1
s3b_flip_turned		= 2
s3b_stick_convex	= 3
s3b_spindash		= 4
s3b_jumping		= 5

lock_mask		= 3
lock_del		= $FF-lock_mask

; ---------------------------------------------------------------------------
; Controller Buttons
;
; Buttons bit numbers
button_up:			EQU	0
button_down:			EQU	1
button_left:			EQU	2
button_right:			EQU	3
button_B:			EQU	4
button_C:			EQU	5
button_A:			EQU	6
button_start:			EQU	7
; Buttons masks (1 << x == pow(2, x))
button_up_mask:			EQU	1<<button_up	; $01
button_down_mask:		EQU	1<<button_down	; $02
button_left_mask:		EQU	1<<button_left	; $04
button_right_mask:		EQU	1<<button_right	; $08
button_B_mask:			EQU	1<<button_B	; $10
button_C_mask:			EQU	1<<button_C	; $20
button_A_mask:			EQU	1<<button_A	; $40
button_start_mask:		EQU	1<<button_start	; $80

; ---------------------------------------------------------------------------
; Constants that can be used instead of hard-coded IDs for various things.
; The "id" function allows to remove elements from an array/table without having
; to change the IDs everywhere in the code.

cur_zone_id := 0 ; the zone ID currently being declared
cur_zone_str := "0" ; string representation of the above

; macro to declare a zone ID
; this macro also declares constants of the form zone_id_X, where X is the ID of the zone in stock Sonic 2
; in order to allow level offset tables to be made dynamic
zoneID macro zoneID,{INTLABEL}
__LABEL__ = zoneID
zone_id_{cur_zone_str} = zoneID
cur_zone_id := cur_zone_id+1
cur_zone_str := "\{cur_zone_id}"
    endm

; Zone IDs. These MUST be declared in the order in which their IDs are in stock Sonic 2, otherwise zone offset tables will screw up
emerald_hill_zone zoneID	$00
zone_1 zoneID			$01
wood_zone zoneID		$02
zone_3 zoneID			$03
metropolis_zone zoneID		$04
metropolis_zone_2 zoneID	$05
wing_fortress_zone zoneID	$06
hill_top_zone zoneID		$07
hidden_palace_zone zoneID	$08
zone_9 zoneID			$09
oil_ocean_zone zoneID		$0A
mystic_cave_zone zoneID		$0B
casino_night_zone zoneID	$0C
chemical_plant_zone zoneID	$0D
death_egg_zone zoneID		$0E
aquatic_ruin_zone zoneID	$0F
sky_chase_zone zoneID		$10

; NOTE: If you want to shift IDs around, set useFullWaterTables to 1 in the assembly options

; set the number of zones
no_of_zones = cur_zone_id

; macro to declare a zone offset table
; entryLen is the length of each table entry, and zoneEntries is the number of entries per zone
zoneOffsetTable macro entryLen,zoneEntries,{INTLABEL}
__LABEL__ label *
; set some global variables
zone_table_name := "__LABEL__"
zone_table_addr := *
zone_entry_len := entryLen
zone_entries := zoneEntries
zone_entries_left := 0
cur_zone_id := 0
cur_zone_str := "0"
    endm

; macro to declare one or more entries in a zone offset table
zoneTableEntry macro value
	if "VALUE"<>""
	    if zone_entries_left
		dc.ATTRIBUTE value
zone_entries_left := zone_entries_left-1
	    else
		!org zone_table_addr+zone_id_{cur_zone_str}*zone_entry_len*zone_entries
		dc.ATTRIBUTE value
zone_entries_left := zone_entries-1
cur_zone_id := cur_zone_id+1
cur_zone_str := "\{cur_zone_id}"
	    endif
	    shift
	    zoneTableEntry ALLARGS
	endif
    endm

; macro which sets the PC to the correct value at the end of a zone offset table and checks if the correct
; number of entries were declared
zoneTableEnd macro
	if (cur_zone_id<>no_of_zones)&&(MOMPASS=1)
	    message "Warning: Table \{zone_table_name} has \{cur_zone_id/1.0} entries, but it should have \{(no_of_zones)/1.0} entries"
	endif
	!org zone_table_addr+cur_zone_id*zone_entry_len*zone_entries
    endm

; Zone and act IDs
emerald_hill_zone_act_1 =	(emerald_hill_zone<<8)|$00
emerald_hill_zone_act_2 =	(emerald_hill_zone<<8)|$01
chemical_plant_zone_act_1 =	(chemical_plant_zone<<8)|$00
chemical_plant_zone_act_2 =	(chemical_plant_zone<<8)|$01
aquatic_ruin_zone_act_1 =	(aquatic_ruin_zone<<8)|$00
aquatic_ruin_zone_act_2 =	(aquatic_ruin_zone<<8)|$01
casino_night_zone_act_1 =	(casino_night_zone<<8)|$00
casino_night_zone_act_2 =	(casino_night_zone<<8)|$01
hill_top_zone_act_1 =		(hill_top_zone<<8)|$00
hill_top_zone_act_2 =		(hill_top_zone<<8)|$01
mystic_cave_zone_act_1 =	(mystic_cave_zone<<8)|$00
mystic_cave_zone_act_2 =	(mystic_cave_zone<<8)|$01
oil_ocean_zone_act_1 =		(oil_ocean_zone<<8)|$00
oil_ocean_zone_act_2 =		(oil_ocean_zone<<8)|$01
metropolis_zone_act_1 =		(metropolis_zone<<8)|$00
metropolis_zone_act_2 =		(metropolis_zone<<8)|$01
metropolis_zone_act_3 =		(metropolis_zone_2<<8)|$00
sky_chase_zone_act_1 =		(sky_chase_zone<<8)|$00
wing_fortress_zone_act_1 =	(wing_fortress_zone<<8)|$00
death_egg_zone_act_1 =		(death_egg_zone<<8)|$00
; Prototype zone and act IDs
wood_zone_act_1 =		(wood_zone<<8)|$00
wood_zone_act_2 =		(wood_zone<<8)|$01
hidden_palace_zone_act_1 =	(hidden_palace_zone<<8)|$00
hidden_palace_zone_act_2 =	(hidden_palace_zone<<8)|$01

; Game modes

; some variables to help define those constants (redefined before a new set of IDs)
offset :=	GameModesArray	; this is the start of the pointer table
ptrsize :=	1		; this is the size of a pointer (should be 1 if the ID is a multiple of the actual size)
idstart :=	0		; value to add to all IDs

; function using these variables
id function ptr,((ptr-offset)/ptrsize+idstart)

GameModeID_SegaScreen =		id(GameMode_SegaScreen) ; 0
GameModeID_TitleScreen =	id(GameMode_TitleScreen) ; 4
GameModeID_Demo =		id(GameMode_Demo) ; 8
GameModeID_Level =		id(GameMode_Level) ; C
GameModeID_ContinueScreen =	id(GameMode_ContinueScreen) ; 14
GameModeID_EndingSequence =	id(GameMode_EndingSequence) ; 20
GameModeID_OptionsMenu =	id(GameMode_OptionsMenu) ; 24
GameModeID_LevelSelect =	id(GameMode_LevelSelect) ; 28
GameModeFlag_TitleCard =	7 ; flag bit
GameModeID_TitleCard =		1<<GameModeFlag_TitleCard ; flag mask

; palette IDs
offset :=	PalPointers
ptrsize :=	8
idstart :=	0

PalID_SEGA =	id(PalPtr_SEGA) ; 0
PalID_Title =	id(PalPtr_Title) ; 1
PalID_L1 =	id(PalPtr_L1) ; 2
PalID_BGND =	id(PalPtr_BGND) ; 3
PalID_EHZ =	id(PalPtr_EHZ) ; 4
PalID_WFZ =	id(PalPtr_WFZ) ; 4
PalID_Menu =	id(PalPtr_Menu) ; 26
PalID_ARZ_U =	id(PalPtr_ARZ_U) ; 17
PalID_Knux =	id(PalPtr_Knux)
PalID_EHZ_Top =	id(PalPtr_EHZ_Top)
PalID_EHZ_U =	id(PalPtr_EHZ_U)

; PLC IDs
offset :=	ArtLoadCues
ptrsize :=	2
idstart :=	0

PLCID_Std1 =		id(PLCPtr_Std1) ; 0
PLCID_Std2 =		id(PLCPtr_Std2) ; 1
PLCID_StdWtr =		id(PLCPtr_StdWtr) ; 2
PLCID_GameOver =	id(PLCPtr_GameOver) ; 3
PLCID_Ehz1 =		id(PLCPtr_Ehz1) ; 4
PLCID_Ehz2 =		id(PLCPtr_Ehz2) ; 5
PLCID_Miles1up =	id(PLCPtr_Miles1up) ; 6
PLCID_MilesLife =	id(PLCPtr_MilesLife) ; 7
PLCID_Tails1up =	id(PLCPtr_Tails1up) ; 8
PLCID_TailsLife =	id(PLCPtr_TailsLife) ; 9
PLCID_Unused1 =		id(PLCPtr_Unused1) ; A
PLCID_Unused2 =		id(PLCPtr_Unused2) ; B
PLCID_Mtz1 =		id(PLCPtr_Mtz1) ; C
PLCID_Mtz2 =		id(PLCPtr_Mtz2) ; D
PLCID_Wfz1 =		id(PLCPtr_Wfz1) ; 10
PLCID_Wfz2 =		id(PLCPtr_Wfz2) ; 11
PLCID_Htz1 =		id(PLCPtr_Htz1) ; 12
PLCID_Htz2 =		id(PLCPtr_Htz2) ; 13
PLCID_Hpz1 =		id(PLCPtr_Hpz1) ; 14
PLCID_Hpz2 =		id(PLCPtr_Hpz2) ; 15
PLCID_Unused3 =		id(PLCPtr_Unused3) ; 16
PLCID_Unused4 =		id(PLCPtr_Unused4) ; 17
PLCID_Ooz1 =		id(PLCPtr_Ooz1) ; 18
PLCID_Ooz2 =		id(PLCPtr_Ooz2) ; 19
PLCID_Mcz1 =		id(PLCPtr_Mcz1) ; 1A
PLCID_Mcz2 =		id(PLCPtr_Mcz2) ; 1B
PLCID_Cnz1 =		id(PLCPtr_Cnz1) ; 1C
PLCID_Cnz2 =		id(PLCPtr_Cnz2) ; 1D
PLCID_Cpz1 =		id(PLCPtr_Cpz1) ; 1E
PLCID_Cpz2 =		id(PLCPtr_Cpz2) ; 1F
PLCID_Dez1 =		id(PLCPtr_Dez1) ; 20
PLCID_Dez2 =		id(PLCPtr_Dez2) ; 21
PLCID_Arz1 =		id(PLCPtr_Arz1) ; 22
PLCID_Arz2 =		id(PLCPtr_Arz2) ; 23
PLCID_Scz1 =		id(PLCPtr_Scz1) ; 24
PLCID_Scz2 =		id(PLCPtr_Scz2) ; 25
PLCID_Results =		id(PLCPtr_Results) ; 26
PLCID_Signpost =	id(PLCPtr_Signpost) ; 27
PLCID_CpzBoss =		id(PLCPtr_CpzBoss) ; 28
PLCID_EhzBoss =		id(PLCPtr_EhzBoss) ; 29
PLCID_HtzBoss =		id(PLCPtr_HtzBoss) ; 2A
PLCID_ArzBoss =		id(PLCPtr_ArzBoss) ; 2B
PLCID_MczBoss =		id(PLCPtr_MczBoss) ; 2C
PLCID_CnzBoss =		id(PLCPtr_CnzBoss) ; 2D
PLCID_MtzBoss =		id(PLCPtr_MtzBoss) ; 2E
PLCID_OozBoss =		id(PLCPtr_OozBoss) ; 2F
PLCID_FieryExplosion =	id(PLCPtr_FieryExplosion) ; 30
PLCID_DezBoss =		id(PLCPtr_DezBoss) ; 31
PLCID_EhzAnimals =	id(PLCPtr_EhzAnimals) ; 32
PLCID_MczAnimals =	id(PLCPtr_MczAnimals) ; 33
PLCID_HtzAnimals =	id(PLCPtr_HtzAnimals) ; 34
PLCID_MtzAnimals =	id(PLCPtr_MtzAnimals) ; 34
PLCID_WfzAnimals =	id(PLCPtr_WfzAnimals) ; 34
PLCID_DezAnimals =	id(PLCPtr_DezAnimals) ; 35
PLCID_HpzAnimals =	id(PLCPtr_HpzAnimals) ; 36
PLCID_OozAnimals =	id(PLCPtr_OozAnimals) ; 37
PLCID_SczAnimals =	id(PLCPtr_SczAnimals) ; 38
PLCID_CnzAnimals =	id(PLCPtr_CnzAnimals) ; 39
PLCID_CpzAnimals =	id(PLCPtr_CpzAnimals) ; 3A
PLCID_ArzAnimals =	id(PLCPtr_ArzAnimals) ; 3B
PLCID_SpecialStage =	id(PLCPtr_SpecialStage) ; 3C
PLCID_SpecStageBombs =	id(PLCPtr_SpecStageBombs) ; 3D
PLCID_WfzBoss =		id(PLCPtr_WfzBoss) ; 3E
PLCID_Tornado =		id(PLCPtr_Tornado) ; 3F
PLCID_Capsule =		id(PLCPtr_Capsule) ; 40
PLCID_Explosion =	id(PLCPtr_Explosion) ; 41
PLCID_ResultsTails =	id(PLCPtr_ResultsTails) ; 42

; Object IDs
offset :=	Obj_Index
ptrsize :=	4
idstart :=	1

;ObjID_Sonic =			id(ObjPtr_Sonic)		; 01
;ObjID_Tails =			id(ObjPtr_Tails)		; 02
;ObjID_PlaneSwitcher =		id(ObjPtr_PlaneSwitcher)	; 03
;ObjID_WaterSurface =		id(ObjPtr_WaterSurface)		; 04
;ObjID_TailsTails =		id(ObjPtr_TailsTails)		; 05
;ObjID_Spiral =			id(ObjPtr_Spiral)		; 06
;ObjID_Oil =			id(ObjPtr_Oil)			; 07
;ObjID_SpindashDust =		id(ObjPtr_SpindashDust)		; 08
;ObjID_Splash =			id(ObjPtr_Splash)		; 08
;ObjID_SonicSS =			id(ObjPtr_SonicSS)		; 09
;ObjID_SmallBubbles =		id(ObjPtr_SmallBubbles)		; 0A
;ObjID_TippingFloor =		id(ObjPtr_TippingFloor)		; 0B
;ObjID_Signpost =		id(ObjPtr_Signpost)		; 0D
;ObjID_IntroStars =		id(ObjPtr_IntroStars)		; 0E
;ObjID_TitleMenu =		id(ObjPtr_TitleMenu)		; 0F
;ObjID_TailsSS =			id(ObjPtr_TailsSS)		; 10
;ObjID_Bridge =			id(ObjPtr_Bridge)		; 11
;ObjID_HPZEmerald =		id(ObjPtr_HPZEmerald)		; 12
;ObjID_HPZWaterfall =		id(ObjPtr_HPZWaterfall)		; 13
;ObjID_Seesaw =			id(ObjPtr_Seesaw)		; 14
;ObjID_SwingingPlatform =	id(ObjPtr_SwingingPlatform)	; 15
;ObjID_HTZLift =			id(ObjPtr_HTZLift)		; 16
;ObjID_ARZPlatform =		id(ObjPtr_ARZPlatform)		; 18
;ObjID_EHZPlatform =		id(ObjPtr_EHZPlatform)		; 18
;ObjID_CPZPlatform =		id(ObjPtr_CPZPlatform)		; 19
;ObjID_OOZMovingPform =		id(ObjPtr_OOZMovingPform)	; 19
;ObjID_WFZPlatform =		id(ObjPtr_WFZPlatform)		; 19
;ObjID_HPZCollapsPform =		id(ObjPtr_HPZCollapsPform)	; 1A
;ObjID_SpeedBooster =		id(ObjPtr_SpeedBooster)		; 1B
;ObjID_Scenery =			id(ObjPtr_Scenery)		; 1C
;ObjID_BridgeStake =		id(ObjPtr_BridgeStake)		; 1C
;ObjID_FallingOil =		id(ObjPtr_FallingOil)		; 1C
;ObjID_BlueBalls =		id(ObjPtr_BlueBalls)		; 1D
;ObjID_CPZSpinTube =		id(ObjPtr_CPZSpinTube)		; 1E
;ObjID_CollapsPform =		id(ObjPtr_CollapsPform)		; 1F
;ObjID_LavaBubble =		id(ObjPtr_LavaBubble)		; 20
;ObjID_HUD =			id(ObjPtr_HUD)			; 21
;ObjID_ArrowShooter =		id(ObjPtr_ArrowShooter)		; 22
;ObjID_FallingPillar =		id(ObjPtr_FallingPillar)	; 23
;ObjID_ARZBubbles =		id(ObjPtr_ARZBubbles)		; 24
;ObjID_Ring =			id(ObjPtr_Ring)			; 25
;ObjID_Monitor =			id(ObjPtr_Monitor)		; 26
;ObjID_Explosion =		id(ObjPtr_Explosion)		; 27
;ObjID_Animal =			id(ObjPtr_Animal)		; 28
;ObjID_Points =			id(ObjPtr_Points)		; 29
;ObjID_Stomper =			id(ObjPtr_Stomper)		; 2A
;ObjID_RisingPillar =		id(ObjPtr_RisingPillar)		; 2B
;ObjID_LeavesGenerator =		id(ObjPtr_LeavesGenerator)	; 2C
;ObjID_Barrier =			id(ObjPtr_Barrier)		; 2D
;ObjID_MonitorContents =		id(ObjPtr_MonitorContents)	; 2E
;ObjID_SmashableGround =		id(ObjPtr_SmashableGround)	; 2F
;ObjID_RisingLava =		id(ObjPtr_RisingLava)		; 30
;ObjID_LavaMarker =		id(ObjPtr_LavaMarker)		; 31
;ObjID_BreakableBlock =		id(ObjPtr_BreakableBlock)	; 32
;ObjID_BreakableRock =		id(ObjPtr_BreakableRock)	; 32
;ObjID_OOZPoppingPform =		id(ObjPtr_OOZPoppingPform)	; 33
;ObjID_TitleCard =		id(ObjPtr_TitleCard)		; 34
;ObjID_InvStars =		id(ObjPtr_InvStars)		; 35
;ObjID_Spikes =			id(ObjPtr_Spikes)		; 36
;ObjID_LostRings =		id(ObjPtr_LostRings)		; 37
;ObjID_Shield =			id(ObjPtr_Shield)		; 38
;ObjID_GameOver =		id(ObjPtr_GameOver)		; 39
;ObjID_TimeOver =		id(ObjPtr_TimeOver)		; 39
;ObjID_Results =			id(ObjPtr_Results)		; 3A
;ObjID_SolidBlock =		id(ObjPtr_SolidBlock)		; 3B
;ObjID_OOZLauncher =		id(ObjPtr_OOZLauncher)		; 3D
;ObjID_EggPrison =		id(ObjPtr_EggPrison)		; 3E
;ObjID_Fan =			id(ObjPtr_Fan)			; 3F
;ObjID_Springboard =		id(ObjPtr_Springboard)		; 40
;ObjID_Spring =			id(ObjPtr_Spring)		; 41
;ObjID_SteamSpring =		id(ObjPtr_SteamSpring)		; 42
;ObjID_SlidingSpike =		id(ObjPtr_SlidingSpike)		; 43
;ObjID_RoundBumper =		id(ObjPtr_RoundBumper)		; 44
;ObjID_OOZSpring =		id(ObjPtr_OOZSpring)		; 45
;ObjID_OOZBall =			id(ObjPtr_OOZBall)		; 46
;ObjID_Button =			id(ObjPtr_Button)		; 47
;ObjID_LauncherBall =		id(ObjPtr_LauncherBall)		; 48
;ObjID_EHZWaterfall =		id(ObjPtr_EHZWaterfall)		; 49
;ObjID_Octus =			id(ObjPtr_Octus)		; 4A
;ObjID_Buzzer =			id(ObjPtr_Buzzer)		; 4B
;ObjID_Aquis =			id(ObjPtr_Aquis)		; 50
;ObjID_CNZBoss =			id(ObjPtr_CNZBoss)		; 51
;ObjID_HTZBoss =			id(ObjPtr_HTZBoss)		; 52
;ObjID_MTZBossOrb =		id(ObjPtr_MTZBossOrb)		; 53
;ObjID_MTZBoss =			id(ObjPtr_MTZBoss)		; 54
;ObjID_OOZBoss =			id(ObjPtr_OOZBoss)		; 55
;ObjID_EHZBoss =			id(ObjPtr_EHZBoss)		; 56
;ObjID_MCZBoss =			id(ObjPtr_MCZBoss)		; 57
;ObjID_BossExplosion =		id(ObjPtr_BossExplosion)	; 58
;ObjID_SSEmerald =		id(ObjPtr_SSEmerald)		; 59
;ObjID_SSMessage =		id(ObjPtr_SSMessage)		; 5A
;ObjID_SSRingSpill =		id(ObjPtr_SSRingSpill)		; 5B
;ObjID_Masher =			id(ObjPtr_Masher)		; 5C
;ObjID_CPZBoss =			id(ObjPtr_CPZBoss)		; 5D
;ObjID_SSHUD =			id(ObjPtr_SSHUD)		; 5E
;ObjID_StartBanner =		id(ObjPtr_StartBanner)		; 5F
;ObjID_EndingController =	id(ObjPtr_EndingController)	; 5F
;ObjID_SSRing =			id(ObjPtr_SSRing)		; 60
;ObjID_SSBomb =			id(ObjPtr_SSBomb)		; 61
;ObjID_SSShadow =		id(ObjPtr_SSShadow)		; 63
;ObjID_MTZTwinStompers =		id(ObjPtr_MTZTwinStompers)	; 64
;ObjID_MTZLongPlatform =		id(ObjPtr_MTZLongPlatform)	; 65
;ObjID_MTZSpringWall =		id(ObjPtr_MTZSpringWall)	; 66
;ObjID_MTZSpinTube =		id(ObjPtr_MTZSpinTube)		; 67
;ObjID_SpikyBlock =		id(ObjPtr_SpikyBlock)		; 68
;ObjID_Nut =			id(ObjPtr_Nut)			; 69
;ObjID_MCZRotPforms =		id(ObjPtr_MCZRotPforms)		; 6A
;ObjID_MTZMovingPforms =		id(ObjPtr_MTZMovingPforms)	; 6A
;ObjID_MTZPlatform =		id(ObjPtr_MTZPlatform)		; 6B
;ObjID_CPZSquarePform =		id(ObjPtr_CPZSquarePform)	; 6B
;ObjID_Conveyor =		id(ObjPtr_Conveyor)		; 6C
;ObjID_FloorSpike =		id(ObjPtr_FloorSpike)		; 6D
;ObjID_LargeRotPform =		id(ObjPtr_LargeRotPform)	; 6E
;ObjID_SSResults =		id(ObjPtr_SSResults)		; 6F
;ObjID_Cog =			id(ObjPtr_Cog)			; 70
;ObjID_MTZLavaBubble =		id(ObjPtr_MTZLavaBubble)	; 71
;ObjID_HPZBridgeStake =		id(ObjPtr_HPZBridgeStake)	; 71
;ObjID_PulsingOrb =		id(ObjPtr_PulsingOrb)		; 71
;ObjID_CNZConveyorBelt =		id(ObjPtr_CNZConveyorBelt)	; 72
;ObjID_RotatingRings =		id(ObjPtr_RotatingRings)	; 73
;ObjID_InvisibleBlock =		id(ObjPtr_InvisibleBlock)	; 74
;ObjID_MCZBrick =		id(ObjPtr_MCZBrick)		; 75
;ObjID_SlidingSpikes =		id(ObjPtr_SlidingSpikes)	; 76
;ObjID_MCZBridge =		id(ObjPtr_MCZBridge)		; 77
;ObjID_CPZStaircase =		id(ObjPtr_CPZStaircase)		; 78
;ObjID_Starpost =		id(ObjPtr_Starpost)		; 79
;ObjID_SidewaysPform =		id(ObjPtr_SidewaysPform)	; 7A
;ObjID_PipeExitSpring =		id(ObjPtr_PipeExitSpring)	; 7B
;ObjID_CPZPylon =		id(ObjPtr_CPZPylon)		; 7C
;ObjID_SuperSonicStars =		id(ObjPtr_SuperSonicStars)	; 7E
;ObjID_VineSwitch =		id(ObjPtr_VineSwitch)		; 7F
;ObjID_MovingVine =		id(ObjPtr_MovingVine)		; 80
;ObjID_MCZDrawbridge =		id(ObjPtr_MCZDrawbridge)	; 81
;ObjID_SwingingPform =		id(ObjPtr_SwingingPform)	; 82
;ObjID_ARZRotPforms =		id(ObjPtr_ARZRotPforms)		; 83
;ObjID_ForcedSpin =		id(ObjPtr_ForcedSpin)		; 84
;ObjID_PinballMode =		id(ObjPtr_PinballMode)		; 84
;ObjID_LauncherSpring =		id(ObjPtr_LauncherSpring)	; 85
;ObjID_Flipper =			id(ObjPtr_Flipper)		; 86
;ObjID_SSNumberOfRings =		id(ObjPtr_SSNumberOfRings)	; 87
;ObjID_SSTailsTails =		id(ObjPtr_SSTailsTails)		; 88
;ObjID_ARZBoss =			id(ObjPtr_ARZBoss)		; 89
;ObjID_WFZPalSwitcher =		id(ObjPtr_WFZPalSwitcher)	; 8B
;ObjID_Whisp =			id(ObjPtr_Whisp)		; 8C
;ObjID_GrounderInWall =		id(ObjPtr_GrounderInWall)	; 8D
;ObjID_GrounderInWall2 =		id(ObjPtr_GrounderInWall2)	; 8E
;ObjID_GrounderWall =		id(ObjPtr_GrounderWall)		; 8F
;ObjID_GrounderRocks =		id(ObjPtr_GrounderRocks)	; 90
;ObjID_ChopChop =		id(ObjPtr_ChopChop)		; 91
;ObjID_Spiker =			id(ObjPtr_Spiker)		; 92
;ObjID_SpikerDrill =		id(ObjPtr_SpikerDrill)		; 93
;ObjID_Rexon =			id(ObjPtr_Rexon)		; 94
;ObjID_Sol =			id(ObjPtr_Sol)			; 95
;ObjID_Rexon2 =			id(ObjPtr_Rexon2)		; 96
;ObjID_RexonHead =		id(ObjPtr_RexonHead)		; 97
;ObjID_Projectile =		id(ObjPtr_Projectile)		; 98
;ObjID_Nebula =			id(ObjPtr_Nebula)		; 99
;ObjID_Turtloid =		id(ObjPtr_Turtloid)		; 9A
;ObjID_TurtloidRider =		id(ObjPtr_TurtloidRider)	; 9B
;ObjID_BalkiryJet =		id(ObjPtr_BalkiryJet)		; 9C
;ObjID_Coconuts =		id(ObjPtr_Coconuts)		; 9D
;ObjID_Crawlton =		id(ObjPtr_Crawlton)		; 9E
;ObjID_Shellcracker =		id(ObjPtr_Shellcracker)		; 9F
;ObjID_ShellcrackerClaw =	id(ObjPtr_ShellcrackerClaw)	; A0
;ObjID_Slicer =			id(ObjPtr_Slicer)		; A1
;ObjID_SlicerPincers =		id(ObjPtr_SlicerPincers)	; A2
;ObjID_Flasher =			id(ObjPtr_Flasher)		; A3
;ObjID_Asteron =			id(ObjPtr_Asteron)		; A4
;ObjID_Spiny =			id(ObjPtr_Spiny)		; A5
;ObjID_SpinyOnWall =		id(ObjPtr_SpinyOnWall)		; A6
;ObjID_Grabber =			id(ObjPtr_Grabber)		; A7
;ObjID_GrabberLegs =		id(ObjPtr_GrabberLegs)		; A8
;ObjID_GrabberBox =		id(ObjPtr_GrabberBox)		; A9
;ObjID_GrabberString =		id(ObjPtr_GrabberString)	; AA
;ObjID_Balkiry =			id(ObjPtr_Balkiry)		; AC
;ObjID_CluckerBase =		id(ObjPtr_CluckerBase)		; AD
;ObjID_Clucker =			id(ObjPtr_Clucker)		; AE
;ObjID_MechaSonic =		id(ObjPtr_MechaSonic)		; AF
;ObjID_SegaScreen =		id(ObjPtr_SegaScreen)		; B0
;ObjID_SonicOnSegaScr =		id(ObjPtr_SonicOnSegaScr)	; B1
;ObjID_Tornado =			id(ObjPtr_Tornado)		; B2
;ObjID_Cloud =			id(ObjPtr_Cloud)		; B3
;ObjID_VPropeller =		id(ObjPtr_VPropeller)		; B4
;ObjID_HPropeller =		id(ObjPtr_HPropeller)		; B5
;ObjID_TiltingPlatform =		id(ObjPtr_TiltingPlatform)	; B6
;ObjID_VerticalLaser =		id(ObjPtr_VerticalLaser)	; B7
;ObjID_WallTurret =		id(ObjPtr_WallTurret)		; B8
;ObjID_Laser =			id(ObjPtr_Laser)		; B9
;ObjID_WFZWheel =		id(ObjPtr_WFZWheel)		; BA
;ObjID_WFZShipFire =		id(ObjPtr_WFZShipFire)		; BC
;ObjID_SmallMetalPform =		id(ObjPtr_SmallMetalPform)	; BD
;ObjID_LateralCannon =		id(ObjPtr_LateralCannon)	; BE
;ObjID_WFZStick =		id(ObjPtr_WFZStick)		; BF
;ObjID_SpeedLauncher =		id(ObjPtr_SpeedLauncher)	; C0
;ObjID_BreakablePlating =	id(ObjPtr_BreakablePlating)	; C1
;ObjID_Rivet =			id(ObjPtr_Rivet)		; C2
;ObjID_TornadoSmoke =		id(ObjPtr_TornadoSmoke)		; C3
;ObjID_TornadoSmoke2 =		id(ObjPtr_TornadoSmoke2)	; C4
;ObjID_WFZBoss =			id(ObjPtr_WFZBoss)		; C5
;ObjID_Eggman =			id(ObjPtr_Eggman)		; C6
;ObjID_Eggrobo =			id(ObjPtr_Eggrobo)		; C7
;ObjID_Crawl =			id(ObjPtr_Crawl)		; C8
;ObjID_TtlScrPalChanger =	id(ObjPtr_TtlScrPalChanger)	; C9
;ObjID_CutScene =		id(ObjPtr_CutScene)		; CA
;ObjID_EndingSeqClouds =		id(ObjPtr_EndingSeqClouds)	; CB
;ObjID_EndingSeqTrigger =	id(ObjPtr_EndingSeqTrigger)	; CC
;ObjID_EndingSeqBird =		id(ObjPtr_EndingSeqBird)	; CD
;ObjID_EndingSeqSonic =		id(ObjPtr_EndingSeqSonic)	; CE
;ObjID_EndingSeqTails =		id(ObjPtr_EndingSeqTails)	; CE
;ObjID_TornadoHelixes =		id(ObjPtr_TornadoHelixes)	; CF
;ObjID_CNZRectBlocks =		id(ObjPtr_CNZRectBlocks)	; D2
;ObjID_BombPrize =		id(ObjPtr_BombPrize)		; D3
;ObjID_CNZBigBlock =		id(ObjPtr_CNZBigBlock)		; D4
;ObjID_Elevator =		id(ObjPtr_Elevator)		; D5
;ObjID_PointPokey =		id(ObjPtr_PointPokey)		; D6
;ObjID_Bumper =			id(ObjPtr_Bumper)		; D7
;ObjID_BonusBlock =		id(ObjPtr_BonusBlock)		; D8
;ObjID_Grab =			id(ObjPtr_Grab)			; D9
;ObjID_ContinueText =		id(ObjPtr_ContinueText)		; DA
;ObjID_ContinueIcons =		id(ObjPtr_ContinueIcons)	; DA
;ObjID_ContinueChars =		id(ObjPtr_ContinueChars)	; DB
;ObjID_RingPrize =		id(ObjPtr_RingPrize)		; DC


; Music IDs
offset :=	MusicIndex
ptrsize :=	4
idstart :=	$81

MusID_2PResult =	id(MusPtr_2PResult)	; 81
MusID_EHZ =		id(MusPtr_EHZ)	; 82
MusID_MCZ_2P =		id(MusPtr_MCZ_2P)	; 83
MusID_OOZ =		id(MusPtr_OOZ)	; 84
MusID_MTZ =		id(MusPtr_MTZ)	; 85
MusID_HTZ =		id(MusPtr_HTZ)	; 86
MusID_ARZ =		id(MusPtr_ARZ)	; 87
MusID_CNZ_2P =		id(MusPtr_CNZ_2P)	; 88
MusID_CNZ =		id(MusPtr_CNZ)	; 89
MusID_DEZ =		id(MusPtr_DEZ)	; 8A
MusID_MCZ =		id(MusPtr_MCZ)	; 8B
MusID_EHZ_2P =		id(MusPtr_EHZ_2P)	; 8C
MusID_SCZ =		id(MusPtr_SCZ)	; 8D
MusID_CPZ =		id(MusPtr_CPZ)	; 8E
MusID_WFZ =		id(MusPtr_WFZ)	; 8F
MusID_HPZ =		id(MusPtr_HPZ)	; 90
MusID_Options =		id(MusPtr_Options)	; 91
MusID_SpecStage =	id(MusPtr_SpecStage)	; 92
MusID_Boss =		id(MusPtr_Boss)	; 93
MusID_EndBoss =		id(MusPtr_EndBoss)	; 94
MusID_Ending =		id(MusPtr_Ending)	; 95
MusID_SuperSonic =	id(MusPtr_SuperSonic); 96
MusID_Invincible =	id(MusPtr_Invincible); 97
MusID_ExtraLife =	id(MusPtr_ExtraLife)	; 98
MusID_Title =		id(MusPtr_Title)	; 99
MusID_EndLevel =	id(MusPtr_EndLevel)	; 9A
MusID_GameOver =	id(MusPtr_GameOver)	; 9B
MusID_Continue =	id(MusPtr_Continue)	; 9C
MusID_Emerald =		id(MusPtr_Emerald)	; 9D
MusID_Credits =		id(MusPtr_Credits)	; 9E
MusID_Countdown =	id(MusPtr_Countdown)	; 9F
MusID__End =		id(SoundA0)	; A0

; Sound IDs
offset :=	SoundIndex
ptrsize :=	4
idstart :=	$A0
SndID_Jump =		id(SndPtr_Jump)			; A0
SndID_Checkpoint =	id(SndPtr_Checkpoint)		; A1
SndID_SpikeSwitch =	id(SndPtr_SpikeSwitch)		; A2
SndID_Hurt =		id(SndPtr_Hurt)			; A3
SndID_Skidding =	id(SndPtr_Skidding)		; A4
SndID_BlockPush =	id(SndPtr_BlockPush)		; A5
SndID_HurtBySpikes =	id(SndPtr_HurtBySpikes)		; A6
SndID_Sparkle =		id(SndPtr_Sparkle)		; A7
SndID_Beep =		id(SndPtr_Beep)			; A8
SndID_Bwoop =		id(SndPtr_Bwoop)		; A9
SndID_Splash =		id(SndPtr_Splash)		; AA
SndID_Swish =		id(SndPtr_Swish)		; AB
SndID_BossHit =		id(SndPtr_BossHit)		; AC
SndID_InhalingBubble =	id(SndPtr_InhalingBubble)	; AD
SndID_ArrowFiring =	id(SndPtr_ArrowFiring)		; AE
SndID_LavaBall =	id(SndPtr_ArrowFiring)		; AE
SndID_Shield =		id(SndPtr_Shield)		; AF
SndID_LaserBeam =	id(SndPtr_LaserBeam)		; B0
SndID_Zap =		id(SndPtr_Zap)			; B1
SndID_Drown =		id(SndPtr_Drown)		; B2
SndID_FireBurn =	id(SndPtr_FireBurn)		; B3
SndID_Bumper =		id(SndPtr_Bumper)		; B4
SndID_Ring =		id(SndPtr_Ring)			; B5
SndID_RingRight =	id(SndPtr_Ring)		; B5
SndID_SpikesMove =	id(SndPtr_SpikesMove)		; B6
SndID_Rumbling =	id(SndPtr_Rumbling)		; B7
SndID_Smash =		id(SndPtr_Smash)		; B9
SndID_DoorSlam =	id(SndPtr_DoorSlam)		; BB
SndID_SpindashRelease =	id(SndPtr_SpindashRelease)	; BC
SndID_Hammer =		id(SndPtr_Hammer)		; BD
SndID_Roll =		id(SndPtr_Roll)			; BE
SndID_ContinueJingle =	id(SndPtr_ContinueJingle)	; BF
SndID_CasinoBonus =	id(SndPtr_CasinoBonus)		; C0
SndID_Explosion =	id(SndPtr_Explosion)		; C1
SndID_WaterWarning =	id(SndPtr_WaterWarning)		; C2
SndID_EnterGiantRing =	id(SndPtr_EnterGiantRing)	; C3
SndID_BossExplosion =	id(SndPtr_BossExplosion)	; C4
SndID_TallyEnd =	id(SndPtr_TallyEnd)		; C5
SndID_RingSpill =	id(SndPtr_RingSpill)		; C6
SndID_Flamethrower =	id(SndPtr_Flamethrower)		; C8
SndID_Bonus =		id(SndPtr_Bonus)		; C9
SndID_SpecStageEntry =	id(SndPtr_SpecStageEntry)	; CA
SndID_SlowSmash =	id(SndPtr_SlowSmash)		; CB
SndID_Spring =		id(SndPtr_Spring)		; CC
SndID_Blip =		id(SndPtr_Blip)			; CD
SndID_RingLeft =	id(SndPtr_RingLeft)		; CE
SndID_Signpost =	id(SndPtr_Signpost)		; CF
SndID_CNZBossZap =	id(SndPtr_CNZBossZap)		; D0
SndID_Signpost2P =	id(SndPtr_Signpost2P)		; D3
SndID_OOZLidPop =	id(SndPtr_OOZLidPop)		; D4
SndID_SlidingSpike =	id(SndPtr_SlidingSpike)		; D5
SndID_CNZElevator =	id(SndPtr_CNZElevator)		; D6
SndID_PlatformKnock =	id(SndPtr_PlatformKnock)	; D7
SndID_BonusBumper =	id(SndPtr_BonusBumper)		; D8
SndID_LargeBumper =	id(SndPtr_LargeBumper)		; D9
SndID_Gloop =		id(SndPtr_Gloop)		; DA
SndID_PreArrowFiring =	id(SndPtr_PreArrowFiring)	; DB
SndID_Fire =		id(SndPtr_Fire)			; DC
SndID_ArrowStick =	id(SndPtr_ArrowStick)		; DD
SndID_Helicopter =	id(SndPtr_Helicopter)		; DE
SndID_SuperTransform =	id(SndPtr_SuperTransform)	; DF
SndID_SpindashRev =	id(SndPtr_SpindashRev)		; E0
SndID_Rumbling2 =	id(SndPtr_Rumbling2)		; E1
SndID_CNZLaunch =	id(SndPtr_CNZLaunch)		; E2
SndID_Flipper =		id(SndPtr_Flipper)		; E3
SndID_HTZLiftClick =	id(SndPtr_HTZLiftClick)		; E4
SndID_Leaves =		id(SndPtr_Leaves)		; E5
SndID_MegaMackDrop =	id(SndPtr_MegaMackDrop)		; E6
SndID_DrawbridgeMove =	id(SndPtr_DrawbridgeMove)	; E7
SndID_QuickDoorSlam =	id(SndPtr_QuickDoorSlam)	; E8
SndID_DrawbridgeDown =	id(SndPtr_DrawbridgeDown)	; E9
SndID_LaserBurst =	id(SndPtr_LaserBurst)		; EA
SndID_Scatter =		id(SndPtr_Scatter)		; EB
SndID_LaserFloor =	id(SndPtr_Scatter)		; EB
SndID_Teleport =	id(SndPtr_Teleport)		; EC
SndID_Error =		id(SndPtr_Error)		; ED
SndID_MechaSonicBuzz =	id(SndPtr_MechaSonicBuzz)	; EE
SndID_LargeLaser =	id(SndPtr_LargeLaser)		; EF
SndID_OilSlide =	id(SndPtr_OilSlide)		; F0

; Special sound IDs

MusID_StopSFX =		$78+$80			; F8
MusID_FadeOut =		$79+$80			; F9
SndID_SegaSound =	$7A+$80			; FA
MusID_SpeedUp =		$7B+$80			; FB
MusID_SlowDown =	$7C+$80			; FC
MusID_Stop =		$7D+$80			; FD
MusID_Pause =		$7E+$80			; FE
MusID_Unpause =		$7F+$80			; FF


; Other sizes
palette_line_size =	$10	; 16 word entries

; ---------------------------------------------------------------------------
; I run the main 68k RAM addresses through this function
; to let them work in both 16-bit and 32-bit addressing modes.
ramaddr function x,-(-x)&$FFFFFFFF

; ---------------------------------------------------------------------------
; RAM variables - General
	phase	ramaddr($FFFF0000)	; Pretend we're in the RAM
RAM_Start:

Chunk_Table:			ds.b	$8000	; was "Metablock_Table"
Chunk_Table_End:

Level_Layout:			ds.b	$1000
Level_Layout_End:

Block_Table:			ds.w	$C00
Block_Table_End:

TempArray_LayerDef:		ds.b	$200	; used by some layer deformation routines
Decomp_Buffer:			ds.b	$200
Sprite_Table_Input:		ds.b	$400	; in custom format before being converted and stored in Sprite_Table/Sprite_Table_2
Sprite_Table_Input_End:

Object_RAM:			; The various objects in the game are loaded in this area.
				; Each game mode uses different objects, so some slots are reused.
				; The section below declares labels for the objects used in main gameplay.
				; Objects for other game modes are declared further down.
Reserved_Object_RAM:
MainCharacter:			; first object (usually Sonic except in a Tails Alone game)
				ds.b	object_size
Sidekick:			; second object (Tails in a Sonic and Tails game)
				ds.b	object_size
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
				ds.b	object_size
				ds.b	object_size
				ds.b	object_size
				ds.b	object_size

CPZPylon:			; Pylon in the foreground in CPZ
				ds.b	object_size
WaterSurface1:			; First water surface
Oil:				; Oil at the bottom of OOZ
				ds.b	object_size
WaterSurface2:			; Second water surface
				ds.b	object_size
Reserved_Object_RAM_End:

Dynamic_Object_RAM:		; Dynamic object RAM
				ds.b	$28*object_size
Dynamic_Object_RAM_2P_End:	; SingleObjLoad stops searching here in 2P mode
				ds.b	$48*object_size
Dynamic_Object_RAM_End:

LevelOnly_Object_RAM:
Tails_Tails:			; address of the Tail's Tails object
				ds.b	object_size
				; unused slot (was super sonic stars)
				ds.b	object_size
Sonic_BreathingBubbles:		; Sonic's breathing bubbles
				ds.b	object_size
Tails_BreathingBubbles:		; Tails' breathing bubbles
				ds.b	object_size
Sonic_Dust:			; Sonic's spin dash dust
				ds.b	object_size
Tails_Dust:			; Tails' spin dash dust
				ds.b	object_size
				; 2 unused slots (were sonic and tails' shields)
				ds.b	object_size
				ds.b	object_size

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
				ds.b	4*object_size
Object_RAM_End:

Underwater_palette:		ds.w	palette_line_size
Underwater_palette_line2:	ds.w	palette_line_size
Underwater_palette_line3:	ds.w	palette_line_size
Underwater_palette_line4:	ds.w	palette_line_size

Underwater_palette_2:		ds.w	palette_line_size
Underwater_palette_2_line2:	ds.w	palette_line_size
Underwater_palette_2_line3:	ds.w	palette_line_size
Underwater_palette_2_line4:	ds.w	palette_line_size

Primary_Collision:		ds.b	$300
Secondary_Collision:		ds.b	$300
VDP_Command_Buffer:		ds.w	6*$15	; stores 21 ($15) VDP commands to issue the next time ProcessDMAQueue is called
VDP_Command_Buffer_Slot:	ds.l	1	; stores the address of the next open slot for a queued VDP command

Sprite_Table_2:			ds.b	$300	; Sprite attribute table buffer for the bottom split screen in 2-player mode
Horiz_Scroll_Buf:		ds.b	$400
Sonic_Stat_Record_Buf:		ds.b	$100
Sonic_Pos_Record_Buf:		ds.b	$100
Tails_Pos_Record_Buf:		ds.b	$100
CNZ_saucer_data:		ds.b	$40	; the number of saucer bumpers in a group which have been destroyed. Used to decide when to give 500 points instead of 10
				ds.b	$C0	; $FFFFE740-$FFFFE7FF ; unused as far as I can tell
Ring_Positions:			ds.b	$600
Ring_start_addr_ROM =        ramaddr( Ring_Positions+Rings_Space )
Ring_end_addr_ROM =        ramaddr( Ring_Positions+Rings_Space+4 )
Ring_start_addr_ROM_P2 =    ramaddr( Ring_Positions+Rings_Space+8 )
Ring_end_addr_ROM_P2 =        ramaddr( Ring_Positions+Rings_Space+12 )
Ring_free_RAM_start =        ramaddr( Ring_Positions+Rings_Space+16 )

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
				ds.b	$18	; $FFFFEE28-$FFFFEE3F
Horiz_block_crossed_flag:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary horizontally
Verti_block_crossed_flag:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary vertically
Horiz_block_crossed_flag_BG:	ds.b	1	; toggles between 0 and $10 when background camera crosses a block boundary horizontally
Verti_block_crossed_flag_BG:	ds.b	1	; toggles between 0 and $10 when background camera crosses a block boundary vertically
Horiz_block_crossed_flag_BG2:	ds.b	1	; used in CPZ
				ds.b	3
Horiz_block_crossed_flag_P2:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary horizontally
Verti_block_crossed_flag_P2:	ds.b	1	; toggles between 0 and $10 when you cross a block boundary vertically
				ds.b	6
Scroll_flags:			ds.w	1	; bitfield ; bit 0 = redraw top row, bit 1 = redraw bottom row, bit 2 = redraw left-most column, bit 3 = redraw right-most column
Scroll_flags_BG:		ds.w	1	; bitfield ; bit 0-3 as above, bit 4-7 unknown (used by some deformation routines)
Scroll_flags_BG2:		ds.w	1	; used in CPZ; bit 0-1 unknown
Scroll_flags_BG3:		ds.w	1	; used in CPZ; bit 0-1 unknown
Scroll_flags_P2:		ds.w	1	; bitfield ; bit 0 = redraw top row, bit 1 = redraw bottom row, bit 2 = redraw left-most column, bit 3 = redraw right-most column
				ds.b	6
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
				ds.b	4
Camera_X_pos_diff_P2:		ds.w	1	; (new X pos - old X pos) * 256
Camera_Y_pos_diff_P2:		ds.w	1	; (new Y pos - old Y pos) * 256
Screen_Shaking_Flag_HTZ:	ds.b	1	; activates screen shaking code in HTZ's layer deformation routine
Screen_Shaking_Flag:		ds.b	1	; activates screen shaking code (if existent) in layer deformation routine
Scroll_lock:			ds.b	1	; set to 1 to stop all scrolling for P1
Scroll_lock_P2:			ds.b	1	; set to 1 to stop all scrolling for P2
				ds.b	6
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
				ds.b	1
				ds.b	1
Dynamic_Resize_Routine:		ds.b	1
				ds.b	$10
Camera_X_pos_copy:		ds.l	1
Camera_Y_pos_copy:		ds.l	1
Tails_Min_X_pos:		ds.w	1
Tails_Max_X_pos:		ds.w	1
				ds.w	1
Tails_Max_Y_pos:		ds.w	1
Camera_RAM_End:

Block_cache:			ds.b	$80
Ring_consumption_table:		ds.b	$80	; contains RAM addresses of rings currently being consumed


				ds.b	$600	; $FFFFF100-$FFFFF5FF ; unused, leftover from the Sonic 1 sound driver (and used by it when you port it to Sonic 2)

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
				ds.b	4
VDP_Reg1_val:			ds.w	1	; normal value of VDP register #1 when display is disabled
				ds.b	6
Demo_Time_left:			ds.w	1	; 2 bytes

Vscroll_Factor:			ds.l	1
				ds.b	8	; $FFFFF61A-$FFFFF621
Teleport_timer:			ds.b	1	; timer for teleport effect
Teleport_flag:			ds.b	1	; set when a teleport is in progress
Hint_counter_reserve:		ds.w	1	; Must contain a VDP command word, preferably a write to register $0A. Executed every V-INT.
Palette_fade_range:				; Range affected by the palette fading routines
Palette_fade_start:		ds.b	1	; Offset from the start of the palette to tell what range of the palette will be affected in the palette fading routines
Palette_fade_length:		ds.b	1	; Number of entries to change in the palette fading routines
				ds.b	2
Vint_routine:			ds.b	1	; was "Delay_Time" ; routine counter for V-int
				ds.b	1
Sprite_count:			ds.b	1	; the number of sprites drawn in the current frame
				ds.b	5
PalCycle_Frame:			ds.w	1	; ColorID loaded in PalCycle
PalCycle_Timer:			ds.w	1	; number of frames until next PalCycle call
RNG_seed:			ds.l	1	; used for random number generation
Game_paused:			ds.w	1	
				ds.b	4
DMA_data_thunk:			ds.w	1	; Used as a RAM holder for the final DMA command word. Data will NOT be preserved across V-INTs, so consider this space reserved.
				ds.w	1
Hint_flag:			ds.w	1	; unless this is 1, H-int won't run

Water_Level_1:			ds.w	1
Water_Level_2:			ds.w	1
Water_Level_3:			ds.w	1
Water_on:			ds.b	1	; is set based on Water_flag
Water_routine:			ds.b	1
Water_fullscreen_flag:		ds.b	1	; was "Water_move"
				ds.b	1

New_Water_Level:		ds.w	1
Water_change_speed:		ds.w	1
				ds.b	8
Palette_frame:			ds.w	1
Palette_timer:			ds.b	1	; was "Palette_frame_count"
Super_Sonic_palette:		ds.b	1
				ds.b	$A
Ctrl_2_Logical:					; 2 bytes
Ctrl_2_Held_Logical:		ds.b	1	; 1 byte
Ctrl_2_Press_Logical:		ds.b	1	; 1 byte
Sonic_Look_delay_counter:	ds.w	1	; 2 bytes
Tails_Look_delay_counter:	ds.w	1	; 2 bytes
Super_Sonic_frame_count:	ds.w	1
				ds.b	$E
Plc_Buffer:			ds.b	$80	; Pattern load queue
Plc_Buffer_End:

Misc_Variables:
				ds.w	1	; unused

; extra variables for the second player (CPU) in 1-player mode
Tails_control_counter:		ds.w	1	; how long until the CPU takes control
Tails_respawn_counter:		ds.w	1
				ds.w	1	; unused
Tails_CPU_routine:		ds.w	1
Tails_CPU_target_x:		ds.w	1
Tails_CPU_target_y:		ds.w	1
Tails_interact_ID:		ds.b	1	; object ID of last object stood on
				ds.b	1

Rings_manager_routine:		ds.b	1
Level_started_flag:		ds.b	1
Ring_start_addr_RAM =        ramaddr( $FFFFF712 )
Ring_start_addr_RAM_P2 =    ramaddr( $FFFFF714 )
Ring_start_addr:		ds.w	1
Ring_end_addr:			ds.w	1
Ring_start_addr_P2:		ds.w	1
Ring_end_addr_P2:		ds.w	1
CNZ_Bumper_routine:		ds.b	1
				ds.b	$11	; $FFFFF71B-$FFFFF72B
Dirty_flag:			ds.b	1	; if whole screen needs to redraw
				ds.b	3
Water_flag:			ds.b	1	; if the level has water or oil
				ds.b	1
Demo_button_index_2P:		ds.w	1	; index into button press demo data, for player 2
Demo_press_counter_2P:		ds.w	1	; frames remaining until next button press, for player 2
				ds.b	$A

Boss_AnimationArray:		ds.b	$10	; up to $10 bytes; 2 bytes per entry
Boss_X_pos:			ds.w	1
				ds.w	1	; Boss_MoveObject reads a long, but all other places in the game use only the high word
Boss_Y_pos:			ds.w	1
				ds.w	1	; same here
Boss_X_vel:			ds.w	1
Boss_Y_vel:			ds.w	1
				ds.w	1
				ds.w	1	; unused

Sonic_top_speed:		ds.w	1
Sonic_acceleration:		ds.w	1
Sonic_deceleration:		ds.w	1
				ds.w	1
				ds.w	1
				ds.w	1
Obj_placement_routine:		ds.b	1
				ds.b	1
Camera_X_pos_last		dc.w	1	; Camera_X_pos_coarse from the previous frame

;when the objects manager is fully initialized,
Obj_load_addr_0:		ds.l	1	; this will contain the address of the rightmost out of range object from the right side of the screen
Obj_load_addr_1:		ds.l	1	; this will contain the address of the rightmost out of range object from the left side of the screen
Obj_load_addr_2:		ds.l	1
Obj_load_addr_3:		ds.l	1
				ds.b	$10
Demo_button_index:		ds.w	1	; index into button press demo data, for player 1
Demo_press_counter:		ds.b	1	; frames remaining until next button press, for player 1
				ds.b	3
Collision_addr:			ds.l	1
				ds.b	$D
Boss_defeated_flag:		ds.b	1
				ds.b	2
Current_Boss_ID:		ds.b	1
				ds.b	$1C
WindTunnel_flag:		ds.b	1
				ds.b	4
Control_Locked:			ds.b	1
				ds.b	3
Chain_Bonus_counter:		ds.w	1	; counts up when you destroy things that give points, resets when you touch the ground
Bonus_Countdown_1:		ds.w	1	; level results time bonus or special stage sonic ring bonus
Bonus_Countdown_2:		ds.w	1	; level results ring bonus or special stage tails ring bonus
Update_Bonus_score:		ds.b	1
				ds.b	3
Camera_X_pos_coarse:		ds.w	1	; (Camera_X_pos - 128) / 256
				ds.b	4
ButtonVine_Trigger:		ds.b	$10	; 16 bytes flag array, #subtype byte set when button/vine of respective subtype activated
				ds.b	$10	; $FFFFF7F0-$FFFFF7FF
Misc_Variables_End:

Sprite_Table:			ds.b	$280	; Sprite attribute table buffer
				ds.b	$80	; unused, but SAT buffer can spill over into this area when there are too many sprites on-screen

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

Object_Respawn_Table:		ds.b	$180

				ds.b	$80	; Stack
System_Stack:

				ds.w	1
Level_Inactive_flag:		ds.w	1	; (2 bytes)
Timer_frames:			ds.w	1	; (2 bytes)
Debug_object:			ds.b	1
				ds.b	1
Debug_placement_mode:		ds.b	1
				ds.b	1	; the whole word is tested, but the debug mode code uses only the low byte
				ds.b	1
				ds.b	1
Vint_runcount:			ds.l	1

Current_ZoneAndAct:				; 2 bytes
Current_Zone:			ds.b	1	; 1 byte
Current_Act:			ds.b	1	; 1 byte
Life_count:			ds.b	1
				ds.b	3
Current_Special_Stage:		ds.b	1
				ds.b	1
Continue_count:			ds.b	1
				ds.b	1	; old super sonic flag
Time_Over_flag:			ds.b	1
Extra_life_flags:		ds.b	1

; If set, the respective HUD element will be updated.
Update_HUD_lives:		ds.b	1
Update_HUD_rings:		ds.b	1
Update_HUD_timer:		ds.b	1
Update_HUD_score:		ds.b	1

Ring_count:			ds.w	1	; 2 bytes
Timer:						; 4 bytes
Timer_minute_word:				; 2 bytes
				ds.b	1	; filler
Timer_minute:			ds.b	1	; 1 byte
Timer_second:			ds.b	1	; 1 byte
Timer_centisecond:				; inaccurate name (the seconds increase when this reaches 60)
Timer_frame:			ds.b	1	; 1 byte

Score:				ds.l	1	; 4 bytes
				ds.b	6
Last_star_pole_hit:		ds.b	1	; 1 byte -- max activated starpole ID in this act
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

				ds.b	$46	; $FFFFFE59-$FFFFFE9E

AnimalsCounter:			ds.b	1
Logspike_anim_counter:		ds.b	1
Logspike_anim_frame:		ds.b	1
Rings_anim_counter:		ds.b	1
Rings_anim_frame:		ds.b	1
Unknown_anim_counter:		ds.b	1	; I think this was $FFFFFEC4 in the alpha
Unknown_anim_frame:		ds.b	1
Ring_spill_anim_counter:	ds.b	1	; scattered rings
Ring_spill_anim_frame:		ds.b	1
Ring_spill_anim_accum:		ds.w	1
				ds.b	$16

; values for the second player (some of these only apply to 2-player games)
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
				ds.b	3
Ring_count_2P:			ds.w	1
Timer_2P:					; 4 bytes
Timer_minute_word_2P:				; 2 bytes
				ds.b	1	; filler
Timer_minute_2P:		ds.b	1	; 1 byte
Timer_second_2P:		ds.b	1	; 1 byte
Timer_centisecond_2P:				; inaccurate name (the seconds increase when this reaches 60)
Timer_frame_2P:			ds.b	1	; 1 byte
Score_2P:			ds.l	1
				ds.b	6
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

				ds.b	$16	; $FFFFFEFA-$FFFFFF09
Results_Screen_2P:		ds.w	1	; 0 = act, 1 = zone, 2 = game, 3 = SS, 4 = SS all
				ds.b	$E	; $FFFFFF12-$FFFFFF1F

Results_Data_2P:				; $18 (24) bytes
EHZ_Results_2P:			ds.b	6	; 6 bytes
MCZ_Results_2P:			ds.b	6	; 6 bytes
CNZ_Results_2P:			ds.b	6	; 6 bytes
SS_Results_2P:			ds.b	6	; 6 bytes
Results_Data_2P_End:

SS_Total_Won:			ds.b	2	; 2 bytes (player 1 then player 2)
				ds.b	6
Perfect_rings_left:		ds.w	1
				ds.b	$2E	; $FFFFFF42-$FFFFFF6F

Player_mode:			ds.w	1	; 0 = Sonic and Tails, 1 = Sonic, 2 = Tails
Player_option:			ds.w	1	; 0 = Sonic and Tails, 1 = Sonic, 2 = Tails

Two_player_items:		ds.w	1
				ds.b	$C	; $FFFFFF76-$FFFFFF81
Level_select_zone:		ds.w	1
Sound_test_sound:		ds.w	1
Title_screen_option:		ds.b	1
				ds.b	1	; unused
Current_Zone_2P:		ds.b	1
Current_Act_2P:			ds.b	1
Two_player_mode_copy:		ds.w	1
Options_menu_box:		ds.b	1
				ds.b	3
Level_Music:			ds.w	1
				ds.b	6
Game_Over_2P:			ds.w	1
				ds.b	$16	; $FFFFFF9A-$FFFFFFAF
Got_Emerald:			ds.b	1
Emerald_count:			ds.b	1
Got_Emeralds_array:		ds.b	7	; 7 bytes
				ds.b	7	; filler
Next_Extra_life_score:		ds.l	1
Next_Extra_life_score_2P:	ds.l	1
Level_Has_Signpost:		ds.w	1	; 1 = signpost, 0 = boss or nothing
				ds.b	6
Level_select_flag:		ds.b	1
Slow_motion_flag:		ds.b	1
Night_mode_flag:		ds.w	1
Correct_cheat_entries:		ds.w	1
Correct_cheat_entries_2:	ds.w	1	; for 14 continues or 7 emeralds codes
Two_player_mode:		ds.w	1	; flag (0 for main game)
				ds.b	6

; Values in these variables are passed to the sound driver during V-INT.
; They use a playlist index, not a sound test index.
Music_to_play:			ds.b	1
SFX_to_play:			ds.b	1	; normal
SFX_to_play_2:			ds.b	1	; alternating stereo
				ds.b	1
Music_to_play_2:		ds.b	1	; alternate (higher priority?) slot
				ds.b	$B

Demo_mode_flag:			ds.w	1 ; 1 if a demo is playing (2 bytes)
Demo_number:			ds.w	1 ; which demo will play next (2 bytes)
Ending_demo_number:		ds.w	1 ; zone for the ending demos (2 bytes, unused)
				ds.w	1
Graphics_Flags:			ds.w	1 ; misc. bitfield
Debug_mode_flag:		ds.w	1 ; (2 bytes)
Checksum_fourcc:		ds.l	1 ; (4 bytes)


    if * > 0	; Don't declare more space than the RAM can contain!
	fatal "The RAM variable declarations are too large by $\{*} bytes."
    endif


; RAM variables - SEGA screen
	phase	Object_RAM	; Move back to the object RAM
SegaScr_Object_RAM:
				; Unused slot
				ds.b	object_size
SegaScreenObject:		; Sega screen
				ds.b	object_size
SonicOnSegaScreen:		; Sonic on Sega screen
				ds.b	object_size

				ds.b	($80-3)*object_size
SegaScr_Object_RAM_End:


; RAM variables - Title screen
	phase	Object_RAM	; Move back to the object RAM
TtlScr_Object_RAM:
				; Unused slot
				ds.b	object_size
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

				ds.b	6*object_size

TitleScreenMenu:
				ds.b	object_size
IntroStars7:
				ds.b	object_size

				ds.b	($70-2)*object_size
TtlScr_Object_RAM_End:


; RAM variables - Special stage
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
PNT_Buffer:			ds.b	$700	; ???
Horiz_Scroll_Buf_2:		ds.b	$900	; ???


; RAM variables - Continue screen
	phase	Object_RAM	; Move back to the object RAM
ContScr_Object_RAM:
				ds.b	object_size
				ds.b	object_size
ContinueText:			; "CONTINUE" on the Continue screen
				ds.b	object_size
ContinueIcons:			; The icons in the Continue screen
				ds.b	$D*object_size

				; Free slots
				ds.b	$70*object_size
ContScr_Object_RAM_End:


; RAM variables - 2P VS results screen
	phase	Object_RAM	; Move back to the object RAM
VSRslts_Object_RAM:
VSResults_HUD:			; Blinking text at the bottom of the screen
				ds.b	object_size

				; Free slots
				ds.b	$7F*object_size
VSRslts_Object_RAM_End:


; RAM variables - Menu screens
	phase	Object_RAM	; Move back to the object RAM
Menus_Object_RAM:		; No objects are loaded in the menu screens
				ds.b	$80*object_size
Menus_Object_RAM_End:


; RAM variables - Ending sequence
	phase	Object_RAM
EndSeq_Object_RAM:
				ds.b	object_size
				ds.b	object_size
Tails_Tails_Cutscene:		; Tails' tails on the cut scene
				ds.b	object_size
				ds.b	object_size
CutScene:
				ds.b	object_size
				ds.b	($80-5)*object_size
EndSeq_Object_RAM_End:

	dephase		; Stop pretending

	!org	0	; Reset the program counter


; ---------------------------------------------------------------------------
; VDP addressses
VDP_data_port =			$C00000 ; (8=r/w, 16=r/w)
VDP_control_port =		$C00004 ; (8=r/w, 16=r/w)
PSG_input =			$C00011

; ---------------------------------------------------------------------------
; Z80 addresses
Z80_RAM =			$A00000 ; start of Z80 RAM
Z80_RAM_End =			$A02000 ; end of non-reserved Z80 RAM
Z80_Version =			$A10001
Z80_Port_1_Data =		$A10002
Z80_Port_1_Control =		$A10008
Z80_Port_2_Control =		$A1000A
Z80_Expansion_Control =		$A1000C
Z80_Bus_Request =		$A11100
Z80_Reset =			$A11200

Security_Addr =			$A14000
Palette_frame_count	=	$FFFFF65E
unk_FFFFEEB4 =			$FFFFEC10
Camera_X_pos_rounded =		$FFFFEC12
Camera_Y_pos_rounded =		$FFFFEC14
Camera_X_round_value =		$FFFFEC16
Camera_Y_round_value =		$FFFFEC18
word_FFFFEE90 =			$FFFFEC1A
unk_FFFFEEB6 =			$FFFFEC1C
unk_FFFFEE8C =			$FFFFEC1E
unk_FFFFEEE2 =			$FFFFEC20
unk_FFFFEEE4 =			$FFFFEC22
; ============================================================================
ActTransitionStartFlag =	$FFFFEC24
Next_Camera_Max_X_Pos =		$FFFFEC26
Super_Tails_flag = 		$FFFFFE19
LevelUncLayout = 		$FFFFEC30
SonicFlyingFlag = 		$FFFFEC35
SonicSSFlag = 			$FFFFEC36
; ===========================================================================
