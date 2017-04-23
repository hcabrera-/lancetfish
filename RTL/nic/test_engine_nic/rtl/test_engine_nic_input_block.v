`timescale 1ns / 1ps

/*
-- Module Name:	Test Engine NiC Input Block

-- Description:	Bloque de recepcion. En este bloque almacena de manera
				temporal los datos de trabajo para el elemento de 
				procesamiento. 

				Ademas se encarga de informar al PE de la presencia de 
				datos validos para que inicie su operacion.

-- Dependencies:	-- system.vh
					-- test_engine_nic_input_control_unit.v

-- Current  Author:

-- Notas:	

-- History:	
	-- 30 de noviembre 2015: 	Creacion	
*/
`include "system.vh"



module test_engine_nic_input_block
	(
		input wire clk,
		input wire reset,

	// -- inputs ------------------------------------------------- >>>>>
		input  wire [`CHANNEL_WIDTH-1:0] 		input_channel_din,

		input  wire 							busy_engine_din,
		input  wire 							zero_credits_din,

	// -- output ------------------------------------------------- >>>>>
		output wire [(2 * `CHANNEL_WIDTH)-1:0]	wordA_dout,
		output wire [(2 * `CHANNEL_WIDTH)-1:0]	wordB_dout,
		output wire [`CHANNEL_WIDTH-3:0]		header_flit_dout,

		output wire 							transfer2pe_strobe_dout
	);




/*
-- Instancia:	input_control_unit

-- Descripcion: Maquina de estado finito para el control de ingreso al
				nodo de procesamiento del router.

				La FSM espera el ingreso de un nuevo paquete a traves 
				del canal de entrada. Durante los siguientes 'n' ciclos
				de reloj se registra cada flit perteneciente al paquete,
				dando la primera posicion del medio de almacenamiento 
				al flit de cabecera.

				Despues de la captura del paquete, si el nodo de 
				procesamiento se encuentra en reposo y el bloque de
				salida aun cuenta con creditos de salida, se emita la 
				señal de arranque al nodo de procesamiento y se
				transita a un estado de reposo.

				En caso contrario, el nodo se encuentre ocupado y no
				se cuente con creditos disponibles, la FSM transita al
				estado WAIT para la espera de la liberacion de recursos.

*/
	wire [`DATA_FLITS:0] 	register_enable;
	wire 					write_strobe;


	test_engine_nic_input_control_unit input_block_control_unit
		(
			.clk	(clk),
			.reset 	(reset),

		// -- inputs --------------------------------------------- >>>>>
			.header_field_din			(input_channel_din[31]),
			.busy_engine_din			(busy_engine_din),
			.zero_credits_din			(zero_credits_din),

		// -- outputs -------------------------------------------- >>>>>
			.transfer2pe_strobe_dout	(transfer2pe_strobe_dout),

			.write_strobe_dout			(write_strobe),
			.register_enable_dout		(register_enable)
		);




/*

	-- Descripcion:	Registro de captura de flit de cabecera. Se describe
					de manera independiene debido a que solo requiere la 
					captura de 30 bits en lugar de 32. El bit de bandera
					de procesamiento siempre llega en 0 y siempre se le
					asigna el valor de 1. Ademas, el bit de cabecera 
					retiene su valor de alto, por lo que se puede 
					asignar a una constante.
*/
	reg [`CHANNEL_WIDTH-3:0] header_flit_reg;

	always @(posedge clk)
		if (register_enable[0] & write_strobe)
				header_flit_reg <= input_channel_din[29:0];




/*

	-- Descripcion:	Banco de registros de captura de datos para el PE.
					Cada registros esta descrito de manera independiente
					a nivel RTL.

					Solo Moldea los registros para captura de flits de 
					datos, el flit de cabecera es capturado en un 
					registro independiente.
*/
	reg [`CHANNEL_WIDTH-1:0] DATA_FLIT_BANK [`DATA_FLITS-1:0];

	genvar index;

	generate
		for (index = 0; index < (`DATA_FLITS); index = index + 1)
			begin: registros_interfaz_de_red
				always @(posedge clk)
					if (register_enable[index+1] & write_strobe)
						DATA_FLIT_BANK[index] <= input_channel_din;
			end
	endgenerate

	initial
		begin: inicializacion_de_registros
			integer idx;
			for (idx = 0; idx < (`DATA_FLITS); idx = idx + 1)
					DATA_FLIT_BANK[idx] <= {`CHANNEL_WIDTH{1'b0}};
		end

	// -- logica de salida --------------------------------------- >>>>>
		assign header_flit_dout = header_flit_reg;

		assign wordA_dout = {DATA_FLIT_BANK[0], DATA_FLIT_BANK[1]};
		assign wordB_dout = {DATA_FLIT_BANK[2], DATA_FLIT_BANK[3]};



endmodule // test_engine_nic_input_block

/* -- Plantilla de instancia ------------------------------------- >>>>>
	test_engine_nic_input_block	 test_engine_nic_input_block
	(
		.clk 	(clk),
		.reset 	(reset),

	// -- inputs ------------------------------------------------- >>>>>
		.input_channel_din			(input_channel_din),

		.busy_engine_din			(busy_engine_din),
		.zero_credits_din			(zero_credits_din),

	// -- output ------------------------------------------------- >>>>>
		.wordA_dout					(wordA_dout),
		.wordB_dout					(wordB_dout),
		.header_flit_dout			(header_flit_dout),
		
		.transfer2pe_strobe_dout	(transfer2pe_strobe_dout)
	);

*/