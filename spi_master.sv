module spi_master(
	input logic rstn,
	input logic clk, //system clk
	input logic miso, 
	output logic mosi,
       	input logic ss,
	output logic clk_m, // if SPI master
	output logic ss_m_0,
        output logic ss_m_1,	//slave slection active low
	output logic done,
	output logic [7:0] data,
	output logic [3:0] counter);

////////// SPI master ///////////
	always @ (posedge clk or negedge rstn) begin 
		if (rstn == 0) begin
				data [7:0] <= 8'b0;
				counter [3:0] <= 4'b000;
				ss_m_0 <= 1'b1;
				ss_m_1 <= 1'b1;
				done <= 1'b0;
				mosi <= 1'b0;
			end

			else begin
				mosi <= data [7];
				data[7:0] <= {data [6:0], miso};
				counter <= counter + 1'b1;
				case (ss) 
					0: begin ss_m_0 <= 1'b0; ss_m_1 <= 1'b1; end
					1: begin ss_m_1 <= 1'b0; ss_m_0 <= 1'b1; end
				endcase
				if(counter[3:0] != 4'b0111) begin
					done <=1'b0;
				end

				else begin //done
				done <= 1'b1;
				counter [3:0] <= 4'b0000;
			end
		end
	end

	always @ (posedge clk or negedge clk) begin
		clk_m <= clk;
	end


/////// SPI Slave //////////
//	always @ (posedge clk_s or negedge rstn) begin
//			if(==0)  begin// slave called by other master
//				if (rstn == 0) begin
//					data [7:0] <= 8'b0;
//					counter [3:0] <= 4'b0;
//				end

//				else begin
//					if(counter != 4'b1000) begin
//						mosi <= data [7];
//						data[7:0] <= {data[6:0],miso};
//			 		       	counter	<= counter + 1'b1;
//					end
		
//					else begin //done
//					done <= 1'b1;
//					end
//				end	
//			  end 
	//	end

	//	else begin
	//	end
//	end
endmodule
