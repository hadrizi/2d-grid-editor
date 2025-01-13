# Godot Singe-Node 2D Grid Editor
This is a simple endless 2D grid editor inside single Control node

# Usage
Just attach this script to Control Node and you are good to go

# Actions
- `grid_mouse_in` - zoom in
- `grid_mouse_out` - zoom out
- `grid_drag` - drag button(moving the grid)
- `grid_place_cell` - place cell button
- `grid_remove_cell` - remove cell button

# Signals
- `signal cell_placed(world_coords: Vector2)` sends placed cell's coordinates
- `signal cell_removed(world_coords: Vector2)` sends removed cell's coordinates

# Showcase
https://github.com/user-attachments/assets/dc0d0a52-5ba6-4b76-a4e9-9d450bf6e029

