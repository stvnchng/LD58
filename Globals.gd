extends Node

# Shoot sound signal - emitted when any entity shoots
# entity_type: String - "player", "floater", or "basic"
signal shoot_sound(entity_type: String)

# Player hurt signal - emitted when player takes damage
signal player_hurt

# Player dash signal - emitted when player dashes
signal player_dash

const difficulty_multiplier: float = 1.005

var burning_duration: float = 4.0
var burning_damage: float = 0.08
var burning_interval: float = 1.0

var bleeding_duration: float = 8.0
var bleeding_damage: float = 0.05
var bleeding_interval: float = 1.0

const BASIC_ENEMY := preload("res://entities/enemies/EnemyBasic.tscn")
const LURCH_ENEMY := preload("res://entities/enemies/EnemyLurcher.tscn")
const FLOAT_ENEMY := preload("res://entities/enemies/enemy_floater.tscn")

const enemy_name_to_scn = {
	"basic": BASIC_ENEMY,
	"lurcher": LURCH_ENEMY,
	"floater": FLOAT_ENEMY
}

# Particle effect spawning functions
static func spawn_taffy_effect(position: Vector3, parent: Node) -> void:
	var particles = CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 20
	particles.lifetime = 0.5
	particles.global_position = position
	
	# Set mesh with material for visibility and color
	var mesh = SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.mesh = mesh
	
	# Blue/purple slow effect - set particle color directly
	particles.color = Color(0.5, 0.5, 1.0, 1.0)  # Light blue base
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.5, 0.5, 1.0, 1.0))  # Light blue
	gradient.add_point(1.0, Color(0.3, 0.0, 0.8, 0.0))  # Purple fade
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particles.color_ramp = gradient_texture
	
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.5
	particles.direction = Vector3.UP
	particles.spread = 45.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	particles.gravity = Vector3(0, -5, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	
	parent.add_child(particles)
	await parent.get_tree().create_timer(1.0).timeout
	particles.queue_free()

static func spawn_bleed_effect(position: Vector3, parent: Node) -> void:
	var particles = CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.7
	particles.amount = 15
	particles.lifetime = 0.6
	particles.global_position = position
	
	# Set mesh with material for visibility and color
	var mesh = SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.mesh = mesh
	
	# Dark red blood - set particle color directly
	particles.color = Color(0.8, 0.0, 0.0, 1.0)  # Bright red base
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.0, 0.0, 1.0))  # Bright red
	gradient.add_point(0.5, Color(0.5, 0.0, 0.0, 0.8))  # Dark red
	gradient.add_point(1.0, Color(0.2, 0.0, 0.0, 0.0))  # Very dark fade
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particles.color_ramp = gradient_texture
	
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.3
	particles.direction = Vector3.UP
	particles.spread = 60.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 3.0
	particles.gravity = Vector3(0, -8, 0)
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 0.7
	
	parent.add_child(particles)
	await parent.get_tree().create_timer(1.0).timeout
	particles.queue_free()

static func spawn_death_effect(position: Vector3, parent: Node) -> void:
	var particles = CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.amount = 25
	particles.lifetime = 0.7
	particles.global_position = position
	
	# Set mesh with material for visibility and color
	var mesh = SphereMesh.new()
	mesh.radius = 0.15
	mesh.height = 0.3
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	particles.mesh = mesh
	
	# Blood splatter - set particle color directly
	particles.color = Color(0.9, 0.1, 0.1, 1.0)  # Bright blood red base
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.9, 0.1, 0.1, 1.0))  # Bright blood red
	gradient.add_point(0.4, Color(0.6, 0.0, 0.0, 0.9))  # Dark blood
	gradient.add_point(1.0, Color(0.2, 0.0, 0.0, 0.0))  # Fade out
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particles.color_ramp = gradient_texture
	
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.4
	particles.direction = Vector3.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 5.0
	particles.gravity = Vector3(0, -10, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	
	parent.add_child(particles)
	await parent.get_tree().create_timer(1.2).timeout
	particles.queue_free()
