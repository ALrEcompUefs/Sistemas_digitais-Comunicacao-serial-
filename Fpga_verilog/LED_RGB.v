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
		
	if(error == 1) begin  // se error for 1, liga o led correspondente
		r = 1'b1;
		
	end else if(WAIT == 1) begin // ou se WAIT for 1, liga o led correspondente
		g = 1'b1;
	end else if(reset == 1) begin // ou se reset for 1, liga o led correspondente
		b = 1'b1;
	end else begin // limpa as saidas
		r = 1'b0;
		g = 1'b0;
		b = 1'b0;
	end

end

endmodule