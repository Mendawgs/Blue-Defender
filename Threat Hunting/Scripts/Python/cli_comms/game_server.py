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
import curses

# --==================
# -- Classes
# --==================

class UserAccount(object):
	def __init__(self, uid, name, pass_hash, descriptiopn, last_login, score):
		self.id = uid
		self.name = name
		self.pass_hash = pass_hash
		self.description = descriptiopn
		self.last_login = last_login
		self.score = score
	
	def __repr__(self):
		return 'id[%d] name[%s] hash[%s] desc[%s] last[%s] score[%d]' %(self.id, self.name, self.pass_hash, self.description, self.last_login, self.score)

	def __str__(self):
		pass

class UserSession(object):
	def __init__(self, database, stdout=sys.stdout.write, stdin=sys.stdin.readline):
		self.database = database
		self.stdout = stdout
		self.stdin = stdin
		self.user = None
		self.socket = None
		self.address = None

class Server(object):
	def __init__(self, database, host="0.0.0.0", port=1337, backlog=30):
		# SQLite3 Database 
		self.database = database
		
		# Clients
		self.clients = 0
		self.clientmap = {}
		
		# Input socket list
		self.client_inputs = []
		
		# Output socket list
		self.client_outputs = []
		
		# Create Socket
		self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
		self.sock.bind((host, port))
		self.sock.listen(backlog)
	
		# Custom Signal Handler
		signal.signal(signal.SIGINT, self.SignalHandler)

	def SignalHandler(self):
		sys.stdout.write("Shutting down server...\n")
		self.SendAll(None, "Shutting down server...\n")
		self.sock.close()
	
	def Serve(self):
		sys.stdout.write("Server listening on port %s\n" %(self.sock.getsockname()[1]))
		self.client_inputs = [self.sock, sys.stdin]
		self.client_outputs = []
		
		running = True
		while running:
			try:
				input_ready, output_ready, error_ready = select.select(self.client_inputs, self.client_outputs, [])
			except select.error as msg:
				sys.stdout.write(msg)
			except socket.error as msg:
				sys.stdout.write(msg)
			
			# Get stdin data from clients & server
			for sock in input_ready:
				if sock == self.sock:
					client, address = self.sock.accept()
					sys.stdout.write("[+] Client %d from %s connected\n" %(client.fileno(), address))
					
					# Create new user session
					session = UserSession(self.database, self.Send, self.Recv)
					
					# Record client information
					self.clients += 1
					self.client_inputs.append(client)
					self.clientmap[client] = session
					
					# Send join message to other clients
					message = "\n[?] %s@%s joined.\n" %(session.user.name, session.address[0])
					self.SendAll(client, message)
					
				elif sock == sys.stdin:
					command = sys.stdin.readline().strip()
					if command == "/quit":
						running = False
					elif command == "/list":
						sys.stdout.write("Connected Clients\n")
						for client in self.clientmap:
							sys.stdout.write(client)
					elif command == "/help":
						sys.stdout.write("/quit - Shutdown Server\n")
						sys.stdout.write("/list - Show Connected Clients\n")
						sys.stdout.write("/help - Help Menu\n")
					else:
						sys.stdout.write("Type /help for help\n")
				else:
					try:
						data = self.Recv(sock)
						if data:
							message = "\n#[%s]> %s" %(self.clientmap[sock].name, data)
							self.SendAll(sock, message)
						else:
							sys.stdout.write("[-] Client %d from %s disconnected\n"%(sock.fileno(), self.clientmap[sock].address,))
							self.clients -= 1
							sock.close()
							self.client_inputs.remove(sock)
							self.client_outputs.remove(sock)
							
							# Send join message to other clients
							message = "\n[?] %s@%s left.\n" %(elf.clientmap[sock].name, elf.clientmap[sock].address[0])
							self.SendAll(None, message)
					except socket.error as msg:
						self.client_inputs.remove(sock)
						self.client_outputs.remove(sock)

		# End of server loop, shutdown socket
		self.sock.close()
						
	def SendAll(self, sender_socket, message):
		for client in self.client_outputs:
			if sender_socket == client:
				continue
			self.Send(out, message)
	
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


	def UserPromptName(self):
		while True:
			self.Print('Enter Name: ')
			name = self.Input().strip()
			if not name.isalpha():
				self.Print('%s has non-alphabetic characters.\n' % name)
			else:
				return name

	def UserPromptPassword(self, min_length=4):
		while True:
			self.Print('Enter Password: ')
			password = self.Input().strip()
			if len(password) < min_length:
				self.Print("Password should be %d characters or more.\n" % min_length)
			else:
				return hashlib.md5(password).hexdigest()

	def UserPromptDescription(self):
		while True:
			self.Print('Enter Player Discription: ')
			description = self.Input().strip()
			if len(description) < 1:
				self.Print("Enter something for the description\n")
			else:
				return description

	def UserPromptNew(self):
		while True:
			name = self.UserPromptName()
			if self.database.GetAccount(name):
				self.Print("Account already exists, login to edit.\n")
				return False
			else:
				break
		
		pass_hash = self.UserPromptPassword()
		description = self.UserPromptDescription()
		self.user = UserAccount(-1, name, pass_hash, description, datetime.datetime.now(), 0)
		self.database.AddAccount(user)
		return True
	
	def Login(self):
		attempts = 3
		name = self.UserPromptName()
		user = self.database.GetAccount(name)
		if user:
			while attempts > 0:
				pwhash = self.UserPromptPassword(min_length=0)
				if pwhash == user.pass_hash:
					self.user = user
					return user
				else:
					attempts -= 1
					self.Print("Incorrect password, try again.\n")
			if attempts == 0:
				self.Print("Login failed.\n")
		else:
			self.Print("Username not found.\n")
		return None

	def Main(self):
		while True:
			self.Print("1) Login\n")
			self.Print("2) New Account\n")
			self.Print("0) Exit\n")
			self.Print("> ")
			choice = self.Input()
			if choice == "1":
				try:
					self.Login()
				except KeyboardInterrupt as msg:
					self.Print("\nAction Canceled\n")
			elif choice == "2":
				try:
					self.UserPromptNew()
				except KeyboardInterrupt as msg:
					self.Print("\nAction Canceled\n")
			elif choice == "0":
				break

class Database(object):
	def __init__(self, filename="master.sqlite"):
		self.filename = filename
		create_users_table = """
		CREATE TABLE IF NOT EXISTS users (
			uid integer PRIMARY KEY,
			name text NOT NULL,
			pass_hash text NOT NULL,
			description text NOT NULL,
			last_login text NOT NULL,
			score integer NOT NULL
		);
		"""
		try:
			sql_db = sqlite3.Connection(filename)
			cursor = sql_db.cursor()
			cursor.execute(create_users_table)
			sql_db.close()
		except sqlite3.Error as e:
			print(e)
	
	def AddAccount(self, user):
		try:
			sql_db = sqlite3.Connection(self.filename)
			cursor = sql_db.cursor()
			cursor.execute(
				'INSERT INTO users (uid, name, pass_hash, description, last_login, score) VALUES(?, ?, ?, ?, ?, ?)', 
				(None, user.name, user.pass_hash, user.description, user.last_login, user.score)
			)
			sql_db.commit()
			sql_db.close()
			return True
		except sqlite3.Error as e:
			print(e)
			return False
	
	def GetAccount(self, username):
		account = None
		try:
			sql_db = sqlite3.Connection(self.filename)
			cursor = sql_db.cursor()
			cursor.execute('SELECT * FROM users WHERE name=? COLLATE NOCASE', (username,))
			rows = cursor.fetchall()
			sql_db.close()
			if len(rows) == 1:
				account = UserAccount(rows[0][0], rows[0][1], rows[0][2], rows[0][3], rows[0][4], rows[0][5])
			else:
				raise ValueError("Returned more than one account\n%s"%str(rows))
		except sqlite3.Error as e:
			print(e)
		return account

# --==================
# -- Functions
# --==================
def main():
	database = Database()
	server = Server(database, host="0.0.0.0", port=1337, backlog=30)
	server.Serve()
	
	#session = UserSession(database, sys.stdout.write, sys.stdin.readline)
	#session.Main()
	
if __name__ == "__main__":
	main()
