interface HumiditySensor 
{
	event void newMeasure(uint8_t newMeasure, uint16_t measureTimestamp);
}