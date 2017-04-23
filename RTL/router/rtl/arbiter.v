`timescale 1ns / 1ps

/*
-- Module Name:	Arbiter

-- Description:	Implementacion de algoritmo de arbitraje entre multiples
				peticiones. En particular este modulo implementa el
				algoritmo round-robin de 4 bits.

				Despues de un reset, el modulo da priorida en orden 
				descendiente a las peticiones de: {PE, x+, y+, x-, y-}.
				Despues de seleccionar un ganador, la maxima prioridad
				durante el siguiente proceso de arbitraje se otorga al 
				puerto inmediato inferior al ganador de la ronda 
				anterior.

				Ej. 	Si el ganador durante la ronda anterior fue la 
						peticion proveniente de 'x+', la siguiente ronda
						las peticiones de 'y+' tendran la maxima 
						prioridad.


-- Dependencies:	-- system.vh



-- Parameters:		-- RQSX:	Codificacion 'One-Hot' de peticiones.
								Ej. Si los puertos validos para hacer
								una peticion son: {x+, y+, x-, y-}, 
								RQS0 tendria el valot 4'b0001

					-- PTY_NEXT_RQSX: 	Codificacion en binario natural
										de los numeros 3 a 0. 


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

	-- 05 de Junio 2015: 	Creacion
	-- 14 de Junio 2015: 	- Constantes RQSX y PTY_NEXT_RQSX pasan a 
							  ser parametros locales en lugar de 
							  `define en system.vh.
							- rqs_priority_next pasa a tener longitud de 
							  2 dos bits en lugar de 4.
							- Se agrega un registro dedicado al 
							  seguimiento de la prioridad siguiente.
							- El algoritmo de RR utiliza la señal 
							  registrada de rqs_priority_reg
*/
`include "system.vh"


module arbiter
	(
		input wire 	clk,

	// -- inputs ------------------------------------------------- >>>>>
		input wire  [3:0]	port_request_din,
		input wire 			arbiter_strobe_din,
		input wire 			clear_arbiter_din,

	// -- output ------------------------------------------------- >>>>>
		output wire [3:0]	xbar_conf_vector_dout
    );



// -- Parametros locales ----------------------------------------- >>>>>
	localparam 	RQS0 =	4'b0001;
	localparam	RQS1 =	4'b0010;
	localparam	RQS2 =	4'b0100;
	localparam	RQS3 =	4'b1000;
	
	localparam	PTY_NEXT_RQS1 =	2'b01;
	localparam	PTY_NEXT_RQS2 =	2'b10;
	localparam	PTY_NEXT_RQS3 =	2'b11;
	localparam	PTY_NEXT_RQS0 =	2'b00;



// -- Declaracion Temprana de Señales ---------------------------- >>>>>
	reg [3:0] xbar_conf_vector_reg 	= 4'b0000;
	


/*
-- Priority Encoder 

-- Descripcion:	Codificador de prioridad para la siguiente ronda de 
				arbitraje. Dependiendo de la peticion ganadora
				(xbar_conf_vector_reg) se otorga prioridad para el 
				proximo proceso de arbitraje a la entrada inferior 
				inmediada en la jeraraquia. 

				Ej. jerarquia por default de puertos {PE, x+, y+, x-, 
					y-}. Si la ronda anterior la peticion de 'y+' 
					resulto ganadora, la siguiente ronda las peticiones
					de 'x-' tienen la maxima prioridad.

				La prioridad esta codificada en binario naturas
				rqs_priority_reg.

*/
	reg  [1:0] rqs_priority_reg = 2'b00;
	reg  [1:0] rqs_priority_next;


	// -- Elemento de memoria ------------------------------------ >>>>>
		always @(posedge clk)
			if (clear_arbiter_din)
				rqs_priority_reg <= rqs_priority_next;


	// -- Elemento de logica del siguiente estado ---------------- >>>>>
		always @(*)
			begin
				rqs_priority_next = 2'b00;
				
				case (xbar_conf_vector_reg)
					RQS0:	rqs_priority_next = PTY_NEXT_RQS1;
					RQS1:	rqs_priority_next = PTY_NEXT_RQS2;
					RQS2:	rqs_priority_next = PTY_NEXT_RQS3;
					RQS3:	rqs_priority_next = PTY_NEXT_RQS0;
				endcase

			end //(*)





/*
-- Round Robin

-- Descripcion:	Codificacion de algoritmo Round Robin por medio de 
				tabla de verdad. Cada bit de 'grant_vector'	es 
				mutuamente excluyente de sus vecinos.

*/
	wire [3:0]	grant_vector;



	// -- Combinational RR ----------------------------------------------- >>>>>
		assign grant_vector[0] = 	(port_request_din[0] & ~rqs_priority_reg[1] & ~rqs_priority_reg[0])																			|
									(port_request_din[0] & ~rqs_priority_reg[1] &  rqs_priority_reg[0] & ~port_request_din[3] & ~port_request_din[2] & ~port_request_din[1])	|
									(port_request_din[0] &  rqs_priority_reg[1] & ~rqs_priority_reg[0] & ~port_request_din[3] & ~port_request_din[2])							|
									(port_request_din[0] &  rqs_priority_reg[1] &  rqs_priority_reg[0] & ~port_request_din[3]);

		assign grant_vector[1] = 	(port_request_din[1] & ~rqs_priority_reg[1] & ~rqs_priority_reg[0] & ~port_request_din[0])													|
									(port_request_din[1] & ~rqs_priority_reg[1] &  rqs_priority_reg[0])																			|
									(port_request_din[1] &  rqs_priority_reg[1] & ~rqs_priority_reg[0] & ~port_request_din[3] & ~port_request_din[2] & ~port_request_din[0])	|
									(port_request_din[1] &  rqs_priority_reg[1] &  rqs_priority_reg[0] & ~port_request_din[3] & ~port_request_din[0]);

		assign grant_vector[2] = 	(port_request_din[2] & ~rqs_priority_reg[1] & ~rqs_priority_reg[0] & ~port_request_din[1] & ~port_request_din[0])							|
									(port_request_din[2] & ~rqs_priority_reg[1] &  rqs_priority_reg[0] & ~port_request_din[1])													|
									(port_request_din[2] &  rqs_priority_reg[1] & ~rqs_priority_reg[0] )																		|
									(port_request_din[2] &  rqs_priority_reg[1] &  rqs_priority_reg[0] & ~port_request_din[3] & ~port_request_din[1] & ~port_request_din[0]);

		assign grant_vector[3] = 	(port_request_din[3] & ~rqs_priority_reg[1] & ~rqs_priority_reg[0] & ~port_request_din[2] & ~port_request_din[1] & ~port_request_din[0])	|
									(port_request_din[3] & ~rqs_priority_reg[1] &  rqs_priority_reg[0] & ~port_request_din[2] & ~port_request_din[1])							|
									(port_request_din[3] &  rqs_priority_reg[1] & ~rqs_priority_reg[0] & ~port_request_din[2])													|
									(port_request_din[3] &  rqs_priority_reg[1] &  rqs_priority_reg[0]);






// -- Registro de control para Crossbar -------------------------- >>>>>
	always @(posedge clk)
		if (clear_arbiter_din)
			xbar_conf_vector_reg <= {4{1'b0}};
		else 
			if (arbiter_strobe_din)
				xbar_conf_vector_reg <= grant_vector;



// -- Salida de Modulo ------------------------------------------- >>>>>
	assign xbar_conf_vector_dout = xbar_conf_vector_reg;



endmodule

/* -- Plantilla de Instancia ------------------------------------- >>>>>
	wire [3:0]	 xbar_conf_vector;

	arbiter 	arbitro_round_robin
		(
			.clk(clk),

		// -- inputs --------------------------------------------- >>>>>
			.port_request_din		(port_request_din),
			.arbiter_strobe_din		(arbiter_strobe_din),
			.clear_arbiter_din		(clear_arbiter_din)

		// -- output --------------------------------------------- >>>>>
			.xbar_conf_vector_dout	(xbar_conf_vector)
	    );

*/