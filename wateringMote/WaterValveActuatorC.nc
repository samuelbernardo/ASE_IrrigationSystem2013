#include "Timer.h"
//#include "Atm128Adc.h"


module WaterValveActuatorC @safe()
{	
	provides interface WaterValveActuator;

	uses interface Boot;
}
implementation
{
	
	bool isOpen; // Valve State
	bool fileDontStarted;
	bool valveIsBroken;

	event void Boot.booted(){
		isOpen = FALSE; //Default Value
		fileDontStarted = TRUE;
		valveIsBroken = FALSE;
		dbg("out", "WaterValveActuator has Booted\n");
	}

	command bool WaterValveActuator.isOpen(){
		return isOpen;
	}

	void upadteValveState(char *pathFileToWrite, int moteID, int state){

		FILE *file = fopen(pathFileToWrite,"a");
		if (file == NULL){
			printf("[ERRO] Problemas ao abrir o ficheiro %s \n", pathFileToWrite);
			exit(0);
		}

		if(state == 0){
			fprintf(file, "Mote-%d[Valve]=Close\n",moteID);
		}
		else{
			fprintf(file, "Mote-%d[Valve]=Open\n",moteID);
		}

		fclose(file);

	}	


	command void WaterValveActuator.openValve(){
		if(!isOpen || fileDontStarted){
			// 3param = 1 -> open valve
			upadteValveState("configFiles/statesOfValves.txt", TOS_NODE_ID, 1);
			
			if(!valveIsBroken){
				isOpen = TRUE;
			}
			fileDontStarted = FALSE;
			
			if(!isOpen){
				dbg("out", "Water Valve is Broken! Don't Open!");
			}
		}
	}

	command void WaterValveActuator.closeValve(){
		if(isOpen || fileDontStarted){
			// 3param = 0 -> close valve
			upadteValveState("configFiles/statesOfValves.txt", TOS_NODE_ID, 0);
			
			if(!valveIsBroken){
				isOpen = FALSE;
			}
			fileDontStarted = FALSE;
			
			if(isOpen){
				dbg("out", "Water Valve is Broken! Don't Close!");				
			}
		}
	}

}

