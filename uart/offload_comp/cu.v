/*compute unit module*/

module add_cu
(
    a,
    b,
    res
);

input wire[31:0] a;
input wire[31:0] b;

output wire[31:0] res;

assign res = a + b;

endmodule