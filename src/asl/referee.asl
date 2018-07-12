// Agent referee in project briscolaSimulation

/* Initial beliefs and rules */

players([]).
teams(["red", "blue", "red", "blue"]).
dealer_addr("add").
turn_order([]).
cards_played([]).
team_points("blue", 0).
team_points("red", 0).
card_values([value(2,0), value(4,0), value(5,0), value(6,0), value(7,0), value(8,2), value(9,3), value(10,4), value(3,10), value(1,11)]).

/* Initial goals */

!start.

/* Beliefs addition */

+wanna_play(player(NAME)) : true <-
    -wanna_play(player(NAME))[source(SENDER)];
    !add_player(player(NAME, SENDER)).
    
+card_distribution_done : true <- 
    !start_hand;
    !play_hand.
    

/* Plans */

+!start: true <- .print("Hello, I'm the referee!").

+!add_player(player(NAME, ADDRESS)) : players(LIST) & .length(LIST) >= 4 <-
    .print("A new player wants to join the game, but there are already 4 players.");
    true.

+!add_player(player(NAME, ADDRESS)) : players(LIST) & .length(LIST) < 4 & teams([TEAM|TAIL])<-
    .print("A new player wants to join the game!");
    -+players([player(NAME, TEAM, ADDRESS) | LIST]);
    .send(ADDRESS, tell, team_name(TEAM));
    -+teams(TAIL);
    if (players(N_LIST) & .length(N_LIST) == 4) {
        !start_game;
    }
    true.
    
+!start_game : players(LIST) & .length(LIST) == 4 <- 
    .print("starting the game, contact the dealer and ask him to setup the deck");
    !random_first_player
    ?dealer_addr(DEALER_ADDR);
    .send(DEALER_ADDR, tell, setup_deck(order(_)));
    t4jn.api.rd("default", "127.0.0.1", "20504", briscola(CARD), OUT_CARD);
    t4jn.api.getResult(OUT_CARD, BR);
    t4jn.api.getArg(BR, 1, BR_CARD);
    +briscola(BR);
    +turns(1).
    
+!start_hand : true <- 
    -+cards_played([]).
    
+!play_hand : turn_order(TO) & .length(TO) == 0 <- 
    !end_turn.
    
+!play_hand : turn_order([player(P_NAME, P_ADDR)|TAIL]) <-
    if (turn_order(L) & .length(L) > 2) {
        .send(P_ADDR, tell, your_turn(true));
    } 
    else {
        .send(P_ADDR, tell, your_turn(false));
    }
    t4jn.api.rd("default", "127.0.0.1", "20504", card_played(_, from(P_NAME), _), OUT_CARD);
    t4jn.api.getResult(OUT_CARD, RESULT);
    ?cards_played(LIST);
    -+cards_played([RESULT|LIST])
    -+turn_order(TAIL);
    !play_hand.
    
+!end_turn : cards_played(L) & .length(L) == 4 <- 
    !calculate_winner(WINNER);
    !calculate_points(POINTS);
    !assign_points(WINNER, POINTS);
    !set_new_first_player(WINNER);
    ?turn(N);
    -+turn(N+1);
    !new_turn.
    
+!calculate_winner(WINNER) : cards_played(CP) & .length(CP) == 4 <-
    .reverse(CP, PC); 
    +card_turn(PC);
    ?card_turn([card_played(card(VALUE, SEED), from(P_NAME), _)|T]);
    +winner(P_NAME);
    +winner_card(card(VALUE, SEED));
    -+card_turn(T);
    for ( .member(card_played(_, _, _), CP)) {
        !check_superior_card(card_played(_, _, _));
    }
    ?winner(WINNER);
    -winner_card(_);
    -winner(_);
    -card_turn(_).
    
+!calculate_points(POINTS) : cards_played(CP) & .length(CP) == 4 <- 
    ?card_values(CV);
    +turn_points(0);
    for ( .member(card_played(card(VALUE,_), _, _), CP)) {
        .member(value(VALUE, X), CV);
        ?turn_points(P);
        -+turn_points(P+X);
    }
    ?turn_points(POINTS);
    -turn_points(_).
    
+!assign_points(WINNER, POINTS) : players(PLAYERS) <- 
    .member(player(WINNER, TEAM, _), PLAYERS);
    ?team_points(TEAM, P);
    -+team_points(TEAM, P+POINTS).
    
+!set_new_first_player(WINNER) : players(PLAYERS) <- 
    -+turn_order([])
    .nth(X, PLAYERS, player(WINNER,_,_));
    !reorder_players(X).
    
+!check_superior_card(card_played(card(VALUE, SEED), from(P_NAME), _)) : winner(WIN) & winner_card(card(WIN_VALUE, WIN_SEED)) <-
    ?card_values(VL);
    .nth(CV, VL, value(VALUE, _));
    .nth(CWV, LV, value(WIN_VALUE, _));
    if (SEED == WIN_SEED & CV > CWV) {
        -+winner(P_NAME);
        -+winner_card(card(VALUE, SEED));
    }
    else {
        ?briscola(B_SEED)
        if (SEED == B_SEED) {
            -+winner(P_NAME);
            -+winner_card(card(VALUE, SEED));
        }   
    }
    true.
    
+!new_turn : turn(N) & N > 10 <- 
    !end_game.
+!new_turn : turn(N) & N <= 10 <-
    ?dealer_addr(DEALER);
    ?turn_order(TO);
    .send(DEALER, tell, give_cards(order(TO))).
    
+!end_game : true <- 
    .print("game ended!");
    ?team_points("blue", BLUE_POINTS);
    ?team_points("red", RED_POINTS);
    print("The red team scored ", RED_POINTS);
    print("The blue team scored ", BLUE_POINTS);
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
    }
    true.
    
+!random_first_player : players(LIST) & .length(LIST) == 4 <- 
    .shuffle([0,1,2,3], [H|T]);
    !reorder_players(H).
    
+!reorder_players(FIRST_INDEX) : turn_order(TU) & .length(TU) == 4 <- 
    .reverse(TU, UT);
    -+turn_order(UT);
    true. 
+!reorder_players(FIRST_INDEX) : turn_order(TU) & -length(TU) < 4 <-
    ?players(LIST);
    .nth(FIRST_INDEX, LIST, P);
    -+turn_order([P|TU]);
    !reorder_players((FIRST_INDEX+1) mod 4).
    
    