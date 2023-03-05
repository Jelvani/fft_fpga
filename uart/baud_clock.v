/*on reset, this generate a posedge clock signal*/
module baud_clock #(parameter BAUD_RATE = 19200, CLOCK_FREQ = 12000000)
    (
    clk,
    rst, //set to high to reset clock generation
    enable,
    baud_clock
    );

    input clk;
    input rst;
    input enable;
    output reg baud_clock = 0;

    reg [31:0] baud_ctr = 32'b0;
    parameter period = (CLOCK_FREQ/BAUD_RATE)/2;

    reg first_tick = 1;
    always @ (posedge clk) begin

        if(rst == 1'b0 && first_tick == 0 && baud_ctr < period) begin
            baud_ctr <= baud_ctr + 1;
        end
        else if(rst == 1'b1 && first_tick == 0) begin
            baud_ctr <= 32'b0;
            baud_clock <= 0;
            first_tick <= 1;
        end
        else if (first_tick == 1) begin
            first_tick <= 0;
            baud_clock <= 1;
        end
        
        if (baud_ctr >= period) begin

            if (enable == 1) begin
                baud_clock <= ~baud_clock; //clock ticks here
            end
            
            baud_ctr <= 32'b0;
        end

    end

endmodule
