`timescale 1ns / 1ps

/*
-- Module Name:	test_engine_network_interface

-- Description:	Top level de interfaz de red. Desde el punto de vista 
				del router del nodo, la interfaz de red parece ser 
				un router vecino, por lo que la comunicacion se lleva
				a cabo como una transaccion entre routers.

				Esta interfaz de red en particular se encarga de 
				transacciones de dos palabras de 64 bits con el PE y 
				recibe de igual forma 2 palabras de 64 bits como
				resultado. La señal start_strobe indica al PE que los
				datos proporcionados son validos, mientras que la 
				señal done_strobe indica a la interfaz que los datos
				entregados por el PE son validos.


-- Dependencies:	-- system.vh
					-- test_engine_nic_input_block.v
					-- test_engine_nic_output_block.v


-- Parameters:		-- CHANNEL_WIDTH:	Ancho de palabra de canales de
										comunicacion para la red.

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 30 de Noviembre 2015: 	Creacion	
*/
`include "system.vh"


module test_engine_network_interface
	(
		input wire 	clk,
		input wire 	reset,

	// -- input port --------------------------------------------- >>>>>
		output wire 							credit_out_dout, 
		input  wire [`CHANNEL_WIDTH-1:0]		input_channel_din,

	// -- output port -------------------------------------------- >>>>>
		input  wire 							credit_in_din, 
		output wire [`CHANNEL_WIDTH-1:0]		output_channel_dout,

	// -- interfaz :: processing node ---------------------------- >>>>>
		output wire 							start_strobe_dout,
		output wire [(2 * `CHANNEL_WIDTH)-1:0]	wordA_dout,
		output wire [(2 * `CHANNEL_WIDTH)-1:0]	wordB_dout,

		input wire 								done_strobe_din,
		input wire 								active_test_engine_din,
		input wire [(2 * `CHANNEL_WIDTH)-1:0]	wordC_din,
		input wire [(2 * `CHANNEL_WIDTH)-1:0]	wordD_din
	);




// -- Declaracion temprana de señales ---------------------------- >>>>>
	wire [`CHANNEL_WIDTH-3:0] header_flit;
	
	wire busy_engine;
	wire zero_credits;
	wire transfer2pe_strobe;

	assign busy_engine = zero_credits | active_test_engine_din;


/*
-- Instancia :: test_engine_nic_input_block

-- Descripcion: Bloque de ingreso. En este bloque se almacena de manera
				temporal los datos de trabajo del elemento de 
				procesamiento. Una vez capturado un conjunto de datos
				(2 palabras de 64 bits), se indica al PE del nodo la
				existencia datos validos para que inicie su trabajo.

				La señal transfer2pe_strobe indica la existencia de 
				datos validos.

*/
	test_engine_nic_input_block	 test_engine_nic_input_block
		(
			.clk	(clk),
			.reset	(reset),

		// -- inputs --------------------------------------------- >>>>>
			.input_channel_din			(input_channel_din),

			.busy_engine_din			(busy_engine),
			.zero_credits_din			(zero_credits),

		// -- output --------------------------------------------- >>>>>
			.wordA_dout					(wordA_dout),
			.wordB_dout					(wordB_dout),
			.header_flit_dout			(header_flit),
			
			.transfer2pe_strobe_dout 	(transfer2pe_strobe)
		);


	// --Salida de bloque ---------------------------------------- >>>>>
		assign credit_out_dout 		= transfer2pe_strobe;
		assign start_strobe_dout	= transfer2pe_strobe;




/*
-- Transformador de Cabecera

-- Descripcion: Re acomodo de la cabecera del paquete que a ingresado al
				Elemento de procesamiento del nodo.

				Dos cambios se llevan a cabo:

					- 	El campo testigo pasa a estado alto para 
						indicar que que el paquete ya a sido trabajado 
						por un elemento de procesamiento.
					-	El campo PUERTA y DESTINO intercambian 
						posiciones. Con este ultimo cambio, el paquete 
						al salir buscara su PUERTA de salida de la red
						y no pedira mas su ingreso a un elemento de 
						procesamiento.
*/

	reg  [`CHANNEL_WIDTH-3:0] header_flit_reg;
	wire [`CHANNEL_WIDTH-1:0] shifted_header;

	always @(posedge clk)
		if (transfer2pe_strobe)
			header_flit_reg <= header_flit;


	assign shifted_header = {	1'b1,									// (Header Field)  Esta salida siempre refleja un flit de cabecera, por lo que el header field siempre esta en alto
								1'b1,									// (Witness Field) Este flit siempre es la salida de procesamiento, por lo que el testigo de procesamiento siempre esta en alto
								header_flit_reg `GATE_FIELD,
								header_flit_reg `DEST_FIELD,
								header_flit_reg `ORIGIN_FIELD,
								header_flit_reg `SERIAL_FIELD
							};

/*
-- Instancia :: test_engine_nic_output_block

-- Descripcion: Bloque de salida de la interfaz de red. Se encarga del
				manejo de la interaccion entre el elemento de 
				procesamiento y el router. 

				Este modulo toma el resultado del elemento de 
				procesamiento y lo organiza en flits para su transporte
				a travez de la red.

				La recepcion de la señal done_strobe_din desde el PE del
				nodo, indica la presencia de datos validos para su 
				captura y envio a traves de la red.
*/
	test_engine_nic_output_block test_engine_nic_output_block
		(
			.clk	(clk),
			.reset	(reset),
		
		// -- inputs from pe ------------------------------------- >>>>>
			.done_strobe_din	(done_strobe_din),

			.wordC_din			(wordC_din),
			.wordD_din			(wordD_din),
			.shifted_header_din (shifted_header),

		// -- to input block ------------------------------------- >>>>>
			.zero_credits_dout	(zero_credits),

		// -- output port ---------------------------------------- >>>>>
			.credit_in_din		(credit_in_din),
			.output_channel_dout(output_channel_dout)
		);


endmodule


/* -- Plantilla de instancia ------------------------------------- >>>>>
test_engine_network_interface test_engine_nic
	(
		.clk	(clk),
		.reset	(reset),

	// -- input port --------------------------------------------- >>>>>
		.credit_out_dout		(credit_out_dout), 
		.input_channel_din		(input_channel_din),

	// -- output port -------------------------------------------- >>>>>
		.credit_in_din			(credit_in_din), 
		.output_channel_dout	(output_channel_dout),

	// -- interfaz :: processing node ---------------------------- >>>>>
		.start_strobe_dout		(start_strobe_dout),
		.wordA_dout				(wordA_dout),
		.wordB_dout				(wordB_dout),
	
		.done_strobe_din		(done_strobe_din),
		.active_test_engine_din	(active_test_engine_din),
		.wordC_din				(wordC_din),
		.wordD_din				(wordD_din)
	);
*/