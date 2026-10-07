extends XROrigin3D

const SNOWBALL_SCRIPT := preload("res://scripts/snowball.gd")

@export var move_speed := 3.2
@export var snap_turn_degrees := 30.0

var xr_camera: XRCamera3D
var left_hand: XRController3D
var right_hand: XRController3D
var left_loaded := false
var right_loaded := false
var left_trigger_was_down := false
var right_trigger_was_down := false
var turn_ready := true
var left_ball_visual: MeshInstance3D
var right_ball_visual: MeshInstance3D

func setup(cam: XRCamera3D, left: XRController3D, right: XRController3D) -> void:
    xr_camera = cam
    left_hand = left
    right_hand = right
    left_ball_visual = _make_loaded_ball(left_hand)
    right_ball_visual = _make_loaded_ball(right_hand)

func _physics_process(delta: float) -> void:
    if xr_camera == null or left_hand == null or right_hand == null:
        return
    _move_player(delta)
    _snap_turn()
    _update_hand(left_hand, true)
    _update_hand(right_hand, false)

func _move_player(delta: float) -> void:
    var stick := left_hand.get_vector2(&"primary")
    if stick.length() < 0.15:
        return
    var forward := -xr_camera.global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    var right := xr_camera.global_transform.basis.x
    right.y = 0.0
    right = right.normalized()
    var direction := (right * stick.x + forward * -stick.y).normalized()
    global_position += direction * move_speed * stick.length() * delta

func _snap_turn() -> void:
    var stick := right_hand.get_vector2(&"primary")
    if abs(stick.x) < 0.45:
        turn_ready = true
        return
    if not turn_ready:
        return
    turn_ready = false
    var angle := deg_to_rad(-snap_turn_degrees if stick.x > 0.0 else snap_turn_degrees)
    var head_before := xr_camera.global_position
    rotate_y(angle)
    var head_after := xr_camera.global_position
    global_position += head_before - head_after

func _update_hand(hand: XRController3D, is_left: bool) -> void:
    var grip := hand.get_float(&"grip")
    var trigger := hand.get_float(&"trigger")
    var loaded := left_loaded if is_left else right_loaded

    # Ramassage : serrer la poignée quand la main est proche du sol.
    if not loaded and grip > 0.65 and hand.global_position.y < 1.0:
        loaded = true
        _set_ball_visible(is_left, true)
        _pulse(hand)

    var was_down := left_trigger_was_down if is_left else right_trigger_was_down
    var trigger_down := trigger > 0.68
    if loaded and trigger_down and not was_down:
        _throw_snowball(hand)
        loaded = false
        _set_ball_visible(is_left, false)
        _pulse(hand)

    if is_left:
        left_loaded = loaded
        left_trigger_was_down = trigger_down
    else:
        right_loaded = loaded
        right_trigger_was_down = trigger_down

func _throw_snowball(hand: XRController3D) -> void:
    var ball := RigidBody3D.new()
    ball.name = "BouleDeNeige"
    ball.set_script(SNOWBALL_SCRIPT)
    get_tree().current_scene.add_child(ball)
    ball.global_transform = hand.global_transform.translated_local(Vector3(0.0, 0.0, -0.16))
    ball.call("setup", "player", 0.11)
    var forward := -hand.global_transform.basis.z.normalized()
    ball.linear_velocity = forward * 11.5

func _make_loaded_ball(hand: XRController3D) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.11
    sphere.height = 0.22
    visual.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("f7fdff")
    mat.roughness = 1.0
    visual.material_override = mat
    visual.position = Vector3(0.0, 0.0, -0.13)
    visual.visible = false
    hand.add_child(visual)
    return visual

func _set_ball_visible(is_left: bool, value: bool) -> void:
    var visual := left_ball_visual if is_left else right_ball_visual
    if visual:
        visual.visible = value

func _pulse(hand: XRController3D) -> void:
    hand.trigger_haptic_pulse(&"haptic", 0.0, 0.6, 0.06, 0.0)
