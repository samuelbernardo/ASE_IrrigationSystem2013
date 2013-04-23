// -----------------------------------------------
//	WaterValveActuator INTERFACE
// -----------------------------------------------
interface WaterValveActuator{
	
	// Funcoes
	command void closeValve();
	command void openValve();
	command bool isOpen();
}