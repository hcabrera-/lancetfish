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


module testcase_TENC_no_xpos_source();

	localparam 	X_WIDTH 		= 5;
	localparam 	Y_WIDTH 		= 5;
	localparam 	PROC_CYCLES 	= 16;
	localparam 	TOTAL_PAQUETES  = 100000;
	localparam 	TRAFFIC 		= 10;

// 

	//localparam 	NODOS_INYECCION = X_WIDTH + X_WIDTH;
	localparam 	NODOS_INYECCION = X_WIDTH;
	localparam 	STEP 			= TOTAL_PAQUETES / NODOS_INYECCION;



// -- Instancia de harnes de pruebas ----------------------------- >>>>>
/*
	-- Descripcion: Instancia de Nucleo de la red + los modulos source y
					sink para la captura y emicion de paquetes de 
					prueba.

					Este arnes incluye deflectores en los puertos del 
					cuadrante 'x+' y 'y-'.

	-- Parametros:

				-- X_WIDTH:	Numero de nodos en la dimension X de la red.
							En otras palabra el numero de nodos por fila
							de la red.

				-- Y_WIDTH:	Numero de nodos en la dimension Y de la red.
							En otras palabra el numero de nodos por 
							columna de la red.

				-- PROC_CYCLES:	Numero de ciclos de procesamiento que
								ejecutara el modulo 'test_engine' de 
								cada nodo de la red.

*/
	harness_TENC 
		#(
			.X_WIDTH		(X_WIDTH),
			.Y_WIDTH		(Y_WIDTH),
			.PROC_CYCLES	(PROC_CYCLES)
		)
	arnes	
		();



// -- variables de simulacion ------------------------------------ >>>>>
	integer sum = 0;

/*
	-- Descripcion:	La variable 'x_deflector' almacena las direcciones
					'x' de todos los deflectores de la red. La variable 
					'y_deflector' lleva a cabo la misma tarea pero con 
					las direcciones en 'y'.

					Las variables 'x_gate' y 'y_gate' cumplen la misma 
					tarea que las variables anteriormente mencionadas 
					pero para las 'gate' de salida de la red.
*/

	integer x_deflectors [0:(NODOS_INYECCION+5) - 1] = 	{
														1,
														5,
														2,
														4,
														3,
														3,
														4,
														2,
														5,
														1
													};

	integer y_deflectors [0:(NODOS_INYECCION+5) - 1] = 	{
														0,
														6,
														0,
														6,
														0,
														6,
														0,
														6,
														0,
														6
													};

	integer x_gates [0:(NODOS_INYECCION+5) - 1] 	= 	{
														1,
														5,
														1,
														5,
														1,
														5,
														1,
														5,
														1,
														5
													};

	integer y_gates [0:(NODOS_INYECCION+5) - 1] 	= 	{
														1,
														5,
														2,
														4,
														3,
														3,
														4,
														2,
														5,
														1
													};





// -- Generadores de trafico ------------------------------------- >>>>>
genvar index_y;

	// -- Generadores de puertos en X- --------------------------- >>>>>
	generate
		for(index_y = 0; index_y < Y_WIDTH; index_y = index_y + 1)
			begin: XNEG_generator
			
			
			// -- Bloque de inyector para puertos XNEG ----------- >>>>>	
				initial
					begin: xneg_injectors

						integer packet_count;
						integer	dest;
						integer gate;
						integer traffic_arbiter;
						integer seed;
						integer packet_serial;

					// -- Inicializar Variables ------------------ >>>>>

						seed 			= $stime + (((-1)^(index_y + 2)) * ((Y_WIDTH * STEP) + (index_y * STEP)));
						//traffic_arbiter = ({$random(seed)}) %  10;
						//dest 			= ({$random(seed)}) %  NODOS_INYECCION;
						//gate 			= (dest * STEP) 	%  NODOS_INYECCION;
						traffic_arbiter = ({$random(seed)}) %  10;
						dest 			= index_y;
						gate 			= index_y;
						packet_serial	= 0;

					// -- Habilitacion de observador ------------- >>>>>

						arnes.xneg_ports[index_y].source.open_observer();

					// -- Espera de Reset de la red -------------- >>>>>
						@(negedge arnes.reset);

					// -- Inicio de ciclo de envio de paquetes --- >>>>>

						for (packet_count = (index_y * STEP); packet_count < ((index_y * STEP) + STEP); packet_count = packet_count + 1)
							begin
								@(posedge arnes.clk)
									#(arnes.Thold)

								
								if (traffic_arbiter < TRAFFIC)
									begin
										arnes.xneg_ports[index_y].packet_generator.network_directed_packet(x_deflectors[dest], y_deflectors[dest], x_gates[gate], y_gates[gate], packet_serial);
										arnes.xneg_ports[index_y].source.send_packet(arnes.xneg_ports[index_y].packet_generator.packet);
										packet_serial = packet_serial + 1;
									end
								else
									begin
										packet_count = packet_count - 1;
									end

								traffic_arbiter = (traffic_arbiter + 1) % 10;
								dest = (dest + 1) % (NODOS_INYECCION+5);
								gate = (gate + 1) % (NODOS_INYECCION+5);
							end
						
						sum = sum + 1;
						
						#(10);

						arnes.xneg_ports[index_y].source.close_observer();

					end



			// -- Observador de salida --------------------------- >>>>>
				initial
					begin

						arnes.xneg_ports[index_y].sink.open_observer();

						@(negedge arnes.reset);

						@(posedge arnes.clk & sum == (NODOS_INYECCION));

						repeat(400)
							@(negedge arnes.clk);

						arnes.xneg_ports[index_y].sink.close_observer();

					end

			end
	endgenerate



/*
	// -- Generadores de puertos en Y+ --------------------------- >>>>>
	generate
		for(index_y = 0; index_y < Y_WIDTH; index_y = index_y + 1)
			begin: XPOS_generator
			
			// -- Bloque de inyector para puertos YPOS ----------- >>>>>	
				initial
					begin: xpos_injectors

						integer packet_count;
						integer	dest;
						integer gate;
						integer traffic_arbiter;
						integer seed;
						integer packet_serial;

					// -- Inicializar Variables ------------------ >>>>>

						seed 			= $stime + (((-1)^(index_y + 2)) * ((X_WIDTH * STEP) + (index_y * STEP)));
						traffic_arbiter = ({$random(seed)}) %  10;
						//dest 			= ({$random(seed)}) %  NODOS_INYECCION;
						//gate 			= (dest * STEP) 	%  NODOS_INYECCION;
						dest 			= index_y + 5;
						gate 			= index_y + 5;
						packet_serial	= 0;

					// -- Habilitacion de observador ------------- >>>>>

						arnes.xpos_ports[index_y].source.open_observer();

					// -- Espera de Reset de la red -------------- >>>>>

						@(negedge arnes.reset);

					// -- Inicio de ciclo de envio de paquetes --- >>>>>

						for (packet_count = ((Y_WIDTH * STEP) + (index_y * STEP)); packet_count < ((Y_WIDTH * STEP) + ((index_y + 1) * STEP)); packet_count = packet_count + 1)
							begin
								@(posedge arnes.clk)
									#(arnes.Thold)

								if (traffic_arbiter < TRAFFIC)
									begin
										arnes.xpos_ports[index_y].packet_generator.network_directed_packet(x_deflectors[dest], y_deflectors[dest], x_gates[gate], y_gates[gate], packet_serial);
										arnes.xpos_ports[index_y].source.send_packet(arnes.xpos_ports[index_y].packet_generator.packet);
										packet_serial = packet_serial + 1;
									end
								else
									begin
										packet_count = packet_count - 1;
									end

								traffic_arbiter = (traffic_arbiter + 1) % 10;
								dest = (dest + 1) % NODOS_INYECCION;
								gate = (gate + 1) % NODOS_INYECCION;
							end
						
						sum = sum + 1;

						#(10);

						arnes.xpos_ports[index_y].source.close_observer();

					end






			// -- Observador de salida --------------------------- >>>>>
				initial
					begin

						arnes.xpos_ports[index_y].sink.open_observer();

						@(negedge arnes.reset);


						@(posedge arnes.clk & sum == (NODOS_INYECCION));

						repeat(400)
							@(negedge arnes.clk);

						arnes.xpos_ports[index_y].sink.close_observer();

					end

			end
	endgenerate
*/





initial
		begin : ciclo_principal

			integer total_recepcion;
			integer fp;


			arnes.sync_reset();

			@(posedge arnes.clk & sum == (NODOS_INYECCION))
			// DBG:	$display("suma: ", sum);

			repeat(800)
				@(negedge arnes.clk);


			fp = $fopen("reception_resume.dat", "w");
			if(!fp)
				$display("Could not open reception_resume.dat");
			else
				$display("Success opening reception_resume.dat");


			total_recepcion =	arnes.xpos_ports[0].sink.packet_count	+
								arnes.xpos_ports[1].sink.packet_count	+
								arnes.xpos_ports[2].sink.packet_count	+
								arnes.xpos_ports[3].sink.packet_count	+
								arnes.xpos_ports[4].sink.packet_count	+
								arnes.xneg_ports[0].sink.packet_count	+
								arnes.xneg_ports[1].sink.packet_count	+
								arnes.xneg_ports[2].sink.packet_count	+
								arnes.xneg_ports[3].sink.packet_count	+
								arnes.xneg_ports[4].sink.packet_count;

			$fdisplay(fp, "%d", arnes.xneg_ports[0].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xneg_ports[1].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xneg_ports[2].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xneg_ports[3].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xneg_ports[4].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xpos_ports[0].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xpos_ports[1].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xpos_ports[2].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xpos_ports[3].sink.packet_count);
			$fdisplay(fp, "%d", arnes.xpos_ports[4].sink.packet_count);
				$fclose(fp);
			$display("reception_resume.dat se cerro de manera exitosa");
			

			$display("",);
			$display("Total de paquetes enviados 'xpos(5,1)': ", arnes.xpos_ports[0].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xpos(5,2)': ", arnes.xpos_ports[1].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xpos(5,3)': ", arnes.xpos_ports[2].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xpos(5,4)': ", arnes.xpos_ports[3].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xpos(5,5)': ", arnes.xpos_ports[4].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xneg(1,1)': ", arnes.xneg_ports[0].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xneg(1,2)': ", arnes.xneg_ports[1].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xneg(1,3)': ", arnes.xneg_ports[2].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xneg(1,4)': ", arnes.xneg_ports[3].source.packet_count);
			$display("",);
			$display("Total de paquetes enviados 'xneg(1,5)': ", arnes.xneg_ports[4].source.packet_count);
			$display("",);
			$display("",);
			$display("",);
			
			$display("",);
			$display("",);
			$display("Total de paquetes recibidos 'xpos(5,1)': ", arnes.xpos_ports[0].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xpos(5,2)': ", arnes.xpos_ports[1].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xpos(5,3)': ", arnes.xpos_ports[2].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xpos(5,4)': ", arnes.xpos_ports[3].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xpos(5,5)': ", arnes.xpos_ports[4].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xneg(1,1)': ", arnes.xneg_ports[0].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xneg(1,2)': ", arnes.xneg_ports[1].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xneg(1,3)': ", arnes.xneg_ports[2].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xneg(1,4)': ", arnes.xneg_ports[3].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'xneg(1,5)': ", arnes.xneg_ports[4].sink.packet_count);
			$display("",);
			$display("Total de paquetes recibidos 'testcase': ", total_recepcion);

			#(10);
            

			$stop;
			$finish;
		end



endmodule