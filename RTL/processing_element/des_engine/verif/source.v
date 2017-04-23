`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////


module source	#(parameter Thold = 5)
	(
		input  wire	clk,

	// -- input -------------------------------------------------- >>>>>
		input  wire active_des_engine_din,

	// -- output ------------------------------------------------- >>>>>
		output reg 			start_strobe_dout,

		output reg [0:63] 	plaintext_dout,
		output reg [0:63]	key_dout
    );




task encrypt;
	input [0:63]	plaintext;
	input [0:63]	key;
	begin
			if (active_des_engine_din)
				wait(active_des_engine_din == 0);

			plaintext_dout 		= plaintext;
			key_dout 			= key;
			start_strobe_dout 	= 1;
			@(posedge clk);
				#(Thold);
				//$display("plaintext:", plaintext_dout);
				//$display("key:", key_dout);
			plaintext_dout 		= {64{1'bx}};
			key_dout 			= {64{1'bx}};
			start_strobe_dout 	= 0;	
	end	
endtask : encrypt



endmodule // source
/* -- Plantilla de instancia
	source	
		#(
			.Thold(Thold)
		)
	entrada_de_datos
		(
			.clk(clk),

		// -- input ---------------------------------------------- >>>>>
			.active_des_engine_din(active_des_engine_din),

		// -- output --------------------------------------------- >>>>>
			.start_strobe_dout(start_strobe_dout),

			.plaintext_dout(plaintext_dout),
			.key_dout(key_dout),
	    );
*/