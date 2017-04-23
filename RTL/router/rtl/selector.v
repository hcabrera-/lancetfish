`timescale 1ns / 1ps

/*
-- Module Name:	Selector

-- Description:	Seleccion de peticion activa para este ciclo de reloj.
				El uso de algoritmos adaptativos o semi adaptativos 
				produce una o mas salidas validas para un paquete. Sin
				embargo la solicitud de dos o mas puertos de salida a la
				vez puede ocacionar dupliacion o liberacion de paquetes
				corruptos a la red.

				Este modulo recibe una o mas solicitudes para los 
				"planificadores de salida", pero solo permite la salida
				de una peticion a la vez.

				La seleccion de peticion activa depende de un esquema de
				prioridad y de la disponibilidad de puertos.


-- Dependencies:	-- system.vh


-- Parameters:		-- PORT_DIR: 	Direccion del puerto de entrada
									conectado a este modulo {x+, y+
									x-, y-}.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
		(05/06/2015) El esquema de prioridad utilizado es fijo, y otorga
		preferencia de salida en el siguiente orden {pe, x+, y+, x-, y-}

-- History:	
	-- Creacion 05 de Junio 2015
*/
`include "system.vh"

module selector 	#(
						parameter PORT_DIR = `X_POS
					)
	(
	// -- inputs ------------------------------------------------- >>>>>
		input wire [3:0]	request_vector_din,
		input wire 			transfer_strobe_din,
		input wire [3:0]	status_register_din,

	// -- outputs ------------------------------------------------ >>>>>
		output reg [3:0]	masked_request_vector_dout
    );



/*
-- 	Si se a aceptado una transferencia (transfer_strobe_din) se anula 
	toda peticion saliendo del selector.

	En caso contrario se aplica una primera etapa de enmascarado, donde 
	solo se permite pasar las peticiones de puertos que se encuentran 
	disponibles actualmente.
*/
	wire [3:0] masked_request;

	assign masked_request =  (transfer_strobe_din) 	?	{4{1'b0}}									:	
														request_vector_din & status_register_din;



/*
--	Segunda etapa de filtrado. En esta etapa se aplica un esquema de
	prioridad de peticion. El esquema es fijo y da prioridad en el 
	siguiente orden: {pe, x+, y+, x-, y-}

	El puerto de entrada ligado al "selector" determina que direcciones
	pueden recibir una peticion. Ej. El selector ligado al puerto x+ no
	puede emitir una solicitud a su misma direccion (x+). Solo uno de 
	los casos de abajo es sintetizado a la vez y es seleccionado por el 
	parametro: PORT_DIR.
*/


		always @(*)
			begin
				masked_request_vector_dout = 4'b0000;

			// -- Selector de Peticion puerto de entrada PE ------ >>>>>
				if (PORT_DIR == `PE)
					begin
						if (masked_request[`PE_XPOS])
							masked_request_vector_dout = 4'b0001;
						else if (masked_request[`PE_YPOS])
							masked_request_vector_dout = 4'b0010;
						else if (masked_request[`PE_XNEG])
							masked_request_vector_dout = 4'b0100;
						else if (masked_request[`PE_YNEG])
							masked_request_vector_dout = 4'b1000;
						else
							masked_request_vector_dout = 4'b0000;
					end //PORT_DIR == PE 


			// -- Selector de Peticion puerto de entrada X+ ------ >>>>>
				else if (PORT_DIR == `X_POS)
					begin
						if (masked_request[`XPOS_PE])
							masked_request_vector_dout = 4'b0001;
						else if (masked_request[`XPOS_YPOS])
							masked_request_vector_dout = 4'b0010;
						else if (masked_request[`XPOS_XNEG])
							masked_request_vector_dout = 4'b0100;
						else if (masked_request[`XPOS_YNEG])
							masked_request_vector_dout = 4'b1000;
						else
							masked_request_vector_dout = 4'b0000;
					end //PORT_DIR == X+


			// -- Selector de Peticion puerto de entrada Y+ ------ >>>>>
				else if (PORT_DIR == `Y_POS)
					begin
						if (masked_request[`YPOS_PE])
							masked_request_vector_dout = 4'b0001;
						else if (masked_request[`YPOS_XPOS])
							masked_request_vector_dout = 4'b0010;
						else if (masked_request[`YPOS_XNEG])
							masked_request_vector_dout = 4'b0100;
						else if (masked_request[`YPOS_YNEG])
							masked_request_vector_dout = 4'b1000;
						else
							masked_request_vector_dout = 4'b0000;
					end //PORT_DIR == Y+


			// -- Selector de Peticion puerto de entrada X- ------ >>>>>
				else if (PORT_DIR == `X_NEG)
					begin
						if (masked_request[`XNEG_PE])
							masked_request_vector_dout = 4'b0001;
						else if (masked_request[`XNEG_XPOS])
							masked_request_vector_dout = 4'b0010;
						else if (masked_request[`XNEG_YPOS])
							masked_request_vector_dout = 4'b0100;
						else if (masked_request[`XNEG_YNEG])
							masked_request_vector_dout = 4'b1000;
						else
							masked_request_vector_dout = 4'b0000;
					end //PORT_DIR == X-


			// -- Selector de Peticion puerto de entrada Y- ------ >>>>>
				else if (PORT_DIR == `Y_NEG)
					begin
						if (masked_request[`YNEG_PE])
							masked_request_vector_dout = 4'b0001;
						else if (masked_request[`YNEG_XPOS])
							masked_request_vector_dout = 4'b0010;
						else if (masked_request[`YNEG_YPOS])
							masked_request_vector_dout = 4'b0100;
						else if (masked_request[`YNEG_XNEG])
							masked_request_vector_dout = 4'b1000;
						else
							masked_request_vector_dout = 4'b0000;
					end //PORT_DIR == Y-
			end //*











// -- Codigo no sintetizable ------------------------------------- >>>>>


// -- Simbolos de Depuracion ------------------------------------- >>>>>
	reg [(16*8)-1:0]	masked_request_dbg;


	always @(*)
	// -- Route Planner :: LC | PE ------------------------------- >>>>>
		if (PORT_DIR == `PE)
			begin
				masked_request_dbg[127-:32] = 	(masked_request_vector_dout[`PE_XPOS]) 	?
													"X+, "	: "    ";

				masked_request_dbg[95-:32]  = 	(masked_request_vector_dout[`PE_YPOS]) 	?
													"Y+, "	: "    ";

				masked_request_dbg[63-:32]  = 	(masked_request_vector_dout[`PE_XNEG]) 	?
													"X-, "	: "    ";

				masked_request_dbg[31 :0]   = 	(masked_request_vector_dout[`PE_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | X+ ------------------------------- >>>>>
		else if(PORT_DIR == `X_POS)
			begin
				masked_request_dbg[127-:32] = 	(masked_request_vector_dout[`XPOS_PE]) 		?
													"PE, "	: "    ";

				masked_request_dbg[95-:32]  = 	(masked_request_vector_dout[`XPOS_YPOS]) 	?
													"Y+, "	: "    ";

				masked_request_dbg[63-:32]  = 	(masked_request_vector_dout[`XPOS_XNEG]) 	?
													"X-, "	: "    ";

				masked_request_dbg[31 :0]   = 	(masked_request_vector_dout[`XPOS_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | Y+ ------------------------------- >>>>>
		else if(PORT_DIR == `Y_POS)
			begin
				masked_request_dbg[127-:32] = 	(masked_request_vector_dout[`YPOS_PE]) 		?
													"PE, "	: "    ";

				masked_request_dbg[95-:32]  = 	(masked_request_vector_dout[`YPOS_XPOS]) 	?
													"X+, "	: "    ";

				masked_request_dbg[63-:32]  = 	(masked_request_vector_dout[`YPOS_XNEG]) 	?
													"X-, "	: "    ";

				masked_request_dbg[31 :0]   = 	(masked_request_vector_dout[`YPOS_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | X- ------------------------------- >>>>>
		else if(PORT_DIR == `X_NEG)
			begin
				masked_request_dbg[127-:32] = 	(masked_request_vector_dout[`XNEG_PE]) 		?
													"PE, "	: "    ";

				masked_request_dbg[95-:32]  = 	(masked_request_vector_dout[`XNEG_XPOS]) 	?
													"X+, "	: "    ";

				masked_request_dbg[63-:32]  = 	(masked_request_vector_dout[`XNEG_YPOS]) 	?
													"Y+, "	: "    ";

				masked_request_dbg[31 :0]   = 	(masked_request_vector_dout[`XNEG_YNEG]) 	?
													"Y-, "	: "    ";
			end

	// -- Route Planner :: LC | Y- ------------------------------- >>>>>
		else if(PORT_DIR == `Y_NEG)
			begin
				masked_request_dbg[127-:32] = 	(masked_request_vector_dout[`YNEG_PE]) 		?
													"PE, "	: "    ";

				masked_request_dbg[95-:32]  = 	(masked_request_vector_dout[`YNEG_XPOS]) 	?
													"X+, "	: "    ";

				masked_request_dbg[63-:32]  = 	(masked_request_vector_dout[`YNEG_YPOS]) 	?
													"Y+, "	: "    ";

				masked_request_dbg[31 :0]   = 	(masked_request_vector_dout[`YNEG_XNEG]) 	?
													"X-, "	: "    ";							
			end






endmodule

/* -- Plantilla de Instancia ------------------------------------ >>>>>>
	wire [3:0]	masked_request_vector;	

	selector selector 	#(
							.PORT_DIR	(PORT_DIR)
						)
		(
		// -- inputs --------------------------------------------- >>>>>
			.request_vector_din			(request_vector_din),
			.transfer_strobe_din		(transfer_strobe_din),
			.status_register_din		(status_register_din),

		// -- outputs -------------------------------------------- >>>>>
			.masked_request_vector_dout	(masked_request_vector)
	    );
*/