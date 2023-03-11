
# BEeWoz 
WozMon for the Ben Eater 6502 with a ACIA add-on 
Pretty sure I got it:
https://github.com/kissmywhat/sd/blob/master/woz_sd.asm

Details about ACIA added to $4000 came from this fine person: 
mike42 https://mike42.me/blog/2021-07-adding-a-serial-port-to-my-6502-computer
Also Wilsonminesco, and the 6502 org threads.

I'm using a free version of Tera Term for the RS232 connection.
A cheap USB to RS232 adapter is used, it crashes sometimes and needs
to be unplugged/plugged back in. Tera Term sometimes needs to be restarted as well.
I've slowed down communication so that nothing is dropped when pasting.
Experiment with this when you are doing longer programs to see how fast it works for you.

Got to Setup→ Serial Port
And change Transmit delay to ‘30’ for both char and line.
You will need to make the line delay longer if you use EhBASIC as it needs a moment to process the 
entered line on longer programs. WozMon itself is consistent.

You may also need to go to Setup→Additional Settings- [Copy and Paste]
and change Paste delay per line to something like 170.

Now you can use Notepad++ or VS Code whatever editor you like and copy paste over to the 6502.

Once running you can do things like see memory at and address:

2000

Or change it:
2000: FF

Or change a row of data:
2000: FF FF FF FF FF FF FF FF

You can also run programs stored at locations in memory. 
These can be programs already loaded on the  ROM.
If you compile using the included bin files the below examples will work. 
You run a program by entering the location followed by R like this:
 
8440 R 

or 

8400 R 

or 

8470 R 

 
Or, you can load a program into ram just like you changed a row of data, but instead with the compiled bin program. 
If the program ends with a RTS and the registers and flags are pushed/pulled it will drop back to the monitor program.


1000: 08 a2 20 a9 d0 85 fb a9 ad 85 fc a9 00 85 fd a9 20 85 fe a0 00 b1 fb 91 fd c8 d0 f9 e6 fc e6 fe a5 fe ca d0 f0 ea 28 60 
1000 R


Here is the code that created the bin source for the above paste-able Woz file.

 PHP
 
 LDX #32 ;32 'lines' as each line is 255 IE 2 lines each
 
 ;set our source memory address to copy from
 
 ;$ADD0
 
 lda #$D0 
 
 sta $FB
 
 lda #$AD
 
 sta $FC
 
 lda #$00 ;set our destination memory to copy to, $2000, WRAM
 
 sta $FD
 
 lda #$20
 
 sta $FE
 
 ldy #$00 ;reset x and y for our loop
 
 
LoopI: ;Image loop

 lda ($FB),Y ;indirect index source memory address, starting at $00
 
 sta ($FD),Y ;indirect index dest memory address, starting at $00
 
 INY
 
 bne LoopI ;loop until our dest goes over 255
 
 inc $FC ;increment high order source memory address, starting at $80
 
 inc $FE ;increment high order dest memory address, starting at $60
 
 lda $FE ;load high order mem address into a
 
 ;copy 68 lines
 
 DEX
 
 bne LoopI ;if we're not there yet, loop
 
 NOP
 
 PLP
 
 RTS


It needs to be converted from it’s bin format.

The below program will convert a bin file and 
export a file with the start location of
$1000


WozHex.py:

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
pc.copy(FileOut)
 


You run this with python with the name of the output bin file you wish to convert.

py WozHex.py a.out

a.out is the default for Vasm. You can change a.out to RomName.bin




