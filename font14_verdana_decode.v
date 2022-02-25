//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module font14_verdana_decode #(parameter M=10,N=10)
	(clk,rst,en,x,y,txt,decode_done);
	input wire clk;
	input wire rst;
	input wire en;
	
	
	input wire [M-1:0] x;
	input wire [N-1:0] y;
	//input wire [7:0] ascii_value_tb;
	output wire txt;
	output wire decode_done;
	
	
	reg  [15:0] colCnt;
	reg  [15:0] rowCnt;
	
	reg  [15:0] col;
	reg  [15:0] row;
	reg [7:0] addr_char;
	
	reg pixel;	
	reg [2:0]step;
	parameter file_header = 3'd0;
	parameter char_header = 3'd1;
	parameter char_font_data = 3'd2;
	
	
	reg [15:0]char_bitwidth;
	reg [15:0]char_length;
	reg [15:0]char_height;
	reg [15:0]next_char_addr;
	reg [15:0]font_char_addr;
	reg [15:0]fontchar_length;
	reg [7:0]char_asciivalue;
	reg [7:0] font_char_data;
	reg font_char_dataen;
	reg char_en;
	integer i,k;
	
	reg [15:0]font_rom_addr;
	wire [7:0] font_rom_data;
	reg [31:0]font_rom_databuf;
	reg	font_rom_dataen;
	reg [9:0]char_header_count;
	
	reg [7:0]fontchar_rom_data;
	reg [15:0]fontchar_rom_addr;
	reg	fontchar_rom_dataen;
	reg ascii_dataen;
	reg [7:0]char_count;
	//wire decode_done;
	reg [15:0]addr_map;
	
	reg [15:0]addr_char_1, addr_char_2, addr_char_3 ;
	reg [7:0]disp_bitwidth;
	wire [7:0]rom_data;
	
	 reg [7:0]disp_bitwidth_L,
				rom_data_13,
				rom_data_12,
				rom_data_11,
				rom_data_3,
				rom_data_2,
				rom_data_1 ;
		
	initial begin
		col <= 0;
		row <= 0;
	end
	
	reg [7:0]font_rom[6400:0];
	
	//reg [7:0]fontchar_rom[6624:0];// 96 x 38, 96 character, each character has 38bytes( char_length(2), char_bitwidth(2), 
								  //                                                    char_asciivalue(2), font_char_data(32))
	
	
	initial
	$readmemh("../input_file/font_14verdana.hex",font_rom);
	
	
	assign decode_done = (char_count > 95) ? 1'b1 : 1'b0;
	
	always@(posedge clk)begin
		if(rst)begin
			font_rom_addr <= 16'd0;
			font_rom_dataen <= 1'b0;
		end
		else if(font_rom_addr < 6400)begin			
			font_rom_dataen <= 1'b1;
			font_rom_addr <= font_rom_addr + 1;
		end
		else
			font_rom_dataen <= 1'b0;
	end
	
	assign font_rom_data = font_rom[font_rom_addr];
	
	
	always@(posedge clk)begin
		if(rst)begin
			fontchar_rom_addr <= 0;	
			k <= 1;
		end
		else if(fontchar_rom_dataen)begin
						
			if(~ascii_dataen)begin
				fontchar_rom_addr <= fontchar_rom_addr + 1;
								
			end
			else if(fontchar_length == 32)begin
				fontchar_rom_addr <= fontchar_rom_addr + 3;
				
			end
			else if(fontchar_length == 48)begin 
				if(k < 2)begin
					fontchar_rom_addr <= fontchar_rom_addr + 1 ;
					k <= k + 1;
				end
				else begin
					fontchar_rom_addr <= fontchar_rom_addr + 2 ;
					k <= 1;
				end
			end
			else if(fontchar_length == 80)begin 
				fontchar_rom_addr <= fontchar_rom_addr + 1;
			end
		end
		
	end
	
	integer font_decode_file;
	reg [20:0]write_addr;
	initial
	font_decode_file = $fopen("../output_file/font_14verdana_decode.hex");
	
	//write into font_times14_decode.hex change the addr as write_addr, display the char choose addr as addr_map
	fontchar_rom font_decode_rom (
												  .clka(clk), // input clka
												  .wea(fontchar_rom_dataen), // input [0 : 0] wea
												  .addra(fontchar_rom_addr), // input [13 : 0] addra
												  .dina(fontchar_rom_data), // input [7 : 0] dina
												  .clkb(clk), // input clkb
												  .addrb(addr_map), //   write_addr  
												  .doutb(rom_data) // output [7 : 0] doutb
												);
	
	
	always@(posedge clk)begin
		if(rst) begin 
	     write_addr <= 0;
		end 	
		else if(write_addr == (75*96)) begin 
			$fclose(font_decode_file);
		end 
		else if(decode_done)begin
			write_addr <= write_addr + 1 ;
			$fwrite(font_decode_file,"%h\n",rom_data);
		end
	end
	
	always@(posedge clk)begin
		if(rst)begin
			step <= file_header;
			font_char_data <= 8'd0;
			font_char_addr <= 16'd0;
			font_char_dataen <= 1'b0;
			font_rom_databuf <= 32'd0;
			char_header_count <= 10'd0;
			char_asciivalue <= 8'd0;
			char_bitwidth <= 16'd0;
			char_height <= 16'd0;
			char_length <= 16'd0;
			fontchar_length <= 16'd0;
			next_char_addr <= 16'd0;
			fontchar_rom_data <= 8'd0;
			ascii_dataen <= 1'b0;
			fontchar_rom_dataen <= 1'b0;
			char_count <= 8'd0;
		end
		else begin
			case (step)
				file_header:	begin 
									if(font_rom_data == 8'h96)begin
										step <= char_header;
										char_header_count <= 0;
									end
									else begin
										char_header_count <= char_header_count + 1;
										step <= file_header;
									end
								end
				char_header:	begin
									if(font_rom_databuf == 32'h55aa0001)begin										
										if(char_header_count < 6)begin
											char_length <= {char_length[7:0],font_rom_data};
											char_header_count <= char_header_count  + 1;
											step <= char_header;
											
											fontchar_rom_data <= font_rom_data;										
											fontchar_rom_dataen <= 1'b1;
										end
										else if(char_header_count < 8)begin
											char_bitwidth <= {char_bitwidth[7:0],font_rom_data};
											char_header_count <= char_header_count  + 1;
											step <= char_header;
											
											fontchar_rom_data <= font_rom_data;										
											fontchar_rom_dataen <= 1'b1;
										end
										else if(char_header_count < 10)begin
											char_height <= {char_height[7:0],font_rom_data};
											char_header_count <= char_header_count  + 1;
											step <= char_header;
											
											fontchar_rom_dataen <= 1'b0;
										end
										else if(char_header_count < 12)begin
											char_asciivalue <= {char_asciivalue[7:0],font_rom_data};
											char_header_count <= char_header_count  + 1;
											step <= char_header;
											
											fontchar_rom_data <= font_rom_data;											
											fontchar_rom_dataen <= 1'b1;
										end
										else if(char_header_count < 14)begin
											next_char_addr <= {next_char_addr[7:0],font_rom_data};
											char_header_count <= char_header_count  + 1;
											step <= char_header;
											
											fontchar_rom_dataen <= 1'b0;
										end
										else if(char_header_count == 15)begin
											step <= char_font_data;
											char_header_count <= 0;
											font_rom_databuf <= 0;
											fontchar_length <= (char_length == 16'h23)? 16'd32:((char_length == 16'h46)?16'd48:16'd80); 
											char_length     <= (char_length == 16'h23)? 16'd23:((char_length == 16'h46)?16'd46:16'd69); 		
											//char_height <= (char_height >= 8'h20) ? (char_height-12):
														//	((char_height > 9)? (char_height-6):char_height);
											
											//ascii_dataen <= 1'b0;
											//fontchar_rom_dataen <= 1'b0;
										end
										else begin
											char_header_count <= char_header_count  + 1;
											step <= char_header;
											
											fontchar_rom_dataen <= 1'b0;
										end
									end
									else begin
										font_rom_databuf <= {font_rom_databuf[23:0],font_rom_data};
										step <= char_header;
										char_header_count <= char_header_count + 1;
										fontchar_rom_dataen <= 1'b0;
										ascii_dataen <= 1'b0;
									end
								end
			  char_font_data:	begin
									if(char_length%16 == 0)begin
										if(char_header_count < fontchar_length-1)begin
											char_header_count <= char_header_count + 1;
											step <= char_font_data;
											ascii_dataen <= 1'b1;
											fontchar_rom_data <= font_rom_data;										
											fontchar_rom_dataen <= 1'b1;										
										end
										else begin
											char_header_count <= 0;
											step <= char_header;
											char_count <= char_count  +1;
											fontchar_rom_dataen <= 1'b1;
										end	
									end
									else if(char_header_count < fontchar_length-1)begin
										if(char_header_count < char_length)begin
											char_header_count <= char_header_count + 1;
											step <= char_font_data;
											ascii_dataen <= 1'b1;
											fontchar_rom_data <= font_rom_data;										
											fontchar_rom_dataen <= 1'b1;
										end
										else begin
											fontchar_rom_dataen <= 1'b0;
											char_header_count <= char_header_count + 1;
										end
									end
									else begin
										char_header_count <= 0;
										step <= char_header;
										char_count <= char_count  +1;
										fontchar_rom_dataen <= 1'b0;										
									end		
								end
								
				default: begin end
			endcase
		end
	end
		
	
 always @(posedge clk) begin
		if (x == 0) begin
			col    	<= 0;
			colCnt 	<= 0;		
		end
		else if(decode_done) begin//&& font_char_dataen
			if (colCnt < disp_bitwidth) // CHAR_WIDTH
				colCnt <= colCnt + 1'b1;
			else begin
				col    	<= col + 1'b1;
				colCnt 	<= 0 ;				
			end
		end
	end
	
	always @(posedge clk) begin
		if (y < 1) begin
			row    <= 0;
			rowCnt <= 0;			
		end
		else if(decode_done) begin//&& font_char_dataen
			if (x == 1) begin
				if (rowCnt < 23)
					rowCnt <= rowCnt + 1'b1;
				else begin
					row    <= row + 1'b1;
					rowCnt <= 0 ;
				end
			end
		end
	end 
	
	always @(posedge clk) begin
		if(rst)
			addr_char <= 32;
		else if(col == 2 && row == 1) begin 
			addr_char <= "F";
		end 
		 else if(col == 3 && row == 1) begin 
			addr_char <= "O";
		end
		else if(col == 4 && row == 1) begin 
			addr_char <= "N";
		end 
		else if(col == 5 && row == 1) begin 
			addr_char <= "T";
		end 
		else if(col == 6 && row == 1) begin 
			addr_char <= ":";
		end 
		 else if(col == 7 && row == 1) begin 
			addr_char <= "1";
		end 
		else if(col == 8 && row == 1) begin 
			addr_char <= "4";
		end 
		else if(col == 2 && row == 2) begin 
			addr_char <= "A";
		end 
		 else if(col == 3 && row == 2) begin 
			addr_char <= "B";
		end
		else if(col == 4 && row == 2) begin 
			addr_char <= "C";
		end 
		else if(col == 5 && row == 2) begin 
			addr_char <= "D";
		end 
		else if(col == 6 && row == 2) begin 
			addr_char <= "E";
		end 
		 else if(col == 7 && row == 2) begin 
			addr_char <= "F";
		end 
		else if(col == 8 && row == 2) begin 
			addr_char <= "G";
		end 
		else if(col == 9 && row == 2) begin 
			addr_char <= "H";
		end
		else if(col == 10 && row == 2) begin 
			addr_char <= "I";
		end 
		else if(col == 11 && row == 2) begin 
			addr_char <= "J";
		end
		else if(col == 12 && row == 2) begin 
			addr_char <= "K";
		end 
		else if(col == 13 && row == 2) begin 
			addr_char <= "L";
		end 
		else if(col == 14 && row == 2) begin 
			addr_char <= "M";
		end
		else if(col == 15 && row == 2) begin 
			addr_char <= "N";
		end 
		else if(col == 16 && row == 2) begin 
			addr_char <= "O";
		end
		else if(col == 17 && row == 2) begin 
			addr_char <= "P";
		end
		else if(col == 18 && row == 2) begin 
			addr_char <= "Q";
		end 
		else if(col == 19 && row == 2) begin 
			addr_char <= "R";
		end 
		else if(col == 20 && row == 2) begin 
			addr_char <= "S";
		end
		else if(col == 21 && row == 2) begin 
			addr_char <= "T";
		end 
		else if(col == 22 && row == 2) begin 
			addr_char <= "U";
		end 
		else if(col == 23 && row == 2) begin 
			addr_char <= "V";
		end 
		else if(col == 24 && row == 2) begin 
			addr_char <= "W";
		end
		else if(col == 25 && row == 2) begin 
			addr_char <= "X";
		end 
		else if(col == 26 && row == 2) begin 
			addr_char <= "Y";
		end
		else if(col == 27 && row == 2) begin 
			addr_char <= "Z";
		end		
		else if(col == 2 && row == 3) begin 
			addr_char <= "a";
		end 
		 else if(col == 3 && row == 3) begin 
			addr_char <= "b";
		end
		else if(col == 4 && row == 3) begin 
			addr_char <= "c";
		end 
		else if(col == 5 && row == 3) begin 
			addr_char <= "d";
		end 
		else if(col == 6 && row == 3) begin 
			addr_char <= "e";
		end 
		 else if(col == 7 && row == 3) begin 
			addr_char <= "f";
		end 
		else if(col == 8 && row == 3) begin 
			addr_char <= "g";
		end 
		else if(col == 9 && row == 3) begin 
			addr_char <= "h";
		end
		else if(col == 10 && row == 3) begin 
			addr_char <= "i";
		end 
		else if(col == 11 && row == 3) begin 
			addr_char <= "j";
		end
		else if(col == 12 && row == 3) begin 
			addr_char <= "k";
		end 
		else if(col == 13 && row == 3) begin 
			addr_char <= "l";
		end 
		else if(col == 14 && row == 3) begin 
			addr_char <= "m";
		end
		else if(col == 15 && row == 3) begin 
			addr_char <= "n";
		end 
		else if(col == 16 && row == 3) begin 
			addr_char <= "o";
		end
		else if(col == 17 && row == 3) begin 
			addr_char <= "p";
		end
		else if(col == 18 && row == 3) begin 
			addr_char <= "q";
		end 
		else if(col == 19 && row == 3) begin 
			addr_char <= "r";
		end 
		else if(col == 20 && row == 3) begin 
			addr_char <= "s";
		end
		else if(col == 21 && row == 3) begin 
			addr_char <= "t";
		end 
		else if(col == 22 && row == 3) begin 
			addr_char <= "u";
		end 
		else if(col == 23 && row == 3) begin 
			addr_char <= "v";
		end 
		else if(col == 24 && row == 3) begin 
			addr_char <= "w";
		end
		else if(col == 25 && row == 3) begin 
			addr_char <= "x";
		end 
		else if(col == 26 && row == 3) begin 
			addr_char <= "y";
		end
		else if(col == 27 && row == 3) begin 
			addr_char <= "z";
		end		
		else begin  
			addr_char <= 32;
		end 
	end

	 
	always @(posedge clk) begin
	if(rst)begin
		disp_bitwidth <= 8'd4;
		addr_map <= 0;
		disp_bitwidth_L <= 8'd4;
		rom_data_13 <= 0;
		rom_data_12 <= 0;
		rom_data_11 <= 0;
		rom_data_3 <= 0;
		rom_data_2 <= 0;
		rom_data_1 <= 0;
		addr_char_1 <= 0;
		addr_char_2 <= 0;
		addr_char_3 <= 0;
		pixel <= 0; 
	end
	else if(decode_done)begin
		if (rowCnt < 23) begin
			case (colCnt)
				0:begin 
						pixel <= 0; 
						addr_map <= ((addr_char - 32)*75)+3;// char_width location 
						addr_char_1 <= ((addr_char - 32)*75) + 6 ; //char_font_data 1st 8bit
						addr_char_2 <= ((addr_char - 32)*75) + 7 ; //char_font_data 2nd 8bit
						addr_char_3 <= ((addr_char - 32)*75) + 8 ; //char_font_data 3rd 8bit
						disp_bitwidth <= disp_bitwidth_L;
						rom_data_13 <= rom_data_3;
						rom_data_12 <= rom_data_2;
						rom_data_11 <= rom_data_1;						
					end
				1: begin 
						addr_map  <= (addr_char_1)+(rowCnt[4:0]*3);
						pixel <= rom_data_11[7];
				   end
				2: begin	
						 addr_map  <= (addr_char_2)+(rowCnt[4:0]*3) ;
						 pixel <= rom_data_11[6];
						 disp_bitwidth_L <= (rom_data >= 8'h20) ? (rom_data-12):
											((rom_data > 9)? (rom_data-6):rom_data);//ascii to integer conversion, % modulo operator give the remainder value
				   end
				3: begin 
						addr_map  <= (addr_char_3)+(rowCnt[4:0]*3) ;
						 pixel <= rom_data_11[5];
						 rom_data_1 <= rom_data;
				   end
				4: begin		
						pixel <= rom_data_11[4];
						rom_data_2 <= rom_data;
				  end
				
				5:  begin 
						pixel <= rom_data_11[3];
						rom_data_3 <= rom_data;
					end
				6:  pixel <= rom_data_11[2];
				7:  pixel <= rom_data_11[1];
				8:  pixel <= rom_data_11[0];
				
				9:  pixel <= rom_data_12[7];
				10:  pixel <= rom_data_12[6];
				11:  pixel <= rom_data_12[5];
				12:  pixel <= rom_data_12[4];
				13:  pixel <= rom_data_12[3];
				14:  pixel <= rom_data_12[2];
				15:  pixel <= rom_data_12[1];
				16:  pixel <= rom_data_12[0];
				
				17:  pixel <= rom_data_13[7];
				18:  pixel <= rom_data_13[6];
				19:  pixel <= rom_data_13[5];
				20:  pixel <= rom_data_13[4];
				21:  pixel <= rom_data_13[3];
				22:  pixel <= rom_data_13[2];
				23:  pixel <= rom_data_13[1];
				24:  pixel <= rom_data_13[0];
				default: pixel <= 0;
			endcase
		end
		else begin
			pixel <= 0;
		end
	end
 end
 
//	always@(posedge clk)begin
//		if(rst)
//			rom_data <= 0;
//		else if(decode_done)
//			rom_data <= fontchar_rom[addr_map];
//	end
	 
	assign txt = (pixel == 1) ? 1'b1 : 1'b0;	
	
endmodule
