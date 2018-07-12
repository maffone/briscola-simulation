// Agent dealer in project briscolaSimulation

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Beliefs addition */

+setup_deck(order(PLAYERS)): true <-
	+order(PLAYERS);
	-setup_deck(order(PLAYERS))[source(SENDER)];
	!distribute_first_cards;
	!notify_job_end(SENDER).
	
+give_cards(order(PLAYERS)): true <-
	+order(PLAYERS);
	-give_cards(order(PLAYERS))[source(SENDER)];
	!distribute_cards;
	!notify_job_end(SENDER).

/* Plans */

+!start: true <- 
	.print("Hello, I'm the dealer!");
	!create_deck.
	// The following are the messages that these agent should receive from the referee.
	//+setup_deck(order([player1, player2, player3, player4])).
	//+give_cards(order([player1, player2, player3, player4])).

+!create_deck: not deck(_) <- 
	.print("Creating deck.");
	+deck([]);
	!add_cards.
	
+!add_cards: deck(_) <-
	!add_seed(1,10,"denari");
	!add_seed(1,10,"bastoni");
	!add_seed(1,10,"spade");
	!add_seed(1,10,"coppe").
	
+!add_seed(MIN, MAX, SEED): MIN > MAX <-
	true.
	
+!add_seed(MIN, MAX, SEED): deck(CARDS) & MIN <= MAX <-
	-+deck([card(MIN, SEED)|CARDS]);
	!add_seed(MIN+1, MAX, SEED).

+!distribute_first_cards <- 
	!shuffle_deck;
	!distribute_cards_to_players(3);
	!place_briscola.

+!distribute_cards <-
	!distribute_cards_to_players(1).

+!shuffle_deck: deck(CARDS) <-
	.print("Shuffling deck.");
	.shuffle(CARDS, SHUFFLED_CARDS);
	-+deck(SHUFFLED_CARDS).

+!distribute_cards_to_players(CARDS_NUMBER): deck([]) <-
	.print("Deck is empty").

+!distribute_cards_to_players(CARDS_NUMBER): order(PLAYERS) & deck(CARDS) & .length(CARDS, DECK_COUNT) & 
											 .length(PLAYERS, PL_COUNT) & DECK_COUNT >= CARDS_NUMBER * PL_COUNT <-
	.print("Distributing cards to players");
	for ( .member(PLAYER, PLAYERS) ) {
		!distribute_cards_to_player(PLAYER, CARDS_NUMBER);
	};
	-order(PLAYER).

+!distribute_cards_to_player(PLAYER, CARDS_NUMBER): CARDS_NUMBER < 1 <-
	true.

+!distribute_cards_to_player(PLAYER, CARDS_NUMBER): CARDS_NUMBER >= 1 & deck([CARD|TAIL]) <-
	.send(PLAYER, tell, CARD);
	-+deck(TAIL);
	!distribute_cards_to_player(PLAYER, CARDS_NUMBER-1).
	
+!place_briscola: deck([CARD|TAIL]) <-
	.print("Placing the briscola");
	t4jn.api.out("default", "127.0.0.1", "20504", briscola(CARD), OUT_BRISCOLA);
	-+deck(TAIL).
	
+!notify_job_end(RECEIVER) <-
	.send(RECEIVER, tell, card_distribution_done).
	