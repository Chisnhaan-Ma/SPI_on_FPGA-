module testbench;
logic rstn,master,clk,clk_s,miso;
logic mosi,clk_m,ss_m_0,ss_m_1,ss,done;
logic[3:0]counter;
logic [7:0]data;

parameter sys_clk = 30;
spi_master  spi_test(.rstn(rstn),.clk(clk),.miso(miso),.mosi(mosi),.clk_m(clk_m),.ss(ss),.ss_m_0(ss_m_0),.ss_m_1(ss_m_1),.done(done),.data(data),.counter(counter));
initial begin :dump
	$fsdbDumpfile("testbench.fsdb");
	$fsdbDumpvars(0,testbench,"+all");
end

initial begin
	clk = 0;
	forever #(sys_clk/6) clk = ~clk;
end


initial begin
	clk_s = 0;
	forever #(sys_clk/6) clk_s = ~clk_s;
end

initial begin :master_test
	rstn = 1'b0; miso = 1'b1; ss = 1'b0; 
	#50 rstn = 1'b1; miso = 1'b0;
	#60 miso = 1'b0;  ss = 1'b1;
	#15 miso = 1'b1;master =1'b0;
	#40 miso = 1'b0;
	#30 miso = 1'b1;
end

initial begin :main_run
#500
$finish;
end

endmodule
