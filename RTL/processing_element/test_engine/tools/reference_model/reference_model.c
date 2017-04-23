#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

/*
-- Module Name:	Reference Model

-- Description:	Modelo de referencia de operacion ha alto nivel del
				modulo test_engine.v (Verilog).

				El programa genera 2 archivos:
				
					* origin.txt:	Datos pre - procesamiento.
					* result.txt: 	Datos procesador

				Los archivos presentan los datos en columna en formato
				hexadecimal(64 bits): 0xYYYYYYYYYYYYYYYY

				El archivo toma dos datos de 64 bits de entrada: wordA y
				wordB. La ronda de procesamiento consisten en:

					* wordA: wordA ^ swap(wordB)
					* wordB: wordA

				El numero de rondas de procesamiento se puede configurar
				al igual que en el archivo HDL.

				El tipo de dato utilizado es uint64_t, puede ser 
				remplazado por long long uint. Para la impresion de
				datos se requiere el uso de las MACROS definidas en 
				inttypes.h.

				En este caso concreto se utiliza -- PRIx64 -- para 
				imprimir un entero  sin signo de 64 bits en formato
				hexadecimal.



-- Dependencies:	-- inttypes.h


-- Parameters:		ROUNDS:		Numero de rondas de procesamiento que se
								ejecutan antes de obtener el resultado 
								final del computo
					SAMPLES:	Numero de puntos de prueba que se
								generan para la prueba en ejecucion.


-- Original Author:	Héctor Cabrera

-- Current  Author:

-- History:	
	-- Creacion 29 de Noviembre 2015
*/


// -- declaracion de funciones ----------------------------------- >>>>>
	uint64_t swapHalfWord(uint64_t word64);
	uint64_t randWord64();
	uint64_t xorWord (uint64_t word64, uint64_t wordB);
	void 	 processingRound(uint64_t* wordA, uint64_t* wordB);




int main (int argc, char *argv[])
	{

		// -- Inicializacion  ------------------------------------ >>>>>
			const int ROUNDS  = 5;
			const int SAMPLES = 100;

			srand(time(NULL));

			uint64_t wordA = 0;
			uint64_t wordB = 0;

			uint64_t *wordA_ptr = &wordA;
			uint64_t *wordB_ptr = &wordB;

			FILE *origin_fp;
			FILE *result_fp;

				// -- inicializacion de manejadores de archivos -- >>>>>
					origin_fp = fopen("origin.txt", "w");
					result_fp = fopen("result.txt", "w");

		// ------------------------------------------------------- >>>>>



		// -- Cuerpo de  programa -------------------------------- >>>>>

			for(int index = 0; index < SAMPLES; index++){
				wordA = randWord64();
				wordB = randWord64();

				fprintf(origin_fp, "0x%016"PRIx64"\n", wordA);
				fprintf(origin_fp, "0x%016"PRIx64"\n", wordB);

				for (int index = 0; index < ROUNDS; index ++){
					processingRound(wordA_ptr, wordB_ptr);
				}

				fprintf(result_fp, "0x%016"PRIx64"\n", wordA);
				fprintf(result_fp, "0x%016"PRIx64"\n", wordB);
			}

		// ------------------------------------------------------- >>>>>


		// -- Cierre de programa --------------------------------- >>>>>
			// -- Cierre de archivos ----------------------------- >>>>>
				fclose(origin_fp);
				fclose(result_fp);
		// ------------------------------------------------------- >>>>>


		return 0;
	}



/* -- swapHalfWord ----------------------------------------------- >>>>>
	
	-- Descripcion:	Rutina para el intercambio de parte baja [31:0] y 
					parta alta [63:32] de una palabra de 64 bits.

*/

	uint64_t swapHalfWord (uint64_t word64){
		
		uint64_t temp64 = 0;
		
			temp64 = word64 & 0x00000000ffffffff;
			temp64 = temp64 << 32;
			
			word64 = word64 >> 32;
			word64 = word64 | temp64;
		
		return word64;
	}


/* -- xorWord ---------------------------------------------------- >>>>>

	-- Descripcion:	Rutina que ejecuta la operacion XOR sobre dos 
					datos de 64 bits.

*/

	uint64_t xorWord(uint64_t wordA, uint64_t wordB){
		return wordA ^ wordB;
	}


/* -- randWord64 ------------------------------------------------- >>>>>

	-- Descripcion: Rutina para la obtencion de un dato aleatorio de 64
					bits. Requiere inicializar con una nueva semilla 
					antes de ser invocada.

						srand(time(NULL));

*/

	uint64_t randWord64(){
		
		uint64_t word64;

			word64 = rand();

		return word64 << 32 | rand();
	}



/* -- processingRound -------------------------------------------- >>>>>

	-- Descripcion: Ejecucion de una ronda de procesamiento. Se ejecuta
					un swap de wordB y el resultado se utiliza en una
					operacion XOR con wordA. El resultado de la ultima
					operacion se almacena en wordA.

					wordB almacena el valor wordA antes de la ejecucion 
					de la operacion descrita en el parrafo anterior.

*/

void processingRound(uint64_t* wordA, uint64_t* wordB){
	
	uint64_t word64;

		word64 = swapHalfWord(*wordB);
		*wordB = *wordA;
		*wordA = xorWord(*wordA, word64);
} 
