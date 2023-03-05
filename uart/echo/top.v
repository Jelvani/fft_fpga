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
    reg clock_ctr = 0;
    reg clock_ctr_old = 0;
    wire busy;
    wire uart_rxed;

    /* LED register */
    reg ledval = 0;

    uart_tx_8n1 transmitter (
        .clk (hwclk),
        .data (uart_txbyte),
        .enable (uart_send),
        .busy (busy),
        .txd (ftdi_tx),
    );

    uart_rx_8n1 reciever (
        .clk (hwclk),
        .data (uart_rxbyte),
        .enable (1),
        .ready (uart_rxed),
        .rxd (ftdi_rx),
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