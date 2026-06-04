extends Node3D

var afternoon_horizon_color: Color = Color(0.161, 0.067, 0.0)
var afternoon_sky_color: Color = Color(0.341, 0.086, 0.027)
var afternoon_color : Color = Color(0.976, 0.678, 0.459)

var night_horizon_color : Color = Color(0.07, 0.05, 0.1)
var night_sky_color : Color = Color(0.005, 0.035, 0.1)
var night_color : Color = Color(0.069, 0.256, 0.381)

var night_light_level : float = 0.02
var afternoon_light_level : int = 1

var night_cloud : float = 0.4
var afternoon_cloud : int = 1

@export var environment : WorldEnvironment
@export var sun : DirectionalLight3D
@export var sky_box : MeshInstance3D

func _ready() -> void:
	await owner.ready
	global.lighting = self
	set_night()

func set_night() -> void:
	RenderingServer.global_shader_parameter_set("sky_color", night_sky_color)
	RenderingServer.global_shader_parameter_set("horizon_color", night_horizon_color)
	RenderingServer.global_shader_parameter_set("cloud_intensity", night_cloud)
	sun.light_energy = night_light_level
	sky_box.show()
	environment.environment.fog_enabled = true
	environment.environment.ambient_light_color = night_color

func set_afternoon() -> void:
	RenderingServer.global_shader_parameter_set("sky_color", afternoon_sky_color)
	RenderingServer.global_shader_parameter_set("horizon_color", afternoon_horizon_color)
	RenderingServer.global_shader_parameter_set("cloud_intensity", afternoon_cloud)
	sun.light_energy = afternoon_light_level
	sky_box.hide()
	environment.environment.fog_enabled = false
	environment.environment.ambient_light_color = afternoon_color
