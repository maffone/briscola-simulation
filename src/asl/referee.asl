// Agent referee in project briscolaSimulation

/* Initial beliefs and rules */

players([]).
init_players([]).
teams([red, blue, red, blue]).
dealer_addr(dealer).
turn_order([]).
cards_played([]).
team_points(blue, 0).
team_points(red, 0).
card_values([value(2,0), value(4,0), value(5,0), value(6,0), value(7,0), value(8,2), value(9,3), value(10,4), value(3,10), value(1,11)]).

/* Initial goals */

!start.

/* Beliefs addition */

+wanna_play(from(PLAYER)) : true <-
    -wanna_play(from(NAME))[source(SENDER)];
    !add_player(player(NAME, SENDER)).
    
+card_distribution_done : true <-
    -card_distribution_done[source(dealer)];
    !start_hand;
    !play_hand.
    
    
+init_players(LIST) : .length(LIST, LEN) & LEN == 4 <- 
    for ( .member(player(NAME, ADDRESS), LIST)) {
        ?teams([H|T]);
        ?players(PL);
        -+players([player(NAME, H, ADDRESS)|PL]);
        .print("I'm making the teams: ", NAME, " is in the ", H, " team.");
        .send(NAME, tell, team_name(H));
        -+teams(T);    
    }.
    
+players(LIST) : .length(LIST, LEN) & LEN == 4 <- 
    !start_game.
    

/* Plans */

+!start: true <- .print("Hello, I'm the referee!").

+!add_player(player(NAME, ADDRESS)) : players(LIST) & .length(LIST, LEN) & LEN >= 4 <-
    .print("A new player wants to join the game, but there are already 4 players.");
    true.

+!add_player(player(NAME, ADDRESS)) : init_players(LIST) & .length(LIST, LEN) & LEN < 4 <-
    .print("A new player wants to join the game, welcome ", NAME, "!");
    -+init_players([player(NAME, ADDRESS) | LIST]).
    
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
    
+!start_hand : true <- 
    -+cards_played([]).
    
+!play_hand : turn_order([]) <- 
    !end_turn.
    
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
    
+!assign_points(WINNER, POINTS) : players(PLAYERS) <- 
    .member(player(WINNER, TEAM, _), PLAYERS);
    .print("The winning team of this hand is the ", TEAM, " team.");
    -team_points(TEAM, P);
    +team_points(TEAM, P+POINTS).
    
+!set_new_first_player(WINNER) : players(PLAYERS) <- 
    -+turn_order([])
    .nth(X, PLAYERS, player(WINNER,_,_));
    !reorder_players(X).
    
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
    .print("The game is over! :(");
    !end_game.
+!new_turn : turns(N) & N <= 10 <-
    .print("It's turn ", N, ", let's start a new hand! The dealer has to distribute the cards...");
    !setup_table;
    .wait(2000); // wait 2 seconds before the new hand.
    ?dealer_addr(DEALER);
    ?turn_order(TO);
    .send(DEALER, tell, give_cards(order(TO))).
    
+!end_game : true <- 
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
    
+!tell_result_to_players(RESULT): players(PLAYERS) <-
	for (.member(player(PLAYER, _, _), PLAYERS)) {
		.send(PLAYER, tell, game_result(RESULT));
	}.
	
    
+!random_first_player : players(LIST) & .length(LIST, LEN) & LEN == 4 <- 
    .shuffle([0,1,2,3], [H|T]);
    !reorder_players(H);
    ?turn_order([FIRST|PLAYERS]);
    .print("The player ", FIRST, " has been randomly chosen as the first player.").
    
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
    
    