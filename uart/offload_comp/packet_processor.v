/*
Layer 1 (physial): RS-232/TTL, this is handled by the FTDI chip on the ice-40 board
Layer 2 (data link): UART (send 8 bits) with clock synch, this is performed in 'uart_trx.v'
Layer 3 (network): This code (send a packet consisting of multiple bytes)
*/



module packet_sender #(parameter PACKET_SIZE = 32)
    (
        clk,
        buff,
        start,
        ftdi_tx,
        busy,
    );

    input clk;
    input reg[PACKET_SIZE-1:0] buff;
    input start; //trigger send packet
    output ftdi_tx;
    output reg busy = 0;

    reg [7:0] txbyte;
    reg sendflag = 1'b0;
    reg startlatch = 0;
    wire txbusy;

    uart_tx_8n1 transmitter (
        .clk (clk),
        .txbyte (txbyte),
        .senddata (sendflag),
        .txbusy (txbusy),
        .tx (ftdi_tx),
    );

    reg [15:0] currrent_byte = 0;
    always @ (posedge clk) begin

        if (startlatch == 1) begin
            if(txbusy == 0) begin
            
                if(currrent_byte < PACKET_SIZE) begin
                    txbyte <= buff[currrent_byte];
                    currrent_byte <= currrent_byte + 1;
                    sendflag <= 1;
                end
                //done transmitting packet
                else begin
                    busy <= 0;
                    startlatch <= 0;
                    currrent_byte <= 0;
                end
            //transmit in progress, disable send flag
            end else begin
                sendflag <= 0;
            end
        end
        
        if(start == 1) begin
            startlatch <= 1;
            busy <= 1;
        end

    end

endmodule


module packet_reciever #(parameter PACKET_SIZE = 32)
    (
        clk,
        buff,
        busy,
    );


    input clk;
    output reg[PACKET_SIZE-1:0] buff;
    output reg busy = 0;


     always @ (posedge clk) begin
        $display("buff size: ", $size(buff));

     end

endmodule