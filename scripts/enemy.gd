extends CharacterBody3D

signal defeated(enemy: Node)

const SNOWBALL_SCRIPT := preload("res://scripts/snowball.gd")

var target: Node3D
var enemy_index := 0
var enemy_kind := "standard"
var display_name := "Adversaire"
var look_id := 0
var main_color := Color("ef5d60")

var hit_points := 3
var throw_timer := 1.2
var throw_interval := 2.0
var strafe_phase := 0.0
var strafe_strength := 0.45
var phase_speed := 1.0
var move_speed := 1.05
var preferred_distance := 5.5
var snowball_speed := 8.0
var base_scale := 1.0
var activation_distance := 18.0
var body_material: StandardMaterial3D
var defeated_once := false
var activated := false

var knockback_timer := 0.0
var knockback_velocity := Vector3.ZERO

func setup(player_target: Node3D, profile: Dictionary, index: int) -> void:
    target = player_target
    enemy_index = index
    enemy_kind = String(profile.get("kind", "standard"))
    display_name = String(profile.get("display_name", "Adversaire"))
    look_id = int(profile.get("look", 0))
    main_color = profile.get("color", Color("ef5d60"))
    activation_distance = float(profile.get("activation_distance", 18.0))
    strafe_phase = float(index) * 1.8

    set_meta("team", "enemy")
    set_meta("display_name", display_name)
    add_to_group("enemies")

    _configure_kind()
    _build_visual()
    print("%s : type=%s, vie=%d" % [display_name, enemy_kind, hit_points])

func _configure_kind() -> void:
    match enemy_kind:
        "runner":
            hit_points = 2
            move_speed = 1.85
            preferred_distance = 4.2
            throw_interval = 1.75
            snowball_speed = 8.6
            base_scale = 0.90
            phase_speed = 1.25
        "sniper":
            hit_points = 2
            move_speed = 0.72
            preferred_distance = 9.5
            throw_interval = 2.7
            snowball_speed = 10.5
            base_scale = 0.96
        "tank":
            hit_points = 5
            move_speed = 0.62
            preferred_distance = 5.0
            throw_interval = 3.0
            snowball_speed = 7.7
            base_scale = 1.18
        "rapid":
            hit_points = 2
            move_speed = 1.15
            preferred_distance = 6.0
            throw_interval = 1.15
            snowball_speed = 8.5
            base_scale = 0.94
        "zigzag":
            hit_points = 3
            move_speed = 1.35
            preferred_distance = 5.0
            throw_interval = 2.0
            snowball_speed = 8.2
            strafe_strength = 0.95
            phase_speed = 1.75
            base_scale = 0.96
        "boss":
            hit_points = 8
            move_speed = 0.82
            preferred_distance = 5.5
            throw_interval = 1.65
            snowball_speed = 9.2
            strafe_strength = 0.60
            base_scale = 1.30
        _:
            hit_points = 3
            move_speed = 1.05
            preferred_distance = 5.5
            throw_interval = 2.1
            snowball_speed = 8.0
            base_scale = 1.0

func _build_visual() -> void:
    body_material = _material(main_color)
    var skin := _material(Color("f0c39e"))
    var dark := _material(Color("26333d"))
    var pale := _material(Color("e8f4f9"))

    _add_capsule("Corps", Vector3(0.0, 0.98, 0.0), 0.38, 1.25, body_material)
    _add_sphere("Tete", Vector3(0.0, 1.78, 0.0), 0.28, skin)

    _add_cylinder("JambeG", Vector3(-0.18, 0.30, 0.0), 0.12, 0.58, dark)
    _add_cylinder("JambeD", Vector3(0.18, 0.30, 0.0), 0.12, 0.58, dark)
    _add_cylinder("BrasG", Vector3(-0.47, 1.05, 0.0), 0.10, 0.72, body_material, Vector3(0, 0, -8))
    _add_cylinder("BrasD", Vector3(0.47, 1.05, 0.0), 0.10, 0.72, body_material, Vector3(0, 0, 8))

    _add_sphere("OeilG", Vector3(-0.095, 1.82, -0.255), 0.035, dark)
    _add_sphere("OeilD", Vector3(0.095, 1.82, -0.255), 0.035, dark)

    _add_headwear(dark, pale)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.75
    collision.position.y = 0.9
    collision.shape = shape
    add_child(collision)

    if enemy_kind == "tank" or enemy_kind == "boss":
        _add_box("BouclierNeige", Vector3(-0.62, 1.00, -0.08), Vector3(0.14, 0.95, 0.70), pale)

    scale = Vector3.ONE * base_scale

func _add_headwear(dark: Material, pale: Material) -> void:
    match look_id % 8:
        0:
            _add_cylinder("Bonnet", Vector3(0, 2.08, 0), 0.30, 0.25, body_material)
            _add_sphere("Pompon", Vector3(0, 2.29, 0), 0.10, pale)
        1:
            _add_cylinder("Bonnet", Vector3(0, 2.08, 0), 0.30, 0.24, body_material)
            _add_sphere("CacheOreilleG", Vector3(-0.30, 1.86, 0), 0.10, dark)
            _add_sphere("CacheOreilleD", Vector3(0.30, 1.86, 0), 0.10, dark)
        2:
            _add_cylinder("Bonnet", Vector3(0, 2.07, 0), 0.30, 0.22, body_material)
            _add_box("LunetteG", Vector3(-0.105, 1.84, -0.285), Vector3(0.16, 0.09, 0.04), dark)
            _add_box("LunetteD", Vector3(0.105, 1.84, -0.285), Vector3(0.16, 0.09, 0.04), dark)
        3:
            _add_cylinder("BonnetHaut", Vector3(0, 2.14, 0), 0.25, 0.42, body_material)
        4:
            _add_sphere("Capuche", Vector3(0, 1.82, 0.09), 0.34, body_material)
            _add_sphere("Visage", Vector3(0, 1.78, -0.08), 0.27, _material(Color("f0c39e")))
        5:
            _add_box("Bandeau", Vector3(0, 1.98, -0.20), Vector3(0.56, 0.10, 0.08), body_material)
        6:
            _add_cylinder("ColEcharpe", Vector3(0, 1.52, 0), 0.31, 0.18, body_material)
            _add_box("Echarpe", Vector3(0.22, 1.28, 0.10), Vector3(0.16, 0.55, 0.12), body_material, Vector3(0, 0, -12))
        7:
            _add_cylinder("Bonnet", Vector3(0, 2.08, 0), 0.30, 0.24, body_material)
            _add_box("MoustacheG", Vector3(-0.07, 1.68, -0.27), Vector3(0.13, 0.045, 0.04), dark, Vector3(0, 0, -12))
            _add_box("MoustacheD", Vector3(0.07, 1.68, -0.27), Vector3(0.13, 0.045, 0.04), dark, Vector3(0, 0, 12))

func _physics_process(delta: float) -> void:
    if target == null or defeated_once:
        return

    var to_player := target.global_position - global_position
    to_player.y = 0.0
    var distance := to_player.length()

    if not activated:
        velocity = Vector3.ZERO
        if distance > activation_distance:
            return
        activated = true
        throw_timer = 0.8 + float(enemy_index % 4) * 0.18
        print("%s entre dans la bataille !" % display_name)

    if knockback_timer > 0.0:
        knockback_timer -= delta
        velocity = knockback_velocity
        knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, minf(1.0, delta * 5.0))
        move_and_slide()
        return

    throw_timer -= delta
    strafe_phase += delta * phase_speed * (0.85 + enemy_index * 0.01)

    if distance > preferred_distance:
        var approach := to_player.normalized()
        var side := Vector3(-approach.z, 0.0, approach.x) * sin(strafe_phase) * strafe_strength
        velocity = (approach + side).normalized() * move_speed
    elif distance < preferred_distance - 1.6 and enemy_kind == "sniper":
        velocity = -to_player.normalized() * move_speed
    else:
        var side_only := Vector3(-to_player.z, 0.0, to_player.x).normalized()
        velocity = side_only * sin(strafe_phase) * move_speed * maxf(0.55, strafe_strength)

    move_and_slide()

    if to_player.length() > 0.01:
        look_at(global_position + to_player, Vector3.UP)

    if throw_timer <= 0.0 and distance < 16.0:
        _throw_at_player()
        throw_timer = throw_interval + float(enemy_index % 3) * 0.16

func _throw_at_player() -> void:
    var ball := RigidBody3D.new()
    ball.name = "BouleEnnemie"
    ball.set_script(SNOWBALL_SCRIPT)
    get_tree().current_scene.add_child(ball)
    ball.global_position = global_position + Vector3(0.0, 1.45, 0.0)
    ball.call("setup", "enemy", 0.105 if enemy_kind != "boss" else 0.15, self, 1, false)

    var aim_point := target.global_position + Vector3(0.0, 1.15, 0.0)
    var direction := (aim_point - ball.global_position).normalized()
    ball.linear_velocity = direction * snowball_speed + Vector3.UP * 0.85

func take_hit(amount: int, impulse: Vector3 = Vector3.ZERO) -> void:
    if defeated_once:
        return

    hit_points -= amount
    activated = true

    if impulse.length() > 0.1:
        knockback_timer = 0.34
        knockback_velocity = impulse

    scale = Vector3.ONE * base_scale * 1.07
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector3.ONE * base_scale, 0.12)

    if hit_points <= 0:
        _defeated()

func _defeated() -> void:
    if defeated_once:
        return

    defeated_once = true
    defeated.emit(self)
    set_physics_process(false)
    velocity = Vector3.ZERO

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "rotation_degrees:z", 90.0, 0.35)
    tween.tween_property(self, "position:y", 0.1, 0.35)
    tween.chain().tween_interval(0.45)
    tween.chain().tween_callback(queue_free)

func _add_capsule(node_name: String, pos: Vector3, radius: float, height: float, mat: Material) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    item.mesh = mesh
    item.position = pos
    item.material_override = mat
    add_child(item)

func _add_sphere(node_name: String, pos: Vector3, radius: float, mat: Material) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    item.mesh = mesh
    item.position = pos
    item.material_override = mat
    add_child(item)

func _add_cylinder(node_name: String, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    item.mesh = mesh
    item.position = pos
    item.rotation_degrees = rot
    item.material_override = mat
    add_child(item)

func _add_box(node_name: String, pos: Vector3, size: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
    var item := MeshInstance3D.new()
    item.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.position = pos
    item.rotation_degrees = rot
    item.material_override = mat
    add_child(item)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    return mat
