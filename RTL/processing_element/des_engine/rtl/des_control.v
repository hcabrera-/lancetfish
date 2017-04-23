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


module des_control
	(
		input wire clk,
		input wire reset,

	// -- input ---------------------------------------------------------- >>>>>
		input wire start_strobe_din,

	// -- output --------------------------------------------------------- >>>>>
		output wire enable_dout,
		output wire source_dout,
		output wire active_dout,
		output reg  round_shift_dout,

		output wire done_strobe_dout
    );

// -- Parametros Locales ------------------------------------------------- >>>>>
	localparam IDLE 	= 1'b0;
	localparam ACTIVE 	= 1'b1;


// -- Declaracion temprana de Señales ------------------------------------ >>>>>
	reg [3:0]	round_counter;


// -- FSM::DES ----------------------------------------------------------- >>>>>
	reg state_reg;
	reg state_next;

	// -- Elementos de memoria FSM --------------------------------------- >>>>> 
		always @(posedge clk)
			if(reset)
				state_reg <= IDLE;
			else
				state_reg <= state_next;

	// -- Logica de estado siguiente ------------------------------------- >>>>>
		always @(*)
			begin
				state_next = state_reg;
				case (state_reg)
					IDLE: 		if (start_strobe_din)
									state_next = ACTIVE;
					
					ACTIVE:	if (round_counter == 4'b1111)
									state_next = IDLE;
				endcase // state_reg
			end


	// -- Contador de rondas --------------------------------------------- >>>>>
		always @(posedge clk)
			if (state_reg)
				round_counter <= round_counter + 1'b1;
			else
				round_counter <= {4{1'b0}};


	// -- Logica de salidas de control ----------------------------------- >>>>>

		// -- enable ----------------------------------------------------- >>>>>
		assign enable_dout = (state_next | state_reg) ? 1'b1 : 1'b0;

		// -- round shift ------------------------------------------------ >>>>>
			always @(*)
				case (round_counter)
					4'd0 : round_shift_dout = 1'b0;
					4'd1 : round_shift_dout = 1'b0;
					4'd8 : round_shift_dout = 1'b0;
					4'd15: round_shift_dout = 1'b0;

					default : round_shift_dout = 1'b1;

				endcase // round_counter

		// -- source select ---------------------------------------------- >>>>>
			assign source_dout = (state_reg) ? 1'b1 : 1'b0;

		// -- done strobe ------------------------------------------------ >>>>>
			assign done_strobe_dout = (&round_counter) ? 1'b1 : 1'b0;

		// -- active ----------------------------------------------------- >>>>>
			assign active_dout = (state_reg) ? 1'b1 : 1'b0;


	// -- Simbolos de Depuracion ----------------------------------------- >>>>>
		wire [6*8:0]	estado_presente;
		wire [6*8:0]	estado_siguiente;

		assign estado_presente  = (state_reg)  ? "ACTIVE" : "IDLE";
		assign estado_siguiente = (state_next) ? "ACTIVE" : "IDLE";


endmodule
