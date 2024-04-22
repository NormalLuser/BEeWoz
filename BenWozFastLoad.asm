; NormalLuser edit of the Ben Eater fork of Wozmonitor.
; Added ' L ' Binary fast Load command.
; Can transmit binary data at a full 19,200 baud without tx delays
; Usage: start address 'L' end address
;     200 L 300
; Any bytes transfered after the end address will be discarded.
; reboot needed after transfer finished.


;.setcpu "65C02"
;.segment "WOZMON"
; .ORG $8000
 .ORG $500
ACIA        = $5000 
ACIA_CTRL   = ACIA+3
ACIA_CMD    = ACIA+2
ACIA_STATUS     = ACIA+1
ACIA_DATA    = ACIA

XAML		= $24                   ; Last "opened" location Low
XAMH		= $25                   ; Last "opened" location High
STL		    = $26                   ; Store address Low
STH		    = $27                   ; Store address High
L	    	= $28                   ; Hex value parsing Low
H	    	= $29                   ; Hex value parsing High
YSAV		= $2A                   ; Used to see if hex value is given
MODE		= $2B                   ; $00=XAM, $7F=STOR, $AE=BLOCK XAM
;---------------------NormalLuser addition----------------------
MSGL        = $2C
MSGH        = $2D
;---------------------------------------------------------------
IN		= $0200			; Input buffer

RESET:
                CLD                     ; Clear decimal arithmetic mode.
                CLI
                ;---------------------NormalLuser addition----------------------
                JSR NewLine
                LDA #<MSG1
                LDX #>MSG1
                JSR SHWMSG      ; Hello Message.
                JSR NewLine
                ;---------------------------------------------------------------
                LDA     #$1F            ; 8-N-1, 19200 bps
                STA     ACIA_CTRL
                LDY     #$8B            ; No parity, no echo, no interrupts.
                STY     ACIA_CMD


NOTCR:
                CMP     #$08            ; Backspace key?
                BEQ     BACKSPACE       ; Yes.
                CMP     #$1B            ; ESC?
                BEQ     ESCAPE          ; Yes.
                INY                     ; Advance text index.
                BPL     NEXTCHAR        ; Auto ESC if line longer than 127.

ESCAPE:
                LDA     #$5C            ; "\".
                JSR     ECHO            ; Output it.

GETLINE:
                LDA     #$0D            ; Send CR
                JSR     ECHO
                LDA     #$0A            ; Send LF
                JSR     ECHO

                LDY     #$01            ; Initialize text index.
BACKSPACE:      DEY                     ; Back up text index.
                BMI     GETLINE         ; Beyond start of line, reinitialize.

NEXTCHAR:
                LDA     ACIA_STATUS     ; Check status.
                AND     #$08            ; Key ready?
                BEQ     NEXTCHAR        ; Loop until ready.
                LDA     ACIA_DATA       ; Load character. B7 will be '0'.
                STA     IN,Y            ; Add to text buffer.
                JSR     ECHO            ; Display character.
                CMP     #$0D            ; CR?
                BNE     NOTCR           ; No.

                LDY     #$FF            ; Reset text index.
                LDA     #$00            ; For XAM mode.
                TAX                     ; X=0.
SETBLOCK:
                ASL
SETSTOR:
                ASL                     ; Leaves $7B if setting STOR mode.
SETMODE:
                STA     MODE            ; $00 = XAM, $74 = STOR, $B8 = BLOK XAM.
BLSKIP:
                INY                     ; Advance text index.
NEXTITEM:
                LDA     IN,Y            ; Get character.
                CMP     #$0D            ; CR?
                BEQ     GETLINE         ; Yes, done this line.
                CMP     #$2E            ; "."?
                BCC     BLSKIP          ; Skip delimiter.
                BEQ     SETBLOCK        ; Set BLOCK XAM mode.
                CMP     #$3A            ; ":"?
                BEQ     SETSTOR         ; Yes, set STOR mode.
                CMP     #$52            ; "R"?
                BEQ     RUNPROG         ; Yes, run user program.
                ;---------------------NormalLuser addition----------------------
                CMP     #$4C            ;* "L"? LOAD Command check
                BEQ     SETMODE         ;* Yes, set LOAD mode. 
                ;---------------------------------------------------------------
                STX     L               ; $00 -> L.
                STX     H               ;    and H.
                STY     YSAV            ; Save Y for comparison

NEXTHEX:
                LDA     IN,Y            ; Get character for hex test.
                EOR     #$30            ; Map digits to $0-9.
                CMP     #$0A            ; Digit?
                BCC     DIG             ; Yes.
                ADC     #$88            ; Map letter "A"-"F" to $FA-FF.
                CMP     #$FA            ; Hex letter?
                BCC     NOTHEX          ; No, character not hex.
DIG:
                ASL
                ASL                     ; Hex digit to MSD of A.
                ASL
                ASL

                LDX     #$04            ; Shift count.
HEXSHIFT:
                ASL                     ; Hex digit left, MSB to carry.
                ROL     L               ; Rotate into LSD.
                ROL     H               ; Rotate into MSD's.
                DEX                     ; Done 4 shifts?
                BNE     HEXSHIFT        ; No, loop.
                INY                     ; Advance text index.
                BNE     NEXTHEX         ; Always taken. Check next character for hex.

NOTHEX:
                CPY     YSAV            ; Check if L, H empty (no hex digits).
                BEQ     ESCAPE          ; Yes, generate ESC sequence.
                ;---------------------------------------------------------------
                LDA #$4C        ; NormalLuser Edit
                CMP MODE        ; Adding a 'L' Load mode.
                BEQ LOAD        ; Match, LOAD a Binary file
                ;---------------------------------------------------------------        

                BIT     MODE            ; Test MODE byte.
                BVC     NOTSTOR         ; B6=0 is STOR, 1 is XAM and BLOCK XAM.

                LDA     L               ; LSD's of hex data.
                STA     (STL,X)         ; Store current 'store index'.
                INC     STL             ; Increment store index.
                BNE     NEXTITEM        ; Get next item (no carry).
                INC     STH             ; Add carry to 'store index' high order.
TONEXTITEM:     JMP     NEXTITEM        ; Get next command item.
;---------------------------------------------------------------
LOAD:           JMP LOADBINARY          ; NormalLuser Edit. Too far. Need a Branch Jump. 
;---------------------------------------------------------------
RUNPROG:
                JMP     (XAML)          ; Run at current XAM index.

NOTSTOR:
                BMI     XAMNEXT         ; B7 = 0 for XAM, 1 for BLOCK XAM.

                LDX     #$02            ; Byte count.
SETADR:         LDA     L-1,X           ; Copy hex data to
                STA     STL-1,X         ;  'store index'.
                STA     XAML-1,X        ; And to 'XAM index'.
                DEX                     ; Next of 2 bytes.
                BNE     SETADR          ; Loop unless X = 0.

NXTPRNT:
                BNE     PRDATA          ; NE means no address to print.
                LDA     #$0D            ; CR.
                JSR     ECHO            ; Output it.
                LDA     #$0A            ; LF.
                JSR     ECHO            ; Output it.
                LDA     XAMH            ; 'Examine index' high-order byte.
                JSR     PRBYTE          ; Output it in hex format.
                LDA     XAML            ; Low-order 'examine index' byte.
                JSR     PRBYTE          ; Output it in hex format.
                LDA     #$3A            ; ":".
                JSR     ECHO            ; Output it.

PRDATA:
                LDA     #$20            ; Blank.
                JSR     ECHO            ; Output it.
                LDA     (XAML,X)        ; Get data byte at 'examine index'.
                JSR     PRBYTE          ; Output it in hex format.
XAMNEXT:        STX     MODE            ; 0 -> MODE (XAM mode).
                LDA     XAML
                CMP     L               ; Compare 'examine index' to hex data.
                LDA     XAMH
                SBC     H
                BCS     TONEXTITEM      ; Not less, so no more data to output.

                INC     XAML
                BNE     MOD8CHK         ; Increment 'examine index'.
                INC     XAMH

MOD8CHK:
                LDA     XAML            ; Check low-order 'examine index' byte
                AND     #$07            ; For MOD 8 = 0
                BPL     NXTPRNT         ; Always taken.

PRBYTE:
                PHA                     ; Save A for LSD.
                LSR
                LSR
                LSR                     ; MSD to LSD position.
                LSR
                JSR     PRHEX           ; Output hex digit.
                PLA                     ; Restore A.

PRHEX:
                AND     #$0F            ; Mask LSD for hex print.
                ORA     #$30            ; Add "0".
                CMP     #$3A            ; Digit?
                BCC     ECHO            ; Yes, output it.
                ADC     #$06            ; Add offset for letter.
; WDC with transmit bug Echo routine.
; ECHO: ;Org Ben Eater echo with 1 timer loop
;                 STA     ACIA_DATA       ; Output character.
;                 PHA                     ; Save A.
;                 LDA     #$FF            ; Initialize delay loop.
; TXDELAY:        DEC                     ; Decrement A.
;                 BNE     TXDELAY         ; Until A gets to 0.
;                 PLA                     ; Restore A.
;                 RTS                     ; Return.
ECHO: ;Longer Echo delay. I had garbeled transmit at 5Mhz
                PHA                    ; Save A.
                PHY
                STA     ACIA_DATA       ; Output character.
                LDA     #$FF           ; Initialize delay loop.
                LDY     #$02           ; Extra Delay just in case
TXDELAY:        DEC                    ; Decrement A.
                BNE     TXDELAY        ; Until A gets to 0.
                DEY
                BNE     TXDELAY        ; Extra Delay time
                PLY
                PLA                    ; Restore A.
                RTS                    ; Return.


LOADBINARY:
; NormalLuser Fast Binary load.
; Quickly Load an program in Binary Format to memory.
; Usage: 2000L4000
; Will start load at location $2000 hex and stop at $4000 hex
; 0L9 -or 1 L 200 -or 100.200,L200 all work also with WOZ parsing
; Space can be saved on the messages. 
; Without any messages routine is under 70 bytes.
;
; STH and STL from Woz parser is Start address 
; H and L from Woz parser is End address 
;
            SEI             ; Turn off IRQ's, don't want/need.
            ;LDA #$1A        ; 8-N-1, 2400 baud
            ;LDA #$1C        ; 8-N-1, 4800 baud
            ;LDA #$1E        ; 8-N-1, 9600 baud
            ;LDA #$1F        ; 8-N-1, 19200 baud
            LDA #$1F        ;* Init ACIA to 19200 Baud.
            STA ACIA_CTRL
            LDA #$0B        ;* No Parity. No IRQ
            STA ACIA_CMD
            ;Below is just to display messages.
            JSR NewLine
            LDA #<MSG2
            LDX #>MSG2
            JSR SHWMSG      ; Hello Message.
            JSR NewLine
            LDA #<MSG3      ; Show address start/end for load
            LDX #>MSG3
            JSR SHWMSG      ; Space
            LDA #'$'
            JSR ECHO
            LDA STH
            JSR PRBYTE
            LDA STL
            JSR PRBYTE
            LDA #<MSG3
            LDX #>MSG3
            JSR SHWMSG      ;Space
            LDA #'$'
            JSR ECHO   
            LDA H
            JSR PRBYTE
            LDA L
            JSR PRBYTE
            
            JSR NewLine
            LDA #<MSG4
            LDX #>MSG4
            JSR SHWMSG      ;Start Data Transfer MSG.
            JSR NewLine
            ; Done with messages
            ; Load Address from WOZ
            LDA STL
            STA YSAV;TAY ;Y +  start address 0
            STZ STL
            LDY YSAV        ; Low byte in Y 

BINARY_LOOP: ; Could  copy GETCHAR here to save cycles or add timout.
            JSR GETCHAR     ; Grab Byte from ACIA
            STA (STL),Y     ; Store it at our memory location
            ; Comment out everything down to the to MEMINC if you don't want status
            ; IF YOU WANT JUST STATUS USE:
            ;  LDA #'X' 
            ;  STA ACIA_DAT ;DON'T CARE IF IT GETS DROPPED JUST SEND
            
            ; Below translates to last HEX char for a nice ASCII output
            ; Not at all needed, just looks neat.
;PRHEX      ;Move inline and just send last char      
            AND #$0F        ;Mask LSD for hex print.
            ORA #$B0        ;Add "0".
            CMP #$BA        ;Digit?
            BCC HECHO        ;Yes, output it.
            ADC #$06        ;Add offset for letter.
HECHO:    
            AND #$7F               ;*Change to "standard ASCII"
            STA     ACIA_DATA      ; Output character.
            ;sta io_putc           ; For Kowalski simulator use:

MEMINC:     ;Check memory pointer for max and INC
            LDX STH         ; Load our high byte
            CPX H           ; Does it match our max?
            BNE NO_HMATCH   ; Nope, just normal inc
            CPY L           ; Does the low byte match our max?
            BNE NO_HMATCH   ; Nope, just normal inc
            JMP BINARY_DONE ; MATCH! We are done!
NO_HMATCH:
            INY ;Inc low byte
            BNE BINARY_LOOP ;jump if not a roll-over
            INC STH ;Roll-over. Inc the high byte.
            JMP BINARY_LOOP
 
BINARY_DONE:; Data transfer Done
            JSR NewLine     ;New line.
            LDA #<MSG5
            LDX #>MSG5
            JSR SHWMSG      ;Show Finished msg

BINARYEXTRA:; Care about garbage data at end?
            ; *For Streaming Test,jmp back to top 
            ; JMP LOOPMEMORY -If you want to stream, like to the screen buffer.
            ; Could RTS here, but we could overwrite data.
            ; Could  copy GETCHAR here to save cycles or add timout.
            JSR GETCHAR
            LDA #'X'
            JSR ECHO
            JMP BINARYEXTRA
 
GETCHAR:
            LDA ACIA_STATUS     ; See if we got an incoming char
            AND #$08        ; Test bit 3
            ;LDA io_getc    ; For Kowalski simulator use
            BEQ GETCHAR     ; Wait for character
            LDA ACIA_DATA    ; Load char
            RTS

NewLine
            PHA
            LDA #$0D
            JSR ECHO        ;* New line.
            LDA #$0A
            JSR ECHO
            PLA
            RTS
 
SHWMSG      ; Changed msg routine to save some bytes
            ; Loads MSG Low byte A High byte X
            ; A and Y are changed.
            ; Usage:
            ; LDA #<MSG1
            ; LDX #>MSG1
            ; JSR SHWMSG

            STA MSGL
            STX MSGH
            ;PHA ; I only msg when A and Y are unused.
            ;PHY ; Save the bytes for now
            ;jsr NewLine ;Could always do a New Line if wanted
            LDY #$0
.PRINT      LDA (MSGL),Y
            BEQ .DONE
            JSR ECHO
            INY 
            BNE .PRINT
.DONE       ;PLY
            ;PLA
            RTS 

MSG1        .byte "Ben Eater WozMon - Fast Binary Load",0
MSG2        .byte "Load Data Start |  Data End",0
MSG3        .byte "        ",0
MSG4        .byte " -Start Binary File Transfer- ",0
MSG5        .byte " All Bytes Imported   -Reset- ",0
MSG6        .byte " -Fast Binary Load by NormalLuser-",0

; Want to save a few bytes on the messages?
; MSG1        .byte "BEWoz FL",0
; MSG2        .byte "Load",0
; MSG3        .byte " : ",0
; MSG4        .byte "File",0
; MSG5        .byte "Done",0

;If putting on ROM
; NMI:
;             RTI
; IRQ:
;             RTI
;    .org $FFFA
;    .word NMI
;    .word RESET
;    .word IRQ
