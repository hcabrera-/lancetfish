`timescale 1ns / 1ps
/*
-- Module Name:	Network Core

-- Description:	Acelerador en hardware basado en multiples nucleos de 
				procesamiento. 


-- Dependencies:	-- system.vh
					-- node_mesh.v
					-- nodo_frontera.v


-- Parameters:		-- X_LOCAL:		Direccion en dimension "x" del nodo 
									en la red.
					-- Y_LOCAL:		Direccion en dimension "y" del nodo 
									en la red.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 11 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control. 
	-- 14 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control.
	-- 03 de Enero 2015:	Cambio de nombre de modulo a network_core
*/
`include "system.vh"




module test_engine_network_core	#(
									parameter X_WIDTH 		= 5,
									parameter Y_WIDTH 		= 5,
									parameter PROC_CYCLES 	= 16
								)
	(
		input wire clk,
		input wire reset,

	// -- tx :: channels  ---------------------------------------- >>>>>
		input  wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_inports_din,
		output wire [0:Y_WIDTH-1]						xneg_credits_dout,

		input  wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_inports_din,
		output wire [0:Y_WIDTH-1]						xpos_credits_dout,
	
	// -- outports ----------------------------------------------- >>>>>
		output wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_outports_dout,
		input  wire [0:X_WIDTH-1]						xneg_credits_din,

		output wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_outports_dout,
		input  wire [0:X_WIDTH-1]						xpos_credits_din
	);





/*
-- Instacia :: 	Test Engine Node Mesh (TENM)

-- Descripcion:	

*/


// -- Señales de core -------------------------------------------- >>>>>
	// -- inports  ----------------------------------------------- >>>>>	Tipo de Nodo
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_inports;			// -- Terminal
		wire [0:Y_WIDTH-1]						xpos_credits_outports;	// -- Terminal
		
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_inports;			// -- Terminal
		wire [0:Y_WIDTH-1]						xneg_credits_outports;	// -- Terminal
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_inports;			// -- Frontera
		wire [0:X_WIDTH-1]						ypos_credits_outports;	// -- Frontera
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_inports;			// -- Frontera
		wire [0:X_WIDTH-1]						yneg_credits_outports;	// -- Frontera

	// -- outports ----------------------------------------------- >>>>>
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_outports;			// -- Terminal
		wire [0:Y_WIDTH-1]						xpos_credits_inports;	// -- Terminal
		
		wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_outports;			// -- Terminal
		wire [0:Y_WIDTH-1]						xneg_credits_inports;	// -- Terminal
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_outports;			// -- Frontera
		wire [0:X_WIDTH-1]						ypos_credits_inports;	// -- Frontera
		
		wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_outports;			// -- Frontera
		wire [0:X_WIDTH-1]						yneg_credits_inports;	// -- Frontera



/*
	-- Descripcion:	Tendido de enlaces entre los puertos de IO del 
					modulo y los canales de comunicacion a los nodos
					terminal de la malla.

					Canales de entrada a la malla de nodos son RX, 
					mientras que los canales de salida son lineas TX.
*/
	// -- XNEG :: RX/TX ------------------------------------------ >>>>>
		assign xneg_inports 		= xneg_inports_din;
		assign xneg_credits_dout	= xneg_credits_outports;

		assign xneg_outports_dout	= xneg_outports;
		assign xneg_credits_inports = xneg_credits_din;

		

	// -- XPOS :: RX/TX ------------------------------------------ >>>>>
		assign xpos_inports 		= xpos_inports_din;
		assign xpos_credits_dout	= xpos_credits_outports;

		assign xpos_outports_dout	= xpos_outports;
		assign xpos_credits_inports = xpos_credits_din;



/*
-- Instacia :: Malla de Nodos
-- Descripcion: 

-- Salidas:		
*/
	test_engine_node_mesh
		#(
			.X_WIDTH 	(X_WIDTH),
			.Y_WIDTH 	(Y_WIDTH),
			.PROC_CYCLES(PROC_CYCLES)
		)
	TENM
		(
			.clk					(clk),
			.reset					(reset),
		// -- inports  ----------------------------------------------- >>>>>
			.xpos_inports 			(xpos_inports),
			.xpos_credits_outports	(xpos_credits_outports),
			
			.xneg_inports 			(xneg_inports),
			.xneg_credits_outports 	(xneg_credits_outports),
			
			.ypos_inports 			(ypos_inports),
			.ypos_credits_outports 	(ypos_credits_outports),
			
			.yneg_inports 			(yneg_inports),
			.yneg_credits_outports 	(yneg_credits_outports),
		// -- outports ----------------------------------------------- >>>>>
			.xpos_outports 			(xpos_outports),
			.xpos_credits_inports 	(xpos_credits_inports),
			
			.xneg_outports 			(xneg_outports),
			.xneg_credits_inports 	(xneg_credits_inports),
			
			.ypos_outports 			(ypos_outports),
			.ypos_credits_inports  	(ypos_credits_inports),
			
			.yneg_outports 			(yneg_outports),
			.yneg_credits_inports 	(yneg_credits_inports)
		);



/*
-- Instacia :: Nodos Frontera
-- Descripcion: 

-- Salidas:		
*/


/*
	-- Descripcion:	Tendido de enlaces entre los puertos de IO de la 
					instancia de la malla de nodos (TENM) y los nodos
					frontera de la red.
*/
	genvar channel;

	wire [`CHANNEL_WIDTH-1:0] ypos_in_channels	[0:X_WIDTH];
	wire 					  ypos_out_credits 	[0:X_WIDTH];

	wire [`CHANNEL_WIDTH-1:0] ypos_out_channels	[0:X_WIDTH];
	wire 					  ypos_in_credits 	[0:X_WIDTH];

	wire [`CHANNEL_WIDTH-1:0] yneg_in_channels	[0:X_WIDTH];
	wire 					  yneg_out_credits 	[0:X_WIDTH];

	wire [`CHANNEL_WIDTH-1:0] yneg_out_channels	[0:X_WIDTH];
	wire 					  yneg_in_credits 	[0:X_WIDTH];


/*
	-- Nota:	Las conexiones entre nodos frontera y la red se lleva
				a cabo directamente entre las instancias de la malla
				de nodos y las instancias de los nodos frontera.

				No se lleva a cabo en los siguientes bloques Generate
				ya que no es necesario el calculo de segmentos de 
				racimos de señales, la correspondencia es uno a uno.
*/
	generate
		for (channel = 0; channel < X_WIDTH; channel = channel + 1) 
			begin
				assign ypos_inports [channel * `CHANNEL_WIDTH:(channel * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] 	= ypos_in_channels[channel];
				assign ypos_out_channels[channel] 	= ypos_outports [channel * `CHANNEL_WIDTH:(channel * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
			end
	endgenerate // Generacion de canales Y+


	generate
		for (channel = 0; channel < Y_WIDTH; channel = channel + 1)
			begin
				assign yneg_inports	[channel * `CHANNEL_WIDTH:(channel * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = yneg_in_channels[channel];
				assign yneg_out_channels[channel] 	= yneg_outports 		[channel * `CHANNEL_WIDTH:(channel * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
			end
	endgenerate // Generacion de canales Y-




genvar index;

// -- Nodos Frontera (YPOS) -------------------------------------- >>>>>
	generate
		
		for (index = 0; index < X_WIDTH; index = index + 1) 
			begin: nodo_frontera_ypos

				nodo_frontera	
					#(
						.X_WIDTH 	(X_WIDTH),
						.Y_WIDTH 	(Y_WIDTH),
						.X_LOCAL 	(index   + 1),
						.Y_LOCAL 	(Y_WIDTH + 1)
					)
				nodo_frontera_ypos
					(
						.clk				(clk),
						.reset 				(reset),

					// -- puertos de entrada --------------------- >>>>>
						.credit_out_dout 	(ypos_credits_inports	[index]),
						.channel_din 		(ypos_out_channels		[index]),

					// -- puertos de salida ---------------------- >>>>>
						.credit_in_din 		(ypos_credits_outports	[index]),
						.channel_dout 		(ypos_in_channels		[index])
				    );
			
			end		

	endgenerate

// -- Nodos Frontera (YNEG) -------------------------------------- >>>>>
	generate
		
		for (index = 0; index < X_WIDTH; index = index + 1) 
			begin: nodo_frontera_yneg
			
				nodo_frontera	
					#(
						.X_WIDTH 	(X_WIDTH),
						.Y_WIDTH 	(Y_WIDTH),
						.X_LOCAL	(index+1),
						.Y_LOCAL	(0)
					)
				nodo_frontera_yneg
					(
						.clk				(clk),
						.reset 				(reset),

					// -- puertos de entrada --------------------- >>>>>
						.credit_out_dout 	(yneg_credits_inports	[index]),
						.channel_din 		(yneg_out_channels		[index]),

					// -- puertos de salida ---------------------- >>>>>
						.credit_in_din 		(yneg_credits_outports	[index]),
						.channel_dout 		(yneg_in_channels		[index])
				    );

			end		

	endgenerate

endmodule // test_engine_network_core



/* -- Plantilla de instancia ------------------------------------- >>>>>

test_engine_network_core	
	#(
		.X_WIDTH 	(X_WIDTH),
		.Y_WIDTH 	(Y_WIDTH),
		.PROC_CYCLES(PROC_CYCLES)
	)
UUT
	(
		.clk				(clk),
		.reset				(reset),

	// -- tx :: channels  ---------------------------------------- >>>>>
		.xneg_inports_din	(xneg_inports_din),
		.xneg_credits_dout	(xneg_credits_dout),

		.ypos_inports_din	(xpos_inports_din),
		.ypos_credits_dout	(xpos_credits_dout),
	
	// -- outports ----------------------------------------------- >>>>>
		.xneg_outports_dout	(xneg_outports_dout),
		.xneg_credits_din	(xneg_credits_din),

		.ypos_outports_dout	(xpos_outports_dout),
		.ypos_credits_din	(xpos_credits_din)
	);
*/

