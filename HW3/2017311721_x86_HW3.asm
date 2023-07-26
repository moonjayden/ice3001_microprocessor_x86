[org 0x7c00]		; Assembly command
					; Let NASM compiler know starting address of memory
					; BIOS reads 1st sector and copied it on memory address 0x7c00
[bits 16] 			; Assembly command
					; Let NASM compiler know that this code consists of 16its

[SECTION .text] 	; text section
START:				; boot loader(1st sector) starts
    cli
    xor ax, ax
    mov ds, ax
    mov sp, 0x9000 		; stack pointer 0x9000
	
	mov ax, 0xB800
    mov es, ax 			; memory address of printing on screen
	
    mov al, byte [MSG_test]
    mov byte [es : 80*2*0+2*0], al
    mov byte [es : 80*2*0+2*0+1], 0x05
	mov al, byte [MSG_test+1]
    mov byte [es : 80*2*0+2*1], al
    mov byte [es : 80*2*0+2*1+1], 0x06
	mov al, byte [MSG_test+2]
    mov byte [es : 80*2*0+2*2], al
    mov byte [es : 80*2*0+2*2+1], 0x07
	mov al, byte [MSG_test+3]
    mov byte [es : 80*2*0+2*3], al
    mov byte [es : 80*2*0+2*3+1], 0x08
	sti
	 
	
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
	lgdt	[gdt_ptr]			; Load GDT	
	

	
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax			; Switch Real mode to Protected mode

	

	jmp SYS_CODE_SEL_0:Protected_START	; jump Protected_START
											; Remove prefetch queue
;---------------------------------------------------------------		
Protected_START:	; Protected mode starts
[bits 32]			; Assembly command
					; Let NASM compiler know that this code consists of 32its

	mov ax, Video_SEL		
	mov es, ax

	mov edi, 80*2*2+2*0					
	mov eax, MSG_Protected_MODE
	mov bl, 0x02
	call printf_s
	call print_cs_Protected

;-------------------------------------------------------------------
; Put Offset in Segment to call gate descriptor                   ;
; Put base address of ldt1 to ldtr1 descriptor					  ;
	mov ax, LDTR1
	lldt ax
; Put base address of ldt2 to ldtr2 descriptor					  ;
; Put base address of ldt3 to ldtr3 descriptor					  ;
;                                                        		  ;
; control transfer 		Protected_START -> LDT1_Start				  						  ;
	jmp LDT1_CODE_SEL_0:LDT1_Start
;																  ;
;------------------------------------------------------------------	
	
GDT_Return:
; print strings
	add edi, 80*2	;+160 (1줄 내리기)
	mov eax, MSG_GDT_Return
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_GDG_Return	
	pop edi	
	
	jmp $						;end the program
	
LDT1_Start:
; print strings
	mov eax, MSG_LDT1_Start_0
	mov edi, 80*2*3
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_LDT1_Start_0
	pop edi
; control transfer	LDT1_Start -> LDT1_Next
	call LDT1_CODE_SEL_1:LDT1_Next
	
; print strings
	add edi, 160	;+160 (1줄 내리기)
	mov eax, MSG_LDT1_Start_1
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_LDT1_Start_1
	pop edi
; control transfer	LDT1_Start -> LDT2_Start
	mov ax, LDTR2
	lldt ax
	jmp LDT2_CODE_SEL_1:LDT2_Start
LDT1_Next:
; print strings
	add edi, 80*2	;+160 (1줄 내리기)
	mov eax, MSG_LDT1_Next
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_LDT1_Next
	pop edi
	call print_cs_in_stack
; control transfer
	retf

LDT2_Start:
; print strings
	add edi, 80*2	;+160 (1줄 내리기)
	mov eax, MSG_LDT2_Start_0
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_LDT2_Start_0	
	pop edi
; control transfer	LDT2_Start -> LDT2_Next
; call gate
	call LDT2_Call_Gate:0
; print strings
	add edi, 80*2	;+160 (1줄 내리기)
	mov eax, MSG_LDT2_Start_1
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_LDT2_Start_1	
	pop edi
; control transfer	LDT2_Start -> LDT3_Start
	mov ax, LDTR3
	lldt ax
	jmp LDT3_CODE_SEL_0:LDT3_Start
LDT2_Next:
; print strings
	add edi, 80*2	;+160 (1줄 내리기)
	mov eax, MSG_LDT2_Next
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_LDT2_Next
	pop edi
; control transfer
	retf
LDT3_Start:
; print strings
	add edi, 80*2	;+160 (1줄 내리기)
	mov eax, MSG_LDT3_Start
	mov bl, 0x02
	push edi
	call printf_s
	call print_CS_LDT3_Start
	pop edi
; control transfer
	jmp SYS_CODE_SEL_1:GDT_Return

	;jmp $						;end the program
;------------------------------------------------------------------------	
MSG_Protected_MODE : db '0. Enter Protected Mode with SYS_CODE_SEL_0', 0
MSG_LDT1_Start_0 : db '1. Enter LDT1_Start with LDT1_CODE_SEL_0', 0
MSG_LDT1_Next : db '2. Enter LDT1_Next with LDT1_CODE_SEL_1', 0
MSG_LDT1_Start_1 : db '3. Return LDT1_Start with LDT1_CODE_SEL_0', 0
MSG_LDT2_Start_0 : db '4. Enter LDT2_Start with LDT2_CODE_SEL_1', 0
MSG_LDT2_Next : db '5. Enter LDT2_Next with LDT2_CODE_SEL_0', 0
MSG_LDT2_Start_1 : db '6. Return LDT2_Start with LDT2_CODE_SEL_1', 0
MSG_LDT3_Start : db '7. Enter LDT3_Start with LDT3_CODE_SEL_0', 0
MSG_GDT_Return : db '8. Return to GDT_Return with SYS_CODEL_SEL_1', 0
;------------------------------------------------------------------------
CS_Protected_MODE : db '0. CS register of Protected Mode :', 0
CS_LDT1_Start_0 : db '1. CS register of LDT1_Start :', 0
CS_LDT1_Next : db '2. CS register of LDT1_Next :', 0
CS_LDT1_Start_1 : db '3. CS register of LDT1_Start :', 0
CS_LDT2_Start_0 : db '4. CS register of LDT2_Start :', 0
CS_LDT2_Next : db '5. CS register of LDT2_Next :', 0
CS_LDT2_Start_1 : db '6. CS register of LDT2_Start :', 0
CS_LDT3_Start : db '7. CS register of LDT3_Start :', 0
CS_GDG_Return : db '8. CS register of GDT_Return :', 0

CS_in_stack: db'CS register in stack:',0
;------------------------------------------------------------------------
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
	
temp: dd 0

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
	
print_cs_Protected:
	pushad
	mov eax, CS_Protected_MODE 
	mov edi, 80*2*12+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*12+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret
	
print_CS_LDT1_Start_0:
	pushad
	mov eax, CS_LDT1_Start_0 
	mov edi, 80*2*13+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*13+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret

print_CS_LDT1_Next:
	pushad
	mov eax, CS_LDT1_Next
	mov edi, 80*2*14+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*14+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
	
print_CS_LDT1_Start_1:
	pushad
	mov eax, CS_LDT1_Start_1
	mov edi, 80*2*15+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*15+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
	
print_CS_LDT2_Start_0:
	pushad
	mov eax, CS_LDT2_Start_0 
	mov edi, 80*2*16+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*16+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret
	
print_CS_LDT2_Next:
	pushad
	mov eax, CS_LDT2_Next
	mov edi, 80*2*17+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*17+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	

print_CS_LDT2_Start_1:
	pushad
	mov eax, CS_LDT2_Start_1 
	mov edi, 80*2*18+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*18+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	

print_CS_LDT3_Start:
	pushad
	mov eax, CS_LDT3_Start
	mov edi, 80*2*19+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*19+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret		

print_CS_GDG_Return :
	pushad
	mov eax, CS_GDG_Return  
	mov edi, 80*2*20+0
	mov bl, 0x02
	call printf_s
	mov edi, 80*2*20+2*33					
	mov bl, 0x04
	mov [temp], cs
	mov eax, temp
	call printf_n
	popad
	ret	
	
print_cs_in_stack:
	pushad
	mov eax, CS_in_stack
	mov edi, 80*2*22+0
	mov bl, 0x02
	call printf_s
	mov eax, [esp+40]
	mov [temp], eax
	mov eax, temp	
	mov edi, 80*2*22+2*27
	mov bl, 0x04
	call printf_n
	popad
	ret	

	
;---------------------------------------------------------------------

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
SYS_CODE_SEL_0 equ	08h
gdt1:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	9Ah			
	db	0cfh		
	db	0			
SYS_DATA_SEL equ	10h
gdt2:
	dw	0FFFFh		
	dw	00000h					
	db	0			
	db	92h			
	db	0cfh		
	db	0			
Video_SEL	equ	18h				
gdt3:
	dw	0FFFFh		
	dw	08000h					
	db	0Bh			
	db	92h			
	db	40h			
	db	00h			
;--------------------------------------------------------------------------
; LDTR descriptors for LDT1                                         ;
LDTR1	equ 20h
gdt4:;limit = 8*3-1 = 23 = 0x17
	;G=0, D=1, L=0, AVL=0, P=1, DPL=00, S=0, Type=0010
	;dw	ldt1_end - ldt1_0 - 1	;limit 15:0 (limit의 상위 16bit)
	dw 	0x17
	dw	ldt1_0	;Base 15:0
	db	0x00	;base 23:16
	db	0x82 	;P, dpl, s, Type 
	db	0x40	;flags, 19:16 limit <--check
	db	0x00	;base 31:24
	
; LDTR descriptors for LDT2                                         ;
LDTR2	equ 28h
gdt5:
	;G=0, D=1, L=0, AVL=0, P=1, DPL=00, S=0, Type=0010
	;dw	ldt2_end - ldt2_0 - 1	;limit 15:0 (limit의 상위 16bit)
	dw	0x1F
	dw	ldt2_0	;Base 15:0
	db	0x00	;base 23:16
	db	0x82 	;P, dpl, s, Type 
	db	0x40	;flags, 19:16 limit <--check
	db	0x00	;base 31:24
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------
SYS_CODE_SEL_1 equ	30h
gdt6:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	9Ah			
	db	0cfh		
	db	0			
;------------------------------------------------------------------------
; LDTR descriptors for two LDT3                                         ;
LDTR3	equ 38h
gdt7:
	;G=0, D=1, L=0, AVL=0, P=1, DPL=00, S=0, Type=0010
	;dw	ldt3_end - ldt3_0 -1	;limit 15:0 (limit의 상위 16bit)
	dw	0x0F
	dw	ldt3_0	;Base 15:0
	db	0x00	;base 23:16
	db	0x82 	;P, dpl, s, Type 
	db	0x40	;flags, 19:16 limit <--check
	db	0x00	;base 31:24
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------
gdt_end:

gdt_ptr:
		dw			gdt_end - gdt - 1	
		dd			gdt		
		
;-------------------------Local Descriptor Table-------------------------
;------------------------------------------------------------------------
; Make Local Descriptor Tables.									        ;
ldt1:
;local descriptor table1						  ;
LDT1_CODE_SEL_0 equ	04h	;idx:0 Code Segment descriptor
ldt1_0:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24										  ;
LDT1_CODE_SEL_1 equ	0ch	;idx:1 Code Segment descriptor
ldt1_1:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24										  ;
LDT1_DATA_SEL_0 equ	14h ;idx:2 Data Segment descriptor
ldt1_2:
	;G=1, D=1, L=0 ,AVL=0, P=1, DPL=00, S=1, Type=0010
	dw	0xF	;limit 15:0	(limit의 상위 16bit)
	dw	0x0000	;base 15:0
	db	0x00	;base 23:16
	db	0x92	;P, dpl, s, Type
	db	0xCF	;flags,19:16 limit
	db	0x00	;base 31:24
ldt1_end:																        ;	
ldt2:
;local descriptor table2						  ;
LDT2_DATA_SEL_0 equ	04h ;idx:0 Data Segment descriptor
ldt2_0:
	;G=1, D=1, L=0 ,AVL=0, P=1, DPL=00, S=1, Type=0010
	dw	0xF	;limit 15:0	(limit의 상위 16bit)
	dw	0x0000	;base 15:0
	db	0x00	;base 23:16
	db	0x92	;P, dpl, s, Type
	db	0xCF	;flags,19:16 limit
	db	0x00	;base 31:24
LDT2_CODE_SEL_0 equ	0ch	;idx:1 Code Segment descriptor
ldt2_1:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24				
LDT2_Call_Gate	equ 14h	;idx: 2 call gate descriptor
ldf2_2:
	;P=1, DPL=00, Type=1100, ParamCnt=0000
	dw	LDT2_Next
	dw	LDT2_CODE_SEL_0
	db	0x00
	db	0x8c
	dw	0x0000
LDT2_CODE_SEL_1 equ	1ch	;idx:3 Code Segment descriptor
ldt2_3:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24										  ;
ldt2_end:										        ;	
ldt3:
;local descriptor table3						  ;
LDT3_CODE_SEL_0 equ	04h	;idx:0 Code Segment descriptor
ldt3_0:
	;G=1, D=1, L=0, AVL=0. P=1, DPL=00, S=1, Type=1010
	dw	0xF	;limit 15:0 (limit의 상위 16bit)
	dw 	0x0000	;base 15:0
	db 	0x00	;base 23:16
	db	0x9A	;P, dpl, s, Type
	db	0xCF	;flags, 19:16 limit
	db 	0x00	;base 31:24				
LDT3_DATA_SEL_0 equ	0ch ;idx:1 Data Segment descriptor
ldt3_1:
	;G=1, D=1, L=0 ,AVL=0, P=1, DPL=00, S=1, Type=0010
	dw	0xF	;limit 15:0	(limit의 상위 16bit)
	dw	0x0000	;base 15:0
	db	0x00	;base 23:16
	db	0x92	;P, dpl, s, Type
	db	0xCF	;flags,19:16 limit
	db	0x00	;base 31:24
ldt3_end:
;																        ;	
;																        ;	
;------------------------------------------------------------------------		
sector_end:

