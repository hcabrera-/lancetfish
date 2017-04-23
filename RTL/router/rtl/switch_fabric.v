`timescale 1ns / 1ps

/*
-- Module Name:	switch fabric -- crossbar --

-- Description:	Estructura de interconexion entre puertos de entrada y 
				salida. El modulo implementa un crossbar por medio de un
				conjunto de multiplexores.

				Las señales de control provienen del camino de control,
				en especifico de los modulos 'planificador de salida'.


-- Dependencies:	-- system.vh



-- Parameters:		-- CHANNEL_WIDTH:	Ancho de palabra de los canales
										de comunicacion entre routers.


-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:
	
-- History:	
	-- Creacion 07 de Junio 2015
*/
`include "system.vh"



module switch_fabric
	(
		input wire clk,
		input wire reset,

	// -- input -------------------------------------------------- >>>>>
		input wire [`CHANNEL_WIDTH-1:0]	inport_pe_din,
		input wire [`CHANNEL_WIDTH-1:0]	inport_xpos_din,
		input wire [`CHANNEL_WIDTH-1:0]	inport_ypos_din,
		input wire [`CHANNEL_WIDTH-1:0]	inport_xneg_din,
		input wire [`CHANNEL_WIDTH-1:0]	inport_yneg_din,

		input wire [3:0]				conf_pe_din,
		input wire [3:0]				conf_xpos_din,
		input wire [3:0]				conf_ypos_din,
		input wire [3:0]				conf_xneg_din,
		input wire [3:0]				conf_yneg_din,

	// -- output ------------------------------------------------- >>>>>
		output reg [`CHANNEL_WIDTH-1:0]	outport_pe_dout,
		output reg [`CHANNEL_WIDTH-1:0]	outport_xpos_dout,
		output reg [`CHANNEL_WIDTH-1:0]	outport_ypos_dout,
		output reg [`CHANNEL_WIDTH-1:0]	outport_xneg_dout,
		output reg [`CHANNEL_WIDTH-1:0]	outport_yneg_dout
    );


/*
-- Descripcion:	Nucleo de crossbar. Cada puerto de salida esta 
				resguardado por un multiplexor. Cada multiplexor recibe
				las salidas de las colas de almacenamiento de los 
				puertos de entrada de direcciones opuestas a el.

				Ej. El multiplexor resguardando el puerto de salida 'y-'
				esta conectado a las colas de almacenamiento {pe, x+,
				y+, x-}.

				Cada multiplexor tiene a su salida un registro. Este
				registro disminuye el retardo de propagacion de 
				informacion al router vecino. Sin embargo, el registro 
				agreaga 1 ciclo de latencia en la propagacion de datos.

				Para eliminar este registro solo se debe de sustituir:
				
					always @(posedge clk)
						outport_pe_dout = output_pe;

				con:

					assign outport_pe_dout = output_pe;

				y cambiar el tipo de señal del puerto de salida en la
				declaracion del modulo de 'reg' a 'wire'.
*/

// -- Parametros locales ----------------------------------------- >>>>>
	localparam 	RQS0 =	4'b0001;
	localparam	RQS1 =	4'b0010;
	localparam	RQS2 =	4'b0100;
	localparam	RQS3 =	4'b1000;


// -- MUX :: Salida PE ------------------------------------------- >>>>>
		reg [`CHANNEL_WIDTH-1:0] output_pe;

		always @(*)
			begin
				output_pe = {`CHANNEL_WIDTH{1'b0}};

				case (conf_pe_din)
					RQS0:	output_pe = inport_xpos_din;
					RQS1:	output_pe = inport_ypos_din;
					RQS2:	output_pe = inport_xneg_din;
					RQS3:	output_pe = inport_yneg_din;
				endcase // conf_pe_din
			end

	// -- Registro de Puerto de Salida PE ------------------------ >>>>>
		always @(posedge clk)
			if (reset)
				outport_pe_dout = {`CHANNEL_WIDTH{1'b0}};
			else
				outport_pe_dout = output_pe;




	// -- MUX :: Salida X+ --------------------------------------- >>>>>
		reg [`CHANNEL_WIDTH-1:0] output_xpos;

		always @(*)
			begin
				output_xpos = {`CHANNEL_WIDTH{1'b0}};

				case (conf_xpos_din)
					RQS0:	output_xpos = inport_pe_din;
					RQS1:	output_xpos = inport_ypos_din;
					RQS2:	output_xpos = inport_xneg_din;
					RQS3:	output_xpos = inport_yneg_din;
				endcase // conf_xpos_din
			end

	// -- Registro de Puerto de Salida X+ ------------------------ >>>>>
		always @(posedge clk)
			if (reset)
				outport_xpos_dout = {`CHANNEL_WIDTH{1'b0}};
			else
				outport_xpos_dout = output_xpos;



	// -- MUX :: Salida Y+ --------------------------------------- >>>>>
		reg [`CHANNEL_WIDTH-1:0] output_ypos;

		always @(*)
			begin
				output_ypos = {`CHANNEL_WIDTH{1'b0}};
				
				case (conf_ypos_din)
					RQS0:	output_ypos = inport_pe_din;
					RQS1:	output_ypos = inport_xpos_din;
					RQS2:	output_ypos = inport_xneg_din;
					RQS3:	output_ypos = inport_yneg_din;
				endcase // conf_ypos_din
			end

	// -- Registro de Puerto de Salida Y+ ------------------------ >>>>>
		always @(posedge clk)
			if (reset)
				outport_ypos_dout = {`CHANNEL_WIDTH{1'b0}};
			else
				outport_ypos_dout = output_ypos;




	// -- MUX :: Salida X- --------------------------------------- >>>>>
		reg [`CHANNEL_WIDTH-1:0] output_xneg;

		always @(*)
			begin
				output_xneg = {`CHANNEL_WIDTH{1'b0}};

				case (conf_xneg_din)
					RQS0:	output_xneg = inport_pe_din;
					RQS1:	output_xneg = inport_xpos_din;
					RQS2:	output_xneg = inport_ypos_din;
					RQS3:	output_xneg = inport_yneg_din;
				endcase // conf_xneg_din
			end

	// -- Registro de Puerto de Salida X- ------------------------ >>>>>
		always @(posedge clk)
		if (reset)
			outport_xneg_dout = {`CHANNEL_WIDTH{1'b0}};
		else
			outport_xneg_dout = output_xneg;




	// -- MUX :: Salida Y- --------------------------------------- >>>>>
		reg [`CHANNEL_WIDTH-1:0] output_yneg;

		always @(*)
			begin
				output_yneg = {`CHANNEL_WIDTH{1'b0}};

				case (conf_yneg_din)
					RQS0:	output_yneg = inport_pe_din;
					RQS1:	output_yneg = inport_xpos_din;
					RQS2:	output_yneg = inport_ypos_din;
					RQS3:	output_yneg = inport_xneg_din;
				endcase // conf_yneg_din
			end

	// -- Registro de Puerto de Salida Y- ------------------------ >>>>>
		always @(posedge clk)
			if (reset)
				outport_yneg_dout = {`CHANNEL_WIDTH{1'b0}};	
			else
				outport_yneg_dout = output_yneg;

endmodule


/*-- Plantilla de Instancia -------------------------------------- >>>>>

switch_fabric 	xbar
	(
		.clk	(clk),

	// -- input -------------------------------------------------- >>>>>
		.inport_pe_din		(inport_pe_din),
		.inport_xpos_din	(inport_xpos_din),
		.inport_ypos_din	(inport_ypos_din),
		.inport_xneg_din	(inport_xneg_din),
		.inport_yneg_din	(inport_yneg_din),

		.conf_pe_din		(conf_pe_din),
		.conf_xpos_din		(conf_xpos_din),
		.conf_ypos_din		(conf_ypos_din),
		.conf_xneg_din		(conf_xneg_din),
		.conf_yneg_din		(conf_yneg_din),

	// -- output ------------------------------------------------- >>>>>
		.outport_pe_dout	(outport_pe_dout),
		.outport_xpos_dout	(outport_xpos_dout),
		.outport_ypos_dout	(outport_ypos_dout),
		.outport_xneg_dout	(outport_xneg_dout),
		.outport_yneg_dout	(outport_yneg_dout)
    );
*/