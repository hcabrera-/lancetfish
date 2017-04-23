`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
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
//////////////////////////////////////////////////////////////////////////////////
`include "system.vh"

module testcase_basic();

	localparam X_LOCAL = 2;
	localparam Y_LOCAL = 2;

	//integer file;
	integer paquetes = 2000;
	integer index;
	
	harness harness();


	always
		harness.input_channel.receive_credit();

	always
		harness.output_channel.receive_packet();



	packet_generator	
		#(
			.port(`X_POS), 
			.pe_percent(8),
			.x_local(X_LOCAL),
			.y_local(Y_LOCAL)
		)
	packet_gen();


	initial
		begin: ciclo_principal

			harness.sync_reset();

			repeat(5)
				@(posedge harness.clk);

			for (index = 0; index < paquetes; index = index + 1)
				begin
					packet_gen.random_packet(index);
					harness.input_channel.send_packet(packet_gen.packet);
				end

			repeat(50)
				@(negedge harness.clk);

			$display("",);
			$display("",);
			$display("",);
			$display("|| -- PAQUETES ENVIADOS ---------------- >>>>>",);
			$display("",);
			$display("Paquetes procesados por dummy: ", harness.test_engine_dummy.packet_counter);
			$display("",);
			$display("",);
			
			$finish;

		end

endmodule // testcase_basic