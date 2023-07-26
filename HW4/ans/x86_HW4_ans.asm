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
    	mov ss, ax
    	mov sp, 0x9000 		; stack pointer 0x9000
    	mov ax, 0xB800
    	mov es, ax 			; memory address of printing on screen

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

times   510-($-$$) db 0 		; $ : current address, $$ : start address of SECTION
								; $-$$ means the size of source
dw      0xAA55 					; signature bytes
								; End of Master Boot Record(1st Sector)
				
sector_2:						; Program Starts
	cli		
	lgdt	[gdt_ptr]			; Load GDT	
	
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax		; Switch Real mode to Protected mode	
	
	jmp SYS_CODE_SEL:Protected_START	; jump Protected_START
											; Remove prefetch queue
Protected_START:
[bits 32]
; this task could say "Task0"

	mov ax, SYS_DATA_SEL
	mov ds, ax
	mov ss, ax
	mov fs, ax
	mov gs, ax
	mov es, ax
	mov esp, 0xA000
	
	mov ax, Video_SEL
	mov es, ax	
	mov eax, MSG_Protected_MODE_Test
	mov edi, 80*2*1+2*0
	mov bl, 0x02
	call printf
	
	mov eax, Busy_Flag
	mov edi, 80*2*9+2*0
	mov bl, 0x02
	call printf	

	mov eax, Registers
	mov edi, 80*2*17+2*0
	mov bl, 0x02
	call printf
	
	mov eax, TSS
	mov edi, 80*2*14+2*50
	mov bl, 0x02
	call printf		
	
	call print_busy1_init
	call print_busy2_init
	call print_busy3_init

;------------------------------------------------------------------------------------	
; Base of TSS descriptors and LDTR descriptors	
; got form week 3 review, regret that I never knew what this description meant:(
	mov eax, tss1
	
	mov word [gdt4+2], ax ;first base field 
	shr eax, 16
	mov byte [gdt4+4], al ;second base field
	mov byte [gdt4+7], ah ;third bas field
	
	mov eax, tss2
	
	mov word [gdt5+2], ax ;first base field 
	shr eax, 16
	mov byte [gdt5+4], al ;second base field
	mov byte [gdt5+7], ah ;third bas field
	
	mov eax, tss3
	
	mov word [gdt6+2], ax ;first base field 
	shr eax, 16
	mov byte [gdt6+4], al ;second base field
	mov byte [gdt6+7], ah ;third bas field
	
	mov eax, ldt1
	
	mov word [gdt7+2], ax ;first base field 
	shr eax, 16
	mov byte [gdt7+4], al ;second base field
	mov byte [gdt7+7], ah ;third bas field
	
	mov eax, ldt2
	
	mov word [gdt8+2], ax ;first base field 
	shr eax, 16
	mov byte [gdt8+4], al ;second base field
	mov byte [gdt8+7], ah ;third bas field
	
	mov eax, ldt3
	
	mov word [gdt9+2], ax ;first base field 
	shr eax, 16
	mov byte [gdt9+4], al ;second base field
	mov byte [gdt9+7], ah ;third bas field

; Initialize three TSS fields
	;LDT : word 96 CS:word 76 DS: word 84 SS: word 80 ES: word 72
	;EIP : dword 32 ESP : dword 56
	
	;tss1 setting
	mov word [tss1+96], LDTR1
	mov word [tss1+76], LDT_CODE_SEL1
	mov word [tss1+84], LDT_DATA_SEL1
	mov word [tss1+80], LDT_DATA_SEL1
	mov word [tss1+72], Video_SEL
	mov dword [tss1+32], Task1
	mov dword [tss1+56], 0xA000
	
	;tss2 setting
	mov word [tss2+96], LDTR2
	mov word [tss2+76], LDT_CODE_SEL2
	mov word [tss2+84], LDT_DATA_SEL2
	mov word [tss2+80], LDT_DATA_SEL2
	mov word [tss2+72], Video_SEL
	mov dword [tss2+32], Task2
	mov dword [tss2+56], 0xB000
	
	;tss3 setting
	mov word [tss3+96], LDTR3
	mov word [tss3+76], LDT_CODE_SEL3_0
	mov word [tss3+84], LDT_DATA_SEL3
	mov word [tss3+80], LDT_DATA_SEL3
	mov word [tss3+72], Video_SEL
	mov dword [tss3+32], Task3
	mov dword [tss3+56], 0xC000


; Jump to Task1																		;
	jmp TSS1Selector:0
;------------------------------------------------------------------------------------	

Task1:
	call print_busy1_task
	call print_reg_1

; print "Task Switching Start"
	mov edi, 80*2*2+2*0			;second line				
	mov eax, Task1_Start
	mov bl, 0x02
	call printf

	mov eax, 0x0A
	mov ebx, 0x0B
	cmp eax, ebx

; call Task2 
	call TSS2Selector:0
	
; print "Task1 switched BACK from Task2"	
	mov edi, 80*2*7+2*0			;next line				
	mov eax, Task1_Back
	mov bl, 0x02
	call printf
	
	call print_tss1_store
	call print_tss2_store
	call print_tss3_store
	call print_busy1_end
	call print_busy2_end
	call print_busy3_end
	
	jmp $					; this is ending point of program
							; when switched back from task2, this line must be active to end program
	
	
	
Task2:

	call print_reg_2
	call print_busy2_task
	
; print "Task2 switched from Task1"
	mov edi, 80*2*3+2*0			;next line				
	mov eax, Task2_Start
	mov bl, 0x02
	call printf
	
	mov eax, 0x0A
	push eax
	mov ebx, 0x0B
	push ebx
	mov ecx, 0x0C
	push ecx

; call Task3 using Task Gate
	call Task_Gate_Descriptor:0
	
; print "Task2 switched BACK from Task3"
	mov edi, 80*2*6+2*0			;next line				
	mov eax, Task2_Back
	mov bl, 0x02
	call printf
; return to Task1
	IRET

Task3:

	call print_reg_3
	call print_busy3_task
	
; print "Task3 Switched from Task2"
	mov edi, 80*2*4+2*0				;next line				
	mov eax, Task3_Start
	mov bl, 0x02
	call printf
; control transfer
	jmp LDT_CODE_SEL3_1:Task3_next ;jump within a task to different code segment

Task3_next:

; print "Jumped to Task3_Next with LDT_CODE_SEL3_1"
	mov edi, 80*2*5+2*0			;next line				
	mov eax, MSG_TASK3_Next
	mov bl, 0x02
	call printf
; return to Task2
	IRET
	
	;jmp $		; this is ending point of program
				; when you make the task switching code, this line must be deactive 
				
;------------------------------------------------------------------------------------------

	
;------------------------------------------------------------------------------------------

MSG_Protected_MODE_Test: db'Protected Mode',0
Task1_Start: db'Task Switching Start',0
Task2_Start: db'Task2 switched from Task1',0
Task3_Start: db'Task3 switched from Task2',0
Task2_Back: db'Task2 switched BACK from Task3',0
Task1_Back: db'Task1 switched BACK from Task2',0
Busy_Flag: db'***** Busy Flag *****',0
Registers: db'*** ESP, CS, DS, EFLAGS ***',0
TSS: db'*** TSS1, TSS2, TSS3 ***',0
MSG_TASK3_Next: db'Jumped to Task3_Next with LDT_CODE_SEL3_1',0
temp: dd 0

printf:
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
	jmp printf	

printf_end:
	ret
	
printf1:
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


	
;--------------------------------------------------------------------------------------------

print_busy1_init:
	pushad
	pushfd
	mov eax, [gdt4+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*10+0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_busy2_init:
	pushad
	pushfd
	mov eax, [gdt5+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*11+0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret		
print_busy3_init:
	pushad
	pushfd
	mov eax, [gdt6+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*12+0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_busy1_task:
	pushad
	pushfd
	mov eax, [gdt4+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*10+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_busy2_task:
	pushad
	pushfd
	mov eax, [gdt5+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*11+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret		
print_busy3_task:
	pushad
	pushfd
	mov eax, [gdt6+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*12+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_busy1_end:
	pushad
	pushfd
	mov eax, [gdt4+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*10+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_busy2_end:
	pushad
	pushfd
	mov eax, [gdt5+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*11+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret		
print_busy3_end:
	pushad
	pushfd
	mov eax, [gdt6+4]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*12+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
;--------------------------------------------------------------------------------	

print_reg_esp_1:
	pushad
	pushfd
	mov eax, esp
	add eax, 0x28
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_cs_1:
	pushad
	pushfd
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*19+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	

print_reg_ds_1:
	pushad
	pushfd
	mov [temp], ds
	mov eax, temp
	mov edi, 80*2*20+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_reg_eflags_1:
	pushad
	pushfd
	mov eax, [esp]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*0					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_1:
	call print_reg_esp_1
	call print_reg_cs_1
	call print_reg_ds_1
	call print_reg_eflags_1
	ret
	
print_reg_esp_2:
	pushad
	pushfd
	mov eax, esp
	add eax, 0x28
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_cs_2:
	pushad
	pushfd
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*19+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	

print_reg_ds_2:
	pushad
	pushfd
	mov [temp], ds
	mov eax, temp
	mov edi, 80*2*20+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_reg_eflags_2:
	pushad
	pushfd
	mov eax, [esp]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*10					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_2:
	call print_reg_esp_2
	call print_reg_cs_2
	call print_reg_ds_2
	call print_reg_eflags_2
	ret
	
print_reg_esp_3:
	pushad
	pushfd
	mov eax, esp
	add eax, 0x28
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_cs_3:
	pushad
	pushfd
	mov [temp], cs
	mov eax, temp
	mov edi, 80*2*19+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	

print_reg_ds_3:
	pushad
	pushfd
	mov [temp], ds
	mov eax, temp
	mov edi, 80*2*20+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
print_reg_eflags_3:
	pushad
	pushfd
	mov eax, [esp]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*20					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
print_reg_3:
	call print_reg_esp_3
	call print_reg_cs_3
	call print_reg_ds_3
	call print_reg_eflags_3
	ret
	
;----------------------------------------------------------------------------------------

print_tss1_store:
	pushad
	pushfd
	mov eax, [tss1+96]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*50					
	mov bl, 0x02
	call printf1

	
	mov eax, [tss1+84]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1+76]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*17+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1+72]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*50					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss1+56]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*19+2*50					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss1+36]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*20+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1+32]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*50					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss1]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*50					
	mov bl, 0x02
	call printf1
	
	popfd
	popad
	ret
	
	
print_tss2_store:
	pushad
	pushfd
	mov eax, [tss2+96]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*60					
	mov bl, 0x02
	call printf1

	
	mov eax, [tss2+84]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2+76]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*17+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2+72]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*60					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss2+56]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*19+2*60					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss2+36]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*20+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2+32]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*60					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss2]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*60					
	mov bl, 0x02
	call printf1
	
	popfd
	popad
	ret
	
	
print_tss3_store:
	pushad
	pushfd
	mov eax, [tss3+96]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*15+2*70					
	mov bl, 0x02
	call printf1

	
	mov eax, [tss3+84]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*16+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3+76]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*17+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3+72]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*18+2*70					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss3+56]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*19+2*70					
	mov bl, 0x02
	call printf1
		
	mov eax, [tss3+36]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*20+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3+32]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*21+2*70					
	mov bl, 0x02
	call printf1
	
	mov eax, [tss3]
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*22+2*70					
	mov bl, 0x02
	call printf1
	
	popfd
	popad
	ret
;--------------------------------------------------------------------------------	

print_register:
	pushad
	pushfd
	mov [temp], eax
	mov eax, temp
	mov edi, 80*2*1+2*60					
	mov bl, 0x02
	call printf1
	popfd
	popad
	ret	
	
;----------------------------------tss-----------------------------------
;-------------------------write your code here---------------------------
; Make 3 TSS field														;
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------
tss1 : ;104 bytes initialize as 0
	dd 0 ;0
	dd 0
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0;32
	dd 0
	dd 0
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0	;64	
	dd 0
	dd 0	;ES
	dd 0	;CS
	dd 0	;SS
	dd 0	;DS
	dd 0 	;FS
	dd 0 	;GS
	dd 0 ;96 //they will print this
	dd 0 ;100

	
tss2 : ;104 bytes
	dd 0 ;0
	dd 0
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0;32
	dd 0
	dd 0
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0	;64	
	dd 0
	dd 0	;ES
	dd 0	;CS
	dd 0	;SS
	dd 0	;DS
	dd 0 	;FS
	dd 0 	;GS
	dd 0 ;96 //they will print this
	dd 0 ;100

tss3 : ;104 bytes
	dd 0 ;0
	dd 0
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0;32
	dd 0
	dd 0
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0 
	dd 0	;64	
	dd 0
	dd 0	;ES
	dd 0	;CS
	dd 0	;SS
	dd 0	;DS
	dd 0 	;FS
	dd 0 	;GS
	dd 0 ;96 //they will print this
	dd 0 ;100

;-------------------------Global Descriptor Table------------------------
;null descriptor. gdt_ptr could be put here to save a few
gdt:
	dw	0			; limit 15:0
	dw	0			; base 15:0
	db	0			; base 23:16
	db	0			; type
	db	0			; limit 19:16, flags
	db	0			; base 31:24
;Code Segment Descriptor
SYS_CODE_SEL equ	08h
gdt1:
	dw	0FFFFh		; limit 15:0
	dw	00000h		; base 15:0				
	db	0			; base 23:16
	db	9Ah			; present, ring 0, code, non-conforming, readable
	db	0cfh		; limit 19:16, flags
	db	0			; base 31:24
;Data Segment Descriptor
SYS_DATA_SEL equ	10h
gdt2:
	dw	0FFFFh		; limit 15:0
	dw	00000h		; base 23:16			
	db	0			; base 23:16
	db	92h			; present, ring 0, data, expand-up, writable
	db	0cfh		; limit 19:16, flags
	db	0			; base 31:24
;Video Segment Descriptor
Video_SEL	equ	18h				
gdt3:
	dw	0FFFFh		; limit 15:0
	dw	08000h		; base 23:16			
	db	0Bh			; base 23:16
	db	92h			; present, ring 0, data, expand-up, writable
	db	40h			; limit 19:16, flags
	db	00h			; base 31:24


;-------------------------write your code here---------------------------
; TSS selector for three Task											;
; LDTR descriptors for three LDTs                                       ;
; Task Gate Descriptor for TSS3 selector						        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------
;TSS 1 Descriptor
TSS1Selector	equ	20h				
gdt4:
	dw	0068h		; limit 15:0
	dw	0000h		; gdt+2: this needs to be set //base 23:16			
	db	00h			; base 23:16
	db	89h			; p=1 system descriptor, BusyBit 0, TSS descriptor
	db	00h			; limit 19:16, flags
	db	00h			; base 31:24
;TSS 2 Descriptor
TSS2Selector	equ	28h				
gdt5:
	dw	0068h		; limit 15:0
	dw	0000h		; base 23:16			
	db	00h			; base 23:16
	db	89h			; p=1 system descriptor, BusyBit 0, TSS descriptor
	db	00h			; limit 19:16, flags
	db	00h			; base 31:24
;TSS 3 Descriptor
TSS3Selector	equ	30h				
gdt6:
	dw	0068h		; limit 15:0
	dw	0000h		; base 23:16			
	db	00h			; base 23:16
	db	89h			; p=1 system descriptor, BusyBit 0, TSS descriptor
	db	00h			; limit 19:16, flags
	db	00h			; base 31:24
;LDTR
LDTR1 equ 38h
gdt7:	
	dw	0xF		;ldt1 limit, I wanted to test my expected result		
	dw	0x0000		;base address of LDT	
	db	0x00		;base address	
	db	0x82			
	db	0x40			
	db	0x00
LDTR2 equ 40h
gdt8:	
	dw	0x17		;ldt2 limit, I wanted to test my expected result		
	dw	0x0000		;base address of LDT	
	db	0x00		;base address	
	db	0x82			
	db	0x40			
	db	0x00	
LDTR3 equ 48h
gdt9:	
	dw	0x002F		;ldt3 limit, I wanted to test my expected result		
	dw	0x0000		;base address of LDT	
	db	0x00		;base address	
	db	0x82			
	db	0x40			
	db	0x00
;Task Gate Descriptor to Task 3
Task_Gate_Descriptor equ 50h
gdt10:
	dw	0000h		;RESERVED		
	dw	TSS3Selector;TSS3 descriptor seg sel	
	db	0x00		;RESERVED	
	db	0x85		;present in memory, dpl00, type 5 :task gate	
	dw 	0000h		;RESERVED
	
gdt_end:

gdt_ptr:
	dw	gdt_end - gdt - 1	; GDT limit
	dd	gdt		; linear addr of GDT (set above)
	
;-------------------------Local Descriptor Table-------------------------

;-------------------------write your code here---------------------------
; Make Local Descriptor Tables.									        ;
; Fill Code Segment Descriptors and Data Segment Descriptors	        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;																        ;	
;------------------------------------------------------------------------

ldt1:;LDT1
;Data Segment Descriptor
LDT_DATA_SEL1 equ 04h
ldt1_0:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	92h			
	db	0cfh		
	db	0
LDT_CODE_SEL1 equ 0ch
ldt1_1:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	9Ah			
	db	0cfh		
	db	0


ldt2:
LDT_DATA_SEL2 equ 04h
ldt2_0:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	92h			
	db	0cfh		
	db	0
NULL0 equ 0ch
ldt2_1:
	dw 0
	dw 0
	dw 0
	dw 0
LDT_CODE_SEL2 equ 14h
ldt2_2:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	9Ah			
	db	0cfh		
	db	0
	
ldt3:
LDT_DATA_SEL3 equ 04h
ldt3_0:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	92h			
	db	0cfh		
	db	0
LDT_CODE_SEL3_0 equ 0ch
ldt3_1:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	9Ah			
	db	0cfh		
	db	0
NULL1 equ 14h
ldt3_2:
	dw 0
	dw 0
	dw 0
	dw 0
LDT_CODE_SEL3_1 equ 1ch
ldt3_3:
	dw	0FFFFh		
	dw	00000h				
	db	0			
	db	9Ah			
	db	0cfh		
	db	0
sector_end: