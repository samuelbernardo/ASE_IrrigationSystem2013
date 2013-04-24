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
  
	bool firstSend;

  event void Boot.booted() {
		firstSend = TRUE;
		tServer = 100000; 		//Default Value
		channelIsBusy = FALSE;
   
    call AMControl.start();
    
    //dbg("out", "Mote %i fez Boot! \n", TOS_NODE_ID);
	dbg("out", "Radio Has Booted \n");
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      	call Timer.startPeriodic(tServer);
      	//call SyncProtocol.sendControlMsg();
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
		//dbg("out", "Vou difundir mensagem com: m = %d, ts = %d \n", measure, measureTS);

		if(!channelIsBusy && TOS_NODE_ID == 5 && firstSend == TRUE){
			firstSend = FALSE;
			rmp = (RadioMeasuresPacket*)(call Packet.getPayload(&packet, sizeof (RadioMeasuresPacket)));
			
			rmp->srcNodeId = TOS_NODE_ID;
			rmp->lastNodeId = TOS_NODE_ID;
			rmp->measures[0] = measure;
			rmp->measuresTS[0] = measureTS;
			rmp->measuresIndex = 1;
			rmp->packetTTL = 10; // <-- chamar funcao do Samuel
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioMeasuresPacket)) == SUCCESS) {
          		channelIsBusy = TRUE;
        	}		
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
    	if (&packet == msg) {
          	channelIsBusy = FALSE;
        	//dbg("out", "Enviei mensagem(tirei lock do channel)\n");
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

	void routeTheMessage(void* payload){
		
		int i;
		//packet recebida
		RadioMeasuresPacket *pktRcv = (RadioMeasuresPacket*) payload;	
		//packet a ser enviada
		RadioMeasuresPacket *pktSnd = (RadioMeasuresPacket*) (call Packet.getPayload(&packet, sizeof (RadioMeasuresPacket)));
	    
	    //DEBUG
	    dbg("out", "RcvRadioPkt src:%d last:%d ttl:%d\n",pktRcv->srcNodeId,pktRcv->lastNodeId,pktRcv->packetTTL);
		
		if((pktRcv->packetTTL <= 0) || (pktRcv->lastNodeId == TOS_NODE_ID)){
			//TTL expirou, nao reenvia mensagem
			//Este Mote foi o ultimo a reenviar mesnsagem, nao a volta a reenviar
			return;
		}


		if(!channelIsBusy){
		
			pktSnd->srcNodeId = pktRcv->srcNodeId;
			pktSnd->lastNodeId = TOS_NODE_ID;
			pktSnd->packetTTL = (pktRcv->packetTTL - 1); 
			pktSnd->measuresIndex = pktRcv->measuresIndex;

			for(i=0; i < pktRcv->measuresIndex; i++){
				pktSnd->measures[i] = pktSnd->measures[i];
				pktSnd->measuresTS[i] = pktSnd->measuresTS[i];
			}
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioMeasuresPacket)) == SUCCESS) {
          		channelIsBusy = TRUE;
        	}	
		}

		/*
		  nx_uint16_t	srcNodeId;			// 2 bytes
		  nx_uint16_t	lastNodeId;			// 2 bytes
		  nx_uint8_t	measures[7];		// 7 bytes
		  nx_uint16_t	measuresTS[7];		// 14 bytes
		  nx_uint8_t	measuresIndex;		// 1 byte
		  nx_uint16_t	packetTTL;			// 2 bytes
		*/
	}


	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
	    
		radio_count_msg_t* pkt;		
	 	
	 	//Recebeu mensagem do servidor
	 	if(len == sizeof(radio_count_msg_t)){
	    	//dbg("out", "Received *setParametersMsg* from Server\n"); //DEBUG
	 		pkt = (radio_count_msg_t*)payload;
	 		processSetParameterMsg(pkt);
	 	}

	 	if(len == sizeof(RadioMeasuresPacket)){
	    	   	
	 		if(TOS_NODE_ID == 0){
	 			
	 			//DEBUG	
				RadioMeasuresPacket *pktRcv = (RadioMeasuresPacket*) payload;	
	    		dbg("out", "RcvRadioPkt src:%d last:%d ttl:%d\n",pktRcv->srcNodeId,pktRcv->lastNodeId,pktRcv->packetTTL);
	 		
	 			// TODO: Log da Mensagem Recebida
	 			// TODO: Log das Medições da Rede
	 		}
	 		else{
	 			// TODO: Log da Mensagem Recebida
	 			
	 			// Reencaminhar Mensagem (routing)
	 			routeTheMessage(payload);
	 		}
	 	}
	 	return bufPtr;
	}
	
	/**
	 * methods for channel control
	 **/
	command bool RadioModule.getChannelState() {
		return channelIsBusy;
	}
	
	command void RadioModule.setChannelState(bool state) {
		channelIsBusy = state;
	}
	
}
