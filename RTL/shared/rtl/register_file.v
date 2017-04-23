`timescale 1ns / 1ps

/*
-- Module Name:	FIFO control

-- Description:	Unidad de control para FIFO. Implementa los punteros de
				escritura/lectura para las operaciones PUSH y POP.


-- Dependencies:	-- system.vh


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


module register_file
	(
		input 	wire 	clk,

	// -- inputs ------------------------------------------------- >>>>>
		input 	wire 						write_strobe_din,
		input 	wire [ADDR_WIDTH-1:0]		write_address_din,
		input 	wire [`CHANNEL_WIDTH-1:0]	write_data_din,

		input 	wire [ADDR_WIDTH-1:0]		read_address_din,

	// -- outputs ------------------------------------------------ >>>>>
		output 	wire [`CHANNEL_WIDTH-1:0]	read_data_dout
    );


// --- Definiciones Locales -------------------------------------- >>>>>
	localparam  ADDR_WIDTH = clog2(`BUFFER_DEPTH);





// -- Modelado de matriz de almacenamiento ----------------------- >>>>>
	reg [`CHANNEL_WIDTH-1:0]	REG_FILE [0:`BUFFER_DEPTH-1];


// -- Puerto de escritura sincrono ------------------------------- >>>>>
	always @(posedge clk)
		if (write_strobe_din)
				REG_FILE[write_address_din] <= write_data_din;


// -- Puerto de lectura asincrono -------------------------------- >>>>>
	assign read_data_dout = REG_FILE[read_address_din];






// -- Codigo no sintetizable ------------------------------------- >>>>>

	// -- Funciones ---------------------------------------------- >>>>>
			
		// -- Rutina de Inicializacion de Registro --------------- >>>>>
			integer rf_index;
				initial
					for (rf_index = 0; rf_index < `BUFFER_DEPTH; rf_index = rf_index + 1)
						REG_FILE[rf_index] = {`CHANNEL_WIDTH{1'b0}};


		// -- Funcion de calculo: log2(x) ------------------------ >>>>>
			function integer clog2;
				input integer depth;
					for (clog2=0; depth>0; clog2=clog2+1)
						depth = depth >> 1;
			endfunction

endmodule				


/* -- Plantilla de Instancia ------------------------------------- >>>>>
	wire [`CHANNEL_WIDTH-1:0]	read_data;

	register_file	register_file
		(
			.clk	(clk),

		// -- inputs --------------------------------------------- >>>>>
			.write_strobe_din	(write_strobe_din),
			.write_address_din	(write_address_din),
			.write_data_din		(write_data_din),

			.read_address_din	(read_address_din),

		// -- outputs -------------------------------------------- >>>>>
			.read_data_dout		(read_data)
	    );
*/