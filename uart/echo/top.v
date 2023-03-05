/* Top level module UART echo demo */
module top (
    // input hardware clock (12 MHz)
    hwclk, 
    // all LEDs
    led1,
    // UART lines
    ftdi_tx,
    ftdi_rx,
    );

    /* Clock input */
    input hwclk;

    /* LED outputs */
    output led1;

    /* FTDI I/O */
    output ftdi_tx;
    input ftdi_rx;


    /* UART registers */
    reg [7:0] uart_txbyte;
    reg [7:0] uart_rxbyte;
    reg uart_send = 1'b0;
    reg uart_recv = 1'b1;
    reg clock_ctr = 0;
    reg clock_ctr_old = 0;
    wire busy;
    wire uart_rxed;

    /* LED register */
    reg ledval = 0;

    /* UART transmitter module designed for
       8 bits, no parity, 1 stop bit. 
    */
    uart_tx_8n1 transmitter (
        // 9600 baud rate clock
        .clk (hwclk),
        // byte to be transmitted
        .txbyte (uart_txbyte),
        // trigger a UART transmit on baud clock
        .senddata (uart_send),
        // input: tx is finished
        .busy (busy),
        // output UART tx pin
        .tx (ftdi_tx),
    );

    uart_rx_8n1 reciever (
        // 9600 baud rate clock
        .clk (hwclk),
        // byte to be recieved
        .rxbyte (uart_rxbyte),
        // trigger a UART recieve
        .recvdata (uart_recv),
        // input: rx is finished
        .rxdone (uart_rxed),
        // input UART rx pin
        .rx (ftdi_rx),
    );

    /* Wiring */
    assign led1=ledval;

    always @ (posedge hwclk) begin
    /*if clock_ctr has changed, send 1 byte*/
        if (clock_ctr_old != clock_ctr) begin
            uart_send <= 1'b1;
            clock_ctr_old <= clock_ctr;
        end else begin
            uart_send <= 1'b0;
            
        end
    end

    //triggered when byte is recieved
    always @ (posedge uart_rxed) begin
        ledval = ~ledval;
        uart_txbyte = uart_rxbyte;
        clock_ctr = ~clock_ctr; //tick clock to send byte back

    end

    


endmodule