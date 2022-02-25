`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:08:38 07/14/2021 
// Design Name: 
// Module Name:    display_top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module display_top(
	// input 
	vga_clk,
	rst,
	vga_rd_data,
	vga_addr,
	vga_rd_en,
	txt_ovr,
	//output 
	vsync,
	hsync,
	lcd_x,
	lcd_y, 
	lcd_en,
	LCD_Red,
	LCD_Green,
	LCD_Blue
	
    );

	input vga_clk;
	input rst;
	

	input [31:0]	vga_rd_data;
	input 			txt_ovr;
	
	output [29:0]	vga_addr;
	output 		 	vga_rd_en;
	output			vsync;
	output			hsync;
	output [15:0]	lcd_x;
	output [15:0]	lcd_y;
	
	output [2:0] LCD_Red;
	output [2:0] LCD_Green;
	output [1:0] LCD_Blue;
	output 		 lcd_en;
	

	//localparam white_color  = 16'b11111_111111_11111;
	localparam white_color  = 8'b111_111_11;
	localparam red_color 	= 16'b11111_000000_00000;
	localparam green_color	= 16'b00000_111111_00000;
	localparam blue_color	= 16'b00000_000000_11111;
	localparam yellow_color = 16'b11111_111111_00000;

	//wire hsync;
	wire [9:0] x;
	wire [8:0] y;
	wire [3-1:0] red;
	wire [3-1:0] green;
	wire [2-1:0] blue;
	wire de;
	
	assign vga_addr  = (x)+((y)*640); 
	assign vga_rd_en = de;
	assign lcd_x	 = x;
	assign lcd_y	 = y;
	
	 reg [7:0]rgb_data;
	
	// always@(posedge vga_clk) begin 
		// if(rst) begin 
			// rgb_data <= 0;
		// end 
		// else if(x < 160)
			// rgb_data <= red_color;
		// else if(x < 320)
			// rgb_data <= green_color;
		// else if(x < 480)
			// rgb_data <= blue_color;
		// else
			// rgb_data <= yellow_color;
	// end 
	
	
	
	always@(posedge vga_clk) begin 
		if(rst) begin 
			rgb_data <= 0;
		end
		else if(txt_ovr) begin 
			rgb_data <= white_color;//blue_color;
		end 
		else
			rgb_data <= vga_rd_data[7:0];
			//{vga_rd_data[7:5],2'b11,vga_rd_data[4:2],3'b111,vga_rd_data[1:0],3'b111};
	end 
	

	display display_0(
		.clk(vga_clk), 
		.rst(rst), 
		.color(rgb_data), 
		.hsync(hsync), 
		.vsync(vsync),
		.de(de),
		.red(red), 
		.green(green), 
		.blue(blue),
		.x(x), 
		.y(y)
	);
	
	reg [4:0]lcd_r;
	reg [5:0]lcd_g;
	reg [4:0]lcd_b;
	reg lcd_de;
	
	always@(posedge vga_clk)
		if(rst) begin 
			lcd_r <= 0;
			lcd_g <= 0;
			lcd_b <= 0;
			lcd_de <= 0;
		end 
		else if(de)begin 
			lcd_r <= red;
			lcd_g <= green;
			lcd_b <= blue;
			lcd_de <= de;
		end 
		else begin 
			lcd_r <= 0;
			lcd_g <= 0;
			lcd_b <= 0;
			lcd_de <= 0;
		end 

	assign LCD_Red   = lcd_r;
	assign LCD_Green = lcd_g;
	assign LCD_Blue  = lcd_b;
	assign lcd_en	 = lcd_de;
	
	
endmodule
