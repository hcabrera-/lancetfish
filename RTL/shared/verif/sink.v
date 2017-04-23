`timescale 1ns / 1ps

/*
-- Module Name:	Sink
-- Description:	Emulador de receptor de paquetes para la red en-chip. El
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


module sink		#(
					parameter 	Thold 	= 5,
					parameter 	PORT 	= `X_NEG,
					parameter	ID 		= 0
				)
	(
		input wire	clk,

	// -- inputs ------------------------------------------------- >>>>>
		input wire [`CHANNEL_WIDTH-1:0]	channel_in,

	// -- outputs ------------------------------------------------ >>>>>
		output reg credit_out
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
						-- paquete: 	Variable para almacenar el 
										ultimo paquete recibido de la 
										red.
						-- packet tick:	Instante de tiempo de simulacion
										en el cual se recibio el ultimo 
										paquete desde la red.
						-- packet count:Numero de paquetes recibidos por
										el modulo sink.
						-- fp: 			Puntero a manejador de log file

	*/
	reg [12*8:0]		file_name;
	reg [4*8:0]			port_name;
	reg `PACKET_TYPE 	paquete;

	reg [17:0]			extended_serial_field;
	reg [11:0] 			field_serial;
	reg [31:0]			dato1_flit;
	reg [31:0]			dato2_flit;
	reg [31:0]			dato3_flit;
	reg [31:0]			dato4_flit;

	integer 	fp;
	integer 	packet_count;
	integer		packet_tick;
	integer 	i;

	reg [7:0] 	file_id;



// -- inicializacion de entorno ---------------------------------- >>>>>
	initial
		begin
			file_name 	= "";
			file_id 	= A_ASCII + ID;
			paquete 	= 0;

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

			extended_serial_field = 0;
			field_serial = 0;
			dato1_flit 	 = 0;
			dato2_flit 	 = 0;
			dato3_flit 	 = 0;
			dato4_flit 	 = 0;

			fp 			 = 0;
			packet_count = 0;
			packet_tick  = 0;
			i 			 = 0;

			credit_out = 0;
		end

	



// -- Manejador de paquetes -------------------------------------- >>>>>
/*
	-- Descripcion:	El modulo "sink.v" escucha de manera constante su
					canal de comunicacion asignado. Cualquier 
					perturbacion en el canal indica la llegada de un 
					nuevo paquete.

					La recepcion consisten el la lectura del valor 
					actual en el canal de entreda y su posterior 
					transferencia a la variable "paquete". Despues de 
					cada lectura del canal de entrada la variable 
					paquete es desplazada a la izquiereda para continuar
					con la captura de los flits consecuentes del 
					paquete.
*/
	always @(channel_in)
		begin
			//	DBG: $display("test 1: %h", channel_in);
			if (channel_in !== {32{1'b0}} && channel_in !== {32{1'bx}})
				begin
					//	DBG: $display("%h", channel_in);
					for (i = 0; i < 5; i = i+1) 
						begin
							if(i == 4)
								begin
									packet_count 	= packet_count + 1;
									credit_out 		<= 1;
								end

							paquete = {paquete[159:32], channel_in};

							@(posedge clk)
								#(Thold);

							if (i < 4)
								paquete = paquete << `CHANNEL_WIDTH;

						end
						
					// DBG:$display("receive packet - serial :: %d", paquete[139:128]);
					i = 0;

					/*
						-- Descripcion: Desensamble del paquete en 
										campos para su registro en el 
										log file de la simulacion.
					*/
					extended_serial_field 	= paquete[145:128];
					dato1_flit				= paquete[127:96];	
					dato2_flit				= paquete[95:64];
					dato3_flit				= paquete[63:32];
					dato4_flit				= paquete[31:0];
					packet_tick 			= $time();
					
					$fdisplay(fp, "%d, %d", extended_serial_field, packet_tick);
					// DBG "Mostrar en pantalla paquete recibido" 		$display("%d, %d, %c, %c, %c, %c", packet_count, packet_tick, dato1_flit, dato2_flit, dato3_flit, dato4_flit);
					// DBG "Escritura de resultados de procesamiento" 	$fdisplay(fp, "%h\n%h\n", {dato1_flit, dato2_flit},{dato3_flit, dato4_flit});
					// DBG "Escritura de resultados de desempeño"	  	$fdisplay(fp, "%d, %d, %d, %d, %d, %d", field_serial, packet_tick, dato1_flit, dato2_flit, dato3_flit, dato4_flit);
					
					credit_out 	<= 0;					
				end
			end
		//end
	//endtask : receive_packet







// -- File Handler Open ------------------------------------------ >>>>>
/* 
	-- Descripcion:	Tarea de apertura de log file para operaciones 
					llevadas a cabo por este modulo.
*/
	task open_observer;
		begin
			file_name = {port_name, "_RX", file_id, ".dat"};
			$display("%s", file_name);
			fp = $fopen(file_name, "w");
				if(!fp)
					$display("Could not open %s", file_name);
				else
					$display("Success opening %s", file_name);
		end
	endtask : open_observer 



// -- File Handler Close ----------------------------------------- >>>>>
/* 
	-- Descripcion:	Cierre de log file.
*/
	task close_observer;
		begin
			file_name = {port_name, "_RX", file_id, ".dat"};
			$fclose(fp);
			$display("%s se cerro de manera exitosa", file_name);
		end
	endtask : close_observer 

endmodule
