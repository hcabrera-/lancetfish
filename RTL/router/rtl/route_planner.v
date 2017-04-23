`timescale 1ns / 1ps

/*
-- Module Name:	Route Planner
-- Description:	Wrapper de algoritmo de planificacion de ruta
				
				"Wrapper" alrededor del algoritmo a utilizar para el 
				calculo de la ruta a seguir para el paquete en transito.

				Forma parte del modulo "Link Controller".

-- Dependencies:	-- system.vh
					-- modulo de algoritmo de planificacion de ruta:
						-- router_west_first_minimal.v

-- Parameters:		-- PORT_DIR: 	Direccion del puerto de entrada
									conectado a este modulo {x+, y+
									x-, y-}.
					-- X_LOCAL:		Direccion en dimension "x" del nodo 
									en la red.
					-- Y_LOCAL:		Direccion en dimension "y" del nodo 
									en la red.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
	(05/06/2015): 	El "wrapper" no agrega la peticion a PE. Actualmente
					el algoritmo de prueba West First Minimal recibe el
					campo done_field y agrega la paeticion a PE, cuando
					esta tarea la deberia llevar a cabo el wrapper.
							

-- History:	
	-- Creacion 05 de Junio 2015
*/
`include "system.vh"


module route_planner	#(
							parameter 	PORT_DIR	= `X_POS,
							parameter 	X_LOCAL 	= 1,
						  	parameter	Y_LOCAL 	= 1,
						  	parameter 	ALGO 		= "",
						  	parameter 	X_WIDTH 	= 2,
							parameter 	Y_WIDTH		= 2	
						)

	(
	// -- inputs ------------------------------------------------- >>>>>
		input wire 						done_field_din,

		input wire  [`ADDR_FIELD-1:0]	x_field_din,
		input wire  [`ADDR_FIELD-1:0]	y_field_din,

	// -- outputs ------------------------------------------------ >>>>>
		output wire [3:0]				request_vector_dout

    );



/*
-- Instancia :: Algoritmo de calculo re ruta (routing)

-- Descripcion: Instancia del algoritmo de planificacion de ruta para el 
				router actual. 

				En caso de utilizar un algoritmo adaptativo o 
				parcialmente adaptativo es forsozo el uso de los modulos 
				"selector" para	dar prioridad a solo una paticion por 
				ronda de arbitraje.
*/

wire [3:0] valid_channels;

	generate
		if (ALGO == "XY")
			begin
					// -- Algoritmo de Enrutamiento :: Modified YX - >>>
					dor_xy
						#(	.PORT_DIR 	(PORT_DIR), 
							.X_LOCAL	(X_LOCAL), 
							.Y_LOCAL	(Y_LOCAL),
							.X_WIDTH	(X_WIDTH),
							.Y_WIDTH	(Y_WIDTH)
						)
					dor_xy
						(
							// -- inputs ------------------------- >>>>>
								.done_field_din	(done_field_din),
								.x_field_din	(x_field_din),
								.y_field_din	(y_field_din),

							// -- outputs ------------------------ >>>>>
								.valid_channels_dout 	(valid_channels)
						);
			end
		else
			begin
				// -- Algoritmo de Enrutamiento :: West First Minimal >>
					west_first_minimal
						#(	
							.PORT_DIR	(PORT_DIR), 
							.X_LOCAL	(X_LOCAL), 
							.Y_LOCAL	(Y_LOCAL),
							.X_WIDTH	(X_WIDTH),
							.Y_WIDTH	(Y_WIDTH)
						)
					west_first_minimal
						(
							// -- inputs ------------------------- >>>>>
								.done_field_din	(done_field_din),
								.x_field_din	(x_field_din),
								.y_field_din	(y_field_din),

							// -- outputs ------------------------ >>>>>
								.valid_channels_dout	(valid_channels)
						);
			end
	endgenerate




/*

-- Nota: 	El algoritmo de planificacion de ruta modificado. De manera 
			tradicional, un paquete de una NoC busca entrar a un 
			elemento de procesamiento hasta alcanzar una direccion 
			objetivo de la red.

			En este diseño, los paquetes buscan una direccion destino,
			sin embargo, solicitan el ingreso al primer elemento de 
			procesamiento disponible en el camino.

			Se utiliza el campo "done_field_din" del paquete de 
			cabecera para activar la peticion al PE.

			La implementacion actual adjunta la peticion de entrada 
			"done_field_din" a un PE en el modulo del algoritmo de 
			encaminamiento, sin embargo este deberia ser agregado en 
			este modulo(wrapper), para hacer este cambio se debe de 
			modificar el modulo de enrutamiento y agregar la siguiente 
			linea:
			
				assign request_vector_dout =   {done_field_din, 
												valid_channels};

			y retirar la linea:

				assign request_vector_dout = valid_channels;
*/

	// -- Anexo de peticion a PE --------------------------------- >>>>>
		assign request_vector_dout = valid_channels;









// -- Codigo no sintetizable ------------------------------------- >>>>>

	// -- Simbolos de Despuracion -------------------------------- >>>>>
	reg [(16*8)-1:0]	valid_channels_dbg;


	always @(*)
	// -- Route Planner :: LC | PE ------------------------------- >>>>>
		if (PORT_DIR == `PE)
			begin
				valid_channels_dbg[127-:32] = 	(valid_channels[`PE_XPOS]) 	?
													"X+, "	: "    ";

				valid_channels_dbg[95-:32]  = 	(valid_channels[`PE_YPOS]) 	?
													"Y+, "	: "    ";

				valid_channels_dbg[63-:32]  = 	(valid_channels[`PE_XNEG]) 	?
													"X-, "	: "    ";

				valid_channels_dbg[31 :0]   = 	(valid_channels[`PE_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | X+ ------------------------------- >>>>>
		else if(PORT_DIR == `X_POS)
			begin
				valid_channels_dbg[127-:32] = 	(valid_channels[`XPOS_PE]) 		?
													"PE, "	: "    ";

				valid_channels_dbg[95-:32]  = 	(valid_channels[`XPOS_YPOS]) 	?
													"Y+, "	: "    ";

				valid_channels_dbg[63-:32]  = 	(valid_channels[`XPOS_XNEG]) 	?
													"X-, "	: "    ";

				valid_channels_dbg[31 :0]   = 	(valid_channels[`XPOS_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | Y+ ------------------------------- >>>>>
		else if(PORT_DIR == `Y_POS)
			begin
				valid_channels_dbg[127-:32] = 	(valid_channels[`YPOS_PE]) 		?
													"PE, "	: "    ";

				valid_channels_dbg[95-:32]  = 	(valid_channels[`YPOS_XPOS]) 	?
													"X+, "	: "    ";

				valid_channels_dbg[63-:32]  = 	(valid_channels[`YPOS_XNEG]) 	?
													"X-, "	: "    ";

				valid_channels_dbg[31 :0]   = 	(valid_channels[`YPOS_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | X- ------------------------------- >>>>>
		else if(PORT_DIR == `X_NEG)
			begin
				valid_channels_dbg[127-:32] = 	(valid_channels[`XNEG_PE]) 		?
													"PE, "	: "    ";

				valid_channels_dbg[95-:32]  = 	(valid_channels[`XNEG_XPOS]) 	?
													"X+, "	: "    ";

				valid_channels_dbg[63-:32]  = 	(valid_channels[`XNEG_YPOS]) 	?
													"Y+, "	: "    ";

				valid_channels_dbg[31 :0]   = 	(valid_channels[`XNEG_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | Y- ------------------------------- >>>>>
		else if(PORT_DIR == `Y_NEG)
			begin
				valid_channels_dbg[127-:32] = 	(valid_channels[`YNEG_PE]) 		?
													"PE, "	: "    ";

				valid_channels_dbg[95-:32]  = 	(valid_channels[`YNEG_XPOS]) 	?
													"X+, "	: "    ";

				valid_channels_dbg[63-:32]  = 	(valid_channels[`YNEG_YPOS]) 	?
													"Y+, "	: "    ";

				valid_channels_dbg[31 :0]   = 	(valid_channels[`YNEG_XNEG]) 	?
													"X-, "	: "    ";							
			end


endmodule



/* -- Plantilla de Instancia ------------------------------------- >>>>>
wire [3:0]	request_vector;

route_planner	
	#(
		.PORT_DIR	(`X_POS),
		.X_LOCAL	(X_LOCAL),
	  	.Y_LOCAL	(Y_LOCAL),
	  	.X_WIDTH	(X_WIDTH),
		.Y_WIDTH	(Y_WIDTH)
	)
route_planner
	(

	// -- inputs ------------------------------------------------- >>>>>
		.done_field_din	(done_field_din),

		.x_field_din	(x_field_din),
		.y_field_din	(y_field_din),

	// -- outputs ------------------------------------------------ >>>>>
		.request_vector_dout	(request_vector)
    );

*/