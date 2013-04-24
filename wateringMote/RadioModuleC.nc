#include "Timer.h"
#include "SharedData.h"


module RadioModuleC @safe() {

  provides interface RadioModule;

  uses interface Boot;
  // Para enviar e processar packets
  uses interface Packet;    //aceder a message_t
  uses interface AMPacket;  //aceder a message_t
  uses interface AMSend;    
  uses interface SplitControl as AMControl;
 
  // Para receber packets
  uses interface Receive;

  //----------------------------
  uses interface IrrigationSystem;
  uses interface SyncProtocol;
  uses interface Timer<TMilli> as Timer;

}
implementation {

	uint32_t tServer; 
	message_t packet;
	bool channelIsBusy;
  
  event void Boot.booted() {
		tServer = 100000; 		//Default Value
		channelIsBusy = FALSE;
   
    call AMControl.start();
    
    dbg("out", "Mote %i fez Boot! \n", moteID);
		//dbg("out", "Radio Has Booted \n");
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      	call Timer.startPeriodic(tServer);
      	call SyncProtocol.sendControlMsg();
    }
    else {
      	call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
   event void Timer.fired() {
      // do nothing, for now...
   }


    //Samuel, estva a fazer esta funcao antes de te enviar o codigo
   	//esta funcao ainda nao esta completa e o que ela faz é difundiar umma mensagem com a ultima leitura do sensor,
    // depois de ter esta funcao testada e "estavel". o que ia fazer era enviar mensagens não com uma medida, 
    //  mas com muitas medidas (no máximo 7). Para aproveitar ao maximo o tamanho da packet. 
	command void RadioModule.sendMeasure(uint8_t measure, uint16_t measureTS){

		RadioMeasuresPacket *rmp;
		dbg("out", "Vou difundir mensagem com: m = %d, ts = %d \n", measure, measureTS);

		if(!channelIsBusy){
			rmp = (RadioMeasuresPacket*)(call Packet.getPayload(&packet, sizeof (RadioMeasuresPacket)));
			
			rmp->srcNodeId = TOS_NODE_ID;
			rmp->lastNodeId = TOS_NODE_ID;
			rmp->measures[0] = measure;
			rmp->measuresTS[0] = measureTS;
			rmp->measuresIndex = 1;
			rmp->packetTTL = 10;
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioMeasuresPacket)) == SUCCESS) {
          		channelIsBusy = TRUE;
        	}		
		}
	}


  	// Aux Function

 	void processSetParameterMsg(radio_count_msg_t* pkt){
		uint32_t paramValue = pkt->paramValue;
  		uint8_t operationCode = pkt->operationCode;
		//uint16_t moteID = pkt->moteID;			//Campo NAO necessario
		//uint16_t packetTTL = pkt->packetTTL;		//Campo NAO necessario
		//uint16_t lastNodeID = pkt->lastNodeID;	//Campo NAO necessario

		if(operationCode == 1){ //set tMeasure
	    	dbg("out", "Recebi setParametersMsg -> setTmeasure\n");
			call IrrigationSystem.setTmeasure(paramValue);
			return;
		}
		if(operationCode == 2){ //set tServer
	    	dbg("out", "Recebi setParametersMsg -> setTserver\n");
			tServer = paramValue;
      		call Timer.startPeriodic(tServer); //Restart timer com novo tServer
			//dbg("out", "RadioModule says: Actualizei tServer = %d \n",call Timer.getdt());	//DEBUG
			return;
		}
		if(operationCode == 3){ //set wmax
	    	dbg("out", "Recebi setParametersMsg -> setWmax\n");
			call IrrigationSystem.setWmax(paramValue);
			//TODO process request
			return;
		}
		if(operationCode == 4){ //set wmin
	    	dbg("out", "Recebi setParametersMsg -> setWmin\n");
	    	call IrrigationSystem.setWmin(paramValue);
			//TODO process request
			return;
		}

	    dbg("out", "[ERROR] Received a *setParametersMsg* but operationCode is INVALID\n");
	    //dbg("out", "|%d|%d|%d|%d|%d| \n",paramValue,operationCode,moteID,packetTTL,lastNodeID); //DEBUG
		return;
	}

	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
	    
		radio_count_msg_t* pkt;		
	 	
	 	if(len == sizeof(radio_count_msg_t)){
	    	//dbg("out", "Received *setParametersMsg* from Server\n"); //DEBUG
	 		pkt = (radio_count_msg_t*)payload;
	 		processSetParameterMsg(pkt);
	 	}
	
	 	return bufPtr;
	}

	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		/*if (&packet == bufPtr) {
	      //locked = FALSE;
	    }*/
	} 	
}
