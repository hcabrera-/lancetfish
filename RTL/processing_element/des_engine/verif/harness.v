`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////
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
module harness();

parameter 	CYCLE 	= 100,
			Tsetup	= 15,
			Thold	= 5;



// -- Señales de interconexion ----------------------------------- >>>>>
		reg 		clk;
		reg 		reset;

	// -- input -------------------------------------------------- >>>>>
		wire 		start_strobe_din;

		wire [0:63] plaintext_din;
		wire [0:63]	key_din;

	// -- output ------------------------------------------------- >>>>>
		wire 		done_strobe_dout;
		wire 		active_des_engine_dout;
		wire [0:63]	ciphertext_dout;


// -- DUT -------------------------------------------------------- >>>>>
des_core	des_engine
	(
		.clk(clk),
		.reset(reset),

	// -- input -------------------------------------------------- >>>>>
		.start_strobe_din		(start_strobe_din),

		.plaintext_din			(plaintext_din),
		.key_din 				(key_din),

	// -- output ------------------------------------------------- >>>>>
		.done_strobe_dout 		(done_strobe_dout),
		.active_des_engine_dout	(active_des_engine_dout),
		.ciphertext_dout 		(ciphertext_dout)
    );



// -- Bus Behaivoral Model --------------------------------------- >>>>>

	source	
		#(
			.Thold(Thold)
		)
	source
		(
			.clk(clk),
		// -- input ------------------------------------------ >>>>>
			.active_des_engine_din(active_des_engine_dout),

		// -- output ----------------------------------------- >>>>>
			.start_strobe_dout(start_strobe_din),
			.plaintext_dout(plaintext_din),
			.key_dout(key_din)
	    );

	sink	
		#(
			.Thold(Thold)
		)
	sink
		(
			.clk(clk),
		// -- inputs ------------------------------------------------- >>>>>
			.done_strobe_din(done_strobe_dout),
			.ciphertext_din(ciphertext_dout)
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