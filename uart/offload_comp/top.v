module top (
    input wire hwclk, 
    output wire led1,
    output wire ftdi_tx,
    input wire ftdi_rx,
    );


    reg [15:0] data = "ab";
    reg enb = 1'b0;
    reg busy;
    packet_sender #( .PACKET_SIZE(2)) transmitter (
        .clk(hwclk),
        .packet(data),
        .enable(enb),
        .txd(ftdi_tx),
        .busy(busy)
    );

    reg [31:0] ctr = 0;
    always @ (posedge hwclk) begin
        if (ctr > 12000000-5 && ctr < 12000000 && busy == 0) begin
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