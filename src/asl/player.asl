// Agent player in project briscolaSimulation

/* Initial beliefs and rules */

card_match(CARD, RANGE, SEED) :-
	card_range_match(CARD, RANGE) & card_seed_match(CARD, SEED).

card_range_match(card(VALUE, _), "liscia") :- 
	(VALUE >=4 & VALUE <= 7) | VALUE = 2.
card_range_match(card(VALUE, _), "figura") :-
	VALUE >= 8 & VALUE <= 10.
card_range_match(card(VALUE, _), "carico") :-
	VALUE = 1 | VALUE = 3.
card_range_match(_, "any").
	
card_seed_match(card(_, SEED), SEED).
card_seed_match(_, "any").

/* Initial goals */

!start.
//!test_stuff.

/* Beliefs addition */

+team_name(_) <-
	+turn(1);
	!serve_question.
	
+your_turn(can_speak(X)): .count(card(VALUE, SEED), 3) | (turn(N) & N >= 9) <-
	!play_turn;
	-your_turn(_);
	-+turn(N + 1).

/* Plans */

+!start: true <- 
	.my_name(ME);
	.print("Hello, I'm ", ME, "!");
	!wanna_play.
				 
+!wanna_play <- 
	.print("I wanna play");
	.my_name(ME);
	.send(referee, tell, wanna_play(from(ME))).
	
+!serve_question <-
	!receive_question(QUESTION_RANGE, QUESTION_SEED);
	!process_question(QUESTION_RANGE, QUESTION_SEED);
	!answer_question;
	!serve_question.
	
+!receive_question(QUESTION_RANGE, QUESTION_SEED): team_name(MY_TEAM) <-
	t4jn.api.rd("default", "127.0.0.1", "20504", ask_companion(team(MY_TEAM), _, _), RD_Q);
	.print("Question received.");
	t4jn.api.getResult(RD_Q, RESULT);
	t4jn.api.getArg(RESULT, 1, QUESTION_RANGE);
	t4jn.api.getArg(RESULT, 2, QUESTION_SEED).
	
+!process_question(QUESTION_RANGE, QUESTION_SEED) <-
	.print("Processing question...");
	+answer_companion(false);
	for ( card(VALUE, SEED) ) {
		if (card_match(card(VALUE, SEED), QUESTION_RANGE, QUESTION_SEED)) {
			-+answer_companion(true);
		}
	}.

+!answer_question: answer_companion(RESPONSE) <-
	.print("Sending response.");
	t4jn.api.out("default", "127.0.0.1", "20504", answer_companion(RESPONSE), OUT_A);
	-answer_companion(_).
	
+!play_turn: .count(card(VALUE, SEED), N) & N >= 1 <-
	.print("It's my turn!");
	!think;
	!play_card.
	
+!think: .findall(card(VALUE, SEED), card(VALUE, SEED), CARDS_LIST) <-
	.print("Thinking...");
	for ( .member(CARD, CARDS_LIST) ) {
		!eval_card(CARD)
	}.
	
+!eval_card(card(VALUE, SEED)) <- 
	+card_score(card(VALUE, SEED), 9).
	
+!play_card: .findall(SCORE, card_score(_, SCORE), CARDS_SCORES) <-
	.max(CARDS_SCORES, MAX_SCORE);
	?card_score(card(VALUE, SEED), MAX_SCORE);
	.print("Playing card: ", VALUE, " of ", SEED, ".");
	!place_card_on_the_table(card(VALUE, SEED));
	.abolish(card_score(_)).
	
+!place_card_on_the_table(CARD) <-
	.my_name(ME);
	?team_name(MY_TEAM);
	t4jn.api.out("default", "127.0.0.1", "20504", card_played(CARD, from(ME), team(MY_TEAM)), OUT_CARD).
	
+!test_stuff <-
	+card(6, "spade");
	+card(9, "coppe");
	+card(3, "coppe");
	+team_name("red").