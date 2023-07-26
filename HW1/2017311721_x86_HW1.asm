[org 0x7c00]		; Assembly command
					; Let NASM compiler know starting address of memory
					; BIOS reads 1st sector and copied it on memory address 0x7c00
[bits 16] 			; Assembly command
					; Let NASM compiler know that this code consists of 16its

[SECTION .text] 	; Text section

START:				; Boot loader(1st sector) starts
    cli				; Clear interrupt
    xor ax, ax		; Initialize ax register
	mov ax, 0x8FF
	mov ds, ax		; Set data segment register
	mov bx, 0x00
	mov al, 0x01

;-----------Following code is for filling some values in the memory-------------;

mem:																		
	mov byte [ds:bx], al
	cmp bx, 0xFF
	je test_end
	jmp re

re:
	add al, 0x02 
	add bx, 0x01
	jmp mem
	
test_end:
	cli
	xor ax, ax
	mov ds, ax
    mov ax, 0xB800
    mov es, ax 
	
;-------------------------------------------------------------------------------;

	sti						; Set interrupt
	
    call load_sectors 		; Load rest sectors
    jmp sector_2

load_sectors:			 	; Read and copy the rest sectors of disk

   	push es
    xor ax, ax
    mov es, ax									; es=0x0000
 	mov bx, sector_2 							; es:bx, Buffer Address Pointer
    mov ah,2 									; Read Sector Mode
    mov al,(sector_end - sector_2)/512 + 1  	; Sectors to Read Count
    mov ch,0 									; Cylinder Number=0
    mov cl,2 									; Sector Number=2
    mov dh,0 									; Head=0
    mov dl,0 									; Drive=0, A:drive
	int 0x13 									; BIOS interrupt
												; Services depend on ah value
    pop es
    ret

times   510-($-$$) db 0 		; $ : current address, $$ : start address of SECTION
								; $-$$ means the size of source
dw      0xAA55 					; signature bytes
								; End of Master Boot Record(1st Sector)
								
		

sector_2:						; Program Starts
	mov ax, 0x8FF
	mov ss, ax
	mov sp, 0x10
	mov ax, 0x1234
	push ax
	mov bx, 0x8FFC
	mov dl, byte [ds:bx]
	add ah, dl
	xchg al, bh
	mov bx, 0x8FFD
	mov word[ds:bx], ax
	sub al, ah
	mov bx, 0x8FFF
	mov byte[ds:bx], al

	
;---------------------------------------------------------------------------;	
; Print your Name in VMware screen											    ;
; Print your ID in VMware screen											    ;
; Print the value(word size) in the Stack Pointer after executing the above code;
;																				;
;																				;
;																				;
;																				;
;																				;
;																				;
;-------------------------------------------------------------------------------;

mov ecx, 0		;counter setting
mov esi, ID
mov edi, 160	;second line
mov ebx, 0		;base register 	+2	+4	+6
mov edx, 12		;light red

print_ID:
;db
	mov eax, 0
	mov al,[si+bx]	;one byte of the string
	mov ah, dl		;color setting
;print
	mov word [es:di], ax	;print one byte of the string
	add ebx, 1
	add edi, 2
	cmp al, 0
	jne print_ID 
	
	
mov esi, NAMEE
mov edi, 320	;second line
mov ebx, 0		;base register 	+2	+4	+6
mov edx, 14		;Yellow

print_NAMEE:
;db
	mov eax, 0
	mov al,[si+bx]	;one byte of the string
	mov ah, dl		;color setting
;print
	mov word [es:di], ax	;print one byte of the string
	add ebx, 1
	add edi, 2
	cmp al, 0
	jne print_NAMEE 
		
mov esi, Answer
mov edi, 480	;second line
mov ebx, 0		;base register 	+2	+4	+6
mov edx, 14		;Yellow

print_Answer:
;db
	mov eax, 0
	mov al,[si+bx]	;one byte of the string
	mov ah, dl		;color setting
;print
	mov word [es:di], ax	;print one byte of the string
	add ebx, 1
	add edi, 2
	cmp al, 0
	jne print_Answer
	
	pop bx				;stack value pop
	

stack_VAL:
	mov ax, 0xF000		;bx = 1110_0100_1100_0001
	and ax, bx			;ax = 1111_0000_0000_0000
	shr ax, 12			;ax = 1110_0000_0000_0000
	cmp al, 0xA			;ax = 0000_0000_0000_1110
	jae above_TEN
	add al, 0x30		; +0x30	(ASCII Offset)
	mov word [es:di], ax	;print one byte of the string
	
print:
	mov ah, dl	;color setting, al <- data
	mov word[es:di], ax
	add edi, 2
	add ecx, 1
	shl bx, 4
	cmp ecx, 4
	je exit
	jmp stack_VAL
	
	
above_TEN:
	add al, 0x37
	jmp print

exit:
;----------------------Name and ID here-----------------------------;

ID  db 'ID : 2017311721',0
NAMEE db 'NAME : Moon Young Jin',0
Answer db 'A value in Stack Pointer(word size) : ',0

;-------------------------------------------------------------------------------;
	
sector_end:

