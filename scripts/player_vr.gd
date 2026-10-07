extends XROrigin3D

const SNOWBALL_SCRIPT := preload("res://scripts/snowball.gd")

@export var move_speed := 3.2
@export var snap_turn_degrees := 30.0
@export var max_health := 5

var xr_camera: XRCamera3D
var left_hand: XRController3D
var right_hand: XRController3D

var left_loaded := false
var right_loaded := false
var left_throw_armed := false
var right_throw_armed := false
var turn_ready := true

var left_ball_visual: MeshInstance3D
var right_ball_visual: MeshInstance3D
var giant_ball_visual: MeshInstance3D

var health := 5
var invulnerability := 0.0
var spawn_position := Vector3.ZERO
var health_pips: Array[MeshInstance3D] = []

var last_left_position := Vector3.ZERO
var last_right_position := Vector3.ZERO
var left_hand_velocity := Vector3.ZERO
var right_hand_velocity := Vector3.ZERO

var giant_building := false
var giant_ready := false
var giant_armed := false
var giant_charge := 0.0

const GIANT_BUILD_TIME := 0.75
const GIANT_HAND_DISTANCE := 0.36

func setup(cam: XRCamera3D, left: XRController3D, right: XRController3D) -> void:
    xr_camera = cam
    left_hand = left
    right_hand = right
    health = max_health
    spawn_position = global_position

    left_ball_visual = _make_loaded_ball(left_hand)
    right_ball_visual = _make_loaded_ball(right_hand)
    giant_ball_visual = _make_giant_ball_visual()

    last_left_position = left_hand.global_position
    last_right_position = right_hand.global_position

    _make_player_hitbox()
    _make_health_indicator()

func _physics_process(delta: float) -> void:
    if xr_camera == null or left_hand == null or right_hand == null:
        return

    invulnerability = maxf(0.0, invulnerability - delta)
    _sample_hand_velocities(delta)
    _move_player(delta)
    _snap_turn()

    if _update_giant_ball(delta):
        return

    _update_hand(left_hand, true)
    _update_hand(right_hand, false)

func _sample_hand_velocities(delta: float) -> void:
    if delta <= 0.0001:
        return

    var raw_left := (left_hand.global_position - last_left_position) / delta
    var raw_right := (right_hand.global_position - last_right_position) / delta

    # Lissage leger : conserve le geste du joueur sans rendre le lancer nerveux.
    left_hand_velocity = left_hand_velocity.lerp(raw_left, 0.55)
    right_hand_velocity = right_hand_velocity.lerp(raw_right, 0.55)

    last_left_position = left_hand.global_position
    last_right_position = right_hand.global_position

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
    var armed := left_throw_armed if is_left else right_throw_armed

    # Ramassage de neige : grip + main proche du sol.
    if not loaded and grip > 0.65 and hand.global_position.y < 1.0:
        loaded = true
        armed = false
        _set_ball_visible(is_left, true)
        _pulse(hand, 0.55, 0.05)

    # On serre la gachette pour tenir la boule puis on la relache pour lancer.
    if loaded and trigger > 0.62:
        armed = true

    if loaded and armed and trigger < 0.25:
        _throw_snowball(hand, is_left)
        loaded = false
        armed = false
        _set_ball_visible(is_left, false)
        _pulse(hand, 0.68, 0.06)

    if is_left:
        left_loaded = loaded
        left_throw_armed = armed
    else:
        right_loaded = loaded
        right_throw_armed = armed

func _throw_snowball(hand: XRController3D, is_left: bool) -> void:
    var ball := RigidBody3D.new()
    ball.name = "BouleDeNeige"
    ball.set_script(SNOWBALL_SCRIPT)
    get_tree().current_scene.add_child(ball)
    ball.global_transform = hand.global_transform.translated_local(Vector3(0.0, 0.0, -0.16))
    ball.call("setup", "player", 0.11, null, 1, false)

    var hand_velocity := left_hand_velocity if is_left else right_hand_velocity
    var forward := -hand.global_transform.basis.z.normalized()
    ball.linear_velocity = _calculate_throw_velocity(hand_velocity, forward, 5.5, 16.0)

func _calculate_throw_velocity(hand_velocity: Vector3, forward: Vector3, min_speed: float, max_speed: float) -> Vector3:
    # Le geste reel domine. Un petit apport vers l'avant rend les petits gestes jouables.
    var velocity := hand_velocity * 1.28 + forward * 2.1
    var speed := velocity.length()

    # Si le joueur relache presque sans mouvement, la boule part quand meme doucement.
    if speed < min_speed:
        var gesture_direction := velocity.normalized() if speed > 0.15 else forward
        velocity = gesture_direction * min_speed
    elif speed > max_speed:
        velocity = velocity.normalized() * max_speed

    return velocity

func _update_giant_ball(delta: float) -> bool:
    if giant_ready:
        _place_giant_visual()
        var left_trigger := left_hand.get_float(&"trigger")
        var right_trigger := right_hand.get_float(&"trigger")

        if left_trigger > 0.62 and right_trigger > 0.62:
            giant_armed = true

        if giant_armed and left_trigger < 0.25 and right_trigger < 0.25:
            _throw_giant_ball()
        return true

    var left_grip := left_hand.get_float(&"grip")
    var right_grip := right_hand.get_float(&"grip")
    var hands_close := left_hand.global_position.distance_to(right_hand.global_position) <= GIANT_HAND_DISTANCE
    var can_build := left_loaded and right_loaded and left_grip > 0.62 and right_grip > 0.62 and hands_close

    if can_build:
        if not giant_building:
            giant_building = true
            giant_charge = 0.0
            _set_ball_visible(true, false)
            _set_ball_visible(false, false)
            giant_ball_visual.visible = true
            _pulse(left_hand, 0.35, 0.04)
            _pulse(right_hand, 0.35, 0.04)

        giant_charge = minf(GIANT_BUILD_TIME, giant_charge + delta)
        _place_giant_visual()
        var progress := giant_charge / GIANT_BUILD_TIME
        var scale_value := lerpf(1.15, 2.7, progress)
        giant_ball_visual.scale = Vector3.ONE * scale_value

        if giant_charge >= GIANT_BUILD_TIME:
            giant_building = false
            giant_ready = true
            giant_armed = false
            left_loaded = false
            right_loaded = false
            left_throw_armed = false
            right_throw_armed = false
            giant_ball_visual.scale = Vector3.ONE * 2.7
            _pulse(left_hand, 0.85, 0.10)
            _pulse(right_hand, 0.85, 0.10)
        return true

    if giant_building:
        _cancel_giant_build()

    return false

func _place_giant_visual() -> void:
    if giant_ball_visual == null:
        return
    giant_ball_visual.global_position = (left_hand.global_position + right_hand.global_position) * 0.5

func _cancel_giant_build() -> void:
    giant_building = false
    giant_charge = 0.0
    giant_ball_visual.visible = false
    giant_ball_visual.scale = Vector3.ONE
    _set_ball_visible(true, left_loaded)
    _set_ball_visible(false, right_loaded)

func _throw_giant_ball() -> void:
    var ball := RigidBody3D.new()
    ball.name = "GrosseBouleDeNeige"
    ball.set_script(SNOWBALL_SCRIPT)
    get_tree().current_scene.add_child(ball)

    var midpoint := (left_hand.global_position + right_hand.global_position) * 0.5
    ball.global_position = midpoint
    ball.call("setup", "player", 0.30, null, 3, true)

    var combined_velocity := (left_hand_velocity + right_hand_velocity) * 0.5
    var combined_forward := (
        -left_hand.global_transform.basis.z.normalized()
        -right_hand.global_transform.basis.z.normalized()
    ).normalized()

    ball.linear_velocity = _calculate_throw_velocity(combined_velocity, combined_forward, 4.8, 12.5)

    giant_ready = false
    giant_armed = false
    giant_charge = 0.0
    giant_ball_visual.visible = false
    giant_ball_visual.scale = Vector3.ONE
    _pulse(left_hand, 1.0, 0.12)
    _pulse(right_hand, 1.0, 0.12)

func take_hit(amount: int = 1, _impulse: Vector3 = Vector3.ZERO) -> void:
    if invulnerability > 0.0:
        return

    invulnerability = 0.8
    health = maxi(0, health - amount)
    _refresh_health_indicator()

    if left_hand:
        _pulse(left_hand, 0.9, 0.12)
    if right_hand:
        _pulse(right_hand, 0.9, 0.12)

    print("Joueur touche : %d/%d" % [health, max_health])

    if health <= 0:
        _respawn()

func _respawn() -> void:
    print("Joueur KO : retour au point de depart")
    global_position = spawn_position
    health = max_health
    invulnerability = 1.8

    left_loaded = false
    right_loaded = false
    left_throw_armed = false
    right_throw_armed = false
    giant_building = false
    giant_ready = false
    giant_armed = false
    giant_charge = 0.0

    _set_ball_visible(true, false)
    _set_ball_visible(false, false)
    if giant_ball_visual:
        giant_ball_visual.visible = false

    _refresh_health_indicator()

func _make_player_hitbox() -> void:
    var hit_area := Area3D.new()
    hit_area.name = "PlayerHitArea"
    hit_area.set_meta("team", "player")
    xr_camera.add_child(hit_area)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.30
    shape.height = 1.25
    collision.shape = shape
    collision.position = Vector3(0.0, -0.62, 0.0)
    hit_area.add_child(collision)

func _make_health_indicator() -> void:
    for i in max_health:
        var pip := MeshInstance3D.new()
        pip.name = "Vie_%02d" % (i + 1)

        var sphere := SphereMesh.new()
        sphere.radius = 0.018
        sphere.height = 0.036
        pip.mesh = sphere

        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color("eaf9ff")
        mat.emission_enabled = true
        mat.emission = Color("bfeaff")
        mat.emission_energy_multiplier = 0.5
        pip.material_override = mat

        pip.position = Vector3(-0.075 + i * 0.037, 0.075, 0.03)
        left_hand.add_child(pip)
        health_pips.append(pip)

    _refresh_health_indicator()

func _refresh_health_indicator() -> void:
    for i in health_pips.size():
        health_pips[i].visible = i < health

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

func _make_giant_ball_visual() -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = "GrosseBoulePreparation"

    var sphere := SphereMesh.new()
    sphere.radius = 0.12
    sphere.height = 0.24
    visual.mesh = sphere

    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("f4fbff")
    mat.roughness = 1.0
    visual.material_override = mat

    visual.visible = false
    add_child(visual)
    return visual

func _set_ball_visible(is_left: bool, value: bool) -> void:
    var visual := left_ball_visual if is_left else right_ball_visual
    if visual:
        visual.visible = value

func _pulse(hand: XRController3D, amplitude: float, duration: float) -> void:
    hand.trigger_haptic_pulse(&"haptic", 0.0, amplitude, duration, 0.0)
