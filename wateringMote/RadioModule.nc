// -----------------------------------------------
//	RadioModule INTERFACE
// -----------------------------------------------
interface RadioModule{
	
	// Funcoes
	command void sendMeasure(uint8_t *measure, uint16_t *measureTS, uint8_t mIndex);
	command bool moteIsOn();
	

	command bool getChannelState();
	command void setChannelState(bool state);

}