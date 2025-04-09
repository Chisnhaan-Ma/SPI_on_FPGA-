module tb_SPI;

    logic clk;
    logic [7:0] SPI_data_trans;
    logic SPI_MSB;
    logic SPI_start;
    logic SPI_reset;
    logic [1:0] SPI_div;
    logic SPI_miso;
    logic SPI_mosi;
    logic SPI_slave_select;
    logic [7:0] SPI_data_rec;
    logic SPI_flag;

    // Instantiate DUT
    SPI uut (
        .clk(clk),
        .SPI_data_trans(SPI_data_trans),
        .SPI_MSB(SPI_MSB),
        .SPI_start(SPI_start),
        .SPI_reset(SPI_reset),
        .SPI_div(SPI_div),
        .SPI_miso(SPI_miso),
        .SPI_mosi(SPI_mosi),
        .SPI_slave_select(SPI_slave_select),
        .SPI_data_rec(SPI_data_rec),
        .SPI_flag(SPI_flag)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
      $dumpfile("tb_SPI.vcd");
      $dumpvars(0,tb_SPI);
        $display("=== TEST SPI: MSB first ===");
        // Init
        clk = 0;
        SPI_reset = 0;
        SPI_start = 0;
        SPI_data_trans = 8'h0f;
        SPI_MSB = 1;             // MSB first
        SPI_div = 2'b01;         // clk / 2
        SPI_miso = 0;

        // Reset
        #3 SPI_reset = 1;

        // Start truyền
        #10 SPI_start = 1;
        #20 SPI_start = 0;

        // Mô phỏng dữ liệu nhận (MISO = 1 sau mỗi chu kỳ clock)
        repeat(16) begin
            #10 SPI_miso = $urandom_range(0, 1);
        end

        #70;

        $display("=== TEST SPI: LSB first ===");
        // Thay đổi sang LSB
        SPI_data_trans = 8'hf0;
        SPI_MSB = 0;             // LSB first
        SPI_div = 2'b10;         // clk / 4

        // Start truyền
        #10 SPI_start = 1;
        #20 SPI_start = 0;

        // Mô phỏng dữ liệu nhận (MISO)
        repeat(16) begin
            #10 SPI_miso = $urandom_range(0, 1);
        end

        #300;

        $finish;
    end

endmodule
