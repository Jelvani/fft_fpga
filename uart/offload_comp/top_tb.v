/* Top level module UART tesbench */
/*TX is connected to RX*/
module top_bench;

    /* Clock input */
    reg clk;

    /* FTDI I/O */
    reg dummy_tx;
    reg dummy_rx;

    reg clk_1;
    reg [31:0] cntr_1;

    reg [8*15-1:0] data;
    reg enb;
    reg busy;
    reg [7:0] rxbyte;

    initial begin
        clk_1 = 0;
        cntr_1 = 32'b0;
        clk = 0;
        data = "this is a test ";
        enb = 1'b0;
        forever begin
            #1 clk = ~clk;
        end 
    end


    packet_sender #( .PACKET_SIZE(16'd15)) transmitter (
        .clk(clk),
        .packet(data),
        .enable(enb),
        .txd(dummy_tx),
        .busy(busy)
    );

    reg ready;
    uart_rx_8n1 recv (
        .clk (clk),
        .data (rxbyte),
        .enable (1),
        .ready (ready),
        .rxd (dummy_tx)
    );

    always @(posedge ready) begin
        $write("%c",rxbyte);
    end

    


    

    /* Low speed clock generation */
    always @ (posedge clk) begin
        cntr_1 <= cntr_1 + 1;
        if (cntr_1 == 5000000) begin
            clk_1 <= ~clk_1;
            cntr_1 <= 32'b0;
            enb <= 1;
        end
        else begin
            enb <= 0;
        end
        
    end

    reg [31:0] res;


    


endmodule