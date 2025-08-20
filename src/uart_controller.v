module uart_controller(
    input           mclk,
    input           n_reset,
    input   [15:0]  baud_max_cnt,
    input   [1:0]   parity_sel,
    input           stop_sel,
    input   [7:0]   tr_data,
    input           send_en,
    output          tr_ready, // uart_tx transmit ready flag
    output          txd, 
    input           rxd, 
    input           read_en,
    output  [7:0]   rd_data,
    output          rd_valid,
    output          full,
    output          frame_err,
    output          parity_err
);

uart_tx t0(
    .mclk               (mclk           ),
    .n_reset            (n_reset        ),
    .baud_max_cnt       (baud_max_cnt   ),
    .parity_sel         (parity_sel     ),
    .stop_sel           (stop_sel       ),
    .tr_data            (tr_data        ),
    .send_en            (send_en        ),
    .done               (tr_ready       ),
    .txd                (txd            )
);

uart_rx t1(
    .mclk               (mclk           ),
    .n_reset            (n_reset        ),
    .baud_max_cnt       (baud_max_cnt   ),
    .parity_sel         (parity_sel     ),
    .stop_sel           (stop_sel       ),
    .rd_data            (rd_data        ),
    .read_en            (read_en        ),
    .rd_valid           (rd_valid       ),
    .full               (full           ),
    .frame_err          (frame_err      ),
    .parity_err         (parity_err     ),
    .rxd                (rxd            )
);

endmodule
