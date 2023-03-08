/*
Layer 1 (physial): RS-232/TTL, this is handled by the FTDI chip on the ice-40 board
Layer 2 (data link): UART (send 8 bits) with clock synch, this is performed in 'uart_trx.v'
Layer 3 (network): This code (send a packet consisting of multiple bytes)
*/



module packet_sender #(parameter PACKET_SIZE = 16'd2)
    (
        input wire clk,
        input [PACKET_SIZE*8-1:0] packet,
        input wire enable,
        output wire txd,
        output reg busy = 0
    );


    reg [7:0] txbyte = 0;
    reg tx_en = 1'b0;
    reg enable_latch = 0;
    reg tx_busy;

    uart_tx_8n1 transmitter (
        .clk (clk),
        .data (txbyte),
        .enable (tx_en),
        .busy (tx_busy),
        .txd (txd)
    );

    reg [15:0] octet = 16'd0;

    always @ (posedge clk) begin


        if (enable_latch == 1) begin //begin sending
            if(tx_busy == 0) begin//tx line is free, send a byte
    
                if(octet != PACKET_SIZE+1) begin
                    txbyte <= packet[octet*8+:8];
                    $write("%c",packet[octet*8+:8]);
                    octet <= octet + 16'd1;
                    tx_en <= 1;
                end else begin//done sending
                    enable_latch <= 0;
                    tx_en <= 0;
                    busy <= 0;
                    octet <= 16'd0;
                    $display(" done!");
                end
            end else begin //tx line is busy, wait
                tx_en <= 0;
            end
        end

        else if(enable == 1 && busy == 0) begin
            enable_latch <= 1;
            busy <= 1;
            octet <= 16'd0;
        end

    end

endmodule