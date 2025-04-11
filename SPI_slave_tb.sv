`include "SPI_slave.sv"
module SPI_slave_tb();

    logic clk;
    logic slave_ss;
    logic slave_mosi;
    logic [7:0] slave_data_trans;
    logic slave_reset;
    logic slave_miso;
    logic [7:0] slave_data_rec;

    // Instantiate the SPI_slave module
    SPI_slave uut (
        .slave_sck(clk),
        .slave_ss(slave_ss),
        .slave_mosi(slave_mosi),
        .slave_data_trans(slave_data_trans),
        .slave_reset(slave_reset),
        .slave_miso(slave_miso),
        .slave_data_rec(slave_data_rec)
    );

    // Clock generation (SPI clock)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // SPI clock 100MHz
    end

    // Test sequence
    initial begin
        $dumpfile("SPI_slave_tb.vcd");
        $dumpvars(0,SPI_slave_tb);

        slave_reset = 0;
        slave_ss = 1;           // Slave not selected
        slave_mosi = 0;
        slave_data_trans = 8'hF0;
        #10;
        
        slave_reset = 1;        // Release reset
        #10;

        // Activate slave
        slave_ss = 0;
        repeat(8) begin
            #10 slave_mosi = $urandom_range(0, 1);
        end
        #30 slave_ss = 1;
        #20 slave_ss = 0;
        #5 slave_mosi = $urandom_range(0, 1);
        #5 slave_mosi = $urandom_range(0, 1);
        #5 slave_mosi = $urandom_range(0, 1);
        #5 slave_ss = 1;
        #50 $finish;
    end


endmodule
