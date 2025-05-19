extends Node2D

var speed := 40
var lifetime := 1.0

func _process(delta):
    position.y -= speed * delta
    lifetime -= delta
    if lifetime <= 0:
        queue_free() 