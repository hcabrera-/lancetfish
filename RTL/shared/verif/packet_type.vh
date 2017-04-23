// `include "packet_type.vh"


`define 	PACKET_TYPE 	[(5*32)-1:0]

`define 	SERIAL			[11:0]
`define 	EXTENDED_SERIAL [17:0]
`define 	ORIGEN			[17:12]
`define 	PUERTA			[23:18]
`define 	DESTINO			[29:24]
`define 	TESTIGO			[30]
`define 	ID_HEAD			[31]

`define 	DATA_0			[63 : 32]
`define 	DATA_1			[95 : 64]
`define 	DATA_2			[127: 96]
`define 	DATA_3			[159:128]
