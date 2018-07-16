// Agent referee in project briscolaSimulation

/*
 * This agent is the referee of the match, and it acts as a coordinator for the entire match. Its main 
 * task are:
 * - Take track of the turn order, and ascertain that the players play in this order.
 * - Contact the dealer, telling him to distribute the cards to the players.
 * - Calculate the points and the winner player of every hand.
 * - Take track of the points scored by the two teams.
 * - Take track of the turns in the game, and proclaim the winner team at the end of the game. 
 */


/* Initial beliefs and rules */

/* The (initial empty) list of players of this match. */
players([]).

/* A list used for storing the players before a team is assigned to them. */
init_players([]).

/* The list of the team. The two teams are interleaved, because a player has to play always before and after 
 * a player of the opposite team.
 */
teams([red, blue, red, blue]).

/* The adress of the dealer */
dealer_addr(dealer).

/* The turn order. Initially empty, every turn it will contain the order of the turn. */
turn_order([]).

/* The cards played in an hand. */
cards_played([]).

/* The points scored by the blue team. */
team_points(blue, 0).

/* The points scored by the red teams  */
team_points(red, 0).

/* An utility list, which contains the value of the cards, ordered by value. */
card_values([value(2,0), value(4,0), value(5,0), value(6,0), value(7,0), value(8,2), value(9,3), value(10,4), value(3,10), value(1,11)]).

/* Initial goals */

!start.

/* Beliefs addition */

/* This plan is triggered when a message is received from a player, indicating the will of the player
 * to play the game. The message is deleted and the plan add_player is executed.
 */
+wanna_play(from(PLAYER)) <-
    -wanna_play(from(NAME))[source(SENDER)];
    !add_player(player(NAME, SENDER)).
    
/* This plan is triggered when a message is received from the dealer, indicating that the dealer finished
 * the card distribution. The message is deleted and the hand is started.
 */
+card_distribution_done <-
    -card_distribution_done[source(dealer)];
    !start_hand;
    !play_hand.
    
/* This plan is triggered when the list of init players is edited, and it contains four elements. 
 * A team is assigned to every player, the player with the team is inserted in the list of players, and a message
 * is sent to the player, indicating the team assigned to them.
 */
+init_players(LIST) : .length(LIST, LEN) & LEN == 4 <- 
    for ( .member(player(NAME, ADDRESS), LIST)) {
        ?teams([H|T]);
        ?players(PL);
        -+players([player(NAME, H, ADDRESS)|PL]);
        .print("I'm making the teams: ", NAME, " is in the ", H, " team.");
        .send(NAME, tell, team_name(H));
        -+teams(T);    
    }.

/* This plan is triggered when the list of players is edited, and it contains four elements. 
 * This means that we have four players in the game, and every player has a team assigned to them.
 * The game can begin.
 */
+players(LIST) : .length(LIST, LEN) & LEN == 4 <- 
    !start_game.
    

/* Plans */

/* The start plan only prints an hello message. The referee now waits for messages sent by players, in
 * order to join the game. 
 */
+!start <- 
    .print("Hello, I'm the referee!").

/* A player wants to join the game, but there are already 4 players. A message is displayed. */
+!add_player(player(NAME, ADDRESS)) : players(LIST) & .length(LIST, LEN) & LEN >= 4 <-
    .print("A new player wants to join the game, but there are already 4 players.").

/* A player wants to join the game, and the number of players is lower than 4. The new player is added
 * to the init_players list.
 */
+!add_player(player(NAME, ADDRESS)) : init_players(LIST) & .length(LIST, LEN) & LEN < 4 <-
    .print("A new player wants to join the game, welcome ", NAME, "!");
    -+init_players([player(NAME, ADDRESS) | LIST]).
    
/* This plans starts the game. First the first player is chosen randomly, then the dealer is contacted, 
 * sending him a message to tell him that he can start the card distribution for the first turn.
 * After that the referee read the tuple space, waiting for the briscola placement. 
 */
+!start_game : players(LIST) & .length(LIST, LEN) & LEN == 4 <- 
    .print("Let's start the game! The dealer has to shuffle the deck and distribute the cards...");
    .wait(1000);
    !random_first_player
    ?dealer_addr(DEALER_ADDR);
    ?turn_order(TO);
    +turns(1);
    .send(DEALER_ADDR, tell, setup_deck(order(TO)));
    t4jn.api.rd("default", "127.0.0.1", "20504", briscola(CARD), OUT_CARD);
    t4jn.api.getResult(OUT_CARD, BR);
    +BR.
    
/* Starts a new hand. Prints in the console the turn number, and the list containing the cards played is the
 * earlier turn is emptied.  
 */
+!start_hand <- 
    -+cards_played([]).
    
/* If a hand has to be played, but every player have already played in this hand trigger the end_turn goal. */
+!play_hand : turn_order([]) <- 
    !end_turn.
    
/* Play a hand. First send a message to the player that have to play, indicating if he/she can speak. After
 * that read on the tuple space the card played by the player, and save it in the agent knowledge base. 
 * Remove the player in the list of the turn order, and play a new hand.
 */
+!play_hand : turn_order([P_NAME|TAIL]) <-
    .print("Player ", P_NAME, ", it's your turn to play.");
    if (turns(N) & N > 1 & turn_order(L) & .length(L, LEN) & LEN > 2) {
        .send(P_NAME, tell, your_turn(can_speak(true)));
    } 
    else {
        .send(P_NAME, tell, your_turn(can_speak(false)));
    }
    t4jn.api.rd("default", "127.0.0.1", "20504", card_played(_, from(P_NAME), _, _), OUT_CARD);
    t4jn.api.getResult(OUT_CARD, RESULT);
    ?cards_played(LIST);
    -+cards_played([RESULT|LIST]);
    -+turn_order(TAIL);
    !play_hand.
    
/* Plan that manages the turn ending. Firstly the winner of this turn is calculated. Secondly the points scored
 * in this hand are computed. Thirdly the points are assigned to the winner team. Lastly the player that 
 * has won this turn is set as the first player for the next turn. The turn number is increased, and the
 * goal new_turn is triggered.  
 */
+!end_turn : cards_played(L) & .length(L, LEN) & LEN == 4 <- 
    .print("This hand is over, I'm now calculating the points...");
    !calculate_winner(WINNER);
    !calculate_points(POINTS);
    .print("The winner of this hand is ", WINNER, " with ", POINTS, " points!");
    !assign_points(WINNER, POINTS);
    !set_new_first_player(WINNER);
    ?turns(N);
    -+turns(N+1);
    /*for (team_points(T,P)) {
        .print("team ", T, "  points: ", P);
    }*/
    !new_turn.

/* Calculate the winner of an hand. Firstly the list that contains the cards played in this hand is reversed,
 * in order to have the first card played in the first position, the second card played in second position etc...
 * The first card played is extracted, and it is set as winner card (and the player that has played it as winner
 * player). For every card in the list is checked if the card is superior to the winner card. If yes, the card
 * is set as the winner card. This process is repeated for every card played in this hand (in order). 
 * A a result the winner is returned.
 */
+!calculate_winner(WINNER) : cards_played(CP) & .length(CP, LEN) & LEN == 4 <-
    .reverse(CP, PC); 
    +card_turn(PC);
    ?card_turn([card_played(card(VALUE, SEED), from(P_NAME), _, _)|T]);
    +winner(P_NAME);
    +winner_card(card(VALUE, SEED));
    -+card_turn(T);
    for ( .member(card_played(A, B, _, _), T)) {
        !check_superior_card(card_played(A, B, _));
    }
    ?winner(WINNER);
    -winner_card(_);
    -winner(_);
    -card_turn(_).
    
/* Calculate the points scored in the current hand. For every card played is derived the corresponding value, 
 * and it is added to the points scored in this hand. The amount is returned.
 */
+!calculate_points(POINTS) : cards_played(CP) & .length(CP, LEN) & LEN == 4 <- 
    ?card_values(CV);
    +turn_points(0);
    for ( .member(card_played(card(VALUE,_), _, _ , _), CP)) {
        .member(value(VALUE, X), CV);
        ?turn_points(P);
        -+turn_points(P+X);
    }
    ?turn_points(POINTS);
    -turn_points(_).
    
/* Assign the points scored in this hand to the winner player team. The points scored in this hand are summed
 * to the points scored by the team in previous hands. 
 */
+!assign_points(WINNER, POINTS) : players(PLAYERS) <- 
    .member(player(WINNER, TEAM, _), PLAYERS);
    .print("The winning team of this hand is the ", TEAM, " team.");
    -team_points(TEAM, P);
    +team_points(TEAM, P+POINTS).
    
/* Set the winner of the last hand as the new first player of the next hand. This plan gets the index
 * of the winner player in the list of player, and use the plan reorder_players to reorder the turn order
 * according to the new first player.
 */
+!set_new_first_player(WINNER) : players(PLAYERS) <- 
    -+turn_order([])
    .nth(X, PLAYERS, player(WINNER,_,_));
    !reorder_players(X).
    
/* Checks if the card passed as an argument is superior to the current winner card of the current hand. 
 * The card is superior to the current winner card if the two card have the same seed, but the card
 * passed as argument has a greater value. 
 * If the two cards have different seeds the card given is superior only if its seed is briscola.
 * If the card given is superior to the current winner card, the winner card (and the winner player) are 
 * updated.
 */
+!check_superior_card(card_played(card(VALUE, SEED), from(P_NAME), _)) : winner(WIN) & winner_card(card(WIN_VALUE, WIN_SEED)) <-
    ?card_values(VL);
    .nth(CV, VL, value(VALUE, _));
    .nth(CWV, VL, value(WIN_VALUE, _));
    if (SEED == WIN_SEED & CV > CWV) {
        -+winner(P_NAME);
        -+winner_card(card(VALUE, SEED));
    } else {
        if (briscola(card(_, SEED))) {
            -+winner(P_NAME);
            -+winner_card(card(VALUE, SEED));
        }   
    }.
    
/* This plan is triggered when a new turn has to be started. If ten turn have already been played the 
 * end_game goal is triggered. 
 * If the new turn can be played, the table is set up (the cards played in the last hand are removed) and a
 * message is sent to the dealer, to ask him to start the card distribution for the new hand. 
 * After this plan the agent will wait for the response message by the dealer.
 */ 
+!new_turn : turns(N) & N > 10 <- 
    .print("The game is over! :(");
    !end_game.
+!new_turn : turns(N) & N <= 10 <-
    .print("It's turn ", N, ", let's start a new hand! The dealer has to distribute the cards...");
    !setup_table;
    .wait(2000); // wait 2 seconds before the new hand.
    ?dealer_addr(DEALER);
    ?turn_order(TO);
    .send(DEALER, tell, give_cards(order(TO))).
    
/* If the game is finished, a message is printed on the console, showing what team has won the game. 
 * After that a message is sent to every player, indicating the team that won the game.
 */
+!end_game <- 
    ?team_points(blue, BLUE_POINTS);
    ?team_points(red, RED_POINTS);
    .print("The final score of the red team is ", RED_POINTS, ".");
    .print("The final score of the blue team is ", BLUE_POINTS, ".");
    if (BLUE_POINTS > RED_POINTS) {
        .print("THE BLUE TEAM WON! Congratulations! :)");
        !tell_result_to_players(win(blue));
    } 
    else {
        if (RED_POINTS > BLUE_POINTS) {
            .print("THE RED TEAM WON! Congratulations! :)");
            !tell_result_to_players(win(red));
        } 
        else {
            .print("IT'S A DRAW! Congratulations to both teams! :)");
            !tell_result_to_players(draw);
        }
    }.
    
/* Sends a message to every player, indicating the team that won the game (or draw). */
+!tell_result_to_players(RESULT): players(PLAYERS) <-
	for (.member(player(PLAYER, _, _), PLAYERS)) {
		.send(PLAYER, tell, game_result(RESULT));
	}.
	
/* Select randomly the first player of the game, and reorder the turn order. */
+!random_first_player : players(LIST) & .length(LIST, LEN) & LEN == 4 <- 
    .shuffle([0,1,2,3], [H|T]);
    !reorder_players(H);
    ?turn_order([FIRST|PLAYERS]);
    .print("The player ", FIRST, " has been randomly chosen as the first player.").
    
/* Reorder the players according to the given first player. If the turn order is already composed 
 * length of the list = 4, then reverse it. If the turn order is not completed, add in the list the player
 * with the given index. 
 */ 
+!reorder_players(FIRST_INDEX) : turn_order(TU) & .length(TU, LEN) & LEN == 4 <- 
    .reverse(TU, UT);
    -+turn_order(UT).
+!reorder_players(FIRST_INDEX) : turn_order(TU) & .length(TU, LEN) & LEN < 4 <- 
    ?players(LIST);
    .nth(FIRST_INDEX, LIST, player(NAME,_,_));
    -+turn_order([NAME|TU]);
    !reorder_players((FIRST_INDEX+1) mod 4).
   
/* Setup the table of the game. Removes all the cards played in the last hand, and all the conversations.
 * Insert the last hand, that contains the cards played in the last hand.  
 */ 
+!setup_table <-
	t4jn.api.inAll("default", "127.0.0.1", "20504", card_played(_, _, _, _), IN_CARDS);
	t4jn.api.inAll("default", "127.0.0.1", "20504", conversation(_,_,_,_,_,_), IN_CONV);
	?cards_played(LIST);
    t4jn.api.out("default", "127.0.0.1", "20504", last_hand(LIST), OUT_LH).
    
    