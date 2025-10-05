class_name Trail3D extends MeshInstance3D

var _points = []
var _widths = []
var _life_points = []

@export var enabled = true
@export var from_width := 0.5
@export var to_width := 0.0
@export_range(0.5, 1.5) var acceleration := 1.0

@export var motion_delta := 0.1
@export var lifespan := 0.2

@export var start_color : Color = Color(1, 1, 1, 1)
@export var end_color : Color = Color(1, 1, 1, 0)

var old_pos : Vector3

func _ready():
	old_pos = global_transform.origin
	mesh = ImmediateMesh.new()
	
func append_point():
	var basis_x = global_transform.basis.x
	_points.append(global_transform.origin)
	_widths.append([
		basis_x * from_width,
		basis_x * from_width - basis_x * to_width
	])
	_life_points.append(0.0)

func remove_point(i):
	_points.remove_at(i)
	_widths.remove_at(i)
	_life_points.remove_at(i)
	
func _process(delta):
	if (old_pos - global_transform.origin).length() > motion_delta and enabled:
		append_point()
		print(_points)
		old_pos = global_transform.origin
		
	var p = 0
	var max_points = _points.size()
	while p < max_points:
		_life_points[p] += delta
		if _life_points[p] > lifespan:
			remove_point(p)
			p -= 1
			if (p < 0): p = 0
		
		max_points = _points.size()
		p += 1

	mesh.clear_surfaces()

	if _points.size() < 2:
		return

	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, null)
	for i in range(_points.size()):
		var t = float(i)/(_points.size()-1)
		var curr_color = start_color.lerp(end_color, 1 - t)
		mesh.surface_set_color(curr_color)
		var curr_width = _widths[i][0] - pow(1-t, acceleration) * _widths[i][1]

		var dir = Vector3.ZERO
		if i > 0:
			dir = (_points[i] - _points[i-1]).normalized()
		var right = dir.cross(Vector3.UP).normalized() * curr_width

		mesh.surface_add_vertex(to_local(_points[i] + right))
		mesh.surface_add_vertex(to_local(_points[i] - right))
	mesh.surface_end()
