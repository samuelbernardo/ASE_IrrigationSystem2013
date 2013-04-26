from TOSSIM import *

import time
from threading import Thread

import cmd
import string, sys

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
networkMap = "serverConfigFiles/networkTopology2.txt"
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

def start():
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


def step(length):
	'''
	for counter in range (1,counterMax):
		print "valor do contador: %i " % (counter)
		t.runNextEvent()
		counter += 1
		time = t.time()
		while time + timerStep > t.time():
			t.runNextEvent()
	'''
	
	for counter in range(length) :
		#time.sleep(0.0001)				Fix: isto ja nao e' necessario
		t.runNextEvent()
		# Se descomentar este print fico com um resultado muita esquisito...
		#print "valor do contador: %i " % (counter)


def moteTurnON(moteId):
	m = t.getNode(moteId)
	if not m.isOn():
		m.turnOn()
		
def moteTurnOFF(moteId):
	m = t.getNode(moteId)
	if m.isOn():
		m.turnOff()


# -------------------------------------------
# Command line definition
class CLI(cmd.Cmd):

	def __init__(self):
		cmd.Cmd.__init__(self)
		self.prompt = '> '

	def do_quit(self, arg):
		sys.exit(1)

	def help_quit(self):
		print "syntax: quit",
		print "-- terminates the application"
		
	def do_run(self, arg):
		print "starting simulation..."
		start()
		
	def help_run(self):
		print "syntax: run",
		print "-- start the application"

	def do_step(self, arg):
		print "running..."
		step(int(arg))
		print "...pause"
		
	def help_step(self):
		print "syntax: step <number of steps>",
		print "-- continue simulation for the step number"

	def do_moteTurnOn(self, arg):
		moteTurnON(int(arg))
		print "Mote "+arg+" have been turned on!"
		
	def help_moteTurnOn(self):
		print "syntax: moteTurnOn <moteId>",
		print "-- turn on mote with moteId"

	def do_moteTurnOff(self, arg):
		moteTurnON(int(arg))
		print "Mote "+arg+" have been turned off!"
		
	def help_moteTurnOff(self):
		print "syntax: moteTurnOff <moteId>",
		print "-- turn off mote with moteId"
		
	def do_setWmax(self,args):
		params = [int(arg) for arg in args.split(' ') if arg.strip()]
		moteIDtoSend = params[0]
		paramValue = params[1]
		ttl = params[2]
		sendSetParametersMsg(moteIDtoSend,paramValue,3,ttl)			#BugFix
		#sendSetParametersMsg(moteIDtoSend,paramValue,"setWmax",ttl) old-with Bug!
	
	def help_setWmax(self):
		print "syntax: setWmax <moteIDtoSend> <paramValue> <ttl>",
		print "-- change Wmax parameter in indicated mote with ttl for sending message"
	
	def do_setWmin(self,args):
		params = [int(arg) for arg in args.split(' ') if arg.strip()]
		moteIDtoSend = params[0]
		paramValue = params[1]
		ttl = params[2]
		sendSetParametersMsg(moteIDtoSend,paramValue,4,ttl) 		#BugFix
		#sendSetParametersMsg(moteIDtoSend,paramValue,"setWmin",ttl) old-with bug!
	
	def help_setWmin(self):
		print "syntax: setWmin <moteIDtoSend> <paramValue> <ttl>",
		print "-- change Wmin parameter in indicated mote with ttl for sending message"
	
	def do_setTserver(self,args):
		params = [int(arg) for arg in args.split(' ') if arg.strip()]
		moteIDtoSend = params[0]
		paramValue = params[1]
		ttl = params[2]
		sendSetParametersMsg(moteIDtoSend,paramValue,2,ttl)				#BugFix
		#sendSetParametersMsg(moteIDtoSend,paramValue,"setTserver",ttl) old-with bug!

	def help_setTserver(self):
		print "syntax: setTserver <moteIDtoSend> <paramValue> <ttl>",
		print "-- change Tserver parameter in indicated mote with ttl for sending message"
		
	def do_setTmeasure(self,args):
		params = [int(arg) for arg in args.split(' ') if arg.strip()]
		moteIDtoSend = params[0]
		paramValue = params[1]
		ttl = params[2]
		sendSetParametersMsg(moteIDtoSend,paramValue,1,ttl) 		#BugFix
		#sendSetParametersMsg(moteIDtoSend,paramValue,"setTmeasure",ttl) old-with bug!
	
	def help_setTmeasure(self):
		print "syntax: setTmeasure <moteIDtoSend> <paramValue> <ttl>",
		print "-- change Tmeasure parameter in indicated mote with ttl for sending message"

	# shortcuts
	do_q = do_quit
	do_wmax = do_setWmax
	do_wmin = do_setWmin
	do_ts = do_setTserver
	do_tm = do_setTmeasure
	do_s = do_step
	do_on = do_moteTurnOn
	do_off = do_moteTurnOff

#
# run command line

cli = CLI()
cli.cmdloop()
