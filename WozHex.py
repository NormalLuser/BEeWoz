import os #delete files
import itertools #read files one byte at a time
import argparse #get command line arguments
import sys

#Script to take a BIN file with .org 1000 and 
#create a formated file/clipboard that can be
#transfered into WozMon via serial.

#Below allows the program to dump to the clipboard
#on a windows machine, comment out if you have issues
#and just copy/paste from cmd or keep PasteOut.txt
#open in Notepad ++ and it will alert and reload when 
#the file changes.
import pyperclip as pc

print("sys args:")
print(sys.argv[1:])




myFile = str('a.out') #str(sys.argv[1:])
print (myFile )
print (sys.argv[0:])
print (sys.argv[1:])
print (sys.argv[2:])
myFile =  str(sys.argv[1:])
myFile = myFile.strip("'[']'")
StartHex = 1000 #VGA Memory location
Length = 30 #Char per line

StartHexChar = str( StartHex)
StartAddress = int(StartHexChar,16)

x=0
OutHex = ""
LineOut = ""
FileOut = 'Testing'
FileOut = ''
Ourstring = ''

if os.path.exists('PasteOut.txt'):
    os.remove('PasteOut.txt')
f1 = open('PasteOut.txt', 'a')

print("StartAddress")
OutHex = hex(StartAddress)
print(OutHex)
print(OutHex[2:])
print("StartAddress")

LineOut = OutHex[2:] + ":"

with open(myFile, 'r',encoding='latin1' ) as f:
    for c in itertools.chain.from_iterable(f):
       Out = hex(ord(c))
       Out = Out[2:]
       LineOut = LineOut + " " + Out.zfill(2)
       x=x+1
       #Line Length Loop
       if x > Length:
           LineOut += "\r\n" #+ "\r\n"
           print(LineOut)
           f1.write(LineOut)
           FileOut += LineOut
           StartAddress += x
           x = 0
           OutHex = hex(StartAddress)
           LineOut = OutHex[2:] + ":"
#Print any last partial lines
LineOut = LineOut + "\r\n" #+ "\r\n" 
print(LineOut)
f1.write(LineOut)

FileOut += LineOut
FileOut += ' 1000R'
#FileOut += "\r\n"
print ('FileOut ')
print (FileOut)
txt = 'testing'
txt = LineOut
TempName = 'temp'

pc.copy(FileOut)

