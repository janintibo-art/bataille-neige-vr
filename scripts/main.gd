extends Node3D

const PLAYER_SCRIPT := preload("res://scripts/player_vr.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")
const ROSTER := preload("res://scripts/roster.gd")

var player_origin: XROrigin3D
var camera: XRCamera3D
var current_wave := 0
var living_enemies := 0
var enemy_serial := 0
var wave_transition := false

func _ready() -> void:
    _init_xr()
    _build_environment()
    _build_player()
    _start_wave(1)

func _init_xr() -> void:
    var xr_interface := XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.initialize():
        get_viewport().use_xr = true
        print("OpenXR initialise")
    else:
        print("OpenXR indisponible : le prototype reste visible en mode ecran")

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("b7d9f3")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("e9f4ff")
    env.ambient_light_energy = 0.8
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

    _add_box_static("Sol", Vector3(34.0, 0.4, 34.0), Vector3(0.0, -0.2, 0.0), Color("f4fbff"))

    _add_box_static("Cabane", Vector3(5.0, 2.8, 4.0), Vector3(0.0, 1.4, -8.0), Color("8d5a3a"))
    _add_box_static("ToitCabane", Vector3(5.8, 0.35, 4.8), Vector3(0.0, 3.0, -8.0), Color("edf7ff"), Vector3(0.0, 0.0, 7.0))

    _add_box_static("MuretG", Vector3(3.2, 1.0, 0.7), Vector3(-5.0, 0.5, -1.0), Color("d9eef8"))
    _add_box_static("MuretD", Vector3(3.2, 1.0, 0.7), Vector3(5.0, 0.5, -1.0), Color("d9eef8"))
    _add_box_static("TasBois", Vector3(2.8, 1.2, 1.2), Vector3(-8.0, 0.6, -6.0), Color("9a6946"))
    _add_box_static("BancNeige", Vector3(3.0, 0.75, 0.8), Vector3(8.0, 0.38, 5.0), Color("e2f2f9"))

    _add_snow_fort()
    _add_snowman_cover("BonhommeG", Vector3(-10.0, 0.0, -5.5))
    _add_snowman_cover("BonhommeD", Vector3(10.0, 0.0, -6.5))

    var tree_positions := [
        Vector3(-9, 0, 5), Vector3(-12, 0, -2), Vector3(-9, 0, -11),
        Vector3(9, 0, 6), Vector3(12, 0, -2), Vector3(10, 0, -11),
        Vector3(-4, 0, 11), Vector3(5, 0, 12)
    ]
    for i in tree_positions.size():
        _add_tree("Sapin_%02d" % i, tree_positions[i])

func _build_player() -> void:
    player_origin = XROrigin3D.new()
    player_origin.name = "Player"
    player_origin.position = Vector3(0.0, 0.0, 8.0)
    player_origin.set_script(PLAYER_SCRIPT)
    add_child(player_origin)

    camera = XRCamera3D.new()
    camera.name = "XRCamera3D"
    camera.position = Vector3(0.0, 1.65, 0.0)
    player_origin.add_child(camera)

    var left := _make_controller("LeftHand", &"left_hand")
    var right := _make_controller("RightHand", &"right_hand")
    player_origin.add_child(left)
    player_origin.add_child(right)

    player_origin.call_deferred("setup", camera, left, right)

    if not get_viewport().use_xr:
        camera.current = true

func _make_controller(node_name: String, tracker_name: StringName) -> XRController3D:
    var controller := XRController3D.new()
    controller.name = node_name
    controller.tracker = tracker_name
    controller.pose = &"grip"

    var hand := MeshInstance3D.new()
    var hand_mesh := SphereMesh.new()
    hand_mesh.radius = 0.065
    hand_mesh.height = 0.13
    hand.mesh = hand_mesh
    hand.material_override = _material(Color("f0c8a2"))
    controller.add_child(hand)
    return controller

func _start_wave(wave_number: int) -> void:
    current_wave = wave_number
    wave_transition = false
    var data := ROSTER.get_wave(wave_number)
    living_enemies = data.size()

    if living_enemies == 0:
        return

    print("=== VAGUE %d/%d ===" % [current_wave, ROSTER.wave_count()])
    for entry in data:
        print(" - %s" % entry["display_name"])

        var enemy := CharacterBody3D.new()
        enemy_serial += 1
        enemy.name = "Adversaire_%02d" % enemy_serial
        enemy.position = entry["position"]
        enemy.set_script(ENEMY_SCRIPT)
        add_child(enemy)

        if enemy.has_signal("defeated"):
            enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))

        enemy.call_deferred("setup", player_origin, entry, enemy_serial)

func _on_enemy_defeated(enemy: Node) -> void:
    living_enemies = max(0, living_enemies - 1)
    var defeated_name := String(enemy.get_meta("display_name", "Adversaire"))
    print("%s elimine. Restants : %d" % [defeated_name, living_enemies])

    if living_enemies > 0 or wave_transition:
        return

    wave_transition = true
    if current_wave >= ROSTER.wave_count():
        print("ZONE SECURISEE ! Les 20 adversaires sont battus.")
        return

    print("Vague terminee. Prochaine vague dans 2 secondes.")
    await get_tree().create_timer(2.0).timeout
    _start_wave(current_wave + 1)

func _add_snow_fort() -> void:
    var snow := Color("dceff8")
    _add_box_static("FortCentre", Vector3(4.6, 1.25, 0.65), Vector3(0.0, 0.62, 3.0), snow)
    _add_box_static("FortGauche", Vector3(0.65, 1.25, 2.6), Vector3(-2.0, 0.62, 4.0), snow)
    _add_box_static("FortDroite", Vector3(0.65, 1.25, 2.6), Vector3(2.0, 0.62, 4.0), snow)

func _add_snowman_cover(node_name: String, pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    add_child(body)

    var lower := MeshInstance3D.new()
    var lower_mesh := SphereMesh.new()
    lower_mesh.radius = 0.72
    lower_mesh.height = 1.44
    lower.mesh = lower_mesh
    lower.position.y = 0.72
    lower.material_override = _material(Color("edf8fc"))
    body.add_child(lower)

    var upper := MeshInstance3D.new()
    var upper_mesh := SphereMesh.new()
    upper_mesh.radius = 0.48
    upper_mesh.height = 0.96
    upper.mesh = upper_mesh
    upper.position.y = 1.78
    upper.material_override = _material(Color("f5fbff"))
    body.add_child(upper)

    var nose := MeshInstance3D.new()
    var nose_mesh := CylinderMesh.new()
    nose_mesh.top_radius = 0.02
    nose_mesh.bottom_radius = 0.09
    nose_mesh.height = 0.38
    nose.mesh = nose_mesh
    nose.rotation_degrees.x = 90.0
    nose.position = Vector3(0.0, 1.78, -0.48)
    nose.material_override = _material(Color("ed8b3d"))
    body.add_child(nose)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.68
    shape.height = 2.15
    collision.position.y = 1.05
    collision.shape = shape
    body.add_child(collision)

func _add_box_static(node_name: String, size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO) -> void:
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    body.rotation_degrees = rot_deg
    add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh_instance.mesh = box
    mesh_instance.material_override = _material(color)
    body.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

func _add_tree(node_name: String, pos: Vector3) -> void:
    var root := StaticBody3D.new()
    root.name = node_name
    root.position = pos
    add_child(root)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.24
    trunk_mesh.height = 2.2
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.1
    trunk.material_override = _material(Color("76503a"))
    root.add_child(trunk)

    for layer in 3:
        var foliage := MeshInstance3D.new()
        var cone := CylinderMesh.new()
        cone.top_radius = 0.0
        cone.bottom_radius = 1.45 - layer * 0.25
        cone.height = 2.2
        foliage.mesh = cone
        foliage.position.y = 2.0 + layer * 0.8
        foliage.material_override = _material(Color("2f6b54"))
        root.add_child(foliage)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 4.0
    collision.position.y = 2.0
    collision.shape = shape
    root.add_child(collision)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    return mat
