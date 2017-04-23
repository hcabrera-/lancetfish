`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.06.2015 12:30:30
// Design Name: 
// Module Name: testcase_basic
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
module testcase_basic();

	harness 	harness();
	data_memory memoria();





	parameter KEY 	= "01234567";
	parameter ROWS	= 133;
	parameter COLS	= 200;

	parameter 	Taddress = (ROWS * COLS) / 8;


	


	initial
		begin: injector
			integer index;
			harness.sync_reset();

						
			for (index = 0; index < Taddress; index = index + 1) 
				begin
					memoria.read(index);
					harness.source.encrypt(memoria.memory_data, KEY);
				end

			//harness.source.encrypt("memories", "slipknot");
			repeat(50)
				@(posedge harness.clk);
			$fclose(harness.sink.fp);
			$finish;		
		end

endmodule // testcase_basic