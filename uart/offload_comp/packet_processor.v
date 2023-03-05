/*
Layer 1 (physial): RS-232/TTL, this is handled by the FTDI chip on the ice-40 board
Layer 2 (data link): UART (send 8 bits) with clock synch, this is performed in 'uart_trx.v'
Layer 3 (network): This code (send a packet consisting of multiple bytes)
*/



module packet_sender #(parameter integer PACKET_SIZE = 10)
    (
        input wire clk,
        input [15:0] packet,
        input wire enable,
        output wire txd,
        output reg busy = 0
    );


    reg [15:0] txbyte = 0;
    reg tx_en = 1'b0;
    reg enable_latch = 0;
    reg tx_busy;

    uart_tx_8n1 transmitter (
        .clk (clk),
        .data (txbyte),
        .enable (tx_en),
        .busy (tx_busy),
        .txd (txd),
    );

    reg [15:0] octet = 0;

    always @ (posedge clk) begin


        if (enable_latch == 1) begin //begin sending
            if(tx_busy == 0) begin//tx line is free, send a byte
    
                if(octet < 2) begin
                    txbyte <= packet[octet*8+:8];
                    octet <= octet + 1;
                    tx_en <= 1;
                end

                    enable_latch <= 0;
                    tx_en <= 0;
                end

            end else begin //tx line is busy, wait
                tx_en <= 0;
            end
        end

        else if(enable == 1) begin
            enable_latch <= 1;
            busy <= 1;
        end

    end


    always @ (negedge tx_busy) begin //tx line is free again 


            if(octet < 2) begin
                txbyte <= packet[octet*8+:8];
                octet <= octet + 1;
                tx_en <= 1;
            end
            else begin
                busy <= 0;
                octet <= 0;
            end
        

    end

endmodule