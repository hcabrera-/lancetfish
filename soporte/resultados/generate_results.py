#!/usr/bin/env python2
# 

import sys
import numpy as np
import matplotlib.pyplot as plt

PATH = str(sys.argv[1])
PATH_HISTO_GRAPH = str(sys.argv[1]) + '/histogram_graphics'
PATH_HISTO_FILE  = str(sys.argv[1]) + '/histogram_files'
PERIODO = 3






'''
	-- 	Descripcion

		Lectura de archivos:

			-	filecount_TX: Numero de modulos source instanciados en 
				la red de la simualcion en analisis.

			-	filecount_RX: Numero de modulos sink instanciados en la
				red de la simulacion.

			-	packetcount_TX: Numero total de paquetes inyectados 
				a la red durante la simulacion.

			-	packetcount_RX: Numero total de paquetes recibidos 
				a la red durante la simulacion.

		En esta etapa se verifica la coherencia de datos de simulacion,
		se verifica que la arquitectura de red sea simetrica (cuadrada)
		y que el numero de paquetes trasnmitidos a la red sea el mismo 
		numero de paquetes recibidos. 		
'''

# -- Variables ----------------- >>>>>
fp_TX  = 0
fp_RX  = 0
fp_LAT = 0
fp_TMP = 0

nodecount_TX 	= 0
nodecount_RX 	= 0

packetcount_TX 	= 0
packetcount_RX 	= 0

# -- Sentencias de trabajo ------ >>>>>
fp_TMP   = open (PATH + '/' +'filecount_TX.txt', 'r');
nodecount_TX = int(fp_TMP.readline())
fp_TMP.close()
#DBG	print nodecount_TX

fp_TMP   = open (PATH + '/' +'packetcount_TX.txt', 'r');
packetcount_TX = int(fp_TMP.readline())
fp_TMP.close()
#DBG	print packetcount_TX

fp_TMP   = open (PATH + '/' + 'filecount_RX.txt', 'r');
nodecount_RX = int(fp_TMP.readline())
fp_TMP.close()
#DBG	print nodecount_RX

fp_TMP   = open (PATH + '/' +'packetcount_RX.txt', 'r');
packetcount_RX = int(fp_TMP.readline())
fp_TMP.close()
#DBG	print packetcount_RX

if nodecount_TX != nodecount_RX:
	sys.exit("Numero de nodos no simetrico")
elif packetcount_TX != packetcount_RX:
	print "Paquetes enviados: " + str(packetcount_TX) + ", paquetes recibidos: " + str(packetcount_RX)
	sys.exit("Paquetes perdidos de simulacion")






'''
	-- 	Descripcion:

		Calculo de latencias (General y por inyector)

		Extraccion de datos posteriores a 'warm up' de la red, y 
		anteriores a los ciclos de 'cool down' de la red.
		
		El porcentaje de paquetes respecto al total de la simulaccion se
		determina mediante el porcentaje asignado a la variable 
		'PERCENTAGE_OUT'

		Con los datos de interes se crea la lista histogram_raw con la 
		diferencia entre el tiempo de recepcion t el tiempo de inyeccion
		de cada paquete de la red.
'''
PERCENTAGE_OUT 	= 10

offset_paquetes = packetcount_TX  / nodecount_TX
warmup_packets  = offset_paquetes / PERCENTAGE_OUT


# -- Variables de trabajo ------ >>>>>
histogram_raw 		= []
histogram_proc		= []
latency_prom_proc	= 0
latency_prom_raw	= 0
line_RX      	  	= 0
data 				= 0
line_count			= 1


fp_TX = open(PATH + '/' + 'sorted_TX_results.txt', 'r')
fp_RX = open(PATH + '/' + 'sorted_RX_results.txt', 'r')


# -- Calculo de la diferencia de tiempos de envio y entrega de paquetes
for line_TX in fp_TX:
	
	line_RX = fp_RX.readline()
	line_TX = line_TX.split()
	line_RX = line_RX.split()

	data = int(line_RX[1]) - int(line_TX[1])
	#DBG	if data < 0:
		#DBG	print  line_RX[0] + '        ' +line_RX[1] + ' - ' + line_TX[1] + ' = ' + str(data)
	histogram_raw.append(data)
	line_count += 1

fp_RX.close()
fp_TX.close()


# -- 	Retiro de paquetes pertenecientes al 'warm up' y al 'cool down' 
#		de la red. Lista de paquetes: histogram_proc
		
for iterator in range(nodecount_TX):
	initial_range 	= (iterator * offset_paquetes) + warmup_packets
	final_range		= (iterator * offset_paquetes) + (offset_paquetes-1) - warmup_packets

	histogram_proc 	= histogram_proc + histogram_raw[initial_range:final_range]



# -- Calculo de latencia de la red en saturacion
for latencia in histogram_proc:
	latency_prom_proc = latency_prom_proc + latencia

latency_prom_proc = latency_prom_proc / len(histogram_proc)
latency_min_proc  = min(histogram_proc)
latency_max_proc  = max(histogram_proc)

# -- Calculo de la latencia de red en su operacion de inicio a fin
for latencia in histogram_raw:
	latency_prom_raw = latency_prom_raw + latencia

latency_prom_raw = latency_prom_raw / len(histogram_raw)
latency_min_raw	 = min(histogram_raw)
latency_max_raw	 = max(histogram_raw)


fp_TMP = open(PATH + '/' + 'resultado_latencias.txt', 'w')
fp_TMP.write('Resultado de latencias\n\n')
fp_TMP.write('latencia promedio proc:\t' + str(latency_prom_proc))
fp_TMP.write('\nlatencia maxima proc:\t' + str(latency_max_proc))
fp_TMP.write('\nlatencia minima proc:\t' + str(latency_min_proc))
fp_TMP.write('\n\n')
fp_TMP.write('latencia promedio raw:\t' + str(latency_prom_raw))
fp_TMP.write('\nlatencia maxima raw:\t' + str(latency_max_raw))
fp_TMP.write('\nlatencia minima raw:\t' + str(latency_min_raw) + '\n')

fp_TMP.close()






'''
	-- 	Descripcion:

		Generacion de Histogramas

		Generacion de graficas de histograma general y por canal. Solo
		se toman en considerancion los datos una vez que la red a 
		alcanzado su estado de saturacion.
'''
# -- General
array = plt.hist(histogram_proc, bins=200, histtype='step')
plt.title("Histograma de latencia")
plt.xlabel("latencia (ns)")
plt.ylabel("incidencia")
plt.savefig(PATH_HISTO_GRAPH + "/" + "histograma_general.png", bbox_inches='tight', dpi=600)
plt.close()

hist, bin_edges = np.histogram(histogram_proc, bins = 200)

# -- Archivo de referencia del histograma creado
fp_TMP = open(PATH_HISTO_FILE + '/' + 'histo_gen_data.txt', 'w')
np.savetxt(fp_TMP, hist, delimiter=',', fmt='%d')
fp_TMP.close()
fp_TMP = open(PATH_HISTO_FILE + '/' + 'histo_gen_bins.txt', 'w')
np.savetxt(fp_TMP, bin_edges, delimiter=',', fmt='%d')
fp_TMP.close()




# -- Por puertos
warmup_packets   = offset_paquetes / 10

for iterator in range(nodecount_TX):
	initial_range 	= (iterator * offset_paquetes) + warmup_packets
	final_range		= (iterator * offset_paquetes) + (offset_paquetes-1) - warmup_packets

	plt.hist(histogram_raw[initial_range:final_range], bins=200, histtype='step')

# -- 	Falta agregar codigo para que detecte el nombre correcto de cada 
#		puerto de inyeccion.		

	if iterator < 5:
		plt.title("Histograma de latencia XNEG[" + str(iterator + 1) + "]")
		hist_name = "histo_XNEG[" + str(iterator + 1) + "].txt"
		bins_name = "bins_XNEG["  + str(iterator + 1) + "].txt"
	else:
		plt.title("Histograma de latencia XPOS[" + str(iterator - 4) + "]")
		hist_name = "histo_XPOS[" + str(iterator + 1) + "].txt"
		bins_name = "bins_XPOS["  + str(iterator + 1) + "].txt"

	plt.xlabel("latencia (ns)")
	plt.ylabel("incidencia")
	file_name = 'histograma_source_' +  str(iterator + 1) + '.png'
	plt.savefig(PATH_HISTO_GRAPH + "/" + file_name, bbox_inches='tight', dpi=600)


	# -- Archivo de referencia del histograma creado
	# -- Dos archivos por histograma: data y bins
	hist, bin_edges = np.histogram(histogram_raw[initial_range:final_range], bins = 200)

	fp_TMP = open(PATH_HISTO_FILE + '/' + hist_name, 'w')
	np.savetxt(fp_TMP, hist, delimiter=',', fmt='%d')
	fp_TMP.close()
	fp_TMP = open(PATH_HISTO_FILE + '/' + bins_name, 'w')
	np.savetxt(fp_TMP, bin_edges, delimiter=',', fmt='%d')
	fp_TMP.close()

	plt.close()
	#DBG	plt.show()






'''
	-- 	Descripcion:

		Throughtput
		
'''

warmup_packets   = int(offset_paquetes * .3)

# -- Ocupacion de puertos
max_time 		= 0
throughput_raw  = []

fp_RX = open(PATH + '/' + 'sorted_RX_results.txt', 'r')

for line_RX in fp_RX:
	line_RX = line_RX.split()
	throughput_raw.append(int(line_RX[1]))

fp_RX.close()

# -- Ultimo dato recibido por la red
max_time 	= max(throughput_raw)


time_sink   = []
index		= 0

fp_TMP = open(PATH + '/reception_resume.dat', 'r')

for line_TMP in fp_TMP:
	time_sink.append(int(line_TMP) * (5 * PERIODO))
	print '\nCycles sink[' + str(index) + ']: ' + str(time_sink[index]) + ', procentaje: ' + str((time_sink[index]*100)/max_time) + '%'
	index += 1

fp_TMP.close()


'''
	-- Area de codigo temporal:

	Codigo en pruebas o de referencia
'''

'''
	-- Calculo de throughput
'''



# -- Obtencion de valores 'warm up' / 'cold down' de transmision
throughput_raw  = []
throughput_data = []

min_time = 0
max_time = 0


fp_TX = open(PATH + '/' + 'sorted_TX_results.txt', 'r')

for line_TX in fp_TX:
	line_TX = line_TX.split()
	throughput_raw.append(int(line_TX[1]))

fp_TX.close()


# -- Eliminar datos fuera del rango de interes ------------------- >>>>>
for iterator in range(nodecount_TX):
	initial_range 	= (iterator * offset_paquetes) + warmup_packets
	final_range		= (iterator * offset_paquetes) + (offset_paquetes-1) - warmup_packets

	throughput_data = throughput_data + throughput_raw[initial_range:final_range]

min_time = min(throughput_raw)
max_time = max(throughput_raw)

throughput_RX  = 0
throughput_TX = 0

fp_RX = open(PATH + '/' + 'sorted_RX_results.txt', 'r')

for line_RX in fp_RX:
	line_RX = line_RX.split()
	#if (int(line_RX[1]) >= min_time) & (int(line_RX[1]) <= max_time):
	if (int(line_RX[1]) >= min_time) & (int(line_RX[1]) <= min_time+10000):
		throughput_RX += 1

fp_RX.close()


fp_TX = open(PATH + '/' + 'sorted_TX_results.txt', 'r')

for line_TX in fp_TX:
	line_TX = line_TX.split()
	#if (int(line_TX[1]) >= min_time) & (int(line_TX[1]) <= max_time):
	if (int(line_TX[1]) >= min_time) & (int(line_TX[1]) <= min_time+10000):
		throughput_TX += 1

fp_TX.close()

# -- Throught Put
#total_time = max_time - min_time
total_time = min_time+10000 - min_time
print 'total time: ' + str(total_time)

tBITS = throughput_RX * 5 * 32
print 'Total bits: ' + str(tBITS)
tSEG  = float(total_time) / 10**9
print 'Time seconds: ' + str(tSEG)
nWORK = 1/tSEG
print 'Number of work: ' + str(nWORK)
throughBPS = nWORK * tBITS
print 'Throughput: ' + str(throughBPS/float(10**9))


fp_TMP = open(PATH + '/' + 'throughput.txt', 'w')
fp_TMP.write("Paquetes inyectados: " + str(throughput_TX) + "\n")
fp_TMP.write("Paquetes recibidos : " + str(throughput_RX) + "\n")
fp_TMP.write("Throughtput : " 		 + str(throughBPS/float(10**9))    + " Gbps\n")

fp_TMP.close()
