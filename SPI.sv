module SPI (
    input  logic       clk,              // CLK hệ thống cấp
    input  logic [7:0] SPI_data_trans,   // 8 bits data gửi đi
    input  logic       SPI_MSB,          // = 1 truyền MSB trước
    input  logic       SPI_start,        // = 1 bắt đầu truyền
    input  logic       SPI_reset,        // reset 
    input  logic [1:0] SPI_div,          // chọn tần số chia
    input  logic       SPI_miso,         // dữ liệu vào từ slave
    output logic       SPI_mosi,         // dữ liệu ra tới slave
    output logic       SPI_slave_select, // active low
    output logic [7:0] SPI_data_rec,     // dữ liệu nhận về
    output logic       SPI_flag,          // 1 khi đang truyền
	 output logic sck
	 );

    SPI_freq_div freq_div (
        .clk(clk),
        .rstn(SPI_reset),      
        .SPI_div(SPI_div),
        .sck(sck)
    );

    SPI_FSM FSM (
        .sck(sck),
        .rstn(SPI_reset),
        .start(SPI_start),
        .miso(SPI_miso),
        .mosi(SPI_mosi),
        .tx_d(SPI_data_trans),
        .ss(SPI_slave_select),
        .rx_d(SPI_data_rec),
        .MSB(SPI_MSB),
        .flag(SPI_flag)
    );

endmodule

	
///////// FSM of SPI /////////
module SPI_FSM (
    input  logic       sck,    // Clock SPI
    input  logic       rstn,   // Reset (active-low)
    input  logic       start,     // start SPI
    input  logic       MSB,    // MSB = 1 MSB trans
    input  logic       miso,   // Master In Slave Out
    input  logic [7:0] tx_d,   // Dữ liệu gửi đi
	 output logic 		  flag,	 // Flag = 1 SPI is transmmiting
    output logic       ss,     // Slave Select (Active Low)
    output logic       mosi,   // Master Out Slave In
    output logic [7:0] rx_d    // Dữ liệu nhận về
);
logic [2:0] counter;
logic [7:0] data;
logic [1:0] next, current;
logic trans_enable;
logic load_enable;
localparam IDLE = 2'B00;
localparam TRANS = 2'B10;
localparam DONE = 2'B01;

// FSM Combinational Logic
 always_comb begin
        case (current)
            IDLE: begin
                if (start) 
                    next = TRANS;
                else    
                    next = IDLE;
            end
            TRANS: begin
                if (counter == 3'b111) 
                    next = DONE;
                else 
                    next = TRANS;
            end
            DONE: begin
                next = IDLE;
            end
            default: next = IDLE;
        endcase
    end
	 
always_ff @ (posedge sck or negedge rstn) begin
	if (!rstn) current <= IDLE;
	else current <= next;
end

always_comb begin
  	ss 	  	 = 1'b1;
    rx_d     = 8'b0;
    flag     = 1'b0;
  	load_enable = 1'b0;
	case (current[1:0])
		IDLE: begin
		 ss 	  = 1'b1;
         rx_d     = 8'b0;
         flag     = 1'b0;
     	 load_enable = 1'b1;
		end

		TRANS: begin
		 flag = 1'b1;
         ss = 1'b0;
        end
		DONE: begin
		 flag = 1'b0;
		 ss = 1'b1;
		 rx_d = data;
		end
		default: begin
         ss 	  = 1'b1;
		 rx_d 	  = 8'b0;
         flag     = 1'b0;
        end
	endcase
end
  
  always_ff @ (posedge sck) begin
    if(load_enable) data <= tx_d;
    else data <= data;
    if(flag) begin
      counter <= counter + 1'b1;
      if(MSB) begin
		mosi		<= data[7];
		data	<= {data[6:0],miso};
      end
      else begin
        mosi		<= data[0];
		data	<= {miso,data[7:1]};
      end
    end
      
 	else begin
      counter <= 3'b0;
      mosi <= 1'b0;
  	end
  end
endmodule 

////////SPI frequency divider ///////////
module SPI_freq_div (
	input  logic       clk,     // Clock gốc
	input  logic       rstn,    // Reset
   input  logic [1:0] SPI_div,     // Chọn tần số đầu ra: 00/01/10/11
   output logic       sck  	// Clock sau chia được chọn
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
            2'b00: sck = clk; // Không chia
            2'b01: sck = f1;  // clk / 2
            2'b10: sck = f2;  // clk / 4
            2'b11: sck = f3;  // clk / 8
        endcase
    end

endmodule

