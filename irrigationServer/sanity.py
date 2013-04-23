import sys
from TOSSIM import *
from RadioSetParametersPacket import *

t = Tossim([])
m = t.mac()
r = t.radio()

t.addChannel("out", sys.stdout)

'''
for i in range(0, 2):
  m = t.getNode(i)
  m.bootAtTime((31 + t.ticksPerSecond() / 10) * i + 1)
'''
m = t.getNode(0)
m.bootAtTime(0)


'''
f = open("topo.txt", "r")
for line in f:
  s = line.split()
  if s:
    if s[0] == "gain":
      r.add(int(s[1]), int(s[2]), float(s[3]))
'''

noise = open("serverConfigFiles/meyer-heavy-short.txt", "r")
for line in noise:
  s = line.strip()
  if s:
    val = int(s)
    for i in range(4):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(4):
  t.getNode(i).createNoiseModel()

for i in range(60):
  t.runNextEvent()



''' === CODE UNDER TEST === '''
print "AA"
msg = RadioSetParametersPacket()
#msg.set_paramValue(65)
#msg.set_operationCode(3)
msg.set_moteID(1)
#msg.set_packetTTL(10)
#msg.set_lastNodeID(0)

pkt = t.newPacket()

pkt.setData(msg.data)
pkt.setType(msg.get_amType())
pkt.setDestination(0)

print "Delivering " + str(msg) + " to 0 at " + str(t.time() + 3);
pkt.deliver(0, t.time() + 3)

print "BB"
''' ====================== '''



for i in range(20):
  t.runNextEvent()