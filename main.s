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

section .text
; stack
	cli
	xor ax, ax
	mov ss, ax
	mov sp, 7c00h

; setup key isr
	mov word [09h * 4], key_isr
	mov word [09h * 4 + 2], cs

	sti

; vga mode 13h
	mov ax, 0013h
	int 10h

	mov ax, 0a000h
	mov es, ax

	mov ax, 1000h
	mov ds, ax
;;
;; MAIN LOOP
;;
loop:
;
; Line Algorithm
;
	push bp
	mov bp, sp

	mov cl, 1
	push [cs:Linedefs]
	push [cs:Linedefs + 2]

rotate:
	fninit

	fild word [cs:Player + 4]
	fldpi
	fmulp st1

	push 180
	fild word [esp]
	fdivp st1, st0

	fsincos

	fild word [esp + 2]
	fisub word [cs:Player + 2]

	fild word [esp + 4]
	fisub word [cs:Player]

	fld st1
	fld st1

	; st0 x
	; st1 y
	; st2 x
	; st3 y
	; st4 cos
	; st5 sin

	; x'
	fmul st4
	fxch

	fmul st5
	fsubp st1
	fistp word [esp + 4]

	; st0 x
	; st1 y
	; st2 cos
	; st3 sin

	; y'
	fmul st3
	fxch

	fmul st2
	faddp st1
	fistp word [esp + 2]

	pop ax

	jcxz delta_x
	dec cl

	push [cs:Linedefs + 4]; [bp - 6]
	push [cs:Linedefs + 6]; [bp - 8]

	jmp rotate

delta_x:

	mov ax, [bp - 6]
	sub ax, [bp - 2]
	push ax	;[bp - 10] delta x

	jns delta_y

	neg ax

delta_y:
	mov bx, [bp - 8]
	sub bx, [bp - 4]
	push bx	;[bp - 12] delta y

	jns step

	neg bx

step:
	cmp ax, bx
	jl step_y

	push ax		; [bp - 10] step
	jmp gradient

step_y:
	push bx		; [bp - 10] step

gradient:
	fild word [bp - 10]	; dx
	fild word [bp - 14]	; step
	fdivp st1, st0

	fild word [bp - 12]	; dy
	fild word [bp - 14]	; step
	fdivp st1, st0

	fild word [bp - 4]
	push 100
	fiadd word [esp]
	pop ax

	fild word [bp - 2]
	push 160
	fiadd word [esp]
	pop ax

	mov cx, [bp - 14]

.draw:
	; st3 dx
	; st2 dy
	; st1 y
	; st0 x

	fist word [bp - 16]
	fadd st0, st3
	fxch st1

	fist word [bp - 18]
	fadd st0, st2
	fxch st1

	mov ax, [bp - 16]
	mov bx, [bp - 18]

; draw pixel
	cmp ax, 319
	jg .outofbounds
	cmp ax, 0
	jl .outofbounds
	cmp bx, 199
	jg .outofbounds
	cmp bx, 0
	jl .outofbounds

	mov si, bx
	mul si, 320

	add si, ax
	mov [ds:si], 0ah

.outofbounds:
	loop .draw

	mov sp, bp
	pop bp

; player movement
	mov al, [cs:Keystate + K_W]
	test al, al
	jz not_w

	dec word [cs:Player + 2]

not_w:
	mov al, [cs:Keystate + K_A]
	test al, al
	jz not_a

	dec word [cs:Player]

not_a:
	mov al, [cs:Keystate + K_S]
	test al, al
	jz not_s

	inc word [cs:Player + 2]

not_s:
	mov al, [cs:Keystate + K_D]
	test al, al
	jz not_d

	inc word [cs:Player]

not_d:
	mov al, [cs:Keystate + K_LEFT]
	test al, al
	jz not_left

	dec word [cs:Player + 4]
	jns not_left

	mov word [cs:Player + 4], 359

not_left:
	mov al, [cs:Keystate + K_RIGHT]
	test al, al
	jz not_right

	mov ax, 360
	inc word [cs:Player + 4]
	cmp word [cs:Player + 4], ax
	jnge not_right

	mov word [cs:Player + 4], 0

not_right:

; vsync
	mov dx, 03dah

trace_end:
	in al, dx
	test al, 08h
	jnz trace_end

trace_start:
	in al, dx
	test al, 08h
	jz trace_start

; copy from buffer to display
	xor si, si
	xor di, di
	mov cx, 32000
	rep movsw

	push es
	mov ax, ds
	mov es, ax

; clear buffer
	xor di, di
	xor ax, ax
	mov cx, 32000
	rep stosw

	pop es

	mov al, [cs:Keystate + K_ESC]
	test al, al
	jz loop
;;
;; END OF LOOP
;;

halt:
	cli
	hlt
	jmp halt

;
; keyboard IRQ handler
;
key_isr:
	push ax
	push bx

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
	pop bx
	pop ax
	iret

	Player dw 0, 0, 0
	Linedefs dw 100, 70, 220, 130

; boot signature
times 200h - 2 - ($ - $$) db 0
dw 0aa55h

section .bss
	Keystate resb 50h
