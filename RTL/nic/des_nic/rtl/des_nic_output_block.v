`timescale 1ns / 1ps

/*
-- Module Name:	output_block

-- Description:	Bloque de salida de la interfaz de red. Se encarga de la
				interaccion entre el elemento de procesamiento y el 
				router. 

				Este modulo toma el resultado del elemento de 
				procesamiento y lo empaquete en flits para su transporte
				a travez de la red.


-- Dependencies:	-- system.vh
					-- output_control_unit.v

-- Parameters:		-- CHANNEL_WIDTH:	Numero de lineas de comunicacion
										entre la interfaz de red y el 
										router.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	

-- History:	
	-- 18 de Junio 2015: 	Creacion
*/
`include "system.vh"

module output_block 
	(
		input  wire clk,
		input  wire reset,
	
	// -- inputs from pn ----------------------------------------- >>>>>
		input  wire done_strobe_din,

		input  wire [(2* `CHANNEL_WIDTH)-1:0] 	ciphertext_din,
		input  wire [`CHANNEL_WIDTH-1:0] 		shifted_header_din,

	// -- to input block ----------------------------------------- >>>>>
		output wire zero_credits_dout,

	// -- output port -------------------------------------------- >>>>>
		input  wire credit_in_din,
		output reg [`CHANNEL_WIDTH-1:0]	output_channel_dout
	);


/*
-- Instancia:	output_control_unit

-- Descripcion: Unidad de control para el bloque de salida de la 
				interfaz de red. Este bloque se encarga de organizar la 
				salida de flits en direccion del router de la red.

				El control de creditos se encuentra implementado dentro 
				de este modulo.
*/
	wire [2:0]	output_selector;

	output_control_unit  output_control_unit 
		(
			.clk	(clk),
			.reset	(reset),
		
		// -- inputs --------------------------------------------- >>>>>
			.credit_in_din			(credit_in_din),
			.done_strobe_din		(done_strobe_din),

		// -- outputs -------------------------------------------- >>>>>	
			.zero_credits_dout		(zero_credits_dout),
			.output_selector_dout	(output_selector)
		);




/*
-- Registro

-- Descripcion: Registro de captura del resultado del elemento de 
				procesamiento. Este registro proporciona el dato
				procesado para ser liberado a la red.

				Solo se captura el texto cifrado, la llave de encriptado
				se desecha.
*/
	reg [(2* `CHANNEL_WIDTH)-1:0] ciphertext_reg;

	always @(posedge clk)
		if (done_strobe_din)
			ciphertext_reg <= ciphertext_din;


/*
-- Multiplexor

-- Descripcion: Multiplexor para la seleccion del flit que saldra 
				a la red durante el siguiente ciclo de reloj.

				Los datos de entrada para el multiplexor son los 
				registros de resultado del PE y la flit de cabecera
				modificado.

				Los dos ultimos dos flits del paquete son cargados
				con las constantes 'NUL1' y 'NUL2' por razones de
				trazabilidad de errores.

				Si no existe transito de flits el multiplexor mantiene
				el canal en un valor de 0.
*/

	always @(*)
		begin
			output_channel_dout = {`CHANNEL_WIDTH{1'b0}};
			case (output_selector)

				3'b101: output_channel_dout = shifted_header_din;

				3'b100:	output_channel_dout = ciphertext_reg[`CHANNEL_WIDTH-1:0];

				3'b011:	output_channel_dout = ciphertext_reg[(2 * `CHANNEL_WIDTH)-1:`CHANNEL_WIDTH];

				3'b010: output_channel_dout = "NUL1";

				3'b001: output_channel_dout = "NUL2";

				3'b000: output_channel_dout = {`CHANNEL_WIDTH{1'b0}};

			endcase
		end




endmodule

/* -- Plantilla de instancia ------------------------------------- >>>>> 

output_block bloque_de_salida
	(
		.clk 					(clk),
		.reset 					(reset),
	
	// -- inputs from PE ----------------------------------------- >>>>>
		.done_strobe_din 		(done_strobe_din),

		.ciphertext_din			(ciphertext_din),
		.shifted_header_din 	(shifted_header_din),

	// -- to input block ----------------------------------------- >>>>>
		.zero_credits_dout 		(zero_credits_dout),

	// -- output port -------------------------------------------- >>>>>
		.credit_in_din 			(credit_in_din),
		.output_channel_dout 	(output_channel_dout)
	);
*/