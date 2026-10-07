extends CharacterBody3D

const SNOWBALL_SCRIPT := preload("res://scripts/snowball.gd")

var target: Node3D
var enemy_index := 0
var hit_points := 3
var throw_timer := 1.2
var strafe_phase := 0.0
var body_material: StandardMaterial3D

func setup(player_target: Node3D, color: Color, index: int) -> void:
    target = player_target
    enemy_index = index
    strafe_phase = float(index) * 1.8
    _build_visual(color)

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

func _physics_process(delta: float) -> void:
    if target == null:
        return
    throw_timer -= delta
    strafe_phase += delta * (0.8 + enemy_index * 0.08)

    var to_player := target.global_position - global_position
    to_player.y = 0.0
    var distance := to_player.length()
    if distance > 5.5:
        var approach := to_player.normalized()
        var side := Vector3(-approach.z, 0.0, approach.x) * sin(strafe_phase) * 0.45
        velocity = (approach + side).normalized() * 1.05
    else:
        var side_only := Vector3(-to_player.z, 0.0, to_player.x).normalized()
        velocity = side_only * sin(strafe_phase) * 0.85
    move_and_slide()

    if to_player.length() > 0.01:
        look_at(global_position + to_player, Vector3.UP)

    if throw_timer <= 0.0 and distance < 15.0:
        _throw_at_player()
        throw_timer = 2.0 + float(enemy_index) * 0.35

func _throw_at_player() -> void:
    var ball := RigidBody3D.new()
    ball.name = "BouleEnnemie"
    ball.set_script(SNOWBALL_SCRIPT)
    get_tree().current_scene.add_child(ball)
    ball.global_position = global_position + Vector3(0.0, 1.45, 0.0)
    ball.call("setup", "enemy", 0.105)
    var aim_point := target.global_position + Vector3(0.0, 1.25, 0.0)
    var direction := (aim_point - ball.global_position).normalized()
    ball.linear_velocity = direction * 8.0 + Vector3.UP * 1.1

func take_hit(amount: int) -> void:
    hit_points -= amount
    scale = Vector3.ONE * 1.07
    var tween := create_tween()
    tween.tween_property(self, "scale", Vector3.ONE, 0.12)
    if hit_points <= 0:
        _defeated()

func _defeated() -> void:
    set_physics_process(false)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "rotation_degrees:z", 90.0, 0.35)
    tween.tween_property(self, "position:y", 0.1, 0.35)
    tween.chain().tween_interval(0.5)
    tween.chain().tween_callback(queue_free)
