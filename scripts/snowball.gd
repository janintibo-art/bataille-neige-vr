extends RigidBody3D

var team := "neutral"
var age := 0.0

func setup(source_team: String, radius: float = 0.11, owner_body: PhysicsBody3D = null) -> void:
    team = source_team
    contact_monitor = true
    max_contacts_reported = 6
    continuous_cd = true

    if owner_body != null:
        add_collision_exception_with(owner_body)

    var mesh_instance := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh_instance.mesh = sphere

    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("f8fdff") if team == "player" else Color("d8efff")
    mat.roughness = 1.0
    mesh_instance.material_override = mat
    add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = radius
    collision.shape = shape
    add_child(collision)

    # Le RigidBody detecte les corps physiques.
    body_entered.connect(_on_body_entered)

    # Un Area3D enfant detecte les zones, notamment la hitbox VR du joueur.
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
    if not is_instance_valid(body):
        return

    var body_team := String(body.get_meta("team", ""))
    if body_team == team:
        return

    if team == "player":
        var target := _find_damage_target(body)
        if target != null:
            target.call("take_hit", 1)
            queue_free()
            return

    if team == "enemy":
        var target := _find_damage_target(body)
        if target != null:
            target.call("take_hit", 1)
            queue_free()
            return

    # La boule disparait aussi lorsqu'elle frappe le decor.
    queue_free()

func _on_area_entered(area: Area3D) -> void:
    if not is_instance_valid(area):
        return

    var area_team := String(area.get_meta("team", ""))
    if area_team == team:
        return

    var target := _find_damage_target(area)
    if target != null:
        target.call("take_hit", 1)
        queue_free()

func _find_damage_target(node: Node) -> Node:
    var current: Node = node
    while current != null:
        if current.has_method("take_hit"):
            return current
        current = current.get_parent()
    return null
