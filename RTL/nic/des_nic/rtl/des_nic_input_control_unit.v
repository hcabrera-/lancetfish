`timescale 1ns / 1ps

/*
-- Module Name:	DES NiC Input Control Unit

-- Description:	Unida de control para el bloque de entrada de la 
				interfaz de red. Este bloque se encarga de la captura de 
				nuevos paquetes provenientes de la red.

				Ejerce control sobre registros de almacenamiento 
				individuales para cada flit de un paquete y lleva 
				a cabo las tares de control de flujo (creditos) con 
				respecto al router de la NoC.


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

module des_nic_input_control_unit 
	(
		input wire clk,
		input wire reset,

	// -- inputs ------------------------------------------------- >>>>>
		input wire 	header_field_din,
		input wire 	busy_engine_din,
		input wire 	zero_credits_din,

	// -- outputs ------------------------------------------------ >>>>>
		output wire transfer2pe_strobe_dout,

		output wire 				write_strobe_dout,
		output wire [`DATA_FLITS:0] register_enable_dout
	);





// -- Parametros locales ----------------------------------------- >>>>>
	localparam IDLE 	= 2'b00;
	localparam CAPTURE 	= 2'b01;
	localparam WAIT 	= 2'b10;

	localparam LOAD		= 1'b1;
	localparam SHIFT	= 1'b0;





/*
-- Descripcion: Secuenciador para habilitacion de escritura en banco
				de registro para flits. Los datos de trabajo para el 
				elemento de procesamiento se almacenan en registros 
				individuales, este contador habilita la escritura en 
				cada uno de ellos. 

				Este registro esta codificado en formato 'one hot', y
				cada uno de sus bits habilita la captura de un flit en
				un registro	diferente.

				Los elementos de memoria estan descritos en el modulo
				des_nic_input_block.v
*/

		
	// -- Elementos de memoria ----------------------------------- >>>>>
		reg  [`DATA_FLITS:0] register_enable_reg;
		wire [`DATA_FLITS:0] register_enable_next;

		always @(posedge clk)
			if (reset)
				register_enable_reg <= {{`DATA_FLITS{1'b0}}, 1'b1};
			else
				register_enable_reg <= register_enable_next;

	// -- Logica del estado siguiente ---------------------------- >>>>>
		assign register_enable_next = 	(state_next == CAPTURE) ? register_enable_reg << 1 		:
										(state_next == IDLE)	? {{`DATA_FLITS{1'b0}}, 1'b1}	:
										register_enable_reg;


	// -- Logica de salidas -------------------------------------- >>>>>
		assign register_enable_dout = register_enable_reg;
		assign write_strobe_dout	= (state_next == CAPTURE) ? 1'b1 : 1'b0;








/*
-- Descripcion: Maquina de estado finito para el control de recepcion de
				paquetes para el PE del nodo.

				La FSM espera el ingreso de un nuevo paquete a traves 
				del canal de entrada. Durante los siguientes 'n' ciclos
				de reloj se registra cada flit perteneciente al paquete,
				dando la primera posicion del medio de almacenamiento 
				al flit de cabecera.

				Al finalizar la captura de flits de un paquete se 
				evalua la disponibilidad del elemento de procesamiento
				(banderas:: busy_engine_din y  zero_credits_din), en 
				caso de la presencia de cualquiera de las dos banderas
				la FSM salta al estado WAIT para esperar disponibilidad
				del elemento de procesamiento.

				La señal capture_strobe indica la captura de un paquete
				completo. esta señal se convierte en la señal de inicio
				para el PE.

				El control de flujo utiliza el mecanismo de creditos.
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
						if (header_field_din)
							state_next <= CAPTURE;

					CAPTURE:
						if ((register_enable_reg      == {`DATA_FLITS+1{1'b0}}) & (~busy_engine_din) & (~zero_credits_din))
							state_next <= IDLE;
						else if ((register_enable_reg == {`DATA_FLITS+1{1'b0}}) & (busy_engine_din   | zero_credits_din))
							state_next <= WAIT;

					WAIT:
						if (~busy_engine_din & ~zero_credits_din)
							state_next <= IDLE;

				endcase // state_reg
			end



	// -- Logica de salidas -------------------------------------- >>>>>
		assign transfer2pe_strobe_dout	= ((state_reg == CAPTURE | state_reg == WAIT) & (state_next == IDLE)) ? 1'b1 : 1'b0;






// -- Codigo no sintetizable ------------------------------------- >>>>>
	reg [7*8:0] state_reg_dbg;

	always @(*)
		case (state_reg)
			IDLE: 		state_reg_dbg 	= " IDLE  ";
			WAIT: 		state_reg_dbg 	= " WAIT  ";
			CAPTURE:	state_reg_dbg 	= "CAPTURE";
			default : 	state_reg_dbg 	= " ERROR ";
		endcase



endmodule

/* Plantilla de instancia ---------------------------------------- >>>>>

des_nic_input_control_unit des_nic_input_control_unit
	(
		.clk					(clk),
		.reset 					(reset),

	// -- inputs ------------------------------------------------- >>>>>
		.header_field_din		(header_field),
		.busy_engine_din		(busy_engine),
		.zero_credits_din		(zero_credits),

	// -- outputs ------------------------------------------------ >>>>>
		.transfer2pe_strobe_dout	(transfer2pe_strobe),

		.write_strobe_dout		(write_strobe),
		.register_enable_dout	(register_enable)
	);

*/