module SPI (
    input  logic       clk,    // Clock SPI
    input  logic       rstn,   // Reset (active-low)
    input  logic       en,     // Enable SPI
    input  logic       miso,   // Master In Slave Out
    input  logic [7:0] tx_d,   // Dữ liệu gửi đi
    output logic       ss,     // Slave Select (Active Low)
    output logic       mosi,   // Master Out Slave In
    output logic [7:0] rx_d    // Dữ liệu nhận về
);
logic [2:0] counter;
logic [7:0] data;
logic [1:0] next, current;

localparam IDLE = 2'B00;
localparam LOAD = 2'B01;
localparam BUSY = 2'B10;
localparam DONE = 2'B11;

// FSM Combinational Logic
 always_comb begin
        case (current)
            IDLE: begin
                if (en) 
                    next = LOAD;
                else    
                    next = IDLE;
            end
            LOAD: begin
                next = BUSY;
            end
            BUSY: begin
                if (counter == 3'b111) 
                    next = DONE;
                else 
                    next = BUSY;
            end
            DONE: begin
                next = IDLE;
            end
            default: next = IDLE;
        endcase
    end
	 
always_ff @ (posedge clk or negedge rstn) begin
	if (!rstn) current <= IDLE;
	else current <= next;
end

always_ff @ (posedge clk or negedge rstn) begin
	case (current[1:0])
		IDLE: begin
			ss 		<= 1'b1;
			counter  <= 3'b000;
         data     <= 8'b0;
         mosi     <= 1'b0;
         rx_d     <= 8'b0;
		end
		LOAD: begin
			ss 		<= 1'b0;
			data		<= tx_d;
		end
		BUSY: begin
			mosi		<= data[7];
			data	<= {data[6:0],miso};
			counter <= counter + 1;
		end
		DONE: begin
			ss <= 1'b1;
			rx_d <= data;
			counter <= 3'b000;
		end
		
	endcase
end





endmodule 