from TOSSIM import *

import time
from threading import Thread

# instanciar mensagens a serem injectadas na rede
# pelo servidor
from RadioSetParametersPacket import *

# instanciar NescApp
#from tinyos.tossim.TossimApp import *
#n = NescApp()

# lista de vars da NescApp
#vars = n.variables.variables()


# Carregar objecto Tossim em t
# vars - porque vou ler variaveis
t = Tossim([])

import sys
t.addChannel("out", sys.stdout);

#Python radio object
radio = t.radio()
#Python mac object
mac = t.mac()

#Aux variables
networkMap = "serverConfigFiles/networkTopology3.txt"
counterMax = 100
timerStep = 1000

# -------------------------------------------
# Aux.Functions
def createMoteNoiseModel( mote ):
	sys.stdout.write('creating noise model on mote ' + str(mote.id()) + '...');
	noise = open("serverConfigFiles/meyer-heavy-short.txt", "r")
	lines = noise.readlines()
	for line in lines:
		str1 = line.strip()
		if str1:
			val = int(str1)
			mote.addNoiseTraceReading(val)
	mote.createNoiseModel()
	print "[DONE]"
	return

def createNetworkTopology():
	sys.stdout.write('creating network topology... ');
	f = open(networkMap, "r")
	for line in f:
		s = line.split()
		if s:
			#print " ", s[0], " ", s[1], " ", s[2];
			radio.add(int(s[0]), int(s[1]), float(s[2]))
	print "[DONE]"
	return

# DEPRECATED def sendSetParametersMsg(moteIDtoSend,paramValue,opCode):
def sendSetParametersMsg(moteIDtoSend,paramValue,opCode,ttl):
	''' === CODE UNDER TEST === '''
	print "Prepare to Deliver"
	msg = RadioSetParametersPacket()
	
	msg.set_paramValue(paramValue)
	msg.set_operationCode(opCode)
	msg.set_moteID(moteIDtoSend)			
	msg.set_packetTTL(ttl)			
	msg.set_lastNodeID(0)	

	pkt = t.newPacket()

	pkt.setData(msg.data)
	pkt.setType(msg.get_amType())
	pkt.setDestination(0) #Servirdor envia sempre mensagens para Mote0

	print "Delivering " + str(msg) + " to" +str(moteIDtoSend)+" by Mote0"
	pkt.deliverNow(0)
	print "Deliver done"
	''' =================== '''
# --------------------------------------------	

# Temos de ligar pelo menos um boot,
# caso contrario o runNextEvent vai retornar sempre False,
# porque nao tem boots onde executar eventos
m0 = t.getNode(0)
m0.bootAtTime(1)

m1 = t.getNode(1)
m1.bootAtTime(1)

m2 = t.getNode(2)
m2.bootAtTime(1)

m3 = t.getNode(3)
m3.bootAtTime(1)

m4 = t.getNode(4)
m4.bootAtTime(1)

m5 = t.getNode(5)
m5.bootAtTime(1)


#v = m.getVariable("ContadorTimerC.contador")

createNetworkTopology()
createMoteNoiseModel(m0)
createMoteNoiseModel(m1)
createMoteNoiseModel(m2)
createMoteNoiseModel(m3)
createMoteNoiseModel(m4)
createMoteNoiseModel(m5)

for i in range(100) :
	t.runNextEvent()

# 1 setTmeasure
# 2 setTserver
# 3 setWmax
# 4 setWmin

#def sendSetParametersMsg(moteIDtoSend,paramValue,opCode,ttl):
#sendSetParametersMsg(2,100,1,6)


'''
for counter in range (1,counterMax):
	print "valor do contador: %i " % (counter)
	t.runNextEvent()
	counter += 1
	time = t.time()
	while time + timerStep > t.time():
		t.runNextEvent()
'''

while True :
	time.sleep(0.0001)
	t.runNextEvent()	
	#counter = v.getData()
	# Se descomentar este print fico com um resultado muita esquisito...
	#print "valor do contador: %i " % (counter)
