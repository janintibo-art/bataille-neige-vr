extends RigidBody3D

var team := "neutral"
var age := 0.0

func setup(source_team: String, radius: float = 0.11) -> void:
    team = source_team
    contact_monitor = true
    max_contacts_reported = 4
    continuous_cd = true

    var mesh_instance := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh_instance.mesh = sphere
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("f8fdff")
    mat.roughness = 1.0
    mesh_instance.material_override = mat
    add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = radius
    collision.shape = shape
    add_child(collision)

    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    age += delta
    if age > 6.0 or global_position.y < -3.0:
        queue_free()

func _on_body_entered(body: Node) -> void:
    if team == "player" and body.has_method("take_hit"):
        body.call("take_hit", 1)
        queue_free()
