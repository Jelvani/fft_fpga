module uart_tx_8n1 (
    input wire clk,        // input clock
    input [7:0] data,     // outgoing byte
    input wire enable,   // begin sending data
    output reg busy = 1'b0,     // sending in progress?
    output wire txd         // tx wire
    );

    /* Parameters */
    parameter STATE_IDLE = 3'd0;
    parameter STATE_START = 3'd1;
    parameter STATE_DATA = 3'd2;
    parameter STATE_STOP = 3'd3;

    reg [3:0] state_status = 4'b0; 

    reg[2:0] state = 3'b0;
    reg[7:0] buf_tx = 0;
    reg[3:0] bits_sent = 4'b0;
    reg enable_latch = 1'b0;


    wire baud_clock;
    baud_clock baud_clk (
        .clk (clk),
        .rst (0),
        .enable (1),
        .baud_clock (baud_clock),
    );

    /* UART state machine */
    always @ (posedge baud_clock) begin

        if (state == STATE_IDLE) begin
            // idle at high
            txd <= 1'b1;
            bits_sent <= 8'b0;
            state_status <= 4'b0;
        end

        else if (state == STATE_START) begin
            buf_tx <= data;
            bits_sent <= 8'b0;
            txd <= 1'b0; //send start bit (low)
            state_status[STATE_STOP] <= 1'b0;
            state_status[STATE_START] <= 1'b1;
        end

        else if (state == STATE_DATA) begin
            txd <= buf_tx[bits_sent];
            bits_sent <= bits_sent + 1;
            if (bits_sent == 7) begin
                state_status[STATE_START] <= 1'b0;
                state_status[STATE_DATA] <= 1'b1;
            end
        end 

        else if (state == STATE_STOP) begin
            // send stop bit (high)
            txd <= 1'b1;
            bits_sent <= 8'b0;
            state_status[STATE_DATA] <= 1'b0;
            state_status[STATE_STOP] <= 1'b1;
        end
    end

    reg reset = 1'b0;
    always @(posedge clk) begin

        if(state == STATE_IDLE) begin
            if(enable == 1'b1)begin
                state <= STATE_START;
                busy <= 1'b1;
            end
        end
        else if(state_status[STATE_START] == 1'b1) begin
            state <= STATE_DATA;
        end
        else if(state_status[STATE_DATA] == 1'b1) begin
            state <= STATE_STOP;
        end
        else if(state_status[STATE_STOP] == 1'b1 && state!=STATE_START)begin
            //make sure this does not get trigger from STATE_IDLE->STATE_START
            state <= STATE_IDLE;
            busy<= 1'b0;
        end
    end
    

endmodule


/*currently this module has an issue with skipping some bytes*/
//will fix later
module uart_rx_8n1 #(parameter BAUD_RATE = 19200, CLOCK_FREQ = 12000000)
    (
    input wire clk, 
    output [7:0] data,
    input wire enable,
    output reg ready, //data has arrived
    input wire rxd
    );

    /* Parameters */
    parameter STATE_IDLE=8'd0;
    parameter STATE_RXING=8'd1;
    parameter STATE_DONE=8'd2;

    /* State variables */
    reg[7:0] state=8'b0;
    reg[7:0] bits_recv=8'b0;
    reg ready=1'b0;

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
        if (state == STATE_IDLE && rxd == 1'b0 && enable == 1) begin
            state <= STATE_RXING;
            ready <= 1'b0;
        end
        else if(state == STATE_IDLE && rxd == 1'b1) begin
            state <= STATE_IDLE;
            ready <= 1'b0;
        end
        // clock data recv
        if (state == STATE_RXING && bits_recv < 8'd8) begin
            data[bits_recv[2:0]] <= rxd;
            //$display("rxd: %b",rxd);
            bits_recv <= bits_recv + 1;
            //$display("data: %b",data);
            if (bits_recv == 7) begin
                state <= STATE_DONE;
            end
            
        end 
        
        if (state == STATE_DONE) begin
            
            bits_recv <= 8'b0;
            // recv stop bit (high)
            if (rxd == 1'b1) begin
                //ready <= 1'b1;
            end

            //no error checking for now

            ready <= 1'b1;
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

            if(rxd == 1'b0) begin
                oversampler_state <= STATE_CHECKING;
            end
        end

        //make sure wire is low for more than a few cycles
        if (oversampler_state == STATE_CHECKING) begin
            sync_ctr <= sync_ctr + 1;
            if (rxd == 1'b1) begin
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
            if(ready == 1) begin
                enable_baud <= 0;
                oversampler_state <= STATE_CHECK;
                 
            end
        end

    end


endmodule