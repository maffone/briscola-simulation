/*
 * Agent boot_agent in project briscolaSimulation, meant to setup the tuple centre. For this purpose,
 * we enhanced the t4jn.jar in order to be able to perform specification operations on the
 * target tuple centre. More specifically, we added the support for the out_s specification
 * primitive. However, we didn't manage to understand why plans fail every time
 * after calling this primitive, even if the primitive itself succeeds. To solve this problem,
 * we used goal-deletion events as a workaround. 
 */

/* Initial beliefs and rules */

/* Initial goals */

!boot.

/* Plans */
				  
/*
 * This plan initializes the tuple "last_hand", meant to contain the last played hand by
 * the players.
 */
+!boot <- 
	.print("Setting up tuple centre...");
	t4jn.api.out("default", "127.0.0.1", "20504", last_hand([]), OUT_LH); 
	!first.

/*
 * In this plan we use this primitive to add the following reaction to the tuple centre:
 * whenever a player answers to its companion's question through the predicate
 * "answer_compagnion(TEAM, FROM, RESPONSE, SEQUENCE)"
 * the tuple centre merges the "ask_companion" and "answer_companion" predicates into a single
 * predicate:
 * "conversation(TEAM, FROM, TO, QUESTION, ANSWER, SEQUENCE)".
 */
+!first <-
	t4jn.api.outS(
		"default", 
		"127.0.0.1", 
		"20504", 
		out(answer_companion(team(T),from(AP),A,seq(SN))), 
		completion, 
		reactions(
			in(ask_companion(team(T),from(QP),ask(QR,QS),seq(SN))), 
			in(answer_companion(team(T),from(AP),A,seq(SN))),
			out(conversation(team(T),from(QP),to(AP),ask(QR, QS),answer(A),seq(SN)))
		), 
		OUT_S
	);
	!second.
	
-!first : true <-
	!second.

/*
 * In this plan we use this primitive to add the following reaction to the tuple centre:
 * whenever the referee wishes to updates the "last_hand" predicate at the end of a 
 * turn, the tuple centre removes the now old one before serving the out primitive (invocation).
 */
+!second : true <-
	t4jn.api.outS(
		"default", 
		"127.0.0.1", 
		"20504", 
		out(last_hand(_)), 
		invocation, 
		reactions(
			in(last_hand(_))
		), 
		OUT_S
	);
	!finish.
	
-!second <- 
	!finish.
	
+!finish <-
	.print("Done booting").
	
	
	
	
	
	
	
	
	