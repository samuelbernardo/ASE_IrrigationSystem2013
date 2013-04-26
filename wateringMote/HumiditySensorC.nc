#include "Timer.h"
//#include "Atm128Adc.h"


module HumiditySensorC @safe()
{
	provides interface HumiditySensor;
  
	uses interface MyADC;
	uses interface Timer<TMilli> as Timer;
	uses interface Boot;
}
implementation
{
	
	uint16_t tMeasure;		// deltaTime for Timer
	uint16_t newMeasure;	// humidityValueRead to send
	uint16_t timeStamp;
	bool humiditySensorBroken;

	
	command void HumiditySensor.setTmeasure(uint16_t tm){		
		
		//evita que mote ao receber mensagens repetidas de set parameter
		// esteja a fazer setParameter repetidos!
		if(tm != tMeasure){
			tMeasure = tm;
			call Timer.startPeriodic(tMeasure);
			// NAO APAGAR ESTA MENSAGEM DE DEBUG, É BASTANTE IMPORTANTE para a demonstracao
			dbg("out", "HumiditySensor: tMeasure updated = %d\n",tMeasure); //DEBUG	
		}
	}

	command uint16_t HumiditySensor.getTimer(){
		return tMeasure;
	}

	event void Boot.booted(){
		tMeasure = 1000; 	//Valor Default (TODO: rever este valor que é maior que o que a variável consegue armazenar - aparece warning de overflow) 	
		newMeasure = 17;
		timeStamp = 1;
		humiditySensorBroken = FALSE;
		call Timer.startPeriodic(tMeasure);
		dbg("out", "HumiditySensor has Booted\n");
	}

	event void Timer.fired(){
		call MyADC.getData();
		
		//DEBUG print 
		//dbg("out", "fired event\n");
	}
	
	event void MyADC.dataReady(uint8_t receivedMeasure){
		
		//NOTA: este IF não tem nada a haver com a logica do projecto.
		// apenas serve para corrigir um aparente BUGZILLA do TOSSIM
		
		if(!humiditySensorBroken){
			signal HumiditySensor.newMeasure(receivedMeasure, timeStamp);
			timeStamp++;
		}
		else{
			//receivedMeasure = 0 porque humiditySensor esta' danificado
			signal HumiditySensor.newMeasure(0, timeStamp);
			timeStamp++;
		}
	}

	default event void HumiditySensor.newMeasure(uint8_t newMeasureValue, uint16_t measureTimestamp){
		//Nao adianta emeter aqui codigo porque ele nao e' executado
		// apenas declara o evento emitido por este modulo
	}
}

