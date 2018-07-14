// Agent watcher_player in project briscolaSimulation.
// This agent can asks questions to its companion, looks at the cards played by other players, 
// and chooses the best card to play accordingly.

/* Initial beliefs and rules */

sequence_number(0).

card_match(CARD, RANGE, SEED) :- card_range_match(CARD, RANGE) & card_seed_match(CARD, SEED).

card_range_match(card(VALUE, _), liscia) :- (VALUE >=4 & VALUE <= 7) | VALUE = 2.
card_range_match(card(VALUE, _), figura) :- VALUE >= 8 & VALUE <= 10.
card_range_match(card(VALUE, _), carico) :- VALUE = 1 | VALUE = 3.
card_range_match(_, any).
	
card_seed_match(card(_, SEED), SEED).
card_seed_match(SEED, any) :- not(briscola(card(_, SEED))).

think_question(card(VALUE, SEED), question(ASK_RANGE, ASK_SEED)) :- 
	card_range_match(card(VALUE, SEED), RANGE) & RANGE \== any &
	think_question(card(RANGE, SEED), question(ASK_RANGE, ASK_SEED)).
think_question(card(carico, MY_SEED), question(carico, any)) :- briscola(card(_, MY_SEED)).
think_question(card(carico, _), question(carico, ASK_SEED)) :- briscola(card(_, ASK_SEED)).
think_question(card(figura, MY_SEED), question(figura, any)) :- briscola(card(_, MY_SEED)).
think_question(card(figura, _), question(any, ASK_SEED)) :- briscola(card(_, ASK_SEED)).
think_question(card(liscia, MY_SEED), question(figura, any)) :- briscola(card(_, MY_SEED)).
think_question(card(liscia, MY_SEED), question(any, MY_SEED)).
	
basic_card_evaluation(card(VALUE, SEED), SCORE) :-
	card_range_match(card(VALUE, SEED), RANGE) & RANGE \== any &
	basic_card_evaluation(card(RANGE, SEED), SCORE).
basic_card_evaluation(card(carico, MY_SEED), 4) :- briscola(card(_, MY_SEED)).
basic_card_evaluation(card(carico, _), 3).
basic_card_evaluation(card(figura, MY_SEED), 5) :- briscola(card(_, MY_SEED)).
basic_card_evaluation(card(figura, _), 7).
basic_card_evaluation(card(liscia, MY_SEED), 6) :- briscola(card(_, MY_SEED)).
basic_card_evaluation(card(liscia, _), 8).
	
winning_card([], dominant(D_CARD, D_PL, D_TEAM), win(D_CARD, D_PL, D_TEAM)).
winning_card([card_played(card(V, S), PL, TEAM, ORDER)|T], dominant(card(D_V, D_S), _, _), win(W_CARD, W_PL, W_TEAM)) :-
	S == D_S & (V == 1 | (V == 3 & D_V \== 1) | (V > D_V & D_V \== 1 & D_V \== 3)) & 
	winning_card(T, dominant(card(V, S), PL, TEAM), win(W_CARD, W_PL, W_TEAM)).
winning_card([card_played(card(V, S), PL, TEAM, ORDER)|T], dominant(card(_, D_S), _, _), win(W_CARD, W_PL, W_TEAM)) :-
	S \== D_S & briscola(card(_, S)) & winning_card(T, dominant(card(V, S), PL, TEAM), win(W_CARD, W_PL, W_TEAM)).
winning_card([_|T], dominant(D_CARD, D_PL, D_TEAM), win(W_CARD, W_PL, W_TEAM)) :- 
	winning_card(T, dominant(D_CARD, D_PL, D_TEAM), win(W_CARD, W_PL, W_TEAM)).
	
/* Initial goals */

!start.
//!test_stuff.

/* Beliefs addition */

+team_name(TEAM) <-
	+turn(1);
	!look_at_briscola;
	+silent_mode(false);
	!serve_question.
	
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

/* Plans */


/***** GAME SETUP *****/
+!start <- 
	!wanna_play.
				 
+!wanna_play <- 
	.my_name(ME);
	.print("Hello, I'm ", ME, ", I wanna play!");
	.send(referee, tell, wanna_play(from(ME))).
	
+!look_at_briscola <-
	t4jn.api.rd("default", "127.0.0.1", "20504", briscola(_), RD_B);
	t4jn.api.getResult(RD_B, BRISCOLA);
	+BRISCOLA.

/***** THINK ******/	
+!play_turn: .count(card(VALUE, SEED), N) & N >= 1 <-
	.print("It's my turn! I need some time to think...");
	!think.
	
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
	
+!evaluate_cards: card_score(_, _, _).
	
+!evaluate_cards: not(card_score(_, _, _)) <-
	!watch_cards_on_the_table;
	.findall(card(VALUE, SEED), card(VALUE, SEED), CARDS_LIST);
	.print("I'm evaluating my cards...");
	for ( .member(CARD, CARDS_LIST) ) {
		!eval_card(CARD);
	}.
	
+!watch_cards_on_the_table <-
	.print("I'm looking at the cards on the table...");
	t4jn.api.rdAll("default", "127.0.0.1", "20504", card_played(_, _, _, _), CARDS_OP);
	t4jn.api.getResult(CARDS_OP, RESULT);
	for ( .member(card_played(PLAYED_CARD, PLAYER, TEAM, ORDER), RESULT) ) {
		+card_played(PLAYED_CARD, PLAYER, TEAM, ORDER);
	}
	.length(RESULT, L);
	-+my_order(L+1).
	
+!eval_card(CARD) <- 
	?basic_card_evaluation(CARD, SCORE);
	+card_score(CARD, SCORE, final(false));
	.findall(card_played(P_CARD, PLAYER, TEAM, ORDER), card_played(P_CARD, PLAYER, TEAM, ORDER), TABLE_CARDS);
	if (not(.empty(TABLE_CARDS))) {
		.member(card_played(D_CARD, D_PL, D_TEAM, order(1)), TABLE_CARDS);
		!eval_card_with_table_cards(CARD, dominant(D_CARD, D_PL, D_TEAM), TABLE_CARDS);
	}.
	
+!eval_card_with_table_cards(CARD, DOMINANT, LIST) <-
	?winning_card(LIST, DOMINANT, win(W_CARD, from(W_PLAYER), team(W_TEAM)));
	if (team_name(W_TEAM)) {
		!eval_card_with_team_winning(my_card(CARD));
	} else {
		!eval_card_with_team_losing(my_card(CARD), win(W_CARD, from(W_PLAYER), team(W_TEAM)));
	}.
	
+!eval_card_with_team_winning(my_card(card(VALUE, SEED))) <-
	?card_range_match(card(VALUE, SEED), RANGE);
	-card_score(card(VALUE, SEED), SCORE, FINAL);
	if (briscola(card(_, SEED)) | RANGE == liscia) {
		+card_score(card(VALUE, SEED), SCORE-3, FINAL);
	} else {
		+card_score(card(VALUE, SEED), SCORE+3, FINAL);
	}.
	
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
	
+!choose_best_card(BEST_CARD, BEST_SCORE) <-
	.findall(SCORE, card_score(_, SCORE, _), CARDS_SCORES);
	.max(CARDS_SCORES, BEST_SCORE);
	?card_score(BEST_CARD, BEST_SCORE, _).

+!can_ask_questions(COUNT_ASK > 0) <-
	.count(card_score(_, _, final(false)), COUNT_ASK).

+!choose_card_to_ask(ASK_CARD) <-
	.findall(SCORE, card_score(CARD, SCORE, final(false)), ASK_LIST);
	.max(ASK_LIST, MAX_SCORE);
	?card_score(ASK_CARD, MAX_SCORE, final(false)).
	

/***** PLAY CARD *****/	
+!play_card(card(VALUE, SEED)) <-
	.print("I'm playing this card: ", VALUE, " of ", SEED, ".");
	-card(VALUE, SEED)[source(dealer)];
	.abolish(card_score(_, _, _));
	!place_card_on_the_table(card(VALUE, SEED)).
	
+!place_card_on_the_table(CARD) <-
	.my_name(ME);
	?team_name(MY_TEAM);
	?my_order(ORDER);
	t4jn.api.out("default", "127.0.0.1", "20504", card_played(CARD, from(ME), team(MY_TEAM), order(ORDER)), OUT_CARD).
	
/***** ASK COMPANION *****/
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
	
+!update_card_score(CARD, UP) <-
	-card_score(CARD, SCORE, _);
	if (UP) {
		+card_score(CARD, SCORE + 3, final(true));
	} else {
		+card_score(CARD, SCORE - 3, final(true));
	}.
	
/***** ANSWER COMPANION *****/	
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
	
+!receive_question(PLAYER, QUESTION_RANGE, QUESTION_SEED, SEQUENCE_NUMBER): team_name(MY_TEAM) <-
	t4jn.api.rd("default", "127.0.0.1", "20504", ask_companion(team(MY_TEAM), _, _, _), RD_Q);
	t4jn.api.getResult(RD_Q, RESULT);
	+RESULT;
	-ask_companion(team(MY_TEAM), from(PLAYER), ask(QUESTION_RANGE, QUESTION_SEED), seq(SEQUENCE_NUMBER)).
	
+!process_question(QUESTION_RANGE, QUESTION_SEED) <-
	.print("Mm, let me check my cards...");
	!time_to_think;
	+answer_companion(false);
	for ( card(VALUE, SEED) ) {
		if (card_match(card(VALUE, SEED), QUESTION_RANGE, QUESTION_SEED)) {
			-+answer_companion(true);
		}
	}.

+!answer_question(SEQUENCE_NUMBER): team_name(MY_TEAM) & answer_companion(RESPONSE) <-
	if (RESPONSE) {
		.print("Yes, I have the card you're looking for!");
	} else {
		.print("I'm sorry, but I don't have such card.");
	}
	.my_name(ME);
	t4jn.api.out("default", "127.0.0.1", "20504", answer_companion(team(MY_TEAM), from(ME), RESPONSE, seq(SEQUENCE_NUMBER)), OUT_A);
	-answer_companion(_).
	
/***** TIME TO THINK *****/
+!time_to_think <- .wait(2000).
	
/***** TEST *****/
+!test_stuff <-
	+briscola(card(_, SEED));
	?winning_card(
		[played(card(3, coppe), from(player2), team(blue))], 
		dominant(card(1, bastoni), from(player1), team(RED)),
		win(card(W_VALUE, W_SEED), from(W_PLAYER), team(W_TEAM))
	);
	.print(W_VALUE, " of ", W_SEED).
	
	
	
	