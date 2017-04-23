`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////
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
////////////////////////////////////////////////////////////////////////
`include "packet_type.vh"
`include "system.vh"


module testcase_basic();

	localparam 	X_WIDTH = 2;
	localparam 	Y_WIDTH = 2;


// -- Instancia de harnes de pruebas ----------------------------- >>>>>
	harness 
		#(
			.X_WIDTH(X_WIDTH),
			.Y_WIDTH(Y_WIDTH)
		)
	arnes	
		();



// -- variables de simulacion ------------------------------------ >>>>>
	genvar index_x;
	genvar index_y;


// -- Generadores de trafico ------------------------------------- >>>>>

	// -- Generadores de puertos en X ---------------------------- >>>>>
	generate
		for(index_x = 0; index_x < Y_WIDTH; index_x = index_x + 1)
			begin:xneg_generators
			
			// -- Bloque de inyector para puertos XNEG ----------- >>>>>	
				initial
					begin: xneg_injectors

						integer  packet_count;
						integer  seed;
								
						@(negedge arnes.reset);

						for (packet_count = 0; packet_count < 30; packet_count = packet_count + 1)
							begin
								@(posedge arnes.clk)
									#(arnes.Thold)
								seed = $stime;
								arnes.xneg_ports[index_x].packet_generator.random_packet(packet_count, seed);
								arnes.xneg_ports[index_x].source.send_packet(arnes.xneg_ports[index_x].packet_generator.packet);					
							end
						//xneg = 1'b1;
					end


			// -- Bloque de inyector para puertos XPOS ----------- >>>>>	
				initial
					begin: xpos_injectors

						integer  packet_count;
						integer  seed;
								
						@(negedge arnes.reset);

						for (packet_count = 0; packet_count < 30; packet_count = packet_count + 1)
							begin
								@(posedge arnes.clk)
									#(arnes.Thold)
								seed = $stime;
								arnes.xpos_ports[index_x].packet_generator.random_packet(packet_count, seed);
								arnes.xpos_ports[index_x].source.send_packet(arnes.xpos_ports[index_x].packet_generator.packet);					
							end
						//xneg = 1'b1;
					end

			end
	endgenerate



	// -- Generadores de puertos en Y ---------------------------- >>>>>
	generate
		for(index_y = 0; index_y < X_WIDTH; index_y = index_y + 1)
			begin:yneg_generators
			
			// -- Bloque de inyector para puertos YNEG ----------- >>>>>	
				initial
					begin: yneg_injectors

						integer  packet_count;
						integer  seed;
								
						@(negedge arnes.reset);

						for (packet_count = 0; packet_count < 30; packet_count = packet_count + 1)
							begin
								@(posedge arnes.clk)
									#(arnes.Thold)
								seed = $stime;
								arnes.yneg_ports[index_y].packet_generator.random_packet(packet_count, seed);
								arnes.yneg_ports[index_y].source.send_packet(arnes.yneg_ports[index_y].packet_generator.packet);					
							end
						//xneg = 1'b1;
					end


			// -- Bloque de inyector para puertos YPOS ----------- >>>>>	
				initial
					begin: ypos_injectors

						integer  packet_count;
						integer  seed;
								
						@(negedge arnes.reset);

						for (packet_count = 0; packet_count < 30; packet_count = packet_count + 1)
							begin
								@(posedge arnes.clk)
									#(arnes.Thold)
								seed = $stime;
								arnes.ypos_ports[index_y].packet_generator.random_packet(packet_count, seed);
								arnes.ypos_ports[index_y].source.send_packet(arnes.ypos_ports[index_y].packet_generator.packet);					
							end
						//xneg = 1'b1;
					end

			end
	endgenerate



initial
	begin: ciclo_principal
		
		arnes.sync_reset();

		repeat(100)
			@(negedge harness.clk);	

	end



endmodule