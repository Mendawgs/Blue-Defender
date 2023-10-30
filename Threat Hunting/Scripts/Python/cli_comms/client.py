#!/usr/bin/env python
import curses
import curses.panel
import time

class CLIGUI(object):
	def __init__(self):
		self.screen = None
		self.command_history = []
		self.current_command = []
		self.temp_command = []
		self.cursor_position_cmdwin = type('obj', (object,), {'row':0, 'col':0})
	
	def command_prompt(self, window):
		#curses.curs_set(0)
		rows, cols = window.getmaxyx()
		window.clear()
		window.border()
		window.addnstr(1, 1, "> " + "".join(self.current_command), cols-2)
		window.move(1 + self.cursor_position_cmdwin.row, 3 + self.cursor_position_cmdwin.col)
		window.refresh()
		
	def output_area(self, window, title=""):
		rows, cols = window.getmaxyx()
		window.clear()
		window.border()
		window.addnstr(0, (cols/2)-(len(title)/2), title, cols-2)
		window.refresh()

	def run(self, screen):
		error = "Screen is too small"
		
		screen_rows, screen_cols = screen.getmaxyx()
		previous_rows, previous_cols = screen.getmaxyx()
		
		cmdwin_rows = 7
		outwin = curses.newwin(screen_rows-cmdwin_rows, screen_cols, 0, 0)
		cmdwin = curses.newwin(cmdwin_rows, screen_cols, screen_rows-cmdwin_rows, 0)
		screen.clear()
		screen.refresh()
		self.output_area(outwin, "1$3B3RG v0.01")
		self.command_prompt(cmdwin)

		while True:
			# Check to see if window is resized
			screen_h, screen_w = screen.getmaxyx()
			if screen_rows < 15 or screen_cols < 40:
				screen.clear()
				screen.addnstr(screen_rows/2, center_text(error, screen_cols, 1), error, screen_cols - 2)
			elif screen_rows != previous_rows or screen_cols != previous_cols:
				screen.clear()
				curses.resizeterm(screen_rows, screen_cols)
				outwin.resize(screen_rows-cmdwin_rows, screen_cols)
				cmdwin.resize(cmdwin_rows, screen_cols)
				cmdwin.mvwin(screen_rows-cmdwin_rows, 0)
				
			previous_rows = screen_rows
			previous_cols = screen_cols
			
			# Get keystroke
			key = screen.getch()
			curses.flushinp()
			if key == curses.KEY_UP:
				pass
			elif key == curses.KEY_DOWN:
				pass
			elif key == curses.KEY_RIGHT:
				if self.cursor_position_cmdwin.col < len(self.current_command):
					self.cursor_position_cmdwin.col += 1
			elif key == curses.KEY_LEFT:
				if self.cursor_position_cmdwin.col > 0:
					self.cursor_position_cmdwin.col -= 1
			elif key == ord('\n'):
				self.command_history.append(self.current_command)
				self.current_command = []
				self.temp_command = []
				self.cursor_position_cmdwin.row = 0
				self.cursor_position_cmdwin.col = 0
			elif key == curses.KEY_BACKSPACE:
				if self.cursor_position_cmdwin.col > 0:
					self.cursor_position_cmdwin.col -= 1
					self.current_command.pop(self.cursor_position_cmdwin.col)
			elif key >= 32 and key <= 126:
				if self.cursor_position_cmdwin.col < len(self.current_command):
					self.current_command.insert(self.cursor_position_cmdwin.col, chr(key))
				else:
					self.current_command.append(chr(key))
				self.cursor_position_cmdwin.col += 1
			
			# Drawing Routines
			screen.refresh()
			self.output_area(outwin, "1$3B3RG v0.01")
			self.command_prompt(cmdwin)
			
			# Delay
			#time.sleep(0.1)

def center_text(text, screen_w, padding):
	return (screen_w / 2) - (padding * 2) - (len(text) / 2)		

def main():
	gui = CLIGUI()

	try:
		curses.wrapper(gui.run)
	except KeyboardInterrupt:
		return -1
	

if __name__ == "__main__":
	main()	

