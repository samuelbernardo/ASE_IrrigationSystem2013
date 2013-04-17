from TOSSIM import *

import time
import sys
from threading import Thread

# instanciar NescApp
from tinyos.tossim.TossimApp import *
n = NescApp()

# lista de vars da NescApp
vars = n.variables.variables()


# Carregar objecto Tossim em t
# vars - porque vou ler variaveis
t = Tossim(vars)

t.addChannel("out", sys.stdout);

# Temos de ligar pelo menos um boot,
# caso contrario o runNextEvent vai retornar sempre False,
# porque nao tem boots onde executar eventos
#m1 = t.getNode(1)
#m1.bootAtTime(1)

#m2 = t.getNode(2)
#m2.bootAtTime(2)
#v = m.getVariable("ContadorTimerC.contador")

#Python radio object
radio = t.radio()
#Python mac object
mac = t.mac()


# -------------------------------------------
# Aux.Functions
def createMoteNoiseModel( mote ):
	sys.stdout.write('creating noise model on mote ' + str(mote.id()) + '...');
	noise = open("meyer-heavy.txt", "r")
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
	f = open("networkTopology2.txt", "r")
	for line in f:
		s = line.split()
		if s:
			#print " ", s[0], " ", s[1], " ", s[2];
			radio.add(int(s[0]), int(s[1]), float(s[2]))
	print "[DONE]"
	return


# --------------------------------------------

# Temos de ligar pelo menos um boot,
# caso contrario o runNextEvent vai retornar sempre False,
# porque nao tem boots onde executar eventos

m1 = t.getNode(1)
m1.bootAtTime(1000)

m2 = t.getNode(2)
m2.bootAtTime(1)

m3 = t.getNode(3)
m3.bootAtTime(1)

m4 = t.getNode(4)
m4.bootAtTime(1)

m5 = t.getNode(5)
m5.bootAtTime(1)

m6 = t.getNode(6)
m6.bootAtTime(1)
#v = m.getVariable("ContadorTimerC.contador")

createNetworkTopology()
createMoteNoiseModel(m1)
createMoteNoiseModel(m2)
createMoteNoiseModel(m3)
createMoteNoiseModel(m4)
createMoteNoiseModel(m5)
createMoteNoiseModel(m6)


#for i in range(100):	
while True :
	#time.sleep(1)
	t.runNextEvent()	
	#counter = v.getData()
	# Se descomentar este print fico com um resultado muita esquisito...
	#print "valor do contador: %i " % (counter)

