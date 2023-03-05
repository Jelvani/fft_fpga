module uart_tx_8n1 (
    clk,        // input clock
    txbyte,     // outgoing byte
    senddata,   // trigger tx
    busy,     // outgoing byte sent
    tx         // tx wire
    );

    /* Inputs */
    input clk;
    input[7:0] txbyte;
    input senddata;

    /* Outputs */
    output busy;
    output tx;

    /* Parameters */
    parameter STATE_IDLE=8'd0;
    parameter STATE_STARTTX=8'd1;
    parameter STATE_TXING=8'd2;

    /* State variables */
    reg[7:0] state = 8'b0;
    reg[7:0] buf_tx;
    reg[7:0] bits_sent = 8'b0;
    reg txbit=1'b1;
    reg busy=1'b0;

    /* Wiring */
    assign tx=txbit;


    reg rst = 0;;
    reg baud_clock;
    baud_clock baud_clk (
        .clk (clk),
        .rst (rst),
        .enable (1),
        .baud_clock (baud_clock),
    );

    reg senddata_latch = 0;
    /* UART state machine */
    always @ (posedge baud_clock) begin
        // start sending?
        if (senddata_latch == 1 && state == STATE_IDLE) begin
            buf_tx <= txbyte;
            busy <= 1'b1;
            bits_sent <= 8'b0;
            txbit <= 1'b0; //send start bit (low)
            state <= STATE_TXING;
        end else if (state == STATE_IDLE) begin
            // idle at high
            txbit <= 1'b1;
            busy <= 1'b0;
        end

        // clock data out
        if (state == STATE_TXING && bits_sent < 8'd8) begin
            txbit <= buf_tx[bits_sent[2:0]];
            bits_sent <= bits_sent + 1;
            if (bits_sent == 7) begin
                state <= STATE_IDLE;
                busy <= 1'b0;
            end
        end 

        /*
        else if (state == STATE_TXING) begin
            // send stop bit (high)
            txbit <= 1'b1;
            bits_sent <= 8'b0;
            state <= STATE_IDLE;
            busy <= 1'b1;
        end
        */
    end

    always @(posedge clk) begin
        if(senddata == 1 && busy == 0) begin
            senddata_latch <= 1;
        end
        else if (busy == 1) begin
            senddata_latch <= 0;
        end
    end
    

endmodule


/*currently this module has an issue*/
module uart_rx_8n1 #(parameter BAUD_RATE = 19200, CLOCK_FREQ = 12000000)
    (
    clk,        // input clock
    rxbyte,     // incoming byte
    recvdata,   // trigger rx
    rxdone,     // incoming byte recieved
    rx         // rx wire
    );

    /* Inputs */
    input clk;
    input rx;
    input recvdata;

    /* Outputs */
    output rxdone;
    output reg[7:0] rxbyte;

    /* Parameters */
    parameter STATE_IDLE=8'd0;
    parameter STATE_RXING=8'd1;
    parameter STATE_DONE=8'd2;

    /* State variables */
    reg[7:0] state=8'b0;
    reg[7:0] bits_recv=8'b0;
    reg rxdone=1'b0;

    reg rst = 0;;
    reg baud_clock;
    reg enable_baud = 0;
    baud_clock baud_clk (
        .clk (clk),
        .rst (rst),
        .enable (enable_baud),
        .baud_clock (baud_clock),
    );


    /* UART state machine */
    always @ (posedge baud_clock) begin

        // recv start bit (low)
        if (state == STATE_IDLE && rx == 1'b0 && recvdata == 1) begin
            state <= STATE_RXING;
            rxdone <= 1'b0;
        end
        else if(state == STATE_IDLE && rx == 1'b1) begin
            state <= STATE_IDLE;
            rxdone <= 1'b0;
        end
        // clock data recv
        if (state == STATE_RXING && bits_recv < 8'd8) begin
            rxbyte[bits_recv[2:0]] <= rx;
            //$display("rxbit: %b",rxbit);
            bits_recv <= bits_recv + 1;
            //$display("rxbyte: %b",rxbyte);
            if (bits_recv == 7) begin
                state <= STATE_DONE;
            end
            
        end 
        
        if (state == STATE_DONE) begin
            
            bits_recv <= 8'b0;
            // recv stop bit (high)
            if (rxbit == 1'b1) begin
                //rxdone <= 1'b1;
            end

            //no error checking for now

            rxdone <= 1'b1;
            state <= STATE_IDLE;

  
        end

    end

    reg [3:0] sync_ctr = 0;
    reg [31:0] start_ctr = 0;
    reg manual_trig = 0;
    parameter STATE_CHECK=8'd0;
    parameter STATE_CHECKING=8'd1;
    parameter STATE_CLOCKRST=8'd2;
    parameter STATE_WAIT_TILL_RXDONE=8'd3;
    reg [7:0] oversampler_state = STATE_CHECK;
    /*clock oversampling for baudrate synch*/
    always @ (posedge clk) begin
        //check if pin is low for 5 clock cycles to filter possible erros/noise
        if(oversampler_state == STATE_CHECK) begin
            sync_ctr <= 0;
            rst <= 0;
            start_ctr <= 5;
            enable_baud <= 0;

            if(rx == 1'b0) begin
                oversampler_state <= STATE_CHECKING;
            end
        end

        //make sure wire is low for more than a few cycles
        if (oversampler_state == STATE_CHECKING) begin
            sync_ctr <= sync_ctr + 1;
            if (rx == 1'b1) begin
                oversampler_state <= STATE_CHECK;
            end

            if(sync_ctr == 5) begin
                oversampler_state <= STATE_CLOCKRST;
            end
        end

        //begin baud clock at middle of low signal
        if (oversampler_state == STATE_CLOCKRST) begin
            start_ctr <= start_ctr + 1;

            if(start_ctr >= (CLOCK_FREQ/BAUD_RATE)/2) begin
                rst <= 1;
                enable_baud <= 1;
                oversampler_state <= STATE_WAIT_TILL_RXDONE;
            end
        end

        if(oversampler_state == STATE_WAIT_TILL_RXDONE) begin
            rst <= 0;
            //after byte is recieved, disable baudclock until next edge
            if(rxdone == 1) begin
                enable_baud <= 0;
                oversampler_state <= STATE_CHECK;
                 
            end
        end

    end


endmodule