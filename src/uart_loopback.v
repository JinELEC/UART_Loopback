module uart_loopback(
    input           clock,
    input           n_reset,
    input           uart_rxd,
    output          uart_txd,
    input   [3:0]   sw,
    output  [7:0]   led
);

// Define states
reg [1:0] state;
parameter IDLE  = 2'd0;
parameter READ  = 2'd1;
parameter SEND  = 2'd2;

// State flag
wire idle_flag  = (state == IDLE)  ? 1'b1 : 1'b0;
wire read_flag  = (state == READ)  ? 1'b1 : 1'b0;
wire send_flag  = (state == SEND)  ? 1'b1 : 1'b0;

// State transition
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        state <= 2'b0;
    else
        state <= (idle_flag  & rd_valid & tr_ready)           ? READ :
                 (read_flag  & (read_cnt == 3'd7))            ? SEND  :
                 (send_flag  & (send_cnt == 3'd7) & tr_ready) ? IDLE  : state;

//----------------------------------------------------------------------------------------------------------------------------------------------------
// read state counter
reg [2:0] read_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        read_cnt <= 3'b0;
    else
        read_cnt <= (read_flag) ? read_cnt + 1'b1 : 3'b0;

// read enable
reg read_en;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        read_en <= 1'b0;
    else
        read_en <= (read_cnt == 3'd2) ? 1'b1 : 1'b0;

wire [7:0] rd_data;
reg  [7:0] tr_data;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        tr_data <= 8'b0;
    else
        tr_data <= (read_cnt == 3'd7) ? rd_data : tr_data;

reg send_en;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        send_en <= 1'b0;
    else
        send_en <= (read_cnt == 3'd7) ? 1'b1 : 1'b0;

// send state counter
reg [2:0] send_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        send_cnt <= 3'b0;
    else
        send_cnt <= (~send_flag) ? 3'b0 :
                    (send_cnt == 3'd7) ? 3'd7 : send_cnt + 1'b1;

wire tr_ready;
wire rd_valid;

wire [15:0] baud_max_cnt = (sw[0]) ? 16'd10416 : 16'd868; // baudrate: 9600 or 115200

wire [1:0] parity_sel = (sw[2:1] == 2'b00) ? 2'b00 :
                        (sw[2:1] == 2'b01) ? 2'b01 :
                        (sw[2:1] == 2'b10) ? 2'b10 : 2'b00;

wire stop_sel = (sw[3]) ? 1'b1 : 1'b0;

wire full;
wire frame_err;
wire parity_err;

my_uart_controller t0(
    .mclk               (clock              ),
    .n_reset            (n_reset            ),
    .baud_max_cnt       (baud_max_cnt       ),
    .parity_sel         (parity_sel         ),
    .stop_sel           (stop_sel           ),

    .send_en            (send_en            ),
    .tr_data            (tr_data            ),
    .tr_ready           (tr_ready           ),
    .txd                (uart_txd           ),
    
    .read_en            (read_en            ),
    .rd_data            (rd_data            ),
    .rd_valid           (rd_valid           ),
    .full               (full               ),
    .frame_err          (frame_err          ),
    .parity_err         (parity_err         ),
    .rxd                (uart_rxd           )
);

assign led = {2'b0, tr_ready, rd_valid, 1'b0, full, frame_err, parity_err};

endmodule
