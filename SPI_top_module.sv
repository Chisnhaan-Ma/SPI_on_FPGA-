module SPI(
    input  logic       clk,              // CLK hệ thống cấp
    input  logic [7:0] SPI_data_trans,   // 8 bits data gửi đi
    input  logic       SPI_MSB,          // = 1 truyền MSB trước
    input  logic       SPI_start,        // = 1 bắt đầu truyền
    input  logic       SPI_reset,        // reset mức thấp 
    input  logic [1:0] SPI_div,          // chọn tần số chia
    input  logic       SPI_miso,         // dữ liệu vào từ slave
    output logic       SPI_mosi,         // dữ liệu ra tới slave
    output logic       SPI_slave_select, // active low
    output logic [7:0] SPI_data_rec,     // dữ liệu nhận về
    output logic       SPI_flag,          // 1 khi đang truyền
  	output logic       sck_slave
);
    logic sck_master;
    SPI_freq_div freq_div (
        .clk(clk),
        .rstn(SPI_reset),      
        .SPI_div(SPI_div),
        .sck_master(sck_master)
    );

    SPI_FSM FSM (
        .sck_master(sck_master),
        .SPI_reset(SPI_reset),
        .SPI_start(SPI_start),
        .SPI_miso(SPI_miso),
        .SPI_mosi(SPI_mosi),
        .SPI_data_trans(SPI_data_trans),
        .ss(SPI_slave_select),
        .SPI_data_rec(SPI_data_rec),
        .SPI_MSB(SPI_MSB),
        .SPI_flag(SPI_flag),
        .sck_slave(sck_slave)
    );

endmodule

	
///////// FSM of SPI /////////
module SPI_FSM (
    input  logic       sck_master,    // Clock SPI
    input  logic       SPI_reset,   // Reset (active-low)
    input  logic       SPI_start,     // start SPI
    input  logic       SPI_MSB,    // MSB = 1 MSB trans
    input  logic       SPI_miso,   // Master In Slave Out
    input  logic [7:0] SPI_data_trans,   // Dữ liệu gửi đi
	output logic 	   SPI_flag,	 // Flag = 1 SPI đang truyền
    output logic       ss,     // Slave Select mức thấp
    output logic       SPI_mosi,   // Master Out Slave In
    output logic [7:0] SPI_data_rec,    // Dữ liệu nhận về
    output logic       sck_slave
);
logic [2:0] counter;
logic [7:0] shift_reg_tx;
logic [7:0] shift_reg_rx;
 
typedef enum logic [1:0] {IDLE,LOAD_DATA,TRANS,DONE} state;
state current, next;
// FSM Combinational Logic
 always_comb begin
        case (current)
            IDLE: begin
                //ss = 1'b1;
                sck_slave = 0;
                if (SPI_start) 
                    next = LOAD_DATA;
                else    
                    next = IDLE;
            end
            LOAD_DATA: begin
                //ss = 1'b0;
                sck_slave = 0;
                next = TRANS;
            end
            TRANS: begin
               // ss = 1'b0;
                sck_slave = sck_master;
                if (counter == 3'b111) 
                    next = DONE;
                else 
                    next = TRANS;
            end
            DONE: begin
                //ss = 1'b0;
                sck_slave = sck_master;
                next = IDLE;
            end
            default: next = IDLE;
        endcase
    end
	 
always_ff @ (posedge sck_master or negedge SPI_reset) begin
    if (!SPI_reset) begin
        current <= IDLE;
        shift_reg_tx <= 8'b0;
        shift_reg_rx <= 8'b0;
        SPI_data_rec <= 8'b0;
        SPI_mosi <= 1'b0;
        //ss <= 1'b1;
        SPI_flag <= 1'b0;
        counter <= 3'b000;
    end else begin
        current <= next;
        // Gán mặc định tránh latch
        shift_reg_tx <= shift_reg_tx;
        shift_reg_rx <= shift_reg_rx;
        SPI_data_rec <= SPI_data_rec;
        SPI_mosi <= SPI_mosi;
        ss <= 1'b1;
        SPI_flag <= 1'b0;
        counter <= counter;

        case (current)
            IDLE: begin
                ss <= 1'b1;
                SPI_flag <= 1'b0;
                counter <= 3'b000;
            end
            LOAD_DATA: begin
                shift_reg_tx <= SPI_data_trans;
                ss <= 1'b1;
            end
            TRANS: begin
                SPI_flag <= 1'b1;
                counter <= counter + 1;
                ss <= ~sck_master;
                if (SPI_MSB) begin
                    SPI_mosi <= shift_reg_tx[7];
                    shift_reg_tx <= {shift_reg_tx[6:0], 1'b0};
                    shift_reg_rx <= {shift_reg_rx[6:0], SPI_miso};
                end else begin
                    SPI_mosi <= shift_reg_tx[0];
                    shift_reg_tx <= {SPI_miso, shift_reg_tx[7:1]};
                    shift_reg_rx <= {SPI_miso, shift_reg_rx[7:1]};
                end
            end

            DONE: begin
                SPI_data_rec <= shift_reg_rx;
                ss <= 1'b1;
                SPI_flag <= 1'b0;
                counter <= 3'b000;
            end
        endcase
    end
end

endmodule


////////SPI frequency divider ///////////
module SPI_freq_div (
	input  logic       clk,     // Clock gốc
	input  logic       rstn,    // Reset bất đồng bộ (active-low)
   input  logic [1:0] SPI_div,     // Chọn tần số đầu ra: 00/01/10/11
   output logic       sck_master  	// Clock sau chia được chọn
);
	// SPI_div
	//00: clk/1;
	//01: ckk/2;
	//10: clk/4;
	//11: clk/8

    logic f1;
	logic f2;
	logic	f3;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            f1 <= 1'b0;
        else
            f1 <= ~f1; // clk / 2
    end

    always_ff @(posedge f1 or negedge rstn) begin
        if (!rstn)
            f2 <= 1'b0;
        else
            f2 <= ~f2; // clk / 4
    end

    always_ff @(posedge f2 or negedge rstn) begin
        if (!rstn)
            f3 <= 1'b0;
        else
            f3 <= ~f3; // clk / 8
    end

    always_comb begin
      case (SPI_div)
            2'b00: sck_master = clk; // Không chia
            2'b01: sck_master = f1;  // clk / 2
            2'b10: sck_master = f2;  // clk / 4
            2'b11: sck_master = f3;  // clk / 8
        endcase
    end

endmodule

