 #include <Timer.h>

//em vez de escrever directamente no 'payload' da 'message_t 
// crio esta struct, escrevo nela, e depois meto-a no 'payload'
// da message_t
typedef nx_struct TTLsyncMsg {
  nx_uint16_t ttl;
	nx_uint16_t syncTS;
	nx_uint16_t numHopsToServer;
	nx_uint16_t lastNode;

} TTLsyncMsg;

 module RadioModuleC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  // Para enviar e processar packets
  uses interface Packet;    //aceder a message_t
  uses interface AMPacket;  //aceder a message_t
  uses interface AMSend;    
  uses interface SplitControl as AMControl;
 
  // Para receber packets
  uses interface Receive;

 }
 implementation {
  uint16_t counter;
  uint16_t moteID;

  bool busy = FALSE;  //flag de acesso ao radio
  message_t pkt;      //pacote a ser enviado
  message_t pktReSend;

  void assinarMensagem(BlinkToRadioMsg* msg){
    //msg->signatureSize = 20;
    msg->signatureIndex = 0;
    msg->nodesSignature[msg->signatureIndex] = TOS_NODE_ID;
    msg->signatureIndex = msg->signatureIndex + 1;
  }

  void reAssinarMensagem(BlinkToRadioMsg* msg){
    //msg->signatureSize = 20;
    //msg->signatureIndex = 0;
    msg->nodesSignature[msg->signatureIndex] = TOS_NODE_ID;
    msg->signatureIndex = msg->signatureIndex + 1;
  }


  void enviarMensagem(){
      /* == ENVIAR PACOTES == */ 
      // DEBUG: apenas o mote'1' envia mensagens
      if (!busy && (moteID == 1)) {
        // btrpkt = aponta para payload da variavel 'message_t pkt'
        BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
        
        btrpkt->srcNodeid = moteID;
        btrpkt->lastNodeId = moteID;
        btrpkt->value = 17; //counter;
        btrpkt->nodesSignature[0] = moteID;
        btrpkt->signatureIndex = 1; //[0,9]
        btrpkt->signatureSize = 10;

        //assinarMensagem(btrpkt);
        if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
          busy = TRUE;
        }
      }
    }
    /*
    void reenviarMensagem(BlinkToRadioMsg* btrpkt){
      /* == REenviar PACOTES / ROUTING DE PACOTES == 
      // DEBUG: apenas o mote'1' envia mensagens
      if (!busy) {
        //BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
        //btrpkt->srcNodeid = moteID;
        //btrpkt->value =  17; //counter;
        reAssinarMensagem(btrpkt);
        if (call AMSend.send(AM_BROADCAST_ADDR, btrpkt, sizeof(BlinkToRadioMsg)) == SUCCESS) {
          busy = TRUE;
        }
      }
    }
    */

   event void Boot.booted() {
    //Muita atencao: Adiar o start do timer, para AMControl.startDone
    counter = 0;
    call AMControl.start();
    moteID = TOS_NODE_ID;
    dbg("out", "Mote %i fez Boot! \n", moteID);
    //enviarMensagem(moteID,17);
   }
 
   event void Timer0.fired() {
      // do nothing
   }


    event void AMSend.sendDone(message_t* msg, error_t error) {
      if ( (&pkt == msg)  || (&pktReSend == msg ) ) {
        dbg("out", "Enviei mensagem %i \n", moteID);
        busy = FALSE;
      }
    }
 
   // Atencao: Timer so e' iniciado quando AMControl está up
   // pc AMControl vai ser usado quando o timer faz fired,
   // e o timer so pode fazer fired quando AMControl fica UP
   event void AMControl.startDone(error_t err) {
      if (err == SUCCESS) {
        enviarMensagem();
        call Timer0.startPeriodic(1000000 /*TIMER_PERIOD_MILLI*/);
      }
      else {call AMControl.start();}
    }

    event void AMControl.stopDone(error_t err) {
        // nao faz nada
    }   

    /* == RECEBER PACOTES == */
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
      int i = 0;
      bool reenviar = TRUE;

      if (len == sizeof(BlinkToRadioMsg)) {
        
        BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
        
        uint16_t srcNodeid = btrpkt->srcNodeid;
        uint16_t lastNodeId = btrpkt->lastNodeId;
        uint16_t value = btrpkt->value;
        uint16_t nodesSignature[10];
        uint16_t signatureIndex = btrpkt->signatureIndex;
        uint16_t signatureSize = btrpkt->signatureSize;

        for(i=0; i<signatureIndex; i++){
            nodesSignature[i] = (btrpkt->nodesSignature)[i];
        }    

        dbg("out", "---------------------------------------\n");
        dbg("out", "Recebi mensagem do mote= %i, lastNode=%i, value= %i, sigIndex= %i, sigSize= %i \n", srcNodeid, lastNodeId, value, signatureIndex, signatureSize);
        dbg("out","nodeSignature [index,signature]=");
        for(i=0; i<signatureIndex; i++){
            printf("[%i,%i]",i,nodesSignature[i]);
            if(nodesSignature[i] == moteID){
              reenviar = FALSE;
            }
        }printf("\n");
        if(reenviar == TRUE)
          dbg("out", "\n vou reenviar este pacote\n");
        else
          dbg("out", "\n NAO vou reenviar este pacote\n");
        dbg("out", "**** END OF DUMP *****\n");

        // REENVIAR MENSAGEM----------------------------------------------------------------
          if (!busy && reenviar == TRUE) {
            // btrpktReSend = aponta para payload da variavel 'message_t pkt'
            BlinkToRadioMsg* btrpktReSend = (BlinkToRadioMsg*)(call Packet.getPayload(&pktReSend, sizeof (BlinkToRadioMsg)));
        
            btrpktReSend->srcNodeid = srcNodeid;
            btrpktReSend->lastNodeId = moteID;
            btrpktReSend->value = value; //counter;
            
            for(i = 0; i<signatureIndex; i++){            
              btrpktReSend->nodesSignature[i] = nodesSignature[i];
            }

            btrpktReSend->nodesSignature[signatureIndex] = moteID;
            btrpktReSend->signatureIndex = signatureIndex + 1; //[0,9]
            btrpktReSend->signatureSize = 10;

            //assinarMensagem(btrpktReSend);
            if(call AMSend.send(AM_BROADCAST_ADDR, &pktReSend, sizeof(BlinkToRadioMsg)) == SUCCESS) {
              busy = TRUE;
              //dbg("out", "Reencaminhei mensagem\n");
            }
        }
      // FIM REENVIAR MENSAGEM------------------------------------------------------------

        /*
        for(i; i < signatureIndex; i++){
          dbg("out", "Lista assinaturas, conteudo: %i \n",  (btrpkt->nodesSignature)[i]);
          if((btrpkt->nodesSignature)[i] == TOS_NODE_ID){
              reenviar = FALSE;
          }
        } 
        if(reenviar){
        //  reenviarMensagem(btrpkt);
        }*/

      }
      return msg;
    }   
 }
