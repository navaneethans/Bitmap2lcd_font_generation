`timescale 1ns / 1ps
module font_read_top_tb ;

				reg clk;
			    reg rst;
				reg [7:0]ascii_value;
				wire vga_hsync;
				wire vga_vsync;
				wire [2:0]vga_Red;
				wire [2:0]vga_Green;
				wire [1:0]vga_Blue;

	font_read_top font_read_top_uut(  
						   .clk(clk),
						   .rst(rst),
						   .ascii_value(ascii_value),
						   .vga_hsync(vga_hsync),
						   .vga_vsync(vga_vsync),
						   .vga_Red(vga_Red),
						   .vga_Green(vga_Green),
						   .vga_Blue(vga_Blue)
						);
			initial
				begin
					clk = 1'b0;
					rst = 1'b1;
					#500
					rst = 1'b0;
					//ascii_value = "!";
					//#1000
					ascii_value = "4";
					//#2000
					//ascii_value = "C";
				end
				
			always #5 clk = ~clk;
			
endmodule

