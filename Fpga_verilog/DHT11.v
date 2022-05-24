module DHT11 (
		input CLK, // clock
		input EN, // enable
		input RST, // reset
	inout DHT_DATA, // pino serial de data
	output [7:0] HUM_INT, // local onde fica salvo a parte Inteira de Umidade
	output [7:0] HUM_FLOAT, // local onde fica salvo a parte Decimal de Umidade
	output [7:0] TEMP_INT, // local onde fica salvo a parte Inteira de Temperatura
	output [7:0] TEMP_FLOAT, // local onde fica salvo a parte Decimal de Temperatura
	output [7:0] CRC, // Codigo do checksum
	output WAIT, // indica estado de espera
	output DEBUG, // para fins de debug
	output error, // indica erro
	output r,g,b // para cores do LED RGB
);



reg DHT_OUT, DIR, WAIT_REG, DEBUG_REG; // Registradores de saida
// DHT_OUT = O dado que, se lido corretamente, será enviado pelo leitor do sensor
// DIR = direcao do tri-state
// WAIT_REG = indica que esta em estado de espera
// DEBUG_REG = para fins de debug
reg [25:0] COUNTER; // Contador de ciclos para gerar delays
reg [5:0] index;
reg [39:0] INTDATA; // registrador de dados interno
reg error_REG;
wire DHT_IN; 

assign WAIT = WAIT_REG;
assign DEBUG = DEBUG_REG;
assign error = error_REG;

// tri-state
TRIS TRIS_DATA (
	.PORT(DHT_DATA),
	.DIR(DIR),
	.SEND(DHT_OUT),
	.READ(DHT_IN)
);
// Para o led-rgb
LED_RGB RGB(
	.WAIT(WAIT),
	.error(error),
	.reset(RST),
	.r(r),
	.g(g),
	.b(b)
);

assign HUM_INT[7] = INTDATA[0];
assign HUM_INT[6] = INTDATA[1];
assign HUM_INT[5] = INTDATA[2];
assign HUM_INT[4] = INTDATA[3];
assign HUM_INT[3] = INTDATA[4];
assign HUM_INT[2] = INTDATA[5];
assign HUM_INT[1] = INTDATA[6];
assign HUM_INT[0] = INTDATA[7];

assign HUM_FLOAT[7] = INTDATA[8];
assign HUM_FLOAT[6] = INTDATA[9];
assign HUM_FLOAT[5] = INTDATA[10];
assign HUM_FLOAT[4] = INTDATA[11];
assign HUM_FLOAT[3] = INTDATA[12];
assign HUM_FLOAT[2] = INTDATA[13];
assign HUM_FLOAT[1] = INTDATA[14];
assign HUM_FLOAT[0] = INTDATA[15];

assign TEMP_INT[7] = INTDATA[16];
assign TEMP_INT[6] = INTDATA[17];
assign TEMP_INT[5] = INTDATA[18];
assign TEMP_INT[4] = INTDATA[19];
assign TEMP_INT[3] = INTDATA[20];
assign TEMP_INT[2] = INTDATA[21];
assign TEMP_INT[1] = INTDATA[22];
assign TEMP_INT[0] = INTDATA[23];

assign TEMP_FLOAT[7] = INTDATA[24];
assign TEMP_FLOAT[6] = INTDATA[25];
assign TEMP_FLOAT[5] = INTDATA[26];
assign TEMP_FLOAT[4] = INTDATA[27];
assign TEMP_FLOAT[3] = INTDATA[28];
assign TEMP_FLOAT[2] = INTDATA[29];
assign TEMP_FLOAT[1] = INTDATA[30];
assign TEMP_FLOAT[0] = INTDATA[31];

assign CRC[7] = INTDATA[32];
assign CRC[6] = INTDATA[33];
assign CRC[5] = INTDATA[34];
assign CRC[4] = INTDATA[35];
assign CRC[3] = INTDATA[36];
assign CRC[2] = INTDATA[37];
assign CRC[1] = INTDATA[38];
assign CRC[0] = INTDATA[39];

reg [3:0] STATE;

//Definicao de estados
parameter S0=1, S1=2, S2=3, S3=4, S4=5, S5=6, S6=7, S7=8, S8=9, S9=10, STOP=0, START=11;

//Processo de FSM
always @(posedge CLK)
begin: FSM
	if(EN == 1'b1) begin // a maquina de estados so funcionara caso o enable esteja ativo
		if(RST == 1'b1) begin // o reset limpa as saidas e retorna o sensor para o estado inicial
			DHT_OUT <= 1'b1;
			WAIT_REG <= 1'b0;
			COUNTER <= 26'b0;
			INTDATA <= 40'b0;
			DIR <= 1'b1;
			error_REG <= 1'b0;
			STATE <= START;
		end
		else begin
			case (STATE)
				START:
					begin
						WAIT_REG <= 1'b1;
						DIR <= 1'b1;
						DHT_OUT <= 1'b1;
						STATE <= S0;
					end
					
				S0:
					begin
						DIR <= 1'b1;
						DHT_OUT <= 1'b1;
						WAIT_REG <= 1'b1;
						error_REG <= 1'b0;
						if(COUNTER < 900000) begin
							COUNTER <= COUNTER + 1'b1;
						end else begin
							COUNTER <= 26'b0;
							STATE <= S1;
						end
					end
					
				S1:
					begin
						DHT_OUT <= 1'b0;
						WAIT_REG <= 1'b1;
						if (COUNTER < 900000) begin
							COUNTER <= COUNTER + 1'b1;
						end else begin
							COUNTER <= 26'b0;
							STATE <= S2;
						end
					end
					
				S2:
					begin
						DHT_OUT <= 1'b1;
						if (COUNTER < 1000) begin
							COUNTER = COUNTER + 1'b1;
						end else begin
							DIR <= 1'b0;
							STATE <= S3;
						end
					end
					
				S3:
					begin
						if(COUNTER < 3000 & DHT_IN == 1'b1) begin
							COUNTER <= COUNTER + 1'b1;
							STATE <= S3;
						end else begin
							if ( DHT_IN == 1'b1 ) begin
								error_REG <= 1'b1;
								COUNTER <= 26'b0;
								STATE <= STOP;
							end else begin
								COUNTER <= 26'b0;
								STATE <= S4;
							end
						end
					end
					
				S4:
					begin
						// DETECTA PULSO DE SINCRONISMO
						if( DHT_IN == 1'b0 & COUNTER < 4400) begin
							COUNTER <= COUNTER + 1'b1;
							STATE <= S4;
						end else begin
							if (DHT_IN == 1'b0) begin
								error_REG <= 1'b1;
								COUNTER <= 26'b0;
								STATE <= STOP;
							end else begin
								STATE <= S5;
								COUNTER <= 26'b0;
							end
						end
					end
					
				S5:
					begin
						// DETECTA PULSO DE SINCRONISMO
						if(DHT_IN == 1'b1 & COUNTER < 4400) begin
							COUNTER <= COUNTER + 1'b1;
							STATE <= S5;
						end else begin
							if(DHT_IN == 1'b1) begin
								error_REG <= 1'b1;
								COUNTER <= 26'b0;
								STATE <= STOP;
							end else begin
								STATE <= S6;
								error_REG <= 1'b0;
								index <= 6'b0; // reseta o contador
								COUNTER <= 26'b0;
							end
						end
					end
					
				S6:
					begin
						if(DHT_IN == 1'b0) begin
							STATE <= S7;
						end else begin
							error_REG <= 1'b1;
							COUNTER <= 26'b0;
							STATE <= STOP;
						end
					end
					
				S7:
					begin
						if(DHT_IN == 1'b1) begin
							COUNTER <= 26'b0;
							STATE <= S8;
						end else begin
							if(COUNTER < 1600000) begin
								COUNTER <= COUNTER + 1'b1;
								STATE <= S7;
							end else begin
								COUNTER <= 26'b0;
								error_REG <= 1'b1;
								STATE <= STOP;
							end
						end
					end
					
				S8:
					begin
						if(DHT_IN == 1'b0) begin
							if(COUNTER > 2500) begin
								INTDATA[index] <= 1'b1;
								DEBUG_REG <= 1'b1;
							end else begin
								INTDATA[index] <= 1'b0;
								DEBUG_REG <= 1'b0;
							end
							
							if(index < 39) begin
								COUNTER <= 26'b0;
								STATE <= S9;
							end else begin
								error_REG <= 1'b0;
								STATE <= STOP;
							end
						end else begin
							COUNTER <= COUNTER + 1'b1;
							
							if(COUNTER > 1600000) begin // 32 Ms -> Travou
								error_REG <= 1'b1;
								STATE <= STOP;
							end
						end
					end
					
				S9:
					begin
						index <= index + 1'b1;
						STATE <= S6;
					end
					
				STOP:
					begin
						STATE <= STOP;
						if( error_REG == 1'b0 ) begin
							DHT_OUT <= 1'b1;
							WAIT_REG <= 1'b0;
							COUNTER <= 26'b0;
							DIR <= 1'b1;
							error_REG <= 1'b0;
							index <= 6'b0;
						end else begin
							if(COUNTER < 16000000) begin
								INTDATA <= 40'b0;
								COUNTER <= COUNTER + 1'b1;
								error_REG <= 1'b1;
								WAIT_REG <= 1'b1;
								DIR <= 1'b0;
							end else begin
								error_REG <= 1'b0;
							end
						end
					end
				endcase
		end
	end
end

endmodule	

	
	
	
	
	
	
	
	
	
	
	