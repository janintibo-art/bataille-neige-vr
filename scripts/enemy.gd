extends CharacterBody3D

signal defeated(enemy: Node)

const SNOWBALL_SCRIPT := preload("res://scripts/snowball.gd")

var target: Node3D
var enemy_index := 0
var enemy_kind := "standard"
var hit_points := 3
var throw_timer := 1.2
var throw_interval := 2.0
var strafe_phase := 0.0
var move_speed := 1.05
var preferred_distance := 5.5
var snowball_speed := 8.0
var body_material: StandardMaterial3D
var defeated_once := false

func setup(player_target: Node3D, color: Color, index: int, kind: String = "standard") -> void:
    target = player_target
    enemy_index = index
    enemy_kind = kind
    strafe_phase = float(index) * 1.8
    set_meta("team", "enemy")
    _configure_kind()
    _build_visual(color)

func _configure_kind() -> void:
    match enemy_kind:
        "runner":
            hit_points = 2
            move_speed = 1.8
            preferred_distance = 4.2
            throw_interval = 1.75
            snowball_speed = 8.6
        "sniper":
            hit_points = 2
            move_speed = 0.72
            preferred_distance = 9.5
            throw_interval = 2.7
            snowball_speed = 10.5
        "tank":
            hit_points = 5
            move_speed = 0.62
            preferred_distance = 5.0
            throw_interval = 3.0
            snowball_speed = 7.7
        _:
            hit_points = 3
            move_speed = 1.05
            preferred_distance = 5.5
            throw_interval = 2.1
            snowball_speed = 8.0

func _build_visual(color: Color) -> void:
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = color
    body_material.roughness = 0.9

    var torso := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.25
    torso.mesh = capsule
    torso.position.y = 0.95
    torso.material_override = body_material
    add_child(torso)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.28
    sphere.height = 0.56
    head.mesh = sphere
    head.position.y = 1.78
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("f0c39e")
    skin.roughness = 1.0
    head.material_override = skin
    add_child(head)

    var hat := MeshInstance3D.new()
    var hat_mesh := CylinderMesh.new()
    hat_mesh.top_radius = 0.18
    hat_mesh.bottom_radius = 0.32
    hat_mesh.height = 0.32
    hat.mesh = hat_mesh
    hat.position.y = 2.1
    hat.material_override = body_material
    add_child(hat)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42
    shape.height = 1.75
    collision.position.y = 0.9
    collision.shape = shape
    add_child(collision)

    if enemy_kind == "runner":
        scale = Vector3.ONE * 0.90
    elif enemy_kind == "tank":
        scale = Vector3.ONE * 1.18

func _physics_process(delta: float) -> void:
    if target == null or defeated_once:
        return
    throw_timer -= delta
    strafe_phase += delta * (0.8 + enemy_index * 0.03)

    var to_player := target.global_position - global_position
    to_player.y = 0.0
    var distance := to_player.length()

    if distance > preferred_distance:
        var approach := to_player.normalized()
        var side := Vector3(-approach.z, 0.0, approach.x) * sin(strafe_phase) * 0.45
        velocity = (approach + side).normalized() * move_speed
    elif distance < preferred_distance - 1.6 and enemy_kind == "sniper":
        velocity = -to_player.normalized() * move_speed
    else:
        var side_only := Vector3(-to_player.z, 0.0, to_player.x).normalized()
        velocity = side_only * sin(strafe_phase) * move_speed * 0.8

    move_and_slide()

    if to_player.length() > 0.01:
        look_at(global_position + to_player, Vector3.UP)

    if throw_timer <= 0.0 and distance < 16.0:
        _throw_at_player()
        throw_timer = throw_interval + float(enemy_index % 3) * 0.18

func _throw_at_player() -> void:
    var ball := RigidBody3D.new()
    ball.name = "BouleEnnemie"
    ball.set_script(SNOWBALL_SCRIPT)
    get_tree().current_scene.add_child(ball)
    ball.global_position = global_position + Vector3(0.0, 1.45, 0.0)
    ball.call("setup", "enemy", 0.105, self)

    var aim_point := target.global_position + Vector3(0.0, 1.15, 0.0)
    var direction := (aim_point - ball.global_position).normalized()
    ball.linear_velocity = direction * snowball_speed + Vector3.UP * 0.85

func take_hit(amount: int) -> void:
    if defeated_once:
        return
    hit_points -= amount
    scale *= 1.07
    var return_scale := Vector3.ONE
    if enemy_kind == "runner":
        return_scale = Vector3.ONE * 0.90
    elif enemy_kind == "tank":
        return_scale = Vector3.ONE * 1.18

    var tween := create_tween()
    tween.tween_property(self, "scale", return_scale, 0.12)
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
