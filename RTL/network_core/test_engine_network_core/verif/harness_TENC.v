`timescale 1ns / 1ps
/*
-- Module Name:	Harness
-- Description:	Arnes para pruebas del modulo test_engine_network_core.
				
				En particular, este arnes conecta todos los puertos de
				la red con 'inyectores / receptores'  de paquetes.

-- Dependencies:	-- system.vh

-- Parameters:		

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
	
-- History:	
	-- Creacion 11 de Diciembre 2015
*/
`include "system.vh"


module harness_TENC #(
						parameter 	X_WIDTH 	= 5,
						parameter	Y_WIDTH 	= 5,
						parameter 	PROC_CYCLES = 5
					)
					();

localparam 	CYCLE 	= 4;
localparam	Tsetup	= CYCLE * 0.2;
localparam	Thold	= CYCLE * 0.2;


	reg clk;
	reg reset;

// -- inports  ----------------------------------------------- >>>>>
	wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_inports;
	wire [0: X_WIDTH-1]						xneg_credits_outports;
		
	wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_inports;
	wire [0: X_WIDTH-1]						xpos_credits_outports;

// -- outports ----------------------------------------------- >>>>>
	wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_outports;
	wire [0: X_WIDTH-1]						xneg_credits_inports;
		
	wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_outports;
	wire [0: X_WIDTH-1]						xpos_credits_inports;
		


// -- UUT -------------------------------------------------------- >>>>>
test_engine_network_core	
	#(
		.X_WIDTH 		(X_WIDTH),
		.Y_WIDTH 		(Y_WIDTH),
		.PROC_CYCLES	(PROC_CYCLES)
	)
TENC_UUT
	(
		.clk				(clk),
		.reset				(reset),

	// -- rx :: channels  ---------------------------------------- >>>>>
		.xneg_inports_din	(xneg_inports),
		.xneg_credits_dout	(xneg_credits_outports),

		.xpos_inports_din	(xpos_inports),
		.xpos_credits_dout	(xpos_credits_outports),
	
	// -- tx :: channels ----------------------------------------- >>>>>
		.xneg_outports_dout	(xneg_outports),
		.xneg_credits_din	(xneg_credits_inports),

		.xpos_outports_dout	(xpos_outports),
		.xpos_credits_din	(xpos_credits_inports)
	);



// -- Bus Behaivoral Model --------------------------------------- >>>>>
	/*
		-- Descripcion:	Generacion de 'alimentadores / receptores' de 
						paquetes para cada puerto IO de la red. Cada 
						puerto de IO esta servido por los siguientes
						modulos:

							* packet_generator: Modulo de soporte. 
							  Ofrece tasks para la generacion de 
							  paquetes validos para la red.

							  Despues de la ejecucion de una rutina
							  de generacion de paquete, el resultado 
							  puede ser accedido por medio de la 
							  variable 'packet'.

							* source: Modulo para el envio de paquetes.
							  Proporciona el servicio de interfaz para
							  la inyeccion de un paquete a la red. 
							  Este modulo se encarga de la 
							  descomposicion de un paquete en flits, y
							  el manejo del mecanismo de control de 
							  flujo.

							  El modulo source interactua con la red 
							  como si se tratase de otro nodo mas de la
							  red.

							* sink: Modulo receptor de paquetes. Se 
							  encarga de la recepcion de paquetes, asi 
							  como de su descomposicion en flits y 
							  campos de datos.

							  El modulo tambien lleva a cabo todas las 
							  tareas relacionadas con el control de 
							  flujo de datos, interactuando con la red
							  como si se tratase de otro nodo mas.

	*/
	genvar rows;

	// -- xneg ports --------------------------------------------- >>>>>
		generate
			for (rows = 0; rows < Y_WIDTH; rows = rows + 1) 
				begin:xneg_ports
				// -- Generador de paquetes ---------------------- >>>>>
					packet_generator 	
						#(
							.PORT 		(`X_NEG),
							.X_LOCAL	(0),
							.Y_LOCAL	(rows + 1),
							.X_WIDTH 	(X_WIDTH),
							.Y_WIDTH 	(Y_WIDTH)
						) 
					packet_generator
						();
				// -- Inyector de paquetes ----------------------- >>>>>
					source
						#(
							.Thold 	(Thold),
							.PORT 	(`X_NEG),
							.ID 	(rows)
						)
					source
						(
							.clk 		(clk),
							.channel_out(xneg_inports 			[rows*`CHANNEL_WIDTH:(rows*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_in 	(xneg_credits_outports	[rows])
						);
				// -- Receptor de paquetes ----------------------- >>>>>
					sink
						#(
							.Thold	(Thold),
							.PORT 	(`X_NEG),
							.ID 	(rows)
						)
					sink
						(
							.clk 		(clk),
							.channel_in (xneg_outports 			[rows*`CHANNEL_WIDTH:(rows*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_out (xneg_credits_inports 	[rows])
						);
				end
		endgenerate			


	// -- xpos ports --------------------------------------------- >>>>>
		generate
			for (rows = 0; rows < Y_WIDTH; rows = rows + 1) 
				begin:xpos_ports
				// -- Generador de paquetes ---------------------- >>>>>
					packet_generator 	
						#(
							.PORT 		(`X_POS),
							.X_LOCAL	(X_WIDTH + 1),
							.Y_LOCAL	(rows	 + 1),
							.X_WIDTH 	(X_WIDTH),
							.Y_WIDTH 	(Y_WIDTH)
						) 
					packet_generator
						();
				// -- Inyector de paquetes ----------------------- >>>>>					
					source
						#(
							.Thold	(Thold),
							.PORT 	(`X_POS),
							.ID 	(rows)
						)
					source
						(
							.clk 		(clk),
							.channel_out(xpos_inports 			[rows*`CHANNEL_WIDTH:(rows*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_in 	(xpos_credits_outports	[rows])
						);
				// -- Receptor de paquetes ----------------------- >>>>>
					sink
						#(
							.Thold 	(Thold),
							.PORT 	(`X_POS),
							.ID 	(rows)
						)
					sink
						(
							.clk 		(clk),
							.channel_in (xpos_outports 			[rows*`CHANNEL_WIDTH:(rows*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_out (xpos_credits_inports 	[rows])
						);
				end
		endgenerate	





// -- Clock Generator -------------------------------------------- >>>>>
	always 	
		begin
			#(CYCLE/2.0)	clk = 1'b0;
			#(CYCLE/2.0)	clk = 1'b1;
		end





// -- Sync Reset Generator --------------------------------------- >>>>>
	task sync_reset;
		begin


			reset <= 1'b1;
			repeat(10)
				begin
					@(posedge clk);
					#(Thold);
				end
			reset <= 1'b0;

		end	
	endtask : sync_reset




endmodule // harness_TENC