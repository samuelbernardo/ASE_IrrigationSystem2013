// -----------------------------------------------
//	HumiditySensor INTERFACE
// -----------------------------------------------
interface HumiditySensor{
	
	// Funcoes
	command void setTmeasure(uint16_t tMeasure);
	command uint16_t getTimer();

	// Eventos
	event void newMeasure(uint8_t newMeasure, uint16_t measureTimestamp);

}