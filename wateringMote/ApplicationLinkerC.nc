
configuration ApplicationLinkerC{
}
implementation
{
  components MainC, HumiditySensorC; /*Atm128AdcC;*/
  components new TimerMilliC() as TimerHumidityC;
  components IrrigationSystemC;

  IrrigationSystemC -> MainC.Boot;
  IrrigationSystemC.HumiditySensor -> HumiditySensorC;
  HumiditySensorC -> MainC.Boot;
  HumiditySensorC.Timer -> TimerHumidityC;
  //HumiditySensorC.Atm128AdcSingle -> Atm128AdcC;
}

