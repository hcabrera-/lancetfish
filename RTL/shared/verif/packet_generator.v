`timescale 1ns / 1ps

/*
-- Module Name:	Packet Generator
-- Description:	Este modulo ofrece tasks para la generacion de paquetes
				para pruebas de rendimiento y validacion de la red en
				chip.

-- Dependencies:	-- system.vh
					-- packet_type.vh

-- Parameters:		-- PORT: 	Direccion (x+, x-, y+, y-, pe) del 
								puerto de router para el cual se 
								generaran paquetes. La direccion limita
								los destinos validos de los paquetes 
								generados.
					-- pe_percent:	
								Porcentaje de paquetes que solicitaran
								ingreso al PE del nodo 
								(witness field = 0).
					-- X_LOCAL:	Direccion en 'X' del nodo inmediato al
								cual esta conectado el inyector de 
								paquetes (source.v).
					-- Y_LOCAL: Direccion en 'Y' del nodo inmediato al
								cual esta conectado el inyector de 
								paquetes (source.v).

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
	
-- History:	
	-- 05 de jun 2015:	Creacion	
	-- 12 de dic 2015: 	Se agrego al generador de paquetes aleatorios la
						capacidad de seleccionar una puerta de salida de 
						la red de manera aleatoria.
	-- 26 de dic 2015: 	Nueva task para generar paquetes recibiendo los
						siguientes datos: direccion destino, direccion
						de puerta y numero de serie. 
						(network_directed_packet)
*/
`include "packet_type.vh"
`include "system.vh"

module packet_generator 	#(
								parameter 	PORT 		= `X_POS,
								parameter	PE_RQS	 	= 5,
								parameter	X_LOCAL 	= 1,
								parameter	Y_LOCAL		= 1,
								parameter	X_WIDTH		= 2,
								parameter	Y_WIDTH 	= 2
							)();


/*
	-- Lista de tasks:

		- Random Packet Router
		- Random Performance Packet
		- Custom Packet
		- Null Packet
		- 
*/

// -- Variables Globales ----------------------------------------- >>>>>
	/*
		-- Descripcion:	
						-- x_dest_addr: Variable aleatoria de direccion 
										destino en X.
						-- y_dest_addr:	Variable aleatoria de direccion 
										destino en Y.
						-- packet:		Contenedor de paquete a liberar.
						-- ascii:		Variable para la conversion de
										numerosa caracteres ascii

	*/

	// -- Declaracion de variables publicas ---------------------- >>>>>
		reg `PACKET_TYPE 	packet;
		

	// -- Declaracion de variables privadas ---------------------- >>>>>
		reg [2:0] x_dest_addr = 3'b000;
		reg [2:0] y_dest_addr = 3'b000;

		reg [2:0] x_gate_addr = 3'b000;
		reg [2:0] y_gate_addr = 3'b000;

		integer   random_number = 0;

		reg [7:0] ascii;



// -- TASK:: NETWORK_DIRECTED_PACKET ----------------------------- >>>>>
	/*
		-- Descripcion:	
	*/
	task network_directed_packet;
			input [2 :0]	x_dest 			= 0;
			input [2 :0]	y_dest 			= 0;
			input [2 :0]	x_gate 			= 0;
			input [2 :0]	y_gate 			= 0;
			input [17:0]	extended_serial = 0;
		begin: directed_packet
			
			// -- Asignacion de valores a campos de cabecera ----- >>>>>
				packet `ID_HEAD = 1'b1;
				packet `TESTIGO = 1'b0;

				packet `DESTINO 		= {x_dest, y_dest};
				packet `PUERTA  		= {x_gate, y_gate};
				packet `EXTENDED_SERIAL = extended_serial;			

			// -- Asignacion de contenido a flits de datos ------- >>>>>
				if (PORT == `X_POS)
					packet `DATA_0 	= "x+  ";
				else if (PORT == `Y_POS)
					packet `DATA_0 	= "y+  ";
				else if (PORT == `X_NEG)
					packet `DATA_0 	= "x-  ";
				else if (PORT == `Y_NEG)
					packet `DATA_0 	= "y-  ";
				else if (PORT == `PE)
					packet `DATA_0 	= "pe  ";


				bin2ascii(x_gate);
				packet `DATA_1 	= {"x =",ascii};

				bin2ascii(y_gate);
				packet `DATA_2 	= {"y =",ascii};

				packet `DATA_3  = "NTST";
		end
	endtask


// -- TASK:: RANDOM_PACKET_ROUTER -------------------------------- >>>>>
/* 
	-- Descripcion:	** NOTA ** 	Esta rutina esta diseñada para evaluar
								routers o nodos de manera independiente.
								Utilizar esta rutina con una NoC 
								completa generara comportamientos 
								erraticos y posiblemente bloques de la
								red por destinos no validos para los 
								paquetes generados.

								El parametro PE_RQS determina si el 
								paquete generado solicitara ingreso 
								al PE del nodo (witness_field == 0).


					Generacion de paquetes a direcciones aleatorias. El
					contenido de los flits de datos generados esta 
					definido de la siguiente forma:

					Flit dato 1:	Puerto de ingreso a router (x+, x-,
									y+, y-).
					Flit dato 2:	Direccion en 'X' de destino.	
					Flit dato 3:	Direccion en 'Y' de destino.
					Flit dato 4:	Testigo de procesamiento (witness 
									field). Si el paquete pedira 
									ingreso al PE

					Este task requiere 2 parametros para su operacion:

					- serial: 	Numero de 12 bits que se asignara al 
								campo serial del flit de cabecera. La
								intencion de este parametro es la de 
								utilizarce en conjunto con una variable 
								indice de un loop para generar id a cada
								paquete.

					- seed:		Semilla para generadores de numeros
								aleatoreos de la funcion $random de 
								verilog.

								Un ejemplo de generacion de un numero 
								de semilla puede ser:

								integer seed;

								seed = $stime;
								random_packet(serial, seed);
*/
	task random_packet_router;
			input [11:0]	serial = 0;
			input [31:0]	seed   = 0;
		begin: random_packet

		// -- Seleccion de direccion destino --------------------- >>>>>

			/*
				-- Descripcion
			*/
			
			if (PORT == `X_POS)
				begin
					x_dest_addr 	= 1 + ({$random(seed)}%(X_WIDTH));
					
					while(x_dest_addr > X_LOCAL)
						x_dest_addr = 1 + ({$random(seed)}%(X_WIDTH));
				end				
			else if (PORT == `X_NEG)
				begin
					x_dest_addr 	= 1 + ({$random(seed)}%(X_WIDTH));
					
					while(x_dest_addr < X_LOCAL)
						x_dest_addr = 1 + ({$random(seed)}%(X_WIDTH));
				end
			else
				x_dest_addr 		= 1 + ({$random(seed)}%(X_WIDTH));




			if (PORT == `Y_POS)
				begin
					y_dest_addr 	= 1 + ({$random(seed)}%(Y_WIDTH));
							
					while(y_dest_addr > Y_LOCAL)
						y_dest_addr = 1 + ({$random(seed)}%(Y_WIDTH));
				end				
			else if (PORT == `Y_NEG)
				begin
					y_dest_addr 	= 1 + ({$random(seed)}%(Y_WIDTH));
							
					while(y_dest_addr < Y_LOCAL)
						y_dest_addr = 1 + ({$random(seed)}%(Y_WIDTH));
				end
			else
				y_dest_addr 		= 1 + ({$random(seed)}%(Y_WIDTH));
		


		// -- Seleccion de direccion de puerta de salida --------- >>>>>

			/*
				-- Descripcion
			*/

			random_number = {$random(seed)} % 4;

			if (random_number == `X_POS)
				begin
					x_gate_addr = X_WIDTH + 1;
					y_gate_addr = 1 + ({$random(seed)}%(Y_WIDTH));
				end
			else if (random_number == `Y_POS)
				begin
					x_gate_addr = 1 + ({$random(seed)}%(X_WIDTH));
					y_gate_addr = Y_WIDTH + 1;
				end
			else if (random_number == `X_NEG)
				begin
					x_gate_addr = 0;
					y_gate_addr = 1 + ({$random(seed)}%(Y_WIDTH));
				end
			else // random_number == Y_NEG
				begin
					x_gate_addr = 1 + ({$random(seed)}%(X_WIDTH));
					y_gate_addr = 0;
				end
				

			
		// -- Seleccion de valor para el 'Witness Field' --------- >>>>>
			
			packet `ID_HEAD = 1'b1;

			if ($unsigned($random(seed))%10 < PE_RQS)
				begin
					packet `TESTIGO = 1'b0;
					packet `DATA_3  = "NTST";
				end
			else
				begin					
					packet `TESTIGO = 1'b1;
					packet `DATA_3  = "TST ";
				end

		// -- Asignacion de valores a campos de cabecera --------- >>>>> 
			packet `DESTINO = {x_dest_addr, y_dest_addr};

			packet `PUERTA  = {x_gate_addr, y_gate_addr};

			packet `ORIGEN  = {6{1'b0}};

			packet `SERIAL  = serial;

			
		// -- Asignacion de contenido a flits de datos ----------- >>>>>
			if (PORT == `X_POS)
				packet `DATA_0 	= "x+  ";
			else if (PORT == `Y_POS)
				packet `DATA_0 	= "y+  ";
			else if (PORT == `X_NEG)
				packet `DATA_0 	= "x-  ";
			else if (PORT == `Y_NEG)
				packet `DATA_0 	= "y-  ";
			else if (PORT == `PE)
				packet `DATA_0 	= "pe  ";


			bin2ascii(x_dest_addr);
			packet `DATA_1 	= {"x =",ascii};

			bin2ascii(y_dest_addr);
			packet `DATA_2 	= {"y =",ascii};

		end	
	endtask : random_packet_router



// -- TASK:: RANDOM_PERFORMANCE_PACKET --------------------------- >>>>>
/* 
	-- Descripcion:	
*/
	task random_performance_packet;
			input [17:0]	serial = 0;
			input [31:0]	seed   = 0;
		begin: random_dn_packet

		// -- Seleccion de direccion destino --------------------- >>>>>

			/*
				-- Descripcion
			*/
			
			if (PORT == `X_POS)
				x_dest_addr = 0;
			else if (PORT == `X_NEG)
				x_dest_addr = X_WIDTH + 1;
			else
				x_dest_addr = 1 + ({$random(seed)}%(X_WIDTH));


			if (PORT == `Y_POS)
				y_dest_addr = 0;
			else if (PORT == `Y_NEG)
				y_dest_addr = Y_WIDTH + 1;
			else
				y_dest_addr = 1 + ({$random(seed)}%(Y_WIDTH));
			


		// -- Seleccion de direccion de puerta de salida --------- >>>>>

			/*
				-- Descripcion
			*/

			random_number = {$random(seed)} % 10;

			if (random_number < 6) // Xneg Gate
				begin
					x_gate_addr = 0;
					y_gate_addr = 1 + ({$random(seed)}%(Y_WIDTH));
				end
			else 					// Ypos Gate
				begin
					x_gate_addr = 1 + ({$random(seed)}%(X_WIDTH));
					y_gate_addr = Y_WIDTH + 1;
				end
			
				

			
		// -- Seleccion de valor para el 'Witness Field' --------- >>>>>
			packet `ID_HEAD = 1'b1;
			packet `TESTIGO = 1'b0;
			packet `DATA_3  = "NTST";
			

		// -- Asignacion de valores a campos de cabecera --------- >>>>> 
			packet `DESTINO = {x_dest_addr, y_dest_addr};

			packet `PUERTA  = {x_gate_addr, y_gate_addr};

			packet `ORIGEN  = serial[17:12];

			packet `SERIAL  = serial[11:0];

			
		// -- Asignacion de contenido a flits de datos ----------- >>>>>
			if (PORT == `X_POS)
				packet `DATA_0 	= "x+  ";
			else if (PORT == `Y_POS)
				packet `DATA_0 	= "y+  ";
			else if (PORT == `X_NEG)
				packet `DATA_0 	= "x-  ";
			else if (PORT == `Y_NEG)
				packet `DATA_0 	= "y-  ";
			else if (PORT == `PE)
				packet `DATA_0 	= "pe  ";


			bin2ascii(x_dest_addr);
			packet `DATA_1 	= {"x =",ascii};

			bin2ascii(y_dest_addr);
			packet `DATA_2 	= {"y =",ascii};

		end	
	endtask : random_performance_packet



// -- TASK:: CUSTOM_PACKET --------------------------------------- >>>>>
/* 
	-- Descripcion:	Paquete generado en su totalidad por datos 
					proporcionados en la invocacion del task.
*/
	task custom_packet;
			input 			testigo;
			input [5:0]		destino;
			input [5:0]		puerta;
			input [11:0]	serial;
			input [31:0]	dato1;
			input [31:0]	dato2;
			input [31:0]	dato3;
			input [31:0]	dato4;
		begin
		
			packet `ID_HEAD = 1'b1;
			packet `TESTIGO = testigo;
			packet `DESTINO = destino;
			packet `PUERTA  = puerta;
			packet `ORIGEN  = {6{1'b0}};
			packet `SERIAL  = serial;

			packet `DATA_0  = dato1;
			packet `DATA_1 	= dato2;
			packet `DATA_2 	= dato3;
			packet `DATA_3  = dato4;


		end	
	endtask : custom_packet



// -- TASK:: NULL_PACKET ----------------------------------------- >>>>>
/* 
	-- Descripcion:	Generacion de paquete con todos los campos y flits 
					en zero.
*/
	task null_packet;
		begin
		
			packet `ID_HEAD = 1'b0;
			packet `TESTIGO = 1'b0;
			packet `DESTINO = {6{1'b0}};
			packet `PUERTA  = {6{1'b0}};
			packet `ORIGEN  = {6{1'b0}};
			packet `SERIAL  = 11'b000_0000_0000;

			packet `DATA_0  = "_NULL";
			packet `DATA_1 	= "_NULL";
			packet `DATA_2 	= "_NULL";
			packet `DATA_3  = "_NULL";


		end	
	endtask : null_packet



// -- TASK:: BIN2ASCII ------------------------------------------ >>>>>
/* 
	-- Descripcion:	Conversor de binario a ascii en un rango de valores
					de 0 a 7.
*/
	task bin2ascii;
			input [2:0]	bin;
		begin
			if(bin == 3'b000)
				ascii = "0";
			else if(bin == 3'b001)
				ascii = "1";
			else if(bin == 3'b010)
				ascii = "2";
			else if(bin == 3'b011)
				ascii = "3";
			else if(bin == 3'b100)
				ascii = "4";
			else if(bin == 3'b101)
				ascii = "5";
			else if(bin == 3'b110)
				ascii = "6";
			else
				ascii = "7";
		end


	endtask : bin2ascii



endmodule

/* -- Plantilla de Instancia ------------------------------------- >>>>>
packet_generator 	
	#(
		.PORT 		(PORT),
		.pe_percent	(pe_percent),
		.X_LOCAL	(X_LOCAL),
		.Y_LOCAL	(Y_LOCAL),
		.X_WIDTH	(X_WIDTH),
		.Y_WIDTH	(Y_WIDTH)
	) 
packet_generator
	();

*/