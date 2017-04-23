`timescale 1ns / 1ps

/*
-- Module Name:	output_control_unit

-- Description:	Unida de control para el bloque de salida de la interfaz
				de red. Este bloque se encarga de organizar la salida
				de paquetes desde el nodo de procesamiento en direccion
				al router de la NoC.

				El control de creditos para el control de flujo de 
				paquetes reeside en este modulo.


-- Dependencies:	-- system.vh

-- Parameters:		-- BUFFER_DEPTH:	Numero de flits que es capaz de 
										almacenar la cola de 
										almacenamiento de la NiC.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 18 de Junio 2015: 	Creacion
*/
`include "system.vh"


module output_control_unit 
	(
		input wire clk,
		input wire reset,
	
	// -- inputs ------------------------------------------------- >>>>>
		input  wire credit_in_din, 
		input  wire done_strobe_din,

	// -- outputs ------------------------------------------------ >>>>>	
		output wire 		zero_credits_dout,
		output wire [2:0]	output_selector_dout
	);




// -- Parametros locales ----------------------------------------- >>>>>
	// -- FSM ---------------------------------------------------- >>>>>
		localparam IDLE 	= 2'b00;
		localparam REQUEST 	= 2'b01;
		localparam ACTIVE 	= 2'b10;
	
	// -- Flit Counter ------------------------------------------- >>>>>
		localparam LOAD		= 1'b1;
		localparam DEC		= 1'b0;
	
	// -- Credit Counter ----------------------------------------- >>>>>
		localparam CREDITS 	 = 	`BUFFER_DEPTH/5;
		localparam CRT_WIDTH = 	clog2(CREDITS);







/*
-- Contador de creditos.

-- Descripcion:	Registro de control de creditos disponibles en el 
				router. La señal 'zero_credits' se conecta con el bloque
				de entrada de la interfaz de red para el control de 
				flujo de paquetes.

				El numero de creditos esta definido por el router de la 
				NoC, no por la interfaz.

				La llegada de la señal 'credit_in_din' incrementa en 1
				el numero de creditos disponibles.
*/

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
		assign credit_sub 	= (state_reg == REQUEST  & state_next == ACTIVE) 	? 1'b1 : 1'b0;


	// -- Logica de salidas -------------------------------------- >>>>>
		assign zero_credits = ~(|credit_reg);

		assign zero_credits_dout = zero_credits;






/*
-- Contador de transferencia de flits.

-- Descripcion: Contador para el control de numero de flits que se han 
				liberado de la salida de la interfaz de red en direccion
				al router.

				Este contador maneja la salida 'output_selector_dout',
				la cual es una señal selectora del registro de salida 
				que se expondra para la captura de dato por parte del
				router de la red.
				
				El valor por defecto de la señal 'output_selector_dout'
				es 0.

*/

	// -- Elementos de memoria ----------------------------------- >>>>>
		reg [2:0] 	flit_counter_reg;
		reg [2:0] 	flit_counter_next;

		wire 		flit_counter_load;
		wire 		flit_counter_sub;

		always @(posedge clk)
			if (reset)
				flit_counter_reg <= 3'b000;
			else
				flit_counter_reg <= flit_counter_next;


	// -- Logica del estado siguiente ---------------------------- >>>>>
		always @(*)
			begin
				flit_counter_next <= flit_counter_reg;
				case ({flit_counter_load, flit_counter_sub})
					
					2'b10:	
						flit_counter_next <= `DATA_FLITS + 1;
					
					2'b01:
						flit_counter_next <= flit_counter_reg - 1'b1;					
				endcase
			end


	// -- Logica de salidas -------------------------------------- >>>>>
		assign output_selector_dout = (state_next == ACTIVE || state_reg == ACTIVE) ? flit_counter_reg	: 3'b000;




/*
-- Maquina de estados

-- Descripcion: FSM para el control de la salida de la interfaz de red.
				La FSM inicia en un estado de reposo (IDLE), en este 
				estado espera por la señal 'done_strobe_din' desde el 
				nodo de procesamiento. Este evento indica a la FSM que 
				el nodo a terminado su tarea y que el resultado correcto 
				se encuentra disponible.

				Con la recepcion 'done_strobe_din' la FSM transita al 
				estado 'REQUEST'. eL ESTADO 'REQUEST' es un estado 
				intermedio donde se valida la disponiblidad de creditos
				para la transferencia de datos al router. Este estado 
				es necesario ya que la señal 'done_strobe_din' es un 
				pulso transitorio.

				Si se cuenta con creditos necesarios para la 
				tranferencia de un paquete de datos, la FSM pasa al
				estado 'ACTIVE'.

				La FSM permanece en estado 'ACTIVE' un numero de ciclos
				igual al numero de flits que forman un paquete. Cada 
				ciclo en 'ACTIVE' substrae una unidad al contador de
				flits de este modulo. Con la salida de todos los flits, 
				indicada por: 

					flit_counter_reg == 3'b000

				La FSM transita nuevamente al estado de reposo en espera
				al siguiente paquete para ser transferido a la red.

				La finalizacion de una transferencia de paquete 
				decrementa el contador de creditos, ya que un espacio de
				buffer en el router a sido tomado por el paquete recien
				liberado.
*/

// -- FSM -------------------------------------------------------- >>>>>
	
	// -- Elementos de memoria ----------------------------------- >>>>>
		reg [1:0]	state_reg;
		reg [1:0]	state_next;

		always @(posedge clk)
			if (reset)
				state_reg <= IDLE;
			else
				state_reg <= state_next;

	// -- Logica del estado siguiente ---------------------------- >>>>>
		always @(*)
			begin
				state_next <= state_reg;
				case (state_reg)
					
					IDLE:
						if (done_strobe_din)
							state_next <= REQUEST;

					REQUEST:
						if (~zero_credits)
							state_next <= ACTIVE;

					ACTIVE:
						if (flit_counter_reg == {3{1'b0}})
							state_next <= IDLE;						

				endcase // state_reg
			end

	// -- logica de salida --------------------------------------- >>>>>

		assign flit_counter_load	= (state_reg  == IDLE & state_next == REQUEST) 	? 1'b1 : 1'b0;
		assign flit_counter_sub 	= (state_next == ACTIVE) 							? 1'b1 : 1'b0;








// -- Codigo no sintetizable ------------------------------------- >>>>>

	// -- Funciones ---------------------------------------------- >>>>>

			//  Funcion de calculo: log2(x) ---------------------- >>>>>
			function integer clog2;
				input integer depth;
					for (clog2=0; depth>0; clog2=clog2+1)
						depth = depth >> 1;
			endfunction

	// -- Simbolos de depuracion --------------------------------- >>>>>
		reg [8*7:0] state_reg_dbg;

		always @(*)
			case (state_reg)
				IDLE	:	state_reg_dbg = " IDLE  ";
				
				REQUEST	:	state_reg_dbg = "REQUEST";
				
				ACTIVE	:	state_reg_dbg = " ACTIVE";
				
				default	: 	state_reg_dbg = "ERROR";
			endcase



endmodule

/* -- Plantilla de instancia ------------------------------------- >>>>>
output_control_unit  output_control_unit 
	(
		.clk					(clk),
		.reset 					(reset),
	
	// -- inputs ------------------------------------------------- >>>>>
		.credit_in_din 			(credit_in_din),
		.done_strobe_din 		(done_strobe_din),

	// -- outputs ------------------------------------------------ >>>>>	
		.zero_credits_dout 		(zero_credits_dout),
		.output_selector_dout 	(output_selector_dout)
	);
*/