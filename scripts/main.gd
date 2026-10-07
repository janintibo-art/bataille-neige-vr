extends Node3D

const PLAYER_SCRIPT := preload("res://scripts/player_vr.gd")
const ENEMY_SCRIPT := preload("res://scripts/enemy.gd")

var player_origin: XROrigin3D
var camera: XRCamera3D

func _ready() -> void:
    _init_xr()
    _build_environment()
    _build_player()
    _spawn_enemies()

func _init_xr() -> void:
    var xr_interface := XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.initialize():
        get_viewport().use_xr = true
        print("OpenXR initialisé")
    else:
        print("OpenXR indisponible : le prototype reste visible en mode écran")

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

    # Cabane centrale, volontairement simple et lisible en VR.
    _add_box_static("Cabane", Vector3(5.0, 2.8, 4.0), Vector3(0.0, 1.4, -8.0), Color("8d5a3a"))
    _add_box_static("ToitCabane", Vector3(5.8, 0.35, 4.8), Vector3(0.0, 3.0, -8.0), Color("edf7ff"), Vector3(0.0, 0.0, 7.0))

    # Couvertures basses.
    _add_box_static("MuretG", Vector3(3.2, 1.0, 0.7), Vector3(-5.0, 0.5, -1.0), Color("d9eef8"))
    _add_box_static("MuretD", Vector3(3.2, 1.0, 0.7), Vector3(5.0, 0.5, -1.0), Color("d9eef8"))
    _add_box_static("TasBois", Vector3(2.8, 1.2, 1.2), Vector3(-8.0, 0.6, -6.0), Color("9a6946"))

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

    # Caméra de secours pour voir la scène si OpenXR n'est pas disponible.
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

func _spawn_enemies() -> void:
    var starts := [Vector3(-6, 0, -4), Vector3(6, 0, -5), Vector3(0, 0, -13)]
    var colors := [Color("ef5d60"), Color("51a7e8"), Color("f0b949")]
    for i in starts.size():
        var enemy := CharacterBody3D.new()
        enemy.name = "Adversaire_%02d" % (i + 1)
        enemy.position = starts[i]
        enemy.set_script(ENEMY_SCRIPT)
        add_child(enemy)
        enemy.call_deferred("setup", player_origin, colors[i], i)

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
