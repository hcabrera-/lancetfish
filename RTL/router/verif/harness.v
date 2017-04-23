`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2015 14:58:39
// Design Name: 
// Module Name: harness
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "system.vh"




module harness();

parameter 	X_LOCAL = 2,
			Y_LOCAL = 2,
			CYCLE 	= 100,
			Tsetup	= 15,
			Thold	= 5;

// -- Señales de interconexion ----------------------------------- >>>>>
		reg clk;
		reg reset;

	// -- puertos de entradas ------------------------------------ >>>>>
		wire credit_out_xpos_dout;
		wire [`CHANNEL_WIDTH-1:0]	channel_xpos_din;

		wire credit_out_ypos_dout;
		wire [`CHANNEL_WIDTH-1:0]	channel_ypos_din;

		wire credit_out_xneg_dout;
		wire[`CHANNEL_WIDTH-1:0]	channel_xneg_din;

		wire credit_out_yneg_dout;
		wire [`CHANNEL_WIDTH-1:0]	channel_yneg_din;

		wire credit_out_pe_dout;
		wire [`CHANNEL_WIDTH-1:0]	channel_pe_din;
			
		
	// -- puertos de salida -------------------------------------- >>>>>
		wire credit_in_xpos_din;
		wire [`CHANNEL_WIDTH-1:0]	channel_xpos_dout;

		wire credit_in_ypos_din;
		wire [`CHANNEL_WIDTH-1:0]	channel_ypos_dout;

		wire credit_in_xneg_din;
		wire [`CHANNEL_WIDTH-1:0]	channel_xneg_dout;

		wire credit_in_yneg_din;
		wire [`CHANNEL_WIDTH-1:0]	channel_yneg_dout;

		wire credit_in_pe_din;
		wire [`CHANNEL_WIDTH-1:0]	channel_pe_dout;



// -- DUT -------------------------------------------------------- >>>>>
	router 	
		#(
			.X_LOCAL(X_LOCAL), 
			.Y_LOCAL(Y_LOCAL)
		)
	lancetfish_router
		(
			.clk	(clk),
			.reset 	(reset),

		// -- puertos de entrada ------------------------------------- >>>>>
			.credit_out_xpos_dout	(credit_out_xpos_dout),
			.channel_xpos_din 		(channel_xpos_din),

			.credit_out_ypos_dout	(credit_out_ypos_dout),
			.channel_ypos_din 		(channel_ypos_din),

			.credit_out_xneg_dout	(credit_out_xneg_dout),
			.channel_xneg_din 		(channel_xneg_din),

			.credit_out_yneg_dout 	(credit_out_yneg_dout),
			.channel_yneg_din 		(channel_yneg_din),

			.credit_out_pe_dout		(credit_out_pe_dout),					// PE
			.channel_pe_din 		(channel_pe_din),

		// -- puertos de salida -------------------------------------- >>>>>
			.credit_in_xpos_din		(credit_in_xpos_din),
			.channel_xpos_dout 		(channel_xpos_dout),
			
			.credit_in_ypos_din		(credit_in_ypos_din),
			.channel_ypos_dout		(channel_ypos_dout),

			.credit_in_xneg_din		(credit_in_xneg_din),
			.channel_xneg_dout		(channel_xneg_dout),

			.credit_in_yneg_din		(credit_in_yneg_din),
			.channel_yneg_dout		(channel_yneg_dout),

			.credit_in_pe_din		(credit_in_pe_din),						// PE
			.channel_pe_dout		(channel_pe_dout)
	    );









// -- Bus Behaivoral Model --------------------------------------- >>>>>

	// -- Canal x+ ----------------------------------------------- >>>>>
		source
			#(
				.Thold(Thold)
			)
		xpos_in_channel
			(
				.clk 		(clk),
				.credit_in 	(credit_out_xpos_dout),
				.channel_out(channel_xpos_din)
			);


		sink
			#(
				.Thold(Thold)
			)
		xpos_out_channel
			(
				.clk 		(clk),
				.channel_in (channel_xpos_dout),
				.credit_out (credit_in_xpos_din)
			);

	// -- Canal y+ ----------------------------------------------- >>>>>
		source
			#(
				.Thold(Thold)
			)
		ypos_in_channel
			(
				.clk 		(clk),
				.credit_in 	(credit_out_ypos_dout),
				.channel_out(channel_ypos_din)
			);


		sink
			#(
				.Thold(Thold)
			)
		ypos_out_channel
			(
				.clk 		(clk),
				.channel_in (channel_ypos_dout),
				.credit_out (credit_in_ypos_din)
			);

	// -- Canal x- ----------------------------------------------- >>>>>
		source
			#(
				.Thold(Thold)
			)
		xneg_in_channel
			(
				.clk 		(clk),
				.credit_in 	(credit_out_xneg_dout),
				.channel_out(channel_xneg_din)
			);


		sink
			#(
				.Thold(Thold)
			)
		xneg_out_channel
			(
				.clk 		(clk),
				.channel_in (channel_xneg_dout),
				.credit_out (credit_in_xneg_din)
			);

	// -- Canal x- ----------------------------------------------- >>>>>
		source
			#(
				.Thold(Thold)
			)
		yneg_in_channel
			(
				.clk 		(clk),
				.credit_in 	(credit_out_yneg_dout),
				.channel_out(channel_yneg_din)
			);


		sink
			#(
				.Thold(Thold)
			)
		yneg_out_channel
			(
				.clk 		(clk),
				.channel_in (channel_yneg_dout),
				.credit_out (credit_in_yneg_din)
			);

		// -- Canal pe ------------------------------------------- >>>>>
		source
			#(
				.Thold(Thold)
			)
		pe_in_channel
			(
				.clk 		(clk),
				.credit_in 	(credit_out_pe_dout),
				.channel_out(channel_pe_din)
			);


		sink
			#(
				.Thold(Thold)
			)
		pe_out_channel
			(
				.clk 		(clk),
				.channel_in (channel_pe_dout),
				.credit_out (credit_in_pe_din)
			);




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
			repeat(4)
				begin
					@(posedge clk);
					#(Thold);
				end
			reset <= 1'b0;

		end	
	endtask : sync_reset



endmodule
