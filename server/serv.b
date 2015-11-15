implement SimpleHTTPD;

include "sys.m";
include "draw.m";

sys : Sys;
Connection : import Sys;

mutex2Writing : chan of int;
mutex2ListAccess : chan of int;

files : list of string;

SimpleHTTPD: module {
	init:	fn(nil: ref Draw->Context, nil: list of string);
};

init(nil: ref Draw->Context, nil: list of string) {

	sys = load Sys Sys->PATH;
	
	mutex2Writing = chan[1] of int;
	mutex2Writing <- = int 1;
	
	mutex2ListAccess = chan[1] of int;
	mutex2ListAccess <- = int 1;
	
	(n, conn) := sys->announce("tcp!*!8034");
	if (n < 0) {
		sys->print("SimpleHTTPD announce failed : %r\n");
		exit;
	}
	
	sys->print("OK\n");
	
	while (1) {
		listen(conn);
	}
}

listen(conn : Connection) {

	buf := array [sys->ATOMICIO] of byte;
	
	(ok, c) := sys->listen(conn);
	if (ok < 0) {
		sys->print("SimpleHTTPD - listen failed %r\n");
		exit;
	}
	
	rfd := sys->open(conn.dir + "/remote", Sys->OREAD);
	
	n :=  sys->read(rfd, buf, len buf);
	
	spawn hdlrthread(c);
}

hdlrthread(conn : Connection) {
	
	buf := array [sys->ATOMICIO] of byte;
	
	rdfd 	:= sys->open(conn.dir + "/data", Sys->OREAD);
	wdfd 	:= sys->open(conn.dir + "/data", Sys->OWRITE);
	rfd		:= sys->open(conn.dir + "/remote", Sys->OREAD);
	
	n := sys->read(rfd, buf, len buf);
	sys->print("SimpleHTTPD : Got new connection from %s\n",
				string buf[:n]);
				
	while (( n = sys->read(rdfd, buf, len buf)) >= 0) {
	
		comand := int buf[0];
		sys->print("Command = %d (", comand);
		case  comand {
			0 =>
				putFile(buf, n, conn);
			1 =>
				sys->print("GET)\n");
			2 =>
				sys->print("LIST)\n");
		}	
	
		return;
	}
}

putFile(buf : array of byte, n : int, conn : Connection) {
		
	sys->print("PUT)\n");
	
	fileNmaeSize := int buf[1];
	sys->print("Filename size: %d\n", fileNmaeSize);
	fileName := string buf[2:(fileNmaeSize + 2)];
	sys->print("Filename: %s\n", fileName);
	
	#sys->print("MAGIC (%d): %s\n", len "FINALE.", string buf[(n - len "FINALE."):]);
	if (string buf[(n - len "FINALE."):] != "FINALE.") {
		sys->print("Broken data!\n");
		#exit;
	}
	
	file := buf[(fileNmaeSize + 2): n - len "FINALE."];
	fileSize := n - len "FINALE." - fileNmaeSize + 2;
	sys->print("File: %s (seze: %d)\n", string file, fileSize);
	
	sys->print("Gritical section entering...\n");
	<-mutex2Writing;
	sys->print("Entered.\n");
	###################################################################
	
	sys->print("Creating file...\n");
	if ((fd := sys->create("./files/" + fileName, sys->ORDWR, 8r600)) == nil) {
		sys->print("FAILED: %r\n");
	}
	else {		
		sys->write(fd, file, fileSize);		
		sys->print("OK\nChanging list...\n");
		<-mutex2Writing;
		###################################################################
		files = fileName::files;
		sys->print("Files: ");
		printList(files);
		sys->print("\n");
		###################################################################
		mutex2Writing <- = int 1;
		sys->print("Done.\n");
	}
			
	###################################################################
	sys->print("Gritical section leaving...\n");
	mutex2Writing <- = int 1;
	sys->print("Left.\n");
}

delFromList(inList : list of string, fileName : string) : list of string {
	
	if (hd inList == fileName)
		return tl inList;
	
	return (hd inList)::delFromList(tl inList, fileName);
}

findInList(inList : list of string, fileName : string) : int {
	
	if (len inList == 0)
		return 0;
	
	if (hd inList == fileName)
		return 1;
	
	return findInList(tl inList, fileName);
}

printList(lisp : list of string) {
	if (len lisp == 0)
		return;
	
	sys->print("%s ", hd lisp);
	printList(tl lisp);
}












