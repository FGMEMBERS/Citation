togglereverser = func {
r1 = "/controls/engines/engine"; 
r2 = "/controls/engines/engine[1]"; 
rv1 = "/engines/engine/reverser-position"; 
rv2 = "/engines/engine[1]/reverser-position"; 

val = getprop(rv1);
if (val == 0 or val == nil) {
interpolate(rv1, 1.0, 1.4);  
interpolate(rv2, 1.0, 1.4);  
setprop(r1,"reverser","true");
setprop(r2,"reverser", "true");
} else {
if (val == 1.0){
interpolate(rv1, 0.0, 1.4);  
interpolate(rv2, 0.0, 1.4);  
setprop(r1,"reverser",0);
setprop(r2,"reverser",0);
  }
 }
}

