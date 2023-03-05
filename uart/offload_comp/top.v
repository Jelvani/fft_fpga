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


endmodule