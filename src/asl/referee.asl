// Agent referee in project briscolaSimulation

/* Initial beliefs and rules */

players([]).
teams(["red", "blue", "red", "blue"]).
dealer_addr("add").
turn_order([]).

/* Initial goals */

!start.

/* Beliefs addition */

+wanna_play(player(NAME)) : true <-
    -wanna_play(player(NAME))[source(SENDER)];
    !add_player(player(NAME, SENDER)).
    

/* Plans */

+!start: true <- .print("Hello, I'm the referee!").

+!add_player(player(NAME, ADDRESS)) : players(LIST) & .length(LIST) >= 4 <-
    .print("A new player wants to join the game, but there are already 4 players.");
    true.

+!add_player(player(NAME, ADDRESS)) : players(LIST) & .length(LIST) < 4 & teams([TEAM|TAIL])<-
    .print("A new player wants to join the game!");
    -+players([player(NAME, TEAM, ADDRESS) | LIST]);
    .send(ADDRESS, tell, team(TEAM));
    -+teams(TAIL);
    if (players(N_LIST) & .length(N_LIST) == 4) {
        !start_game;
    }
    true.
    
+!start_game : players(LIST) & .length(LIST) == 4 <- 
    .print("starting the game, contact the dealer and ask him to setup the deck");
    
    -+players(S_LIST);
    ?dealer_addr(DEALER_ADDR);
    .send(DEALER_ADDR, tell, setup_deck(order(S_LIST))).
    
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
    
    