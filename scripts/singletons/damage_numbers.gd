extends Node

const DAMAGE_NUMBER_SCENE = preload("res://scenes/DamageNumber.tscn")

func spawn(amount: int, world_pos: Vector3, color := Color.WHITE) -> void:
    var dn = DAMAGE_NUMBER_SCENE.instantiate() as Label3D
    if dn == null:
        push_error("damage number scene root aint a label3d cowboy")
        return
    get_tree().root.add_child(dn)
    dn.global_position = world_pos
    dn.text = str(amount)
    dn.modulate = color

    await get_tree().create_timer(0.5).timeout
    dn.queue_free()
