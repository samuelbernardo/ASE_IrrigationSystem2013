interface IrrigationSystem 
{
	command bool getMeasures(RadioMeasuresPacket *pkt);
	command void setTmeasure(uint32_t tm);
	command void setWmin(uint8_t wmin);
	command void setWmax(uint8_t wmax);
}