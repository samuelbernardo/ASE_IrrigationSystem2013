#include "Timer.h"
//#include "Atm128Adc.h"


module HumiditySensorC @safe()
{
	provides interface HumiditySensor;
  
  	//uses interface Atm128AdcSingle;
	uses interface Timer<TMilli> as Timer;
	uses interface Boot;
}
implementation
{
	
	uint16_t tMeasure;		// deltaTime for Timer
	uint16_t newMeasure;	// humidityValueRead to send
	uint16_t timeStamp;

	/* 	Le os parameteros 'SoilHumidityMeasure' e 'Tmeasure' do ficheiro de configuracao
	 *	configParametersFile.txt, faz set nas variaveis tMeasure e newMeasure, 
	 *	respectivamente
	 */
	void readParametersFromFIle(){
		//TODO
	} 

	event void Boot.booted(){
		tMeasure = 100000;			
		newMeasure = 17;
		timeStamp = 0;
		call Timer.startPeriodic(tMeasure);
		readParametersFromFIle();
		dbg("out", "HumiditySensor has Booted\n");
	}

	event void Timer.fired(){
		//call Atm128AdcSingle.getData(10,10,FALSE,10);
		signal HumiditySensor.newMeasure(newMeasure, timeStamp);
		readParametersFromFIle();
		timeStamp++;
		dbg("out", "fired event\n"); //DEBUG
	}

/*
	async event void Atm128AdcSingle.dataReady(uint16_t valueReaded, bool precise){
		signal HumiditySensor.newMeasure(newMeasure, timeStamp);
	}
*/

	default event void HumiditySensor.newMeasure(uint8_t newMeasureValue, uint16_t measureTimestamp){
		//Nao adianta emeter aqui codigo porque ele nao e' executado
		// apenas declara o evento emitido por este modulo
	}

}

