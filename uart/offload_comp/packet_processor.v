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

    uart_tx_8n1 uart_transmitter (
        .clk (clk),
        .data (txbyte),
        .enable (tx_en),
        .busy (tx_busy),
        .txd (txd)
    );

    reg [15:0] octet = 16'd0;

    
    always @ (posedge clk) begin


        if (enable_latch == 1) begin //begin sending
            /*
            checking tx_en==1'b0 is necessary to prevent sending every other byte only.
            this way we allow an extra clock cycle for the busy flag in the tx module 
            to turn on after setting the enable flag for the tx module. 
            */
            if(tx_busy == 1'b0 && tx_en == 1'b0) begin//tx line is free, send a byte
                if(octet != PACKET_SIZE) begin
                    //$display("packet_sender: %c",packet[octet*8+:8]);
                    txbyte <= packet[(PACKET_SIZE-octet-1)*8+:8];
                    octet <= octet + 16'd1;
                    tx_en <= 1'b1;
                end else begin//done sending
                    enable_latch <= 0;
                    tx_en <= 0;
                    busy <= 0;
                    octet <= 16'd0;
                    $display("packet_sender: sent!");
                end
            end else begin //tx line is busy, wait
                tx_en <= 1'b0;
            end
        end

        else if(enable == 1 && busy == 0) begin
            enable_latch <= 1;
            busy <= 1;
            octet <= 16'd0;
        end

    end

endmodule


module packet_reciever #(parameter PACKET_SIZE = 16'd2)
    (
        input wire clk,
        output reg [PACKET_SIZE*8-1:0] packet,
        input wire enable,
        input wire rxd,
        output reg ready = 1'b0
    );

    reg [7:0] rxbyte;
    reg rx_ready;

    uart_rx_8n1 uart_reciever (
        .clk (clk),
        .data (rxbyte),
        .enable (1'b1),
        .ready (rx_ready),
        .rxd (rxd)
    );

    reg [15:0] octet = 16'd0;

    always @(posedge clk) begin

        if(rx_ready == 1'b1) begin
            if(octet != PACKET_SIZE-1) begin
                ready <= 1'b0;
                packet[(PACKET_SIZE - octet - 1)*8+:8] <= rxbyte;
                octet <= octet + 16'd1;
            end else begin //recieve last byte of packet
                packet[0+:8] <= rxbyte;
                ready <= 1'b1;
                octet <= 16'd0;
            end
        end
        
        if(ready == 1'b1) begin
            ready <= 1'b0;
        end



    end

    always @(posedge ready) begin
        $display("packet_reciever: recieved!");
    end






endmodule