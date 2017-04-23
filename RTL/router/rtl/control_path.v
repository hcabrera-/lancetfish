`timescale 1ns / 1ps

/*
-- Module Name:	Control Path

-- Description:	Modulo top level para el camino de control de un router.
				Instancia a los modulos 'control de enlace' y 
				'planificador de salida'.

				Ademas de los modulos mencionados, en este archivo se
				encuentra el desglose necesario de señales y la
				interconexion de los modulos.


-- Dependencies:	-- system.vh
					-- link_controller.v 	x 4
					-- outport_scheduler.v 	x 4


-- Parameters:		-- X_LOCAL:		Direccion en dimension "x" del nodo 
									en la red.
					-- Y_LOCAL:		Direccion en dimension "y" del nodo 
									en la red.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	** Esta pendiente arreglar los indices de las señales 
			   'input_channel_xxxx_din'	y 'buffer_xxxx_din'

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 10 de Junio 2015: 	* actualizacion de instancia de link 
							  controllers.

							* se agregan puerto para recibir el campo
							  'destino' del flit de cabecera desde las
							  colas de almacenamiento temporal del
							  datapath
*/
`include "system.vh"


module control_path		#(
							parameter 	X_LOCAL 	= 2,
							parameter	Y_LOCAL 	= 2,
							parameter 	X_WIDTH 	= 2,
							parameter 	Y_WIDTH		= 2	
						)
	(
		input wire clk,
		input wire reset,

	// -- segmentos de puertos de entrada ------------------------ >>>>>
		output wire			credit_out_xpos_dout,
		input wire [31:24]	input_channel_xpos_din,
		input wire [29:24]	buffer_xpos_din,
		input wire 			done_buffer_xpos_din,

		output wire			credit_out_ypos_dout,
		input wire [31:24]	input_channel_ypos_din,
		input wire [29:24]	buffer_ypos_din,
		input wire 			done_buffer_ypos_din,

		output wire			credit_out_xneg_dout,
		input wire [31:24]	input_channel_xneg_din,
		input wire [29:24]	buffer_xneg_din,
		input wire 			done_buffer_xneg_din,

		output wire			credit_out_yneg_dout,
		input wire [31:24]	input_channel_yneg_din,
		input wire [29:24]	buffer_yneg_din,
		input wire 			done_buffer_yneg_din,

		output wire			credit_out_pe_dout,
		input wire [31:24]	input_channel_pe_din,
		input wire [29:24]	buffer_pe_din,
		input wire 			done_buffer_pe_din,

	// -- puertos de recepcion de creditos ----------------------- >>>>>
		input wire 			credit_in_xpos_din,
		input wire 			credit_in_ypos_din,
		input wire 			credit_in_xneg_din,
		input wire 			credit_in_yneg_din,
		input wire 			credit_in_pe_din,

	// -- señales de salida a camino de datos -------------------- >>>>>
		output wire [4:0]	write_strobe_dout,
		output wire [4:0]	read_strobe_dout,

		output wire [3:0]	xbar_conf_vector_xpos_dout,
		output wire [3:0]	xbar_conf_vector_ypos_dout,
		output wire [3:0]	xbar_conf_vector_xneg_dout,
		output wire [3:0]	xbar_conf_vector_yneg_dout,
		output wire [3:0]	xbar_conf_vector_pe_dout

    );


// -- Parametros locales ----------------------------------------- >>>>>
	localparam 	X_ADDR = clog2(X_WIDTH);
	localparam 	Y_ADDR = clog2(Y_WIDTH);





/*
-- Instancia :: Controladores de Enlace

-- Descripcion:	Modulo para la administracion de paquetes entrando al
				router. Se encarga de la recepcion de paquetes, 
				solicitud del uso de un puerto de salida y de la 
				transferencia de paquetes recibidos al puerto de salida 
				destino.

				Cada instancia de este modulo esta ligada a un puerto 
				de entrada y a una cola de almacenamiento.

				La negociacion de recursos se lleva  a cabo con los 
				modulos "planificador de salida".
*/


// -- Link Controllers ------------------------------------------- >>>>>

	/*
	-- 	Las señales son agrupadas en vectores para poder hacer el enlace
		entre puertos dentro de los ciclos Generate.
	*/

	// -- Desglose de Señales ------------------------------------ >>>>>

		// -- Entrada :: Campo header de Flit de Cabecera -------- >>>>>
			wire [4:0]	header_field;

			assign header_field[`X_POS] = input_channel_xpos_din[31];
			assign header_field[`Y_POS] = input_channel_ypos_din[31];
			assign header_field[`X_NEG] = input_channel_xneg_din[31];
			assign header_field[`Y_NEG] = input_channel_yneg_din[31];
			assign header_field[`PE] 	= input_channel_pe_din  [31];
	
		// -- Entrada :: Campo done de Flit de Cabecera ---------- >>>>>
			wire [4:0]	done_field;

			assign done_field[`X_POS] 	= input_channel_xpos_din[30];
			assign done_field[`Y_POS] 	= input_channel_ypos_din[30];
			assign done_field[`X_NEG] 	= input_channel_xneg_din[30];
			assign done_field[`Y_NEG] 	= input_channel_yneg_din[30];
			assign done_field[`PE] 		= input_channel_pe_din  [30];

		// -- Entrada :: Campo done desde Buffer ----------------- >>>>>
			wire [4:0]	done_buffer;

			assign done_buffer[`X_POS] 	= done_buffer_xpos_din;
			assign done_buffer[`Y_POS] 	= done_buffer_ypos_din;
			assign done_buffer[`X_NEG] 	= done_buffer_xneg_din;
			assign done_buffer[`Y_NEG] 	= done_buffer_yneg_din;
			assign done_buffer[`PE] 	= done_buffer_pe_din;

		// -- Entrada :: Campo destino X de Flit de Cabecera ----- >>>>>
			wire [`ADDR_FIELD-1:0]	x_field [4:0];

			assign x_field[`X_POS] = input_channel_xpos_din[29-:`ADDR_FIELD];
			assign x_field[`Y_POS] = input_channel_ypos_din[29-:`ADDR_FIELD];
			assign x_field[`X_NEG] = input_channel_xneg_din[29-:`ADDR_FIELD];
			assign x_field[`Y_NEG] = input_channel_yneg_din[29-:`ADDR_FIELD];
			assign x_field[`PE]    = input_channel_pe_din  [29-:`ADDR_FIELD];

		// -- Entrada :: Campo destino Y de Flit de Cabecera ----- >>>>>
			wire [`ADDR_FIELD-1:0]	y_field [4:0];

			assign y_field[`X_POS] = input_channel_xpos_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_field[`Y_POS] = input_channel_ypos_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_field[`X_NEG] = input_channel_xneg_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_field[`Y_NEG] = input_channel_yneg_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_field[`PE]    = input_channel_pe_din  [(29-`ADDR_FIELD)-:`ADDR_FIELD];

		// -- Entrada :: Campo destino X desde Buffer ------------ >>>>>
			wire [`ADDR_FIELD-1:0]	x_buffer [4:0];

			assign x_buffer[`X_POS] = buffer_xpos_din[29-:`ADDR_FIELD];
			assign x_buffer[`Y_POS] = buffer_ypos_din[29-:`ADDR_FIELD];
			assign x_buffer[`X_NEG] = buffer_xneg_din[29-:`ADDR_FIELD];
			assign x_buffer[`Y_NEG] = buffer_yneg_din[29-:`ADDR_FIELD];
			assign x_buffer[`PE]    = buffer_pe_din  [29-:`ADDR_FIELD];

		// -- Entrada :: Campo destino Y desde Buffer ------------ >>>>>
			wire [`ADDR_FIELD-1:0]	y_buffer [4:0];

			assign y_buffer[`X_POS] = buffer_xpos_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_buffer[`Y_POS] = buffer_ypos_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_buffer[`X_NEG] = buffer_xneg_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_buffer[`Y_NEG] = buffer_yneg_din[(29-`ADDR_FIELD)-:`ADDR_FIELD];
			assign y_buffer[`PE]    = buffer_pe_din  [(29-`ADDR_FIELD)-:`ADDR_FIELD];

		
		// -- Salida :: Señal transfer strobe -------------------- >>>>>
			wire [4:0]	transfer_strobe;

		// -- Salida :: Señal credit add out --------------------- >>>>>
			wire [4:0]	credit_out;										// +1
			
			assign credit_out_xpos_dout = credit_out[`X_POS];
			assign credit_out_ypos_dout = credit_out[`Y_POS];
			assign credit_out_xneg_dout = credit_out[`X_NEG];
			assign credit_out_yneg_dout = credit_out[`Y_NEG];
			assign credit_out_pe_dout   = credit_out[`PE];				// PE

		// -- Salida :: Señal request vector --------------------- >>>>>
			wire [3:0]	request_vector [4:0]; 							// +1


	// -- Intancias :: Link Controller --------------------------- >>>>>
		genvar index;
		
		generate

			for (index = `X_POS; index < (`PE + 1); index=index + 1) 
				begin: link_controller
					link_controller	
						#(	
							.PORT_DIR	(index),
							.X_LOCAL	(X_LOCAL),
							.Y_LOCAL	(Y_LOCAL),
							.X_WIDTH	(X_WIDTH),
							.Y_WIDTH	(Y_WIDTH)
						)
					controlador_de_enlace
						(
							.clk	(clk),
							.reset 	(reset),
						
						// -- input ------------------------------ >>>>>
							.transfer_strobe_din(transfer_strobe[index]),

							.header_field_din	(header_field[index]),

							.done_field_din		(done_field[index]),
							.done_buffer_din	(done_buffer[index]),
							

							.x_field_din		(x_field[index]),
							.y_field_din		(y_field[index]),

							.x_buffer_din		(x_buffer[index]),
							.y_buffer_din		(y_buffer[index]),
							
						
						// -- output ----------------------------- >>>>>
							.write_strobe_dout	(write_strobe_dout[index]),
							.read_strobe_dout	(read_strobe_dout[index]),

							.credit_out_dout	(credit_out[index]),
							
							.request_vector_dout(request_vector[index])
					    );
				end
		endgenerate






/*
-- Instancia :: Selector

-- Descripcion:	Modulo de filtrado de peticiones. El uso de algoritmos 
				adaptativos o parcialmente adaptativos ofrece varios
				caminos para dar salida a un paquete, sin embargo la 
				ejecucion de multiples peticiones produce resultados 
				impredecibles: duplicacion de paquetes, paquetes 
				corruptos, etc.

				Los modulos 'selector' solo permiten la salida de una 
				peticion por ciclo de reloj (por puerto de salida).
*/

// -- Selector de Peticiones ------------------------------------- >>>>>

	// -- Desglose de Señales ------------------------------------ >>>>>

		// -- Entrada :: Status Register ------------------------- >>>>>
		// -- Nota :: 	PSR esta modelado como una memoria pero debe de 
		// --			inferir registros (memoria distribuida).
			wire [3:0]	port_status_register [4:0];

		// -- Salida :: Vector de Solicitudes Acotado ------------ >>>>>
			wire [3:0]	masked_request_vector [4:0];

	// -- Instancias :: Selector --------------------------------- >>>>>
		generate

			for (index = `X_POS; index < (`PE + 1); index=index + 1)
				begin: selectores
						selector 
							#(
								.PORT_DIR 	(index)
							)
						selector
							(
							// -- inputs ------------------------- >>>>>
								.request_vector_din 		(request_vector[index]),
								.transfer_strobe_din 		(transfer_strobe[index]),
								.status_register_din 		(port_status_register[index]),

							// -- outputs ------------------------ >>>>>
								.masked_request_vector_dout (masked_request_vector[index])
						    );
				end
		endgenerate






/*
-- Descripcion:	Cada puerto de salida solo puede recibir peticiones de 
				puertos de entrada opuestos a el. 

				Ej: Puerto de salida 'x+' solo puede recibir peticiones
				de los puertos {pe, y+, x-, y-}. Las lineas de codigo 
				a continuacion reparten peticiones a sus repestectivos 
				'planificadores de salida'.
*/

// -- Distribucion de Peticiones por Puerto ---------------------- >>>>>
	wire [3:0] request_to_port [4:0];


		assign request_to_port[`X_POS] = 	{	
												masked_request_vector[`Y_NEG][`YNEG_XPOS],
												masked_request_vector[`X_NEG][`XNEG_XPOS],
												masked_request_vector[`Y_POS][`YPOS_XPOS],
												masked_request_vector[`PE][`PE_XPOS]
											};

		assign request_to_port[`Y_POS] = 	{	
												masked_request_vector[`Y_NEG][`YNEG_YPOS],
												masked_request_vector[`X_NEG][`XNEG_YPOS],
												masked_request_vector[`X_POS][`XPOS_YPOS],
												masked_request_vector[`PE][`PE_YPOS]
											};

		assign request_to_port[`X_NEG] = 	{	
												masked_request_vector[`Y_NEG][`YNEG_XNEG],
												masked_request_vector[`Y_POS][`YPOS_XNEG],
												masked_request_vector[`X_POS][`XPOS_XNEG],
												masked_request_vector[`PE][`PE_XNEG]
											};

		assign request_to_port[`Y_NEG] = 	{	
												masked_request_vector[`X_NEG][`XNEG_YNEG],
												masked_request_vector[`Y_POS][`YPOS_YNEG],
												masked_request_vector[`X_POS][`XPOS_YNEG],
												masked_request_vector[`PE][`PE_YNEG]
											};

		assign request_to_port[`PE] = 		{	
												masked_request_vector[`Y_NEG][`YNEG_PE],
												masked_request_vector[`X_NEG][`XNEG_PE],
												masked_request_vector[`Y_POS][`YPOS_PE],
												masked_request_vector[`X_POS][`XPOS_PE]
											};	

// -- Planificador de Salida ------------------------------------- >>>>>
	// -- Desglose de Señales ------------------------------------ >>>>>
			// -- Entrada :: credit add in ----------------------- >>>>>
				wire [4:0]	credit_in;									// +1 

				assign credit_in[`X_POS] = credit_in_xpos_din;
				assign credit_in[`Y_POS] = credit_in_ypos_din;
				assign credit_in[`X_NEG] = credit_in_xneg_din;
				assign credit_in[`Y_NEG] = credit_in_yneg_din;
				assign credit_in[`PE]    = credit_in_pe_din; 			// PE

				// -- Salida :: vector de configuracion de crossbar ------ >>>>>
					wire [3:0] xbar_conf_vector [4:0]; 					// +1

				// -- Salida :: vector de pulso de transferencia --------- >>>>>
					wire [3:0] transfer_strobe_vector [4:0]; 			// +1

				// -- Salida :: bits del registro de estado de puertos --- >>>>>
					wire [4:0] status_register;



	// -- Instancias :: Planificador de Salida --------------------------- >>>>>
		generate

			for (index = `X_POS; index < (`PE + 1); index=index + 1)
				begin: output_scheduler
					
					outport_scheduler 	
						#(
							.PORT_DIR(index)
						)
					planificador_de_salida
						(
							.clk							(clk),
							.reset 							(reset),

						// -- inputs ------------------------------------- >>>>>
							.port_request_din				(request_to_port[index]),
							.credit_in_din 					(credit_in[index]),

						// -- outputs ------------------------------------ >>>>>
							.transfer_strobe_vector_dout	(transfer_strobe_vector[index]),
							.port_status_dout				(status_register[index]),
							.xbar_conf_vector_dout 			(xbar_conf_vector[index])
					    );

				end
		endgenerate


	// -- Asignador de vectores de configuracion para crossbar ----------- >>>>>
		assign xbar_conf_vector_xpos_dout = xbar_conf_vector[`X_POS];
		assign xbar_conf_vector_ypos_dout = xbar_conf_vector[`Y_POS];
		assign xbar_conf_vector_xneg_dout = xbar_conf_vector[`X_NEG];
		assign xbar_conf_vector_yneg_dout = xbar_conf_vector[`Y_NEG];
		assign xbar_conf_vector_pe_dout   = xbar_conf_vector[`PE];



	// -- Distribucion de Bits de estado de puerto ----------------------- >>>>>
		assign port_status_register[`X_POS] = 	{
													status_register[`Y_NEG],
													status_register[`X_NEG],
													status_register[`Y_POS],
													status_register[`PE]
												};

		assign port_status_register[`Y_POS] = 	{
													status_register[`Y_NEG],
													status_register[`X_NEG],
													status_register[`X_POS],
													status_register[`PE]
												};

		assign port_status_register[`X_NEG] = 	{
													status_register[`Y_NEG],
													status_register[`Y_POS],
													status_register[`X_POS],
													status_register[`PE]
												};

		assign port_status_register[`Y_NEG] = 	{
													status_register[`X_NEG],
													status_register[`Y_POS],
													status_register[`X_POS],
													status_register[`PE]
												};

		assign port_status_register[`PE] = 	{
													status_register[`Y_NEG],
													status_register[`X_NEG],
													status_register[`Y_POS],
													status_register[`X_POS]
												};



	// --	Distribucion de Señales Transfer Strobe ---------------------- >>>>>
		assign transfer_strobe[`X_POS] = 	transfer_strobe_vector[`Y_POS][`YPOS_XPOS]	|
											transfer_strobe_vector[`X_NEG][`XNEG_XPOS]	|
											transfer_strobe_vector[`Y_NEG][`YNEG_XPOS]	|
											transfer_strobe_vector[`PE][`PE_XPOS];

		assign transfer_strobe[`Y_POS] = 	transfer_strobe_vector[`X_POS][`XPOS_YPOS]	|
											transfer_strobe_vector[`X_NEG][`XNEG_YPOS]	|
											transfer_strobe_vector[`Y_NEG][`YNEG_YPOS]	|
											transfer_strobe_vector[`PE][`PE_YPOS];

		assign transfer_strobe[`X_NEG] = 	transfer_strobe_vector[`X_POS][`XPOS_XNEG]	|
											transfer_strobe_vector[`Y_POS][`YPOS_XNEG]	|
											transfer_strobe_vector[`Y_NEG][`YNEG_XNEG]	|
											transfer_strobe_vector[`PE][`PE_XNEG];

		assign transfer_strobe[`Y_NEG] = 	transfer_strobe_vector[`X_POS][`XPOS_YNEG]	|
											transfer_strobe_vector[`Y_POS][`YPOS_YNEG]	|
											transfer_strobe_vector[`X_NEG][`XNEG_YNEG]	|
											transfer_strobe_vector[`PE][`PE_YNEG];

		assign transfer_strobe[`PE] 	= 	transfer_strobe_vector[`X_POS][`XPOS_PE]	|
											transfer_strobe_vector[`Y_POS][`YPOS_PE]	|
											transfer_strobe_vector[`X_NEG][`XNEG_PE]	|
											transfer_strobe_vector[`Y_NEG][`YNEG_PE];		
											







// -- Codigo no sintetizable ------------------------------------- >>>>>

	// -- Funciones ---------------------------------------------- >>>>>

			//  Funcion de calculo: log2(x) ---------------------- >>>>>
			function integer clog2;
				input integer depth;
					for (clog2=0; depth>0; clog2=clog2+1)
						depth = depth >> 1;
			endfunction



endmodule


/* -- Plantilla de Instancia ------------------------------------- >>>>>
control_path	
	#(
		.X_LOCAL	(X_LOCAL), 
		.Y_LOCAL	(Y_LOCAL)
	)
camino_de_control
	(
		.clk	(clk),
		.reset 	(reset),

	// -- segmentos de puertos de entrada ------------------------ >>>>>
		.credit_out_xpos_dout		(credit_out_xpos_dout),
		.input_channel_xpos_din		(input_channel_xpos_din),
		.buffer_xpos_din			(buffer_xpos_din),
		.done_buffer_xpos_din		(done_buffer_xpos_din),

		.credit_out_ypos_dout		(credit_out_ypos_dout),
		.input_channel_ypos_din		(input_channel_ypos_din),
		.buffer_ypos_din			(buffer_ypos_din),
		.done_buffer_ypos_din		(done_buffer_ypos_din),

		.credit_out_xneg_dout		(credit_out_xneg_dout),
		.input_channel_xneg_din		(input_channel_xneg_din),
		.buffer_xneg_din			(buffer_xneg_din),
		.done_buffer_xneg_din		(done_buffer_xneg_din),

		.credit_out_yneg_dout		(credit_out_yneg_dout),
		.input_channel_yneg_din		(input_channel_yneg_din),
		.buffer_yneg_din			(buffer_yneg_din),
		.done_buffer_yneg_din		(done_buffer_yneg_din),

		.credit_out_pe_dout			(credit_out_pe_dout),
		.input_channel_pe_din		(input_channel_pe_din),
		.buffer_pe_din				(buffer_pe_din),
		.done_buffer_pe_din			(done_buffer_pe_din),

	// -- puertos de recepcion de creditos ----------------------- >>>>>
		.credit_in_xpos_din			(credit_in_xpos_din),
		.credit_in_ypos_din			(credit_in_ypos_din),
		.credit_in_xneg_din			(credit_in_xneg_din),
		.credit_in_yneg_din			(credit_in_yneg_din),
		.credit_in_pe_din			(credit_in_pe_din),

	// -- señales de salida a camino de datos -------------------- >>>>>
		.write_strobe_dout			(write_strobe_dout),
		.read_strobe_dout			(read_strobe_dout),

		.xbar_conf_vector_xpos_dout	(xbar_conf_vector_xpos_dout),
		.xbar_conf_vector_ypos_dout	(xbar_conf_vector_ypos_dout),
		.xbar_conf_vector_xneg_dout	(xbar_conf_vector_xneg_dout),
		.xbar_conf_vector_yneg_dout	(xbar_conf_vector_yneg_dout),
		.xbar_conf_vector_pe_dout	(xbar_conf_vector_pe_dout)

    );
    */