
configuration ApplicationLinkerC{
}
implementation
{
  components MainC, HumiditySensorC, MyADC_C, WaterValveActuatorC;
  components new TimerMilliC() as TimerHumidityC;
  components new TimerMilliC() as TimerRadioModuleC;
  components IrrigationSystemC;
  components RadioModuleC;

  //Radio Components ---------------------------
  //components new TimerMilliC() as TimerRadioC;
  components ActiveMessageC;  
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG); 

  RadioModuleC -> MainC.Boot;
  //RadioModuleC.TimerR -> TimerRadioC;

  RadioModuleC.Packet -> AMSenderC;
  //RadioModuleC.AMPacket -> AMSenderC;
  RadioModuleC.AMSend -> AMSenderC;
  RadioModuleC.AMControl -> ActiveMessageC;
  RadioModuleC.Receive -> AMReceiverC;
  
  RadioModuleC.IrrigationSystem -> IrrigationSystemC;
  RadioModuleC.Timer -> TimerRadioModuleC;
  //------------------------------------------

  IrrigationSystemC -> MainC.Boot;
  HumiditySensorC -> MainC.Boot;
  MyADC_C -> MainC.Boot;
  WaterValveActuatorC -> MainC.Boot;
  IrrigationSystemC.HumiditySensor -> HumiditySensorC;
  IrrigationSystemC.WaterValveActuator -> WaterValveActuatorC;
  IrrigationSystemC.RadioModule -> RadioModuleC;
 
  HumiditySensorC.Timer -> TimerHumidityC;
  HumiditySensorC.MyADC -> MyADC_C; 

}

