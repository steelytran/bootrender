org 7c00h
bits 16

BLACK equ 00h 
BLUE equ 01h 
GREEN equ 02h 
CYAN equ 03h 
RED equ 04h 
MAGENTA equ 05h 
BROWN equ 06h 
LIGHT_GRAY equ 07h 
GRAY equ 08h 
LIGHT_BLUE equ 09h 
LIGHT_GREEN equ 0ah 
LIGHT_CYAN equ 0bh 
LIGHT_RED equ 0ch 
LIGHT_MAGENTA equ 0dh 
YELLOW equ 0eh 
WHITE equ 0fh

K_ESC equ 001h
K_F1 equ 03Bh
K_F2 equ 03Ch
K_F3 equ 03Dh
K_F4 equ 03Eh
K_F5 equ 03Fh
K_F6 equ 040h
K_F7 equ 041h
K_F8 equ 042h
K_F9 equ 043h
K_F10 equ 044h
K_GRAVE equ 029h
K_1 equ 002h
K_2 equ 003h
K_3 equ 004h
K_4 equ 005h
K_5 equ 006h
K_6 equ 007h
K_7 equ 008h
K_8 equ 009h
K_9 equ 00Ah
K_0 equ 00Bh
K_MINUS equ 00Ch
K_EQUALS equ 00Dh
K_BACKSPACE equ 00Eh
K_TAB equ 00Fh
K_Q equ 010h
K_W equ 011h
K_E equ 012h
K_R equ 013h
K_T equ 014h
K_Y equ 015h
K_U equ 016h
K_I equ 017h
K_O equ 018h
K_P equ 019h
K_LBRACKET equ 01Ah
K_RBRACKET equ 01Bh
K_LSHIFT equ 02Ah
K_BACKSLASH equ 02Bh
K_LCTRL equ 01Dh
K_A equ 01Eh
K_S equ 01Fh
K_D equ 020h
K_F equ 021h
K_G equ 022h
K_H equ 023h
K_J equ 024h
K_K equ 025h
K_L equ 026h
K_SEMICOLON equ 027h
K_APOSTROPHE equ 028h
K_RETURN equ 01Ch
K_Z equ 02Ch
K_X equ 02Dh
K_C equ 02Eh
K_V equ 02Fh
K_B equ 030h
K_N equ 031h
K_M equ 032h
K_COMMA equ 033h
K_PERIOD equ 034h
K_SLASH equ 035h
K_RSHIFT equ 036h
K_SPACE equ 039h
K_INS equ 052h
K_HOME equ 047h
K_PGUP equ 049h
K_DEL equ 053h
K_END equ 04Fh
K_PGDN equ 051h
K_UP equ 048h
K_LEFT equ 04Bh
K_DOWN equ 050h
K_RIGHT equ 04Dh

section .bss
	Keystate resb 50h

section .text
; stack
	cli
	xor ax, ax
	mov ss, ax
	mov sp, 7c00h

; setup key isr
	mov es, ax
	mov bx, (09h * 4)

	mov word [es:bx], key_isr
	mov word [es:bx + 2], cs
	sti

; sine approximation
; TODO: write macro for sine and cosine LUT
sine:
	mov cx, 180
     
	mov ax, 1000h
	mov ds, ax

	mov bx, 0fe97h

.calc:
	mov al, 180
	sub al, cl
	mul cl

	mov [bx], ax

	neg ax
	mov [bx + 360], ax

	dec bx
	dec bx

	loop .calc

; vga mode 13h
	mov ax, 0013h
	int 10h

	mov ax, 0a000h
	mov es, ax

;;
;; MAIN LOOP
;;
loop:
	push 2
	push 5
	push [cs:Player]
	push [cs:Player + 2]
	call Line

	mov al, [cs:Keystate + K_W]
	test al, al
	jz .not_w

	dec word [cs:Player + 2]

.not_w:
	mov al, [cs:Keystate + K_A]
	test al, al
	jz .not_a

	dec word [cs:Player]

.not_a:
	mov al, [cs:Keystate + K_S]
	test al, al
	jz .not_s

	inc word [cs:Player + 2]

.not_s:
	mov al, [cs:Keystate + K_D]
	test al, al
	jz .not_d

	inc word [cs:Player]

.not_d:

; vsync
	mov dx, 03dah

trace_end:
	in ax, dx
	test ax, 08h
	jnz trace_end

trace_start:
	in ax, dx
	test ax, 08h
	jz trace_start

; copy from buffer to display
	xor si, si
	xor di, di
	mov cx, 7d80h
	rep movsw

	push es
	mov ax, ds
	mov es, ax

; clear buffer
	xor di, di
	xor ax, ax
	mov cx, 7d80h
	rep stosw

	pop es

	mov al, [cs:Keystate + K_ESC]
	test al, al
	jz loop
;;
;; END OF LOOP
;;

	jmp halt

;
; plot pixel
;
Pixel:
	push cx

	cmp ax, 319
	jg .outofbounds
	cmp ax, 0
	jle .outofbounds
	cmp bx, 199
	jg .outofbounds
	cmp bx, 0
	jle .outofbounds

	mov si,  bx
	shl si, 1
	shl si, 1
	mov cl, 6
	add si, bx
	shl si, cl

	add si, ax
	mov [ds:si], 0ah

.outofbounds:
	pop cx
	ret
;
; Line Algorithm
;
	;[bp + 4]	y2
	;[bp + 6]	x2
	;[bp + 8]	y1
	;[bp + 10]	x1
Line:
	push bp
	mov bp, sp

delta_x:
	mov ax, [bp + 6]
	sub ax, [bp + 10]
	jns .positive

	push ax	;[bp - 2] delta x
	neg ax
	push -1	;[bp - 4] sign of x

	jmp delta_y

.positive:
	push ax		;[bp - 2] delta x
	push 1		;[bp - 4] sign of x

delta_y:
	mov bx, [bp + 4]
	sub bx, [bp + 8]
	jns .positive

	push bx	;[bp - 6] delta y
	neg bx
	push -1	;[bp - 8] sign of y

	jmp slope

.positive:
	push bx		;[bp - 6] delta y
	push 1		;[bp - 8] sign of y

slope:
	push ax		;[bp - 10] unsigned delta x
	push bx		;[bp - 12] unsigned delta y

	cmp ax, bx
	jl dy_over_dx

dx_over_dy:
	mov dx, bx	;py
	shr dx, 1	;

	mov cx, ax

	mov ax, [bp + 10]
	mov bx, [bp + 8]

.rep:
	add dx, [bp - 12]
	cmp dx, [bp - 10]
	jl .continue

	sub dx, [bp - 10]
	add bx, [bp - 8]

.continue:

	add ax, [bp - 4]
	call Pixel
	loop .rep

	jmp Line.done

dy_over_dx:
	mov dx, ax	;px
	shr dx, 1	;

	mov cx, bx

	mov ax, [bp + 10]
	mov bx, [bp + 8]

.rep:
	add dx, [bp - 10]
	cmp dx, [bp - 12]
	jl .continue

	sub dx, [bp - 12]
	add ax, [bp - 4]

.continue:

	add bx, [bp - 8]
	call Pixel
	loop .rep

Line.done:

	mov sp, bp
	pop bp
	ret 8

;
; keyboard IRQ handler
;
key_isr:
	push ax
	push bx
	push ds

	in al, 60h
	mov ah, al

	mov al, 20h
	out 20h, al

	mov al, ah
	mov bx, ax
	and bx, 007fh

	test al, 80h
	jnz .break

.make:
	mov byte [cs:Keystate + bx], 1
	jmp .done

.break:
	mov byte [cs:Keystate + bx], 0

.done:
	pop ds
	pop bx
	pop ax
	iret

halt:
	cli
	hlt
	jmp halt

; player position
	Player dw 159, 99

; boot signature
times 200h - 2 - ($ - $$) db 0
dw 0aa55h
