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
- Pressure buttons, sliding doors (momentary or permanent), and hazards.
- Nine independent level scenes; **level 2 is the ghost/button/door showcase**.
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

## Level 2: “Hold the Button”

- A pressure pad sits on the floor near the start.
- A full-height pillar divides the room; a door blocks the only passage.
- Step on the pad and the door opens; step off and it closes.
- The pad is too far from the door to reach while standing on it.
- Press **G** on the pad: your ghost records the walk, respawns you, then
  replays the walk and stops on the pad, holding the door open.
- Follow it through the doorway to the exit.
- Level 2 has exactly one ghost. The HUD shows `Ghosts 0 / 1` and a hint.

Levels 3–9 are still empty bordered rooms, ready to design. They are intentionally
not populated yet.

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
7. Drag `scenes/objects/pressure_button.tscn`, `door.tscn`, and `hazard.tscn`
   into a level as needed.
8. Link a door by selecting it and dragging the button node into its **Buttons**
   array in the Inspector.

The nine levels are **independent copies**. `level_base.tscn` is a clean bordered
room to duplicate. The player and every ghost start at the `Spawn` marker at
runtime.

## Hazards and falling

- `scenes/objects/hazard.tscn` is a flat red hazard Area2D.
- It kills only the living player; ghosts ignore it.
- Touching a hazard leaves a ghost at the contact spot and respawns you.
- Falling below the room (y > 320) also counts as a death. The ghost recording is
  clipped to the last on-screen frame.
- Level 2 does not use hazards; they are there for later levels.

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
- **Wall** - wall slide/grab speeds, wall jump, scamper speed and distance

Ghost and door tuning:

- Level root: `ghost_solid_delay`.
- Door: `slide_distance`, `slide_time`, `open_mode`, `require_all_buttons`.
- Ghost scene: default `solid_delay`.
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
    hazard.tscn
  ui/hud.tscn           Level / ghost / hint labels
  levels/
    level_base.tscn     Bordered template room
    level_01..09.tscn   Independent levels; 02 is the showcase
scripts/
  player.gd             Movement, respawn
  level.gd              Recording, ghosts, death, world reset, HUD
  ghost.gd              Playback, solid delay, statue
  pressure_button.gd
  door.gd
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
