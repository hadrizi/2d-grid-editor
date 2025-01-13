extends Control
class_name LevelEditorGrid

# Define a signal to send the clicked cell world coordinates
signal cell_placed(world_coords: Vector2)
signal cell_removed(world_coords: Vector2)

@export_category("Grid Settings")
@export var debug: bool = false

@export_group("Zoom Properties")
@export var min_zoom: float = .45
@export var max_zoom: float = 5.
@export_range(1.1, 2, 0.1) var zoom_in_multiplier: float = 1.1
@export_range(0.1, 0.9, 0.1) var zoom_out_multiplier: float = 0.9

@export_group("Grid Line Properties")
@export var enable_grid_lines: bool = true
@export_color_no_alpha var grid_line_color: Color = Color(0.8, 0.8, 0.8)
@export_range(1, 2, 0.1) var grid_line_width: float = 1

@export_group("Cells Properties")
@export var enable_cell_hovering: bool = true
@export var enable_cell_clicking: bool = true
@export var hovered_cell_color: Color = Color(1, 1, 0, 0.5)
@export var clicked_cell_color: Color = Color(0.2, 0.6, 0.2, 0.5)

@export_group("Coordinate Lines Properties")
@export var coordinate_arrow_size: float = 10.
@export_color_no_alpha var x_axis_color = Color(1, 0, 0)
@export_color_no_alpha var y_axis_color = Color(0, 1, 0)
@export var x_coordinate_line_size: float = 2.
@export var y_coordinate_line_size: float = 2.

# Grid variables
var grid_spacing: float = 64.0
var zoom_level: float = 1.0
var offset: Vector2 = Vector2.ZERO

# Dragging control
var is_dragging: bool = false

# Mouse control
var mouse_position: Vector2 = Vector2.ZERO
var mouse_inside: bool = false

# Hover and click control variables
var clicked_cells: Array[Vector2] = []

func _ready():
	assert(min_zoom <= max_zoom)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _input(event):
	if not mouse_inside:
		return

	var mouse_world_pos_before = (mouse_position - offset) / zoom_level
	
	if event.is_action("grid_mouse_in"):
		_input_zoom(mouse_world_pos_before, true)
		queue_redraw()
	if event.is_action("grid_mouse_out"):
		_input_zoom(mouse_world_pos_before, false)
		queue_redraw()

	if event.is_action_pressed("grid_drag"):
		is_dragging = true
	if event.is_action_released("grid_drag"):
		is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		offset += event.relative  # Adjust offset by mouse movement
		queue_redraw()

	if event.is_action_pressed("grid_place_cell") and enable_cell_clicking:
		_input_click_cell()
		queue_redraw()
	if event.is_action_pressed("grid_remove_cell") and enable_cell_clicking:
		_input_click_cell(true)
		queue_redraw()

	# Update hover position
	if event is InputEventMouseMotion and not is_dragging:
		mouse_position = get_local_mouse_position()
		queue_redraw()


func _draw():
	# Adjust grid spacing by zoom level
	var scaled_grid_spacing = grid_spacing * zoom_level

	_draw_grid_lines(scaled_grid_spacing)
	_draw_grid_coordinates(scaled_grid_spacing)
	_draw_highlight_hovered_cell(scaled_grid_spacing)
	_draw_clicked_cells(scaled_grid_spacing)
	_draw_coordinate_arrows()


func _input_zoom(mouse_world_pos_before: Vector2, zoom_in: bool):
	if zoom_in:
		zoom_level = clampf(zoom_level * zoom_in_multiplier, min_zoom, max_zoom)
	else:
		zoom_level = clampf(zoom_level * zoom_out_multiplier, min_zoom, max_zoom)

	var mouse_world_pos_after = (mouse_position - offset) / zoom_level
	offset += (mouse_world_pos_after - mouse_world_pos_before) * zoom_level


func _input_click_cell(remove: bool = false):
	var world_coords = __get_hovered_cell_world_coords()
	
	if world_coords not in clicked_cells and not remove:
		clicked_cells.append(world_coords)
		cell_placed.emit(world_coords)
	
	if world_coords in clicked_cells and remove:
		clicked_cells.erase(world_coords)
		cell_removed.emit(world_coords)


func _draw_grid_lines(scaled_grid_spacing):
	if not enable_grid_lines:
		return
	
	# Calculate the number of vertical and horizontal lines needed
	var horizontal_lines = int(ceil(size.x / scaled_grid_spacing)) + 1
	var vertical_lines = int(ceil(size.y / scaled_grid_spacing)) + 1

	# Draw horizontal and vertical grid lines
	for x in range(horizontal_lines):
		var x_pos = fmod(offset.x, scaled_grid_spacing) + x * scaled_grid_spacing
		if x_pos >= 0 and x_pos <= size.x:  # Limit drawing to the Control node bounds
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y), grid_line_color, grid_line_width)

	for y in range(vertical_lines):
		var y_pos = fmod(offset.y, scaled_grid_spacing) + y * scaled_grid_spacing
		if y_pos >= 0 and y_pos <= size.y:  # Limit drawing to the Control node bounds
			draw_line(Vector2(0, y_pos), Vector2(size.x, y_pos), grid_line_color, grid_line_width)


func _draw_clicked_cells(scaled_grid_spacing):
	for clicked_cell in clicked_cells:
		var clicked_rect = __create_bound_rect(clicked_cell * grid_spacing, scaled_grid_spacing)

		# Only draw the cell if it's within the control node
		draw_rect(
			clicked_rect,
			clicked_cell_color, true
		)


func _draw_highlight_hovered_cell(scaled_grid_spacing):
	if is_dragging or not enable_cell_hovering:
		return

	var hovered_cell_pos = __get_hovered_cell_world_coords() * grid_spacing

	var hover_rect = __create_bound_rect(hovered_cell_pos, scaled_grid_spacing)
	draw_rect(hover_rect, hovered_cell_color, true)


func __get_hovered_cell_world_coords():
	# Get the world coordinates of the hovered cell
	var local_mouse_pos = (mouse_position - offset) / zoom_level
	var hovered_cell_x = floor(local_mouse_pos.x / grid_spacing)
	var hovered_cell_y = floor(local_mouse_pos.y / grid_spacing)
	return Vector2(hovered_cell_x, hovered_cell_y)


func __create_bound_rect(pos: Vector2, side_size: float) -> Rect2:
	# Convert cell coordinates back to screen space (with zoom and offset)
	var cell_screen_pos = pos * zoom_level + offset
	var cell_size = Vector2(side_size, side_size)
	
	# Check if cell is inside Control node if not return zero-sized rect
	var testr = Rect2(cell_screen_pos, Vector2(side_size, side_size))
	if not Rect2(0, 0, size.x, size.y).intersects(testr):
		return Rect2(0, 0, 0, 0)

	if cell_screen_pos.x < 0:
		cell_size.x = cell_screen_pos.x + side_size
		cell_screen_pos.x = 0.
	if cell_screen_pos.y < 0:
		cell_size.y = cell_screen_pos.y + side_size
		cell_screen_pos.y = 0.
	
	if cell_screen_pos.x + side_size > size.x:
		cell_size.x = size.x - cell_screen_pos.x
	if cell_screen_pos.y + side_size > size.y:
		cell_size.y = size.y - cell_screen_pos.y

	return Rect2(cell_screen_pos, cell_size)


# Used for debugging purposes
func _draw_grid_coordinates(scaled_grid_spacing):
	if not debug:
		return

	# Loop through visible grid cells and draw coordinates
	for x in range(int(ceil(size.x / scaled_grid_spacing)) + 1):
		for y in range(int(ceil(size.y / scaled_grid_spacing)) + 1):
			# Calculate the grid cell position based on the offset and zoom level
			var x_pos = fmod(offset.x, scaled_grid_spacing) + x * scaled_grid_spacing
			var y_pos = fmod(offset.y, scaled_grid_spacing) + y * scaled_grid_spacing

			# Ensure we only draw within the bounds of the Control node
			if x_pos < 0 or x_pos > size.x or y_pos < 0 or y_pos > size.y:
				continue

			# Calculate the actual world coordinates of the grid cell
			var cell_x_world = floor((x_pos - offset.x) / scaled_grid_spacing)
			var cell_y_world = floor((y_pos - offset.y) / scaled_grid_spacing)

			# Convert the coordinates to screen space
			var screen_pos = Vector2(x_pos, y_pos)

			# Display the world coordinates in the center of each cell
			var cell_coordinates = "(%d, %d)" % [cell_x_world, cell_y_world]
			draw_string(
				ThemeDB.fallback_font,
				screen_pos + Vector2(5, 20),
				cell_coordinates
			)


func _draw_coordinate_arrows():
	# Draw the X-axis line
	var start_x = Vector2(0, offset.y)
	if start_x.y >= 0 and start_x.y <= size.y:
		draw_line(
			Vector2(0, offset.y), Vector2(size.x, offset.y),
			x_axis_color, x_coordinate_line_size
		)
	
	var x_arrow_end_pos = Vector2(size.x, offset.y)
	var x_arrow_left_pos = Vector2(0, offset.y)

	if x_arrow_end_pos.y >= 0 and x_arrow_end_pos.y <= size.y:
		# Positive X arrow (right side)
		draw_line(
			x_arrow_end_pos, x_arrow_end_pos + Vector2(-coordinate_arrow_size, coordinate_arrow_size / 2),
			x_axis_color, x_coordinate_line_size
		)
		draw_line(
			x_arrow_end_pos, x_arrow_end_pos + Vector2(-coordinate_arrow_size, -coordinate_arrow_size / 2),
			x_axis_color, x_coordinate_line_size
		)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(size.x - 40, offset.y + 20),
			"X", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, x_axis_color
		)
	
	if x_arrow_left_pos.y >= 0 and x_arrow_left_pos.y <= size.y:
		# Negative X arrow (left side)
		draw_line(
			x_arrow_left_pos, x_arrow_left_pos + Vector2(coordinate_arrow_size, coordinate_arrow_size / 2),
			x_axis_color, x_coordinate_line_size
		)
		draw_line(
			x_arrow_left_pos, x_arrow_left_pos + Vector2(coordinate_arrow_size, -coordinate_arrow_size / 2),
			x_axis_color, x_coordinate_line_size
		)

	# Draw Y-axis line
	var start_y = Vector2(offset.x, 0)
	if start_y.x >= 0 and start_y.x <= size.x:
		draw_line(
			Vector2(offset.x, 0), Vector2(offset.x, size.y),
			y_axis_color, y_coordinate_line_size
		)

	var y_arrow_top_pos = Vector2(offset.x, 0)
	var y_arrow_bottom_pos = Vector2(offset.x, size.y)

	if y_arrow_top_pos.x >= 0 and y_arrow_top_pos.x <= size.x:
		# Positive Y arrow (up)
		draw_line(
			y_arrow_top_pos, y_arrow_top_pos + Vector2(-coordinate_arrow_size / 2, coordinate_arrow_size),
			y_axis_color, y_coordinate_line_size
		)
		draw_line(
			y_arrow_top_pos, y_arrow_top_pos + Vector2(coordinate_arrow_size / 2, coordinate_arrow_size), 
			y_axis_color, y_coordinate_line_size
		)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(offset.x + 10, 20), 
			"Y", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, y_axis_color
		)
	
	if y_arrow_bottom_pos.x >= 0 and y_arrow_bottom_pos.x <= size.x:
		# Negative Y arrow (down)
		draw_line(
			y_arrow_bottom_pos, y_arrow_bottom_pos + Vector2(-coordinate_arrow_size / 2, -coordinate_arrow_size),
			y_axis_color, y_coordinate_line_size
		)
		draw_line(
			y_arrow_bottom_pos, y_arrow_bottom_pos + Vector2(coordinate_arrow_size / 2, -coordinate_arrow_size),
			y_axis_color, y_coordinate_line_size
		)


func _on_mouse_entered():
	mouse_inside = true


func _on_mouse_exited():
	mouse_inside = false
