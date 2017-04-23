`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2015 05:17:53 PM
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
`include "packet_type.vh"
`include "system.vh"

module testcase_basic();

	localparam X_LOCAL = 2;
	localparam Y_LOCAL = 2;

	localparam xpos_packets = 7600;
	localparam ypos_packets = 8600;
	localparam xneg_packets = 9600;
	localparam yneg_packets = 10600;


	reg xpos = 1'b0;
	reg ypos = 1'b0;
	reg xneg = 1'b0;
	reg yneg = 1'b0;
	reg pe   = 1'b0;


harness harness();

	

	// -- x+
		always
			harness.xpos_in_channel.receive_credit();
		
	// -- y+
		always
			harness.ypos_in_channel.receive_credit();
			
	// -- x-
		always
			harness.xneg_in_channel.receive_credit();
			
	// -- y-
		always
			harness.yneg_in_channel.receive_credit();







	packet_generator	
		#(
			.port(`X_POS), 
			.pe_percent(3),
			.x_local(X_LOCAL),
			.y_local(Y_LOCAL)
		)
	xpos_gen();

	initial
		begin: xpos_injector

			integer  index;
				
			@(negedge harness.reset);

				for (index = 0; index < xpos_packets; index = index + 1)
					begin
						@(posedge harness.clk)
							#(harness.Thold)
						xpos_gen.random_packet(index);
						harness.xpos_in_channel.send_packet(xpos_gen.packet);
					end

			xpos = 1'b1;

		end





	packet_generator	
		#(
			.port(`X_NEG), 
			.pe_percent(5),
			.x_local(X_LOCAL),
			.y_local(Y_LOCAL)
		)
	xneg_gen();

	initial
		begin: xneg_injector

			integer  index;
				
			@(negedge harness.reset);

				for (index = 0; index < xneg_packets; index = index + 1)
					begin
						@(posedge harness.clk)
							#(harness.Thold)
						xneg_gen.random_packet(index);
						harness.xneg_in_channel.send_packet(xneg_gen.packet);					
					end

			xneg = 1'b1;

		end





	packet_generator	
		#(
			.port(`Y_POS), 
			.pe_percent(4),
			.x_local(X_LOCAL),
			.y_local(Y_LOCAL)
		)
	ypos_gen();

	initial
		begin: ypos_injector

			integer  index;
				
			@(negedge harness.reset);

				for (index = 0; index < ypos_packets; index = index + 1)
					begin
						@(posedge harness.clk)
							#(harness.Thold)
						ypos_gen.random_packet(index);
						harness.ypos_in_channel.send_packet(ypos_gen.packet);					
					end

			ypos = 1'b1;

		end





	packet_generator	
		#(
			.port(`Y_NEG), 
			.pe_percent(8),
			.x_local(X_LOCAL),
			.y_local(Y_LOCAL)
		)
	yneg_gen();

	initial
		begin: yneg_injector

			integer  index;
				
			@(negedge harness.reset);

			//harness.yneg_in_channel.send_packet({"DAT4", "DAT3", "DAT2", "DAT1", {2'b10, 3'd2, 3'd4, "Y--"}});

				for (index = 0; index < yneg_packets; index = index + 1)
					begin
						@(posedge harness.clk)
							#(harness.Thold)
						yneg_gen.random_packet(index);
						harness.yneg_in_channel.send_packet(yneg_gen.packet);					
					end

			yneg = 1'b1;

		end


initial
		begin : ciclo_principal

			integer total_envio;
			integer total_recepcion;

			
			harness.sync_reset();
			


			//repeat(120)
			//	@(negedge harness.clk);

			@(xpos & ypos & xneg & yneg)

			repeat(100)
				@(negedge harness.clk);



			total_envio =	harness.xpos_in_channel.packet_count	+
							harness.xneg_in_channel.packet_count	+
							harness.ypos_in_channel.packet_count	+
							harness.yneg_in_channel.packet_count;

			total_recepcion =	harness.xpos_out_channel.packet_count	+
								harness.xneg_out_channel.packet_count	+
								harness.ypos_out_channel.packet_count	+
								harness.yneg_out_channel.packet_count;

			$display("",);
			$display("",);
			$display("",);
			$display("|| -- PAQUETES ENVIADOS ---------------- >>>>>",);
			$display("",);
			$display("Paquetes enviados por x+: ", harness.xpos_in_channel.packet_count);
			$display("Paquetes enviados por x-: ", harness.xneg_in_channel.packet_count);
			$display("Paquetes enviados por y+: ", harness.ypos_in_channel.packet_count);
			$display("Paquetes enviados por y-: ", harness.yneg_in_channel.packet_count);
			$display("",);
			$display("Total de paquetes enviados'testcase': ", 	total_envio);
			$display("",);
			$display("|| -- PAQUETES RECIBIDOS --------------- >>>>>",);
			$display("",);
			$display("Paquetes recibidos por x+: ", harness.xpos_out_channel.packet_count);
			$display("Paquetes recibidos por x-: ", harness.xneg_out_channel.packet_count);
			$display("Paquetes recibidos por y+: ", harness.ypos_out_channel.packet_count);
			$display("Paquetes recibidos por y-: ", harness.yneg_out_channel.packet_count);
			$display("",);
			$display("Total de paquetes recibidos'testcase': ", total_recepcion);
			$display("",);
			$display("|| -- TOTALES -------------------------- >>>>>",);
			$display("",);
			$display("",);
			if(total_envio == total_recepcion) 
				$display("prueba satisfactoria",);
			else
				$display("prueba no satisfactoria",);
			$display("",);
			$display("",);
			$display("",);

			$finish;
		end

endmodule
