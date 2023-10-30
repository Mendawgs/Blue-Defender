#!/usr/bin/env python
# --==================
# -- Imports
# --==================
import sqlite3
import hashlib
import sys
import time
import datetime
import socket
import select
import signal
import cPickle
import struct

# --==================
# -- Classes
# --==================
class Client(object):
	def __init__(self, host="127.0.0.1", port=1337):
		self.running = True
		self.port = int(port)
		self.host = host
		
		
		# Create Socket
		try:
			self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
			self.sock.connect((self.host, self.port))
		except socket.error as msg:
			sys.stdout.write("Cannot connect to %s:%d\n" %(self.host, self.port))
			sys.exit(1)
	
	def Send(self, channel, *args):
		buf = cPickle.dumps(args)
		value = socket.htonl(len(buf))
		size = struct.pack("L", value)
		channel.send(size)
		channel.send(buf)
	
	def Recv(self, channel):
		size = struct.calcsize("L")
		size = channel.recv(size)
		try:
			size = socket.ntohl(struct.unpack("L", size)[0])
		except struct.error as msg:
			return ''
		buf = ""
		while len(buf) < size:
			buf = channel.recv(size-len(buf))
		return cPickle.loads(buf)[0]
	
	def Start(self):
		while self.running:
			sys.stdout.write("> ")
			sys.stdout.flush()
			
			try:
				input_ready, output_ready, error_ready = select.select([sys.stdin, self.sock], [], [])
				for i in input_ready:
					if i == 0:
						data = sys.stdin.readline().strip()
						if data:
							self.Send(self.sock, data)
						elif i == self.sock:
							data = self.Receive(self.sock)
							if not data:
								sys.stdout.write("Terminating Client\n")
								self.running = False
								break
							else:
								sys.stdout.write(data+"\n")
								sys.stdout.flush()
			except socket.error as msg:
				sys.stdout.write(msg)
			except select.error as msg:
				sys.stdout.write(msg)
				self.sock.close()
				self.running = False
			except KeyboardInterrupt:
				sys.stdout.write("Terminating Client\n")
				self.sock.close()
				self.running = False

# --==================
# -- Functions
# --==================
def main():
	client = Client("127.0.0.1", 1337)
	client.Start()
	
if __name__ == "__main__":
	main()
