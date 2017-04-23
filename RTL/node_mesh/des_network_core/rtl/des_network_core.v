`timescale 1ns / 1ps

/*
-- Module Name:	network core

-- Description:	Top level de router NoC. 


-- Dependencies:	-- system.vh
					-- router.v *
					-- data_path.v



-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 11 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control. 
	-- 14 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control. 
*/
`include "system.vh"




module des_network_core
	(
		input wire clk,
		input wire reset,

	// -- inports  ----------------------------------------------- >>>>>
		input  wire [0:(`Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_inports,
		output wire [0:`Y_WIDTH-1]						xpos_credits_outports,
		
		input  wire [0:(`Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_inports,
		output wire [0:`Y_WIDTH-1]						xneg_credits_outports,
		
		input  wire [0:(`X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_inports,
		output wire [0:`X_WIDTH-1]						ypos_credits_outports,
		
		input  wire [0:(`X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_inports,
		output wire [0:`X_WIDTH-1]						yneg_credits_outports,

	// -- outports ----------------------------------------------- >>>>>
		output wire [0:(`Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_outports,
		input  wire [0:`Y_WIDTH-1]						xpos_credits_inports,
		
		output wire [0:(`Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_outports,
		input  wire [0:`Y_WIDTH-1]						xneg_credits_inports,
		
		output wire [0:(`X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_outports,
		input  wire [0:`X_WIDTH-1]						ypos_credits_inports,
		
		output wire [0:(`X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_outports,
		input  wire [0:`X_WIDTH-1]						yneg_credits_inports
	);




// -- Declaracion temprana de señales ---------------------------- >>>>>
	wire [`CHANNEL_WIDTH-1:0] row_right_channels	[0:`X_WIDTH][0:`Y_WIDTH-1];
	wire 					  row_left_credit	 	[0:`X_WIDTH][0:`Y_WIDTH-1];
	wire [`CHANNEL_WIDTH-1:0] row_left_channels  	[0:`X_WIDTH][0:`Y_WIDTH-1];
	wire 					  row_right_credit		[0:`X_WIDTH][0:`Y_WIDTH-1];
	

	wire [`CHANNEL_WIDTH-1:0] col_down_channels 	[0:`X_WIDTH-1][0:`Y_WIDTH];
	wire 					  col_up_credit		 	[0:`X_WIDTH-1][0:`Y_WIDTH];
	wire [`CHANNEL_WIDTH-1:0] col_up_channels		[0:`X_WIDTH-1][0:`Y_WIDTH];
	wire 					  col_down_credit 	 	[0:`X_WIDTH-1][0:`Y_WIDTH];
	



// -- Andamiaje para interconexion de buses de puertos ----------- >>>>>
	genvar rows;
	genvar cols;
	
	generate
		for (rows = 0; rows < `Y_WIDTH; rows = rows + 1) 
			begin				
			
			// -- inport / outport X- bus ------------------------ >>>>>
				assign row_right_channels [0][rows] = xneg_inports 	  [rows * `CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
				assign xneg_credits_outports [rows] = row_left_credit [0][rows];

				assign xneg_outports 	[rows*`CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = row_left_channels [0][rows];
				assign row_right_credit [0][rows] 	= xneg_credits_inports [rows];
				

			// -- inport / outport X+ bus ------------------------ >>>>>
				assign row_left_channels [`X_WIDTH][rows] = xpos_inports [rows * `CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
				assign xpos_credits_outports       [rows] = row_right_credit  [`X_WIDTH][rows];

				assign xpos_outports 	 [rows*`CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = row_right_channels[`X_WIDTH][rows];
				assign row_left_credit   [`X_WIDTH][rows] = xpos_credits_inports [rows];
				

			end
	endgenerate


	generate
		for (cols = 0; cols < `X_WIDTH; cols = cols + 1) 
			begin				
			
			
			// -- inport / outport Y+ bus ------------------------ >>>>>
				assign col_down_channels	  [cols][`Y_WIDTH] 	= ypos_inports  [cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
				assign ypos_credits_outports  [cols]    		= col_up_credit [cols][`Y_WIDTH];

				assign ypos_outports 	[cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = col_up_channels  [cols][`Y_WIDTH];
				assign col_down_credit  [cols][`Y_WIDTH] = ypos_credits_inports [cols];

			
			// -- inport / outport Y- bus ------------------------ >>>>>
				assign col_up_channels  	  [cols][0]  = yneg_inports [cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
				assign yneg_credits_outports  [cols] 	 = col_down_credit  [cols][0];

				assign yneg_outports [cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = col_down_channels[cols][0];
				assign col_up_credit [cols][0] = yneg_credits_inports [cols];

			end
	endgenerate






// -- Instancia de Nodos ----------------------------------------- >>>>>
	generate

		for (cols = 0; cols < `X_WIDTH; cols = cols + 1) 
			begin: columna
				for (rows = 0; rows < `Y_WIDTH; rows = rows + 1) 
					begin: lancetfish_node

						des_node 	
							#(
								.X_LOCAL(cols + 1),
								.Y_LOCAL(rows + 1)
							)
						des_node
							(
								.clk	(clk),
								.reset 	(reset),

							// -- puertos de entrada ------------------------------------- >>>>>
								.channel_xneg_din 		(row_right_channels [cols][rows]),
								.credit_out_xneg_dout	(row_left_credit   	[cols][rows]),

								.channel_xpos_din 		(row_left_channels  [cols+1][rows]),
								.credit_out_xpos_dout	(row_right_credit   [cols+1][rows]),
								
			
								.channel_ypos_din 		(col_down_channels 	[cols][rows+1]),
								.credit_out_ypos_dout	(col_up_credit   	[cols][rows+1]),

								.channel_yneg_din 		(col_up_channels   	[cols][rows]),
								.credit_out_yneg_dout 	(col_down_credit    [cols][rows]),

							// -- puertos de salida -------------------------------------- >>>>>
								.channel_xneg_dout		(row_left_channels 	[cols][rows]),
								.credit_in_xneg_din		(row_right_credit   [cols][rows]),
								
								.channel_xpos_dout 		(row_right_channels	[cols+1][rows]),
								.credit_in_xpos_din		(row_left_credit 	[cols+1][rows]),

								
								.channel_ypos_dout		(col_up_channels	[cols][rows+1]),
								.credit_in_ypos_din		(col_down_credit	[cols][rows+1]),				
								
								.channel_yneg_dout		(col_down_channels	[cols][rows]),
								.credit_in_yneg_din		(col_up_credit 		[cols][rows])
								
							);
					end
			
			end

	endgenerate



endmodule


/* -- Plantilla de instancia ------------------------------------- >>>>>
// -- Ancho de Frente de red (X)
//		canales 	:: [0:(`X_WIDTH * `CHANNEL_WIDTH)-1]
//		creditos 	:: [0:`X_WIDTH-1]
// -- Ancho de Frente de red (Y)
//		canales 	:: [0:(`X_WIDTH * `CHANNEL_WIDTH)-1]
//		creditos 	:: [0:`X_WIDTH-1]
module lancetfish_network_core
	(
		.clk(clk),
		.reset(reset),
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
// --------------------------------------------------------------- >>>>>*/ 