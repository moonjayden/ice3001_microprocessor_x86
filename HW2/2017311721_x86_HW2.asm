[org 0x7c00]		; Assembly command
					; Let NASM compiler know starting address of memory
					; BIOS reads 1st sector and copied it on memory address 0x7c00
[bits 16] 			; Assembly command
					; Let NASM compiler know that this code consists of 16its

[SECTION .text] 	; Text section

START:				; Boot loader(1st sector) starts
    cli				; Clear interrupt
    xor ax, ax		; Initialize ax register
    mov ds, ax		; Base address of data segment

;----------------------------------------------
;																  ;
	mov ax, 0xB800
    mov es, ax 			; memory address of printing on screen
	
    mov al, byte [MSG_test]
    mov byte [es : 80*2*0+2*0], al
    mov byte [es : 80*2*0+2*0+1], 0x02
	mov al, byte [MSG_test+1]
    mov byte [es : 80*2*0+2*1], al
    mov byte [es : 80*2*0+2*1+1], 0x02
	mov al, byte [MSG_test+2]
    mov byte [es : 80*2*0+2*2], al
    mov byte [es : 80*2*0+2*2+1], 0x02
	mov al, byte [MSG_test+3]
    mov byte [es : 80*2*0+2*3], al
    mov byte [es : 80*2*0+2*3+1], 0x02
;																  ;
;------------------------------------------------------------------

	sti						; set interrupt
	
    call load_sectors 		; load rest sectors
    jmp sector_2

load_sectors:			 	; read and copy the rest sectors of disk

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
	
MSG_test: db'test',0

times   510-($-$$) db 0 		; $ : current address, $$ : start address of SECTION
								; $-$$ means the size of source
dw      0xAA55 					; signature bytes
								; End of Master Boot Record(1st Sector)
				
sector_2:						; Program Starts
	cli		
	
	
;---------------------------------------------------------------
;																  ;
;Load the address of GDT to GDTR								  ;
	lgdt [gdt_ptr]	;load the address of GDT to GDTR
;																  ;
;------------------------------------------------------------------

;---------------------------------------------------------------
;																  ;
;Control Register 0(CR0) setting								  ;
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax	;PE=1
;																  ;
;------------------------------------------------------------------

	mov bx, 0x10	
	mov ds, bx
	mov es, bx
	mov fs, bx
	mov gs, bx
	mov ss, bx
	
	jmp SYS_CODE_SEL_1:Protected_START	; jump Protected_START
										; Remove prefetch queue
;---------------------------------------------------------------		
Protected_START:	; Protected mode starts
[bits 32]			; Assembly command
					; Let NASM compiler know that this code consists of 32its
					
	;jmp $							; jump to current address,
									; infinite loop
									
									
;-----------------------------------------------------------------
;																  ;
; Store the value of Selector which indicates the domain 		  ;
; of Video Memory on ES Register								  ;
	mov ax, VIDEO_SEL
	mov es, ax
;																  ;
;------------------------------------------------------------------

	call print_protected	
	call print_cs_Protected
	;jmp $							; for first problem
									; after finishing making GDT and loading it,
									; remove the remark ';'
									
	
;-----------------------------------------------------------------------
; Put base address of ldt to ldtr descriptor					  ;
; Load ldt														  ;
; 											 					  ;
	mov ax, LDTR
	lldt ax
;																  ;
;------------------------------------------------------------------	

	jmp 0x04:LDT0_Start			; for second problem
									; after finishing making LDT and loading it,
									; remove the remark ';'

LDT0_Start:

	call print_cs_LDT0_Start	
	
	jmp $							; for second problem
									; after finishing making LDT and loading it,
									; remove the remark ';'	
	
;----------------------------------------------------------------------------	
MSG_Protected_MODE_Test: db'Protectd Mode',0
CS_LDT0_Start: db'CS register of LDT0_Start : ',0
CS_Protected_Start: db'CS register of Protected_Start : ',0
temp: dd 0

printf_s:
	mov cl, byte [ds:eax]
	mov byte [es: edi], cl
	inc edi
	mov byte [es: edi], bl
	inc edi

	inc eax								
	mov cl, byte [ds:eax]
	mov ch, 0
	cmp cl, ch							
	je printf_end						
	jmp printf_s	

printf_end:
	ret
	
printf_n:
	inc eax
	inc eax
	inc eax
	mov bh, 0x01
	jmp printf2
printf2:
	mov cl, byte [ds:eax]
	mov dl, cl
	shr dl, 4
	cmp dl, 0x09
	ja a1
	jmp a2
printf3:
	mov byte [es: edi], dl
	inc edi
	mov byte [es: edi], bl
	inc edi
	mov dl, cl
	and dl, 0x0f
	cmp dl, 0x09
	ja a3
	jmp a4
printf4:
	mov byte [es: edi], dl
	inc edi
	mov byte [es: edi], bl
	inc edi
	
	cmp bh, 0x04
	je printf_end1
	jmp a5

a1 :
	add dl, 0x37
	jmp printf3	
a2 :
	add dl, 0x30
	jmp printf3
a3 :
	add dl, 0x37
	jmp printf4
a4 :
	add dl, 0x30
	jmp printf4
a5 :
	add bh, 0x01
	dec eax
	jmp printf2
printf_end1:
	ret
	
print_protected:
	pushad
	mov eax, MSG_Protected_MODE_Test
	mov edi, 80*2*1+0
	mov bl, 0x02
	call printf_s
	popad
	ret
print_cs_LDT0_Start:
	pushad
	mov eax, CS_LDT0_Start
	mov edi, 80*2*5+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*5+2*28					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret
print_cs_Protected:
	pushad
	mov eax, CS_Protected_Start
	mov edi, 80*2*4+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*4+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
;----------------------------------------------------------------------------		
	
;----------------------Global Description Table-----------------------
;[SECTION .data]
;null descriptor. gdt_ptr could be put here to save a few
gdt:
	dw	0			
	dw	0			
	db	0			
	db	0			
	db	0			
	db	0			
;Code Segment Descriptor										  ;
SYS_CODE_SEL equ	08h	;idx:1 code segment descriptor
gdt1:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xFFFF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24
;Data Segment Descriptor										  ;
SYS_DATA_SEL equ	10h ;idx:2 Data Segment descriptor
gdt2:
	;G=1, D=1, L=0 ,AVL=0, P=1, DPL=00, S=1, Type=0010
	dw	0xFFFF	;limit 15:0	(limit의 상위 16bit)
	dw	0x0000	;base 15:0
	db	0x00	;base 23:16
	db	0x92	;P, dpl, s, Type
	db	0xCF	;flags,19:16 limit
	db	0x00	;base 31:24
;Video Segment Descriptor										  ;
VIDEO_SEL equ	18h ;idx:3 Video Segment descriptor
gdt3:
	;G=0, D=1, L=0 ,AVL=0, P=1, DPL=00, S=1, Type=0010
	dw	0xFFFF	;limit 15:0	(limit의 상위 16bit)
	dw	0x8000	;base 15:0
	db	0x0B	;base 23:16
	db	0x92	;P, dpl, s, Type
	db	0x40	;flags,19:16 limit 
	db	0x00	;base 31:24
;LDTR descriptor (for LDT)	
LDTR equ	20h	;idx:4 LDTR descriptor
gdt4:
	;G=0, D=1, L=0, AVL=0, P=1, DPL=00, S=0, Type=0010
	dw	0xFFFF	;limit 15:0 (limit의 상위 16bit)
	dw	ldt0	;Base 15:0
	db	0x00	;base 23:16
	db	0x82 	;P, dpl, s, Type 
	db	0x40	;flags, 19:16 limit <--check
	db	0x00	;base 31:24
	
;Code Segment descriptor2						
SYS_CODE_SEL_1 equ	28h	;idx:5 code segment descriptor2
gdt5:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xFFFF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24										  ;
;------------------------------------------------------------------

gdt_end:

gdt_ptr:
;----------------------Write your code here------------------------
	dw	gdt_end - gdt - 1	;top of GDT(gdt_end-1) - very bottom(gdt) / 16bit gdt table limit
	dd 	gdt					;32 bit base address
;																  ;
;Calculate the base and limit of GDT							  ;
;Store in gdt_prt memory address								  ;
;																  ;
;------------------------------------------------------------------


;---------------------------Local Description Table-----------------------
ldt:
;--------------------------------------------------------------------
;Code Segment Descriptor										  ;
LDT_CODE_SEL_0 equ	0h	;idx:0 Code Segment descriptor
ldt0:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xFFFF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24		
;Data Segment Descriptor										  ;
LDT_DATA_SEL_0 equ	0ch
ldt1:
	;G=1, D=1, L=0 ,AVL=0, P=1, DPL=00, S=1, Type=0010
	dw	0xFFFF	;limit 15:0	(limit의 상위 16bit)
	dw	0x0000	;base 15:0
	db	0x00	;base 23:16
	db	0x92	;P, dpl, s, Type
	db	0xCF	;flags,19:16 limit
	db	0x00	;base 31:24
;																  ;
;------------------------------------------------------------------
			
sector_end:

