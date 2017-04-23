`timescale 1ns / 1ps

/*
-- Module Name:	Data Path

-- Description:	Camino de datos. Top level para la instancia de los 
				elementos que manejan datos a travez del router.


-- Dependencies:	-- system.vh
					-- input_queue.v 	x 4
					-- switch_fabric.v 	x 1


-- Parameters:		-- 	{X_POS, Y_POS, X_NEG, Y_NEG, PE} Identificador
						asignado a cada direccion de IO del router. El 
						identificador es utilizado como medio para 
						realizar las conexiones correctas en los ciclos
						for : generate durante la instancia de sub 
						modulos.



-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 11 de Junio 2015: 	+ Puertos de salida 'buffer_xxxx_dout' para
							  comunicarse con el control path.
	-- 14 de Junio 2015: 	+ Puerto de salida de buffer para arbitraje 
							  en PE. Se agrego señales de control 
							  (read/write_strobe) para buffer de PE.
							  Se Anexo al vector outgoing_flit el 
							  elemeto para reresentar la salida del 
							  buffer de PE.
*/
`include "system.vh"



module data_path
	(
		input wire clk,
		input wire reset,

	// -- input -------------------------------------------------- >>>>>
		input wire [`CHANNEL_WIDTH-1:0]	channel_xpos_din,
		input wire [`CHANNEL_WIDTH-1:0]	channel_ypos_din,
		input wire [`CHANNEL_WIDTH-1:0]	channel_xneg_din,
		input wire [`CHANNEL_WIDTH-1:0]	channel_yneg_din,
		input wire [`CHANNEL_WIDTH-1:0]	channel_pe_din,

		input wire [4:0]	write_strobe_din,
		input wire [4:0]	read_strobe_din,

		input wire [3:0]	xbar_conf_vector_xpos_din,
		input wire [3:0]	xbar_conf_vector_ypos_din,
		input wire [3:0]	xbar_conf_vector_xneg_din,
		input wire [3:0]	xbar_conf_vector_yneg_din,
		input wire [3:0]	xbar_conf_vector_pe_din,
	
	// -- output ------------------------------------------------- >>>>>
		output wire [29:24]	buffer_xpos_dout,
		output wire [29:24]	buffer_ypos_dout,
		output wire [29:24]	buffer_xneg_dout,
		output wire [29:24]	buffer_yneg_dout,
		output wire [29:24]	buffer_pe_dout,

		output wire done_buffer_xpos_dout,
		output wire done_buffer_ypos_dout,
		output wire done_buffer_xneg_dout,
		output wire done_buffer_yneg_dout,
		output wire done_buffer_pe_dout,

		
		output wire [`CHANNEL_WIDTH-1:0]	channel_xpos_dout,
		output wire [`CHANNEL_WIDTH-1:0]	channel_ypos_dout,
		output wire [`CHANNEL_WIDTH-1:0]	channel_xneg_dout,
		output wire [`CHANNEL_WIDTH-1:0]	channel_yneg_dout,
		output wire [`CHANNEL_WIDTH-1:0]	channel_pe_dout
    );



/*
-- Instancia :: Buffers de Entrada (Input Queue)

-- Descripcion:	Colas de almacenamiento ligadas a cada puerto de entrada
				. Las señales de control para operaciones de lectura/
				escritura provienen del camino de control del router, en
				especifico del modulo 'control de enlace'.

				Los canales de entrada se agrupan en el arreglo 
				'input_channels' para poder ser conectados de manera
				automatica en el loop - generate.
*/

	// -- Desglose de Señales ------------------------------------ >>>>>
		
		// -- Consolidacion de Canalas de Entrada ---------------- >>>>>
			wire [`CHANNEL_WIDTH-1:0] input_channels [4:0];	

			assign input_channels[`X_POS] = channel_xpos_din;
			assign input_channels[`Y_POS] = channel_ypos_din;
			assign input_channels[`X_NEG] = channel_xneg_din;
			assign input_channels[`Y_NEG] = channel_yneg_din;
			assign input_channels[`PE]    = channel_pe_din;

		// -- Salida :: Flit a la Salida del Buffer -------------- >>>>>
			wire [`CHANNEL_WIDTH-1:0] 	outgoing_flit [4:0];

			wire [4:0]	full_flag;
			wire [4:0]	empty_flag;
	

	// -- Intancias :: Input Queue ------------------------------- >>>>>
	/* -- Nota : 	No se crea instancia de Queue para PE por que el 
					medio de almacenamiento se encuentra dentro de la 
					unidad funcional.				
	*/
		genvar index;
			
			generate
				for (index = `X_POS; index < (`PE + 1); index=index + 1)
					begin: input_queue
						fifo	buffer_de_paquetes
							(
								.clk(clk),
								.reset(reset),

							// -- inputs ------------------------- >>>>>
								.write_strobe_din	(write_strobe_din[index]),
								.read_strobe_din	(read_strobe_din[index]),

								.write_data_din		(input_channels[index]),

							// -- outputs ------------------------ >>>>>
								.full_dout			(full_flag[index]),
								.empty_dout			(empty_flag[index]),

								.read_data_dout 	(outgoing_flit[index])
							);
					end
			endgenerate
	

		assign buffer_xpos_dout 		= outgoing_flit[`X_POS][29:24];
		assign buffer_ypos_dout 		= outgoing_flit[`Y_POS][29:24];
		assign buffer_xneg_dout 		= outgoing_flit[`X_NEG][29:24];
		assign buffer_yneg_dout 		= outgoing_flit[`Y_NEG][29:24];
		assign buffer_pe_dout   		= outgoing_flit[`PE][29:24];

		assign done_buffer_xpos_dout 	= outgoing_flit[`X_POS][30];
		assign done_buffer_ypos_dout 	= outgoing_flit[`Y_POS][30];
		assign done_buffer_xneg_dout 	= outgoing_flit[`X_NEG][30];
		assign done_buffer_yneg_dout 	= outgoing_flit[`Y_NEG][30];
		assign done_buffer_pe_dout   	= outgoing_flit[`PE][30];		 



/*
-- Instancia :: Medio de Interconexion del router

-- Descripcion:	Crossbar para la conexion de puertos de entrada con 
				puertos de salida. El diseño consiste en un conjunto
				de multiplexores para permitir el paso de los datos
				provenientes de una de las colas de almacenamiento en
				direccion de un puerto de salida.

				Las señales de control para los multiplexores provienen
				del camino de contol, en especifico de los modulos 
				'planificador de salida.'
*/
	// -- Instancia :: SF ---------------------------------------- >>>>>
		switch_fabric 	xbar
			(
				.clk	(clk),
				.reset 	(reset),

			// -- input ------------------------------------------ >>>>>
				.inport_xpos_din	(outgoing_flit[`X_POS]),
				.inport_ypos_din	(outgoing_flit[`Y_POS]),
				.inport_xneg_din	(outgoing_flit[`X_NEG]),
				.inport_yneg_din	(outgoing_flit[`Y_NEG]),
				.inport_pe_din  	(outgoing_flit[`PE]),

				.conf_xpos_din 		(xbar_conf_vector_xpos_din),
				.conf_ypos_din 		(xbar_conf_vector_ypos_din),
				.conf_xneg_din 		(xbar_conf_vector_xneg_din),
				.conf_yneg_din 		(xbar_conf_vector_yneg_din),
				.conf_pe_din  		(xbar_conf_vector_pe_din),

			// -- output ----------------------------------------- >>>>>
				.outport_xpos_dout	(channel_xpos_dout),
				.outport_ypos_dout	(channel_ypos_dout),
				.outport_xneg_dout	(channel_xneg_dout),
				.outport_yneg_dout	(channel_yneg_dout),
				.outport_pe_dout  	(channel_pe_dout)
		    );

endmodule

/* -- Plantilla de Instancia ------------------------------------- >>>>>

data_path 	camino_de_datos
	(
		.clk 	(clk),
		.reset 	(reset),

	// -- input -------------------------------------------------- >>>>>
		.channel_xpos_din			(channel_xpos_din),
		.channel_ypos_din			(channel_ypos_din),
		.channel_xneg_din			(channel_xneg_din),
		.channel_yneg_din			(channel_yneg_din),
		.channel_pe_din  			(channel_pe_din),

		.write_strobe_din			(write_strobe_din),
		.read_strobe_din 			(read_strobe_din),

		.xbar_conf_vector_xpos_din	(xbar_conf_vector_xpos_din),
		.xbar_conf_vector_ypos_din	(xbar_conf_vector_ypos_din),
		.xbar_conf_vector_xneg_din	(xbar_conf_vector_xneg_din),
		.xbar_conf_vector_yneg_din	(xbar_conf_vector_yneg_din),
		.xbar_conf_vector_pe_din	(xbar_conf_vector_pe_din),
	
	// -- output ------------------------------------------------- >>>>>
		.buffer_xpos_dout 			(buffer_xpos_dout),
		.buffer_ypos_dout 			(buffer_ypos_dout),
		.buffer_xneg_dout 			(buffer_xneg_dout),
		.buffer_yneg_dout 			(buffer_yneg_dout),
		.buffer_pe_dout  			(buffer_pe_dout),

		.done_buffer_xpos_dout		(done_buffer_xpos_dout),
		.done_buffer_ypos_dout		(done_buffer_ypos_dout),
		.done_buffer_xneg_dout		(done_buffer_xneg_dout),
		.done_buffer_yneg_dout		(done_buffer_yneg_dout),
		.done_buffer_pe_dout		(done_buffer_pe_dout),

		.channel_xpos_dout			(channel_xpos_dout),
		.channel_ypos_dout			(channel_ypos_dout),
		.channel_xneg_dout			(channel_xneg_dout),
		.channel_yneg_dout			(channel_yneg_dout),
		.channel_pe_dout			(channel_pe_dout)
    );

*/