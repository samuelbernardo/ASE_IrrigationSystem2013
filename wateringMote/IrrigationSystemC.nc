#include "SharedData.h"

#define	BUFFER_SIZE	1000

module IrrigationSystemC @safe()
{
	provides interface IrrigationSystem; 

	uses interface Boot;
	uses interface HumiditySensor;
}
implementation
{

	uint8_t wmax;	//valor max. de humidade
	uint8_t wmin;	//valor mmin. de humidade

	uint8_t measuresBuffer[BUFFER_SIZE];
	uint16_t measuresTSBuffer[BUFFER_SIZE];
	uint16_t bufferIndex;


	/* 	Le os parameteros 'wmax', 'wmnin',  do ficheiro de configuracao
	 *	configParametersFile.txt, faz set nas variaveis wmax e wmin, 
	 *	respectivamente
	 */
	void readParametersFromFIle(){
		//TODO
	} 

	void initBuffers(){
		int i;
		for(i = 0; i < BUFFER_SIZE; i++){
			measuresBuffer[i]=0;
			measuresTSBuffer[i]=0;
		}
	}

	command bool IrrigationSystem.getMeasures(RadioMeasuresPacket *pkt){
		//TODO
		/*Preencher a packet com as leituras, existentes nos buffers
		 * as leituras que forem colocadas nesta packet, têm de ser apagadas
		 * do mesuresBuffer = decrementar bufferIndexe
		 *
		 *	retorna TRUE se todas as measures vão na packet => bufferIndex = 0
		 *	retorna FALSE se houve measures "recentes" que nao couberam na packet => bufferIndex > 0 
		 * 			neste caso, o Radio Module tem de voltar a chamar o getMeasures 
		 *			para que se coloquem as medicoes que nao couberam na packet anterior
		 */

		return TRUE;
	}

	event void Boot.booted(){
		bufferIndex = 0;
		initBuffers();
		readParametersFromFIle();
		dbg("out", "IrrigationSystem has Booted\n");
	}

	/* Handler do evento gerado pelo HumiditySensor */ 
	event void HumiditySensor.newMeasure(uint8_t newMeasure, uint16_t measureTimestamp){
		
		// FixMe: Atencao, temde se corrigir a situcao em que bufferIndex > BUFFER_SIZE
		// solucao tem de passar por esquema tipo round-robin
		measuresBuffer[bufferIndex] = newMeasure;
		measuresTSBuffer[bufferIndex] = measureTimestamp;
		bufferIndex++;

		readParametersFromFIle();
		
		dbg("out", "Catch Measure: v=%i, ts=%i, b=%i\n", newMeasure, measureTimestamp, bufferIndex); //DEBUG
	}

}

