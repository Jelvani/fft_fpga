`include "fft-core/fftmain.v"
`include "fft-core/bitreverse.v"
`include "fft-core/laststage.v"
`include "fft-core/qtrstage.v"
`include "fft-core/fftstage.v"
`include "fft-core/butterfly.v"
`include "fft-core/convround.v"
`include "fft-core/longbimpy.v"
`include "fft-core/bimpy.v"
module top (
	input  clk,
	output LED0,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
	output LED6,
	output LED7
);
	reg [8191:0] fft_array = 10;
	reg [8191:0] fft_out;
	reg out_sync;
	reg rst = 1'b0;
	generate
		genvar i;
		for(i=0;i<10;i=i+1)
		begin
			fftmain f1(clk,rst,1'b1,fft_array,fft_out,out_sync);
		end
	endgenerate	
	


	localparam BITS = 8;
	localparam LOG2DELAY = 22;

	reg [BITS+LOG2DELAY-1:0] counter = 0;
	reg [BITS-1:0] outcnt;

	always @(posedge clk) begin
		counter <= counter + 1;
		outcnt <= counter >> LOG2DELAY;
		if(rst == 1'b0)
			rst = 1'b1;
		else
			rst = 1'b0;


	end

	assign {LED0, LED1, LED2, LED3, LED4, LED5, LED6, LED7} = outcnt ^ (outcnt >> 1);
endmodule
