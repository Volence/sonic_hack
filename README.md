# sonic_hack
A modification of sonic the hedgehog 2 for research/entertainment purposes

## To Do:

### Bug List:
- General Collision Bugs
  - Certain collision routines (looking at you SolidObject) are handled outside the object touch response, they should be included
  - Monitor also has some code that needs to be put into the object touch response
- Fix Tails' Tails
- Fix Knuckles Climbing (as well as when he comes out of debug mode)
- Bubbles spawning better
- Monitors Respawn
- Monitors if they don't respawn sometimes spawn an empty object that has collision like a monitor and creates a 'moving up' broken monitor when 'broken'

### Feature List:
- Update all objects code and take any objects not spawned in layout off the list (and change their names)
- Update all objects code to new format as well as update object loading
- Seperate all level data to make it easy to add new levels and update it so each act gets its own information (art, layout, ect...)
- Try to make all object coding faster/more efficient if possible (such as animate object ect...)
- New faster compression format
- Faster way to load art
- Implement "Tile, Block, Chunk and Section" system

## Changelog:
 * 06/12/2019
   * Fixed shield art, shield items now correspond with correct mappings
   * Fixed up object in layout, objects placed are now correct from the object_index
   * Fixed up naming of items in soned2 to correlate with the object_index
 * 06/11/2019
   * Cleaned up the Pitcher Plant badnik code, commented it a bit as well
   * Commented more of the object touch response code
 * 06/10/2019
   * Moved the solid object data from the main file to object_touch_response
   * Commented more on the touchresponse routine
   * Plan to merge solid object into object_touch_response
