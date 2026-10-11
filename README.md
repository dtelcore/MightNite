# MightNite

Local 1v1 fighter. Two characters, Ryuji and Titan, five stages, best of three.

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

## Play

From the main menu, press Enter. On the select screen, P1 uses A/D, P2 uses Left/Right, Q/E changes the stage, and Enter starts the match.

| | Move | Punches (L / M / H) | Kicks (L / M / H) |
|---|---|---|---|
| P1 | W A S D | U I O | J K L |
| P2 | Arrow keys | `;` `'` `\` | `,` `.` `/` |

P2 can also use the numpad: 7 8 9 for punches and 4 5 6 for kicks. Gamepad 1 is P1 and gamepad 2 is P2 (left stick to move; X Y RB are punches, A B right-stick click are kicks).

Hold back to block. Crouch with down. Double-tap forward or back to dash. Light punch plus light kick throws. Quarter-circle forward plus punch is Ryuji’s fireball. Forward, down, down-forward plus punch is the uppercut. Titan’s command grab is a full-circle motion plus punch. Double quarter-circle forward plus punch is a super.

F1 toggles the debug overlay. Esc leaves a match and returns to the menu.
