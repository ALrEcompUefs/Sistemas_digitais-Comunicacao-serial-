#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>		//Usado para UART
#include <fcntl.h>		//Usado para UART
#include <termios.h>	//Usado para UART

void uart_tx(char* tx_string, int uart_filestream); //Fun��o para envio de dados

int main(){
	int sensor=0;
	int comando=0;
	int resposta;
	unsigned char comandoResposta[9];
	unsigned char dadoInteiro[9];
	unsigned char dadoFracao[9];

	char situacao[]="0x03"; //codigo da situacao aual do sensor.
	char temperatura[]="0x04"; //codigo da medida de temperatura.
	char umidade[]="0x05";//codigo da medida de umidade.
	
    //char* str2 = "3.14159";
 	//int myint1 = atoi(str1);
 	
/* Converte de hexadecimal para inteiro
char hexstring[7]="04FA56";
long int numValue;
numValue = strtol (hexstring , NULL, 16);
printf("Decimal Valor: % ld " , numValue);*/
    
//-----------------------------------------------------------------------------------------------------------------------------------
	//Configura��o da UART
   
   //Abertura do arquivo da UART
	int uart_filestream = -1;
	uart_filestream = open("/dev/serial0", O_RDWR | O_NOCTTY | O_NDELAY);	//Abre em modo escrita/leitura bloqueado
	if (uart_filestream == -1){
		printf("\nErro: n�o � poss�vel abrir o arquivo da UART.\n");
	}
	//Struct para configura��o dos par�metros de comunica��o
	struct termios options;
	tcgetattr(uart_filestream, &options);
	options.c_cflag = B9600 | CS8 | CLOCAL | CREAD| PARENB | PARODD; //Seta Baud-Rate para 9600, tamanho de 8 bits, habilita paridade e define paridade �mpar
	options.c_iflag = IGNPAR; //Ignora caracteres com erros de paridade
	options.c_oflag = 0;
	options.c_lflag = 0;
	tcflush(uart_filestream, TCIFLUSH); //Libera entrada pendente. Esvazia a sa�da n�o transmitida.
	tcsetattr(uart_filestream, TCSANOW, &options);
	
//----------------------------------------------------------------------------------------------------------------------------------
//Solicitacao de dados para criar a requisicao
  
	//Solicita ao usu�rio o sensor que deseja obter informa��es
	printf("\nSelecione o sensor que deseja receber informacoes");
	printf("\n1 - DHT11\n");
	scanf("%i", &sensor);
	while(sensor!=1){ //Solicita novamente at� que a op��o seja v�lida.
		printf("\nOpcao de sensor invalida. Selecione o sensor corretamente");
		printf("\n1 - DHT11\n");
		scanf("%i", &sensor);
	}
	
	//Solicita ao usu�rio o tipo de informa��o que deseja receber do sensor
	printf("\nSelecione o tipo de informacao que deseja receber");
	printf("\n1-Situacao atual do sensor.\n2-Medida de temperatura.\n3-Medida de umidade.\n");
	scanf("%i", &comando);
	while(comando<1 || comando>3){ //Solicita novamente at� que a op��o seja v�lida.
		printf("\nInformacao invalida, selecione uma disponivel:");
		printf("\n1-Situacao atual do sensor.\n2-Medida de temperatura.\n3-Medida de umidade.\n");
		scanf("%i", &comando);
	}
//----------------------------------------------------------------------------------------------------------------------------------	
//ENVIO DO C�DIGO DA REQUISI��O
	switch (comando){
	    case 1:
	    	//Envia o c�digo da requisi��o de situa��o do sensor
	    	uart_tx(situacao,uart_filestream);
	  	break;
	  	case 2:
	  		//Envia o c�digo da requisi��o de medida de temperatura
	  		uart_tx(temperatura,uart_filestream);
	  	break;
	  	case 3:
	  		//Envia o c�digo da requisi��o de medida de umidade
	  		uart_tx(umidade,uart_filestream);	
	  	break;
	    default:
		    printf("\n\nInformacao invalida, selecione uma disponivel:");
			printf("\n1-Situacao atual do sensor.\n2-Medida de temperatura.\n3-Medida de umidade.\n");
			scanf("%i", &comando);
	}
//----------------------------------------------------------------------------------------------------------------------------------		
//ENVIO DO ENDERE�O DA REQUISI��O
	switch (sensor){
	    case 1:
	    	//Envia o c�digo de endereco do DHT11
	   		uart_tx("0x01",uart_filestream); 
	  	break;
	    default:
		    printf("\n\n Opcao de sensor invalida. Selecione o sensor corretamente");
			printf("\n1 - DHT11\n");
			scanf("%i", &sensor);
	}
	
	sleep(3);
//----------------------------------------------------------------------------------------------------------------------------------
//Leitura do byte de c�digo de resposta	
	int rx_length;
	if (uart_filestream != -1){
		//unsigned char rx_buffer[9];
		rx_length = read(uart_filestream, (void*)comandoResposta, 8); //Filestream, buffer para armazenar, n�mero maximo de bytes lidos
		if (rx_length < 0){
			printf("Ocorreu um erro na leitura de dados");
		}
		else if (rx_length == 0){
			printf("Nenhum dado lido");
		}
		else{
			//Byte recebido
			comandoResposta[rx_length] = '\0';
			printf("\n%i bytes read : %s\n", rx_length, comandoResposta);
			if(strcmp(comandoResposta, "0x1F")==0){
		     	printf("\nO sensor esta com problema");
		  	}
		  	else if(strcmp(comandoResposta, "0x00")==0){
		  		printf("\nO sensor esta funcionando corretamente");
			}
		  	else if(strcmp(comandoResposta, "0x01")==0){
		  		printf("\nMedida de umidade");
		  	}
		 	else if(strcmp(comandoResposta, "0x02")==0){
		 		printf("\nMedida de temperatura");
		 	}
		}
	}
	else{
		printf("\nFalha na abertura do arquivo");
	}
	sleep(1);
	
	//leitura do byte de dado 1
	if (uart_filestream != -1){
		//unsigned char rx_buffer[9];
		rx_length = read(uart_filestream, (void*)dadoInteiro, 8); //Filestream, buffer para armazenar, n�mero maximo de bytes lidos
		if (rx_length < 0){
			printf("Ocorreu um erro na leitura de dados");
		}
		else if (rx_length == 0){
			printf("Nenhum dado lido");
		}
		else{
			//Byte recebido
			dadoInteiro[rx_length] = '\0';
			printf("\n%i bytes read : %s\n", rx_length, dadoInteiro);
		}
	}
	else{
		printf("\nFalha na abertura do arquivo");
	}
	sleep(1);
	
	//leitura do byte de dado 2
	if (uart_filestream != -1){
		//unsigned char rx_buffer[9];
		rx_length = read(uart_filestream, (void*)dadoFracao, 8); //Filestream, buffer para armazenar, n�mero maximo de bytes lidos
		if (rx_length < 0){
			printf("Ocorreu um erro na leitura de dados");
		}
		else if (rx_length == 0){
			printf("Nenhum dado lido");
		}
		else{
			//Byte recebido
			dadoFracao[rx_length] = '\0';
			printf("\n%i bytes read : %s\n", rx_length,dadoFracao);
		}
	}
	else{
		printf("\nFalha na abertura do arquivo");
	}
	
	close(uart_filestream);
	return 0;
}
//----------------------------------------------------------------------------------------------------------------------------------
//Fun��o que envia os dados na UART
void uart_tx(char* tx_string, int uart_filestream){
	if (uart_filestream != -1){
		write(uart_filestream, tx_string, strlen(tx_string));		//Filestream,mensagem enviada,tamanho da mensagem
	}	
	else{
		printf("\nFalha na abertura do arquivo");
	}
}




