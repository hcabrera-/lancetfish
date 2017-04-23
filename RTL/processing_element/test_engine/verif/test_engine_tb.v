`timescale 1ns / 1ps

module test_engine_tb();

reg clk;
reg reset;

reg 		start_strobe;
reg [63:0]	wordA;
reg [63:0]	wordB;

wire 		done_strobe;
wire 		active_test_engine;
wire [63:0] wordC;
wire [63:0] wordD;


test_engine 	
	#(
		.ROUNDS(5)
	)
test_engine
	(
		.clk	(clk),
		.reset 	(reset),

	// -- inputs ------------------------------------------------- >>>>>
		.start_strobe_din			(start_strobe),

		.wordA_din					(wordA),
		.wordB_din					(wordB),

	// -- outputs ------------------------------------------------ >>>>>
		.done_strobe_dout			(done_strobe),
		.active_test_engine_dout	(active_test_engine),
		.wordC_dout					(wordC),
		.wordD_dout					(wordD)
	);



// -- Parametros de lectura de archivo --------------------------- >>>>> 
	localparam SAMPLES = 100;
	reg [63:0] file_read [0:(SAMPLES * 2) - 1];
	integer	index;
	integer fp;


always
	begin
		clk = 1'b0;
		#(20);
		clk = 1'b1;
		#(20);
	end


initial
	$readmemh("/home/hector/Dropbox/red/processing_element/test_engine/tools/reference_model/origin.txt", file_read);

initial
	fp = $fopen("/home/hector/Dropbox/red/processing_element/test_engine/tools/reference_model/hardware.txt", "w");



/*

initial
	begin
		 $readmemh("/home/hector/Dropbox/red/processing_element/test_engine/tools/reference_model/origin.txt", file_read);
		 for(index = 0; index < 20; index = index + 1)
		 	begin
		 		$display("Valor en posicion %d: \t %h", index+1, file_read[index]);
		 	end
	end

*/

initial
	begin
		clk = 0;
		reset = 1;
		start_strobe = 0;
		wordA = 0;
		wordB = 0;

		repeat (5)
			@(negedge clk);

		reset = 0;

		repeat (5)
			@(negedge clk);


		for (index = 0; index < SAMPLES; index = index + 1) 
			begin
				wordA = file_read[(index*2)];
				wordB = file_read[(index*2) + 1];
				start_strobe = 1;
					@(negedge clk);
				start_strobe = 0;
					wait(done_strobe)
					@(negedge clk);
				$fwrite(fp, "0x%h\n", wordC);
				$fwrite(fp, "0x%h\n", wordD);
					@(negedge clk);
			end
		
		repeat (10)
			@(negedge clk);

		$fclose(fp);

		$finish;

	end

endmodule // test_engine_tb