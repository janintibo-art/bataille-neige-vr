extends RefCounted

static func wave_count() -> int:
    return 5

static func get_wave(wave_number: int) -> Array:
    match wave_number:
        1:
            return [
                _enemy("Berni", Vector3(-6, 0, -4), "standard", Color("ef5d60"), 0),
                _enemy("Kevin Turbo", Vector3(6, 0, -5), "runner", Color("51a7e8"), 1),
                _enemy("Chantal Mitraillette", Vector3(-1, 0, -12), "rapid", Color("f0b949"), 2),
                _enemy("Marco Longue Vue", Vector3(8, 0, -13), "sniper", Color("786de3"), 3)
            ]
        2:
            return [
                _enemy("Lea l'Esquive", Vector3(-8, 0, -31), "zigzag", Color("62c58a"), 4),
                _enemy("Jojo la Doudoune", Vector3(8, 0, -33), "tank", Color("d66ad2"), 5),
                _enemy("Dede les Poches", Vector3(-5, 0, -40), "rapid", Color("de7f4f"), 6),
                _enemy("Nono Ninja", Vector3(6, 0, -42), "runner", Color("427d62"), 7)
            ]
        3:
            return [
                _enemy("Ginette du Balcon", Vector3(-8, 0, -61), "sniper", Color("748fe5"), 1),
                _enemy("Titou la Pelle", Vector3(8, 0, -62), "standard", Color("e86658"), 5),
                _enemy("Lucette la Moufle", Vector3(-5, 0, -70), "tank", Color("ba6bd1"), 0),
                _enemy("Pierrot de Travers", Vector3(6, 0, -71), "zigzag", Color("54bfc3"), 3)
            ]
        4:
            return [
                _enemy("Momo le Tricheur", Vector3(-8, 0, -92), "rapid", Color("e95b83"), 7),
                _enemy("Gerard le Bucheron", Vector3(8, 0, -93), "tank", Color("9a6b48"), 4),
                _enemy("Fifi Flocon", Vector3(-6, 0, -102), "runner", Color("57bce6"), 0),
                _enemy("Josiane Camouflage", Vector3(7, 0, -103), "sniper", Color("6a946d"), 2)
            ]
        5:
            return [
                _enemy("Maurice Bonhomme", Vector3(-8, 0, -123), "standard", Color("5faed6"), 6),
                _enemy("Gaston Glacon", Vector3(8, 0, -123), "rapid", Color("72cbd7"), 2),
                _enemy("Robert Couvercle", Vector3(-6, 0, -133), "tank", Color("7f8795"), 5),
                _enemy("Raoul le Chef", Vector3(2, 0, -138), "boss", Color("d64e4e"), 3)
            ]
        _:
            return []

static func get_checkpoint(wave_number: int) -> Vector3:
    match wave_number:
        1:
            return Vector3(0, 0, 8)
        2:
            return Vector3(0, 0, -23)
        3:
            return Vector3(0, 0, -53)
        4:
            return Vector3(0, 0, -84)
        5:
            return Vector3(0, 0, -115)
        _:
            return Vector3.ZERO

static func get_zone_name(wave_number: int) -> String:
    match wave_number:
        1:
            return "Village des Flocons"
        2:
            return "Foret des Sapins Tordus"
        3:
            return "Riviere Gelee"
        4:
            return "Vieille Scierie"
        5:
            return "Fort de Raoul"
        _:
            return "Neige"

static func _enemy(display_name: String, pos: Vector3, kind: String, color: Color, look: int) -> Dictionary:
    return {
        "display_name": display_name,
        "position": pos,
        "kind": kind,
        "color": color,
        "look": look,
        "activation_distance": 18.0
    }
