# VRAM Debug Guide for Exodus Emulator

## Important Notes
- **VRAM addresses in Exodus are typically shown as BYTE addresses**
- **Art tile constants are TILE indices** (1 tile = 32 bytes = 16 words)
- **Conversion**: Tile index × 32 = byte address, Tile index × 16 = word address

## Key VRAM Regions to Inspect

### 1. Level Art Region (Kosinski decompressed)
- **Tile range**: $0000 - $023F (max for ARZ)
- **Byte range**: $0000 - $047E
- **Word range**: $0000 - $023F
- **What to check**: 
  - Does this contain level tile data?
  - Is it all zeros (not loaded)?
  - Does it overflow into sprite art space ($0400+)?

### 2. UI/FX Region ($0400 - $04FF tiles)
- **Powerups**: Tile $0400 = Byte $0800, Word $0400
- **HUD**: Tile $0440 = Byte $0880, Word $0440  
- **Numbers**: Tile $0458 = Byte $08B0, Word $0458
- **Shield**: Tile $046A = Byte $08D4, Word $046A
- **What to check**: 
  - Is HUD art actually at byte $0880?
  - Are there overlaps or wrong data?

### 3. Life Icons ($0500 - $051F tiles)
- **Sonic life**: Tile $0500 = Byte $0A00, Word $0500
- **Tails life**: Tile $050C = Byte $0A18, Word $050C
- **Knuckles life**: Tile $0518 = Byte $0A30, Word $0518

### 4. Core Gameplay ($0520 - $06CF tiles)
- **Explosion**: Tile $0524 = Byte $0A48, Word $0524
- **Rings**: Tile $06BC = Byte $0D78, Word $06BC
- **What to check**: Rings should be visible at byte $0D78

### 5. Character Patterns ($0780 - $07FF tiles)
- **Sonic/Tails/Knuckles**: Tile $0780 = Byte $0F00, Word $0780

## What to Look For

### Good Signs:
- Coherent patterns of tile data
- Different regions have different data patterns
- No obvious repeating garbage

### Bad Signs:
- **Repeating patterns** (like "DDDD" or "ffff") = corruption or wrong data
- **All zeros** = art not loaded
- **Same data in multiple regions** = overlap/copy issue
- **Random garbage** = wrong source data or address calculation error

## Specific Checks Based on Your Hex Dump

From your hex dump, I noticed:
- **Lines 01A0-01F0**: Heavy "DDDD" patterns - this might be corruption
- **Lines 0200-03F0**: Lots of "f" and "a" patterns - could be level art or corruption
- **Lines 0400-0460**: Mixed symbols - this is the UI/FX region, should contain sprite art

## What to Check Right Now

1. **Check if level art is loading at $0000**:
   - Look at byte address $0000 in VRAM
   - Should see level tile data, not all zeros

2. **Check if level art overflows**:
   - Check byte address $0800 (tile $0400) - should be sprite art, NOT level art
   - If you see level art here, it's overflowing!

3. **Check HUD location**:
   - Look at byte address $0880 (tile $0440)
   - Should see HUD sprite data

4. **Check for overlaps**:
   - Compare data at $0800 (Powerups) vs $0880 (HUD)
   - They should be different - if same, there's an overlap

## How to Use Exodus VRAM Viewer

1. Open Exodus emulator
2. Load your ROM and get to the corrupted level
3. Open the VRAM viewer/memory editor
4. Navigate to the byte addresses listed above
5. Take screenshots or note what you see at each address
6. Share the findings!

