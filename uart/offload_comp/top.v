module top (
    input wire hwclk, 
    output wire led1,
    output wire ftdi_tx,
    input wire ftdi_rx
    );
    parameter packet_size = 16'd4; 
    
    reg [8*packet_size-1:0] data_tx;
    reg [8*packet_size-1:0] data_rx;
    reg enb = 1'b0;
    reg busy;
    reg ready;
    
    packet_sender #( .PACKET_SIZE(packet_size)) p_transmitter (
        .clk(hwclk),
        .packet(data_tx),
        .enable(enb),
        .txd(ftdi_tx),
        .busy(busy)
    );

    
    packet_reciever #( .PACKET_SIZE(packet_size)) p_reciever (
        .clk(hwclk),
        .packet(data_rx),
        .enable(1'b1),
        .rxd(ftdi_rx),
        .ready(ready)
    );
    
    always @ (posedge hwclk) begin
        if(ready == 1'b1) begin
            data_tx <= data_rx;
            enb <= 1'b1;
            led1 <= ~led1;
        end
        else if(enb == 1'b1) begin
            enb <= 1'b0;
        end
    end

endmodule