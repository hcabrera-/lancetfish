`timescale 1ns / 1ps

/*
-- Module Name:	nodo_frontera

-- Description:	Deflector de red para combinacion de puertos X+/X-. La 
				nomenclatura utilizada para nombrar este es archivoes la 
				siguiente:

				D_X0X1_ND

				-- D:		Posicion de deflectores
				-- X0X1:	Deflectores en puertos X+/X-
				-- ND:		Modulo Network Deflector


-- Dependencies:	-- system.vh


-- Parameters:		-- X_LOCAL:		Direccion en dimension "x" del nodo 
									en la red.
					-- Y_LOCAL:		Direccion en dimension "y" del nodo 
									en la red.
					-- X_WIDTH:		Numero de columnas de nodos que 
									conforman la red.
					-- Y_WIDTH:		Numero de filas de nodos que 
									conforman la red.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
	-- 03 de enero 2016:	Solo se agrego soporte para la generacion de
							direcciones destino en 'X' y 'Y'.

-- History:	
	-- 01 de enero 2016: 	Creacion
 	-- 03 de enero 2016:	Cambio de denominacion de 'deflector' a 
 							'nodo frontera'. Se agrega mecanismo para
 							seleccionar destinos dependiendo de su
 							posicion en la red.
*/
`include "system.vh"



module nodo_frontera	#(
							parameter 	X_WIDTH 	= 2,
							parameter	Y_WIDTH 	= 2,
							parameter 	X_LOCAL 	= 2,
							parameter	Y_LOCAL 	= 2
						)
	(
		input wire clk,
		input wire reset,

	// -- inports ------------------------------------------------ >>>>>
		input wire  [`CHANNEL_WIDTH-1:0]	channel_din,
		output wire							credit_out_dout,

	// -- outports ----------------------------------------------- >>>>>
		output wire [`CHANNEL_WIDTH-1:0]	channel_dout,
		input wire 							credit_in_din
	);




// -- Parametros locales ----------------------------------------- >>>>>
		localparam 	FLIT_COUNTER_WITDH 	= clog2(`DATA_FLITS);
		localparam 	PKT_COUNTER_WITDH 	= clog2(`BUFFER_DEPTH/5);

	// -- FSM1 Y FSM2 -------------------------------------------- >>>>>
		localparam	IDLE 	= 1'b0;
		localparam	ACTIVE 	= 1'b1;

	// -- Contador de creditos ----------------------------------- >>>>>
		localparam CREDITS 	 = 	`BUFFER_DEPTH/5;
		localparam CRT_WIDTH = 	clog2(CREDITS);

	// -- Direccion de paquete rebotando ------------------------- >>>>>
		localparam [2:0] X_NEW 	= 	newX(X_WIDTH, Y_WIDTH, X_LOCAL, Y_LOCAL);
		localparam [2:0] Y_NEW 	= 	newY(X_WIDTH, Y_WIDTH, X_LOCAL, Y_LOCAL);



// -- Declaracion temprana de señales ---------------------------- >>>>>
	wire header_field;
	wire witness_field;

	assign header_field 	= channel_din `HEADER_FIELD;
	assign witness_field	= channel_din `WITNESS_FIELD;



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

-- Salidas:		write_strobe_dout
*/

// -- Elemento de Memoria :: Contador de Flits ------------------- >>>>>
	reg  [FLIT_COUNTER_WITDH-1:0]	fsm1_counter_reg;

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

	
// -- Logica de Estado Siguiente :: Contador de Flits FSM1 ------- >>>>>
	assign 	fsm1_counter_sub 	= (fsm1_state_reg == ACTIVE || fsm1_state_next == ACTIVE) 	? 1'b1 : 1'b0;
	assign 	fsm1_counter_clear	= (fsm1_state_reg == ACTIVE && fsm1_state_next == IDLE)		? 1'b1 : 1'b0;



// -- FSM1 :: Elementos de Memoria ------------------------------- >>>>>
	reg  fsm1_state_reg;
	reg  fsm1_state_next;

	wire write_strobe;

	always @(posedge clk)
		if(reset)
			fsm1_state_reg <= IDLE;
		else
			fsm1_state_reg <= fsm1_state_next;


// -- FSM1 :: Logica de Estado Siguiente ------------------------- >>>>>
	always @(*)
		begin
			fsm1_state_next = fsm1_state_reg;
			case (fsm1_state_reg)

				IDLE:
					if (header_field)
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
	assign	write_strobe = ((fsm1_state_reg == ACTIVE & fsm1_state_next == IDLE) || fsm1_state_next == ACTIVE) 	? 1'b1 : 1'b0;









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

-- Salidas:		read_strobe_dout
				credit_out_dout
*/

	// -- Elemento de Memoria :: Contador de Flits --------------- >>>>>
		reg  [FLIT_COUNTER_WITDH:0]	fsm2_counter_reg;

		wire		fsm2_counter_sub;
		wire 		fsm2_counter_clear;
		wire 		fsm2_couter_reset;

		assign fsm2_couter_reset = reset | fsm2_counter_clear;

		always @(posedge clk)
			if(fsm2_couter_reset)
				fsm2_counter_reg <= `DATA_FLITS;
			else
				if (fsm2_counter_sub)
					fsm2_counter_reg <= fsm2_counter_reg - 1'b1;

	// -- Logica de Estado Siguiente :: Contador de Flits -------- >>>>>
		assign 	fsm2_counter_sub 	= (fsm2_state_reg == ACTIVE || fsm2_state_next == ACTIVE)	? 1'b1 : 1'b0;
		assign 	fsm2_counter_clear	= (fsm2_state_reg == ACTIVE && fsm2_state_next == IDLE)		? 1'b1 : 1'b0;



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
		assign credit_sub 	= (fsm2_state_reg == IDLE && fsm2_state_next == ACTIVE) ? 1'b1 : 1'b0;

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
						if (|credit_reg & ~empty)
							fsm2_state_next = ACTIVE;
						
					ACTIVE:
						if (|fsm2_counter_reg)
							fsm2_state_next = ACTIVE;
						else
							fsm2_state_next = IDLE;

				endcase // fsm2_state_regdi
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
		assign read_strobe		= ((fsm2_state_reg == ACTIVE & fsm2_state_next == IDLE) || fsm2_state_next == ACTIVE)	? 1'b1 : 1'b0;
		
		assign credit_out_dout	= (fsm2_state_reg == ACTIVE & fsm2_state_next == IDLE)	? 1'b1 : 1'b0; 
		









/*
-- Instancia :: Buffer (FIFO)

-- Descripcion: 

-- Salidas:		read_data_dout
*/


// -- Buffer de paquetes ----------------------------------------- >>>>>
	wire [`CHANNEL_WIDTH-1:0]	read_data;
	wire [`CHANNEL_WIDTH-1:0]	write_data;
		
	wire 	full;
	wire 	empty;
	
	
	fifo	buffer_de_paquetes
		(
			.clk	(clk),
			.reset 	(reset),

		// -- inputs --------------------------------------------- >>>>>
			.write_strobe_din	(write_strobe),
			.read_strobe_din	(read_strobe),

			.write_data_din 	(write_data),

		// -- outputs -------------------------------------------- >>>>>
			.full_dout 			(full),
			.empty_dout			(empty),
			.read_data_dout 	(read_data)
	    );

// -- Modificar flits de cabecera con direccion de rebote ---- >>>>>
		assign write_data   = (fsm1_state_reg == IDLE && fsm1_state_next == ACTIVE && ~witness_field) 	? 	{channel_din[31:30], X_NEW, Y_NEW, channel_din[23:0]} :
																											channel_din;

		assign channel_dout = (fsm2_state_reg == IDLE && fsm2_state_next == IDLE) 						? 	{`CHANNEL_WIDTH{1'b0}} : 
																											read_data;



/*
-- Funciones
*/

//  Funcion de calculo: log2(x) ---------------------------------- >>>>>
	function integer clog2;
		input integer depth;
			for (clog2=0; depth>0; clog2=clog2+1)
				depth = depth >> 1;
	endfunction



	function [2:0] newX;
		input integer X_WIDTH;
		input integer Y_WIDTH;
		input integer X_LOCAL;
		input integer Y_LOCAL;
		begin
			if (Y_LOCAL == Y_WIDTH + 1)
				//newX = (X_LOCAL == X_WIDTH) ? 1	: X_LOCAL + 1;
				newX = (X_LOCAL == X_WIDTH) ? X_LOCAL	: X_LOCAL + 1;
			/*
				-- Descripcion: Generacion de direcciones validas para
								nodos fronteras en limite inferior
								(Y_LOCAL == 0)
			*/
			else if (Y_LOCAL == 0)
				//newX = (X_LOCAL == X_WIDTH) ? 1	: X_LOCAL + 1;
				newX = (X_LOCAL == X_WIDTH) ? X_LOCAL	: X_LOCAL + 1;
			/*
				-- Descripcion: Generacion de direcciones validas para
								nodos fronteras en limite derecho
								(X_LOCAL == X_WIDTH + 1)
			*/
			else if (X_LOCAL == X_WIDTH + 1)
				//newX = 0;
				newX = X_LOCAL;
			/*
				-- Descripcion: Generacion de direcciones validas para
								nodos fronteras en limite izquierdo
								(X_LOCAL == 0)
			*/
			else 
				newX = X_WIDTH + 1;
		end
	endfunction




	function [2:0] newY;
		input integer X_WIDTH;
		input integer Y_WIDTH;
		input integer X_LOCAL;
		input integer Y_LOCAL;
		begin
			if (Y_LOCAL == Y_WIDTH + 1)
				newY = 0;
			/*
				-- Descripcion: Generacion de direcciones validas para
								nodos fronteras en limite inferior
								(Y_LOCAL == 0)
			*/
			else if (Y_LOCAL == 0)
				newY = Y_WIDTH + 1;
			/*
				-- Descripcion: Generacion de direcciones validas para
								nodos fronteras en limite derecho
								(X_LOCAL == X_WIDTH + 1)
			*/
			else if (X_LOCAL == X_WIDTH + 1)
				newY = (Y_LOCAL == Y_WIDTH) ? 1	: Y_LOCAL + 1;
			/*
				-- Descripcion: Generacion de direcciones validas para
								nodos fronteras en limite izquierdo
								(X_LOCAL == 0)
			*/
			else 
				newY = (Y_LOCAL == Y_WIDTH) ? 1	: Y_LOCAL + 1;
		end
	endfunction



/*
	-- Simbolos de depuracion
*/

	wire [2:0]	x_dest_dbg;
	wire [2:0]	y_dest_dbg;

	assign x_dest_dbg = write_data[29:27];
	assign y_dest_dbg = write_data[26:24];


endmodule // nodo_frontera

/* -- Plantilla de instancia ------------------------------------- >>>>>

nodo_frontera	
	#(
		.X_WIDTH(X_WIDTH),
		.Y_WIDTH(Y_WIDTH),
		.X_LOCAL(X_LOCAL),
		.Y_LOCAL(Y_LOCAL)
	)
nodo_frontera
	(
		.clk				(clk),
		.reset 				(reset),

	// -- puertos de entrada ------------------------------------- >>>>>
		.credit_out_dout 	(credit_out_dout),
		.channel_din 		(channel_din),

	// -- puertos de salida -------------------------------------- >>>>>
		.credit_in_din 		(credit_in_din),
		.channel_dout 		(channel_dout)
    );

*/