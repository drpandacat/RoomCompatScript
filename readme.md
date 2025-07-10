# [RoomCompatScript](https://github.com/drpandacat/RoomCompatScript/)
## What!!!!
By default, rooms containing entities from multiple mods will still show up and crash the game when entered if one of its dependencies is missing.
With the power of [REPENTOGON](https://repentogon.com/), including this script within your mod will automatically detect and attempt to replace incompatible rooms, requiring no additional setup in code or within room files.
## Notes
If a perfect replacement can not be found for a room (possible in cases where a room is totally unique in that there is no vanilla room that matches its required doors, shape, type, etc.), it will attempt to find a looser replacement by ignoring the room's difficulty. If a replacement can still not be found, the room will still spawn, but without the non-existent entities that would usually crash your game.
## Beta
I believe this to be stable, however I am not perfect. If you come across any issues, please report it here or on its [GitHub issues page](https://github.com/drpandacat/RoomCompatScript/issues) with a log.txt file if possible. Happy rooming idk
