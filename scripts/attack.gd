class_name Attack
extends Resource

@export var animation: StringName
@export var damage: float
@export var knockback: Vector2
@export var stun_duration: float
@export var hitbox_frames: Array[HitboxSpecs] = []
@export var hurtbox_frames: Array[HitboxSpecs] = []
@export var hitbox_size: Vector2
@export var hitbox_offset: Vector2
@export var sound_effect: StringName
@export var hit_stop: float = 0.1   # seconds — 0.08 is a good default
@export var is_grab: bool = false
@export var grab_anchor: Vector2 # local position on attacker the grabee is pulled to
@export var grab_anchor_frame: float  # time in seconds when grabee arrives at anchor
