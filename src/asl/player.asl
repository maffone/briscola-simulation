// Agent player in project briscolaSimulation.

/* This agent can play a complete game of Briscola in the 4 players version.
 * He has a strategy to select the card to play at every turn. He can ask questions to his companion, 
 * look at the cards played by other players, and choose the best card to play accordingly. 
 */

/* Initial beliefs and rules */

/* Every question asked by this agent has to contain a progressive sequence number that identifies it. */
sequence_number(0).

/* Every card (with value and seed) matches a certain range of value and seed. */
card_match(CARD, RANGE, SEED) :- card_range_match(CARD, RANGE) & card_seed_match(CARD, SEED).

/* A card has a corresponding range according to its value. Every card matches with the special range "any". */
card_range_match(card(VALUE, _), liscia) :- (VALUE >=4 & VALUE <= 7) | VALUE = 2.
card_range_match(card(VALUE, _), figura) :- VALUE >= 8 & VALUE <= 10.
card_range_match(card(VALUE, _), carico) :- VALUE = 1 | VALUE = 3.
card_range_match(_, any).
	
/* A card naturally matches its own seed. Every card, that is not a briscola, matches also the special seed "any". */
card_seed_match(card(_, SEED), SEED).
card_seed_match(SEED, any) :- not(briscola(card(_, SEED))).
	
/* A player needs to have a rule to make a basic evaluation of a card, considering the benefits involving in playing it. 
 * The basic principle is to attribute higher scores at the lower cards, to discourage the play of high card, 
 * if not strictly necessary. 
 */
basic_card_evaluation(card(VALUE, SEED), SCORE) :-
	card_range_match(card(VALUE, SEED), RANGE) & RANGE \== any &
	basic_card_evaluation(card(RANGE, SEED), SCORE).
basic_card_evaluation(card(carico, MY_SEED), 4) :- briscola(card(_, MY_SEED)).
basic_card_evaluation(card(carico, _), 3).
basic_card_evaluation(card(figura, MY_SEED), 5) :- briscola(card(_, MY_SEED)).
basic_card_evaluation(card(figura, _), 7).
basic_card_evaluation(card(liscia, MY_SEED), 6) :- briscola(card(_, MY_SEED)).
basic_card_evaluation(card(liscia, _), 8).
	
/* A player needs to detect the winning card in a bunch of cards, with the information of which one of them is the 
 * current dominant card (generally the first that has been played in the current hand). 
 */
winning_card([], dominant(D_CARD, D_PL, D_TEAM), win(D_CARD, D_PL, D_TEAM)).
winning_card([card_played(card(V, S), PL, TEAM, ORDER)|T], dominant(card(D_V, D_S), _, _), win(W_CARD, W_PL, W_TEAM)) :-
	S == D_S & (V == 1 | (V == 3 & D_V \== 1) | (V > D_V & D_V \== 1 & D_V \== 3)) & 
	winning_card(T, dominant(card(V, S), PL, TEAM), win(W_CARD, W_PL, W_TEAM)).
winning_card([card_played(card(V, S), PL, TEAM, ORDER)|T], dominant(card(_, D_S), _, _), win(W_CARD, W_PL, W_TEAM)) :-
	S \== D_S & briscola(card(_, S)) & winning_card(T, dominant(card(V, S), PL, TEAM), win(W_CARD, W_PL, W_TEAM)).
winning_card([_|T], dominant(D_CARD, D_PL, D_TEAM), win(W_CARD, W_PL, W_TEAM)) :- 
	winning_card(T, dominant(D_CARD, D_PL, D_TEAM), win(W_CARD, W_PL, W_TEAM)).
	
/* A player needs to know how to formulate an appropriate question to its companion. 
 * According to a specific card, a related question that could be asked exists.
 */
think_question(card(VALUE, SEED), question(ASK_RANGE, ASK_SEED)) :- 
	card_range_match(card(VALUE, SEED), RANGE) & RANGE \== any &
	think_question(card(RANGE, SEED), question(ASK_RANGE, ASK_SEED)).
think_question(card(carico, MY_SEED), question(carico, any)) :- briscola(card(_, MY_SEED)).
think_question(card(carico, _), question(carico, ASK_SEED)) :- briscola(card(_, ASK_SEED)).
think_question(card(figura, MY_SEED), question(figura, any)) :- briscola(card(_, MY_SEED)).
think_question(card(figura, _), question(any, ASK_SEED)) :- briscola(card(_, ASK_SEED)).
think_question(card(liscia, MY_SEED), question(figura, any)) :- briscola(card(_, MY_SEED)).
think_question(card(liscia, MY_SEED), question(any, MY_SEED)).
	
	
/* Initial goals */

!start.


/* Beliefs addition */

/* This agent has just received a message from the referee containing the name of its team. 
 * That means that he can look at the table waiting for the briscola to be placed and listen to any questions 
 * from its companion.
 */
+team_name(TEAM) <-
	+turn(1);
	!look_at_briscola;
	+silent_mode(false);
	!serve_question.
	
/* This agent has just received a message from the referee which says it's its turn to play. */
+your_turn(can_speak(X)): .count(card(VALUE, SEED), 3) | (turn(N) & N >= 9) <-
	!play_turn;
	-your_turn(_)[source(referee)];
	-turn(N);
	+turn(N+1);
	.abolish(conversation(_, _, _, _, _, _));
	.abolish(card_played(_,_,_,_));
	if (silent_mode(true)) {
		-+silent_mode(false);
		!serve_question;	
	}.
	
/* The game is over and the referee has just notified this player the final result. The player reacts to the 
 * final result, and then ends his execution.
 */
+game_result(GAME_RESULT) <- 
	!game_over(GAME_RESULT);
	.print("Bye!")
	.my_name(ME);
	.kill_agent(ME).


/* Plans */

// --------------- GAME SETUP --------------- 

/* This player tries immediately to participate in the game. */
+!start <- 
	!wanna_play.
	
/* To participate in the game, this player sends a wanna_play message to the referee. */			 
+!wanna_play <- 
	.my_name(ME);
	.print("Hello, I'm ", ME, ", I wanna play!");
	.send(referee, tell, wanna_play(from(ME))).
	
/* This player looks at the briscola card on the table. */
+!look_at_briscola <-
	t4jn.api.rd("default", "127.0.0.1", "20504", briscola(_), RD_B);
	t4jn.api.getResult(RD_B, BRISCOLA);
	+BRISCOLA.

// --------------- THINK ---------------	

/* It's the turn of this player, he needs to think of a strategy. */
+!play_turn: .count(card(VALUE, SEED), N) & N >= 1 <-
	.print("It's my turn! I need some time to think...");
	!think.
	
/* This is the key plan of the player. In here he follows a certain strategy to play the right card. 
 * 1) He evaluates his cards, using also the information that are on the table.
 * 2) He chooses the best card.
 * 3) If he's not completely sure about playing that card, he asks some advice to his companion (only if the 
 * 	  referee allows it). Otherwise, if he has no second thoughts, he plays that card.
 */
+!think <-
	!time_to_think;
	!evaluate_cards;
	!choose_best_card(BEST_CARD, BEST_SCORE);
	?your_turn(can_speak(CAN_SPEAK));
	!can_ask_questions(CAN_ASK);
	if (CAN_SPEAK & CAN_ASK & BEST_SCORE <= 7) {
		!choose_card_to_ask(ASK_CARD);
		!ask_companion(ASK_CARD);
		!think;
	} else {
		!play_card(BEST_CARD);
	}.
	
/* The player evaluates every card in his hands, compared to the cards on the table. */
+!evaluate_cards: not(card_score(_, _, _)) <-
	!watch_cards_on_the_table;
	.findall(card(VALUE, SEED), card(VALUE, SEED), CARDS_LIST);
	.print("I'm evaluating my cards...");
	for ( .member(CARD, CARDS_LIST) ) {
		!eval_card(CARD);
	}.
+!evaluate_cards: card_score(_, _, _).
	
/* The player looks at the table and get all the knowledge about the cards played by the other players. */
+!watch_cards_on_the_table <-
	.print("I'm looking at the cards on the table...");
	t4jn.api.rdAll("default", "127.0.0.1", "20504", card_played(_, _, _, _), CARDS_OP);
	t4jn.api.getResult(CARDS_OP, RESULT);
	for ( .member(card_played(PLAYED_CARD, PLAYER, TEAM, ORDER), RESULT) ) {
		+card_played(PLAYED_CARD, PLAYER, TEAM, ORDER);
	}
	.length(RESULT, L);
	-+my_order(L+1).

/* The player evaluate a single card, assigning to it a certain score (from 1 to 10). If the score is high, 
 * it means that could be a good idea to play that card.
 */	
+!eval_card(CARD) <- 
	?basic_card_evaluation(CARD, SCORE);
	+card_score(CARD, SCORE, final(false));
	.findall(card_played(P_CARD, PLAYER, TEAM, ORDER), card_played(P_CARD, PLAYER, TEAM, ORDER), TABLE_CARDS);
	if (not(.empty(TABLE_CARDS))) {
		.member(card_played(D_CARD, D_PL, D_TEAM, order(1)), TABLE_CARDS);
		!eval_card_with_table_cards(CARD, dominant(D_CARD, D_PL, D_TEAM), TABLE_CARDS);
	}.

/* The player evaluate a card compared to the cards already played by the other players in the current turn. */
+!eval_card_with_table_cards(CARD, DOMINANT, LIST) <-
	?winning_card(LIST, DOMINANT, win(W_CARD, from(W_PLAYER), team(W_TEAM)));
	if (team_name(W_TEAM)) {
		!eval_card_with_team_winning(my_card(CARD));
	} else {
		!eval_card_with_team_losing(my_card(CARD), win(W_CARD, from(W_PLAYER), team(W_TEAM)));
	}.

/* The previous score of a certain card of the player is updated following this reasoning: if the temporary 
 * winning card has been played by my companion, every card that could increase the team score is valued more,
 * while the score assigned to pointless cards or briscola cards is decreased.
 */	
+!eval_card_with_team_winning(my_card(card(VALUE, SEED))) <-
	?card_range_match(card(VALUE, SEED), RANGE);
	-card_score(card(VALUE, SEED), SCORE, FINAL);
	if (briscola(card(_, SEED)) | RANGE == liscia) {
		+card_score(card(VALUE, SEED), SCORE-3, FINAL);
	} else {
		+card_score(card(VALUE, SEED), SCORE+3, FINAL);
	}.

/* The previous score of a certain card of the player is updated following this reasoning: if the temporary 
 * winning card has been played by an opponent, every card that could win against the current opponent card is
 * valued way more than before.
 */		
+!eval_card_with_team_losing(my_card(CARD), win(card(D_V, D_S), from(D_PL), team(D_TEAM))) <-
	.my_name(ME);
	?team_name(T);
	?my_order(MY_ORDER);
	?winning_card([card_played(CARD, from(ME), team(T), order(MY_ORDER))], 
		dominant(card(D_V, D_S), from(D_PL), team(D_T)), win(_, from(W_PL), _)
	);
	if (W_PL == ME) {
		-card_score(card(VALUE, SEED), SCORE, FINAL);
		+card_score(card(VALUE, SEED), SCORE+6, FINAL);
	}.
	
/* The player picks the best card out of the previous evaluated cards in his hands. */
+!choose_best_card(BEST_CARD, BEST_SCORE) <-
	.findall(SCORE, card_score(_, SCORE, _), CARDS_SCORES);
	.max(CARDS_SCORES, BEST_SCORE);
	?card_score(BEST_CARD, BEST_SCORE, _).

/* The players checks if he has the maximum information about his cards (in this case the result is false) 
 * or if he can get some advice from his companion (in this case the result is true).
 */
+!can_ask_questions(COUNT_ASK > 0) <-
	.count(card_score(_, _, final(false)), COUNT_ASK).

+!choose_card_to_ask(ASK_CARD) <-
	.findall(SCORE, card_score(CARD, SCORE, final(false)), ASK_LIST);
	.max(ASK_LIST, MAX_SCORE);
	?card_score(ASK_CARD, MAX_SCORE, final(false)).
	
// --------------- PLAY CARD ---------------

/* The player plays a specific card from his hands. */
+!play_card(card(VALUE, SEED)) <-
	.print("I'm playing this card: ", VALUE, " of ", SEED, ".");
	-card(VALUE, SEED)[source(dealer)];
	.abolish(card_score(_, _, _));
	!place_card_on_the_table(card(VALUE, SEED)).

/* The player put the card he wants to play on the table. */
+!place_card_on_the_table(CARD) <-
	.my_name(ME);
	?team_name(MY_TEAM);
	?my_order(ORDER);
	t4jn.api.out("default", "127.0.0.1", "20504", card_played(CARD, from(ME), team(MY_TEAM), order(ORDER)), OUT_CARD).
	
// --------------- ASK COMPANION ---------------

/* The player wants to play a card, but he's not sure about it. So he asks a question about that specific card 
 * to his companion, in order to get some help. In the question, the player asks his companion if he has a card
 * corresponding with a certain range and/or seed.
 */
+!ask_companion(card(VALUE, SEED)) <-
	?think_question(card(VALUE, SEED), question(ASK_RANGE, ASK_SEED));
	if (conversation(_, _, _, ask(ASK_RANGE, ASK_SEED), answer(ANSWER), _)) {
		!update_card_score(card(VALUE, SEED), ANSWER);
	} else {
		.print("Mm, I need some help from my teammate: do you have ", ASK_RANGE, " of ", ASK_SEED, "?");
		?team_name(MY_TEAM);
		.my_name(ME);
		?sequence_number(SN);
		t4jn.api.out("default", "127.0.0.1", "20504", ask_companion(team(MY_TEAM), from(ME), ask(ASK_RANGE, ASK_SEED), seq(SN)), OUT_ASK);
		!process_response(card(VALUE, SEED));
	}.
	
/* The player has previously ask a question to his companion and now he processes the response. The companion 
 * answer is binary: positive if he has a card matching the requested one in the question, negative otherwise.
 */
+!process_response(card(VALUE, SEED)) <-
	?team_name(MY_TEAM);
	.my_name(ME);
	-sequence_number(SN);
	t4jn.api.rd("default", "127.0.0.1", "20504", conversation(team(MY_TEAM), from(ME), _, _, _, seq(SN)), RD_ANS);
	t4jn.api.getResult(RD_ANS, RESULT);
	+RESULT;
	.print("Okay, let me think about it...");
	?conversation(team(MY_TEAM), from(ME), _, _, answer(ANSWER), seq(SN));
	+sequence_number(SN + 1);
	!update_card_score(card(VALUE, SEED), ANSWER).
	
/* The player has received the answer to his question about a card. If it's positive, the score of the card grows, 
 * on the other hand, if it's negative the score of the card decreases.
 */
+!update_card_score(CARD, UP) <-
	-card_score(CARD, SCORE, _);
	if (UP) {
		+card_score(CARD, SCORE + 3, final(true));
	} else {
		+card_score(CARD, SCORE - 3, final(true));
	}.
	
// --------------- ANSWER COMPANION ---------------

/* The player listens to any incoming questions from his companion. If one comes, he processes it and answers to it. */
+!serve_question <-
	!receive_question(PLAYER, QUESTION_RANGE, QUESTION_SEED, SEQUENCE_NUMBER);
	.my_name(ME);
	if (PLAYER \== ME) {
		!process_question(QUESTION_RANGE, QUESTION_SEED);
		!answer_question(SEQUENCE_NUMBER);
		!serve_question;
	} else {
		-+silent_mode(true);
	}.
	
/* The player listens to any incoming questions from his companion. */
+!receive_question(PLAYER, QUESTION_RANGE, QUESTION_SEED, SEQUENCE_NUMBER): team_name(MY_TEAM) <-
	t4jn.api.rd("default", "127.0.0.1", "20504", ask_companion(team(MY_TEAM), _, _, _), RD_Q);
	t4jn.api.getResult(RD_Q, RESULT);
	+RESULT;
	-ask_companion(team(MY_TEAM), from(PLAYER), ask(QUESTION_RANGE, QUESTION_SEED), seq(SEQUENCE_NUMBER)).
	
/* The player has received a question from his companion. The companion ask if the player has a card that 
 * matches the indications reported in the question. In this plan the player checks his cards to search for 
 * such card.
 */
+!process_question(QUESTION_RANGE, QUESTION_SEED) <-
	.print("Mm, let me check my cards...");
	!time_to_think;
	+answer_companion(false);
	for ( card(VALUE, SEED) ) {
		if (card_match(card(VALUE, SEED), QUESTION_RANGE, QUESTION_SEED)) {
			-+answer_companion(true);
		}
	}.

/* The player sends the response to the question of his companion. */
+!answer_question(SEQUENCE_NUMBER): team_name(MY_TEAM) & answer_companion(RESPONSE) <-
	if (RESPONSE) {
		.print("Yes, I have the card you're looking for!");
	} else {
		.print("I'm sorry, but I don't have such card.");
	}
	.my_name(ME);
	t4jn.api.out("default", "127.0.0.1", "20504", answer_companion(team(MY_TEAM), from(ME), RESPONSE, seq(SEQUENCE_NUMBER)), OUT_A);
	-answer_companion(_).

// --------------- GAME_OVER ---------------

/* The game is over. The player reacts to the final result of the game. */
+!game_over(win(MY_TEAM)): team_name(MY_TEAM) <- .print("Wow :)").
+!game_over(win(MY_TEAM)): team_name(WINNING_TEAM) & MY_TEAM \== WINNING_TEAM <- .print("Sob :(").
+!game_over(draw): team_name(_) <- .print("Okay :|").
	
// --------------- TIME TO THINK ---------------

+!time_to_think <- .wait(2000).
