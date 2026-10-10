**Concrete MVP Plan: Tekken-inspired 2D Fighter in Godot 4 (GDScript)**

Focus: Local 1v1, responsive combat, combos, strong game feel. One training stage, two characters, best-of-3. No online, ranked, story, or advanced UI.

### 1. Project Setup & Folder Structure

Create a new Godot 4.3+ project (Compatibility or Forward+ renderer). Set fixed 2D resolution (e.g. 1920×1080 or 1280×720) with stretch mode “viewport” + aspect “keep”.

Recommended structure:

```
res://
├── Characters/
│   ├── CharacterBase.gd
│   ├── CharacterBase.tscn
│   ├── Ryuji/
│   │   ├── Ryuji.gd
│   │   ├── Ryuji.tscn
│   │   └── moves/          # Move resources
│   └── Titan/
│       ├── Titan.gd
│       ├── Titan.tscn
│       └── moves/
├── Systems/
│   ├── InputManager.gd
│   ├── CombatManager.gd
│   ├── HitboxSystem.gd
│   ├── HealthSystem.gd
│   ├── MatchManager.gd
│   └── StateMachine.gd
├── Resources/
│   ├── MoveData.gd         # Resource class
│   ├── CharacterData.gd    # Resource class
│   └── FrameData.gd        # Optional helper
├── UI/
│   ├── HealthBar.tscn
│   ├── TimerUI.tscn
│   ├── ComboCounter.tscn
│   ├── CharacterSelect.tscn
│   └── RoundAnnouncer.tscn
├── Stages/
│   └── TrainingStage.tscn
├── Core/
│   ├── GameManager.gd
│   └── Constants.gd
└── Scenes/
    ├── MainMenu.tscn
    ├── CharacterSelect.tscn
    └── Match.tscn
```



### 2. Godot Scene Hierarchy (Key Scenes)

**Match.tscn** (main gameplay)

```
Match (Node2D)
├── Camera2D (with limits + slight shake on hits)
├── Stage (TrainingStage instance)
├── Player1 (CharacterBase instance)
├── Player2 (CharacterBase instance)
├── CombatManager (Node)
├── MatchManager (Node)
├── UI (CanvasLayer)
│   ├── HealthBars (HBox)
│   ├── Timer
│   ├── ComboCounter
│   └── RoundAnnouncer
└── HitstopController (Node)
```

**CharacterBase.tscn**

```
CharacterBase (CharacterBody2D)
├── Sprite2D / AnimatedSprite2D
├── CollisionShape2D (body)
├── Hurtbox (Area2D + CollisionShape2D)
├── HitboxContainer (Node2D)
│   └── Hitbox (Area2D) – enabled/disabled per frame
├── StateMachine (Node)
├── AnimationPlayer
├── InputBuffer (Node)
└── Effects (Node2D for sparks, etc.)
```

**Character Select**
Simple side-by-side portraits + name + confirm. On confirm → load Match with selected characters.

### 3. Resource Definitions (Data-Driven)

**MoveData.gd** (Resource)

```gdscript
class_name MoveData
extends Resource

@export var move_name: String
@export var input: String          # "5LP", "6HK", "236P", "360P", etc.
@export var startup: int
@export var active: int
@export var recovery: int
@export var damage: int
@export var chip_damage: int = 0
@export var hitstun: int
@export var blockstun: int
@export var knockback: Vector2
@export var launch_force: float = 0.0   # >0 = launcher
@export var is_projectile: bool = false
@export var is_throw: bool = false
@export var is_command_grab: bool = false
@export var armor: bool = false
@export var hitbox_frames: Array[Rect2]  # or use AnimationPlayer markers
@export var animation: String
@export var cancel_into: Array[String]   # move names that can cancel
@export var scaling: float = 1.0
```

**CharacterData.gd** (Resource)

```gdscript
class_name CharacterData
extends Resource

@export var character_name: String
@export var max_health: int = 1000
@export var walk_speed: float
@export var dash_speed: float
@export var jump_force: float
@export var moves: Array[MoveData]
@export var specials: Array[MoveData]
@export var supers: Array[MoveData]
```

Store one CharacterData per fighter + individual MoveData files in `Characters/X/moves/`.

### 4. State Machine Architecture

Use a simple hierarchical or flat state machine on each character.

**Core States** (CharacterBase):

- Idle
- Walk / BackWalk
- Crouch
- Jump (Rising / Apex / Falling)
- Dash / BackDash
- Attack (sub-states via current MoveData)
- Block (Standing / Crouching)
- Hitstun / Blockstun
- Knockdown / Getup
- Throw / Thrown
- Super Freeze (optional short pause)

**StateMachine.gd** skeleton:

```gdscript
class_name StateMachine
extends Node

var current_state: State
var states: Dictionary = {}

func change_state(new_state_name: String, data: Dictionary = {}):
    if current_state:
        current_state.exit()
    current_state = states[new_state_name]
    current_state.enter(data)
```

Each concrete state (IdleState.gd, AttackState.gd, etc.) implements `enter()`, `exit()`, `physics_update(delta)`, `handle_input()`.

**Attack flow**:

1. Input detected → check InputBuffer → find matching MoveData.
2. Change to Attack state with that MoveData.
3. AnimationPlayer plays the move.
4. On specific frames (via AnimationPlayer call method or frame markers) enable Hitbox.
5. On hit → apply hitstop, damage, hitstun, knockback/launch, update combo counter + scaling.
6. Cancel window checked against current MoveData.cancel_into.



### 5. Core Systems Implementation Order (MVP Build Sequence)

**Phase 1 – Foundation (Day 1-2)**

1. CharacterBase + basic movement (walk, backwalk, crouch, jump, dash).
2. InputManager (keyboard + gamepad, 5-frame buffer using a queue of InputEvents or bitmasks).
3. Simple AnimationPlayer setup for both characters.
4. Camera that follows both players with soft lock.

**Phase 2 – Combat Core (Day 3-5)**

1. Hitbox / Hurtbox system (Area2D layers: Player1Hurt, Player1Hit, Player2Hurt, Player2Hit).
2. MoveData resources for all normal attacks (standing + crouching L/M/H).
3. Attack state + animation-driven hitbox activation.
4. Hit detection → damage, hitstun, blockstun, knockback.
5. Basic block (hold back while grounded).
6. Hitstop (Engine.time_scale or custom pause for 3–8 frames) + simple particle spark.
7. Combo counter + damage scaling (e.g. 0.9× per hit after 3rd).

**Phase 3 – Advanced Moves & Feel (Day 6-8)**

1. Specials: Ryuji fireball (projectile scene), uppercut (launcher), Titan command grab + armor move.
2. Super attacks (meter optional for MVP – just input + big damage + freeze).
3. Throws (proximity + input, or dedicated throw hurtbox).
4. Air juggling (launch → airborne state → juggle window).
5. Knockdown + getup invulnerability frames.
6. Input buffer polishing + priority (specials > normals).

**Phase 4 – Match Flow & UI (Day 9-10)**

1. MatchManager: 99s timer, best-of-3, round win/lose, final winner.
2. HealthSystem + UI bars (smooth lerp).
3. Character select screen → pass CharacterData to Match.
4. Training stage (simple ground + background).
5. Round announcer text + “KO”, “Perfect”, “Time’s Up”.

**Phase 5 – Polish (Day 11-12)**

1. Screen shake on heavy hits / supers.
2. Hit sparks / block sparks (CPUParticles2D or AnimatedSprite).
3. Sound placeholders (hit, block, whoosh, KO).
4. Tight tuning of frame data, pushback, gravity, friction.
5. Debug overlays (hitboxes, state name, combo count).



### 6. Key Implementation Notes for Responsiveness

- **Input Buffer**: 5-frame circular buffer. Store directional + button presses. Match sequences like “6 → 2 → 3 → P” for specials.
- **Hitstop**: On successful hit, pause both characters (and optionally projectiles) for N frames via a global HitstopController.
- **Cancel Windows**: Only allow cancels during recovery of the current move if the next move is in `cancel_into` and input is buffered.
- **Damage Scaling**: Start at 1.0, multiply by 0.85–0.9 each successive hit in the same combo.
- **Layers**: Use Physics layers properly so Player1 hitboxes only detect Player2 hurtboxes.
- **Fixed Timestep**: Rely on Godot’s physics process; keep all frame data in integers (frames @ 60 fps).



### 7. Setup Instructions (for you or a collaborator)

1. Create Godot 4.3+ project.
2. Create the folder structure above.
3. Implement Constants.gd (layer numbers, input actions, etc.).
4. Create MoveData and CharacterData resources.
5. Build CharacterBase.tscn + StateMachine.
6. Implement InputManager and basic movement states.
7. Add two placeholder characters with simple colored rectangles + animations.
8. Implement HitboxSystem + one light attack end-to-end.
9. Expand to full movelist.
10. Wire MatchManager + UI.
11. Test local 1v1 thoroughly (keyboard vs gamepad recommended).



### 8. Future Roadmap (Post-MVP)

- **Online Multiplayer + Rollback Netcode**
  - Integrate Godot’s MultiplayerAPI or a dedicated library (e.g. Godot Rollback Netcode community solutions or custom GGPO-style).
  - Deterministic simulation (fixed-point math if needed, seed-based RNG).
  - Input delay + rollback prediction.
  - Lobby / room system.
- Additional characters (data-driven → very easy).
- Training mode tools (frame data display, dummy recording, hitbox viewer).
- More stages, music, announcer VO.
- Super meter + EX moves.
- Ranked / casual matchmaking later.



### Priority Order for “Fun” Feel

1. Input buffer + 1-frame response on normals.
2. Satisfying hitstop + sparks + screen shake.
3. Launchers that feel floaty but juggleable.
4. Clear cancel routes for short combos (3–6 hits).
5. Distinct character identities (Ryuji zoning + anti-air, Titan oppressive grabs + armor).

This plan delivers a fully playable vertical slice with clean architecture that is easy to extend. Start with movement + one attack, then iterate on combat feel before adding the second character and match flow.

Would you like me to expand any specific part into full starter code (e.g. CharacterBase + StateMachine + InputBuffer + one MoveData example)?