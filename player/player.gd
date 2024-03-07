extends CharacterBody2D

var sounds = Sounds
var stats = Stats
var global_timer = GlobalTimer

signal respawn

const step_particles = preload("res://particles/step_particles.tscn")

func add_particle():
	var part = step_particles.instantiate()
	get_parent().add_child(part)
	part.modulate = Color(stats.ground_color)
	part.position = global_position

var current_velocity = 0.0
@export var acceleration = 512
@export var default_max_velocity = 65
@export var max_velocity :float = 65.0
@export var ledge_bonus = 3.5
@export var b_hop_bonus_multiplier = 20
@export var friction = 512
@export var wall_friction = .02
@export var ground_friction = .2
@export var jump_force = 150
@export var partial_jump_multiplier = .9
@export var air_friction = 90
@export var default_max_fall_velocity:float = 128.0
@export var fall_bonus = .05
@export var max_fall_velocity = 150
@export var gravity = 300
@export var wall_slide_speed = 150
@export var wall_slide_bonus = .1
@export var max_wall_slide_speed = 150
@export var slope_speed = 150
@export var slope_gravity = 300
@export var stomp_impulse = 75.0
@export var stomp_bonus = .1

@onready var sprite = $sprite
@onready var coyote_jump_timer = $coyote_jump_timer
@onready var coyote_wall_timer = $coyote_wall_timer
@onready var jump_timer = $jump_timer
@onready var collision = $collision
@onready var jump_collision = $jump_collision
@onready var animation_player = $AnimationPlayer

var state = move_state
var just_jumped = false
var double_jump = true:
	get:
		return double_jump
	set(value):
		double_jump = value
		if double_jump == true:
			sprite.self_modulate = Color.WHITE
		else:
			sprite.self_modulate = Color("#e6004d")
			#sprite.self_modulate = Color("#4682b4")

var invincible = false
var tile_map = null
var slope_tiles = [
	Vector2i(11,0),
	Vector2i(11,1),
	Vector2i(12,0),
	Vector2i(12,1),
	Vector2i(11,5),
	Vector2i(11,6),
	Vector2i(12,5),
	Vector2i(12,6),
	Vector2i(11,7),
	Vector2i(11,8),
	Vector2i(12,7),
	Vector2i(12,8),
	Vector2i(11,9),
	Vector2i(11,10),
	Vector2i(12,9),
	Vector2i(12,10),
	Vector2i(11,11),
	Vector2i(11,12),
	Vector2i(12,11),
	Vector2i(12,12),
]

func _physics_process(delta):
	current_velocity = abs(velocity.x)
	state.call(delta)
	#just_jumped = false

func create_walk_sound():
	@warning_ignore("narrowing_conversion")
	sounds.play_sfx("step", randf_range(0.6,1.2), -15)
	add_particle()

func create_dig_sound():
	@warning_ignore("narrowing_conversion")
	sounds.play_sfx("dig", 0.9, -15)
	pass

func move_state(delta):
	apply_gravity(delta)
	var input_axis = get_input_axis()
	if is_moving(input_axis):
		apply_acceleration(delta,input_axis)
	else:
		apply_friction(delta)
	jump_check()
	var was_on_floor = is_on_floor()
	var was_on_wall = is_on_wall()
	fall_bonus_check()
	update_animations(input_axis)
	var wall = wall_check()
	move_and_slide()
	var just_left_edge = was_on_floor and not is_on_floor() and velocity.y >= 0
	if just_left_edge:
		coyote_jump_timer.start()
	#print(wall)
	slope_check()
	var just_left_wall = was_on_wall and not is_on_wall()
	if just_left_wall and wall != false:
		coyote_wall_timer.start()
	reset_velocity_check()

func apply_gravity(delta):
	velocity.y = move_toward(velocity.y, max_fall_velocity, gravity * delta)
	#if not is_on_floor():
		#velocity.y = move_toward(velocity.y, max_fall_velocity, gravity * delta)

func get_input_axis():
	var input_axis = 0
	if Input.get_axis("controller_left", "controller_right") != 0:
		input_axis = Input.get_axis("controller_left", "controller_right")
	if Input.get_axis("left", "right") != 0:
		input_axis = Input.get_axis("left", "right")
	return signi(input_axis)

func is_moving(input_axis):
	return input_axis != 0

func apply_acceleration(delta, input_axis):
	velocity.x = move_toward(velocity.x, input_axis * max_velocity, acceleration * delta)

func apply_friction(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, air_friction * delta)

func jump_check():
	if is_on_floor():
		double_jump = true
	if coyote_wall_timer.time_left > 0.0:
		if Input.is_action_just_pressed("jump") || Input.is_action_just_pressed("controller_jump"):
			jump(jump_force)
	elif is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_just_pressed("jump") || Input.is_action_just_pressed("controller_jump"):
			max_velocity = max(default_max_velocity,current_velocity)
			if coyote_jump_timer.time_left > 0.0:
				max_velocity += ledge_bonus-(coyote_jump_timer.time_left*2)
			coyote_jump_timer.stop()
			jump(jump_force)
	elif not is_on_floor():
		if just_jumped and (Input.is_action_just_released("jump")|| Input.is_action_just_released("controller_jump")) and velocity.y < -jump_force / 2:
			velocity.y = -jump_force / 2
		if (Input.is_action_just_pressed("jump")||Input.is_action_just_pressed("controller_jump")) and double_jump:
			jump(jump_force * partial_jump_multiplier)
			double_jump = false

func jump(force):
	just_jumped = true
	jump_timer.start()
	velocity.y = -force
	@warning_ignore("narrowing_conversion")
	sounds.play_sfx("player_jump", randf_range(0.6,1.4), -10)

func fall_bonus_check():
	if is_on_floor():
		max_fall_velocity = default_max_fall_velocity
	else:
		if Input.is_action_pressed("down") || Input.is_action_pressed("controller_down"):
			max_fall_velocity+=fall_bonus

func update_animations(input_vector):
	var facing = input_vector
	if facing !=0:
		sprite.scale.x = facing
		jump_collision.scale.x = facing
		$hurt_box/collision2.scale.x = facing
	if not is_on_floor():
		animation_player.stop()
		jump_collision.disabled = false
		collision.disabled = true
		if velocity.y <= 0:
			sprite.frame = 18
		else:
			sprite.frame = 19
	elif input_vector != 0:
		collision.disabled = false
		jump_collision.disabled = true
		animation_player.play("run")
	else: 
		collision.disabled = false
		jump_collision.disabled = true
		animation_player.play("idle")

func wall_check():
	if not is_on_floor() and is_on_wall():
		var tile_id = ""
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() is TileMap:
				var tilemap = collision.get_collider()
				var contact_point = collision.get_position()
				var cell_pos = tilemap.local_to_map(contact_point)
				if sign(get_wall_normal().x) == 1:
					cell_pos = Vector2i(int(cell_pos.x)-1,int(cell_pos.y))
				else:
					cell_pos = Vector2i(int(cell_pos.x),int(cell_pos.y))
				tile_id = tilemap.get_cell_atlas_coords(0,cell_pos)
		if tile_id == Vector2i(12,15):
			return false
			#print("stop",tile_id)
		else:
			state = wall_slide_state
			max_velocity = max(max_velocity-wall_friction,default_max_velocity)
			double_jump = true

func reset_velocity_check():
	if is_on_floor():
		max_velocity = max(max_velocity-ground_friction,default_max_velocity)

func wall_slide_state(delta):
	animation_player.stop()
	collision.disabled = false
	var wall_normal = sign(get_wall_normal().x)
	if wall_normal !=0:
		sprite.scale.x = wall_normal
	if velocity.y <= 0:
		sprite.frame = 24
	else:
		sprite.frame = 25
	velocity.y = clampf(velocity.y, -max_fall_velocity, max_fall_velocity)
	wall_jump_check(wall_normal)
	apply_wall_slide_gravity(delta)
	move_and_slide()
	wall_detach(delta)

func wall_jump_check(wall_axis):
	if Input.is_action_just_pressed("jump")||Input.is_action_just_pressed("controller_jump"):
		#print(wall_axis)
		velocity.x = wall_axis*default_max_velocity
		state = move_state
		jump(jump_force*partial_jump_multiplier)

func apply_wall_slide_gravity(delta):
	var slide_speed = wall_slide_speed
	if Input.is_action_pressed("down") || Input.is_action_pressed("controller_down"):
		slide_speed = max_fall_velocity
		max_fall_velocity+=wall_slide_bonus
	else:
		slide_speed = wall_slide_speed
	velocity.y = move_toward(velocity.y, slide_speed, gravity * delta)

func wall_detach(delta):
	if Input.is_action_just_pressed("right") || Input.is_action_just_pressed("controller_right"):
		velocity.x = acceleration * delta
		state = move_state
	if Input.is_action_just_pressed("left") || Input.is_action_just_pressed("controller_left"):
		velocity.x = -acceleration * delta
		state = move_state
	if not is_on_wall() and not is_on_ceiling() or is_on_floor():
		state = move_state

func slope_check():
	if get_floor_angle() < .9 and get_floor_angle() > .7:
		#print("on slope",get_floor_angle())
		state = slope_state
		velocity = Vector2.ZERO
		#max_velocity = max(max_velocity-wall_friction,default_max_velocity)
		double_jump = false

func slope_state(delta):
	#velocity.y = clampf(velocity.y, -max_fall_velocity, max_fall_velocity)
	#velocity.y = move_toward(velocity.y, slope_speed, slope_gravity * delta)
	velocity.y = slope_speed
	move_and_slide()
	slope_exit()

func slope_exit():
	if get_floor_angle() < .9 and get_floor_angle() > .7:
		pass
		#print("nooooo")
	else:
		if get_floor_angle() == 0:
			state = move_state

func _on_hurt_box_hit(damage):
	if not invincible:
		invincible = true
		check_death()
	else:
		pass

func set_invincible(_bool):
	invincible = _bool

func check_death():
	if stats.game_mode == "no_hit":
		call_deferred("change_scene")
	else:
		respawn.emit()

func change_scene(new_scene = null):
	if new_scene:
		get_tree().change_scene_to_file(new_scene)
	else:
		get_tree().reload_current_scene()

@warning_ignore("unused_parameter")
func _on_hit_box_area_entered(area):
	if velocity.y>0:
		double_jump = true
		var bounce = area.bounce * (((area.max_health-area.health)*.25)+1)
		velocity = calculate_stomp_velocity(velocity, bounce)
		max_velocity += stomp_bonus
		area.hit(1)

func calculate_stomp_velocity(linear_velocity: Vector2, impulse):
	var out: = linear_velocity
	out.y = -impulse
	return out


func _on_jump_timer_timeout():
	just_jumped = false
