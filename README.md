# Deja Mew

A very small, single-screen 2D platformer built in **Godot 4.7**.

Everything is a **graybox**: flat, single-colour rectangles only. There is no
generated art, music, or other assets. Levels are painted and edited entirely
with Godot's built-in GUI tools.

The core idea: every death leaves a **recorded ghost of your past attempt**.
Ghosts replay alongside you, press buttons, hold doors, and eventually become
solid platforms. Level 1 gives you 0 ghosts; level 9 gives you 8 — nine lives
for a cat.

## Features

- 16x16 tile grid with a real `TileMapLayer` + `TileSet` (paintable in the editor).
- Fixed camera: 512x288 internal resolution, each level is one 32x18 tile room.
- Celeste-inspired player controller:
  - Arrow-key movement
  - Jump with coyote time, jump buffering, and variable height
  - 8-directional dash (X), refills on the floor
  - Wall slide and wall jump
  - Grab (Z) and a two-tile wall scamper (Z + Up)
- Graybox cat visual is 20x12: horizontal on all fours by default, rotated toward
  the dash direction (including diagonals), and upright for scampering/up-dashes.
- Ghost replay system with per-level budgets (level number - 1).
- Celeste-style **wavedash**: down-diagonal dash into the floor, then jump.
- Pressure buttons, sliding doors (momentary or permanent), moving platforms, and hazards.
- Nine independent level scenes; **level 2 showcases ghosts + doors**, and
  **level 3 showcases the keyframed ferry platform**.
- HUD with level name, ghost counter, and per-level hint.
- Level progression, completion screen, and full reset.

## Controls

| Action | Key |
| --- | --- |
| Move | Arrow keys |
| Jump | C |
| Dash | X |
| Grab | Z (hold) |
| Scamper up a wall | Z + Up |
| Wall jump | C while airborne against a wall |
| Wavedash | Down-diagonal dash into the ground, then C during the dash |
| Give up / leave a ghost | G |
| Reset level and all ghosts | R |
| Quit | Esc |

## Running

Open `project.godot` in Godot **4.7** and press **F5** to play the whole run, or
press **F6** while a level scene is open to test that level by itself.

From a terminal:

```bash
godot --path .
```

## Wavedash

A Celeste-style wavedash:

1. Dash **down-diagonally** into the floor (e.g. Down + Right + X).
2. Press **C** while the dash is still active and you are on the ground.

The dash is canceled into a jump with a horizontal boost (`wavedash_speed`,
default 320) and a short speed-carry window (`wavedash_carry_time`, default
0.22 s). Jump input is buffered through the dash freeze, so pressing C early
still works. Holding the dash direction preserves the boost; braking against it
reduces it.

Tune it on the Player under **Wavedash** in the Inspector.

## The ghost mechanic

- Every attempt is recorded at 60 Hz: position and the cat's sprite pose.
- Pressing **G** (or dying) finalizes the recording at your exact current spot.
- If the level has ghost budget left, that recording becomes a ghost.
- You respawn at `Spawn`, and **all ghosts restart their replays from frame 0**
  in sync with your new attempt.
- When a ghost's replay ends, it **stays at its final spot** as a solid statue.
- Fall deaths are clipped to the last on-screen frame, so the ghost ends at the
  room edge instead of below the floor.
- Ghost budgets are automatic: level 1 → 0, level 2 → 1, … level 9 → 8.
- Once the budget is full, further deaths/give-ups respawn you without adding a
  ghost; the existing ghosts still replay.
- **Death/G resets the world**: buttons release, doors close, permanent latches
  clear. Ghosts and their recordings remain. Their replays re-trigger the world.
- **R** reloads the level and clears every ghost and attempt.

### Ghost collision layers

| Layer | Name | Used by |
| --- | --- | --- |
| 1 | World | Tiles, player, doors, hazards |
| 2 | Ghost Sensor | Ghosts, always active; buttons detect this |
| 3 | Ghost Solid | Ghosts after `solid_delay` (default 2 s) |

- A ghost presses buttons from the moment it touches them.
- After the solid delay, it can be stood on, wall-jumped off, and can push you.
- Ghosts do not collide with doors, hazards, exits, or each other.
- `solid_delay` is exported on each level root (`ghost_solid_delay`) and on the
  Ghost scene.

## Buttons and doors

### PressureButton

- `scenes/objects/pressure_button.tscn`.
- An `Area2D` pad that detects the player and ghosts.
- Emits `pressed_changed(bool)`, plus `pressed` and `released`.
- Place it with its origin on the floor line so the pad sits on the surface.
- It can be connected to custom scripts through the Signals panel.

### Door

- `scenes/objects/door.tscn`.
- A sliding `AnimatableBody2D` (16x32 by default) that opens upward.
- Inspector options:
  - **Buttons** — drag one or more pressure button nodes into this array.
  - **Open Mode** — `While Pressed` or `Permanently`.
  - **Require All Buttons** — for multi-plate doors.
  - **Slide Distance / Slide Time**.
- A single button can drive multiple doors by adding it to each door's array.
- Place the door so its bottom sits on the floor and it fills the doorway.

Level 2 is already wired as an example: its `Door` node has the
`PressureButton` node in its **Buttons** array. Open the scene and select the
door to see the link.

## Moving platforms

- `scenes/objects/moving_platform.tscn`.
- The root is an `AnimationPlayer`; `PlatformBody` is an `AnimatableBody2D`
  carrying the visual and collision.
- The **Move** animation keyframes `PlatformBody:position`; the first keyframe
  is also the platform's resting position (shown in the editor by a small tool
  script).
- Inspector options:
  - **Buttons** — drag one or more pressure buttons here.
  - **Require All Buttons**.
  - **Rewind Delay** (default 2 s) and **Rewind Speed**.
- Behavior:
  - While the pad is held, the looping animation plays.
  - On release, the platform freezes, waits `rewind_delay`, then reverses along
    the animation back to time 0 and stops.
  - Pressing the pad during the wait/rewind resumes forward from the current
    position.
  - Death/G immediately resets the platform to its first keyframe; R reloads it.
- The platform is an `AnimatableBody2D`, so it carries the player while riding.

### Editing a platform path

1. Select the platform instance (an `AnimationPlayer`).
2. Open the **Animation** panel and choose **Move**.
3. Select `PlatformBody`, move it, and insert position keyframes at the desired
   times.
4. Adjust the animation length and loop mode. The first key is the resting spot.
5. Tune **Rewind Delay / Rewind Speed** on the platform.

### Per-instance animations

The reusable scene contains a sample **Move** animation. To give a new instance
its own path:

1. Instantiate `moving_platform.tscn`.
2. Select the instance (the `AnimationPlayer`).
3. Make its animation library unique:
   - **Animation** panel → **Manage Animations** (disk icon) → **Make Unique**, or
   - Inspector → **AnimationMixer → Libraries** → right-click → **Make Unique**.
4. Edit the **Move** animation.

Level 3's ferry instance already has a unique, local animation library, so you
can edit its path without affecting the template. You can also duplicate the
level 3 ferry node as a starting point.

## Level 2: “Hold the Button”

- A pressure pad sits on the floor near the start.
- A full-height pillar divides the room; a door blocks the only passage.
- Step on the pad and the door opens; step off and it closes.
- The pad is too far from the door to reach while standing on it.
- Press **G** on the pad: your ghost records the walk, respawns you, then
  replays the walk and stops on the pad, holding the door open.
- Follow it through the doorway to the exit.
- Level 2 has exactly one ghost. The HUD shows `Ghosts 0 / 1` and a hint.

## Level 3: “Ghost Ferry”

- The floor has an 11-tile pit; the exit is on the right ledge.
- A pressure pad on the left ledge is linked to the moving platform's
  **Buttons** array.
- Press **G** on the pad. Your ghost replays the walk, holds the pad down, and
  starts the ferry.
- Board during the platform's left-dock hold, ride across, and step off at the
  right ledge.
- The platform has a 6-second loop: 2 s hold left, 1 s move right, 2 s hold
  right, 1 s move back.
- Level 3 has **2 ghosts**; one is enough to solve it.
- Hint: *“Leave a ghost on the pad to power the ferry.”*

Levels 4–9 are still empty bordered rooms, ready to design.

## Editing levels

1. Open a level scene, e.g. `scenes/levels/level_02.tscn`.
2. Select the `Solid` node (a `TileMapLayer`).
3. Open the **TileMap** panel and paint with left-click / erase with right-click.
4. Move the `Spawn` marker to change where the player and ghosts start.
5. Move the `Exit` area to change where the level ends.
6. Select the level root to edit:
   - `level_number` — also determines the ghost budget.
   - `level_count` — default 9.
   - `level_name` — shown in the HUD.
   - `hint` — optional on-screen tutorial text.
   - `ghost_solid_delay` — seconds before ghosts become solid.
7. Drag `scenes/objects/pressure_button.tscn`, `door.tscn`,
   `moving_platform.tscn`, and `hazard.tscn` into a level as needed.
8. Link a door by selecting it and dragging the button node into its **Buttons**
   array in the Inspector. Link a moving platform the same way.

The nine levels are **independent copies**. `level_base.tscn` is a clean bordered
room to duplicate. The player and every ghost start at the `Spawn` marker at
runtime.

## Hazards and falling

- `scenes/objects/hazard.tscn` is a flat red hazard Area2D.
- It kills only the living player; ghosts ignore it.
- Touching a hazard leaves a ghost at the contact spot and respawns you.
- Falling below the room (y > 320) also counts as a death. The ghost recording is
  clipped to the last on-screen frame.
- Levels 2 and 3 do not use hazards; they are there for later levels.

## Adding a level

1. Duplicate an existing level scene and save it as `level_10.tscn` (or any name).
2. Set `level_number` and `level_count` on the root in the Inspector.
3. Open `scenes/main.tscn`, select `Main`, and add the new scene to the `levels`
   array in the Inspector. Reorder the array to change the order.
4. The completion overlay appears after the last entry in the array.

## Tuning

Select `Player` in `scenes/player/player.tscn` for the movement exports:

- **Run** - speed, acceleration, air control
- **Jump** - jump speed, gravity, fall speed, coyote/buffer times
- **Dash** - speed, duration, freeze frames, end speed, dashes per airtime
- **Wavedash** - horizontal boost speed and boost-carry time
- **Wall** - wall slide/grab speeds, wall jump, scamper speed and distance

Ghost, door, and platform tuning:

- Level root: `ghost_solid_delay`.
- Door: `slide_distance`, `slide_time`, `open_mode`, `require_all_buttons`.
- Ghost scene: default `solid_delay`.
- Moving platform: `buttons`, `require_all_buttons`, `rewind_delay`,
  `rewind_speed`, `animation_name`.
- Player: `scamper_distance` defaults to 34 px (about two 16 px tiles).

## Project layout

```
assets/                 Flat-colour PNGs
resources/              graybox_tileset.tres
scenes/
  main.tscn             Level loader / progression
  player/player.tscn
  objects/
    exit.tscn
    ghost.tscn          Recorded replay body
    pressure_button.tscn
    door.tscn
    moving_platform.tscn Keyframed button-powered platform
    hazard.tscn
  ui/hud.tscn           Level / ghost / hint labels
  levels/
    level_base.tscn     Bordered template room
    level_01..09.tscn   Independent levels; 02 and 03 are showcases
scripts/
  player.gd             Movement, respawn
  level.gd              Recording, ghosts, death, world reset, HUD
  ghost.gd              Playback, solid delay, statue
  pressure_button.gd
  door.gd
  moving_platform.gd    Button-driven animation, rewind, reset
  hazard.gd
  main.gd
  hud.gd
tools/
  make_graybox_assets.py
```

## Graybox assets

`tools/make_graybox_assets.py` regenerates the flat-colour textures with Pillow:

```bash
python3 tools/make_graybox_assets.py
```

The TileSet points at `assets/tiles/tile_gray.png`. If you replace that image,
Godot reimports it and the tiles update automatically. Keep the 16x16 size (or
update the TileSet's texture region size) if you change it.

The cat texture (`assets/sprites/cat_graybox.png`) is drawn facing right and is
20x12. The player keeps it horizontal on all fours and rotates it toward the
dash direction; a 90-degree rotation makes it exactly match the 12x20 collision
box. Swap in a right-facing cat later and the same orientation code will work.

## Repository

https://github.com/AJS1597/deja-mew
