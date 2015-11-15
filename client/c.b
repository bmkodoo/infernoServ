implement MyClient;

include "sys.m";
include "draw.m";

sys : Sys;
Connection : import Sys;

MyClient: module {
	init:	fn(nil: ref Draw->Context, argv: list of string);
};

init(nil: ref Draw->Context, argv: list of string) {

	sys = load Sys Sys->PATH;

	# проверяем наличие аргументов командной строки
	
	if ((tl argv) == nil) {
		sys->print("Wrong parametres! (PUT, GET or LIST)\n");
		exit;
	} 
	
	comand := hd (tl argv);
	filename : string;
	comandId : int;
	if ((comand == "PUT") || (comand == "GET")) {
		sys->print("Comand: %s\n", comand);
		if (comand == "PUT")
			comandId = 0;
		else 
			comandId = 1;
		tail := tl argv;
		if ((tl tail) == nil) {
			sys->print("Wrong parametres! (need filename)\n");
			exit;
		}
		
		filename = hd (tl tail);
		sys->print("Filename: %s\n", filename);
	}	
	else if (comand == "LIST")
		comandId = 2;
	else {
		sys->print("Wrong parametres! (PUT, GET or LIST)\n");
		exit;
	}
	
	(n, conn) := sys->dial("tcp!127.0.0.1!8034", nil);
	if (n < 0) {
		sys->print("Client: Connection error: %r\n");
		exit;
	}
	
	case  comandId {
		0 =>
			sendFile(conn, filename);		
		1 =>
			sys->print("GET)\n");
		2 =>
			sys->print("LIST)\n");
	}	
	
	
}

sendFile(conn : Connection, filename : string) {
	
	fileNameBytes := array of byte filename;
	fileNameSize := len fileNameBytes;
	
	
	rdfd := sys->open("./" + filename, Sys->OREAD);
	buf := array [sys->ATOMICIO] of byte;
	n := sys->read(rdfd, buf, len buf);
	#->print("File: %s\n", string buf[:n]);
	
	magSize := 1 + 1 + fileNameSize + n + len "FINALE.";
	
	data := array [magSize] of byte;
	data[0] = byte int 0;
	data[1] = byte fileNameSize;
	data[2:] = fileNameBytes;
	data[(2 + fileNameSize):] = buf[:n];
	
	data[(2 + fileNameSize + n):] = array of byte "FINALE.";
	
	wdfd := sys->open(conn.dir + "/data", Sys->OWRITE);
	
	sys->write(wdfd, data, len data);
	
}













