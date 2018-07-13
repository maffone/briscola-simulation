// Agent sample_agent in project briscolaSimulation

/* Initial beliefs and rules */

/* Initial goals */

!boot.

/* Plans */
				  
+!boot <- 
	.print("Setting up tuple centre...");
	!first.

+!clean <- 
	.print("Cleaning...");
	t4jn.api.inAll("default", "127.0.0.1", "20504", briscola(_), ALL_OP);
	t4jn.api.inAll("deafult", "127.0.0.1", "20504", card_played(_, _, _), ALL2_OP);
	t4jn.api.inAll("default", "127.0.0.1", "20504", conversation(_, _, _, _, _), ALL3_OP);
	.print("Cleaned");
	!first.

+!first <-
	t4jn.api.outS(
		"default", 
		"127.0.0.1", 
		"20504", 
		out(answer_companion(team(T),from(AP),A)), 
		completion, 
		reactions(
			in(ask_companion(team(T),from(QP),ask(QR,QS))), 
			in(answer_companion(team(T),from(AP),A)),
			out(conversation(team(T),from(QP),to(AP),ask(QR, QS),answer(A)))
		), 
		OUT_S
	);
	!second.
	
-!first : true <-
	!second.
	
+!second : true <-
	.print("Done booting").