 #define __NUM_MAX_MOTES__ 100
 #define __TIMER_PERIOD_MILLI__ 1000

 #include <Timer.h>
 #include <stdlib.h>
 #include <stdio.h>
 #include <string.h>

//em vez de escrever directamente no 'payload' da 'message_t 
// crio esta struct, escrevo nela, e depois meto-a no 'payload'
// da message_t
typedef nx_struct TTLsyncMsg {
	nx_uint16_t ttl;
	nx_uint16_t syncTS;
	nx_uint16_t numHopsToServer;
	nx_uint16_t lastNode;
} TTLsyncMsg;

 module SyncProtocolC {
	provides interface SyncProtocol;
	
  uses interface Timer<TMilli> as Timer0;
  
  // Para controlo do lock no envio das mensagens
  uses interface RadioModule;

  // Para enviar e processar packets
  uses interface Packet;    //aceder a message_t
  uses interface AMPacket;  //aceder a message_t
  uses interface AMSend;
 
  // Para receber packets
  uses interface Receive;

 }
 implementation {
  uint16_t counter = 0;
  uint16_t moteID;
	uint16_t syncTS;
	uint16_t ttl_max = __NUM_MAX_MOTES__;
	uint16_t ts = 0;

  message_t syncPathPkt;      //pacote a ser enviado

	bool reenviar = TRUE;

 	uint16_t getTimeStamp() {
			return ++counter;
	}


	void registarCalibracaoTTL(uint16_t newTTL, uint16_t tStamp){
		FILE *msgOut;
		msgOut = fopen("serverLog/syncMSG.log", "a+");
		fprintf(msgOut, "\t\tMoteID: %d NewTTL= %d TS=%d \n", TOS_NODE_ID, newTTL,tStamp);
		fclose(msgOut);
	}

  void enviarMsgControlo(){
      /* == ENVIAR PACOTES == */ 
      // DEBUG: apenas o mote'0' envia mensagem inicial
      if (!(call RadioModule.getChannelState()) && (moteID == 0)) {
        // btrpkt = aponta para payload da variavel 'message_t pkt'
        TTLsyncMsg* btrpkt = (TTLsyncMsg*)(call Packet.getPayload(&syncPathPkt, sizeof(TTLsyncMsg)));
        
        btrpkt->ttl = __NUM_MAX_MOTES__;
        btrpkt->syncTS = getTimeStamp();
        btrpkt->numHopsToServer = 1;
        btrpkt->lastNode = moteID;

        //assinarMensagem(btrpkt);
        if (call AMSend.send(AM_BROADCAST_ADDR, &syncPathPkt, sizeof(TTLsyncMsg)) == SUCCESS) {
          call RadioModule.setChannelState(TRUE);
        }
      }
    }

	void ttlUpdate(TTLsyncMsg* btrpkt) {
		btrpkt->ttl--;
		btrpkt->numHopsToServer++;
		btrpkt->lastNode = moteID;
	}
		
    void reenviarMsgControlo(message_t* msg, TTLsyncMsg* btrpkt){
      // == REenviar PACOTES / ROUTING DE PACOTES == 
      // DEBUG: apenas o mote'0' envia mensagens
      
	if(!(call RadioModule.getChannelState()) && moteID != 0 && btrpkt->ttl > 1) {
				
				if(ts < btrpkt->syncTS) {
					//dbg("out", "Não foi efectuada actualização de ttl_max para mensagem recebida do mote%i com numHopsToServer=%i e timestamp=%i\n", btrpkt->lastNode, btrpkt->numHopsToServer, btrpkt->syncTS);
					ttl_max = btrpkt->numHopsToServer;
					ts = btrpkt->syncTS;
					registarCalibracaoTTL(ttl_max,ts);
					ttlUpdate(btrpkt);
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(TTLsyncMsg)) == SUCCESS) {
						call RadioModule.setChannelState(TRUE);
					}
				}
				else if(btrpkt->numHopsToServer < ttl_max || ts > btrpkt->syncTS) {
					
					//E aqui que se afaz a calibraco do TTL
					ttl_max = btrpkt->numHopsToServer;
					ts = btrpkt->syncTS;
					registarCalibracaoTTL(ttl_max,ts);

					//dbg("out", "Actualizei ttlmax=%i para mensagem recebida do mote%i\n", ttl_max, btrpkt->lastNode);
					ttlUpdate(btrpkt);
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(TTLsyncMsg)) == SUCCESS) {
						call RadioModule.setChannelState(TRUE);
					}
				}
				else {
					//dbg("out", "Não foi efectuada actualização de ttl_max para mensagem recebida do mote%i com numHopsToServer=%i e não foi reenviada por ter timestamp=%i igual ao actual %i.\n", btrpkt->lastNode, btrpkt->numHopsToServer, btrpkt->syncTS, ts);
				}
      }
    
    /*
      if(!(call RadioModule.getChannelState()) && moteID != 0 && btrpkt->ttl > 1) {
				
				if(btrpkt->numHopsToServer < ttl_max || ts > btrpkt->syncTS) {
					
					//E aqui que se afaz a calibraco do TTL
					ttl_max = btrpkt->numHopsToServer;
					ts = btrpkt->syncTS;

					registarCalibracaoTTL(ttl_max,ts);

					//dbg("out", "Actualizei ttlmax=%i para mensagem recebida do mote%i\n", ttl_max, btrpkt->lastNode);
					ttlUpdate(btrpkt);
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(TTLsyncMsg)) == SUCCESS) {
						call RadioModule.setChannelState(TRUE);
					}
				}
				else if(ts < btrpkt->syncTS) {
					//dbg("out", "Não foi efectuada actualização de ttl_max para mensagem recebida do mote%i com numHopsToServer=%i e timestamp=%i\n", btrpkt->lastNode, btrpkt->numHopsToServer, btrpkt->syncTS);
					ts = btrpkt->syncTS;
					ttlUpdate(btrpkt);
					if (call AMSend.send(AM_BROADCAST_ADDR, msg, sizeof(TTLsyncMsg)) == SUCCESS) {
						call RadioModule.setChannelState(TRUE);
					}
				}
				else {
					//dbg("out", "Não foi efectuada actualização de ttl_max para mensagem recebida do mote%i com numHopsToServer=%i e não foi reenviada por ter timestamp=%i igual ao actual %i.\n", btrpkt->lastNode, btrpkt->numHopsToServer, btrpkt->syncTS, ts);
				}

      }*/



    }


    event void AMSend.sendDone(message_t* msg, error_t error) {
      if ( &syncPathPkt == msg ) {
		//TTLsyncMsg* payload = (TTLsyncMsg*)(call Packet.getPayload(msg, sizeof(TTLsyncMsg)));
        //dbg("out", "Mote%i enviou mensagem com timestamp %i \n", moteID, payload->syncTS);
        
        call RadioModule.setChannelState(FALSE);
      }
    }

    /* == RECEBER PACOTES == */
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
			TTLsyncMsg* btrpkt;

      if (len == sizeof(TTLsyncMsg)) {
				//para controlo do lock no envio de mensagens
				syncPathPkt = *msg;
				btrpkt = (TTLsyncMsg*)(call Packet.getPayload(&syncPathPkt, sizeof(TTLsyncMsg)));
				
				if(moteID != 0) {
					
					//Se mote Estiver NAO(!) Ligado 
					if(!(call RadioModule.moteIsOn())){
						return &syncPathPkt; 
					}

					//dbg("out", "---------------------------------------\n");
					//dbg("out", "Recebi mensagem do mote lastNode=%i, com timestamp= %i, numHopsToServer = %i, ttl = %i \n", btrpkt->lastNode, btrpkt->syncTS, btrpkt->numHopsToServer, btrpkt->ttl);
					
					if(reenviar == TRUE) {
						//dbg("out", "\n vou reenviar este pacote\n");
						// REENVIAR MENSAGEM----------------------------------------------------------------
						reenviarMsgControlo(&syncPathPkt, btrpkt);
						// FIM REENVIAR MENSAGEM------------------------------------------------------------
					}
					else {
						//dbg("out", "\n NAO vou reenviar este pacote\n");
					}
					//dbg("out", "**** END OF DUMP *****\n");
					
				}
				
				else {
					
					FILE *msgOut;
					msgOut = fopen("serverLog/syncMSG.log", "a+");
					fprintf(msgOut, "Recebi mensagem do mote lastNode=%i, com timestamp= %i, numHopsToServer = %i, ttl = %i \n", btrpkt->lastNode, btrpkt->syncTS, btrpkt->numHopsToServer, btrpkt->ttl);
					fclose(msgOut);
					
				}
      }
      
      return &syncPathPkt;
    }
    
    /**
     * Get TTL max
     **/
    command uint16_t SyncProtocol.getTTLmax() {
    	return ttl_max;
    }
    
	/**
	 * Vai lançando temporizadamente mensagens para controlo do estado
	 * da topologia da rede
	 **/
	event void Timer0.fired() {
		//dbg("out", "FIRED!\n");
		enviarMsgControlo();
	}
    
    /**
     * Comando a ser lançando após o arranque de AMcontrol
     **/
    command void SyncProtocol.sendControlMsg() {
		moteID = TOS_NODE_ID;
		
		if(TOS_NODE_ID == 0) {
			FILE *msgOut;
			
			counter = 0;
			
			msgOut = fopen("serverLog/syncMSG.log", "w");
			fprintf(msgOut, "========= Network shortest path algorithm initialized =========\n\n");
			fclose(msgOut);
						
			enviarMsgControlo();
			call Timer0.startPeriodic(__TIMER_PERIOD_MILLI__);
			
			//dbg("out", "Mote %i vai enviar nova mensagem do protocolo de sincronização! \n", TOS_NODE_ID);
		}
		else {
			//dbg("out", "Mote %i executou command void SyncProtocol.sendControlMsg() sem enviar mensagem! (não sendo o mote0 está correcto)\n", TOS_NODE_ID);
		}
	}
		
 }
