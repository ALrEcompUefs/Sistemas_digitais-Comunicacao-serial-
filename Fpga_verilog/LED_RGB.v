module LED_RGB (
input WAIT,
input error,
input reset,

output reg r,g,b
);



initial begin

r = 1'b0;
g = 1'b0;
b = 1'b0;

end

always @(*) begin


		r = 1'b0;
		g = 1'b0;
		b = 1'b0;
		
	if(error == 1) begin 
		r = 1'b1;
		
	end else if(WAIT == 1) begin
		g = 1'b1;
	end else if(reset == 1) begin
		b = 1'b1;
	end else begin
		r = 1'b0;
		g = 1'b0;
		b = 1'b0;
	end

end

endmodule