class_name GameManager extends Node3D

var all_cards: Array[Card]
var player1: Player
var player2: Player
var opponent_deck: Array[Card]

var turn: int = 0
var one_start: bool = false
var has_winner_been_announced = false

var bath: Array[Card]
var my_deck: Array[Card]
var last_deck: Array[Card]
var last_bath: Array[Card]
var last_win: int = 0
var wins_p1: int = 0
var wins_p2: int = 0

var counter: int = 0
var curr_run_data: RunData
var run_data: Array[RunData]

func _ready() -> void:
	create_all_cards()
	build_opponent_deck()
	bath = all_cards.duplicate()
	build_my_deck()


func _process(_delta: float) -> void:
	if counter == 0: last_deck = my_deck.duplicate()
	if counter != 0 : switch_a_card()
	
	curr_run_data = RunData.new()
	
	for j in range(250):
		start_game()
	one_start = !one_start
	for j in range(250):
		start_game()
	one_start = !one_start
	
	save_deck_or_back()
	save_run_data()
	print_result()
	wins_p1 = 0
	wins_p2 = 0
	counter += 1
	
	if counter >= 10000:
		export_txt_optimized_deck()
		print("FINITO")
		get_tree().quit()


func create_all_cards() -> void:
	var simple_cards: Array[Card]
	
	for i in range(0, 15):
		for j in range(1, 16):
			var card: Card = Card.new(i, j)
			if card.cost <= 7 : all_cards.push_back(card)
			if card.cost <= 6 : simple_cards.push_back(card)
			
	for card: Card in simple_cards:
		if card.cost + 1 <= 7:
			var card1: Card = Card.new(card.attack, card.defense, false, true, false)
			all_cards.push_back(card1)
		if card.cost + 2 <= 7:
			var card1: Card = Card.new(card.attack, card.defense, true, false, false)
			var card2: Card = Card.new(card.attack, card.defense, false, false, true)
			all_cards.push_back(card1)
			all_cards.push_back(card2)
		if card.cost + 3 <= 7:
			var card1: Card = Card.new(card.attack, card.defense, true, true, false)
			var card2: Card = Card.new(card.attack, card.defense, false, true, true)
			all_cards.push_back(card1)
			all_cards.push_back(card2)
		if card.cost + 4 <= 7:
			var card1: Card = Card.new(card.attack, card.defense, true, false, true)
			all_cards.push_back(card1)
		if card.cost + 5 <= 7:
			var card1: Card = Card.new(card.attack, card.defense, true, true, true)
			all_cards.push_back(card1)
 

func build_opponent_deck() -> void:
	var cpy: Array[Card] = clone_cards_array(all_cards)
	for i in range(40):
		var card: Card = cpy.pick_random()
		opponent_deck.push_back(card)
		cpy.erase(card)


func build_my_deck() -> void:
	for i in range(40):
		var card: Card = bath.pick_random()
		my_deck.push_back(card)
		bath.erase(card)


func clone_cards_array(src: Array[Card]) -> Array[Card]:
	var out: Array[Card] = []
	for card in src:
		out.push_back(Card.new(card.attack, card.defense, card.is_guard, card.is_fly, card.is_charge))
	return out


func save_deck_or_back() -> void:
	if wins_p1 >= last_win:
		last_win = wins_p1
		last_deck = my_deck.duplicate()
		last_bath = bath.duplicate()
	else:
		my_deck = last_deck.duplicate()
		bath = last_bath.duplicate()


func switch_a_card() -> void:
	var card_to_trhow: Card = my_deck.pick_random()
	var card_to_add: Card = bath.pick_random()
	my_deck.push_back(card_to_add)
	bath.erase(card_to_add)
	my_deck.erase(card_to_trhow)
	bath.push_back(card_to_trhow)


func start_game() -> void:
	has_winner_been_announced = false
	turn = 0
	initiate_players()
	while(not is_game_finished()):
		play_turn()
	save_game_data()
	reset_cards()

func reset_cards() -> void:
	for card: Card in all_cards:
		card.is_active = false
		card.current_def = card.defense
	for card: Card in opponent_deck:
		card.is_active = false
		card.current_def = card.defense


func initiate_players() -> void:
	player1 = Player.new()
	player1.deck = my_deck.duplicate()
	player2 = Player.new()
	player2.deck = opponent_deck.duplicate()
	player1.build_hand()
	player2.build_hand()
	player1.opponent = player2
	player2.opponent = player1


func play_turn() -> void:
	player1.mana = 4 + turn
	player2.mana = 4 + turn
	var first: Player = player1 if one_start else player2
	var second: Player = player2 if one_start else player1
	first.play_turn()
	if is_game_finished(): return
	second.play_turn()
	turn += 1


func is_game_finished() -> bool:
	if not has_winner_been_announced:
		if player1.life <= 0:
			has_winner_been_announced = true
			wins_p2 += 1
		if player2.life <= 0:
			wins_p1 += 1
			has_winner_been_announced = true
			if one_start: curr_run_data.won_P1_first += 1
			else: curr_run_data.won_P1_second += 1
	return player1.life <= 0 or player2.life <= 0


func print_result() -> void:
	print(" p1 : ", wins_p1, ", p2 : ", wins_p2, ", tour : ", counter)


func export_txt_optimized_deck() -> void:
	var result: String = ""
	for card: Card in my_deck:
		result += card.name + "\n"
	var file := FileAccess.open("res://ydris_deck.txt", FileAccess.WRITE)
	file.store_string(result)


func save_game_data():
	if one_start: curr_run_data.turns_per_game_first.push_back(turn)
	else: curr_run_data.turns_per_game_second.push_back(turn)


func save_run_data():
	pass


#########################################


class Card:
	extends RefCounted
	var name: String
	var attack: int
	var defense: int
	var current_def: int
	var cost: int 
	var is_active: bool = false
	var is_guard: bool = false
	var is_fly: bool = false
	var is_charge: bool = false
	
	
	func _init(_attack: int,
			_defense: int,
			_is_guard: bool = false,
			_is_fly: bool = false,
			_is_charge: bool = false) -> void:
		attack = _attack
		defense = _defense
		current_def = _defense
		is_guard = _is_guard
		is_fly = _is_fly
		is_charge = _is_charge
		cost = (attack + defense) / 2
		cost += (2 if _is_guard else 0) + (1 if _is_fly else 0) + (2 if _is_charge else 0)
		name = str(cost) + "_" + str(attack) + "_" + str(defense) + "_"
		name += str(is_guard as int) + "_" + str(is_fly as int) + "_" + str(is_charge as int)


#########################################


class Player:
	extends  RefCounted
	var deck: Array[Card]
	var hand: Array[Card]
	var field: Array[Card]
	var life: int = 30
	var mana: int = 4
	var opponent: Player
	
	func build_hand() -> void:
		for i in range(7):
			draw()
	
	func draw() -> void:
		if deck.size() != 0:
			var card: Card = deck.pick_random()
			hand.push_back(card)
			deck.erase(card)
		else:
			life -= 1
	
	func play_turn() -> void:
		activate_field_cards()
		put_cards_on_field()
		play_player_turn()
		if opponent.life <= 0: return
		draw()
	
	func activate_field_cards() -> void:
		for card: Card in field:
			card.is_active = true
	
	func put_cards_on_field() -> void:
		if hand.size() == 0 :return
		hand.sort_custom(func(a: Card, b: Card): return a.cost < b.cost)
		var i: int = hand.size() - 1
		while(hand.size() != 0 and hand[0].cost <= mana):
			var card: Card = hand[i]
			if card.cost <= mana: put_card(card)
			i -= 1
	
	func put_card(card: Card):
		mana -= card.cost
		field.push_back(card)
		hand.erase(card)
		if card.is_charge: card.is_active = true
	
	func play_player_turn():
		for card: Card in field:
			if card.is_active: play_card(card)
			if opponent.life <= 0 : break
		reset_cards_life()
	
	func play_card(card: Card) -> void:
		var is_blocked: bool = false
		for e_card: Card in opponent.field:
			if card.is_fly and not e_card.is_fly : continue
			if e_card.is_guard:
				is_blocked = true
				card.current_def -= e_card.attack
				e_card.current_def -= card.attack
				if e_card.current_def <= 0: opponent.field.erase(e_card)
				if card.current_def <= 0: field.erase(card)
				break
		if not is_blocked: opponent.life -= card.attack
	
	func reset_cards_life():
		for card: Card in field : card.current_def = card.defense
		for card: Card in opponent.field : card.current_def = card.defense


#########################################


class RunData:
	extends RefCounted
	var turns_per_game_first: Array[int]
	var turns_per_game_second: Array[int]
	var won_P1_first: int
	var won_P1_second: int
	var saved_deck: Array[Card]
	var attack_average: float
	var defense_average: float
	var cost_average: float
	var n_gard: int
	var n_fly: int
	var n_charge: int
