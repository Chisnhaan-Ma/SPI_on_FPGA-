module SPI_slave (
    input  logic        slave_sck,          // Clock từ Master
    input  logic        slave_ss,           // Slave Select, active low
    input  logic        slave_mosi,         // MOSI từ Master
    input  logic [7:0]  slave_data_trans,   // Dữ liệu gửi đi
    input  logic        slave_reset,        // Reset active high
    output logic        slave_miso,         // Gửi về Master
    output logic [7:0]  slave_data_rec      // Dữ liệu nhận được
);

    logic [2:0] counter;
    logic [7:0] shift_reg_slave_tx;
    logic [7:0] shift_reg_slave_rx;

    typedef enum logic[1:0] {IDLE, TRANS, WAIT} state;
    state current, next;

    // FSM chuyển trạng thái
    always_comb begin
        case (current)
            IDLE: begin
                if (slave_ss) next = IDLE;   
                else          next = TRANS; 
            end 
            TRANS:begin
                if (counter==3'd7) next = WAIT;
                else if (slave_ss) next = IDLE;
                else          next = TRANS;
            end
            WAIT: begin
                if(slave_ss) next = IDLE;
                else next = WAIT;
            end
            default: next = IDLE;
        endcase
    end


    always_ff @(posedge slave_sck or negedge slave_reset) begin
        if (!slave_reset) begin
            current <= IDLE;
            counter <= 3'd0;
            shift_reg_slave_tx <= 8'd0;
            shift_reg_slave_rx <= 8'd0;
            slave_data_rec <= 8'd0;
            slave_miso <= 1'b0;
        end 
        else begin
            current <= next;

            case (current)
                IDLE: begin
                    if (!slave_ss) begin 
                        shift_reg_slave_tx <= slave_data_trans;
                        counter <= 3'd0;
                    end
                end

                TRANS: begin
                    shift_reg_slave_rx <= {shift_reg_slave_rx[6:0], slave_mosi};
                    slave_miso <= shift_reg_slave_tx[7];
                    shift_reg_slave_tx <= {shift_reg_slave_tx[6:0], 1'b0};
                    counter <= counter + 1;
                end

                WAIT: begin
					slave_data_rec = shift_reg_slave_rx;
                    counter <= 3'd0;
                end
            endcase
        end
    end
endmodule
