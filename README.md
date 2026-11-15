# Deja Mew

A very small, single-screen 2D platformer scaffold built in **Godot 4.7**.

Everything is a **graybox**: flat, single-colour rectangles only. There is no
generated art, music, or other assets. The project is set up so the levels can
be painted and edited entirely with Godot's built-in GUI tools.

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
- Nine independent level scenes, ready to design.
- Level progression, HUD, exit areas, restart, and a completion screen.
- All movement values exported on the Player for Inspector tuning.

## Controls

| Action | Key |
| --- | --- |
| Move | Arrow keys |
| Jump | C |
| Dash | X |
| Grab | Z (hold) |
| Scamper up a wall | Z + Up |
| Wall jump | C while airborne against a wall |
| Reset level | R |
| Quit | Esc |

## Running

Open `project.godot` in Godot **4.7** and press **F5** to play the whole run, or
press **F6** while a level scene is open to test that level by itself.

From a terminal:

```bash
godot --path .
```

## Editing levels

1. Open a level scene, e.g. `scenes/levels/level_01.tscn`.
2. Select the `Solid` node (a `TileMapLayer`).
3. Open the **TileMap** panel at the bottom of the editor.
4. Select the single gray tile, then paint with left-click and erase with
   right-click. The scene saves like any normal Godot scene.
5. Move the `Spawn` marker to change where the player starts.
6. Move the `Exit` `Area2D` to change where the level ends.
7. Select the level root to edit `level_number`, `level_count`, and
   `level_name` in the Inspector.

The nine levels are **independent copies**, so painting one does not affect the
others. `level_base.tscn` is a clean bordered room you can duplicate when you
want another level. The player always snaps to the `Spawn` marker at runtime,
so you only need to move the marker, not the player instance.

## Adding a level

1. Duplicate an existing level scene and save it as `level_10.tscn` (or any name).
2. Set `level_number` and `level_count` on the root in the Inspector.
3. Open `scenes/main.tscn`, select the `Main` node, and add the new scene to the
   `levels` array in the Inspector. Reorder the array to change the order.
4. The completion overlay appears after the last entry in the array.

## Tuning the feel

Select `Player` in `scenes/player/player.tscn` and adjust the exported groups in
the Inspector:

- **Run** - speed, acceleration, air control
- **Jump** - jump speed, gravity, fall speed, coyote/buffer times
- **Dash** - speed, duration, freeze frames, end speed, dashes per airtime
- **Wall** - wall slide/grab speeds, wall jump, scamper speed and distance

`scamper_distance` defaults to 34 px (about two 16 px tiles) per airtime and
resets when the player lands.

## Project layout

```
assets/                 Flat-colour PNGs
resources/              graybox_tileset.tres
scenes/
  main.tscn             Level loader / progression
  player/player.tscn
  objects/exit.tscn
  ui/hud.tscn
  levels/
    level_base.tscn     Bordered template room
    level_01..09.tscn   Independent, editable levels
scripts/                player.gd, level.gd, main.gd, hud.gd
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
