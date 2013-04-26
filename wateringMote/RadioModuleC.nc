#include "Timer.h"
#include "SharedData.h"

#define	BUFFER_SIZE	10

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
	
	// == Log Variables ==
	uint16_t totalBytesSent;
	uint16_t totalBytesRecv;
	//relogio logico de envio e recepcao de mensagens 
	uint16_t radioTimesatamp;
	bool logInit;
	
	// ===================
	
	/**
	 * Server variables initialization
	 **/
	MeasuresControl measuresControl[__TOTAL_NODES_NUMBER__];
	uint16_t numNodes;
	
	// == Aux Buffers ===
	uint8_t mBufferAux[BUFFER_SIZE];
	uint16_t mTSBufferAux[BUFFER_SIZE];
	uint16_t mBufferIndexAux;
	//===================

	//-----------------------------------------------------------


	void initBuffers(){
		int i=0;
		mBufferIndexAux = 0;
		for(i = 0; i < BUFFER_SIZE; i++){
			mBufferAux[i]=0;
			mTSBufferAux[i]=0;
		}
	}
	

  event void Boot.booted() {
	firstSend = TRUE; // Apenas para DEBUG, no fim tem de ser removido
	
	tServer = 9000; 		//Default Value
	channelIsBusy = FALSE;
   	totalBytesSent = 0;
	totalBytesRecv = 0;
	radioTimesatamp = 0;
	logInit = FALSE;
		
	if(TOS_NODE_ID == 0){
  		uint16_t nodeId;
  		FILE* measuresFile;
  		
		numNodes = __TOTAL_NODES_NUMBER__;
		
		for(nodeId=0; nodeId < numNodes; nodeId++) {
			measuresControl[nodeId].measureTS = 0;
		}
		
		measuresFile = fopen("serverLog/measures.log","w+");
		fprintf(measuresFile, "NodeID\t\tTimestamp\tHumidityMeasure\n");
		fclose(measuresFile);
	}
	
	initBuffers();

    call AMControl.start();
    
	dbg("out", "Radio Has Booted \n");
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
		//dbg("out", "RadioTimerFire! \n");
   		mBufferIndexAux =  call IrrigationSystem.getMeasures(mBufferAux, mTSBufferAux);
   		call RadioModule.sendMeasure(mBufferAux, mTSBufferAux, mBufferIndexAux);
   		mBufferIndexAux = 0;
   }

   	// log da mensagem de set Parameters que o mote recebeu ou enviou,
	// 2param: 1=recebida, 0=enviada 
	void logSetParametersMessage(radio_count_msg_t *pkt, int lenght, char *msgType, int IOstate){

		char fileName[40];
		char *state;
		char setOperation[15];
		FILE *file;
		sprintf(fileName,"radioMoteLog/radioMoteLog_%d",TOS_NODE_ID);
		file = fopen(fileName,"a");


		radioTimesatamp++;

		if(logInit == FALSE){
			fprintf(file, "============= New File =============\n");	
			logInit = TRUE;
		}

		if(IOstate == 1){	
			state = "Recv";
			totalBytesRecv = totalBytesRecv + lenght;	
		}

		if(IOstate == 0){	
			state = "Sent";	
			totalBytesSent = totalBytesSent + lenght;
		}

		switch(pkt->operationCode){
			case 1 : sprintf(setOperation,"setTmeasure"); break;
			case 2 : sprintf(setOperation,"setTserver"); break;
			case 3 : sprintf(setOperation,"setWmax"); break;
			case 4 : sprintf(setOperation,"setWmin"); break;
			default : dbg("out", "[ERROR@RadioModule@logSetParametersMessage] OperationCode Invalid!\n"); break;
		}

		fprintf(file, ">> TS: %d \t [%s] [%s]\tMsgSize: %d TotalBytesRecv: %d\tTotalBytesSent: %d\tTotalBytes: %d\n",radioTimesatamp,state,msgType,lenght,totalBytesRecv,totalBytesSent,(totalBytesRecv+totalBytesSent) );	
		fprintf(file, "\t\t\t Operation: %s NewValue: %d  DestMote: %d LastMote: %d TTL: %d\n",setOperation,pkt->paramValue,pkt->moteID,pkt->lastNodeID,pkt->packetTTL);	
		
		/*
		nx_uint32_t paramValue;     // 4 bytes - timers configurados em milisegundos, numero é mto grande
  		nx_uint8_t operationCode;   // 1 bytes
  		nx_uint16_t moteID;         // 2 Bytes
  		nx_uint16_t packetTTL;      // 2 bytes
  		nx_uint16_t lastNodeID;     // 2 bytes
		*/
		fclose(file);

	}



   	// log da mensagem que o mote recebeu ou enviou, nao faz log do conteudo(leituras) da mensagem
    // faz log do tamaho da mensagem do Timesatamp, e se foi recebida ou enviada.
	// 2param: 1=recebida, 0=enviada 
	void logTheMeasuresMessage(RadioMeasuresPacket *pkt, int lenght, char *msgType, int IOstate){
		

		/* == Log Variables ==
		uint16_t totalBytesSent;
		uint16_t totalBytesRecv;
		//relogio logico de envio e recepcao de mensagens 
		uint16_t radioTimesatamp;
		bool logInit;
		=================== */

		char fileName[40];
		FILE *file;
		sprintf(fileName,"radioMoteLog/radioMoteLog_%d",TOS_NODE_ID);
		file = fopen(fileName,"a");

		radioTimesatamp++;

		if(logInit == FALSE){
			fprintf(file, "============= New File =============\n");	
			logInit = TRUE;
		}
		
		if(IOstate == 1){
			//fprintf(file, "[%d]Recebi um pacote\n", TOS_NODE_ID);	
			totalBytesRecv = totalBytesRecv + lenght;	
			fprintf(file, ">> TS: %d \t [Recv] [%s]\tMsgSize: %d TotalBytesRecv: %d\tTotalBytesSent: %d\tTotalBytes: %d\n",radioTimesatamp,msgType,lenght,totalBytesRecv,totalBytesSent,(totalBytesRecv+totalBytesSent) );	
			fprintf(file, "\t\t\t SrcMote: %d LastMote: %d  #Measures: %d TTL: %d\n",pkt->srcNodeId,pkt->lastNodeId,pkt->measuresIndex,pkt->packetTTL);	
		}
		
		if(IOstate == 0){
			//fprintf(file, "[%d]Enviei um pacote\n", TOS_NODE_ID);	
			totalBytesSent = totalBytesSent + lenght;
			fprintf(file, ">> TS: %d \t [Sent] [%s]\tMsgSize: %d TotalBytesRecv: %d\tTotalBytesSent: %d\tTotalBytes: %d\n",radioTimesatamp,msgType,lenght,totalBytesRecv,totalBytesSent,(totalBytesRecv+totalBytesSent) );	
			fprintf(file, "\t\t\t SrcMote: %d LastMote: %d  #Measures: %d TTL: %d\n",pkt->srcNodeId,pkt->lastNodeId,pkt->measuresIndex,pkt->packetTTL);	
		}

		fclose(file);
	}

	
	/**
	 * Filter repeated messages
	 **/
	bool verifyNewMeasureMsg(RadioMeasuresPacket* measuresPkt) {
		//dbg("out","[verifyNewMeasureMsg]\nRadioMeasuresPacket: nodeId=%i\tmeasuresTS=%i\tmeasures=%i\nmeasuresControl[%i].measureTS=%i\n", measuresPkt->srcNodeId, measuresPkt->measuresTS[0], measuresPkt->measures[0],measuresPkt->srcNodeId,measuresControl[measuresPkt->srcNodeId].measureTS);
	
		if(measuresControl[measuresPkt->srcNodeId].measureTS < measuresPkt->measuresTS[0]) {
			measuresControl[measuresPkt->srcNodeId].measureTS = measuresPkt->measuresTS[0];
			return TRUE;
		}
		
		return FALSE;
	}
	
	/**
	 * Measures logging
	 **/
	void logMeasures(RadioMeasuresPacket* measuresPkt) {
		uint8_t i, numMeasures;
		FILE* measuresFile;
		
		//dbg("out", "###############logMeasures begin\n");
		
		if(verifyNewMeasureMsg(measuresPkt)) {
			
			measuresFile = fopen("serverLog/measures.log","a+");
			
			numMeasures = measuresPkt->measuresIndex;
			
			for(i=0; i < numMeasures; i++) {
				fprintf(measuresFile, "%i\t\t%i\t\t%i\n", measuresPkt->srcNodeId, measuresPkt->measuresTS[i], measuresPkt->measures[i]);
			}
			
			fclose(measuresFile);
		}
		
		//dbg("out", "###############logMeasures end\n");
	}
	
	
    //Samuel, estva a fazer esta funcao antes de te enviar o codigo
   	//esta funcao ainda nao esta completa e o que ela faz é difundiar umma mensagem com a ultima leitura do sensor,
    // depois de ter esta funcao testada e "estavel". o que ia fazer era enviar mensagens não com uma medida, 
    //  mas com muitas medidas (no máximo 7). Para aproveitar ao maximo o tamanho da packet. 
	command void RadioModule.sendMeasure(uint8_t *measure, uint16_t *measureTS, uint8_t measureIndex){

		int i;
		RadioMeasuresPacket *rmp;
		//dbg("out", "Vou difundir mensagem com: m = %d, ts = %d \n", measure, measureTS);

		// Nota: 2 e 3 condicao do IF serverm apenas para debug
		// apenas o mote 1 envia leituras, e só as envia uma vez!
		// assim so se tem "uma" mensagem a navegar na rede.
		if(!channelIsBusy/* && TOS_NODE_ID == 1  && firstSend == TRUE*/){
			firstSend = FALSE;
			
			rmp = (RadioMeasuresPacket*)(call Packet.getPayload(&packet, sizeof (RadioMeasuresPacket)));
			
			rmp->srcNodeId = TOS_NODE_ID;
			rmp->lastNodeId = TOS_NODE_ID;
			
			for(i=0; i<measureIndex; i++){
				rmp->measures[i] = measure[i];
				rmp->measuresTS[i] = measureTS[i];
			}

			rmp->measuresIndex = measureIndex;
			rmp->packetTTL = call SyncProtocol.getTTLmax();
			
			//DEBUG dbg("out", "M= %d TS= %d  \n", rmp->measures[0], rmp->measuresTS[0]);
			
 			// Log das medições de humidade no mote 0
 			if(TOS_NODE_ID == 0) {
 				logMeasures(rmp);
 			}
			else if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioMeasuresPacket)) == SUCCESS) {
          		channelIsBusy = TRUE;
	 			logTheMeasuresMessage(rmp,sizeof(*rmp),"Measures",0); // 2param: 1=recebida, 0=enviada
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
	    	//dbg("out", "Recebi setParametersMsg -> setTmeasure\n");
			call IrrigationSystem.setTmeasure(paramValue);
			return;
		}
		if(operationCode == 2){ //set tServer
	    	//dbg("out", "Recebi setParametersMsg -> setTserver\n");
			
			//evita execucao de mensagens setParameters repetidas
			if(tServer != paramValue){
				tServer = paramValue;
	      		call Timer.startPeriodic(tServer); //Restart timer com novo tServer
				// NAO APAGAR ESTA MENSAGEM DE DEBUG, É BASTANTE UTIL
				dbg("out", "RadioModule: tServer updated = %d \n",tServer);
			}
			return;
		}
		if(operationCode == 3){ //set wmax
	    	//dbg("out", "Recebi setParametersMsg -> setWmax\n");
			call IrrigationSystem.setWmax(paramValue);
			return;
		}
		if(operationCode == 4){ //set wmin
	    	//dbg("out", "Recebi setParametersMsg -> setWmin\n");
	    	call IrrigationSystem.setWmin(paramValue);
			return;
		}

	    //dbg("out", "[ERROR] Received a *setParametersMsg* but operationCode is INVALID\n");
	    //dbg("out", "|%d|%d|%d|%d|%d| \n",paramValue,operationCode,moteID,packetTTL,lastNodeID); //DEBUG
		return;
	}

	void routeSetParametersMessage(radio_count_msg_t* pktRcv){
	   	//dbg("out", "Received *setParametersMsg* from Server----------------------\n"); //DEBUG
	 	//dbg("out","DUMP: pv: %d opC: %d destID: %d lastID: %d ttl: %d\n", pkt->paramValue,pkt->operationCode,pkt->moteID,pkt->lastNodeID,pkt->packetTTL);

		radio_count_msg_t *pktSnd;
		
		if(!channelIsBusy && (pktRcv->packetTTL >= 1)){

			pktSnd = (radio_count_msg_t*) (call Packet.getPayload(&packet, sizeof (radio_count_msg_t)));
			
			pktSnd->paramValue = pktRcv->paramValue;
			pktSnd->operationCode = pktRcv->operationCode;
			pktSnd->moteID = pktRcv->moteID;
			pktSnd->packetTTL = (pktRcv->packetTTL - 1);
			pktSnd->lastNodeID = TOS_NODE_ID;

			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
				logSetParametersMessage(pktSnd,sizeof(*pktSnd),"SetParameter(R)", 0);
          		channelIsBusy = TRUE;
        	}	
		}

		/*
		nx_uint32_t paramValue;     // 4 bytes - timers configurados em milisegundos, numero é mto grande
  		nx_uint8_t operationCode;   // 1 bytes
  		nx_uint16_t moteID;         // 2 Bytes
  		nx_uint16_t packetTTL;      // 2 bytes
  		nx_uint16_t lastNodeID;     // 2 bytes
		*/
	}

	// route the Measures Message
	void routeTheMessage(void* payload){
		
		int i;
		//packet recebida
		RadioMeasuresPacket *pktRcv = (RadioMeasuresPacket*) payload;	
		//packet a ser enviada
		RadioMeasuresPacket *pktSnd = (RadioMeasuresPacket*) (call Packet.getPayload(&packet, sizeof (RadioMeasuresPacket)));
	    
	    //DEBUG
	    //dbg("out", "RcvRadioPkt src:%d last:%d ttl:%d\n",pktRcv->srcNodeId,pktRcv->lastNodeId,pktRcv->packetTTL);
		
		if((pktRcv->packetTTL < 1) || (pktRcv->lastNodeId == TOS_NODE_ID)){
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
				pktSnd->measures[i] = pktRcv->measures[i];    	//BugFix
				pktSnd->measuresTS[i] = pktRcv->measuresTS[i];	//BugFix

				/*
	    		if(TOS_NODE_ID == 5){
	    			dbg("out", "#### ID:%d i:%d m:%d ts:%d\n",pktRcv->srcNodeId,i,pktRcv->measures[i],pktRcv->measuresTS[i]);
				}*/
			}
			
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioMeasuresPacket)) == SUCCESS) {
          		channelIsBusy = TRUE;
	 			logTheMeasuresMessage(pktSnd,sizeof(*pktSnd),"Meas.(R)",0); 		// 2param: 1=recebida, 0=enviada        		
        	}	
		}

	}

	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
	    		
	 	//Recebeu mensagem do servidor
	 	if(len == sizeof(radio_count_msg_t)){
	    	
	 		radio_count_msg_t* pkt = (radio_count_msg_t*)payload;
	    	
	    	//DEBUG
	    	//dbg("out", "Received *setParametersMsg* from Server----------------------\n"); //DEBUG
	 		//dbg("out","DUMP: pv: %d opC: %d destID: %d lastID: %d ttl: %d\n", pkt->paramValue,pkt->operationCode,pkt->moteID,pkt->lastNodeID,pkt->packetTTL);

	 		if(pkt->moteID == TOS_NODE_ID){
		    	//dbg("out", "Recebi setParamsMsg que é para mim. Vou processa-la! ----------------------\n"); //DEBUG
	 			
	 			// 3param: 1=recebida, 0=enviada
				logSetParametersMessage(pkt,len,"SetParam.(this)", 1);
	 			processSetParameterMsg(pkt);
	 		}
	 		else{
		    	//dbg("out", "Recebi setParamsMsg que NAO é para mim. Vou reenvia-la com TTL--! ----------------------\n"); //DEBUG
				logSetParametersMessage(pkt,len," SetParameters ", 1);
	 			routeSetParametersMessage(pkt);
	 		}
	 	}
	 	//Recebeu, de outro mote, mensagem com medições
	 	if(len == sizeof(RadioMeasuresPacket)){
			
			RadioMeasuresPacket *pkt = (RadioMeasuresPacket*) payload;	
	    	   	
	 		if(TOS_NODE_ID == 0){
	 			
	 			// Log das Medições da Rede
	 			logMeasures(pkt);

				// Log da Mensagem Recebida
	    		//dbg("out", "RcvRadioPkt src:%d last:%d ttl:%d\n",pkt->srcNodeId,pkt->lastNodeId,pkt->packetTTL);
	 			// 2param: 1=recebida, 0=enviada
	 			logTheMeasuresMessage(pkt,len,"Meas.(R)",1);
	 			
	 		}
	 		else{
	 			// 2param: 1=recebida, 0=enviada
	 			logTheMeasuresMessage(pkt,len,"Meas.(R)",1);
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
