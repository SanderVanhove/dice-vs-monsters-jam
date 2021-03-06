extends Node2D
class_name Fight

signal monster_died
signal hero_died

var UIDieClass = preload("res://Things/UIDie/UIDie.tscn")
var DieClass = preload("res://Things/Die/Die.tscn")

const MAX_THROWS: int = 3
const MAX_DICE_SAVED: int = 4
const HERO_MAX_HEALTH: int = 10

export(Resource) var enemy_definition = enemy_definition as EnemyDefinition
export(bool) var is_tutorial = false

onready var _dice: Node2D = $DiceTray/Dice
onready var _dice_tray: DiceTray = $DiceTray
onready var _saved_diece: Control = $CanvasLayer/UI/HBoxContainer/CenterContainer/VBoxContainer/CenterContainer/SavedDice
onready var _throw_label: Label = $CanvasLayer/UI/HBoxContainer/CenterContainer/VBoxContainer/CenterContainer2/ThrowLabel
onready var _roll_button: Button = $CanvasLayer/UI/HBoxContainer/VBoxContainer/RollButton
onready var _end_turn_button: Button = $CanvasLayer/UI/HBoxContainer/VBoxContainer/EndTurnButton
onready var _stats_ui: StatsUI = $CanvasLayer/UI/Stats
onready var _phase_timer: Timer = $PhaseTimer
onready var _start_timer: Timer = $StartTimer
onready var _end_timer: Timer = $EndTimer
onready var _enemy: Enemy = $Enemy

onready var _heal_effect: Effect = $Effects/HealEffect
onready var _slash_effect: Effect = $Effects/SlashEffect
onready var _sword_effect: Effect = $Effects/SwordEffect
onready var _monster_block_effect: Effect = $Effects/MonsterBlockEffect
onready var _hero_block_effect: Effect = $Effects/HeroBlockEffect

onready var _intro_modal: Modal = $CanvasLayer/Modals/IntroModal
onready var _win_modal: Modal = $CanvasLayer/Modals/WinModal
onready var _lose_modal: Modal = $CanvasLayer/Modals/LoseModal
onready var _roll_tutorial_var: Modal = $CanvasLayer/Modals/RollTutorial
onready var _end_turn_tutorial: Modal = $CanvasLayer/Modals/EndTurnModal
onready var _click_dice_tutorial: Modal = $CanvasLayer/Modals/ClickOnDiceModal
onready var _unsave_dice_tutorial: Modal = $CanvasLayer/Modals/UnsaveModal
onready var _outcome_tutorial: Modal = $CanvasLayer/Modals/EndOfTurnModal
onready var _damage_tutorial: Modal = $CanvasLayer/Modals/DamageModal
onready var _monster_tutorial: Modal = $CanvasLayer/Modals/MonsterModal
onready var _end_modal: Modal = $CanvasLayer/Modals/EndModal

onready var _pickup_audio: AudioStreamPlayer = $Audio/PickupAudio
onready var _sword_audio: AudioStreamPlayer = $Audio/SwordAudio
onready var _shield_audio: AudioStreamPlayer = $Audio/ShieldAudio
onready var _hero_pain_audio: RandomStreamPlayer = $Audio/HeroPain
onready var _monster_attack: AudioStreamPlayer = $Audio/MonsterAttack
onready var _monster_pain_audio: AudioStreamPlayer = $Audio/MonsterPain
onready var _impact_audio: AudioStreamPlayer = $Audio/ImpactAudio
onready var _heal_audio: AudioStreamPlayer = $Audio/HealAudio
onready var _click_audio: AudioStreamPlayer = $Audio/ClickAudio
onready var _hero_die_audio: AudioStreamPlayer = $Audio/HeroDieAudio
onready var _win_audio: AudioStreamPlayer = $Audio/WinAudio
onready var _monster_die_audio: AudioStreamPlayer = $Audio/MonsterDieAudio

var _hero_health: int = HERO_MAX_HEALTH

var _monster_health: int = 10

var _throw_number: int = 0
var _is_end_turn: bool = false
var _add_extra_die: bool = false
var _show_end_modal: bool = false

func _ready() -> void:
	randomize()

	_stats_ui.load_stats(_hero_health, enemy_definition)
	_monster_health = enemy_definition.health

	_enemy.load_enemy(enemy_definition)

	update_throws_label()

	if _add_extra_die:
		var new_die: Die = DieClass.instance()
		_dice_tray.add_die(new_die)
		new_die.throw(false)
		new_die.connect("clicked", self, "save_die")

	connect_dice()

	_intro_modal.title = enemy_definition.name
	_intro_modal.text = enemy_definition.flavor_text
	_win_modal.text = enemy_definition.win_text
	_lose_modal.text = enemy_definition.lose_text
	yield(_intro_modal.popup(), "completed")

	_start_timer.start()


func throw_all_dice():
	_end_turn_button.disabled = true

	_throw_number += 1
	update_throws_label()
	_roll_button.disabled = _throw_number == MAX_THROWS

	for die in _dice.get_children():
		die.throw()

	yield(_dice.get_child(0), "throw_done")
	_end_turn_button.disabled = false

	if is_tutorial and is_instance_valid(_roll_tutorial_var):
		yield(_roll_tutorial_var.popup(), "completed")
		yield(_click_dice_tutorial.popup(), "completed")


func connect_dice():
	for die in _dice.get_children():
		die.connect("clicked", self, "save_die")


func save_die(die: Die):
	if _saved_diece.get_child_count() >= MAX_DICE_SAVED:
		return

	var new_ui_die: UIDie = UIDieClass.instance()
	new_ui_die.type = die.type
	_saved_diece.add_child(new_ui_die)
	new_ui_die.connect("clicked", self, "unsave_die")

	die.queue_free()

	_pickup_audio.play()

	if is_tutorial and is_instance_valid(_unsave_dice_tutorial):
		yield(_unsave_dice_tutorial.popup(), "completed")


func unsave_die(ui_die: UIDie):
	var new_die: Die = DieClass.instance()
	new_die.type = ui_die.type
	_dice_tray.add_die(new_die)
	new_die.throw(false)
	new_die.connect("clicked", self, "save_die")

	ui_die.queue_free()


func _on_RollButton_pressed() -> void:
	_click_audio.play()

	yield(throw_all_dice(), "completed")

	if is_tutorial and is_instance_valid(_end_turn_tutorial):
		yield(_end_turn_tutorial.popup(), "completed")


func update_throws_label():
	_throw_label.text = "Throws: " + str(_throw_number) + "/" + str(MAX_THROWS)


func get_outcome() -> Array:
	var outcome: Array = [0, 0, 0, 0]

	for die in _dice.get_children():
		outcome[die.type] += 1
	for ui_die in _saved_diece.get_children():
		outcome[ui_die.type] += 1

	return outcome


func _on_EndTurnButton_pressed() -> void:
	_click_audio.play()

	_is_end_turn = true
	_roll_button.disabled = true
	_end_turn_button.disabled = true

	if is_tutorial and is_instance_valid(_outcome_tutorial):
		yield(_outcome_tutorial.popup(), "completed")
		yield(_damage_tutorial.popup(), "completed")

	_throw_number = 0

	# Calculate outcome
	var outcome: Array = get_outcome()

	### ATTACK MONSTER
	var hero_attack: int = outcome[0] - enemy_definition.defence

	if outcome[0]:
		_sword_audio.play()

		if hero_attack:
			_enemy.play_damage_animation()
			_monster_health = clamp(_monster_health - hero_attack, 0, enemy_definition.health)
			_stats_ui.change_monster_health(_monster_health)

			_sword_effect.play(-hero_attack)
			_impact_audio.play()

			if _monster_health <= 0:
				_enemy.play_die_animation()
				_end_timer.start()
				_win_audio.play()
				_monster_die_audio.play()
				yield(_end_timer, "timeout")
				yield(_win_modal.popup(), "completed")
				if _show_end_modal:
					yield(_end_modal.popup(), "completed")
				emit_signal("monster_died")
				return
			else:
				_monster_pain_audio.play()
		else:
			_monster_block_effect.play(0)
			_shield_audio.play()

		_phase_timer.start()
		yield(_phase_timer, "timeout")

	### HEAL HERO
	if outcome[1] > 0:
		_heal_audio.play()
		_hero_health = clamp(_hero_health + outcome[1], 0, HERO_MAX_HEALTH)
		_stats_ui.change_hero_health(_hero_health)
		_heal_effect.play(outcome[1])
		_phase_timer.start()
		yield(_phase_timer, "timeout")

	if is_tutorial and is_instance_valid(_monster_tutorial):
		yield(_monster_tutorial.popup(), "completed")

	### ATTACK HERO
	var monster_attack: int = enemy_definition.attack - outcome[2]
	_enemy.play_attack_animation()
	_monster_attack.play()
	if monster_attack > 0:
		_hero_health = clamp(_hero_health - monster_attack, 0, HERO_MAX_HEALTH)
		_stats_ui.change_hero_health(_hero_health)
		_slash_effect.play(-monster_attack)
		_hero_pain_audio.play(.5)
		_impact_audio.play()

		if _hero_health <= 0:
			_hero_die_audio.play()
			yield(_lose_modal.popup(), "completed")
			emit_signal("hero_died")
			return
	else:
		_hero_block_effect.play(0)
		_shield_audio.play()

	_phase_timer.start()
	yield(_phase_timer, "timeout")

	# Spawn new dice
	for ui_die in _saved_diece.get_children():
		var new_die: Die = DieClass.instance()
		new_die.type = ui_die.type
		_dice_tray.add_die(new_die, false)

		ui_die.queue_free()
		_saved_diece.remove_child(ui_die)

	connect_dice()
	throw_all_dice()

	_is_end_turn = false
	_roll_button.disabled = false


func _on_StartTimer_timeout() -> void:
	throw_all_dice()
