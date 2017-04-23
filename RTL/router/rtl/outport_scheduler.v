`timescale 1ns / 1ps

/*
-- Module Name:	Outport Scheduler

-- Description:	Top Level del Planificador de Salida. El modulo se 
				encarga de administrar el proceso de asignacion de 
				uso de puertos de salida. En el rse reciben peticiones
				desde de los puertos de entrada (lnk controller). Se
				ejecuta un proceso de arbitraje para decidir la peticion 
				ganadora.

				Con una peticion ganadora se procede a crear un enlace 
				entre el puerto de entrada y el puerto de salida por
				medio de Crossbar del sistema (xbar_conf_vector_dout).

				Una vez terminada una transferencia de paquete entre 
				entrada/salida, el modulo cierra el enlace y queda a la 
				espera de una nueva peticion.


-- Dependencies:	-- system.vh
					-- outport_scheduler_control_unit.v
					-- arbiter.v



-- Parameters:		

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- Creacion 06 de Junio 2015
*/
`include "system.vh"



module outport_scheduler 	#(
								parameter PORT_DIR = `X_POS
							)
	(
		input wire clk,
		input wire reset,

	// -- inputs ------------------------------------------------- >>>>>
		input wire  [3:0]	port_request_din,
		input wire 			credit_in_din,

	// -- outputs ------------------------------------------------ >>>>>
		output wire [3:0]	transfer_strobe_vector_dout,
		output wire [3:0]	xbar_conf_vector_dout,
		output wire 		port_status_dout		
    );


// -- Definicion de parametros locales --------------------------- >>>>>

	localparam PORT_BUSY = 1'b0;
	localparam PORT_IDLE = 1'b1;




/*
-- Instancia :: Unidad de Control del Planificador de Salida

-- Descripcion:	Implementacion de maquina de estado para el control de
				la recepcion de peticiones desde puertos de entrada, 
				asignacion de uso de puerto de salida, creacion de 
				enlace entre puerto de entrada y puerto de salida, y 
				cierre de enlace. 
*/

// -- Unidad de Control del Planificador de Salida --------------- >>>>>
	wire transfer_strobe;
	wire arbiter_strobe;
	wire clear_arbiter;
	wire zero_credits;

	wire any_request;

	assign any_request = |port_request_din;

	outport_scheduler_control_unit	
		#(
			.PORT_DIR(PORT_DIR)
		)
	unidad_de_control_planificador_salida
		(
			.clk					(clk),
			.reset 					(reset),

		// -- inputs --------------------------------------------- >>>>>
			.any_request_din 		(any_request),
			.credit_in_din			(credit_in_din),

		// -- outputs -------------------------------------------- >>>>>
			.zero_credits_dout		(zero_credits),
			.transfer_strobe_dout 	(transfer_strobe),
			.arbiter_strobe_dout 	(arbiter_strobe),
			.clear_arbiter_dout 	(clear_arbiter)
	    );



/*
-- Instancia :: Arbitro

-- Descripcion:	Implementacion de algoritmo de arbitraje entre  4 
				peticiones de uso de puerto de salida. (Round Robin).
*/

	// -- Arbitro de Planificador de Salida ---------------------- >>>>>
		arbiter 	rra_allocator
			(
				.clk					(clk),

			// -- inputs ----------------------------------------- >>>>>
				.port_request_din 		(port_request_din),
				.arbiter_strobe_din 	(arbiter_strobe),
				.clear_arbiter_din 		(clear_arbiter),

			// -- output ----------------------------------------- >>>>>
				.xbar_conf_vector_dout 	(xbar_conf_vector_dout)
		    );


	// -- Logica para Salidas del Planificador ------------------- >>>>>
		assign transfer_strobe_vector_dout 	= 	xbar_conf_vector_dout  & {4{transfer_strobe}};
		assign port_status_dout 			= 	(|xbar_conf_vector_dout || zero_credits)   ? PORT_BUSY : PORT_IDLE;


endmodule

/* -- Plantilla de Instancia ------------------------------------- >>>>>

outport_scheduler 	planificador_de_salida
	(
		.clk 							(clk),
		.reset 							(reset),

	// -- inputs ------------------------------------------------- >>>>>
		.port_request_din 				(port_request_din),
		.credit_in_din 					(credit_in_din),

	// -- outputs ------------------------------------------------ >>>>>
		.transfer_strobe_vector_dout 	(transfer_strobe_vector_dout),
		.port_status_dout 				(port_status_dout),
		.xbar_conf_vector_dout 			(xbar_conf_vector_dout)
    );

*/