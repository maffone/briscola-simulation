// Agent talkative_player in project briscolaSimulation.
// This agent can asks questions to its companion and chooses the best card to play accordingly.

/* Initial beliefs and rules */

card_match(CARD, RANGE, SEED) :-
	card_range_match(CARD, RANGE) & card_seed_match(CARD, SEED).

card_range_match(card(VALUE, _), liscia) :- 
	(VALUE >=4 & VALUE <= 7) | VALUE = 2.
card_range_match(card(VALUE, _), figura) :-
	VALUE >= 8 & VALUE <= 10.
card_range_match(card(VALUE, _), carico) :-
	VALUE = 1 | VALUE = 3.
card_range_match(_, any).
	
card_seed_match(card(_, SEED), SEED).
card_seed_match(_, any).

companion_info(card(carico, _), question(ASK_RANGE, ASK_SEED)) :-
	ASK_RANGE = carico & briscola(ASK_SEED).
companion_info(card(carico, MY_SEED), question(ASK_RANGE, ASK_SEED)) :-
	briscola(MY_SEED) & ASK_RANGE = carico & ASK_SEED = any.
	
	
/* Initial goals */

!start.
//!test_stuff.

/* Beliefs addition */

+team_name(TEAM) <-
	.print("My team is ", TEAM, ".");
	+turn(1).
	//!serve_question.
	
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
	
+!serve_question <-
	!receive_question(PLAYER, QUESTION_RANGE, QUESTION_SEED);
	.my_name(ME);
	if (PLAYER \== ME) {
		.print("Question received.");
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
	.print("Processing question...");
	+answer_companion(false);
	for ( card(VALUE, SEED) ) {
		if (card_match(card(VALUE, SEED), QUESTION_RANGE, QUESTION_SEED)) {
			-+answer_companion(true);
		}
	}.

+!answer_question: team_name(MY_TEAM) & answer_companion(RESPONSE) <-
	.print("Sending response.");
	.my_name(ME);
	t4jn.api.out("default", "127.0.0.1", "20504", answer_companion(team(MY_TEAM), from(ME), RESPONSE), OUT_A);
	-answer_companion(_).
	
+!play_turn: .count(card(VALUE, SEED), N) & N >= 1 <-
	.print("It's my turn!");
	!think.
	
+!think: .findall(card(VALUE, SEED), card(VALUE, SEED), CARDS_LIST) <-
	.print("Thinking...");
	for ( .member(CARD, CARDS_LIST) ) {
		!eval_card(CARD);
	};
	.findall(SCORE, card_score(_, SCORE), CARDS_SCORES);
	.max(CARDS_SCORES, MAX_SCORE);
	?card_score(BEST_CARD, MAX_SCORE);
	?your_turn(can_speak(CAN_SPEAK));
	if (CAN_SPEAK & MAX_SCORE < 8) {
		!ask_companion(BEST_CARD);
	} else {
		!play_card(BEST_CARD);
	}.
	
+!eval_card(CARD) <- 
	+card_score(card(VALUE, SEED), 9).
	
+!ask_companion(card(VALUE, SEED)) <-
	.print("Sending question to companion.");
	?card_range_match(card(VALUE, SEED), RANGE);
	?companion_info(card(RANGE, SEED), question(ASK_RANGE, ASK_SEED));
	?team_name(MY_TEAM);
	.my_name(ME);
	t4jn.api.out("default", "127.0.0.1", "20504", ask_companion(team(MY_TEAM), from(ME), ask(ASK_RANGE, ASK_SEED)), OUT_ASK);
	!process_response(card(VALUE, SEED)).
	
+!process_response(card(VALUE, SEED)) <-
	.print("Processing companion answer...");
	?team_name(MY_TEAM);
	.my_name(ME);
	t4jn.api.rd("default", "127.0.0.1", "20504", conversation(team(MY_TEAM), from(ME), _, _, _), RD_ANS);
	t4jn.api.getResult(RD_ANS, RESULT);
	+RESULT;
	?conversation(team(MY_TEAM), from(ME), _, _, answer(ANSWER));
	?card_score(card(VALUE, SEED), SCORE);
	if (ANSWER) {
		-+card_score(card(VALUE, SEED), SCORE + 3);
	} else {
		-+card_score(card(VALUE, SEED), SCORE - 3);
	}.
	//!think.
	
+!play_card(card(VALUE, SEED)) <-
	.print("Playing card: ", VALUE, " of ", SEED, ".");
	!place_card_on_the_table(card(VALUE, SEED));
	.abolish(card_score(_)).
	
+!place_card_on_the_table(CARD) <-
	.my_name(ME);
	?team_name(MY_TEAM);
	t4jn.api.out("default", "127.0.0.1", "20504", card_played(CARD, from(ME), team(MY_TEAM)), OUT_CARD).
	
+!test_stuff <-
	+briscola(coppe);
	+team_name(red);
	+card(1, spade);
	+card_score(card(1, spade), 6);
	?card_score(card(1, spade), CARD_SCORE_BEFORE);
	.print("Card score before: ", CARD_SCORE_BEFORE);
	!ask_companion(card(1, spade));
	?card_score(card(1, spade), CARD_SCORE_AFTER);
	.print("Card score after: ", CARD_SCORE_AFTER).
	
	
	
	
	
	