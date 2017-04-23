`timescale 1ns / 1ps

/*
-- Module Name:	Link Controller

-- Description:	Control de enlace de entrada. Una instancia de este 
				modulo esta ligada a cada puerto de entrada del router
				con excepcion del puerto del elemento de procesamiento.
				
				Sus tareas son: 
					Recepcion de nuevos paquetes al router. Para cada
					paquete el modulo Link Controller inicia el proceso 
					de solicitud de un puerto de salida. Ademas se 
					encarga de almacenar los flits de un paquete en el 
					buffer asociado al puerto de entrada donde se 
					encuentra.

					Una vez obtenido el permiso de uso de un puerto de 
					salida, envia todos los flits del paquete al puerto
					correspondiente.


				La negociacion del uso de un puerto de salida se lleva a
				a cabo con los modulos "Planificador de Salida".


-- Dependencies:	-- system.vh
					-- router_route_planner.v
						-- algoritmo de encaminamiento *
					-- router_link_controller_control_unit.v


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

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 10 de Junio 2015: 	* puerto de entrada 	-- x_buffer_din
							 					 	-- y_buffer_din

							* cambio en instancia de unidad de control.

							* se agrega mux para seleccionar entre 
							direccion {x,y} desde el canal de entrada o
							la cola de paquetes.
*/
`include "system.vh"


module link_controller	#(
							parameter 	PORT_DIR	= `X_POS,
							parameter 	X_LOCAL 	= 2,
						  	parameter	Y_LOCAL 	= 2,
						  	parameter 	X_WIDTH 	= 2,
							parameter 	Y_WIDTH		= 2	
						)
	(
		input wire clk,
		input wire reset,

	// -- input -------------------------------------------------- >>>>>
		input wire 	transfer_strobe_din,

		input wire 	header_field_din,

		input wire 	done_field_din,
		input wire 	done_buffer_din,

		input wire [`ADDR_FIELD-1:0]	x_field_din,
		input wire [`ADDR_FIELD-1:0]	y_field_din,

		input wire [`ADDR_FIELD-1:0]	x_buffer_din,
		input wire [`ADDR_FIELD-1:0]	y_buffer_din,
		
	// -- output ------------------------------------------------- >>>>>
		output wire 		write_strobe_dout,
		output wire 		read_strobe_dout,

		output wire 		credit_out_dout,

		output wire [3:0]	request_vector_dout	
    );








/*
-- Instancia :: Unidad de Control de Control de Enlace

-- Descripcion:	Implementacion de maquinas de estado para el control de
				las operaciones de recepcion denuevos paquetes y la 
				transferencia de paquetes a puertos de salida del 
				router. 
*/

	// -- Link Controller :: Unidad de Control (FSM) ------------- >>>>>
		wire routing_source;
		wire routing_strobe;

		link_controller_control_unit	unidad_de_control_LC
			(
				.clk	(clk),
				.reset 	(reset),

			// -- inputs ----------------------------------------- >>>>>
				.header_field_din	(header_field_din),
				.transfer_strobe_din(transfer_strobe_din),

			// -- outputs ---------------------------------------- >>>>>
				.write_strobe_dout	(write_strobe_dout),
				.read_strobe_dout	(read_strobe_dout),

				.routing_source_dout(routing_source),
				.routing_strobe_dout(routing_strobe),
				
				.credit_out_dout	(credit_out_dout)
		    );










/*
-- Instancia :: Planificador de Ruta

-- Descripcion:	Wrapper para algortimos de calculo de ruta. El wrapper
				incluye un multiplexor para la seleccion del origen de 
				la direccion del nodo destino. La direccion se puede
				obtener de manera directa de la slineas del canal de 
				entrada al router o de la salida de la cola de 
				almacenamiento de flits ligada al control de enlace.

				Los multiplexores descritos por medio de la señal
				"routing_source" selecciones si se tomaran los datos
				de ruteo desde el canal de entrada o desde el buffer
				de paquetes.
*/

	// -- Mux Selector de origen de direccion {x,y} -------------- >>>>>
		wire [`ADDR_FIELD-1:0]	x_addr;	
		wire [`ADDR_FIELD-1:0]	y_addr;

		assign x_addr = (routing_source) ?  x_buffer_din : x_field_din;
		assign y_addr = (routing_source) ?  y_buffer_din : y_field_din;

		wire done_tag;

		assign done_tag = (routing_source) ? done_buffer_din : done_field_din;

	// -- Planificador de Ruta ----------------------------------- >>>>>
		wire [3:0]	request_vector;

		route_planner	
			#(
				.PORT_DIR	(PORT_DIR),
				.X_LOCAL	(X_LOCAL),
			  	.Y_LOCAL	(Y_LOCAL),
			  	.X_WIDTH	(X_WIDTH),
				.Y_WIDTH	(Y_WIDTH)
			)
		route_planner
			(
			// -- inputs ----------------------------------------- >>>>>
				.done_field_din	(done_tag),
				
				.x_field_din	(x_addr),
				.y_field_din	(y_addr),

			// -- outputs ---------------------------------------- >>>>>
				.request_vector_dout	(request_vector)

		    );







/*
-- Registro

-- Descripcion:	Registro para el bloqueo de peticiones de puerto de
				salida para un paquete entrante. Este registro funciona
				la unica etapa de segmentado del router.
*/
	// -- Registro de Peticion en Curso -------------------------- >>>>>
		reg [3:0]	request_vector_reg = 4'h0;

		always @(posedge clk)
			if (transfer_strobe_din)
				request_vector_reg <= 4'h0;
			else 
				if (routing_strobe)
					request_vector_reg <= request_vector;
				

		assign request_vector_dout = request_vector_reg;










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

link_controller	
	#(	.PORT_DIR	(PORT_DIR),
		.X_LOCAL	(X_LOCAL),
		.Y_LOCAL	(Y_LOCAL),
		.X_WIDTH	(X_WIDTH),
		.Y_WIDTH	(Y_WIDTH)
	)
controlador_de_enlace
	(
		.clk	(clk),
		.reset 	(reset),

	// -- input -------------------------------------------------- >>>>>
		.transfer_strobe_din(transfer_strobe_din),

		.header_field_din	(header_field_din),
		
		.done_field_din		(done_field_din),
		.done_buffer_din	(done_buffer_din),

		.x_field_din		(x_field_din),
		.y_field_din		(y_field_din),

		.x_buffer_din		(x_buffer_din),
		.y_buffer_din		(y_buffer_din),
		
	// -- output ------------------------------------------------- >>>>>
		.write_strobe_dout	(write_strobe_dout),
		.read_strobe_dout	(read_strobe_dout),

		.credit_out_dout	(credit_out_dout),
		.request_vector_dout(request_vector_dout)
    );

*/