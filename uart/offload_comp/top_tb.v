/* Top level module UART tesbench */
/*TX is connected to RX*/
module top_bench;
    parameter packet_size = 16'd15; 
    /* Clock input */
    reg clk;

    /* FTDI I/O */
    reg dummy_tx;
    reg dummy_rx;

    reg clk_1;
    reg [31:0] cntr_1;

    reg [8*packet_size-1:0] data_tx;
    reg [8*packet_size-1:0] data_rx;
    reg enb;
    reg busy;
    reg [7:0] rxbyte;

    initial begin
        clk_1 = 0;
        cntr_1 = 32'b0;
        clk = 0;
        data_tx = "this is a test ";
        enb = 1'b0;
        forever begin
            #1 clk = ~clk;
        end 
    end


    packet_sender #( .PACKET_SIZE(packet_size)) transmitter (
        .clk(clk),
        .packet(data_tx),
        .enable(enb),
        .txd(dummy_tx),
        .busy(busy)
    );


    reg ready;
    packet_reciever #( .PACKET_SIZE(packet_size)) reciever (
        .clk(clk),
        .packet(data_rx),
        .enable(1'b1),
        .rxd(dummy_tx),
        .ready(ready)
    );


    always @(posedge ready) begin
        for(int i = 32'(packet_size); i >= 0; i--) begin
            $display("%d: %c",i,data_rx[8*i+:8]);
        end
        
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