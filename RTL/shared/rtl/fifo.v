`timescale 1ns / 1ps

/*
-- Module Name:	Input Queue

-- Description:	Estructura FIFO. El modulo permite el intercambio de 
				medio de almacenamiento. Por ejemplo, el uso del diseño
				registerFile_distRAM.v implementa un banco de registros
				que utiliza de manera exclusiva bloques de memoria 
				distribuida en FPGAs de Xilinx.

				Las banderas de full/empty estan deshabilitadas ya que 
				la informacion almacenada es auto regulada por el 
				mecanismo de creditos.


-- Dependencies:	-- system.vh
					-- fifo_control.v
					-- registerFile_distRAM.v 	(** intercambiable)


-- Parameters:		-- CHANNEL_WIDTH:	Ancho de palabra de los canales
										de comunicacion entre routers.

					-- BUFFER_DEPTH:	Numero de direcciones en la 
										estructura de memoria.

					-- ADDR_WIDTH: 		Numero de bits requerido para
										representar el espacio de 
										direcciones del elemento de
										memoria del FIFO.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:

-- History:	
	-- Creacion 07 de Junio 2015
*/
`include "system.vh"



module fifo
	(
		input 	wire 	clk,
		input 	wire 	reset,

	// -- inputs ------------------------------------------------- >>>>>
		input 	wire 						write_strobe_din,
		input 	wire 						read_strobe_din,

		input 	wire [`CHANNEL_WIDTH-1:0]	write_data_din,

	// -- outputs ------------------------------------------------ >>>>>
		output 	wire 	full_dout,
		output 	wire 	empty_dout,

		output 	wire [`CHANNEL_WIDTH-1:0]	read_data_dout
    );


// --- Definiciones Locales -------------------------------------- >>>>>
	localparam  ADDR_WIDTH = clog2(`BUFFER_DEPTH);




/*
-- Instancia :: Unidad de Control de FIFO

-- Descripcion:	Implementacion de estructura de control para FIFO. 
				Incluye punteros para el camculo de la direccion a 
				escribir y a leer.
*/

	// -- Unidad de Control -------------------------------------- >>>>>
	wire 	[ADDR_WIDTH-1:0]	write_addr;
	wire 	[ADDR_WIDTH-1:0]	read_addr;

	wire 						write_enable;

		fifo_control_unit fifo_control_unit
			(
				.clk	(clk),
				.reset 	(reset),

			// -- inputs ----------------------------------------- >>>>>
				.write_strobe_din	(write_strobe_din),
				.read_strobe_din	(read_strobe_din),

			// -- outputs ---------------------------------------- >>>>>
				.full_dout			(full_dout),
				.empty_dout			(empty_dout),
				.write_addr_dout	(write_addr),
				.read_addr_dout 	(read_addr)

			);

	assign write_enable = write_strobe_din & ~full_dout;







/*
-- Instancia :: Banco de registros

-- Descripcion:	Elemento de almacenamiento del FIFO. Puede intercambiar
				la implementacion del banco de memoria (Memoria 
				Distribuida / Bloque de Memoria). 
*/
	// -- Banco de Registros ------------------------------------- >>>>>

			register_file	register_file
				(
					.clk(clk),

				// -- inputs ------------------------------------- >>>>>
					.write_strobe_din 	(write_enable),
					.write_address_din 	(write_addr),
					.write_data_din 	(write_data_din),

					.read_address_din 	(read_addr),

				// -- outputs ------------------------------------ >>>>>
					.read_data_dout 	(read_data_dout)
					
			    );






 // -- Codigo no sintetizable ------------------------------------ >>>>>

	// -- Funciones ---------------------------------------------- >>>>>

			//  Funcion de calculo: log2(x) ---------------------- >>>>>
			function integer clog2;
				input integer depth;
					for (clog2=0; depth>0; clog2=clog2+1)
						depth = depth >> 1;
			endfunction


endmodule




/* -- Plantilla de instancia ------------------------------------- >>>>>
	wire [`CHANNEL_WIDTH-1:0]	read_data;
	
	wire 	full;
	wire 	empty;
	
	
	fifo	buffer_de_paquetes
		(
			.clk				(clk),
			.reset 				(reset),

		// -- inputs --------------------------------------------- >>>>>
			.write_strobe_din	(write_strobe),
			.read_strobe_din	(read_strobe),

			.write_data_din 	(write_data),

		// -- outputs -------------------------------------------- >>>>>
			.full_dout 			(full),
			.empty_dout			(empty),
			
			.read_data_dout 	(read_data)
	    );
*/
