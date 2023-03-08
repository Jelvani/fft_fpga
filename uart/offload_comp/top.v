module top (
    input wire hwclk, 
    output wire led1,
    output wire ftdi_tx,
    input wire ftdi_rx,
    );


    reg [8*9-1:0] data = "123456789";
    reg enb = 1'b0;
    reg busy;
    packet_sender #( .PACKET_SIZE(16'd9)) transmitter (
        .clk(hwclk),
        .packet(data),
        .enable(enb),
        .txd(ftdi_tx),
        .busy(busy)
    );

    reg [31:0] ctr = 0;
    
    always @ (posedge hwclk) begin
        if (ctr == 12000000 && busy == 0) begin
            enb <= 1;
            ctr <= 0;
            led1 <= ~led1;
        end
        else begin
            ctr <= ctr + 1;
            enb <= 0;
        end
    end


endmodule