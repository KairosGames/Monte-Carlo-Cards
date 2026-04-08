class_name GameManager extends Node3D

var all_cards: Array[Card]
var name_counter: int = 0
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

func _ready() -> void:
	create_all_cards()
	build_deck(opponent_deck)
	bath = clone_cards_array(all_cards)
	build_my_deck()
	play_all_games()


func create_all_cards() -> void:
	for i in range(0, 15):
		for j in range(1, 16):
			var card: Card = Card.new(str(name_counter), i, j)
			all_cards.push_back(card)
			name_counter += 1


func build_deck(deck: Array[Card]) -> void:
	var cpy: Array[Card] = clone_cards_array(all_cards)
	for i in range(30):
		var card: Card = cpy.pick_random()
		deck.push_back(card)
		cpy.erase(card)


func build_my_deck() -> void:
	for i in range(30):
		var card: Card = bath.pick_random()
		my_deck.push_back(card)
		bath.erase(card)


func clone_cards_array(src: Array[Card]) -> Array[Card]:
	var out: Array[Card] = []
	for card in src:
		out.push_back(Card.new(card.name, card.attack, card.defense))
	return out


func play_all_games() -> void:
	var ind: int = 0
	last_deck = clone_cards_array(my_deck)
	for i in range(200):
		if ind != 0 : switch_a_card()
		for j in range(250):
			start_game()
		one_start = !one_start
		for j in range(250):
			start_game()
		one_start = !one_start
		save_deck_or_back()
		print_result()
		wins_p1 = 0
		wins_p2 = 0
		ind += 1
	print("FINITO !")


func save_deck_or_back() -> void:
	if wins_p1 >= last_win:
		last_win = wins_p1
		last_deck = clone_cards_array(my_deck)
		last_bath = clone_cards_array(bath)
	else:
		my_deck = clone_cards_array(last_deck)
		bath = clone_cards_array(last_bath)


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


func initiate_players() -> void:
	player1 = Player.new()
	player1.deck = clone_cards_array(my_deck)
	player2 = Player.new()
	player2.deck = clone_cards_array(opponent_deck)
	player1.build_hand()
	player2.build_hand()
	player1.opponent = player2
	player2.opponent = player1


func play_turn() -> void:
	player1.mana = 3 + turn
	player2.mana = 3 + turn
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
	return player1.life <= 0 or player2.life <= 0


func print_result() -> void:
	print("--------")
	print(" player 1 : ", wins_p1)
	print(" player 2 : ", wins_p2)
	print("--------")


#########################################


class Card:
	extends RefCounted
	var name: String
	var attack: int
	var defense: int
	var cost: int 
	var is_active: bool = false
	
	func _init(_name: String, _attack: int, _defense: int) -> void:
		name = _name
		attack = _attack
		defense = _defense
		cost = (attack + defense) / 2


#########################################


class Player:
	extends  RefCounted
	var deck: Array[Card]
	var hand: Array[Card]
	var field: Array[Card]
	var life: int = 20
	var mana: int = 3
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
		apply_damages()
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
			if card.cost <= mana: play_card(card)
			i -= 1
	
	func play_card(card: Card):
		mana -= card.cost
		field.push_back(card)
		hand.erase(card)
	
	func apply_damages():
		var dmg: int = 0
		for card: Card in field:
			if card.is_active: dmg += card.attack
		opponent.life -= dmg
