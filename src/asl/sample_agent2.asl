!start.

/* Plans */

+!start : true <- .print("hello world2.");
				  !getTuple.
				  
				  
+!getTuple <- t4jn.api.in("default", "127.0.0.1", "20504", hello(world), In0);
	          t4jn.api.getResult(In0, Res0);
			  t4jn.api.getArg(Res0, 0, Arg0);
			  .print(Arg0).