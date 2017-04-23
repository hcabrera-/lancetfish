// -- Simbolos de campos de paquete ------------------------------ >>>>>

	`define HEADER_FIELD 			[31]
	`define WITNESS_FIELD			[30]
	`define DEST_FIELD				[29:24]
	`define GATE_FIELD 				[23:18]
	`define ORIGIN_FIELD 			[17:12]
	`define SERIAL_FIELD 			[11:0]



// -- Caracteristicas Generales de la NoC ------------------------ >>>>>
	`define 	CHANNEL_WIDTH 	32
	`define 	DATA_FLITS 		4
	`define 	BUFFER_DEPTH	15

	`define 	X_POS	0
	`define 	Y_POS	1
	`define 	X_NEG	2
	`define 	Y_NEG	3
	`define 	PE 		4

	`define		ADDR_FIELD	3
	
	


// -- Parametros para pruebas ------------------------------------ >>>>>
	`define 	ROUNDS 	5


// -- Direccion de Señales :: LC y OS ---------------------------- >>>>>

	// -- X+ [0] ------------------------------------------------- >>>>>
		`define 	XPOS_PE 	0
		`define 	XPOS_YPOS	1
		`define 	XPOS_XNEG	2
		`define 	XPOS_YNEG	3

	// -- Y+ [1] ------------------------------------------------- >>>>>
		`define 	YPOS_PE 	0
		`define 	YPOS_XPOS	1
		`define 	YPOS_XNEG	2
		`define 	YPOS_YNEG	3

	// -- X- [2] ------------------------------------------------- >>>>>
		`define 	XNEG_PE 	0
		`define 	XNEG_XPOS	1
		`define 	XNEG_YPOS	2
		`define 	XNEG_YNEG	3

	// -- Y- [3] ------------------------------------------------- >>>>>
		`define 	YNEG_PE 	0
		`define 	YNEG_XPOS	1
		`define 	YNEG_YPOS	2
		`define 	YNEG_XNEG	3

	// -- PE [4] ------------------------------------------------- >>>>>
		`define 	PE_XPOS 	0
		`define 	PE_YPOS		1
		`define 	PE_XNEG		2
		`define 	PE_YNEG		3

