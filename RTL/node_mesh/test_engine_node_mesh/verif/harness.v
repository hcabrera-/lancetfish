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


module harness #(
					parameter 	X_WIDTH = 6,
					parameter	Y_WIDTH = 6
				)
	();



localparam 	CYCLE 	= 100;
localparam	Tsetup	= 15;
localparam	Thold	= 5;


		reg clk;
		reg reset;

	// -- inports  ----------------------------------------------- >>>>>
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_inports;
		wire [0:Y_WIDTH-1]						xpos_credits_outports;
		
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_inports;
		wire [0:Y_WIDTH-1]						xneg_credits_outports;
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_inports;
		wire [0:X_WIDTH-1]						ypos_credits_outports;
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_inports;
		wire [0:X_WIDTH-1]						yneg_credits_outports;

	// -- outports ----------------------------------------------- >>>>>
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_outports;
		wire [0:Y_WIDTH-1]						xpos_credits_inports;
		
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_outports;
		wire [0:Y_WIDTH-1]						xneg_credits_inports;
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_outports;
		wire [0:X_WIDTH-1]						ypos_credits_inports;
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_outports;
		wire [0:X_WIDTH-1]						yneg_credits_inports;



// -- UUT -------------------------------------------------------- >>>>>
	test_engine_network_core	
		#(
			.X_WIDTH(X_WIDTH),
			.Y_WIDTH(Y_WIDTH)
		)
	UUT
		(
			.clk					(clk),
			.reset					(reset),
		// -- inports  ------------------------------------------- >>>>>
			.xpos_inports 			(xpos_inports),
			.xpos_credits_outports	(xpos_credits_outports),
			
			.xneg_inports 			(xneg_inports),
			.xneg_credits_outports 	(xneg_credits_outports),
			
			.ypos_inports 			(ypos_inports),
			.ypos_credits_outports 	(ypos_credits_outports),
			
			.yneg_inports 			(yneg_inports),
			.yneg_credits_outports 	(yneg_credits_outports),
		// -- outports ------------------------------------------- >>>>>
			.xpos_outports 			(xpos_outports),
			.xpos_credits_inports 	(xpos_credits_inports),
			
			.xneg_outports 			(xneg_outports),
			.xneg_credits_inports 	(xneg_credits_inports),
			
			.ypos_outports 			(ypos_outports),
			.ypos_credits_inports  	(ypos_credits_inports),
			
			.yneg_outports 			(yneg_outports),
			.yneg_credits_inports 	(yneg_credits_inports)
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
	genvar cols;

	// -- xneg ports --------------------------------------------- >>>>>
		generate
			for (rows = 0; rows < Y_WIDTH; rows = rows + 1) 
				begin:xneg_ports
				// -- Generador de paquetes ---------------------- >>>>>
					packet_generator 	
						#(
							.PORT 		(`X_NEG),
							.pe_percent	(10),
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
							.Thold(Thold)
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
							.Thold(Thold)
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
							.pe_percent	(10),
							.X_LOCAL	(X_WIDTH + 1),
							.Y_LOCAL	(rows 	 + 1),
							.X_WIDTH 	(X_WIDTH),
							.Y_WIDTH 	(Y_WIDTH)
						) 
					packet_generator
						();
				// -- Inyector de paquetes ----------------------- >>>>>
					source
						#(
							.Thold(Thold)
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
							.Thold(Thold)
						)
					sink
						(
							.clk 		(clk),
							.channel_in (xpos_outports 			[rows*`CHANNEL_WIDTH:(rows*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_out (xpos_credits_inports 	[rows])
						);
				end
		endgenerate



	// -- yneg ports --------------------------------------------- >>>>>
		generate
			for (cols = 0; cols < Y_WIDTH; cols = cols + 1) 
				begin:yneg_ports	
				// -- Generador de paquetes ---------------------- >>>>>
					packet_generator 	
						#(
							.PORT 		(`Y_NEG),
							.pe_percent	(10),
							.X_LOCAL	(cols + 1),
							.Y_LOCAL	(0),
							.X_WIDTH 	(X_WIDTH),
							.Y_WIDTH 	(Y_WIDTH)
						) 
					packet_generator
						();
				// -- Inyector de paquetes ----------------------- >>>>>				
					source
						#(
							.Thold(Thold)
						)
					source
						(
							.clk 		(clk),
							.channel_out(yneg_inports 			[cols*`CHANNEL_WIDTH:(cols*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_in 	(yneg_credits_outports	[cols])
						);
				// -- Receptor de paquetes ----------------------- >>>>>
					sink
						#(
							.Thold(Thold)
						)
					sink
						(
							.clk 		(clk),
							.channel_in (yneg_outports 			[cols*`CHANNEL_WIDTH:(cols*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_out (yneg_credits_inports 	[cols])
						);				
				end
		endgenerate	



	// -- ypos ports --------------------------------------------- >>>>>
		generate
			for (cols = 0; cols < Y_WIDTH; cols = cols + 1) 
				begin:ypos_ports
				// -- Generador de paquetes ---------------------- >>>>>
					packet_generator 	
						#(
							.PORT 		(`Y_POS),
							.pe_percent	(10),
							.X_LOCAL	(cols	 + 1),
							.Y_LOCAL	(Y_WIDTH + 1),
							.X_WIDTH 	(X_WIDTH),
							.Y_WIDTH 	(Y_WIDTH)
						) 
					packet_generator
						();
				// -- Inyector de paquetes ----------------------- >>>>>					
					source
						#(
							.Thold(Thold)
						)
					source
						(
							.clk 		(clk),
							.channel_out(ypos_inports 			[cols*`CHANNEL_WIDTH:(cols*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_in 	(ypos_credits_outports	[cols])
						);
				// -- Receptor de paquetes ----------------------- >>>>>
					sink
						#(
							.Thold(Thold)
						)
					sink
						(
							.clk 		(clk),
							.channel_in (ypos_outports 			[cols*`CHANNEL_WIDTH:(cols*`CHANNEL_WIDTH+`CHANNEL_WIDTH)-1]),
							.credit_out (ypos_credits_inports 	[cols])
						);
				end
		endgenerate	



// -- Clock Generator -------------------------------------------- >>>>>
	always 	
		begin
			#(CYCLE/2)	clk = 1'b0;
			#(CYCLE/2)	clk = 1'b1;
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




endmodule // harness