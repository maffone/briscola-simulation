// Agent sample_agent in project briscolaSimulation

/* Initial beliefs and rules */

/* Initial goals */

!boot.

/* Plans */
				  
+!boot : true <- 
	!first.

+!first : true <-
	t4jn.api.outS("default", "127.0.0.1", "20504", out(event(X)), completion, reactions(out(reaction(X)), out(reaction2(X))), OUT_S);
	!second.
	
-!first : true <-
	!second.
	
+!second : true <-
	.print("Done booting").