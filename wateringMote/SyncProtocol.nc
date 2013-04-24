// -----------------------------------------------
//	SyncProtocol INTERFACE
// -----------------------------------------------
interface SyncProtocol {
	
	// Funcoes
	command void sendControlMsg();
	command uint16_t getTTLmax();

}
