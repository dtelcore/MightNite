# MightNite

1v1 fighter. Three characters, Martial Hero, Light Bandit, and Heavy Bandit, five stages, best of three. Play locally on one keyboard, or online with a friend through a room code.

## Open in Godot

This project needs **Godot 4.7** (tested with 4.7.2). Download it from [godotengine.org](https://godotengine.org/download).

1. Start the Godot Project Manager.
2. Choose **Import**.
3. Select `project.godot` in this folder and confirm.
4. Open the project, then press **F5** (or the Play button). The game starts at `Scenes/MainMenu.tscn`.

The project folder is the one that contains `project.godot`. On a case-sensitive disk, `MightNite` and `might-nite` are different folders. Open the one that has `project.godot`, the `Characters` folder, and the `assets` folder.

From a terminal, if `godot` is on your PATH:

```bash
godot --path . --editor
```

Play without the editor:

```bash
godot --path .
```

## Play locally

From the main menu, choose **FIGHT** or press Enter. On the select screen, P1 uses A/D, P2 uses Left/Right, Q/E changes the stage, and Enter starts the match.

| | Move | Punches (L / M / H) | Kicks (L / M / H) |
|---|---|---|---|
| P1 | W A S D | U I O | J K L |
| P2 | Arrow keys | `;` `'` `\` | `,` `.` `/` |

P2 can also use the numpad: 7 8 9 for punches and 4 5 6 for kicks. Gamepad 1 is P1 and gamepad 2 is P2 (left stick to move; X Y RB are punches, A B right-stick click are kicks).

Hold back to block. Crouch with down. Double-tap forward or back to dash. Light punch plus light kick throws. Quarter-circle forward plus punch is Martial Hero’s fireball. Forward, down, down-forward plus punch is the uppercut. Heavy Bandit’s command grab is a full-circle motion plus punch. Double quarter-circle forward plus punch is a super.

F1 toggles the debug overlay. Esc leaves a match and returns to the menu.

## Play online

Choose **ONLINE** on the main menu. One player hosts a room and reads the 4-character code to the other. The guest types that code and joins.

Each player moves only their own cursor. The host picks the stage. Both press Enter when ready. In the match, both players use the P1 keys above for their own fighter. The round waits until both inputs for that frame have arrived, so a slow connection adds a short delay.

When the match ends, both players return to the main menu. That room code is closed, so the next fight needs a new room.

Online needs the same game build on both computers, including `addons/webrtc_native`. The project URL and publishable key are already in the game, so the other computer does not need a separate config file. The rooms table is created by `supabase/rooms.sql`.

If the two computers cannot open a direct link, the character select screen says so and the match does not start.
