interface IrrigationSystem 
{
	command uint16_t getMeasures(uint8_t *measuresBuf, uint16_t *measuresTSBuf);
	command void setTmeasure(uint32_t tm);
	command void setWmin(uint8_t wmin);
	command void setWmax(uint8_t wmax);
}