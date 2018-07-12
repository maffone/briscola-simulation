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
    -card_distribution_done;
    !start_hand;
    !play_hand.
    
    
+init_players(LIST) : .length(LIST, LEN) & LEN == 4 <- 
    for ( .member(player(NAME, ADDRESS), LIST)) {
        ?teams([H|T]);
        ?players(PL);
        -+players([player(NAME, H, ADDRESS)|PL]);
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
    .print("A new player wants to join the game!");
    -+init_players([player(NAME, ADDRESS) | LIST]).
    
+!start_game : players(LIST) & .length(LIST, LEN) & LEN == 4 <- 
    .print("starting the game, contact the dealer and ask him to setup the deck...");
    .wait(1000);
    !random_first_player
    ?dealer_addr(DEALER_ADDR);
    ?turn_order(TO);
    .send(DEALER_ADDR, tell, setup_deck(order(TO)));
    t4jn.api.rd("default", "127.0.0.1", "20504", briscola(CARD), OUT_CARD);
    t4jn.api.getResult(OUT_CARD, BR);
    +BR;
    +turns(1).
    
+!start_hand : true <- 
    .print("[referee] - start a new hand");
    -+cards_played([]).
    
+!play_hand : turn_order([]) <- 
    !end_turn.
    
+!play_hand : turn_order([P_NAME|TAIL]) <-
    .print("[referee] - player ", P_NAME, " have to play");
    if (turn_order(L) & .length(L, LEN) & LEN > 2) {
        .send(P_NAME, tell, your_turn(can_speak(true)));
    } 
    else {
        .send(P_NAME, tell, your_turn(can_speak(false)));
    }
    t4jn.api.rd("default", "127.0.0.1", "20504", card_played(_, from(P_NAME), _), OUT_CARD);
    t4jn.api.getResult(OUT_CARD, RESULT);
    ?cards_played(LIST);
    -+cards_played([RESULT|LIST]);
    -+turn_order(TAIL);
    !play_hand.
    
+!end_turn : cards_played(L) & .length(L, LEN) & LEN == 4 <- 
    .print("[referee] - turn ended, now calculate points");
    !calculate_winner(WINNER);
    .print("[referee] - the winner of this hand is ", WINNER);
    !calculate_points(POINTS);
    .print("[referee] - the winner scores ", POINTS, " points");
    !assign_points(WINNER, POINTS);
    !set_new_first_player(WINNER);
    ?turns(N);
    -+turns(N+1);
    !new_turn.
    
+!calculate_winner(WINNER) : cards_played(CP) & .length(CP, LEN) & LEN == 4 <-
    .reverse(CP, PC); 
    +card_turn(PC);
    ?card_turn([card_played(card(VALUE, SEED), from(P_NAME), _)|T]);
    +winner(P_NAME);
    +winner_card(card(VALUE, SEED));
    -+card_turn(T);
    for ( .member(card_played(A, B, _), T)) {
        !check_superior_card(card_played(A, B, _));
    }
    ?winner(WINNER);
    -winner_card(_);
    -winner(_);
    -card_turn(_).
    
+!calculate_points(POINTS) : cards_played(CP) & .length(CP, LEN) & LEN == 4 <- 
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
    .print("[referee] - the winning team of this hand is ", TEAM, " team");
    -+team_points(TEAM, P+POINTS).
    
+!set_new_first_player(WINNER) : players(PLAYERS) <- 
    -+turn_order([])
    .nth(X, PLAYERS, player(WINNER,_,_));
    !reorder_players(X).
    
+!check_superior_card(card_played(card(VALUE, SEED), from(P_NAME), _)) : winner(WIN) & winner_card(card(WIN_VALUE, WIN_SEED)) <-
    ?card_values(VL);
    .nth(CV, VL, value(VALUE, _));
    .nth(CWV, VL, value(WIN_VALUE, _));
    .print(card(VALUE, SEED), "   player ", P_NAME);
    if (SEED == WIN_SEED & CV > CWV) {
        -+winner(P_NAME);
        -+winner_card(card(VALUE, SEED));
    } else {
        .print("[referee] - im in the else, fucckkk");
        ?briscola(card(_, B_SEED));
        .print("seed ", SEED, ",  briscola seed ", B_SEED);
        if (briscola(card(_, SEED))) {
            .print("[referee] - this is briscola");
            -+winner(P_NAME);
            -+winner_card(card(VALUE, SEED));
        }   
    }.
    
+!new_turn : turns(N) & N > 10 <- 
    .print("[referee] - game ended :(");
    !end_game.
+!new_turn : turns(N) & N <= 10 <-
    .print("[referee] - begin a new turn, contact the dealer...");
    .wait(5000);
    ?dealer_addr(DEALER);
    ?turn_order(TO);
    .print(TO);
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
    
+!random_first_player : players(LIST) & .length(LIST, LEN) & LEN == 4 <- 
    .print("[referee] - select the first player randomly");
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
    
    
    