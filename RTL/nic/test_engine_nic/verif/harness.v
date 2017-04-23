`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////
`include "system.vh"




module harness();


parameter 	CYCLE 	= 100,
			Tsetup	= 15,
			Thold	= 5;


// -- Señales de interconexion ----------------------------------- >>>>>
		reg 	clk;
		reg 	reset;

	// -- input port --------------------------------------------- >>>>>
		wire 						credit_out_dout;
		wire [`CHANNEL_WIDTH-1:0]	input_channel_din;

	// -- output port -------------------------------------------- >>>>>
		wire 						credit_in_din;
		wire [`CHANNEL_WIDTH-1:0]	output_channel_dout;

	// -- interfaz :: processing node ---------------------------- >>>>>
		wire 							start_strobe;
		wire [(2 * `CHANNEL_WIDTH)-1:0]	wordA;
		wire [(2 * `CHANNEL_WIDTH)-1:0]	wordB;

		wire 							done_strobe;
		wire 							active_test_engine;
		wire [(2 * `CHANNEL_WIDTH)-1:0]	wordC;
		wire [(2 * `CHANNEL_WIDTH)-1:0]	wordD;



// -- DUT -------------------------------------------------------- >>>>>
	test_engine_network_interface DUT
		(
			.clk	(clk),
			.reset	(reset),

		// -- input port ----------------------------------------- >>>>>
			.credit_out_dout		(credit_out_dout), 
			.input_channel_din		(input_channel_din),

		// -- output port ---------------------------------------- >>>>>
			.credit_in_din			(credit_in_din), 
			.output_channel_dout	(output_channel_dout),

		// -- interfaz :: processing node ------------------------ >>>>>
			.start_strobe_dout		(start_strobe),
			.wordA_dout				(wordA),
			.wordB_dout				(wordB),
		
			.done_strobe_din		(done_strobe),
			.active_test_engine_din	(active_test_engine),
			.wordC_din				(wordC),
			.wordD_din				(wordD)
		);


// -- PE dummy --------------------------------------------------- >>>>>
	test_engine_dummy	
		#(
			.Thold(Thold)
		)
	test_engine_dummy
		(
			.clk(clk),

		// -- inputs --------------------------------------------- >>>>>
			.start_strobe_din(start_strobe),
			.wordA_din(wordA),
			.wordB_din(wordB),

		// -- outputs -------------------------------------------- >>>>>
			.done_strobe_dout(done_strobe),
			.active_test_engine_dout(active_test_engine),
			.wordC_dout(wordC),
			.wordD_dout(wordD)
	    );



	// -- Canal IO ----------------------------------------------- >>>>>
		source
			#(
				.Thold(Thold),
				.CREDITS(1)
			)
		input_channel
			(
				.clk 		(clk),
				.credit_in 	(credit_out_dout),
				.channel_out(input_channel_din)
			);


		sink
			#(
				.Thold(Thold)
			)
		output_channel
			(
				.clk 		(clk),
				.channel_in (output_channel_dout),
				.credit_out (credit_in_din)
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


endmodule // harness