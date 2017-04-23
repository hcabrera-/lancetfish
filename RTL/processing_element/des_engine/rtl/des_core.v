`timescale 1ns / 1ps

/*
-- Module Name:	DES Core

-- Description:	Nucleo de encriptacion DES. El bloque trabaja con un
				bloque de datos a encriptar de 64 bits denominado 
				'plaintext' y una llave de encriptacion de 64 bits
				llamada 'key'.

				El proceso de encriptacion tiene una duracion de 16
				ciclos de reloj.


-- Dependencies:	-- none


-- Parameters:		-- none


-- Original Author:	Héctor Cabrera

-- Current  Author:

-- History:	
	-- Creacion 05 de Junio 2015
*/


module des_core
	(
		input wire clk,
		input wire reset,

	// -- input -------------------------------------------------- >>>>>
		input wire 			start_strobe_din,

		input wire [0:63] 	plaintext_din,
		input wire [0:63]	key_din,

	// -- output ------------------------------------------------- >>>>>
		output wire 		done_strobe_dout,
		output wire 		active_des_engine_dout,
		output wire 		parity_check_dout,
		output wire [0:63]	ciphertext_dout
    );

// -- Declaracion temprana de señales ---------------------------- >>>>>
	wire enable;
	wire source;
	wire round_shift;

	wire [0:47]	round_key;
	wire [0:63] ciphertext;



// -- Parity Drop ------------------------------------------------ >>>>>
/*
	-- Nota: 	La llave de DES esta formada por 64 bits. Sin embargo,
				los datos utilizados de manera efectiva son 56. Este 
				paso elimina los bits de paridad de toda la llave,
				dejando atras solo datos efectivos.
*/
	wire [0:55]	parity_drop_key;
	wire 		parity_check;


	assign parity_drop_key[0 +: 8] = 	{
											key_din[56],
											key_din[48],
											key_din[40],
											key_din[32],
											key_din[24],
											key_din[16],
											key_din[8],
											key_din[0]
										};

	assign parity_drop_key[8 +: 8] = 	{
											key_din[57],
											key_din[49],
											key_din[41],
											key_din[33],
											key_din[25],
											key_din[17],
											key_din[9],
											key_din[1]
										};

	assign parity_drop_key[16 +: 8] = 	{
											key_din[58],
											key_din[50],
											key_din[42],
											key_din[34],
											key_din[26],
											key_din[18],
											key_din[10],
											key_din[2]
										};

	assign parity_drop_key[24 +: 8] = 	{
											key_din[59],
											key_din[51],
											key_din[43],
											key_din[35],
											key_din[62],
											key_din[54],
											key_din[46],
											key_din[38]
										};

	assign parity_drop_key[32 +: 8] = 	{
											key_din[30],
											key_din[22],
											key_din[14],
											key_din[6],
											key_din[61],
											key_din[53],
											key_din[45],
											key_din[37]
										};

	assign parity_drop_key[40 +: 8] = 	{
											key_din[29],
											key_din[21],
											key_din[13],
											key_din[5],
											key_din[60],
											key_din[52],
											key_din[44],
											key_din[36]
										};

	assign parity_drop_key[48 +: 8] = 	{
											key_din[28],
											key_din[20],
											key_din[12],
											key_din[4],
											key_din[27],
											key_din[19],
											key_din[11],
											key_din[3]
										};

	assign 	parity_check_dout = 	key_din[7]	^
									key_din[15]	^
									key_din[23]	^
									key_din[31]	^
									key_din[39]	^
									key_din[47]	^
									key_din[55]	^
									key_din[63];



// -- Unidad de Control ------------------------------------------ >>>>>
	des_control 	unidad_control
		(
			.clk				(clk),
			.reset				(reset),

		// -- input ---------------------------------------------- >>>>>
			.start_strobe_din	(start_strobe_din),

		// -- output --------------------------------------------- >>>>>
			.enable_dout		(enable),
			.source_dout		(source),
			.active_dout 		(active_des_engine_dout),
			.round_shift_dout	(round_shift),

			.done_strobe_dout	(done_strobe_dout)
	    );


// -- Camino de datos de nucleo DES ------------------------------ >>>>>
	
	// -- Generador de Round keys ------------------------------- >>>>>>
		des_key_generator 	key_generator
			(
				.clk				(clk),
				.reset				(reset),

			// -- input ------------------------------------------ >>>>>
				.enable_din			(enable),
				.source_sel_din		(source),
				.round_shift_din	(round_shift),

				.parity_drop_key_din(parity_drop_key),

			// -- output ----------------------------------------- >>>>>
				.round_key_dout		(round_key)
		    );	


	// -- Rondas de encriptacion --------------------------------- >>>>>
		des_datapath 	cipher_rounds
			(
				.clk 			(clk),
				.reset 			(reset),

			// -- inputs ----------------------------------------- >>>>>
				.enable 		(enable),
				.source_sel 	(source),
				.plaintext_din	(plaintext_din),
				.round_key_din	(round_key),
			// -- outputs ---------------------------------------- >>>>>
				.ciphertext_dout(ciphertext)
		    );
	
	// -- logica de salida --------------------------------------- >>>>>	
		assign  ciphertext_dout = ciphertext;

endmodule
/* -- Plantilla de instancia ------------------------------------- >>>>>
des_core	des_engine
	(
		.clk(clk),
		.reset(reset),

	// -- input -------------------------------------------------- >>>>>
		.start_strobe_din		(start_strobe_din),

		.plaintext_din			(plaintext_din),
		.key_din 				(key_din),

	// -- output ------------------------------------------------- >>>>>
		.done_strobe_dout 		(done_strobe_dout),
		.active_des_engine_dout	(active_des_engine_dout),
		.parity_check_dout 		(parity_check_dout),
		.ciphertext_dout 		(ciphertext_dout)
    );
*/