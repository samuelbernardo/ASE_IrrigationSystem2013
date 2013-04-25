#include "SharedData.h"

#define	BUFFER_SIZE	10

module IrrigationSystemC @safe()
{
	provides interface IrrigationSystem; 

	uses interface Boot;
	uses interface HumiditySensor;
	uses interface WaterValveActuator;
	uses interface RadioModule;
}
implementation
{

	uint8_t wmax;	//valor max. de humidade
	uint8_t wmin;	//valor mmin. de humidade

	uint8_t measuresBuffer[BUFFER_SIZE];
	uint16_t measuresTSBuffer[BUFFER_SIZE];
	uint16_t bufferIndex;

	uint8_t lastMeeasure;		//DEBUG vars
	uint16_t lastMeeasureTS;	//DEBUG vars

	void initBuffers(){
		int i;
		lastMeeasure = 0;
		lastMeeasureTS = 0;
		bufferIndex = 0;
		for(i = 0; i < BUFFER_SIZE; i++){
			measuresBuffer[i]=0;
			measuresTSBuffer[i]=0;
		}
	}

	command void IrrigationSystem.setTmeasure(uint32_t tm){
		//dbg("out", "IrrigationSystem says: vou actualizar o TM no HumiditySensor = %d\n",tm);	//DEBUG
		call HumiditySensor.setTmeasure(tm);
	}

	command void IrrigationSystem.setWmax(uint8_t max){
		if(wmax != max){
			wmax = max;
			dbg("out", "IrrigationSystem: Wmax updated = %d \n",wmax);	//DEBUG
		}
	}

	command void IrrigationSystem.setWmin(uint8_t min){
		if(wmin != min){
			wmin = min;
			dbg("out", "IrrigationSystem: Wmin updated = %d \n",wmin);	//DEBUG
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
		wmin = 20;	//Default Values
		wmax = 80;	//Default Values
		initBuffers();
		//readParametersFromFIle(); estes params nao vem por file, mas por radio
		dbg("out", "IrrigationSystem has Booted\n");
	}

	/* Handler do evento gerado pelo HumiditySensor */ 
	event void HumiditySensor.newMeasure(uint8_t newMeasure, uint16_t measureTimestamp){
		
		// FixMe: Atencao, temde se corrigir a situcao em que bufferIndex > BUFFER_SIZE
		// solucao tem de passar por esquema tipo round-robin
		/* FIXE THIS CODE!
		measuresBuffer[bufferIndex] = newMeasure;
		measuresTSBuffer[bufferIndex] = measureTimestamp;
		bufferIndex++;
		*/

		lastMeeasure = newMeasure;
		lastMeeasureTS = measureTimestamp;

		if(newMeasure > wmax){
			call WaterValveActuator.closeValve();
		}	
		if(newMeasure < wmin){
		 	call WaterValveActuator.openValve();
		}

		// *******************************************************
		// MOTE NAO ESTA A ENVIAR MEDICOES PORQUE ESTOU A TESTAR o "SET PARAMETERS"
		// call RadioModule.sendMeasure(newMeasure, measureTimestamp);
		//*********************************************************

		//DEBUG print
		//dbg("out", "Catch Measure: v=%i, ts=%i, b=%i\n", newMeasure, measureTimestamp, bufferIndex);
	}

}

