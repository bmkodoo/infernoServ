implement SimpleHTTPD;

include "sys.m";
include "draw.m";

sys : Sys;
Connection : import Sys;
mutex : chan of int;

SimpleHTTPD: module {
	init:	fn(nil: ref Draw->Context, nil: list of string);
};

init(nil: ref Draw->Context, nil: list of string) {

	sys = load Sys Sys->PATH;
	mutex = chan[1] of int;
	mutex <- = int 1;
	
	(n, conn) := sys->announce("udp!*!8034");
	if (n < 0) {
		sys->print("SimpleHTTPD announce failed : %r\n");
		exit;
	}
	
	sys->print("OK\n");
	
	buf := array [sys->ATOMICIO] of byte;
	
	
	while (1) {		
		
		(ok, c) := sys->listen(conn);
		if (ok < 0) {
			sys->print("Listen failed!: %r\n");
			exit;
		}
		
		sys->print("Listen - OK.\n");
	
		rdfd	:= sys->open(conn.dir + "/data", Sys->OREAD);
		rfd 	:= sys->open(conn.dir + "/remote", Sys->OREAD);
		n = sys->read(rdfd, buf, len buf);
		sys->read(rfd, buf, len buf);
		if (n > 0) {
			sys->print("SimpleHTTPD : Got new data from (incomplete) %s\n",
				string buf[:n]);
			
		}
		else {
			sys->print("SimpleHTTPD : Got no data.\n");
		}
	}
}

readMsg(conn : Connection) {

	
	
}

hdlrthread(conn : Connection) {
	
	buf := array [sys->ATOMICIO] of byte;	
	header := array [1] of byte;
		
	rdfd 	:= sys->open(conn.dir + "/data", Sys->OREAD);
	wdfd 	:= sys->open(conn.dir + "/data", Sys->OWRITE);
	rfd		:= sys->open(conn.dir + "/remote", Sys->OREAD);
	
	n := sys->read(rfd, buf, len buf);
	sys->print("SimpleHTTPD : Got new connection from %s\n",
				string buf[:n]);
	
	n = sys->read(rdfd, header, len header);
	command := int header[0];
	sys->print("Command = %d\n", command);
	case  command {
		1 =>
			putFile(conn);			
		2 =>
			sys->print("GET\n");
		3 =>
			sys->print("LIST\n");
	}	
								
	
	return;
}

putFile(conn : Connection) {
		
	sys->print("PUT\n");
	<-mutex;
	
	msg := array [sys->ATOMICIO] of byte;
		
	rdfd 	:= sys->open(conn.dir + "/data", Sys->OREAD);
	wdfd 	:= sys->open(conn.dir + "/data", Sys->OWRITE);
	
	n := sys->read(rdfd, msg, len msg);
	
	
	nameLength := 	int msg[0];
	fileName := 	string msg[1:(nameLength + 1)];
	dataSize := 	n - (nameLength + 1);
	
	sys->print("File name length = %d\n", nameLength);
	sys->print("File name = %s\n", fileName);
	sys->print("Data size = %d\n", dataSize);
	#sys->print("Data: %s\n", string msg[(nameLength + 2):n*2]);	
	
	sys->print("Creating file...\n");
	if ((fd := sys->create("./files/" + fileName, sys->ORDWR, 8r600)) == nil) {
		sys->print("FAILED: %r\n");
	}
	else {
		sys->print("OK\n");
		
		sys->write(fd, msg[(nameLength + 1):], dataSize);
		sys->write(wdfd,
					array of byte "<HTML><BODY>Hello!</BODY></HTML>\n",
					len "<HTML><BODY>Hello!</BODY></HTML>\n");
	}
			
	mutex <-= 1;
	sys->print("KO - free mutex\n");
}













