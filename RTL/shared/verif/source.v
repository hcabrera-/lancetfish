`timescale 1ns / 1ps

/*
-- Module Name:	Source
-- Description:	Emulador de origen de paquetes para la red en-chip. El
				modulo se encuentra descrito de manera comportamental. 
				Este modulo no es sintetizable, su uso se limita a fines
				de validacion y pruebas de rendimiento.

-- Dependencies:	-- system.vh
					-- packet_type.vh

-- Parameters:		-- Thold: 	Tiempo de retencion post - flanco 
								positivo de la señal de reloj. Tiempo
								necesario para que un valor quede 
								registrado en un elemento de memoria
								y sea valido a la salido del elemento.
					-- CREDITS:	Numero de creditos disponibles en el
								router conectado a este modulo.
					-- ID:		Numero de identificacion de modulo
								source. Es utilizado para a 
								identificacion de modulos individuales
								cuando el diseño cuenta con varias 
								instancias de source.v.

-- Original Author:	Héctor Cabrera
-- Current  Author:

-- Notas:	
	
-- History:	
	-- Creacion 05 de Junio 2015
*/
`include "system.vh"
`include "packet_type.vh"



module source	#(
					parameter Thold 	= 5,
					parameter PORT 		= `X_NEG,
					parameter CREDITS 	= 2,
					parameter ID 		= 0
				)
	(
		input  wire	clk,
	
	// -- inputs ------------------------------------------------- >>>>>
		input  wire credit_in,

	// -- outputs ------------------------------------------------ >>>>>
		output reg [`CHANNEL_WIDTH-1:0]	channel_out
    );



// -- Parametros locales ----------------------------------------- >>>>>
	/*
		-- Descripcion:	El modulo source puede crear log files para el 
						registro de paquetes inyectados a la red. el 
						parametro A_ASCII es utilizado como prefixo 
						para la creacion de varios archivos de manera
						secuencial.
	*/

	localparam A_ASCII = 65;

	

// -- Variables Globales ----------------------------------------- >>>>>
	/*
		-- Descripcion:	
						-- creditos: 	Variable de registro de numero 
										de credios disponibles en el
										router.
						-- packet tick:	Instante de tiempo de simulacion
										en el cual salio el ultimo 
										paquete enviado a la red.
						-- packet count:Numero de paquetes liberados por
										el modulo source.
						-- fp: 			Puntero a manejador de log file

	*/
	integer 	creditos;
	integer		packet_tick;
	integer 	packet_count;

	integer 	fp;

	reg [12*8:0]		file_name;
	reg [4*8:0]			port_name;
	reg [7:0] 			file_id;

	reg [17:0]			extended_serial_field;
	reg [11:0] 			field_serial;
	reg [31:0]			dato1_flit;
	reg [31:0]			dato2_flit;
	reg [31:0]			dato3_flit;
	reg [31:0]			dato4_flit;
	


// -- inicializacion de entorno ---------------------------------- >>>>>
	initial
		begin
			fp 			 = 0;
			file_name 	 = "";
			file_id 	 = A_ASCII + ID;

			if (PORT == `X_NEG)
				port_name = "XNEG";
			else if (PORT == `X_POS)
				port_name = "XPOS";
			else if (PORT == `Y_NEG)
				port_name = "YNEG";
			else if (PORT == `Y_POS)
				port_name = "YPOS";
			else
				port_name = "PE__";
			
			channel_out  = {`CHANNEL_WIDTH{1'b0}};
			creditos 	 = CREDITS;

			extended_serial_field = 0;
			field_serial = 0;
			dato1_flit 	 = 0;
			dato2_flit 	 = 0;
			dato3_flit 	 = 0;
			dato4_flit 	 = 0;

			packet_tick  = 0;
			packet_count = 0;
		end



// -- Manejador de creditos -------------------------------------- >>>>>
/*
	-- Descripcion:	Los creditos regresando al modulo "source" son 
					capturados de manera automatica por esta rutina. El
					registro de ingreso de creditos se lleva a cabo de 
					manera sincrona.

					La actualizacion de la variable "creditos" se lleva
					a cabo en el siguiente flanco positivo para emular
					el tiempo de procesamiento necesario para 
					actualizar esta variable en hardware.
*/
	always @(posedge clk)
		if (credit_in == 1)
			begin
				#(Thold);
				creditos = creditos + 1;
			end




// -- TASK: SEND_PACKET ------------------------------------------ >>>>>
/*
	-- Descripcion: Metodo para el envio de paquetes a la red. La rutina
					se encarga de recibir un dato tipo `PACKET_TYPE 
					(packet_type.vh) y transferirlo a la red.

					Las variables "packet_count" y "packet_tick" se 
					actualizan durante la ejecucion de esta rutina.
*/
	task send_packet;
		input	`PACKET_TYPE 		pkt;
		integer i;
			begin

					packet_tick	 = $time();

					// DBG: $display("Data 0: %h", pkt `DATA_0);
					// DBG: $display("tiempo %t",$time());

					extended_serial_field 	= pkt `EXTENDED_SERIAL;
					dato1_flit 	 			= pkt `DATA_0;
					dato2_flit 	 			= pkt `DATA_1;
					dato3_flit 				= pkt `DATA_2;
					dato4_flit 	 			= pkt `DATA_3;

					$fdisplay(fp, "%d, %d", extended_serial_field, packet_tick);
					// DBG: $fdisplay(fp, "%d, %d, %d, %d", extended_serial_field, packet_tick, pkt `DESTINO, pkt `PUERTA);
					// DBG: "Solo campos de rendimiento" $fdisplay(fp, "%d, %d", extended_serial_field, packet_tick);
					// DBG: "paquete completo" $fdisplay(fp, "%d, %d, %h, %h, %h, %h", extended_serial_field, packet_tick, dato1_flit, dato2_flit, dato3_flit, dato4_flit);

					if (creditos < 1)
						@(creditos > 0);
									
					
					for (i = 0; i < 5; i = i+1) 
						begin
							channel_out <= pkt[`CHANNEL_WIDTH-1:0];
								@(posedge clk);
									#(Thold);
							if (i == 0)
								creditos = creditos - 1;
							pkt = pkt >> `CHANNEL_WIDTH;
						end
					packet_count = packet_count + 1;
					channel_out  = {`CHANNEL_WIDTH{1'bx}};
			end
	endtask : send_packet





// -- TASK:: OPEN OBSERVER --------------------------------------- >>>>>
/* 
	-- Descripcion:	Tarea de apertura de log file para operaciones 
					llevadas a cabo por este modulo.
*/
	task open_observer;
		begin
			file_name = {port_name, "_TX", file_id, ".dat"};
			$display("%s", file_name);
			fp = $fopen(file_name, "w");
				if(!fp)
					$display("Could not open %s", file_name);
				else
					$display("Success opening %s", file_name);
		end
	endtask : open_observer 



// -- TASK:: CLOSE_OBSERVER -------------------------------------- >>>>>
/* 
	-- Descripcion:	Cierre de log file.
*/
	task close_observer;
		begin
			$fclose(fp);
			$display("%s se cerro de manera exitosa", file_name);
		end
	endtask : close_observer 


endmodule
