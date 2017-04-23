`timescale 1ns / 1ps

/*
-- Module Name:	Outport Scheduler Control Unit

-- Description:	Maquina de control para las unidades perteneceientes al
				planificador de salida. En general, el modulo espera
				a recibir una peticion desde cualquier puerto 
				(any_request_din). 

				Al recibir peticiones, el modulo da la señal 
				(arbiter_strobe_dout) de inicio de un proceso de 
				arbitraje por el uso del puerto de salida ligado a el.

				Al obtener un resultado del arbitraje, el modulo deja 
				saber al la fuente de la peticion ganadora, por medio
				de la señal 'transfer_strobe_dout', que puede empezar
				el envio del paquete.


-- Dependencies:	-- system.vh


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- Creacion 06 de Junio 2015
*/
`include "system.vh"


module outport_scheduler_control_unit	#(
											parameter PORT_DIR = `X_POS
										)
	(
		input wire clk,
		input wire reset,

	// -- inputs ------------------------------------------------- >>>>>
		input wire any_request_din,
		input wire credit_in_din,

	// -- outputs ------------------------------------------------ >>>>>
		output wire zero_credits_dout,
		output wire transfer_strobe_dout,
		output wire arbiter_strobe_dout,
		output wire clear_arbiter_dout
    );


// -- Declaracion de parametros locales -------------------------- >>>>>
	localparam CREDITS 	 = 	(PORT_DIR == `PE) ?	1 : `BUFFER_DEPTH/5;
	localparam CRT_WIDTH = 	clog2(CREDITS);

	localparam FLIT_COUNTER_WITDH 	= clog2(`DATA_FLITS);

// -- FSM -------------------------------------------------------- >>>>>
	localparam IDLE 	= 	1'b0;
	localparam ACTIVE	=	1'b1;

	





// -- Declaracion Temprana de Señales ---------------------------- >>>>>
	wire credit_sub;





/*
-- Contador de Creditos y de Flits faltantes

-- Descripcion: Contadores de apoyo para la operacion del puerto de
				salida.

				Contador de Flits: 	Lleva control de el numero de flits 
									que han	sido transferidos desde el 
									puerto de entrada al puerto de 
									salida.

				Contador de Creditos:	Control de espacio disponible en 
										buffer en el router vecino.

										Nucleo del mecanismo de control
										de flujo de paquetes entre 
										routers (credit flow control).
*/



	// -- Elemento de Memoria :: Contador de Flits --------------- >>>>>
		reg  [FLIT_COUNTER_WITDH:0]	counter_reg;

		wire	counter_sub;
		wire 	counter_clear;
		wire 	couter_reset;

		assign couter_reset = reset | counter_clear;

		always @(posedge clk)
			if(couter_reset)
				counter_reg <= `DATA_FLITS;
			else
				if (counter_sub)
					counter_reg <= counter_reg - 1'b1;

	// -- Logica de Estado Siguiente :: Contador de Flits -------- >>>>>
		assign counter_sub 		= (state_reg  == ACTIVE) 						? 1'b1 : 1'b0;
		assign counter_clear	= (state_reg  == ACTIVE && state_next == IDLE) 	? 1'b1 : 1'b0;






	// -- Elemento de Memoria :: Contador de Creditos ------------ >>>>>
	 	reg [CRT_WIDTH-1:0]	credit_reg;
	 	reg [CRT_WIDTH-1:0]	credit_next;
	 	
	 	
	 	always @(posedge clk)
	 		if (reset)
	 			credit_reg <= CREDITS;
	 		else
	 			credit_reg <= credit_next;
	 	

	 	always @(*)
	 		begin
	 			credit_next = credit_reg;
		 		case ({credit_in_din, credit_sub})
		 			
		 			2'b01:	credit_next = credit_reg - 1'b1;
		 			2'b10:	credit_next = credit_reg + 1'b1;
		 		
		 		endcase  //{credit_in_din, credit_sub}
		 	end

	// -- Logica de Estado Siguiente :: Contador de Creditos ----- >>>>>
		assign credit_sub 	= (state_reg == IDLE && state_next == ACTIVE) 	? 1'b1 : 1'b0;

	// -- Logica de salida del contador de creditos -------------- >>>>>
		assign zero_credits_dout = ~|credit_reg;






/*
-- Maquina de Estados Finito :: Tranferencia de Flits

-- Descripcion: La FSM tiene dos estados: IDLE Y ACTIVE.
				
				En estado de reposo (IDLE) la maquina solo esta a la
				espera de la llegada de una o mas peticiones desde 
				cualquier modulo 'link controller'.

				Durante la transicion de estado de reposo a activo 
				(ACTIVE) se solicita el bloqueo de la peticion ganadora
				en el arbitro (arbiter_strobe_dout). Ademas se envia una
				señal (transfer_strobe_dout) a la peticion ganadora para
				avisar que se puede iniciar la transferencia de flits.

				El estado ACTIVE tiene una duracion igual al numero de 
				flits de un paquete.

				El proceso de arbitraje no puede iniciar si no hay 
				creditos disponibles para el envio de paquetes al 
				siguiente router.
*/

	// -- FSM :: Elementos de Memoria ---------------------------- >>>>>
		reg state_reg;
		reg state_next;

		always @(posedge clk)
			if (reset)
				state_reg <= IDLE;
			else 
				state_reg <= state_next;



	// -- FSM :: Logica de Estado Siguiente ---------------------- >>>>>
		always @(*)
			begin
				state_next = state_reg;

				case (state_reg)
					IDLE:	
						if((|credit_reg) & any_request_din)
							state_next = ACTIVE;

					ACTIVE:	
						if (|counter_reg)
							state_next = ACTIVE;
						else
							state_next = IDLE;
				endcase //state_reg
			end






/*
-- Logica de Salida

-- Descripcion: 	La logica de salida del modulo depende del estado
					presente y estado siguiente de ambas maquinas de 
					estado finito.

					clear_arbiter_dout: Da clear al resultado actual del
					arbitro, eliminando la salida de datos provenientes
					de cualquier puerto de entrada. Se considera como el
					estado de reposo.

					arbiter_strobe_dout: Señal de captura del resultado
					del presente proceso de arbitraje.
*/
	

	assign clear_arbiter_dout	= (state_reg == ACTIVE && state_next ==   IDLE) ? 1'b1 : 1'b0;
	assign arbiter_strobe_dout 	= (state_reg == IDLE   && state_next == ACTIVE) ? 1'b1 : 1'b0;

		
	reg transfer_strobe_reg = 1'b0;

	always @(posedge clk)
		if (state_reg == IDLE   && state_next == ACTIVE)
			transfer_strobe_reg <= 1'b1;
		else
			transfer_strobe_reg <= 1'b0;

	assign transfer_strobe_dout = transfer_strobe_reg;
	








// -- Codigo no sintetizable ------------------------------------- >>>>>


	// -- Funciones ---------------------------------------------- >>>>>

			//  Funcion de calculo: log2(x) ---------------------- >>>>>
			function integer clog2;
				input integer depth;
					for (clog2=0; depth>0; clog2=clog2+1)
						depth = depth >> 1;
			endfunction




	// -- Simbolos de Depuracion --------------------------------- >>>>>
		reg [8*9:0]	estado_presente;
		reg [5*8:0]	crd_count_reg_dbg;

		always @(*)
			case (state_reg)
				IDLE: 	estado_presente = "IDLE";
				ACTIVE: estado_presente = "ACTIVE";
			endcase //state_reg

endmodule


/* -- Plantilla de Instancia ------------------------------------- >>>>>

outport_scheduler_control_unit	unidad_de_control_planificador_salida
	(
		.clk					(clk),
		.reset 					(reset),

	// -- inputs ------------------------------------------------- >>>>>
		.any_request_din		(port_request_din),
		.credit_in_din			(credit_in_din),
	
	// -- outputs ------------------------------------------------ >>>>>
		.zero_credits_dout		(zero_credits_dout),
		.transfer_strobe_dout	(transfer_strobe_dout),
		.arbiter_strobe_dout	(arbiter_strobe_dout),
		.clear_arbiter_dout		(clear_arbiter_dout)
    );

*/
