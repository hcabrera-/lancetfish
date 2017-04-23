`timescale 1ns / 1ps

/*
-- Module Name:	FIFO control

-- Description:	Unidad de control para FIFO. Implementa los punteros de
				escritura/lectura para las operaciones PUSH y POP.

				Esta implementacion no ofrece una señal para indicar que
				el FIFO se encuentra vacio. existe la señal de buffer
				vacio, simplemente no se expone como linea para 
				interactuar con el diseño.


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



module fifo_control_unit
	(
		input 	wire 	clk,
		input 	wire 	reset,

	// -- inputs ------------------------------------------------- >>>>>
		input 	wire 					write_strobe_din,
		input 	wire 					read_strobe_din,

	// -- outputs ------------------------------------------------ >>>>>
		output 	wire 					full_dout,
		output 	wire 					empty_dout,
		
		output 	wire [ADDR_WIDTH-1:0]	write_addr_dout,
		output 	wire [ADDR_WIDTH-1:0]	read_addr_dout

    );


// --- Definiciones Locales -------------------------------------- >>>>>
	localparam  ADDR_WIDTH = clog2(`BUFFER_DEPTH);


// --- Señales --------------------------------------------------- >>>>>
	reg  [ADDR_WIDTH-1:0]	write_ptr_reg;
	reg  [ADDR_WIDTH-1:0]	write_ptr_next;
	reg  [ADDR_WIDTH-1:0]	read_ptr_reg;
	reg  [ADDR_WIDTH-1:0]	read_ptr_next;
	reg 					full_reg;
	reg 					full_next;
	reg 					empty_reg;
	reg 					empty_next;


	assign write_addr_dout 	= write_ptr_reg;
	assign read_addr_dout	= read_ptr_reg;
	assign full_dout		= full_reg;
	assign empty_dout		= empty_reg;





/*
-- Descripcion:	Maquina de estados finito para la administracion del 
				espacio de almacenamiento.

				Se especifican 3 tipos de operaciones:

					-- Escritura:	Si el buffer no se encuentra repleto
									se ordena la escritura del dato 
									presente en el puerto de entrada.
									Puntero de escritura mas uno.

					-- Lectura:	Si el buffer no se encuentra vacio, se
								muestra a la salida del FIFO el 
								siguiente dato almacenado.
								Puntero de lectura mas uno.

					-- Escritura/Lectura:
								Operacion concurrente de lectura y 
								escritura, los punteros no se avanzan.
*/

	// --- Elementos de Memoria ---------------------------------- >>>>>
		always @(posedge clk)
			if (reset)
				begin
					full_reg 		<= 1'b0;
					empty_reg 		<= 1'b1;
				end
			else
				begin
					full_reg 		<= full_next;
					empty_reg 		<= empty_next;
				end


	// --- Elementos de Memoria ---------------------------------- >>>>>
		always @(posedge clk)
			if (reset)
				write_ptr_reg 	<= {ADDR_WIDTH{1'b0}};
			else
				write_ptr_reg 	<= write_ptr_next;

		always @(posedge clk)
			if (reset)
				read_ptr_reg 	<= {ADDR_WIDTH{1'b0}};
			else
				read_ptr_reg 	<= read_ptr_next;



	// --- Logica de punteros de estado -------------------------- >>>>>
	wire [ADDR_WIDTH-1:0] write_ptr_succ;
	wire [ADDR_WIDTH-1:0] read_ptr_succ;

	assign write_ptr_succ  = (write_ptr_reg == `BUFFER_DEPTH-1) ? {ADDR_WIDTH{1'b0}} : write_ptr_reg + 1'b1;
	assign read_ptr_succ   = (read_ptr_reg  == `BUFFER_DEPTH-1) ? {ADDR_WIDTH{1'b0}} : read_ptr_reg  + 1'b1;

	always @(*)
		begin			
			write_ptr_next  = write_ptr_reg;
			read_ptr_next   = read_ptr_reg;
			full_next 		= full_reg;
			empty_next 		= empty_reg;


			case ({write_strobe_din, read_strobe_din})
					2'b01: // Read
						begin
							if(~empty_reg)
								begin
									read_ptr_next 		= read_ptr_succ;
									full_next 			= 1'b0;
									if (read_ptr_succ 	== write_ptr_reg)
										empty_next 		= 1'b1;
								end
						end

					2'b10:	// Write
						begin
							if(~full_reg)
								begin
									write_ptr_next 		= write_ptr_succ;
									empty_next 			= 1'b0;
									if (write_ptr_succ 	== read_ptr_reg)
										full_next 		= 1'b1;
								end
						end

					2'b11: // Concurrent Read - Write
						begin
							write_ptr_next = write_ptr_succ;
							read_ptr_next  = read_ptr_succ; 
						end
			endcase

		end








// -- Codigo no sintetizable ------------------------------------- >>>>>

	// -- Funciones ---------------------------------------------- >>>>>

			//  Funcion de calculo: log2(x) ---------------------- >>>>>
			function integer clog2;
				input integer depth;
					for (clog2=0; depth>0; clog2=clog2+1)
						depth = depth >> 1;
			endfunction

endmodule



/* -- Plantilla de Instancia ------------------------------------- >>>>>
	wire 			full;
	wire 			empty;
	
	wire [ADDR_WIDTH-1:0]	write_addr;
	wire [ADDR_WIDTH-1:0]	read_addr;

fifo_control_unit	fifo_control_unit
	(
		.clk 				(clk),
		.reset 				(reset),

	// -- inputs ------------------------------------------------- >>>>>
		.write_strobe_din 	(write_strobe_din),
		.read_strobe_din 	(read_strobe_din),

	// -- outputs ------------------------------------------------ >>>>>
		.full_dout 			(full),
		//.empty_dout 		(empty),
		
		.write_addr_dout	(write_addr),
		.read_addr_dout 	(read_addr)

    );
*/