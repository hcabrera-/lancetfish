`timescale 1ns / 1ps

/*
-- Module Name:	Test Engine Network Core
-- Description:	Red de nucleos de procesamiento ligados a travez de una
				red en-chip. Los puertos frontera de todos los nodos
				finales de la red cuentan con sus terminales abiertas
				para la conexion de inyectores y receptores de paquetes.

-- Dependencies:	-- system.vh

-- Parameters:		

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
	(05/06/2015): 	Esta es una implementacion modificada del algoritmo
					WF. Require modificarse para pasar la alteracion al
					modulo wrapper (route_planner.v)
							

-- History:	
	-- Creacion 07 de Diciembre 2015
*/
`include "system.vh"


/*
	-- Nota: 	Los canales de entrada (xpos_inports, xneg_inports, 
				ypos_inports, yneg_inports) se encuentran descritos como
				un solo ramillete de señales.

				De manera posterior se dividen y asignan a buses 
				individuales.
*/
module test_engine_node_mesh	#(
									parameter X_WIDTH 		= 2,
									parameter Y_WIDTH 		= 2,
									parameter PROC_CYCLES 	= 5
								)
	(
		input wire clk,
		input wire reset,

	// -- inports  ----------------------------------------------- >>>>>
		input  wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_inports,
		output wire [0:Y_WIDTH-1]						xpos_credits_outports,
		
		input  wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_inports,
		output wire [0:Y_WIDTH-1]						xneg_credits_outports,
		
		input  wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_inports,
		output wire [0:X_WIDTH-1]						ypos_credits_outports,
		
		input  wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_inports,
		output wire [0:X_WIDTH-1]						yneg_credits_outports,

	// -- outports ----------------------------------------------- >>>>>
		output wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xpos_outports,
		input  wire [0:Y_WIDTH-1]						xpos_credits_inports,
		
		output wire [0:(Y_WIDTH * `CHANNEL_WIDTH)-1] 	xneg_outports,
		input  wire [0:Y_WIDTH-1]						xneg_credits_inports,
		
		output wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	ypos_outports,
		input  wire [0:X_WIDTH-1]						ypos_credits_inports,
		
		output wire [0:(X_WIDTH * `CHANNEL_WIDTH)-1] 	yneg_outports,
		input  wire [0:X_WIDTH-1]						yneg_credits_inports
	);



// -- Andamiaje para interconexion de buses de puertos ----------- >>>>>

	/*
		-- Descripcion:	Desplegado de lineas de conexion entre los 
						puertos IO de los nodos frontera de la red y los
						puertos IO del modulo network core.

						Los siguientes 2 generate se encaragar de 
						interconectar en primer lugar los puertos de
						entrada/salida en la direccion 'x-' y los 
						puertos	entrada/salida en la direccion 'x+'.

						El segundo bloque generate se encarga de la 
						misma tarea pero con los puertos en las 
						direcciones 'y-' y  'y+'.

						Al terminar la ejecucion de los bloques generate
						la red lucira de la siguiente manera:
		
											  Y+

											^	^
											|	|
											v 	v
										<->	N 	N <->
								X- 							X+
										<->	N 	N <->
											^	^
											|	|
											v 	v

											  Y-

						Donde:

							N: 		Nodo de red
							<->:	Canal de comunicacion.
							^
							|:		Canal de comunicacion.
							v
	*/


	// -- Declaracion temprana de señales ------------------------ >>>>>
		/*
			-- Descripcion:	Arreglo de lineas de interconexion para la
							comunicacion entre nodos. Las señales se 
							encuentran organizadas en el sentido de 
							filas (rows) y columnas (col).

							Las señales con denominador right indican 
							que se conectaran a canales de comunicacion
							que entran por los puertos 'x-' de los 
							nodos, mientras que las señales con el 
							denominador left indica el flujo de datos 
							en direccion de los puertos 'x+' de los 
							nodos de red.

							Las señales con denominador 'up' se asocian
							a puertos en direccion 'y-', mientras que 
							las señales 'down' se viculan a puertos 
							'y+' .

		*/
		wire [`CHANNEL_WIDTH-1:0] row_right_channels	[0:X_WIDTH][0:Y_WIDTH-1];
		wire 					  row_left_credit	 	[0:X_WIDTH][0:Y_WIDTH-1];

		wire [`CHANNEL_WIDTH-1:0] row_left_channels  	[0:X_WIDTH][0:Y_WIDTH-1];
		wire 					  row_right_credit		[0:X_WIDTH][0:Y_WIDTH-1];
		

		wire [`CHANNEL_WIDTH-1:0] col_down_channels 	[0:X_WIDTH-1][0:Y_WIDTH];
		wire 					  col_up_credit		 	[0:X_WIDTH-1][0:Y_WIDTH];

		wire [`CHANNEL_WIDTH-1:0] col_up_channels		[0:X_WIDTH-1][0:Y_WIDTH];
		wire 					  col_down_credit 	 	[0:X_WIDTH-1][0:Y_WIDTH];

		genvar rows;
		genvar cols;
		


	/*
		-- Descripcion:	Interconexion entre puertos X-(xneg_inports/
						xneg_outports) y X+(xpos_inports/xpos_outports) 
						con lineas de conexion de canales a nodos de la 
						perifereia de la malla.
						
						Solo se establecen las conexion para los nodos
						en los limites izquierdo y derecho de la red.
	*/
		generate
			for (rows = 0; rows < Y_WIDTH; rows = rows + 1) 
				begin				
				
				// -- inport / outport X- bus ------------------------ >>>>>
					assign row_right_channels [0][rows] = xneg_inports 	  [rows * `CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
					assign xneg_credits_outports [rows] = row_left_credit [0][rows];

					assign xneg_outports 	[rows*`CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = row_left_channels [0][rows];
					assign row_right_credit [0][rows] 	= xneg_credits_inports [rows];
					

				// -- inport / outport X+ bus ------------------------ >>>>>
					assign row_left_channels [X_WIDTH][rows] = xpos_inports [rows * `CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
					assign xpos_credits_outports       [rows] = row_right_credit  [X_WIDTH][rows];

					assign xpos_outports 	 [rows*`CHANNEL_WIDTH:(rows * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = row_right_channels[X_WIDTH][rows];
					assign row_left_credit   [X_WIDTH][rows] = xpos_credits_inports [rows];
					

				end
		endgenerate



	/*
		-- Descripcion:	Interconexion entre puertos Y-(yneg_inports/
						yneg_outports) y Y+(ypos_inports/ypos_outports) 
						con lineas de conexion de canales a nodos de la 
						perifereia de la malla.
						
						Solo se establecen las conexion para los nodos
						en los limites superior e inferior de la red.
	*/
		generate
			for (cols = 0; cols < X_WIDTH; cols = cols + 1) 
				begin				
				
				
				// -- inport / outport Y+ bus ------------------------ >>>>>
					assign col_down_channels	  [cols][Y_WIDTH] 	= ypos_inports  [cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
					assign ypos_credits_outports  [cols]    		= col_up_credit [cols][Y_WIDTH];

					assign ypos_outports 	[cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = col_up_channels  [cols][Y_WIDTH];
					assign col_down_credit  [cols][Y_WIDTH] = ypos_credits_inports [cols];

				
				// -- inport / outport Y- bus ------------------------ >>>>>
					assign col_up_channels  	  [cols][0]  = yneg_inports [cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1];
					assign yneg_credits_outports  [cols] 	 = col_down_credit  [cols][0];

					assign yneg_outports [cols * `CHANNEL_WIDTH:(cols * `CHANNEL_WIDTH + `CHANNEL_WIDTH) - 1] = col_down_channels[cols][0];
					assign col_up_credit [cols][0] = yneg_credits_inports [cols];

				end
		endgenerate






// -- Instancia de Nodos ----------------------------------------- >>>>>
	/*
		-- Descripcion: Bloque generate para crear las instancias de 
						nodos de procesamiento que conforman la red.

						La creacion de nodos se lleva en orden de  
						columnas / filas, es decir, se en primer lugar
						se crean todos los nodos de la columna cero,
						despues la columna uno y asi sucesivamente.

						La interconexion entre nodos se lleva a cabo 
						mediante los arreglos de lineas de enlace:

							* 	row_right_channels
							*	row_left_credit
							*	row_left_channels
							* 	row_right_credit

							*	col_down_channels
							*	col_up_credit
							*	col_up_channels
							*	col_down_credit

						Los nodos se encuentran enumerados a partir de 
						las coordenanadas 1,1 a n,n. El rango de 
						direcciones que contiene x = 0 y y = 0 estan 
						reservados para inyectores, receptores y 
						reflectores de paquetes.
	*/
	generate

		for (cols = 0; cols < X_WIDTH; cols = cols + 1) 
			begin: columna
				for (rows = 0; rows < Y_WIDTH; rows = rows + 1) 
					begin: network_node

						test_engine_node	
							#(
								.X_LOCAL(cols + 1),
								.Y_LOCAL(rows + 1),
								.X_WIDTH(X_WIDTH),
								.Y_WIDTH(Y_WIDTH),
								.ROUNDS	(PROC_CYCLES)
							)
						test_engine_node
							(
								.clk	(clk),
								.reset 	(reset),

							// -- puertos de entrada ------------------------------------- >>>>>
								.channel_xneg_din 		(row_right_channels [cols][rows]),
								.credit_out_xneg_dout	(row_left_credit   	[cols][rows]),

								.channel_xpos_din 		(row_left_channels  [cols+1][rows]),
								.credit_out_xpos_dout	(row_right_credit   [cols+1][rows]),
								
			
								.channel_ypos_din 		(col_down_channels 	[cols][rows+1]),
								.credit_out_ypos_dout	(col_up_credit   	[cols][rows+1]),

								.channel_yneg_din 		(col_up_channels   	[cols][rows]),
								.credit_out_yneg_dout 	(col_down_credit    [cols][rows]),

							// -- puertos de salida -------------------------------------- >>>>>
								.channel_xneg_dout		(row_left_channels 	[cols][rows]),
								.credit_in_xneg_din		(row_right_credit   [cols][rows]),
								
								.channel_xpos_dout 		(row_right_channels	[cols+1][rows]),
								.credit_in_xpos_din		(row_left_credit 	[cols+1][rows]),

								
								.channel_ypos_dout		(col_up_channels	[cols][rows+1]),
								.credit_in_ypos_din		(col_down_credit	[cols][rows+1]),				
								
								.channel_yneg_dout		(col_down_channels	[cols][rows]),
								.credit_in_yneg_din		(col_up_credit 		[cols][rows])
								
							);
					end
			
			end

	endgenerate



endmodule


/* -- Plantilla de instancia ------------------------------------- >>>>>
// -- Ancho de Frente de red (X)
//		canales 	:: [0:(`X_WIDTH * `CHANNEL_WIDTH)-1]
//		creditos 	:: [0:`X_WIDTH-1]
// -- Ancho de Frente de red (Y)
//		canales 	:: [0:(`X_WIDTH * `CHANNEL_WIDTH)-1]
//		creditos 	:: [0:`X_WIDTH-1]

test_engine_node_mesh	
	#(
		.X_WIDTH(2),
		.Y_WIDTH(2)
	)
UUT
	(
		.clk					(clk),
		.reset					(reset),
	// -- inports  ----------------------------------------------- >>>>>
		.xpos_inports 			(xpos_inports),
		.xpos_credits_outports	(xpos_credits_outports),
		
		.xneg_inports 			(xneg_inports),
		.xneg_credits_outports 	(xneg_credits_outports),
		
		.ypos_inports 			(ypos_inports),
		.ypos_credits_outports 	(ypos_credits_outports),
		
		.yneg_inports 			(yneg_inports),
		.yneg_credits_outports 	(yneg_credits_outports),
	// -- outports ----------------------------------------------- >>>>>
		.xpos_outports 			(xpos_outports),
		.xpos_credits_inports 	(xpos_credits_inports),
		
		.xneg_outports 			(xneg_outports),
		.xneg_credits_inports 	(xneg_credits_inports),
		
		.ypos_outports 			(ypos_outports),
		.ypos_credits_inports  	(ypos_credits_inports),
		
		.yneg_outports 			(yneg_outports),
		.yneg_credits_inports 	(yneg_credits_inports)
	);
// --------------------------------------------------------------- >>>>>*/ 