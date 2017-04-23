`timescale 1ns / 1ps

/*
-- Module Name:	West First Minimal
-- Description:	Algoritmo parcialmente adaptativo para el calculo de
				de ruta en NoCs con topologia Mesh.
				
				El algoritmo esta basado en el "Turn Model". Se puede
				encontrar mas informacion en:

				The turn model for adaptive routing

				Christopher J. Glass	
				Lionel M. Ni
				
				ProceedingsISCA '92 Proceedings of the 19th annual 
				international symposium on Computer architecture
				Pages 278-287 

				Forma parte del modulo "Link Controller".

-- Dependencies:	-- system.vh

-- Parameters:		-- PORT_DIR: 	Direccion del puerto de entrada
									conectado a este modulo {x+, y+
									x-, y-}.
					-- X_LOCAL:		Direccion en dimension "x" del nodo 
									en la red.
					-- Y_LOCAL:		Direccion en dimension "y" del nodo 
									en la red.

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
	(05/06/2015): 	Esta es una implementacion modificada del algoritmo
					WF. Require modificarse para pasar la alteracion al
					modulo wrapper (route_planner.v)
							

-- History:	
	-- Creacion 05 de Junio 2015
*/
`include "system.vh"



module dor_yx	#(
					parameter 	PORT_DIR	= `X_POS,	
					parameter 	X_LOCAL 	= 2,
					parameter	Y_LOCAL 	= 2
				)
	(
	// -- inputs --------------------------------------------- >>>>>
		input wire 						done_field_din,

		input wire  [`ADDR_FIELD-1:0]	x_field_din,
		input wire  [`ADDR_FIELD-1:0]	y_field_din,

	// -- outputs -------------------------------------------- >>>>>
		output reg  [3:0]				valid_channels_dout
    );


/*
-- 	Calculo de diferencia entre la direccion del nodo actual con la
	direccion del nodo objetivo.

	Banderas zero_x y zero_y indican que la diferencia es "0" en sus 
	respectivas dimensiones.

	Banderas Xoffset y Yoffset el resultado de la diferencia entre la
	direccion actual y la objetivo. Puede ser positiva o negativa.
*/

	// -- Dimension X -------------------------------------------- >>>>>
		wire Xoffset;
		wire zero_x;
		
		assign Xoffset 	=  	(x_field_din >  X_LOCAL)	?	1'b1 : 1'b0;
		assign zero_x 	= 	(x_field_din == X_LOCAL)	?	1'b1 : 1'b0;
		
	// -- Dimension Y -------------------------------------------- >>>>>
		wire Yoffset;
		wire zero_y;
	
		assign Yoffset 	=  	(y_field_din >  Y_LOCAL)	?	1'b1 : 1'b0;
		assign zero_y 	= 	(y_field_din == Y_LOCAL)	?	1'b1 : 1'b0;
	



/*
-- 	En base a la diferencia de la direccion actual y objetivo, se 
	selecciona las direcciones de salida que acercan al paquete a su 
	destino.

	Existen 4 casos dependiendo del puerto de entrada ligado al 
	planificador de ruta. El caso activo se determina con el parametro
	PORT_DIR. Solo las asignaciones del caso  activo se toman 
	encuenta al momento de la sintesis.

	Para detalles sobre la toma de desiciones del algoritmo consultar el
	el paper citado en la cabecera de este archivo.
*/
// -- Seleccion de puertos de salida productivos ----------------- >>>>>


	always @(*)
	// -- Route Planner :: LC | PE ------------------------------- >>>>>
		if (PORT_DIR == `PE)
			begin
				valid_channels_dout [`PE_YPOS]		= (Yoffset) 			? 1'b1 : 1'b0;
				valid_channels_dout [`PE_YNEG]		= (~Yoffset)			? 1'b1 : 1'b0;

				valid_channels_dout [`PE_XPOS]		= (zero_y & Xoffset) 	? 1'b1 : 1'b0;
				valid_channels_dout [`PE_XNEG]		= (zero_y & ~Xoffset)	? 1'b1 : 1'b0;				
			end

	// -- Route Planner :: LC | X+ ------------------------------- >>>>>
		else if(PORT_DIR == `X_POS)
			begin
				valid_channels_dout [`XPOS_PE]		= ~done_field_din;

				valid_channels_dout [`XPOS_YPOS]	= (Yoffset) 			? 1'b1 : 1'b0;
				valid_channels_dout [`XPOS_YNEG]	= (~Yoffset)			? 1'b1 : 1'b0;

				valid_channels_dout [`XPOS_XNEG]	= (zero_y & ~Xoffset)	? 1'b1 : 1'b0;				
			end

	// -- Route Planner :: LC | Y+ ------------------------------- >>>>>
		else if(PORT_DIR == `Y_POS)
			begin
				valid_channels_dout [`YPOS_PE]		= ~done_field_din;

				valid_channels_dout [`YPOS_YNEG]	= (~Yoffset) 			? 1'b1 : 1'b0;

				valid_channels_dout [`YPOS_XPOS]	= (zero_y & Xoffset) 	? 1'b1 : 1'b0;
				valid_channels_dout [`YPOS_XNEG]	= (zero_y & ~Xoffset)	? 1'b1 : 1'b0;
				
			end

	// -- Route Planner :: LC | X- ------------------------------- >>>>>
		else if(PORT_DIR == `X_NEG)
			begin
				valid_channels_dout [`XNEG_PE]		= ~done_field_din;

				valid_channels_dout [`XNEG_YPOS]	= (Yoffset) 			? 1'b1 : 1'b0;
				valid_channels_dout [`XNEG_YNEG]	= (~Yoffset) 			? 1'b1 : 1'b0;

				valid_channels_dout [`XNEG_XPOS]	= (zero_y & ~Xoffset)	? 1'b1 : 1'b0;				
			end

	// -- Route Planner :: LC | Y- ------------------------------- >>>>>
		else if(PORT_DIR == `Y_NEG)
			begin
				valid_channels_dout [`YNEG_PE]		= ~done_field_din;

				valid_channels_dout [`YNEG_YPOS]	= (Yoffset) 			? 1'b1 : 1'b0;

				valid_channels_dout [`YNEG_XPOS]	= (Yoffset) 			? 1'b1 : 1'b0;				
				valid_channels_dout [`YNEG_XNEG]	= (~Yoffset) 			? 1'b1 : 1'b0;
			end


endmodule // west_first_minimal


/* -- Plantilla de Instancia ------------------------------------- >>>>>
	wire [3:0] valid_channels;

	mdor_yx
		#(	.PORT_DIR	(PORT_DIR), 
			.X_LOCAL	(X_LOCAL), 
			.Y_LOCAL	(Y_LOCAL)
		)
	dor_yx
	(
		// -- inputs --------------------------------------------- >>>>>
			.done_field_din	(done_field_din),
			.x_field_din	(x_field_din),
			.y_field_din	(y_field_din),

		// -- outputs -------------------------------------------- >>>>>
			.valid_channels_dout	(valid_channels)
    );
*/