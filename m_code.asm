#make_bin#

; BIN is plain binary format similar to .com format, but not limited to 1 segment;
; All values between # are directives, these values are saved into a separate .binf file.
; Before loading .bin file emulator reads .binf file with the same file name.

; All directives are optional, if you don't need them, delete them.

; set loading address, .bin file will be loaded to this address:
#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

; set entry point:
#CS=0000h#	; same as loading segment
#IP=0000h#	; same as loading offset

; set segment registers
#DS=0000h#	; same as loading segment
#ES=0000h#	; same as loading segment

; set stack
#SS=0000h#	; same as loading segment
#SP=FFFEh#	; set to top of loading segment

; set general registers (optional)
#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here   

        jmp start1
        db 381 dup(0)   
        
;IVT entry for 60h  
        dw isr_60
        dw 0000
        db 636 dup(0)                    
        
        
;main program
start1:	cli
;initialise ds,es,ss to start of RAM
        mov ax,0200h
        mov ds,ax
        mov es,ax
        mov ss,ax
        mov sp,0FFFEh 

;initialize 8255
		mov al, 10010001b		;PortA: i/p, PortCd: i/p, PortB: o/p, PortCu: o/p, Mode 0
		out 36h, al
		
;initialize 8253[1] mock, base address 10h
		mov al, 00110100b		;Mode 2 counter 0 binary
		out 16h, al
		mov al, 01110100b		;Mode 2 counter 1 binary
		out 16h, al
		mov al, 10110100b		;Mode 2 counter 2 binary
		out 16h, al
;initialize 8253[2] mock, base address 20h
		mov al, 00010100b		;mode 2 counter 0 binary
		out 26h, al
		mov al, 01011010b		;mode 5 counter 1 binary
		out 26h, al
		mov al, 10011010b		;mode 5 counter 2 binary
		out 26h, al


;CW initialisations for the original counter set is the same as that of the mock counter set		
;initialize 8253[1], base address 50h 
		mov al, 00110100b
		out 56h, al
		mov al, 01110100b
		out 56h, al
		mov al, 10110100b
		out 56h, al
;initialize 8253[2], base address 60h
		mov al, 00010100b
		out 66h, al
		mov al, 01011010b
		out 66h, al
		mov al, 10011010b
		out 66h, al
		
;Load counts for mock, base addresses: 10h, 20h

mcnt0_0	equ	10h
mcnt0_1 equ 12h
mcnt0_2	equ	14h
mcnt1_0	equ	20h
mcnt1_1	equ	22h
mcnt1_2	equ	24h

		mov al, 01010001b	;LSB for 50001D, have to do a 16-bit write
		out mcnt0_0, al
		mov al, 11000011b	;MSB for 50001D
		out mcnt0_0, al
		
		mov al, 00001011b	;LSB for 11D, have done a 16-bit write
		out mcnt0_1, al		;compatibility with original counter
		mov al, 00000000b	;MSB for 11D
		out mcnt0_1, al
		
		mov al, 00000110b	;LSB for 6D
		out mcnt0_1, al
		mov al, 00000000b
		out mcnt0_1, al		;MSB for 6D
		
		mov al, 25D			;8-bit write, gives OUT pulse every 24 second
		out mcnt1_0, al
		
		mov al, 19D			;8-bit write
		out mcnt1_1, al		;Out pulse 18 seconds after a pulse from mcnt_10

		mov al, 12D			;8-bit write, 11 seconds
		out mcnt1_2, al		;every 11 seconds
;Completed loading count for mock

;Load counts for mock



;Completed loading count for mock

;initialize 8259, base address 40h
	;check level triggering	mov al, 00010011b
		out 40h, al
		mov al, 00111100b
		out 42h, al
		mov al, 00000001b
		out 42h, al
	;only mock counter int is enabled, original is in ir5. only ir0 is enabled here.
		mov al, 11111110b
		out 42h, al
		
		sti

;8255 starting addrsess 30h
;read i/p from PA
;PortA: i/p, PortCd: i/p, PortB: o/p, PortCu: o/p, Mode 0
;i/p bit 1 means watering is needed
isr_60:	in	al,30h		;read i/p from PA
		;call delay_0.04s
		
		mov bl,al		;store Pa0-Pa7 in bl
		out 32h,al		;write i/p from Pa to Pb
		
		in al,34h		;read from PC, only PC4-7 are read
		;call delay_0.04s
		mov bh,al		;lower nibble of bh stores the input PC0-PC3
		and bh,0fh		;upper nibble of bh made 0000h
		mov cl,4
		ror al,cl		;switch nibbles of al register
		out 34h,al		;write PC, only PC4-7 are written, pc0-3 directed to pc4-7
		
		mov cx,0
		cmp bx,cx		;check if all of them are zero
		jne isr_60

		iret