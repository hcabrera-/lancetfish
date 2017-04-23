`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2015 05:56:12 PM
// Design Name: 
// Module Name: des_cipher_text
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module des_datapath
	(
		input wire clk,
		input wire reset,

	// -- inputs --------------------------------------------------------- >>>>>
		input wire 			enable,
		input wire 			source_sel,

		input wire [0:63]	plaintext_din,
		input wire [0:47]	round_key_din,

	// -- outputs -------------------------------------------------------- >>>>>
		output wire [0:63]	ciphertext_dout
    );


// -- Declaracion temprana de señales ------------------------------------ >>>>>
	wire [0:31] left_round_out;
	wire [0:31]	right_round_out;


// -- Initial Permutation ------------------------------------------------ >>>>>
	wire [0:63]	initial_permutation;

	assign initial_permutation[0 +: 8] = 	{
												plaintext_din[57],
												plaintext_din[49],
												plaintext_din[41],
												plaintext_din[33],
												plaintext_din[25],
												plaintext_din[17],
												plaintext_din[9],
												plaintext_din[1]
											};

	assign initial_permutation[8 +: 8] = 	{
												plaintext_din[59],
												plaintext_din[51],
												plaintext_din[43],
												plaintext_din[35],
												plaintext_din[27],
												plaintext_din[19],
												plaintext_din[11],
												plaintext_din[3]
											};

	assign initial_permutation[16 +: 8] = 	{
												plaintext_din[61],
												plaintext_din[53],
												plaintext_din[45],
												plaintext_din[37],
												plaintext_din[29],
												plaintext_din[21],
												plaintext_din[13],
												plaintext_din[5]
											};

	assign initial_permutation[24 +: 8] = 	{
												plaintext_din[63],
												plaintext_din[55],
												plaintext_din[47],
												plaintext_din[39],
												plaintext_din[31],
												plaintext_din[23],
												plaintext_din[15],
												plaintext_din[7]
											};

	assign initial_permutation[32 +: 8] = 	{
												plaintext_din[56],
												plaintext_din[48],
												plaintext_din[40],
												plaintext_din[32],
												plaintext_din[24],
												plaintext_din[16],
												plaintext_din[8],
												plaintext_din[0]
											};

	assign initial_permutation[40 +: 8] = 	{
												plaintext_din[58],
												plaintext_din[50],
												plaintext_din[42],
												plaintext_din[34],
												plaintext_din[26],
												plaintext_din[18],
												plaintext_din[10],
												plaintext_din[2]
											};

	assign initial_permutation[48 +: 8] = 	{
												plaintext_din[60],
												plaintext_din[52],
												plaintext_din[44],
												plaintext_din[36],
												plaintext_din[28],
												plaintext_din[20],
												plaintext_din[12],
												plaintext_din[4]
											};

	assign initial_permutation[56 +: 8] = 	{
												plaintext_din[62],
												plaintext_din[54],
												plaintext_din[46],
												plaintext_din[38],
												plaintext_din[30],
												plaintext_din[22],
												plaintext_din[14],
												plaintext_din[6]
											};



// -- Selector de origen de datos ---------------------------------------- >>>>>	
	wire [0:31]	round_left;
	wire [0:31]	round_right;

	assign round_left  = (source_sel) ? left_round_out  : initial_permutation[0 :31];
	assign round_right = (source_sel) ? right_round_out : initial_permutation[32:63];



// -- Registros de Entrada ----------------------------------------------- >>>>>
	reg [0:31] left_reg;
	reg [0:31] right_reg;

		always @(posedge clk)
			begin
				if (reset)
					begin
						left_reg  <= {32{1'b0}}; 
						right_reg <= {32{1'b0}};
					end
				else
					if (enable)
						begin
							left_reg  <= round_left;
							right_reg <= round_right;
						end
					
			end



// -- DES function ------------------------------------------------------- >>>>>
	wire [0:47]	right_expansion;
	wire [0:47] right_xor_key;
	wire [0:31]	sboxs_out;
	wire [0:31] pbox_permutation;

	// -- Expansion permutation ------------------------------------------ >>>>>
		assign right_expansion[0  +: 6] = {right_reg[31], right_reg[0 +: 5]};
		assign right_expansion[6  +: 6] = {right_reg[3  +: 6]};
		assign right_expansion[12 +: 6] = {right_reg[7  +: 6]};
		assign right_expansion[18 +: 6] = {right_reg[11 +: 6]};
		assign right_expansion[24 +: 6] = {right_reg[15 +: 6]};
		assign right_expansion[30 +: 6] = {right_reg[19 +: 6]};
		assign right_expansion[36 +: 6] = {right_reg[23 +: 6]};
		assign right_expansion[42 +: 6] = 	{	
												right_reg[27],
												right_reg[28],
												right_reg[29],
												right_reg[30],
												right_reg[31],
												right_reg[0]
											};

	// -- Expanded Right XOR Round Key ----------------------------------- >>>>>
		assign right_xor_key = right_expansion ^ round_key_din;

	// -- S Boxes -------------------------------------------------------- >>>>>
		des_sbox1	sbox1	(
							.right_xor_key_segment_din(right_xor_key[0 +: 6]),
							.sbox_dout(sboxs_out[0 +: 4])
						);

		des_sbox2	sbox2	(
							.right_xor_key_segment_din(right_xor_key[6 +: 6]),
							.sbox_dout(sboxs_out[4 +: 4])
						);

		des_sbox3	sbox3	(
							.right_xor_key_segment_din(right_xor_key[12 +: 6]),
							.sbox_dout(sboxs_out[8 +: 4])
						);

		des_sbox4	sbox4	(
							.right_xor_key_segment_din(right_xor_key[18 +: 6]),
							.sbox_dout(sboxs_out[12 +: 4])
						);

		des_sbox5	sbox5	(
							.right_xor_key_segment_din(right_xor_key[24 +: 6]),
							.sbox_dout(sboxs_out[16 +: 4])
						);

		des_sbox6	sbox6	(
							.right_xor_key_segment_din(right_xor_key[30 +: 6]),
							.sbox_dout(sboxs_out[20 +: 4])
						);

		des_sbox7	sbox7	(
							.right_xor_key_segment_din(right_xor_key[36 +: 6]),
							.sbox_dout(sboxs_out[24 +: 4])
						);

		des_sbox8	sbox8	(
							.right_xor_key_segment_din(right_xor_key[42 +: 6]),
							.sbox_dout(sboxs_out[28 +: 4])
						);
	
	// -- Straight Permutation ---------------------------------------------- >>>>>
		assign pbox_permutation[0 +: 8] = 	{
												sboxs_out[15],
												sboxs_out[6],
												sboxs_out[19],
												sboxs_out[20],
												sboxs_out[28],
												sboxs_out[11],
												sboxs_out[27],
												sboxs_out[16]
											};

		assign pbox_permutation[8 +: 8] = 	{
												sboxs_out[0],
												sboxs_out[14],
												sboxs_out[22],
												sboxs_out[25],
												sboxs_out[4],
												sboxs_out[17],
												sboxs_out[30],
												sboxs_out[9]
											};

		assign pbox_permutation[16 +: 8] = {
												sboxs_out[1],
												sboxs_out[7],
												sboxs_out[23],
												sboxs_out[13],
												sboxs_out[31],
												sboxs_out[26],
												sboxs_out[2],
												sboxs_out[8]
											};

		assign pbox_permutation[24 +: 8] = {
												sboxs_out[18],
												sboxs_out[12],
												sboxs_out[29],
												sboxs_out[5],
												sboxs_out[21],
												sboxs_out[10],
												sboxs_out[3],
												sboxs_out[24]
											};

	// -- Salidas Parciales --------------------------------------------- >>>>>
	assign left_round_out  = right_reg;
	assign right_round_out = pbox_permutation ^ left_reg;


// -- Final Permutation ------------------------------------------------ >>>>>
	wire [0:63]	partial_result;
	wire [0:63]	final_permutation;

	assign partial_result = {right_round_out, left_round_out};

	assign final_permutation[0 +: 8] = 	{
												partial_result[39],
												partial_result[7],
												partial_result[47],
												partial_result[15],
												partial_result[55],
												partial_result[23],
												partial_result[63],
												partial_result[31]
											};

	assign final_permutation[8 +: 8] = 	{
												partial_result[38],
												partial_result[6],
												partial_result[46],
												partial_result[14],
												partial_result[54],
												partial_result[22],
												partial_result[62],
												partial_result[30]
											};

	assign final_permutation[16 +: 8] = 	{
												partial_result[37],
												partial_result[5],
												partial_result[45],
												partial_result[13],
												partial_result[53],
												partial_result[21],
												partial_result[61],
												partial_result[29]
											};

	assign final_permutation[24 +: 8] = 	{
												partial_result[36],
												partial_result[4],
												partial_result[44],
												partial_result[12],
												partial_result[52],
												partial_result[20],
												partial_result[60],
												partial_result[28]
											};

	assign final_permutation[32 +: 8] = 	{
												partial_result[35],
												partial_result[3],
												partial_result[43],
												partial_result[11],
												partial_result[51],
												partial_result[19],
												partial_result[59],
												partial_result[27]
											};

	assign final_permutation[40 +: 8] = 	{
												partial_result[34],
												partial_result[2],
												partial_result[42],
												partial_result[10],
												partial_result[50],
												partial_result[18],
												partial_result[58],
												partial_result[26]
											};

	assign final_permutation[48 +: 8] = 	{
												partial_result[33],
												partial_result[1],
												partial_result[41],
												partial_result[9],
												partial_result[49],
												partial_result[17],
												partial_result[57],
												partial_result[25]
											};

	assign final_permutation[56 +: 8] = 	{
												partial_result[32],
												partial_result[0],
												partial_result[40],
												partial_result[8],
												partial_result[48],
												partial_result[16],
												partial_result[56],
												partial_result[24]
											};


	assign ciphertext_dout = final_permutation;

endmodule
