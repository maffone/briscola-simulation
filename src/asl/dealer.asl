// Agent dealer in project briscolaSimulation

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Beliefs addition */

/*
 * When the dealer is told to setup the deck by the referee upon game start, it proceeds 
 * to shuffle the deck, distribute cards to the players and notify the referee when all its done.
 */
+setup_deck(order(PLAYERS)) <-
	+order(PLAYERS);
	-setup_deck(order(PLAYERS))[source(SENDER)];
	!distribute_first_cards;
	!notify_job_end(SENDER).

/*
 * Same as above, but:
 * 1) the deck is not shuffled, obviously.
 * 2) the dealer distributes only one card to each player.
 */
+give_cards(order(PLAYERS)) <-
	+order(PLAYERS);
	-give_cards(order(PLAYERS))[source(SENDER)];
	!distribute_cards;
	!notify_job_end(SENDER).

/* Plans */

+!start <- 
	!create_deck.

/*
 * This plan creates the deck, storing it in the belief base.
 */
+!create_deck: not deck(_) <- 
	.print("Hello, I'm the dealer of this game!");
	+deck([]);
	!add_cards.
	
+!add_cards: deck(_) <-
	!add_seed(1,10,denari);
	!add_seed(1,10,bastoni);
	!add_seed(1,10,spade);
	!add_seed(1,10,coppe).

/*
 * These plans add all the cards with the specified seed and values in range
 * [MIN, MAX] to the deck.
 */	
+!add_seed(MIN, MAX, SEED): MIN > MAX <-
	true.
	
+!add_seed(MIN, MAX, SEED): deck(CARDS) & MIN <= MAX <-
	-+deck([card(MIN, SEED)|CARDS]);
	!add_seed(MIN+1, MAX, SEED).

/*
 * These plans distribute cards to the players. The first one is used for the first turn,
 * where the dealer has to shuffle the deck and distribute three cards to each player.
 */
+!distribute_first_cards <- 
	!shuffle_deck;
	!distribute_cards_to_players(3);
	!place_briscola.

+!distribute_cards <-
	!distribute_cards_to_players(1).

/*
 * This plan retrieves the deck from the belief base, shuffles it and adds it back to
 * the belief base. 
 */
+!shuffle_deck: deck(CARDS) <-
	.print("I'm shuffling the deck...");
	.wait(1000);
	.shuffle(CARDS, SHUFFLED_CARDS);
	-+deck(SHUFFLED_CARDS).

/*
 * These plans are used to distribute one or more card to each player, through the "send"
 * internal action.
 */
+!distribute_cards_to_players(CARDS_NUMBER): deck([]) <-
	.print("The deck is empty, my job for this hand is done.").

+!distribute_cards_to_players(CARDS_NUMBER): order(PLAYERS) & deck(CARDS) & .length(CARDS, DECK_COUNT) & 
											 .length(PLAYERS, PL_COUNT) & DECK_COUNT >= CARDS_NUMBER * PL_COUNT <-
	.print("I'm distributing the cards to the players...");
	.wait(1000);
	for ( .member(PLAYER, PLAYERS) ) {
		!distribute_cards_to_player(PLAYER, CARDS_NUMBER);
	};
	.print("Card distributed, my job for this hand is done.");
	-order(PLAYER).

+!distribute_cards_to_player(PLAYER, CARDS_NUMBER): CARDS_NUMBER < 1.

+!distribute_cards_to_player(PLAYER, CARDS_NUMBER): CARDS_NUMBER >= 1 & deck([CARD|TAIL]) <-
	.send(PLAYER, tell, CARD);
	-+deck(TAIL);
	!distribute_cards_to_player(PLAYER, CARDS_NUMBER-1).

/*
 * This plan is executed upon game start for placing the briscola card on the table, so that
 * everyone can see it.
 */
+!place_briscola: deck([card(VALUE, SEED)|TAIL]) <-
	.print("I'm placing the briscola on the table. It's the ", VALUE, " of ", SEED, ".");
	t4jn.api.out("default", "127.0.0.1", "20504", briscola(card(VALUE, SEED)), OUT_BRISCOLA);
	.concat(TAIL, [card(VALUE, SEED)], DECK);
	-+deck(DECK).

/*
 * Plan used to notify the referee when the card distribution is done.
 */
+!notify_job_end(RECEIVER) <-
	.send(RECEIVER, tell, card_distribution_done).
	