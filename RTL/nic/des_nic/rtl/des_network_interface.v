`timescale 1ns / 1ps

/*
-- Module Name:	network_interface

-- Description:	Top level de interfaz de red. Desde el punto de vista 
				del router de un nodo, la interfaz de red parece ser 
				un router vecino, por lo que la comunicacion se lleva
				a cabo como una transaccion entre routers.


-- Dependencies:	-- system.vh
					-- packet_type.vh
					-- input_block.v
					-- output_block.v


-- Parameters:		-- CHANNEL_WIDTH:	Ancho de palabra de canales de
										comunicacion para la red.

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 16 de Junio 2015: 	Creacion	
*/
`include "system.vh"


module des_network_interface
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
		output wire [(2 * `CHANNEL_WIDTH)-1:0]	plaintext_dout,
		output wire [(2 * `CHANNEL_WIDTH)-1:0]	key_dout,

		input wire 								done_strobe_din,
		input wire 								active_des_engine_din,
		input wire [(2 * `CHANNEL_WIDTH)-1:0]	ciphertext_din	
	);




// -- Declaracion temprana de señales ---------------------------- >>>>>
	wire [`CHANNEL_WIDTH-3:0] header_flit;
	
	wire busy_engine;
	wire zero_credits;
	wire transfer2pe_strobe;




/*
-- Instancia :: bloque de entrada

-- Descripcion: Bloque de ingreso. En este bloque se almacena de manera
				temporal los datos de trabajo del elemento de 
				procesamiento y se indica a este mismo que existe datos
				validos para que inicie su trabajo. 

*/
	input_block	 bloque_de_ingreso
		(
			.clk	(clk),
			.reset	(reset),

		// -- inputs --------------------------------------------- >>>>>
			.input_channel_din			(input_channel_din),

			.busy_engine_din			(busy_engine),
			.zero_credits_din			(zero_credits),

		// -- output --------------------------------------------- >>>>>
			.plaintext_dout				(plaintext_dout),
			.key_dout					(key_dout),
			.header_flit_dout			(header_flit),
			
			.transfer2pe_strobe_dout 	(transfer2pe_strobe)
		);


	// --Salida de bloque ---------------------------------------- >>>>>
		assign credit_out_dout 		= transfer2pe_strobe;
		assign start_strobe_dout	= transfer2pe_strobe;




/*
-- Transformador de Cabecera

-- Descripcion: Re acomodo de la cabecera del paquete siendo
				trabajado por el elemento de procesaminto.

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


	assign shifted_header = {	1'b1,							// Esta salida siempre refleja un flit de cabecera, por lo que el header field siempre esta en alto
								1'b1,							// Este flit siempre es la salida de procesamiento, por lo que el testigo de procesamiento siempre esta en alto
								header_flit_reg `GATE_FIELD,
								header_flit_reg `DEST_FIELD,
								header_flit_reg `ORIGIN_FIELD,
								header_flit_reg `SERIAL_FIELD
							};

/*
-- Instancia :: bloque de salida

-- Descripcion: Bloque de salida de la interfaz de red. Se encarga del
				manejo de la interaccion entre el elemento de 
				procesamiento y el router. 

				Este modulo toma el resultado del elemento de 
				procesamiento y lo organiza en flits para su transporte
				a travez de la red.
*/
	output_block bloque_de_salida
		(
			.clk	(clk),
			.reset	(reset),
		
		// -- inputs from pn ------------------------------------- >>>>>
			.done_strobe_din	(done_strobe_din),

			.ciphertext_din		(ciphertext_din),
			.shifted_header_din	(shifted_header),

		// -- to input block ------------------------------------- >>>>>
			.zero_credits_dout	(zero_credits),

		// -- output port ---------------------------------------- >>>>>
			.credit_in_din		(credit_in_din),
			.output_channel_dout(output_channel_dout)
		);


	assign busy_engine = zero_credits | active_des_engine_din;

endmodule

/* -- Plantilla de instancia ------------------------------------- >>>>>
des_network_interface interfaz_de_red
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
		.plaintext_dout			(plaintext_dout),
		.key_dout				(key_dout),
	
		.done_strobe_din		(done_strobe_din),
		.active_des_engine_din	(active_des_engine_din),
		.ciphertext_din			(ciphertext_din)
	);
*/