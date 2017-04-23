DATE=`date +%F_%H:%M`
HISTO_GRAPH='histogram_graphics'
HISTO_FILE='histogram_files'

mkdir 	"$DATE"
cd 		"$DATE"

mkdir	"$HISTO_GRAPH"
mkdir	"$HISTO_FILE"


ls /home/hector/Documents/vivado_projects/tesis/tesis.sim/sim_1/behav/*TX* > filelist_TX.txt
cat filelist_TX.txt | xargs cat | sort -n > sorted_TX_results.txt
wc -l < filelist_TX.txt > filecount_TX.txt
wc -l < sorted_TX_results.txt > packetcount_TX.txt


ls /home/hector/Documents/vivado_projects/tesis/tesis.sim/sim_1/behav/*RX* > filelist_RX.txt
cat filelist_RX.txt | xargs cat | sort -n > sorted_RX_results.txt
wc -l < filelist_RX.txt > filecount_RX.txt
wc -l < sorted_RX_results.txt > packetcount_RX.txt


cp /home/hector/Documents/vivado_projects/tesis/tesis.sim/sim_1/behav/reception_resume.dat reception_resume.dat

cd ..

python2.7 generate_results.py "$DATE"
