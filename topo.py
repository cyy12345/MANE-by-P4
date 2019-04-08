#!/usr/bin/python
from mininet.net import Mininet
from mininet.topo import Topo
from mininet.log import setLogLevel, info
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.node import RemoteController

from p4_mininet import P4Switch, P4Host

import argparse
from time import sleep
import os
import subprocess

_THIS_DIR = os.path.dirname(os.path.realpath(__file__))
_THRIFT_BASE_PORT = 22222

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral_exe',help='Path to behavioral executable',
					type=str, action="store", required=True)
parser.add_argument('--json',help='Path to JSON config file',
					type=str, action="store",required=True)
parser.add_argument('--cli',help='Path to BM CLI',
					type=str,action="store",required=True)

args = parser.parse_args()

class MyTopo(Topo):
	def __init__(self, sw_path, json_path, nb_hosts, nb_switches, links, **opts):
		Topo.__init__(self, **opts)



		for i in xrange(nb_switches):
			switch = self.addSwitch('s%d' % (i+1),
									sw_path=sw_path,
									json_path=json_path,
									thrift_port = _THRIFT_BASE_PORT+i,
									pcap_dump= True,
									debugger=True,
									log_console=True,
									device_id = i)
		for h in xrange(nb_hosts):
			host = self.addHost('h%d'%(h+1),mac='00:00:00:00:00:0%d'%(h+1))

		for a,b in links:
			self.addLink(a, b)

def read_topo():
	nb_hosts=0
	nb_switches=0
	links=[]
	with open("topo.txt","r") as f:
		line = f.readline()[:-1]
		w, nb_switches = line.split()
		assert(w=="switches")
		line = f.readline()[:-1]
		w,nb_hosts = line.split()
		assert(w=="hosts")
		for line in f:
			if not f:break
			a,b = line.split()
			links.append((a,b))
	return int(nb_hosts),int(nb_switches),links


def main():
	nb_hosts,nb_switches,links = read_topo()

	topo = MyTopo(args.behavioral_exe,args.json,nb_hosts,nb_switches,links)

	#c0 = RemoteController("onos",ip="127.0.0.1")

	net = Mininet(topo = topo,
				host = P4Host,
				switch = P4Switch,
				controller = None
				)
	
	
	net.start()

	for n in xrange(nb_hosts):
		h = net.get('h%d' % (n+1))

		for i in range(6):
			if i!=n:
				h.cmd("arp -s 10.0.0.%d 00:00:00:00:00:0%d" %((i+1),(i+1)))

	for i in xrange(nb_switches):
		cmd = [args.cli,"--json",args.json,
			"--thrift-port",str(_THRIFT_BASE_PORT+i)]
		with open('commands.txt',"r") as f:
			print " ".join(cmd)
			try:
				output = subprocess.check_output(cmd, stdin=f)
				print output
			except subprocess.CalledProcessError as e:
				print e
				print e.output

	sleep(1)

	print "Ready !"

	
	#net.get("h1").cmd("vlc-wrapper -vvv test.264 --sout "+'\n#'+"\"transcode{vcodec=h264,vb=0,scale=0,acodec=mpga,ab=128,channels=2,samplerate=44100}:rtp{dst=172.16.1.100,port=1212,mux=ts,ttl=10}\" ")
	
	#net.get("h3").cmd("vlc-wrapper rtp://@:1212")

	CLI(net)
	net.stop()

if __name__ == '__main__':
	setLogLevel('info')
	main()