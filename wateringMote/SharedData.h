

//Nota: MaxSize desta estrutura = 28 Bytes
typedef nx_struct RadioMeasuresPacket {
  nx_uint16_t	srcNodeId;			// 2 bytes
  nx_uint16_t	lastNodeId;			// 2 bytes
  nx_uint8_t	measures[7];		// 7 bytes
  nx_uint16_t	measuresTS[7];		// 14 bytes
  nx_uint8_t	measuresIndex;		// 1 byte
  nx_uint16_t	packetTTL;			// 2 bytes
} RadioMeasuresPacket;				// Total: 28 Bytes

typedef nx_struct RadioTTLCalibrationPacket {
  nx_uint16_t	lastNodeId;			// 2 bytes
  nx_uint16_t	packetTTL;			// 2 bytes
  nx_uint16_t	hopsToServer;		// 2 bytes  
  nx_uint16_t	calibrationTS;	// 2 bytes <-- para optimizar algoritmo
} RadioTTLCalibrationPacket;		// Total: 8 Bytes
