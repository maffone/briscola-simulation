// Agent referee in project briscolaSimulation

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

/* This behavior is triggered when a message is received from a player, indicating the will of the player
 * to play the game. The message is deleted and the plan add_player is executed.
 */
+wanna_play(from(PLAYER)) : true <-
    -wanna_play(from(NAME))[source(SENDER)];
    !add_player(player(NAME, SENDER)).
    
/* This behavior is triggered when a message is received from the dealer, indicating that the dealer finished
 * the card distribution. The message is deleted and the hand is started.
 */
+card_distribution_done : true <-
    -card_distribution_done[source(dealer)];
    !start_hand;
    !play_hand.
    
/* This behavior is triggered when the list of init players is edited, and it contains four elements. 
 * A team is assigned to every player, the player with the team is inserted in the list of players, and a message
 * is sent to the player, indicating the team assigned to them.
 */
+init_players(LIST) : .length(LIST, LEN) & LEN == 4 <- 
    for ( .member(player(NAME, ADDRESS), LIST)) {
        ?teams([H|T]);
        ?players(PL);
        -+players([player(NAME, H, ADDRESS)|PL]);
        .send(NAME, tell, team_name(H));
        -+teams(T);    
    }.

/* This behavior is triggered when the list of players is edited, and it contains four elements. 
 * This means that we have four players in the game, and every player has a team assigned to them.
 * The game can begin.
 */
+players(LIST) : .length(LIST, LEN) & LEN == 4 <- 
    !start_game.
    

/* Plans */

/* The start plan only prints an hello message. The referee now waits for messages sent by players, in
 * order to join the game. 
 */
+!start: true <- .print("Hello, I'm the referee!").

/* A player wants to join the game, but there are already 4 players. A message is displayed. */
+!add_player(player(NAME, ADDRESS)) : players(LIST) & .length(LIST, LEN) & LEN >= 4 <-
    .print("A new player wants to join the game, but there are already 4 players.").

/* A player wants to join the game, and the number of players is lower than 4. The new player is added
 * to the init_players list.
 */
+!add_player(player(NAME, ADDRESS)) : init_players(LIST) & .length(LIST, LEN) & LEN < 4 <-
    .print("A new player wants to join the game!");
    -+init_players([player(NAME, ADDRESS) | LIST]).
    
/* This plans starts the game. First the first player is chosen randomly, then the dealer is contacted, 
 * sending him a message to tell him that he can start the card distribution for the first turn.
 * After that the referee read the tuple space, waiting for the briscola placement. 
 */
+!start_game : players(LIST) & .length(LIST, LEN) & LEN == 4 <- 
    .print("starting the game, contact the dealer and ask him to setup the deck...");
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
+!start_hand : true <- 
	?turns(N);
    .print("start a new hand, turn ", N);
    -+cards_played([]).
    
/* If a hand has to be played, but every player have already played in this hand trigger the end_turn plan. */
+!play_hand : turn_order([]) <- 
    !end_turn.
    
/* Play a hand. First send a message to the player that have to play, indicating if he/she can speak. After
 * that read on the tuple space the card played by the player, and save it in the agent knowledge base. 
 * Remove the player in the list of the turn order, and play a new hand.
 */
+!play_hand : turn_order([P_NAME|TAIL]) <-
    .print("player ", P_NAME, " has to play");
    if (turn_order(L) & .length(L, LEN) & LEN > 2) {
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
 * has won tis turn is set as the first player for the next turn. The turn number is increased, and the
 * plan new_turn is triggered.  
 */
+!end_turn : cards_played(L) & .length(L, LEN) & LEN == 4 <- 
    .print("turn ended, now calculate points");
    !calculate_winner(WINNER);
    .print("the winner of this hand is ", WINNER);
    !calculate_points(POINTS);
    .print("the winner scores ", POINTS, " points");
    !assign_points(WINNER, POINTS);
    !set_new_first_player(WINNER);
    ?turns(N);
    -+turns(N+1);
    for (team_points(T,P)) {
        .print("team ", T, "  points: ", P);
    }
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
    .print("the winning team of this hand is ", TEAM, " team");
    -team_points(TEAM, P);
    +team_points(TEAM, P+POINTS).
    
/* Set the winner of the last hand as the new first player of the next hand. This plan gets the index
 * of the winner player in the list of player, and use the plan reorder_players to reorder the turn order
 * accordingly to the new first player.
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
    
+!new_turn : turns(N) & N > 10 <- 
    .print("game ended :(");
    !end_game.
+!new_turn : turns(N) & N <= 10 <-
    .print("[referee] - begin a new turn, contact the dealer...");
    !setup_table;
    .wait(2000); // wait 2 seconds before the new hand.
    ?dealer_addr(DEALER);
    ?turn_order(TO);
    .send(DEALER, tell, give_cards(order(TO))).
    
+!end_game : true <- 
    ?team_points(blue, BLUE_POINTS);
    ?team_points(red, RED_POINTS);
    .print("The red team scored ", RED_POINTS);
    .print("The blue team scored ", BLUE_POINTS);
    if (BLUE_POINTS > RED_POINTS) {
        .print("BLUE TEAM WON!");
    } 
    else {
        if (RED_POINTS > BLUE_POINTS) {
            .print("RED TEAM WON!");
        } 
        else {
            .print("DRAW!");
        }
    }.
    
+!random_first_player : players(LIST) & .length(LIST, LEN) & LEN == 4 <- 
    .print("select the first player randomly");
    .shuffle([0,1,2,3], [H|T]);
    !reorder_players(H).
    
+!reorder_players(FIRST_INDEX) : turn_order(TU) & .length(TU, LEN) & LEN == 4 <- 
    .reverse(TU, UT);
    -+turn_order(UT).
+!reorder_players(FIRST_INDEX) : turn_order(TU) & .length(TU, LEN) & LEN < 4 <- 
    ?players(LIST);
    .nth(FIRST_INDEX, LIST, player(NAME,_,_));
    -+turn_order([NAME|TU]);
    !reorder_players((FIRST_INDEX+1) mod 4).
    
+!setup_table <-
	t4jn.api.inAll("default", "127.0.0.1", "20504", card_played(_, _, _, _), IN_CARDS);
	t4jn.api.inAll("default", "127.0.0.1", "20504", conversation(_,_,_,_,_,_), IN_CONV);
	?cards_played(LIST);
    t4jn.api.out("default", "127.0.0.1", "20504", last_hand(LIST), OUT_LH).
    
    