#include "Timer.h"

module MyADC_C @safe()
{
	provides interface MyADC;

	uses interface Boot;
}
implementation
{
	
	uint8_t measureReaded;

	/* 	Le os parameteros 'SoilHumidityMeasure' e 'Tmeasure' do ficheiro de configuracao
	 *	configParametersFile.txt, faz set nas variaveis tMeasure e newMeasure, 
	 *	respectivamente
	 */
	uint8_t readMeasureFromFIle(uint16_t moteID, char *pathFile){
		char *line = NULL;
		size_t lineSize = 0;
		int moteIDAux = 0;
		int humidityValue = 0;
		char buffer[10];
		int indexBuffer = 0;

		int valueFlag = 0;
		int idFlag = 0;

		FILE *file = fopen(pathFile,"r");

		if (file == NULL){
			printf("[ERRO] Problemas ao abrir o ficheiro %s \n", pathFile);
			exit(0);
		}

	   	while ((getline(&line, &lineSize, file)) != -1) {
	    	int i;
	    	for(i=0; i<lineSize; i++){
	    		if(line[i] == '-'){
					idFlag = 1;
					continue;
				}
				if(idFlag == 1 && isdigit(line[i])){
					buffer[indexBuffer] = line[i];
					indexBuffer++;
					continue;
				}
				if(idFlag == 1 && !isdigit(line[i])){
					idFlag = 0;
					buffer[indexBuffer] = '\0';
					indexBuffer = 0;
					moteIDAux = atoi(buffer);
				}
	    		if(line[i] == '='){
					valueFlag = 1;
					continue;
				}

				if(valueFlag == 1 && isdigit(line[i])){
					buffer[indexBuffer] = line[i];
					indexBuffer++;
					continue;	
				}
				if(valueFlag == 1 && !isdigit(line[i])){
					valueFlag = 0;
					buffer[indexBuffer] = '\0';
					indexBuffer = 0;
					humidityValue = atoi(buffer);
					break;
				}
	    	}
	    
	    	if(moteIDAux == moteID){
				fclose(file);
	    		return humidityValue;
	    	}
	    }
		fclose(file);
	    return 0;
	} 

	event void Boot.booted(){
		measureReaded = 0;		//Default value
		dbg("out", "ADC from HumiditySensor has Booted\n");
	}


	command void MyADC.getData(){
		uint8_t measure = readMeasureFromFIle(TOS_NODE_ID, "configFiles/leituras.txt");
		signal MyADC.dataReady(measure);
	}

	default event void MyADC.dataReady(uint8_t newMeasureValue){
		//Nao adianta meter aqui codigo porque ele nao e' executado
		// apenas declara o evento emitido por este modulo
	}
}

