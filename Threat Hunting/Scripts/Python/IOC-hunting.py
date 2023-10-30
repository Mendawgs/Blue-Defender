import os
import platform
import subprocess
import sys
import sqlite3
import winreg
import ctypes

WINNETCMDS = {
	'10': [
		("arp", "-A"),
		("netstat", "-anob"),
		("ipconfig", "/all"),
		("netsh", "firewall", "show", "state"),
		("netsh", "firewall", "show", "config"),
		("route", "print"),
	],
}

class AdminStateUnknownError(Exception):
	"""Cannot determine whether the user is an admin."""
	pass

class Registry(object):
	# Map text to winreg hive object
	HIVE = {
		"HKEY_CURRENT_USER": winreg.HKEY_CURRENT_USER,
		"HKEY_LOCAL_MACHINE": winreg.HKEY_LOCAL_MACHINE
	}
	
	REG_TYPES = {
		"REG_SZ" : winreg.REG_SZ,
		"REG_BINARY" : winreg.REG_BINARY,
		"REG_NONE" : winreg.REG_NONE,
		"REG_DWORD" : winreg.REG_DWORD,
		"REG_QWORD" : winreg.REG_QWORD
	}

	def __init__(self):
		# Load persistence keys from a file
		self.PersistenceKeys = []
		try:
			fin = open("persistencekeys.txt", "r")
			for key in fin.readlines():
				key = key.strip('\n')
				self.PersistenceKeys.append(key)
				
		except IOError:
			print("Cannot find persistencekeys.txt file!")
	
	def QueryKeyValues(self, hive, path):
		values = []
		rootkey = winreg.OpenKey(self.HIVE[hive], path, 0, winreg.KEY_READ)
		n_values = winreg.QueryInfoKey(rootkey)[1]
		for index in range(n_values):
			query = winreg.EnumValue(rootkey, index)
			values.append(query)
		winreg.CloseKey(rootkey)
		return values
	
	def DelKeyValue(self, hive, path, valuename):
		rootkey = winreg.OpenKey(self.HIVE[hive], path, 0, winreg.KEY_ALL_ACCESS)
		winreg.DeleteValue(rootkey, valuename)
		winreg.CloseKey(rootkey)
	
	def AddKeyValue(self, hive, path, name, data, sz_type):
		rootkey = winreg.OpenKey(self.HIVE[hive], path, 0, winreg.KEY_SET_VALUE)
		winreg.SetValueEx(rootkey, name, 0, sz_type, data)
		winreg.CloseKey(rootkey)
		
	def GetLiveKeys(self):
		livekeys = {}
		for key in self.PersistenceKeys:
			# Break key into hive and path parts
			parts = key.split('\\')
			hive = parts[0]
			path = "\\".join(parts[1:])
			
			# Query Key
			try:
				livekeys[key] = self.QueryKeyValues(hive, path)
			except WindowsError:
				#print("[!] Cannot find key %s\\%s" % (hive, path))
				pass
		return livekeys
		
	def PromptDelValue(self, hive, path):
		while True:
			print("Deleting values from %s\\%s" %(hive, path))
			values = self.QueryKeyValues(hive, path)
			for index in range(len(values)):
				print("  %2d) %s - %s" %(index + 1, values[index][0], values[index][1]))
			print("   0) Done")

			try:
				option = int(input("> "))
				if option > 0 and option <= len(values):
					verify = str(input("Are you sure? Y/N\n> "))
					if verify.lower() in ["y", "yes"]:
						self.DelKeyValue(hive, path, values[option-1][0])
					elif verify.lower() in ["n", "no"]:
						print("Canceled")
					else:
						print("Unknown response...")
				elif option == 0:
					break
				else:
					print("Unknown option %d" % option)
			except ValueError:
				print("Must enter a number!")
	
	def PromptKeyContent(self):
		name = None
		data = None
		sz_type = None
		while True:
			print("[Name] %s" % name)
			print("[Data] %s" % data)
			print("[Type] %s" % sz_type)
			print("1). Set Key Name")
			print("2). Set Key Data")
			print("3). Set Key Type")
			print("0). Done")
			option = str(input("> "))
			
			if option == "1":
				print("Enter Value Name")
				name = str(input("> "))
				if len(name) == 0:
					print("Must enter something!")
			elif option == "2":
				print("Enter Value Data")
				data = str(input("> "))
				if len(data) == 0:
					print("Must enter something!")
			elif option == "3":
				print("Select Data Type")
				types = list(self.REG_TYPES.keys())
				for index in range(len(types)):
					print("  %2d) %s" %(index + 1, types[index]))
				print("   0) Cancel")
				selection = str(input("> "))
				if selection == "0":
					continue
				try:
					selection = int(selection) - 1
					sz_type = types[selection]
				except ValueError:
					print("Must enter a number")
				except IndexError:
					print("Value is out of range.")
			elif option == "0":
				break
			else:
				print("Unknown option %d" % option)
		return(name, data, sz_type)
	
	def menu(self):
		while True:
			print("1). View Persistence Keys")
			print("2). Add Persistence")
			print("3). Delete Persistence")
			print("0). Back")
			option = str(input("> "))

			if option == "1":
				livekeys = self.GetLiveKeys()
				for key in livekeys.keys():
					print("  " + key)
					for value in livekeys[key]:
						(name, data, sz_type) = value
						print("    [V] %s %s" %(name, data))
					print()
			
			elif option == "2":
				commonkeys = list(self.GetLiveKeys().keys())
				print("Select a key to modify:")
				for index in range(len(commonkeys)):
					print("  %2d) %s" %(index + 1, commonkeys[index]))
				else:
					print("  %2d) Custom" % (index + 2))
				print("  %2d) Cancel" % 0)
				
				try:
					option = int(input("> "))
					if option == 0:
						continue
					elif option > 0 and option <= len(commonkeys):
						print("Accessing %s" % commonkeys[int(option)-1])
						(name, data, sz_type) = self.PromptKeyContent()
						if name and data and sz_type:
							parts = commonkeys[int(option)-1].split('\\')
							hive = parts[0]
							path = "\\".join(parts[1:])
							if sz_type in ["REG_DWORD", "REG_QWORD"]:
								self.AddKeyValue(hive, path, name, int(data), self.REG_TYPES[sz_type])
							else:
								self.AddKeyValue(hive, path, name, data, self.REG_TYPES[sz_type])
						else:
							print("Required data was not provided")
					elif option == len(commonkeys) + 1:
						print("Accessing CUSTOM")
					else:
						print("Selection is out of range.")
				except ValueError:
					print("Value entered must be a number")
					
			elif option == "3":
				commonkeys = list(self.GetLiveKeys().keys())
				print("Select a key to modify:")
				for index in range(len(commonkeys)):
					print("  %2d) %s" %(index + 1, commonkeys[index]))
				print("  %2d) Cancel" % 0)
				
				try:
					option = int(input("> "))
					if option == 0:
						continue
					elif option > 0 and option <= len(commonkeys):
						print("Accessing %s" % commonkeys[int(option)-1])
						parts = commonkeys[int(option)-1].split('\\')
						hive = parts[0]
						path = "\\".join(parts[1:])
						self.PromptDelValue(hive, path)
					else:
						print("Selection is out of range.")
				except ValueError:
					print("Value entered must be a number")
			
			elif option == "0":
				break
			
			else:
				print("Unknown option %s" %(option))

def osdetect():
	print("You are on a %s %s Machine!" % (platform.system(), platform.release()))
	if platform.system() == "Windows":
		computer = os.getenv("computername")
		username = os.getenv("username")
		print("Your Username is: %s" % username)
		print("Your Computer is: %s" % computer)
	else:
		print("Probably linux")

def is_user_admin():
	# type: () -> bool
	"""Return True if user has admin privileges.

	Raises:
		AdminStateUnknownError if user privileges cannot be determined.
	"""
	try:
		return os.getuid() == 0
	except AttributeError:
		pass
	try:
		return ctypes.windll.shell32.IsUserAnAdmin() == 1
	except AttributeError:
		raise AdminStateUnknownError

# Logo
def logo():
	print('''

This script is to assist Administrators in Enumerating 
a Windows System for IOCs Ensure this script is run in elevation.
	''')



def main(release):
	registry = Registry()
	logo()
	osdetect()
	if is_user_admin():
		print("Running as an administrator")
	else:
		print("WARNING: Not running as an administrator")

	while True:
		print("Make a selection from the options below")
		print("1). Windows Registry Keys")
		print("2). Windows Services")
		print("3). Windows Tasks")
		print("4). Windows Processes")
		print("5). Network Information")
		print("0). Quit")
		option = str(input("> "))

		if option == "1":
			registry.menu()

		elif option == "2":
			pass
		elif option == "3":
			pass
		elif option == "4":
			pass
		elif option == "5":
			for WINNET in WINNETCMDS[platform.release()]:
				netcmd = subprocess.Popen(WINNET, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
				stdout, stderr = netcmd.communicate()
				if stdout:
					for character in stdout.decode('utf-8'):
						sys.stdout.write(character)
				if stderr:
					for character in stderr.decode('utf-8'):
						sys.stdout.write(character)
		elif option == "0":
			print("Peace")
			quit()
		
		else:
			print("Unknown option %s" %(option))

if __name__ == "__main__":
	try:
		main(platform.release())
	except KeyboardInterrupt:
		print("Closing the application")

