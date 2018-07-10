// Agent sample_agent in project briscolaSimulation

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Plans */

+!start : true <- .print("hello world1.");
				  .print("sending tuple to tuple centre.");
				  t4jn.api.out("default", "127.0.0.1", "20504", test(dio), Out0).
