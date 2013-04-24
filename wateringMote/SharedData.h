#ifndef SHARED_DATA_H
#define SHARED_DATA_H

// ========================================
// Nota: MaxSize desta estrutura = 28 Bytes
// ========================================

typedef nx_struct RadioMeasuresPacket {
  nx_uint16_t	srcNodeId;			// 2 bytes
  nx_uint16_t	lastNodeId;			// 2 bytes
  nx_uint8_t	measures[7];		// 7 bytes
  nx_uint16_t	measuresTS[7];		// 14 bytes
  nx_uint8_t	measuresIndex;		// 1 byte aonta para a primeira posição livre do vector (C Style)
  nx_uint16_t	packetTTL;			// 2 bytes
} RadioMeasuresPacket;				// Total: 28 Bytes

//Afinal isto nao esta a ser usado
typedef nx_struct RadioTTLCalibrationPacket {
  nx_uint16_t	lastNodeId;			// 2 bytes
  nx_uint16_t	packetTTL;			// 2 bytes
  nx_uint16_t	hopsToServer;		// 2 bytes  
  nx_uint16_t	calibrationTS;	// 2 bytes <-- para optimizar algoritmo
} RadioTTLCalibrationPacket;		// Total: 8 Bytes


/*
Key: operationCode = {1,2,3,4}
    1 - setTmeasure
    2 - setTserver
    3 - setWmax
    4 - setWmin

    otherValues - Do Nothing
*/

//Aconteca o que acontecer, NAO aleteres o nome desta struct!
//se alterares o nome desta struct, o mote deixa de apanhar esta packet
typedef nx_struct radio_count_msg {
  nx_uint32_t paramValue;     // 4 bytes - timers configurados em milisegundos, numero é mto grande
  nx_uint8_t operationCode;   // 1 bytes
  nx_uint16_t moteID;         // 2 Bytes
  nx_uint16_t packetTTL;      // 2 bytes
  nx_uint16_t lastNodeID;     // 2 bytes
} radio_count_msg_t;   // Total: 11s Bytes

enum {
  AM_RADIO_COUNT_MSG = 6,
};

#endif