	module font_read_top(  input clk,
						   input rst,
						   input [7:0]ascii_value,
						   output vga_hsync,
						   output vga_vsync,
						   output [2:0]vga_Red,
						   output [2:0]vga_Green,
						   output [1:0]vga_Blue
						);
						
		
		wire [9:0]lcd_x;
		wire [9:0]lcd_y;
		wire lcd_en;
		wire txt_ovr;
		wire vga_rd_en;
		wire decode_done;
		wire clk_25;
		
		clk_gen clk_vga
				(
				 .CLK_IN1(clk),
				 .CLK_OUT1(clk_25)
				);    
		
							
		font14_verdana_decode  verdana14(	
							.clk(clk_25),
							.rst(rst),
							
							.en(lcd_en),
							.x(lcd_x),
							.y(lcd_y),
							
							.txt(txt_ovr),
							.decode_done(decode_done)
							
							); 
				 
		display_top display_uut(
							.vga_clk(clk_25), 
							.rst(rst || ~decode_done), //
												
							.lcd_x(lcd_x),
							.lcd_y(lcd_y),
							.txt_ovr(txt_ovr),
							.vga_rd_data(32'd0), 
							.vga_addr(), //vga_addr
							.vga_rd_en(vga_rd_en),//
							.vsync(vga_vsync),
							.hsync(vga_hsync),
							.LCD_Red(vga_Red), 
							.LCD_Green(vga_Green), 
							.LCD_Blue(vga_Blue), 
							.lcd_en(lcd_en) 
							
						);
endmodule

		
