// Agent watcher_player in project briscolaSimulation.
// This agent can asks questions to its companion, looks at the cards played by other players, 
// and chooses the best card to play accordingly.

/* Initial beliefs and rules */

card_match(CARD, RANGE, SEED) :- card_range_match(CARD, RANGE) & card_seed_match(CARD, SEED).

card_range_match(card(VALUE, _), liscia) :- (VALUE >=4 & VALUE <= 7) | VALUE = 2.
card_range_match(card(VALUE, _), figura) :- VALUE >= 8 & VALUE <= 10.
card_range_match(card(VALUE, _), carico) :- VALUE = 1 | VALUE = 3.
card_range_match(_, any).
	
card_seed_match(card(_, SEED), SEED).
card_seed_match(SEED, any) :- not(briscola(card(_, SEED))).
//card_seed_match(_, any).

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
	
/* Initial goals */

!start.
//!test_stuff.

/* Beliefs addition */

+team_name(TEAM) <-
	.print("I'm in the ", TEAM, " team.");
	+turn(1);
	!look_at_briscola;
	!serve_question.
	
+your_turn(can_speak(X)): .count(card(VALUE, SEED), 3) | (turn(N) & N >= 9) <-
	!play_turn;
	-your_turn(_);
	-+turn(N + 1).

-your_turn(_) <-
	!serve_question.

/* Plans */

+!start: true <- 
	.my_name(ME);
	.print("Hello, I'm ", ME, "!");
	!wanna_play.
				 
+!wanna_play <- 
	.print("I wanna play");
	.my_name(ME);
	.send(referee, tell, wanna_play(from(ME))).
	
+!look_at_briscola <-
	t4jn.api.rd("default", "127.0.0.1", "20504", briscola(_), RD_B);
	t4jn.api.getResult(RD_B, BRISCOLA);
	+BRISCOLA.
	
+!serve_question <-
	!receive_question(PLAYER, QUESTION_RANGE, QUESTION_SEED);
	.my_name(ME);
	if (PLAYER \== ME) {
		!process_question(QUESTION_RANGE, QUESTION_SEED);
		!answer_question;
		!serve_question;
	}.
	
+!receive_question(PLAYER, QUESTION_RANGE, QUESTION_SEED): team_name(MY_TEAM) <-
	t4jn.api.rd("default", "127.0.0.1", "20504", ask_companion(team(MY_TEAM), _, _), RD_Q);
	t4jn.api.getResult(RD_Q, RESULT);
	+RESULT;
	?ask_companion(team(MY_TEAM), from(PLAYER), ask(QUESTION_RANGE, QUESTION_SEED)).
	
+!process_question(QUESTION_RANGE, QUESTION_SEED) <-
	.print("Question received, processing...");
	!time_to_think;
	+answer_companion(false);
	for ( card(VALUE, SEED) ) {
		if (card_match(card(VALUE, SEED), QUESTION_RANGE, QUESTION_SEED)) {
			-+answer_companion(true);
		}
	}.

+!answer_question: team_name(MY_TEAM) & answer_companion(RESPONSE) <-
	.print("Sending response: ", RESPONSE);
	.my_name(ME);
	t4jn.api.out("default", "127.0.0.1", "20504", answer_companion(team(MY_TEAM), from(ME), RESPONSE), OUT_A);
	-answer_companion(_).
	
+!play_turn: .count(card(VALUE, SEED), N) & N >= 1 <-
	.print("It's my turn!");
	!think.
	
+!think <-
	.print("Thinking...");
	!time_to_think;
	!evaluate_cards;
	!choose_best_card(BEST_CARD, BEST_SCORE);
	?your_turn(can_speak(CAN_SPEAK));
	if (CAN_SPEAK & BEST_SCORE < 8) {
		!ask_companion(BEST_CARD);
	} else {
		!play_card(BEST_CARD);
	}.
	
+!evaluate_cards: card_score(_, _).
	
+!evaluate_cards: not(card_score(_, _)) <-
	.findall(card(VALUE, SEED), card(VALUE, SEED), CARDS_LIST);
	for ( .member(CARD, CARDS_LIST) ) {
		!eval_card(CARD);
	}.
	
+!eval_card(CARD) <- 
	?basic_card_evaluation(CARD, SCORE);
	+card_score(CARD, SCORE).
	
+!choose_best_card(BEST_CARD, BEST_SCORE) <-
	.findall(SCORE, card_score(_, SCORE), CARDS_SCORES);
	.max(CARDS_SCORES, BEST_SCORE);
	?card_score(BEST_CARD, BEST_SCORE).
	
+!ask_companion(card(VALUE, SEED)) <-
	?think_question(card(VALUE, SEED), question(ASK_RANGE, ASK_SEED));
	.print("Sending question to companion: do you have ", ASK_RANGE, " of ", ASK_SEED, "?");
	?team_name(MY_TEAM);
	.my_name(ME);
	t4jn.api.out("default", "127.0.0.1", "20504", ask_companion(team(MY_TEAM), from(ME), ask(ASK_RANGE, ASK_SEED)), OUT_ASK);
	!process_response(card(VALUE, SEED)).
	
+!process_response(card(VALUE, SEED)) <-
	?team_name(MY_TEAM);
	.my_name(ME);
	t4jn.api.rd("default", "127.0.0.1", "20504", conversation(team(MY_TEAM), from(ME), _, _, _), RD_ANS);
	t4jn.api.getResult(RD_ANS, RESULT);
	+RESULT;
	.print("Companion answer received, processing...");
	?conversation(team(MY_TEAM), from(ME), _, _, answer(ANSWER));
	!update_card_score(card(VALUE, SEED), ANSWER);
	!think.
	
+!update_card_score(CARD, UP) <-
	-card_score(CARD, SCORE);
	if (UP) {
		+card_score(CARD, SCORE + 3);
	} else {
		+card_score(CARD, SCORE - 3);
	}.
	
+!play_card(card(VALUE, SEED)) <-
	.print("Playing card: ", VALUE, " of ", SEED, ".");
	!place_card_on_the_table(card(VALUE, SEED));
	.abolish(card_score(_)).
	
+!place_card_on_the_table(CARD) <-
	.my_name(ME);
	?team_name(MY_TEAM);
	t4jn.api.out("default", "127.0.0.1", "20504", card_played(CARD, from(ME), team(MY_TEAM)), OUT_CARD).
	
+!time_to_think <- .wait(2000).
	
+!test_stuff <-
	+briscola(card(6, coppe));
	+team_name(red);
	+card(1, spade);
	+card_score(card(1, spade), 6);
	?card_score(card(1, spade), CARD_SCORE_BEFORE);
	.print("Card score before: ", CARD_SCORE_BEFORE);
	!ask_companion(card(1, spade));
	?card_score(card(1, spade), CARD_SCORE_AFTER);
	.print("Card score after: ", CARD_SCORE_AFTER).
	