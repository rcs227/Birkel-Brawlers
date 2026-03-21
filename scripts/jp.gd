extends Player
@onready var jp: AnimatedSprite2D = $Sprite2D

var is_stunned: bool = false
var stun_timer: float = 0.0
const LIGHT_ATTACK_COOLDOWN: float = 0.5

func _ready() -> void:
	jp.play("default")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			jp.play("default")

func _input(event: InputEvent) -> void:
	if is_stunned:
		return
	super._input(event)
	if event.is_action_pressed("light_attack"):
		jp.play("light_attack")
		is_stunned = true
		stun_timer = LIGHT_ATTACK_COOLDOWN
	if event.is_action_pressed("down"):
		jp.play("shadow")
	if event.is_action_released("down"):
		jp.stop()
		jp.play("default")
