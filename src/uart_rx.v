module uart_rx(
    input           mclk,
    input           n_reset,
    input   [15:0]  baudrate,
    input   [1:0]   parity_sel,
    input           stop_sel,
    input           rd_en,
    output  [7:0]   rdata,
    output          rvalid,     
    output          overrun,    // fifo full 
    output  reg     frame_err,  // stop bit error
    output  reg     parity_err, // parity error
    input           rxd
);

// Define states
reg [1:0] present_state, next_state;
parameter IDLE    = 2'd0;
parameter RECEIVE = 2'd1;
parameter DONE    = 2'd2;

// State flag
wire idle_flag    = (present_state == IDLE)    ? 1'b1 : 1'b0;
wire receive_flag = (present_state == RECEIVE) ? 1'b1 : 1'b0;
wire done_flag    = (present_state == DONE)    ? 1'b1 : 1'b0;

// State update
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        present_state <= IDLE;
    else
        present_state <= next_state;

// State transition
always@(*) begin
    next_state = present_state;
    case(present_state)
        IDLE    : next_state = (idle_flag & rxd_negedge)                                                           ? RECEIVE : IDLE;
        RECEIVE : next_state = ((parity_sel == 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd9)  & (cnt1 == baudrate)) ? DONE : 
                               ((parity_sel == 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd10) & (cnt1 == baudrate)) ? DONE :
                               ((parity_sel != 2'b00) & (stop_sel == 1'b0) & (cnt2 == 4'd10) & (cnt1 == baudrate)) ? DONE :
                               ((parity_sel != 2'b00) & (stop_sel == 1'b1) & (cnt2 == 4'd11) & (cnt1 == baudrate)) ? DONE : RECEIVE;
       DONE     : next_state = (done_flag & (done_cnt == 3'd7))                                                    ? IDLE : DONE;
    endcase
end

// rxd negative edge 
reg rxd_1d, rxd_2d, rxd_3d;
wire rxd_negedge = ~rxd_2d & rxd_3d;
always@(negedge n_reset, posedge mclk)
    if(!n_reset) begin
        rxd_1d <= 1'b1;
        rxd_2d <= 1'b1;
        rxd_3d <= 1'b1;
    end
    else begin
        rxd_1d <= rxd;
        rxd_2d <= rxd_1d;
        rxd_3d <= rxd_2d;
    end

// 1-bit duration counter
reg [15:0] cnt1;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt1 <= 16'b0;
    else
        cnt1 <= (~receive_flag)    ? 16'b0 :
                (cnt1 == baudrate) ? 16'b0 : cnt1 + 1'b1;

// transmitting bit counter
reg [3:0] cnt2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cnt2 <= 4'b0;
    else
        cnt2 <= (~receive_flag)    ? 4'b0 :
                (cnt1 == baudrate) ? cnt2 + 1'b1 : cnt2;

// rxd data field part
reg [7:0] rxd_data;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        rxd_data <= 8'b0;
    else begin
        rxd_data[0] <= ((cnt2 == 4'd1) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[0];
        rxd_data[1] <= ((cnt2 == 4'd2) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[1];
        rxd_data[2] <= ((cnt2 == 4'd3) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[2];
        rxd_data[3] <= ((cnt2 == 4'd4) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[3];
        rxd_data[4] <= ((cnt2 == 4'd5) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[4];
        rxd_data[5] <= ((cnt2 == 4'd6) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[5];
        rxd_data[6] <= ((cnt2 == 4'd7) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[6];
        rxd_data[7] <= ((cnt2 == 4'd8) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_data[7];
    end

// calculate parity bit
wire cal_parity = rxd_data[0]^rxd_data[1]^rxd_data[2]^rxd_data[3]^rxd_data[4]^rxd_data[5]^rxd_data[6]^rxd_data[7];

reg cal_parity2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        cal_parity2 <= 1'b0;
    else
        cal_parity2 <= (parity_sel == 2'b01) ? cal_parity : (parity_sel == 2'b10) ? ~cal_parity : 1'b0;

// parity bit from receive data
reg rxd_parity;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        rxd_parity <= 1'b0;
    else
        rxd_parity <= ((cnt2 == 4'd9) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : rxd_parity;

// stop_bit1 from rxd
reg stop_bit1;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        stop_bit1 <= 1'b0;
    else
        stop_bit1 <= ((parity_sel == 2'b00) & (cnt2 == 4'd9) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d :
                     ((parity_sel != 2'b00) & (cnt2 == 4'd10) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : stop_bit1;

// stop_bit2 from rxd
reg stop_bit2;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        stop_bit2 <= 1'b0;
    else
        stop_bit2 <= ((parity_sel == 2'b00) & (cnt2 == 4'd10) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d :
                     ((parity_sel != 2'b00) & (cnt2 == 4'd11) & (cnt1 == {1'b0, baudrate[15:1]})) ? rxd_3d : stop_bit2;

// done state counter
reg [2:0] done_cnt;
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        done_cnt <= 3'b0;
    else
        done_cnt <= (done_flag) ? done_cnt + 1'b1 : 3'b0;

// errors
// frame_err
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        frame_err <= 1'b0;
    else
        frame_err <= ((done_cnt == 3'd5) & (stop_sel == 1'b0) & (stop_bit1 == 1'b0)) ? 1'b1 : 
                     ((done_cnt == 3'd5) & (stop_sel == 1'b1) & ((stop_bit1 == 1'b0) | (stop_bit2 == 1'b0))) ? 1'b1 : frame_err;

// parity bit error
always@(negedge n_reset, posedge mclk)
    if(!n_reset)
        parity_err <= 1'b0;
    else
        parity_err <= (parity_sel == 2'b00) ? 1'b0 :
                      ((done_cnt == 3'd5) & (cal_parity2 == rxd_parity)) ? 1'b0 :
                      ((done_cnt == 3'd5) & (cal_parity2 != rxd_parity)) ? 1'b1 : parity_err;

wire   fifo_full;
assign overrun = fifo_full;

wire   fifo_empty;
assign rvalid = ~fifo_empty;

wire   [7:0] fifo_din = rxd_data;
wire   fifo_wen = (done_cnt == 3'd2) ? 1'b1 : 1'b0;
wire   fifo_ren = rd_en;
wire   [7:0] fifo_dout;
assign  rdata = fifo_dout;

fifo_16x8 rxd_fifo(
    .clk            (mclk),
    .srst           (1'b0),
    .din            (fifo_din),
    .wr_en          (fifo_wen),
    .rd_en          (fifo_ren),
    .dout           (fifo_dout),
    .full           (fifo_full),
    .empty          (fifo_empty),
    .valid          ()
);

endmodule
