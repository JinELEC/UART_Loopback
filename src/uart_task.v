module uart_task(
    input           clock,
    input           n_reset,
    input   [3:0]   btn,
    output          uart_txd
);

wire [3:0] btn_out_clear;
btn_in t0(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[0]             ),
    .btn_out        (btn_out_clear[0]   )
);

btn_in t1(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[1]             ),
    .btn_out        (btn_out_clear[1]   )
);

btn_in t2(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[2]             ),
    .btn_out        (btn_out_clear[2]   )
);

btn_in t3(
    .clock          (clock              ),
    .n_reset        (n_reset            ),
    .btn_in         (btn[3]             ),
    .btn_out        (btn_out_clear[3]   )
);

reg [7:0] tr_data;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        tr_data <= 8'b0;
    else
        tr_data <= (btn_out_clear[0]) ? 8'h41 :
                   (btn_out_clear[1]) ? 8'h42 :
                   (btn_out_clear[2]) ? 8'h43 :
                   (btn_out_clear[3]) ? 8'h44 : tr_data;

wire send_en = (btn_out_clear[0] | btn_out_clear[1] | btn_out_clear[2] | btn_out_clear[3]);

wire        done;
wire [15:0] baud_max_cnt = 16'd10416;
wire [1:0]  parity_sel   = 2'b00;
wire        stop_sel     = 1'b0;

uart_tx t4(
    .mclk               (clock              ),
    .n_reset            (n_reset            ),
    .baud_max_cnt       (baud_max_cnt       ),
    .parity_sel         (parity_sel         ),
    .stop_sel           (stop_sel           ),
    .tr_data            (tr_data            ),
    .send_en            (send_en            ),
    .txd                (uart_txd           ),
    .done               (done               )
);

endmodule
