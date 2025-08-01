module tb_uart_tx;

reg             mclk, n_reset;
reg     [15:0]  baudrate       = 16'd900;
reg     [1:0]   parity_sel     = 2'b01;
reg             stop_sel       = 1'b1;
reg     [7:0]   tdata          = 8'h55;
reg             send_en;
wire            txd;
wire            done;

always #5 mclk = ~mclk;

initial begin
    n_reset = 1'b0;
    mclk = 1'b0;

#100 n_reset = 1'b1;
end

reg [9:0] cnt;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt <= 10'b0;
    else
        cnt <= (cnt == 10'd1023) ? 10'd1023 : cnt + 1'b1;

// send_en
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        send_en <= 1'b0;
    else
        send_en <= (cnt == 10'd1000) ? 1'b1 : 1'b0;

initial begin
    $dumpfile("tb_uart_tx.vcd");
    $dumpvars(0, tb_uart_tx);
    #200000
    $finish;
end

uart_tx t0(
    .mclk           (mclk),
    .n_reset        (n_reset),
    .baudrate       (baudrate),
    .parity_sel     (parity_sel),
    .stop_sel       (stop_sel),
    .tdata          (tdata),
    .send_en        (send_en),
    .txd            (txd),
    .done           (done)
);

endmodule
