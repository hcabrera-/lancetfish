`timescale 1ns / 1ps

/*
-- Module Name:	Link Controller Control Unit

-- Description:	Unidad de Control para el modulo "Controlador de Enlace"
				
				Se encarga de organizar los procesos de almacenaje de 
				flits y calculo de nueva ruta para paquetes en transito 
				a traves del router.

				Forma parte del modulo "Link Controller".

-- Dependencies:	-- system.vh

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 09 de Junio 2015: 	+	puerto de salida - routing_source_dout
							+	maquina de estado FSM3
								FSM1 maneja: 	write_strobe
								FSM2 maneja: 	read_strobe
												credit_out
	-- 11 de Junio 2015:	+ 	Contador de paquetes y logica de 
								seleccion de origen de direccion {x,y}
*/
`include "system.vh"


module link_controller_control_unit
	(
		input wire clk,
		input wire reset,

	// -- inputs ------------------------------------------------- >>>>>
		input wire header_field_din,
		input wire transfer_strobe_din,

	// -- outputs ------------------------------------------------ >>>>>
		output wire write_strobe_dout,
		output wire read_strobe_dout,

		output wire routing_source_dout,
		output wire routing_strobe_dout,
		
		output wire credit_out_dout
	);


// -- Parametros locales ----------------------------------------- >>>>>
		localparam 	FLIT_COUNTER_WITDH 	= clog2(`DATA_FLITS);
		localparam 	PKT_COUNTER_WITDH 	= clog2(`BUFFER_DEPTH/5);

	// -- FSM1 Y FSM2 -------------------------------------------- >>>>>
		localparam	IDLE 	= 1'b0;
		localparam	ACTIVE 	= 1'b1;

	// -- FSM3 --------------------------------------------------- >>>>>
		localparam	OFF		= 2'b00;
		localparam	FIELD	= 2'b01;
		localparam	BUFFER	= 2'b10;




/*
-- Maquina de Estados Finito :: Recepcion de Flits

-- Descripcion: Estados - IDLE Y ACTIVE.
				
				En estado de reposo (IDLE), la FSM1 se encuentra a la
				espera de la llegada de un nuevo paquete. La señal
				'header_field_din' indica la llegada del nuevo paquete.

				Durante la transicion de estado de reposo a estado 
				activo (ACTIVE), la FSM1 emite un pulso de escritura al 
				buffer.

				La FSM1 emita pulsos de escritura al buffer por cada 
				flit de datos del paquete (numero determinado por 
				DATA_FLITS - 1).

				El contador de Flits es un restador para llevar cuenta
				del numero de flits que se han recibido del paquete. A 
				traves de el se dispara el cambio de estado de ACTIVE
				a IDLE.

-- Salidas:		write_strobe_dout
*/


	// -- Elemento de Memoria :: Contador de Flits --------------- >>>>>
		reg  [FLIT_COUNTER_WITDH-1:0] 	fsm1_counter_reg;

		wire fsm1_counter_sub;
		wire fsm1_counter_clear;
		wire fsm1_counter_reset;


		assign fsm1_counter_reset = reset | fsm1_counter_clear;


		always @(posedge clk)
			if(fsm1_counter_reset)
				fsm1_counter_reg <= `DATA_FLITS;
			else
				if (fsm1_counter_sub)
					fsm1_counter_reg <= fsm1_counter_reg - 1'b1;

	
	// -- Logica de Estado Siguiente :: Contador de Flits FSM1 --- >>>>>
		assign 	fsm1_counter_sub 	= (fsm1_state_reg == ACTIVE || fsm1_state_next == ACTIVE) 	? 1'b1 : 1'b0;
		assign 	fsm1_counter_clear	= (fsm1_state_reg == ACTIVE && fsm1_state_next == IDLE)		? 1'b1 : 1'b0;




	// -- FSM1 :: Elementos de Memoria --------------------------- >>>>>
		reg fsm1_state_reg;
		reg fsm1_state_next;

		always @(posedge clk)
			if(reset)
				fsm1_state_reg <= IDLE;
			else
				fsm1_state_reg <= fsm1_state_next;


	// -- FSM1 :: Logica de Estado Siguiente --------------------- >>>>>
		always @(*)
			begin
				fsm1_state_next = fsm1_state_reg;
				case (fsm1_state_reg)

					IDLE:
						if (header_field_din)
							fsm1_state_next = ACTIVE;
						
					ACTIVE:
						if (|fsm1_counter_reg)
							fsm1_state_next = ACTIVE;
						else
							fsm1_state_next = IDLE;

				endcase // fsm1_state_reg
			end


	/*
		-- Logica de Salida FSM1

		-- Descripcion: FSM1 maneja el pulso de escritura de la cola de 
						almacenamiento en el camino de datos.
	*/
		assign	write_strobe_dout	= 	((fsm1_state_reg == ACTIVE & fsm1_state_next == IDLE) || fsm1_state_next == ACTIVE) 	? 1'b1 : 1'b0;










/*
-- Maquina de Estados Finito :: Liberacion de Flits

-- Descripcion: Estados - IDLE Y ACTIVE.
				
				En estado de reposo (IDLE), la FSM2 se encuentra a la
				espera de la llegada de la confirmacion 
				(transfer_strobe_din) de la consolidacion de enlace 
				entre el puerto de entrada y el puerto de salida 
				solicitado por el paquete.

				Durante la transicion de estado de reposo a estado 
				activo (ACTIVE), la FSM2 emite un pulso de lectura al 
				buffer.

				La FSM2 emita pulsos de lectura al buffer por cada flit
				de datos en el paquete (numero determinado por 
				DATA_FLITS - 1). Al final de la liberarcion de todos los 
				flits del paquete, la FSM2 libera la señal 
				(credit_out_dout) para indicarle al router 'downstream'
				que ha liberado un espacio en su buffer de paquetes.

				El contador de Flits es un restador para llevar cuenta
				del numero de flits que se han liberado del paquete. A 
				traves de el se dispara el cambio de estado de ACTIVE
				a IDLE.

-- Salidas:		read_strobe_dout
				credit_out_dout
*/

	// -- Elemento de Memoria :: Contador de Flits --------------- >>>>>
		reg  [FLIT_COUNTER_WITDH-1:0]	fsm2_counter_reg;

		wire		fsm2_counter_sub;
		wire 		fsm2_counter_clear;
		wire 		fsm2_counter_reset;

		wire 		credit_out;


		assign fsm2_counter_reset = reset | fsm2_counter_clear;


		always @(posedge clk)
			if(fsm2_counter_reset)
				fsm2_counter_reg <= `DATA_FLITS;				
			else
				if (fsm2_counter_sub)
					fsm2_counter_reg <= fsm2_counter_reg - 1'b1;


	// -- Logica de Estado Siguiente :: Contador de Flits -------- >>>>>
		assign 	fsm2_counter_sub 	= (fsm2_state_reg == ACTIVE || fsm2_state_next == ACTIVE)	? 1'b1 : 1'b0;
		assign 	fsm2_counter_clear	= (fsm2_state_reg == ACTIVE && fsm2_state_next == IDLE)		? 1'b1 : 1'b0;


	// -- FSM2 :: Elementos de Memoria --------------------------- >>>>>
		reg fsm2_state_reg;
		reg fsm2_state_next;

		always @(posedge clk)
			if(reset)
				fsm2_state_reg <= IDLE;
			else
				fsm2_state_reg <= fsm2_state_next;


	// -- FSM2 :: Logica de Estado Siguiente --------------------- >>>>>
		always @(*)
			begin
				fsm2_state_next = fsm2_state_reg;
				case (fsm2_state_reg)

					IDLE:
						if (transfer_strobe_din)
							fsm2_state_next = ACTIVE;
						
					ACTIVE:
						if (|fsm2_counter_reg)
							fsm2_state_next = ACTIVE;
						else
							fsm2_state_next = IDLE;

				endcase // fsm2_state_reg
			end


	/*
		-- Logica de Salida FSM2

		-- Descripcion: FSM2 maneja el pulso de lectura de la cola de 
						almacenamiento en el camino de datos, y la 
						salida de creditos al router 'downstream'.

						La señal 'credit_out' es utilizada por la FSM3,
						sin embargo, la misma logica maneja la salida
						'credit_out_dout'.
	*/
		assign read_strobe_dout	= ((fsm2_state_reg == ACTIVE & fsm2_state_next == IDLE) || fsm2_state_next == ACTIVE)	? 1'b1 : 1'b0;
		assign credit_out		= (fsm2_state_reg == IDLE & fsm2_state_next == ACTIVE)	? 1'b1 : 1'b0; 
		assign credit_out_dout	= credit_out;

		




/*
-- Logica de Manejo de planificacion de ruta --------------------- >>>>>

-- Descripcion: Logica para decodificar la direccion destino de un 
				paquete. La direcion {x,y} puede obtenerse
				directamente del canal de entrada, previo al 
				almacenamiento en la cola, o puede obtenerse de la 
				salida de la cola de almacenamiento.

				Cuando la cola de almacenamiento no tiene paquetes 
				pendientes, el planificador de ruta es configurado para 
				(routing_source_dout = 0) utilizar el campo 'destino' 
				del flit de cabecera para el calculo de ruta. En caso de 
				haber paquetes en espera, al finalizar la transmision 
				del paquete en turno, el nuevo proceso de calculo de 
				ruta se lleva a cabo con el flit de cabecera a la salida 
				de la cola de almacenamiento (routing_source_dout = 1)
				en lugar del campo destino del canal de entrada.

				El proceso de calculo de ruta es desencadenado por los
				siguientes eventos:

					* 	Llegada de un nuveo paquete
					* 	Paquete pendiente en cola despues de la 
						finalizacion de transmision de un paquete 
						anterior.

				No se utiliza una FSM ya que las condiciones de disparo
				de calculo de ruta se pueden deducir a partir del 
				contador de paquetes pendiente.


-- Salidas:		routing_strobe_dout
				routing_source_dout
*/

	// -- Elemento de Memoria :: Contador de paquetes ------------ >>>>>
		reg [PKT_COUNTER_WITDH-1:0]	packet_counter_reg;
		reg [PKT_COUNTER_WITDH-1:0]	packet_counter_next;

		wire packet_counter_sub;
		wire packet_counter_add;
		
		wire zero_packets;


		always @(posedge clk)
			if(reset)
				packet_counter_reg <= {PKT_COUNTER_WITDH{1'b0}};
			else
				packet_counter_reg <= packet_counter_next;

		always @(*)
			begin
				packet_counter_next = packet_counter_reg;
					case ({packet_counter_add, packet_counter_sub})
						2'b01:	packet_counter_next = packet_counter_reg - 1'b1;
						2'b10:	packet_counter_next = packet_counter_reg + 1'b1;
					endcase //{packet_counter_add, packet_counter_sub}
			end
			


	// -- Logica de Estado Siguiente :: Contador de paquetes ----- >>>>>
		assign 	packet_counter_add 	= (fsm1_state_reg == IDLE   & fsm1_state_next == ACTIVE) 	? 1'b1 : 1'b0;
		assign 	packet_counter_sub	= (fsm2_state_reg == IDLE   & fsm2_state_next == ACTIVE)	? 1'b1 : 1'b0;

		assign 	zero_packets 		= (|packet_counter_reg) ? 1'b0 : 1'b1;


	
	reg pending_routing_reg = 1'b0;

	always @(posedge clk)
		if (fsm2_state_reg == ACTIVE && fsm2_state_next == IDLE)
			pending_routing_reg <= 1'b1;
		else
			pending_routing_reg <= 1'b0;
	

	assign 	routing_strobe_dout	= 	(fsm1_state_reg == IDLE && fsm1_state_next == ACTIVE && zero_packets && fsm2_state_reg == IDLE)	?	1'b1 :
									(~zero_packets && pending_routing_reg)															?	1'b1 :
									1'b0;
	
	assign 	routing_source_dout	= 	(|packet_counter_reg) ? 1'b1 : 1'b0;











// -- Codigo no sintetizable ------------------------------------- >>>>>


/*
-- Simbolos de Depuracion
*/
	reg [6*8:0]	fsm1_state_reg_dbg;
	reg [6*8:0]	fsm2_state_reg_dbg;
	reg [5*8:0]	pck_count_reg_dbg;

		always @(*)
			case(fsm1_state_reg)
				IDLE 	:		fsm1_state_reg_dbg = "IDLE";
				ACTIVE  :		fsm1_state_reg_dbg = "ACTIVE";
			endcase // fsm1_state_reg

		always @(*)
			case(fsm2_state_reg)
				IDLE	:		fsm2_state_reg_dbg = "IDLE";
				ACTIVE 	:		fsm2_state_reg_dbg = "ACTIVE";
			endcase // fsm2_state_reg

		always @(*)
			case(packet_counter_reg)
				2'b00 :	pck_count_reg_dbg = "ZERO";
				2'b01 :	pck_count_reg_dbg = "ONE";
				2'b10 :	pck_count_reg_dbg = "TWO";
				2'b11 :	pck_count_reg_dbg = "THREE";
			endcase // fsm2_state_reg


/*
-- Funciones
*/

//  Funcion de calculo: log2(x) ---------------------------------- >>>>>
	function integer clog2;
		input integer depth;
			for (clog2=0; depth>0; clog2=clog2+1)
				depth = depth >> 1;
	endfunction





endmodule // link_controller_control_unit



/* -- Plantilla de Instancia ------------------------------------- >>>>>
	wire write_strobe;
	wire routing_strobe;
	wire routing_source;

	wire read_strobe;
	wire credit_add;


link_controller_control_unit	unidad_de_control_de_control_de_enlace
	(
		.clk	(clk),
		.reset 	(reset),

	// -- inputs ------------------------------------------------- >>>>>
		.header_field_din 		(header_field_din),
		.transfer_strobe_din	(transfer_strobe_din),

	// -- outputs ------------------------------------------------ >>>>>
		.write_strobe_dout		(write_strobe),

		.routing_strobe_dout	(routing_strobe),
		.routing_source_dout	(routing_source),

		.read_strobe_dout		(read_strobe),
		.credit_out_dout		(credit_out)
    );
*/