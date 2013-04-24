// -----------------------------------------------
//	RadioModule INTERFACE
// -----------------------------------------------
interface RadioModule{
	
	// Funcoes
	command void sendMeasure(uint8_t measure, uint16_t measureTS);
	
	command bool getChannelState();
	command void setChannelState(bool state);

}