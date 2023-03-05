/* Top level module UART tesbench */
/*TX is connected to RX*/
module top_bench;

    /* Clock input */
    reg clk;

    /* FTDI I/O */
    reg dummy_tx;
    reg dummy_rx;

    /* 9600 Hz clock generation */
    reg clk_9600;
    reg [31:0] cntr_9600;
    parameter period_9600 = 625;

    /* 1 Hz clock generation*/
    reg clk_1;
    reg [31:0] cntr_1;
    parameter period_1 = 6000000/10;

    // Note: could also use "0" or "9" below, but I wanted to
    // be clear about what the actual binary value is.
    parameter ASCII_A = 8'd65;
    parameter ASCII_z = 8'd122;

    /* UART registers */
    reg [7:0] uart_txbyte;
    reg [7:0] uart_rxbyte;
    reg uart_send;
    reg uart_recv;
    reg clock_ctr;
    reg clock_ctr_old;
    reg uart_txed;
    reg uart_rxed;



    initial begin
        clk_9600 = 0;
        cntr_9600 = 32'b0;
        clk_1 = 0;
        cntr_1 = 32'b0;
        uart_txbyte = ASCII_A;
        uart_send = 1'b0;
        uart_recv = 1'b1;
        clock_ctr = 0;
        clock_ctr_old = 0;
        clk = 0;
        forever begin
            #1 clk = ~clk;
        end 
    end

    /* UART transmitter module designed for
       8 bits, no parity, 1 stop bit. 
    */
    uart_tx_8n1 transmitter (
        // 9600 baud rate clock
        .clk (clk_9600),
        // byte to be transmitted
        .txbyte (uart_txbyte),
        // trigger a UART transmit on baud clock
        .senddata (uart_send),
        // input: tx is finished
        .txdone (uart_txed),
        // output UART tx pin
        .tx (dummy_tx)
    );

    uart_rx_8n1 reciever (
        // 9600 baud rate clock
        .clk (clk_9600),
        // byte to be recieved
        .rxbyte (uart_rxbyte),
        // trigger a UART recieve
        .recvdata (uart_recv),
        // input: rx is finished
        .rxdone (uart_rxed),
        // input UART rx pin
        .rx (dummy_tx)
    );



    

    /* Low speed clock generation */
    always @ (posedge clk) begin
        /* generate 9600 Hz clock */
        cntr_9600 <= cntr_9600 + 1;
        if (cntr_9600 == period_9600) begin

            clk_9600 <= ~clk_9600; //clock ticks here
            cntr_9600 <= 32'b0;

        end

        /* generate 1 Hz clock */
        cntr_1 <= cntr_1 + 1;
        if (cntr_1 == period_1) begin
            clk_1 <= ~clk_1;
            cntr_1 <= 32'b0;
        end
        

        
    end

    /* Increment ASCII character*/
    always @ (posedge clk_1 ) begin
    
        if (uart_txbyte > ASCII_z) begin
            uart_txbyte <= ASCII_A;
        end
        else begin
            uart_txbyte <= uart_txbyte + 1;
        end
        
        clock_ctr <= ~clock_ctr;
        
    end

    always @ (negedge clk_9600) begin
    /*if clock_ctr has changed, send 1 byte*/
        if (clock_ctr_old != clock_ctr) begin
            uart_send <= 1'b1;
            clock_ctr_old <= clock_ctr;
        end else begin
            uart_send <= 1'b0;
        end

    end

    reg [31:0] res;
    packet_processor #(.PACKET_SIZE(32)) pp
    (
        .clk(clk_1),
        .buff(res)
    );

    always @ (posedge uart_rxed) begin
        $display("time=%0t TX=%0t RX=%0t",$time,uart_txbyte,uart_rxbyte);

    end

    


endmodule