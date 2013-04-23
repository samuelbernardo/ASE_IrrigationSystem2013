COMPONENT=ApplicationLinkerC
BUILD_EXTRA_DEPS = RadioSetParametersPacket.py
CLEAN_EXTRA = RadioSetParametersPacket.py

RadioSetParametersPacket.py: SharedData.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=RadioSetParametersPacket SharedData.h radio_count_msg -o $@

include $(MAKERULES)