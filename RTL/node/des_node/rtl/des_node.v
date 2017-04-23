`timescale 1ns / 1ps

/*
-- Module Name:	DES Node

-- Description:	Top level de un nodo de la red en-chip. Vale la pena notar
				que las interfaces fuera del modulo son las mismas que las
				de un router de red, la razon de esto es que el puerto del
				elemento de procesamiento de cada nodo solo tiene acceso 
				exterior por medio de un canal del router. 


-- Dependencies:	-- system.vh
					-- router.v
					-- data_path.v


-- Parameters:		-- X_LOCAL:		Direccion en dimension "x" del nodo 
									en la red.
					-- Y_LOCAL:		Direccion en dimension "y" del nodo 
									en la red.
					-- PE:			Elemento de procesamiento. Este 
									parametro representa una cadena de
									texto con el nombre del RTL de la
									unida funcional del nodo.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 05 de Junio 2015: 	Creacion
	-- 11 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control. 
	-- 14 de Junio 2015: 	Actualizacion de instancias de camino de 
							datos y camino de control. 
*/
`include "system.vh"


module des_node	#(
					parameter 	X_LOCAL 	= 2,
					parameter	Y_LOCAL 	= 2
				)
	(
		input wire clk,
		input wire reset,

	// -- puertos de entrada ------------------------------------- >>>>>
		output wire	credit_out_xpos_dout,
		input wire  [`CHANNEL_WIDTH-1:0]	channel_xpos_din,

		output wire	credit_out_ypos_dout,
		input wire  [`CHANNEL_WIDTH-1:0]	channel_ypos_din,

		output wire	credit_out_xneg_dout,
		input wire  [`CHANNEL_WIDTH-1:0]	channel_xneg_din,

		output wire	credit_out_yneg_dout,
		input wire  [`CHANNEL_WIDTH-1:0]	channel_yneg_din,


	// -- puertos de salida -------------------------------------- >>>>>
		input wire 	credit_in_xpos_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_xpos_dout,
		
		input wire 	credit_in_ypos_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_ypos_dout,

		input wire 	credit_in_xneg_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_xneg_dout,

		input wire 	credit_in_yneg_din,
		output wire [`CHANNEL_WIDTH-1:0]	channel_yneg_dout

	/* -- Salida de bit de paridad para Llave de encriptacion ---- >>>>>

		Descripcion:	Activar para tener acceso al bit de paridad
						generado a partir de la llave de encriptacion
						de DES.
	*/
		//output wire parity_check_dout
	
	);





/*
-- Instancia :: Router

-- Descripcion:	Elemento de distribucion de informacion para el nodo.
				Todos lso router son homogeneos, es decir tienen 4
				canales bidireccionales de comunicacion para 
				interconectarse con hasta 4 vecinos en las direcciones

					* x+
					* x-
					* y+
					* y-
				
				El router presenta un quinto canal para enlazarse a 
				una unidad funcional por medio de una interfaz de red.

				Para una lista completa de dependencias es necesario
				consultar el archivo router.v.
*/

// -- Declaracion temparana de Señales -------------------------- >>>>>>
		wire	credit_out_pe;
		wire  [`CHANNEL_WIDTH-1:0]	channel_pe_in;
		wire 	credit_in_pe;
		wire [`CHANNEL_WIDTH-1:0]	channel_pe_out;

// -- Instancia del modulo router ------------------------------- >>>>>>
router 	
	#(
		.X_LOCAL(X_LOCAL), 
		.Y_LOCAL(Y_LOCAL)
	)
des_router
	(
		.clk					(clk),
		.reset 					(reset),

	// -- puertos de entrada ------------------------------------- >>>>>
		.credit_out_xpos_dout	(credit_out_xpos_dout),
		.channel_xpos_din 		(channel_xpos_din),

		.credit_out_ypos_dout	(credit_out_ypos_dout),
		.channel_ypos_din 		(channel_ypos_din),

		.credit_out_xneg_dout	(credit_out_xneg_dout),
		.channel_xneg_din 		(channel_xneg_din),

		.credit_out_yneg_dout 	(credit_out_yneg_dout),
		.channel_yneg_din 		(channel_yneg_din),

		.credit_out_pe_dout		(credit_out_pe),
		.channel_pe_din 		(channel_pe_in),

	// -- puertos de salida -------------------------------------- >>>>>
		.credit_in_xpos_din		(credit_in_xpos_din),
		.channel_xpos_dout 		(channel_xpos_dout),
		
		.credit_in_ypos_din		(credit_in_ypos_din),
		.channel_ypos_dout		(channel_ypos_dout),

		.credit_in_xneg_din		(credit_in_xneg_din),
		.channel_xneg_dout		(channel_xneg_dout),

		.credit_in_yneg_din		(credit_in_yneg_din),
		.channel_yneg_dout		(channel_yneg_dout),

		.credit_in_pe_din		(credit_in_pe),
		.channel_pe_dout		(channel_pe_out)
    );




/*
-- Instancia :: Interfaz de red

-- Descripcion: Elemento de interconexion entre router y elemento de 
				procesamiento del nodo. La interfaz esta encargada de 
				recibir paquetes de la red y decodificarlos para la
				extracion y presentacion de datos de trabajo en un 
				formato compatible con los requerimientos del elemento
				de procesamiento.

				De igual forma, la interfaz de red toma paquetes del
				elemento de procesamiento y los empaqueta en flits 
				para su distribucion a traves de la red por medio del
				router del nodo.
*/


// -- Declaracion temprana de señales ------------------------ >>>>>
	wire 							start_strobe;
	wire [(2 * `CHANNEL_WIDTH)-1:0]	plaintext;
	wire [(2 * `CHANNEL_WIDTH)-1:0]	key;

	wire 							done_strobe_din;
	wire 							active_des_engine_din;
	wire [(2 * `CHANNEL_WIDTH)-1:0]	ciphertext;


des_network_interface interfaz_de_red
	(
		.clk					(clk),
		.reset					(reset),

	// -- input port --------------------------------------------- >>>>>
		.credit_out_dout		(credit_in_pe), 
		.input_channel_din		(channel_pe_out),

	// -- output port -------------------------------------------- >>>>>
		.credit_in_din			(credit_out_pe), 
		.output_channel_dout	(channel_pe_in),

	// -- interfaz :: processing node ---------------------------- >>>>>
		.start_strobe_dout		(start_strobe),
		.plaintext_dout			(plaintext),
		.key_dout				(key),

		.done_strobe_din		(done_strobe),
		.active_des_engine_din	(active_des_engine),
		.ciphertext_din			(ciphertext)
	);




/*
-- Instancia :: Encriptador DES

-- Descripcion: Elemento funcional del nodo de red. Este es particular
				para cada tarea que se desea acelerar, en este caso 
				particular la encriptacion de bloques de 64 bits.
*/

wire parity_check;

des_core	des_engine
	(
		.clk					(clk),
		.reset 					(reset),

	// -- input -------------------------------------------------- >>>>>
		.start_strobe_din		(start_strobe),

		.plaintext_din			(plaintext),
		.key_din 				(key),

	// -- output ------------------------------------------------- >>>>>
		.done_strobe_dout 		(done_strobe),
		.active_des_engine_dout	(active_des_engine),
		.parity_check_dout 		(parity_check),
		.ciphertext_dout 		(ciphertext)
	);



endmodule

/* -- Plantilla de instancia ------------------------------------- >>>>>

	des_node	
		#(
			.X_LOCAL 				(X_LOCAL), 
			.Y_LOCAL 				(Y_LOCAL)
		)
	des_node
	
			.clk					(clk),
			.reset 					(reset),

		// -- puertos de entrada --------------------------------- >>>>>
			.credit_out_xpos_dout	(credit_out_xpos_dout),
			.channel_xpos_din 		(channel_xpos_din),

			.credit_out_ypos_dout	(credit_out_ypos_dout),
			.channel_ypos_din 		(channel_ypos_din),

			.credit_out_xneg_dout	(credit_out_xneg_dout),
			.channel_xneg_din 		(channel_xneg_din),

			.credit_out_yneg_dout 	(credit_out_yneg_dout),
			.channel_yneg_din 		(channel_yneg_din),

		// -- puertos de salida ---------------------------------- >>>>>
			.credit_in_xpos_din		(credit_in_xpos_din),
			.channel_xpos_dout 		(channel_xpos_dout),
			
			.credit_in_ypos_din		(credit_in_ypos_din),
			.channel_ypos_dout		(channel_ypos_dout),

			.credit_in_xneg_din		(credit_in_xneg_din),
			.channel_xneg_dout		(channel_xneg_dout),

			.credit_in_yneg_din		(credit_in_yneg_din),
			.channel_yneg_dout		(channel_yneg_dout)
	    );

*/