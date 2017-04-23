`timescale 1ns / 1ps

/*
-- Module Name:	router

-- Description:	Top level de router NoC. 


-- Dependencies:	-- system.vh
					-- control_path.v
					-- data_path.v


-- Parameters:		-- X_LOCAL:		Direccion en dimension "x" del nodo 
									en la red.
					-- Y_LOCAL:		Direccion en dimension "y" del nodo 
									en la red.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 11 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control. 
	-- 14 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control. 
*/
`include "system.vh"


module router 	#(
					parameter 	X_LOCAL 	= 2,
					parameter	Y_LOCAL 	= 2,
					parameter 	X_WIDTH 	= 2,
					parameter 	Y_WIDTH 	= 2
				)
	(
		input wire clk,
		input wire reset,

	// -- puertos de entrada ------------------------------------- >>>>>
		output wire							credit_out_xpos_dout,
		input  wire [`CHANNEL_WIDTH-1:0]	channel_xpos_din,

		output wire							credit_out_ypos_dout,
		input  wire [`CHANNEL_WIDTH-1:0]	channel_ypos_din,

		output wire							credit_out_xneg_dout,
		input  wire [`CHANNEL_WIDTH-1:0]	channel_xneg_din,

		output wire							credit_out_yneg_dout,
		input  wire [`CHANNEL_WIDTH-1:0]	channel_yneg_din,

		output wire							credit_out_pe_dout,
		input  wire [`CHANNEL_WIDTH-1:0]	channel_pe_din,

	// -- puertos de salida -------------------------------------- >>>>>
		input  wire 						credit_in_xpos_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_xpos_dout,
		
		input  wire 						credit_in_ypos_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_ypos_dout,

		input  wire 						credit_in_xneg_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_xneg_dout,

		input  wire 						credit_in_yneg_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_yneg_dout,

		input  wire 						credit_in_pe_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_pe_dout
    );






/*
-- Instancia :: Camino de Control

-- Descripcion:	Top level para logica de control. En este modulo 
				contiene instancias para los modulos:

					-- control de enlace 		(link controller)
					-- selector
					-- planificador de salida 	(outport scheduler)

				Todas las salidas del modulo se conectan al camino de 
				datos con excepcion de las terminales para la recepcion/
				transmicion de creditos.

				La señales IO se agrupan en arreglos para facilitar la
				interconexion.

				Los puertos buffer_xxxx son el puente de comunicacion
				con el camino de datos. Se utilizan para la transmision
				del campo 'destino' para el calculo de ruta.
*/
	// -- Desglose de Señales ------------------------------------ >>>>>

		
		// -- Entrada :: Dupla (x,y) desde buffer ---------------- >>>>>
			wire [29:24]	buffer_xpos;
			wire [29:24]	buffer_ypos;
			wire [29:24]	buffer_xneg;
			wire [29:24]	buffer_yneg;
			wire [29:24]	buffer_pe;

		// -- Entrada :: Campo 'done' desde buffer---------------- >>>>>
			wire 			buffer_done_xpos;
			wire 			buffer_done_ypos;
			wire 			buffer_done_xneg;
			wire 			buffer_done_yneg;
			wire 			buffer_done_pe;

		// -- Salida :: Señales de Escritura/Lectura a Buffer ---- >>>>>
			wire [4:0]		write_strobe;
			wire [4:0]		read_strobe;

		// -- Salida :: Señales de Configuracion de XBAR --------- >>>>>
			wire [3:0]		xbar_conf_vector_xpos;
			wire [3:0]		xbar_conf_vector_ypos;
			wire [3:0]		xbar_conf_vector_xneg;
			wire [3:0]		xbar_conf_vector_yneg;
			wire [3:0]		xbar_conf_vector_pe;
		
	
	// -- Instancia :: Camino de Control ------------------------- >>>>>
	control_path	
		#(
			.X_LOCAL	(X_LOCAL), 
			.Y_LOCAL	(Y_LOCAL),
			.X_WIDTH	(X_WIDTH),
			.Y_WIDTH	(Y_WIDTH)
		)
	camino_de_control
		(
			.clk	(clk),
			.reset 	(reset),

		// -- segmentos de puertos de entrada -------------------- >>>>>
			.credit_out_xpos_dout	(credit_out_xpos_dout),
			.input_channel_xpos_din	(channel_xpos_din[31:24]),
						
			.credit_out_ypos_dout	(credit_out_ypos_dout),
			.input_channel_ypos_din	(channel_ypos_din[31:24]),			

			.credit_out_xneg_dout	(credit_out_xneg_dout),
			.input_channel_xneg_din	(channel_xneg_din[31:24]),			

			.credit_out_yneg_dout	(credit_out_yneg_dout),
			.input_channel_yneg_din	(channel_yneg_din[31:24]),			

			.credit_out_pe_dout		(credit_out_pe_dout),
			.input_channel_pe_din	(channel_pe_din[31:24]),
			

		// -- puertos de recepcion de creditos ------------------- >>>>>
			.credit_in_xpos_din		(credit_in_xpos_din),
			.credit_in_ypos_din		(credit_in_ypos_din),
			.credit_in_xneg_din		(credit_in_xneg_din),
			.credit_in_yneg_din		(credit_in_yneg_din),
			.credit_in_pe_din		(credit_in_pe_din),

		// -- señales de entrada desde el camino de datos -------- >>>>>
			.buffer_xpos_din		(buffer_xpos),
			.done_buffer_xpos_din	(buffer_done_xpos),

			.buffer_ypos_din		(buffer_ypos),
			.done_buffer_ypos_din	(buffer_done_ypos),

			.buffer_xneg_din		(buffer_xneg),
			.done_buffer_xneg_din	(buffer_done_xneg),

			.buffer_yneg_din		(buffer_yneg),
			.done_buffer_yneg_din	(buffer_done_yneg),

			.buffer_pe_din			(buffer_pe),
			.done_buffer_pe_din		(buffer_done_pe),

		// -- señales de salida a camino de datos ---------------- >>>>>
			.write_strobe_dout		(write_strobe),
			.read_strobe_dout		(read_strobe),

			.xbar_conf_vector_xpos_dout	(xbar_conf_vector_xpos),
			.xbar_conf_vector_ypos_dout	(xbar_conf_vector_ypos),
			.xbar_conf_vector_xneg_dout	(xbar_conf_vector_xneg),
			.xbar_conf_vector_yneg_dout	(xbar_conf_vector_yneg),
			.xbar_conf_vector_pe_dout	(xbar_conf_vector_pe)

	    );






/*
-- Instancia :: Camino de Datos

-- Descripcion:	Top level para la infraestructura de manejo de datos a 
				traves del router. El modulo incluye las instancias de:

					-- Colas de almacenamiento (Input Queue)
					-- Crossbar (switch_fabric)

				El modulo proporciona los puertos de entrada y salida 
				del router. Todas las señales de control son 
				proporcionadas por el modulo 'control_path'.

				Los puertos buffer_xxxx son el puente de comunicacion
				con el camino de datos. Se utilizan para la transmision
				del campo 'destino' para el calculo de ruta.
*/
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

		.write_strobe_din			(write_strobe),
		.read_strobe_din 			(read_strobe),

		.xbar_conf_vector_xpos_din	(xbar_conf_vector_xpos),
		.xbar_conf_vector_ypos_din	(xbar_conf_vector_ypos),
		.xbar_conf_vector_xneg_din	(xbar_conf_vector_xneg),
		.xbar_conf_vector_yneg_din	(xbar_conf_vector_yneg),
		.xbar_conf_vector_pe_din	(xbar_conf_vector_pe),
	
	// -- output ------------------------------------------------- >>>>>
		.buffer_xpos_dout 			(buffer_xpos),
		.buffer_ypos_dout			(buffer_ypos),
		.buffer_xneg_dout			(buffer_xneg),
		.buffer_yneg_dout			(buffer_yneg),
		.buffer_pe_dout  			(buffer_pe),

		.done_buffer_xpos_dout		(buffer_done_xpos),
		.done_buffer_ypos_dout		(buffer_done_ypos),
		.done_buffer_xneg_dout		(buffer_done_xneg),
		.done_buffer_yneg_dout		(buffer_done_yneg),
		.done_buffer_pe_dout		(buffer_done_pe),

		.channel_xpos_dout			(channel_xpos_dout),
		.channel_ypos_dout			(channel_ypos_dout),
		.channel_xneg_dout			(channel_xneg_dout),
		.channel_yneg_dout			(channel_yneg_dout),
		.channel_pe_dout			(channel_pe_dout)
    );

endmodule

/* -- Plantilla de Instancia ------------------------------------- >>>>>

router 	
	#(
		.X_LOCAL	(X_LOCAL), 
		.Y_LOCAL	(Y_LOCAL),
		.X_WIDTH	(X_WIDTH),
		.Y_WIDTH	(Y_WIDTH)
	)
lancetfish_router
	(
		.clk	(clk),
		.reset 	(reset),

	// -- puertos de entrada ------------------------------------- >>>>>
		.credit_out_xpos_dout	(credit_out_xpos_dout),
		.channel_xpos_din 		(channel_xpos_din),

		.credit_out_ypos_dout	(credit_out_ypos_dout),
		.channel_ypos_din 		(channel_ypos_din),

		.credit_out_xneg_dout	(credit_out_xneg_dout),
		.channel_xneg_din 		(channel_xneg_din),

		.credit_out_yneg_dout 	(credit_out_yneg_dout),
		.channel_yneg_din 		(channel_yneg_din),

		.credit_out_pe_dout		(credit_out_pe_dout),
		.channel_pe_din 		(channel_pe_din),

	// -- puertos de salida -------------------------------------- >>>>>
		.credit_in_xpos_din		(credit_in_xpos_din),
		.channel_xpos_dout 		(channel_xpos_dout),
		
		.credit_in_ypos_din		(credit_in_ypos_din),
		.channel_ypos_dout		(channel_ypos_dout),

		.credit_in_xneg_din		(credit_in_xneg_din),
		.channel_xneg_dout		(channel_xneg_dout),

		.credit_in_yneg_din		(credit_in_yneg_din),
		.channel_yneg_dout		(channel_yneg_dout),

		.credit_in_pe_din		(credit_in_pe_din),
		.channel_pe_dout		(channel_pe_dout)
    );
*/
