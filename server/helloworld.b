# this file implements the module interface "Helloworld"
implement Helloworld;


# include the files sys.m & draw.m (from /module)
include "sys.m";
include "draw.m";


# "Helloworld" is a module, it has the function ("fn") "init" with two parameters.
# both parameters are unnamed ("nil") because they are not used.
Helloworld: module {
	init:	fn(nil: ref Draw->Context, nil: list of string);
};


# implementation of the function "init", as described in the
# module interface "Helloworld" above.  "init" in limbo is like "main" in C.
init(nil: ref Draw->Context, nil: list of string)
{
	# declare "sys" by assigning it the result of loading the Sys module.
	sys := load Sys Sys->PATH;

	# call function "print" from the loaded module "sys"
	sys->print("hello world!\n");
}