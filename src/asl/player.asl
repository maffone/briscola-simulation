// Agent player in project briscolaSimulation

/* Initial beliefs and rules */

/* Initial goals */

!start.

/* Plans */

+!start: true <- .my_name(Me);
				 .print("Hello, I'm ", Me, "!").