`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2015 04:15:25 PM
// Design Name: 
// Module Name: source
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




module test_engine_dummy	#(parameter Thold = 5)
	(
		input wire clk,

	// -- inputs ------------------------------------------------- >>>>>
		input wire 								start_strobe_din,
		input wire [(2 * `CHANNEL_WIDTH)-1:0]	wordA_din,
		input wire [(2 * `CHANNEL_WIDTH)-1:0]	wordB_din,

	// -- outputs ------------------------------------------------ >>>>>
		output reg  							done_strobe_dout,
		output reg 								active_test_engine_dout,
		output reg  [(2 * `CHANNEL_WIDTH)-1:0]	wordC_dout,
		output reg  [(2 * `CHANNEL_WIDTH)-1:0]	wordD_dout
    );

	reg 	[63:0]	wordC;
	reg 	[63:0]	wordD;

	integer packet_counter = 0;
	
	event 	valid_data;



	initial
		begin
			done_strobe_dout 		= 0;
			active_test_engine_dout = 0;
			wordC_dout 				= 0;
			wordD_dout 				= 0;

		end



	always
		@(posedge start_strobe_din)
			begin
				@(posedge clk);
				#(Thold);
				
				wordC <= wordB_din;
				wordD <= wordA_din;
				active_test_engine_dout <= 1;
				
				repeat(16)
					@(posedge clk);
				#(Thold);
				-> valid_data;
			end



	always
		begin
			@(valid_data);
				active_test_engine_dout <= 0;

				done_strobe_dout <= 1;
				wordC_dout  <= wordC;
				wordD_dout	<= wordD;
				@(posedge clk);
					#(Thold);
				done_strobe_dout <= 0;
				wordC_dout  <= {64{1'bx}};
				wordD_dout  <= {64{1'bx}};
				packet_counter = packet_counter + 1;
		end


endmodule // test_engine_dummy

/* -- Plantilla de instancia ------------------------------------- >>>>>
test_engine_dummy	
	#(
		.Thold(Thold)
	)
test_engine_dummy
	(
		.clk(clk),

	// -- inputs ------------------------------------------------- >>>>>
		.start_strobe_din(start_strobe_din),
		.wordA_din(wordA_din),
		.wordB_din(wordB_din),

	// -- outputs ------------------------------------------------ >>>>>
		.done_strobe_dout(done_strobe_dout),
		.active_test_engine_dout(active_test_engine_dout),
		.wordC_dout(wordC_dout),
		.wordD_dout(wordD_dout)
    );
*/



