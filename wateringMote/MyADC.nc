// -----------------------------------------------
//	ADC(Analog-Digital Converter) INTERFACE
// -----------------------------------------------
interface MyADC{
	
	// Funcoes
	command void getData();

	// Eventos
	event void dataReady(uint8_t newMeasure);
}