
configuration ApplicationLinkerC{
}
implementation
{
  components MainC, HumiditySensorC, MyADC_C, WaterValveActuatorC;
  components new TimerMilliC() as TimerHumidityC;
  components new TimerMilliC() as TimerRadioModuleC;
  components IrrigationSystemC;
  components RadioModuleC, SyncProtocolC;
  components new TimerMilliC() as Timer0;

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
  RadioModuleC.SyncProtocol -> SyncProtocolC;
  
  //SyncProtocol --------------------------------
  SyncProtocolC.Timer0 -> Timer0;
  SyncProtocolC.Packet -> AMSenderC;
  SyncProtocolC.AMPacket -> AMSenderC;
  SyncProtocolC.AMSend -> AMSenderC;
  SyncProtocolC.Receive -> AMReceiverC;
  
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

