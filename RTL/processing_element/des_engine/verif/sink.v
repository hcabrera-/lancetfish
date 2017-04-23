`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2015 04:15:25 PM
// Design Name: 
// Module Name: sink
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


module sink	#(parameter Thold = 5)
	(
		input wire	clk,
		
		input wire 			done_strobe_din,
		input wire [0:63]	ciphertext_din
    );

integer fp;

initial
	fp = $fopen("/home/hcabrera/Dropbox/tesis/noc/work/verilog/project_lancetfish/processing_node/des_engine/verif/results_mem.dat");

always
	@(posedge done_strobe_din)
		begin
			#(Thold);
			$fdisplayh(fp, "", ciphertext_din[0 : 7]); 
			$fdisplayh(fp, "", ciphertext_din[8 :15]); 
			$fdisplayh(fp, "", ciphertext_din[16:23]); 
			$fdisplayh(fp, "", ciphertext_din[24:31]); 
			$fdisplayh(fp, "", ciphertext_din[32:39]); 
			$fdisplayh(fp, "", ciphertext_din[40:47]);
			$fdisplayh(fp, "", ciphertext_din[48:55]);
			$fdisplayh(fp, "", ciphertext_din[56:63]);
			$display("ciphertext:", ciphertext_din);
		end


endmodule // sink
/* -- Plantilla de instancia ------------------------------------- >>>>>
sink	
	#(
		.Thold(Thold)
	)
receptor_datos
	(
		.clk(clk),
	// -- inputs ------------------------------------------------- >>>>>
		.done_strobe_din(done_strobe_din),
		.ciphertext_din(ciphertext_din)
    );
*/