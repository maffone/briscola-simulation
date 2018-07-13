// Agent sample_agent in project briscolaSimulation

/* Initial beliefs and rules */

/* Initial goals */

!boot.

/* Plans */
				  
+!boot <- 
	.print("Setting up tuple centre...");
	t4jn.api.out("default", "127.0.0.1", "20504", last_hand([]), OUT_LH); 
	!first.

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
	
	
	
	
	
	
	
	
	