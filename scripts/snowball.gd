extends RigidBody3D

var team := "neutral"
var age := 0.0
var damage := 1
var giant := false
var impact_done := false

func setup(
    source_team: String,
    radius: float = 0.11,
    owner_body: PhysicsBody3D = null,
    damage_amount: int = 1,
    is_giant: bool = false
) -> void:
    team = source_team
    damage = damage_amount
    giant = is_giant

    contact_monitor = true
    max_contacts_reported = 8
    continuous_cd = true
    mass = 1.8 if giant else 0.35

    if owner_body != null:
        add_collision_exception_with(owner_body)

    var mesh_instance := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh_instance.mesh = sphere

    var mat := StandardMaterial3D.new()
    if team == "player":
        mat.albedo_color = Color("f8fdff")
    else:
        mat.albedo_color = Color("d8efff")
    mat.roughness = 1.0
    mesh_instance.material_override = mat
    add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = radius
    collision.shape = shape
    add_child(collision)

    body_entered.connect(_on_body_entered)

    var detector := Area3D.new()
    detector.name = "AreaDetector"
    detector.monitoring = true
    detector.monitorable = false
    detector.collision_layer = 0
    detector.collision_mask = 1
    add_child(detector)

    var detector_collision := CollisionShape3D.new()
    var detector_shape := SphereShape3D.new()
    detector_shape.radius = radius * 1.08
    detector_collision.shape = detector_shape
    detector.add_child(detector_collision)

    detector.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
    age += delta
    if age > 6.0 or global_position.y < -3.0:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if impact_done or not is_instance_valid(body):
        return

    var body_team := String(body.get_meta("team", ""))
    if body_team == team:
        return

    var target := _find_damage_target(body)
    if target != null:
        _apply_damage(target)

    _impact(target)

func _on_area_entered(area: Area3D) -> void:
    if impact_done or not is_instance_valid(area):
        return

    var area_team := String(area.get_meta("team", ""))
    if area_team == team:
        return

    var target := _find_damage_target(area)
    if target != null:
        _apply_damage(target)
        _impact(target)

func _apply_damage(target: Node) -> void:
    if target == null or not target.has_method("take_hit"):
        return

    var impulse := Vector3.ZERO
    if linear_velocity.length() > 0.1:
        impulse = linear_velocity.normalized() * (5.5 if giant else 1.2)

    target.call("take_hit", damage, impulse)

func _impact(primary_target: Node) -> void:
    if impact_done:
        return
    impact_done = true

    if giant and team == "player":
        _splash_damage(primary_target)

    _spawn_snow_puff(1.55 if giant else 0.75)
    queue_free()

func _splash_damage(primary_target: Node) -> void:
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if enemy == primary_target or not is_instance_valid(enemy):
            continue
        if not enemy.has_method("take_hit"):
            continue

        var distance := global_position.distance_to(enemy.global_position)
        if distance <= 1.85:
            var push := enemy.global_position - global_position
            push.y = 0.18
            if push.length() < 0.01:
                push = Vector3.FORWARD
            enemy.call("take_hit", 2, push.normalized() * 4.5)

func _spawn_snow_puff(size_multiplier: float) -> void:
    var root := Node3D.new()
    root.name = "EclaboussureNeige"
    get_tree().current_scene.add_child(root)
    root.global_position = global_position

    var directions := [
        Vector3(1.0, 0.4, 0.0),
        Vector3(-1.0, 0.5, 0.2),
        Vector3(0.2, 0.7, 1.0),
        Vector3(-0.2, 0.6, -1.0),
        Vector3(0.7, 0.9, 0.7),
        Vector3(-0.7, 0.8, -0.6)
    ]

    var tween := root.create_tween()
    tween.set_parallel(true)

    for i in directions.size():
        var flake := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.035 * size_multiplier
        mesh.height = 0.07 * size_multiplier
        flake.mesh = mesh

        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color("edf9ff")
        mat.roughness = 1.0
        flake.material_override = mat

        root.add_child(flake)
        var destination := directions[i].normalized() * (0.35 + 0.08 * i) * size_multiplier
        tween.tween_property(flake, "position", destination, 0.28)
        tween.tween_property(flake, "scale", Vector3.ZERO, 0.30)

    tween.chain().tween_callback(root.queue_free)

func _find_damage_target(node: Node) -> Node:
    var current: Node = node
    while current != null:
        if current.has_method("take_hit"):
            return current
        current = current.get_parent()
    return null
