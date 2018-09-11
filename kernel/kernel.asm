name "kernel"
#load_segment=0800#
#load_offset=0000#

#al=0b#
#ah=00#
#bh=00#
#bl=00#
#ch=00#
#cl=02#
#dh=00#
#dl=00#
#ds=0800#
#es=0800#
#si=7c02#
#di=0000#
#bp=0000#
#cs=0800#
#ip=0000#
#ss=07c0#
#sp=03fe#

putc    macro   char
push    ax
mov     al, char
mov     ah, 0eh
int     10h
pop     ax
endm


; sets current cursor position:
gotoxy  macro   col, row
push    ax
push    bx
push    dx
mov     ah, 02h
mov     dh, row
mov     dl, col
mov     bh, 0
int     10h
pop     dx
pop     bx
pop     ax
endm


print macro x, y, attrib, sdat
LOCAL   s_dcl, skip_dcl, s_dcl_end
pusha
mov dx, cs
mov es, dx
mov ah, 13h
mov al, 1
mov bh, 0
mov bl, attrib
mov cx, offset s_dcl_end - offset s_dcl
mov dl, x
mov dh, y
mov bp, offset s_dcl
int 10h
popa
jmp skip_dcl
s_dcl DB sdat
s_dcl_end DB 0
skip_dcl:
endm


org 0000h


jmp start

;==== data section =====================

; welcome message:
msg  db "==== Sistema Operacional de Pobre ====", 0

cmd_size        equ 20    ; size of command_buffer
command_buffer  db cmd_size dup("b")
clean_str       db cmd_size dup(" "), 0
prompt          db ">", 0

; commands:
chelp    db "ajuda", 0
chelp_tail:
ccls     db "limpartela", 0
ccls_tail:
ccalculadora db "calculadora", 0
ccalculadora_tail:
cfatorial db "fatorial", 0
cfatorial_tail:
chora db "hora", 0
chora_tail:
cbonus db "cobra",0
cbonus_tail:
creboot  db "reboot", 0
creboot_tail:

help_msg db "comandos:", 0Dh,0Ah
db "ajuda       - Mostra essa lista.", 0Dh,0Ah
db "limpartela  - Limpa a tela.", 0Dh,0Ah
db "hora        - Mostra a hora atual.", 0Dh,0Ah
db "calculadora - Calculadora de inteiros.", 0Dh,0Ah
db "cobra       - Jogo da cobrinha.", 0Dh,0Ah 
db "fatorial    - Calcula o fatorial de um numero.", 0Dh,0Ah
db "reboot      - Reinicia a maquina.", 0Dh,0Ah,0

;unknown  db "unknown command: " , 0

;======================================

start:

; set data segment:
push    cs
pop     ds

; set default video mode 80x25:
mov     ah, 00h
mov     al, 03h
int     10h

; blinking disabled for compatibility with dos/bios,
; emulator and windows prompt never blink.
mov     ax, 1003h
mov     bx, 0      ; disable blinking.
int     10h


; *** the integrity check  ***
cmp [0000], 0E9h
jz integrity_check_ok
integrity_failed:
mov     al, 'F'
mov     ah, 0eh
int     10h
; wait for any key...
mov     ax, 0
int     16h
; reboot...
mov     ax, 0040h
mov     ds, ax
mov     w.[0072h], 0000h
jmp    0ffffh:0000h
integrity_check_ok:
nop
; *** ok ***



; clear screen:
call    clear_screen


; print out the message:
lea     si, msg
call    print_string


eternal_loop:
call    get_command

call    process_cmd


; make eternal loop:
jmp eternal_loop


;===========================================
get_command proc near

; set cursor position to bottom
; of the screen:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]

gotoxy  0, al

; clear command line:
lea     si, clean_str
call    print_string

gotoxy  0, al

; show prompt:
lea     si, prompt
call    print_string


; wait for a command:
mov     dx, cmd_size    ; buffer size.
lea     di, command_buffer
call    get_string


ret
get_command endp
;===========================================

process_cmd proc    near

;//// check commands here ///
; set es to ds
push    ds
pop     es

cld     ; forward compare.

; compare command buffer with 'ajuda'
lea     si, command_buffer
mov     cx, chelp_tail - offset chelp   ; size of ['help',0] string.
lea     di, chelp
repe    cmpsb
je      help_command


; compare command buffer with 'hora'
lea si,command_buffer
mov cx,chora_tail - offset chora
lea di,chora
repe cmpsb
je hora_command

; compare command buffer with 'bonus'
lea si,command_buffer
mov cx,cbonus_tail - offset cbonus
lea di,cbonus
repe cmpsb
je bonus_command  

; compare command buffer with 'calculadora'
lea si,command_buffer
mov cx,ccalculadora_tail - offset ccalculadora
lea di,ccalculadora
repe cmpsb
je calculadora_command 

; compare command buffer with 'fatorial'
lea si,command_buffer
mov cx,cfatorial_tail - offset cfatorial
lea di,cfatorial
repe cmpsb
je fatorial_command

; compare command buffer with 'limpartela'
lea     si, command_buffer
mov     cx, ccls_tail - offset ccls  ; size of ['cls',0] string.
lea     di, ccls
repe    cmpsb
jne     not_cls
jmp     cls_command
not_cls:

; compare command buffer with 'reboot'
lea     si, command_buffer
mov     cx, creboot_tail - offset creboot  ; size of ['reboot',0] string.
lea     di, creboot
repe    cmpsb
je      reboot_command

; ignore empty lines
cmp     command_buffer, 0
jz      processed


;////////////////////////////

; if gets here, then command is
; unknown...

mov     al, 1
call    scroll_t_area

; set cursor position just
; above prompt line:
mov     ax, 40h
mov     es, ax
mov     al, es:[84h]
dec     al
gotoxy  0, al

;lea     si, unknown
;call    print_string

lea     si, command_buffer
call    print_string

mov     al, 1
call    scroll_t_area

jmp     processed

; +++++ 'help' command ++++++
help_command:

; scroll text area 9 lines up:
mov     al, 9
call    scroll_t_area 
;call    clear_screen

; set cursor position 9 lines
; above prompt line:
mov     ax, 40h 
mov     bh,0101_1111b
mov     es, ax
mov     al, es:[84h]
sub     al, 9
gotoxy  0, al

lea     si, help_msg
call    print_string

mov     al, 1
call    scroll_t_area

jmp     processed




; +++++ 'cls' command ++++++
cls_command:
call    clear_screen
jmp     processed


; +++++++ 'hora' command +++++++
hora_command:
call HORA 
call clear_screen
jmp processed

; +++++++ 'cobra' command +++++++
bonus_command:
call BONUS 
call clear_screen
jmp processed

; +++++++ 'calculadora' command +++++++
calculadora_command:
call clear_screen
call CALCULADORA 
call clear_screen
jmp processed 

; +++++++ 'fatorial' command +++++++
fatorial_command:
call clear_screen
call FATORIAL 
call clear_screen
jmp processed

; +++ 'quit', 'exit', 'reboot' +++
reboot_command:
call    clear_screen
print 5,2,0000_1111b," Por favor retire qualquer disco floppy "
print 5,3,0000_1111b," e pressione qualquer tecla para reiniciar... "
mov ax, 0  ; wait for any key....
int 16h

; store magic value at 0040h:0072h:
;   0000h - cold boot.
;   1234h - warm boot.
mov     ax, 0040h
mov     ds, ax
mov     w.[0072h], 0000h ; cold boot.
jmp    0ffffh:0000h     ; reboot!

; ++++++++++++++++++++++++++

processed:
ret
process_cmd endp

;===========================================

; scroll all screen except last row
; up by value specified in al

scroll_t_area   proc    near

    mov dx, 40h
    mov es, dx  ; for getting screen parameters.
    mov ah, 06h ; scroll up function id.
    mov bh, 0101_1111b,07  ; attribute for new lines.
    mov ch, 0   ; upper row.
    mov cl, 0   ; upper col.
    mov di, 84h ; rows on screen -1,
    mov dh, es:[di] ; lower row (byte).
    dec dh  ; don't scroll bottom line.
    mov di, 4ah ; columns on screen,
    mov dl, es:[di]
    dec dl  ; lower col.
    int 10h
    
    ret
scroll_t_area   endp

;===========================================




; get characters from keyboard and write a null terminated string
; to buffer at DS:DI, maximum buffer size is in DX.
; 'enter' stops the input.
get_string      proc    near
    push    ax
    push    cx
    push    di
    push    dx
    
    mov     cx, 0                   ; char counter.
    
    cmp     dx, 1                   ; buffer too small?
    jbe     empty_buffer            ;
    
    dec     dx                      ; reserve space for last zero.
    
    
    ;============================
    ; eternal loop to get
    ; and processes key presses:
    
    wait_for_key:
    
    mov     ah, 0                   ; get pressed key.
    int     16h
    
    cmp     al, 0Dh                 ; 'return' pressed?
    jz      exit
    
    
    cmp     al, 8                   ; 'backspace' pressed?
    jne     add_to_buffer
    jcxz    wait_for_key            ; nothing to remove!
    dec     cx
    dec     di
    putc    8                       ; backspace.
    putc    ' '                     ; clear position.
    putc    8                       ; backspace again.
    jmp     wait_for_key
    
    add_to_buffer:
    
    cmp     cx, dx          ; buffer is full?
    jae     wait_for_key    ; if so wait for 'backspace' or 'return'...
    
    mov     [di], al
    inc     di
    inc     cx
    
    ; print the key:
    mov     ah, 0eh
    int     10h
    
    jmp     wait_for_key
    ;============================
    
    exit:
    
    ; terminate by null:
    mov     [di], 0
    
    empty_buffer:
    
    pop     dx
    pop     di
    pop     cx
    pop     ax
    ret
get_string      endp




; print a null terminated string at current cursor position,
; string address: ds:si
print_string proc near
    push    ax      ; store registers...
    push    si      ;
    
    next_char:
    mov     al, [si]
    cmp     al, 0
    jz      printed
    inc     si
    mov     ah, 0eh ; teletype function.
    int     10h
    jmp     next_char
    printed:
    
    pop     si      ; re-store registers...
    pop     ax      ;
    
    ret
print_string endp



; clear the screen by scrolling entire screen window,
; and set cursor position on top.
; default attribute is set to white on blue.
clear_screen proc near
    push    ax      ; store registers...
    push    ds      ;
    push    bx      ;
    push    cx      ;
    push    di      ;
    
    mov     ax, 40h
    mov     ds, ax  ; for getting screen parameters.
    mov     ah, 06h ; scroll up function id.
    mov     al, 0   ; scroll all lines!
    mov     bh, 0101_1111b  ; attribute for new lines.
    mov     ch, 0   ; upper row.
    mov     cl, 0   ; upper col.
    mov     di, 84h ; rows on screen -1,
    mov     dh, [di] ; lower row (byte).
    mov     di, 4ah ; columns on screen,
    mov     dl, [di]
    dec     dl      ; lower col.
    int     10h
    
    ; set cursor position to top
    ; of the screen:
    mov     bh, 0   ; current page.
    mov     dl, 0   ; col.
    mov     dh, 0   ; row.
    mov     ah, 02
    int     10h
    
    pop     di      ; re-store registers...
    pop     cx      ;
    pop     bx      ;
    pop     ds      ;
    pop     ax      ;
    
    ret
clear_screen endp


BONUS proc

    call clear_screen
    jmp     startsnk
    
    ; ------ data section ------
    
    s_size  equ     7
    
    ; the snake coordinates
    ; (from head to tail)
    ; low byte is left, high byte
    ; is top - [top, left]
    snake dw s_size dup(0)
    
    tail    dw      ?
    
    ; direction constants
    ;          (bios key codes):
    left    equ     4bh
    right   equ     4dh
    up      equ     48h
    down    equ     50h
    
    ; current snake direction:
    cur_dir db      right
    
    wait_time dw    0
    
    ; welcome message
    msgsnk     db "==== Como Jogar ====", 0dh,0ah
    db "Controle a cobra (hum...) usando as setas.", 0dh,0ah
    db "Qualquer outra tecla para a cobra (hum...).", 0dh,0ah, 0ah
    db "Precione Esc para sair.", 0dh,0ah
    db "==========================================================================", 0dh,0ah, 0ah
    db "     @   @",0dh,0ah,0ah,"   @             @           @            @                    @",0dh,0ah,0ah
    db "                 @   @             @             @",0dh,0ah,0ah
    db "              @                               @ ",0dh,0ah,0ah
    db "     @   @",0dh,0ah,0ah,"   @             @           @            @                    @",0dh,0ah,0ah
    db " @             @          @                       @",0dh,0ah,0ah
    db "==========================================================================", 0dh,0ah, 0ah
    db "Pressione qualquer tecla para comecar!",0
    
    ; ------ code section ------
    
    startsnk:
    
    ; print welcome message:
    
    lea si,msgsnk
    call print_string
    
    
    ; wait for any key:
    mov ah, 00h
    int 16h
    
    
    ; hide text cursor:
    mov     ah, 1
    mov     ch, 2bh
    mov     cl, 0bh
    int     10h
    
    
    game_loop:
    
    ; === select first video page
    mov     al, 0  ; page number.
    mov     ah, 05h
    int     10h
    
    ; === show new head:
    mov     dx, snake[0]
    
    ; set cursor at dl,dh
    mov     ah, 02h
    int     10h
    
    ; print '*' at the location:
    mov     al, '*'
    mov     ah, 09h
    mov     bl, 0101_1110b ; attribute.
    mov     cx, 1   ; single char.
    int     10h
    
    ; === keep the tail:
    mov     ax, snake[s_size * 2 - 2]
    mov     tail, ax
    
    call    move_snake
    
    
    ; === hide old tail:
    mov     dx, tail
    
    ; set cursor at dl,dh
    mov     ah, 02h
    int     10h
    
    ; print ' ' at the location:
    mov     al, ' '
    mov     ah, 09h
    mov     bl, 0101_1111b ; attribute.
    mov     cx, 1   ; single char.
    int     10h
    
    
    
    check_for_key:
    
    ; === check for player commands:
    mov     ah, 01h
    int     16h
    jz      no_key
    
    mov     ah, 00h
    int     16h
    
    cmp     al, 1bh    ; esc - key?
    je      stop_game  ;
    
    mov     cur_dir, ah
    
    no_key:
    
    
    
    ; === wait a few moments here:
    ; get number of clock ticks
    ; (about 18 per second)
    ; since midnight into cx:dx
    mov     ah, 00h
    int     1ah
    cmp     dx, wait_time
    jb      check_for_key
    add     dx, 4
    mov     wait_time, dx
    
    
    
    ; === eternal game loop:
    jmp     game_loop
    
    
    stop_game:
    
    ; show cursor back:
    mov     ah, 1
    mov     ch, 0bh
    mov     cl, 0bh
    int     10h
    
    ret
    
    ; ------ functions section ------
    
    ; this procedure creates the
    ; animation by moving all snake
    ; body parts one step to tail,
    ; the old tail goes away:
    ; [last part (tail)]-> goes away
    ; [part i] -> [part i+1]
    ; ....
    ret
BONUS endp

move_snake proc near
    
    ; set es to bios info segment:
    mov     ax, 40h
    mov     es, ax
    
    ; point di to tail
    mov   di, s_size * 2 - 2
    ; move all body parts
    ; (last one simply goes away)
    mov   cx, s_size-1
    move_array:
    mov   ax, snake[di-2]
    mov   snake[di], ax
    sub   di, 2
    loop  move_array
    
    
    cmp     cur_dir, left
    je    move_left
    cmp     cur_dir, right
    je    move_right
    cmp     cur_dir, up
    je    move_up
    cmp     cur_dir, down
    je    move_down
    
    jmp     stop_move       ; no direction.
    
    
    move_left:
    mov   al, b.snake[0]
    dec   al
    mov   b.snake[0], al
    cmp   al, -1
    jne   stop_move
    mov   al, es:[4ah]    ; col number.
    dec   al
    mov   b.snake[0], al  ; return to right.
    jmp   stop_move
    
    move_right:
    mov   al, b.snake[0]
    inc   al
    mov   b.snake[0], al
    cmp   al, es:[4ah]    ; col number.
    jb    stop_move
    mov   b.snake[0], 0   ; return to left.
    jmp   stop_move
    
    move_up:
    mov   al, b.snake[1]
    dec   al
    mov   b.snake[1], al
    cmp   al, -1
    jne   stop_move
    mov   al, es:[84h]    ; row number -1.
    mov   b.snake[1], al  ; return to bottom.
    jmp   stop_move
    
    move_down:
    mov   al, b.snake[1]
    inc   al
    mov   b.snake[1], al
    cmp   al, es:[84h]    ; row number -1.
    jbe   stop_move
    mov   b.snake[1], 0   ; return to top.
    jmp   stop_move
    
    stop_move:
    ret
move_snake endp 

HORA proc
    call clear_screen
    jmp msghora
    hratual DW 'A hora atual e: ',0
    msghora:
    lea si,hratual
    call print_string
    
    mov ah,00h
    int 1Ah
    jmp h1
    ho DB 0
    mi DB 0
    se DB 0
    ho2 DB 0
    mi2 DB 0
    se2 DB 0 
    h100 dw -1h
    m100 dw 444h
    s100 dw 18
    
    h1:
    mov ax,dx
    mov dx,cx
    div h100
    mov ho2,al
    mov ax,dx
    mov dx,0
    div m100
    mov mi2,al
    mov ax,100h
    mul dx
    div s100
    mov se2,ah

    compara:
    cmp ho2,9
    jg th
    cmp mi2,9
    jg tm
    cmp se2,9
    jg ts
    jmp imprimehora
    th:
    mov dx,0
    mov ah,0
    mov al,ho2
    mov bx,10
    div bx
    mov ho,al
    mov ho2,dl
    jmp compara
    tm:
    mov dx,0
    mov ah,0
    mov al,mi2
    mov bx,10
    div bx
    mov mi,al
    mov mi2,dl
    jmp compara
    ts:
    mov dx,0
    mov ah,0
    mov al,se2
    mov bx,10
    div bx
    mov se,al
    mov se2,dl
    jmp compara
    imprimehora:
    add ho,'0'
    add mi,'0'
    add se,'0'
    add ho2,'0'
    add mi2,'0'
    add se2,'0'
    mov ah,0eh
    mov al,ho
    int 10h
    mov al,ho2
    int 10h
    mov al,':'
    int 10h
    mov al,mi
    int 10h
    mov al,mi2
    int 10h
    mov al,':'
    int 10h
    mov al,se
    int 10h
    mov al,se2
    int 10h
    jmp mp
    msghora1    db  0Dh,0Ah,"pressione qualquer tecla...",0Dh,0Ah,0
    mp:
    lea si,msghora1
    call print_string
    mov ah, 0
    int 16h
    ret
HORA endp

CALCULADORA proc
    jmp calculadorastart
    
    
    ; define variables:
    
    msg0 db "==== Calculadora de Inteiros ====",0Dh,0Ah,0Dh,0Ah,0
    msg1 db 0Dh,0Ah, 0Dh,0Ah, 'Entre com o primeiro numero (-100 ate 100): ',0
    msg2 db "Escolha o operador:    +  -  *  /     : ",0
    msg3 db "Entre com o segundo numero (-100 ate 100): ",0
    msg4 db  0dh,0ah , 'O resultado e : ',0 
    msg5 db  0dh,0ah ,'pressione qualquer tecla para voltar ao S.O ...', 0Dh,0Ah,0
    err1 db  "Operador errado!", 0Dh,0Ah , 0
    smth db  " mais alguma coisa.... ",0
    ten  DW  10      
    
    ; operator can be: '+','-','*','/' or 'q' to exit in the middle.
    opr db '?'
    
    ; first and second number:
    num1 dw ?
    num2 dw ?
    
    
    calculadorastart:
    lea si, msg0
    call    print_string
    
    
    lea si, msg1
    call    print_string 
    
    
    ; get the multi-digit signed number
    ; from the keyboard, and store
    ; the result in cx register:
    
    call scan_num
    
    ; store first number:
    mov num1, cx 
    
    
    
    ; new line:
    putc 0Dh
    putc 0Ah
    
    
    
    
    lea si, msg2
    call    print_string  
    
    
    ; get operator:
    mov ah, 00h   ; single char input to AL.
    int 16h
    mov ah,0Eh
    int 10h
    mov opr, al
    
    
    
    ; new line:
    putc 0Dh
    putc 0Ah
    
    
    cmp opr, 'q'      ; q - exit in the middle.
    je exit
    
    cmp opr, '*'
    jb wrong_opr
    cmp opr, '/'
    ja wrong_opr
    
    
    
    
    
    
    ; output of a string at ds:dx
    lea si, msg3
    call    print_string  
    
    
    ; get the multi-digit signed number
    ; from the keyboard, and store
    ; the result in cx register:
    
    call scan_num
    
    
    ; store second number:
    mov num2, cx 
    
    
    
    
    lea si, msg4
    call    print_string  
    
    
    
    
    ; calculate:
    
    
    
    
    
    cmp opr, '+'
    je do_plus
    
    cmp opr, '-'
    je do_minus
    
    cmp opr, '*'
    je do_mult
    
    cmp opr, '/'
    je do_div
    
    
    ; none of the above....
    wrong_opr:
    lea si, err1
    call    print_string  
    
    
    calculadoraexit:
    ; output of a string at ds:dx
    lea si, msg5
    call    print_string 
    
    
    ; wait for any key...
    mov ah, 0
    int 16h
    
    
    ret  ; return back to os.
    
    
    
    
    
    
    
    
    
    
    
    do_plus:
    
    
    mov ax, num1
    add ax, num2
    call print_num    ; print ax value.
    
    jmp calculadoraexit
    
    
    
    do_minus:
    
    mov ax, num1
    sub ax, num2
    call print_num    ; print ax value.
    
    jmp calculadoraexit
    
    
    
    
    do_mult:
    
    mov ax, num1
    imul num2 ; (dx ax) = ax * num2. 
    call print_num    ; print ax value.
    ; dx is ignored (calc works with tiny numbers only).
    
    jmp calculadoraexit
    
    
    
    
    do_div:
    ; dx is ignored (calc works with tiny integer numbers only).
    mov dx, 0
    mov ax, num1
    idiv num2  ; ax = (dx ax) / num2.
    cmp dx, 0
    jnz approx
    call print_num    ; print ax value.
    jmp calculadoraexit
    approx:
    call print_num    ; print ax value.
    lea si, smth
    call print_string 
    jmp calculadoraexit

CALCULADORA endp



SCAN_NUM        PROC    NEAR
            PUSH    DX
            PUSH    AX
            PUSH    SI
            
            MOV     CX, 0
    
            ; reset flag:
            MOV     CS:make_minus, 0
    
    next_digit:
    
            ; get char from keyboard
            ; into AL:
            MOV     AH, 00h
            INT     16h
            ; and print it:
            MOV     AH, 0Eh
            INT     10h
    
            ; check for MINUS:
            CMP     AL, '-'
            JE      set_minus
    
            ; check for ENTER key:
            CMP     AL, 0Dh  ; carriage return?
            JNE     not_cr
            JMP     stop_input
    not_cr:
    
    
            CMP     AL, 8                   ; 'BACKSPACE' pressed?
            JNE     backspace_checked
            MOV     DX, 0                   ; remove last digit by
            MOV     AX, CX                  ; division:
            DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
            MOV     CX, AX
            PUTC    ' '                     ; clear position.
            PUTC    8                       ; backspace again.
            JMP     next_digit
    backspace_checked:
    
    
            ; allow only digits:
            CMP     AL, '0'
            JAE     ok_AE_0
            JMP     remove_not_digit
    ok_AE_0:        
            CMP     AL, '9'
            JBE     ok_digit
    remove_not_digit:       
            PUTC    8       ; backspace.
            PUTC    ' '     ; clear last entered not digit.
            PUTC    8       ; backspace again.        
            JMP     next_digit ; wait for next input.       
    ok_digit:
    
    
            ; multiply CX by 10 (first time the result is zero)
            PUSH    AX
            MOV     AX, CX
            MUL     CS:ten                  ; DX:AX = AX*10
            MOV     CX, AX
            POP     AX
    
            ; check if the number is too big
            ; (result should be 16 bits)
            CMP     DX, 0
            JNE     too_big
    
            ; convert from ASCII code:
            SUB     AL, 30h
    
            ; add AL to CX:
            MOV     AH, 0
            MOV     DX, CX      ; backup, in case the result will be too big.
            ADD     CX, AX
            JC      too_big2    ; jump if the number is too big.
    
            JMP     next_digit
    
    set_minus:
            MOV     CS:make_minus, 1
            JMP     next_digit
    
    too_big2:
            MOV     CX, DX      ; restore the backuped value before add.
            MOV     DX, 0       ; DX was zero before backup!
    too_big:
            MOV     AX, CX
            DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
            MOV     CX, AX
            PUTC    8       ; backspace.
            PUTC    ' '     ; clear last entered digit.
            PUTC    8       ; backspace again.        
            JMP     next_digit ; wait for Enter/Backspace.
            
            
    stop_input:
            ; check flag:
            CMP     CS:make_minus, 0
            JE      not_minus
            NEG     CX
    not_minus:
    
            POP     SI
            POP     AX
            POP     DX
            RET
    make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP





; this procedure prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
PRINT_NUM       PROC    NEAR
            PUSH    DX
            PUSH    AX
    
            CMP     AX, 0
            JNZ     not_zero
    
            PUTC    '0'
            JMP     calculadoraprinted
    
    not_zero:
            ; the check SIGN of AX,
            ; make absolute if it's negative:
            CMP     AX, 0
            JNS     positive
            NEG     AX
    
            PUTC    '-'
    
    positive:
            CALL    PRINT_NUM_UNS
    calculadoraprinted:
            POP     AX
            POP     DX
            RET
PRINT_NUM       ENDP



; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
            PUSH    AX
            PUSH    BX
            PUSH    CX
            PUSH    DX
    
            ; flag to prevent printing zeros before number:
            MOV     CX, 1
    
            ; (result of "/ 10000" is always less or equal to 9).
            MOV     BX, 10000       ; 2710h - divider.
    
            ; AX is zero?
            CMP     AX, 0
            JZ      print_zero
    
    begin_print:
    
            ; check divider (if zero go to end_print):
            CMP     BX,0
            JZ      end_print
    
            ; avoid printing zeros before number:
            CMP     CX, 0
            JE      calc
            ; if AX<BX then result of DIV will be zero:
            CMP     AX, BX
            JB      skip
    calc:
            MOV     CX, 0   ; set flag.
    
            MOV     DX, 0
            DIV     BX      ; AX = DX:AX / BX   (DX=remainder).
    
            ; print last digit
            ; AH is always ZERO, so it's ignored
            ADD     AL, 30h    ; convert to ASCII code.
            PUTC    AL
    
    
            MOV     AX, DX  ; get remainder from last div.
    
    skip:
            ; calculate BX=BX/10
            PUSH    AX
            MOV     DX, 0
            MOV     AX, BX
            DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
            MOV     BX, AX
            POP     AX
    
            JMP     begin_print
            
    print_zero:
            PUTC    '0'
            
    end_print:
    
            POP     DX
            POP     CX
            POP     BX
            POP     AX
            RET
PRINT_NUM_UNS   ENDP 

FATORIAL proc

    jmp fatorialstart
    
    
    fatorialresult dw ?
    fatorialmsg5 db  0dh,0ah ,'pressione qualquer tecla para voltar ao S.O ...', 0Dh,0Ah,0     
    
    
    fatorialstart:
    
    lea si,fatorialmsg1
    call print_string
    
    jmp fatorialn1
    fatorialmsg1 db 0Dh,0Ah, 'Entre com um numero (0 ate 8): ',0
    fatorialn1:
    
    call    scan_num
    
    
    ; factorial of 0 = 1:
    mov     ax, 1
    cmp     cx, 0
    je      fatorialprint_result
    
    ; move the number to bx:
    ; cx will be a counter:
    
    mov     bx, cx
    
    mov     ax, 1
    mov     bx, 1
    
    fatorialcalc_it:
    mul     bx
    cmp     dx, 0
    jne     fatorialoverflow
    inc     bx
    loop    fatorialcalc_it
    
    mov fatorialresult, ax
    
    
    fatorialprint_result:
    
    ; print result in ax:
    lea si, fatorialmsg2
    call print_string
    jmp fatorialn2
    fatorialmsg2 db 0Dh,0Ah, 'Fatorial: ',0
    fatorialn2:
    
    
    lea     si, fatorialresult
    call    print_num_uns
    jmp     fatorialexit
    
    
    fatorialoverflow:
    lea si, fatorialmsg3
    call print_string
    jmp fatorialn3
    fatorialmsg3 db 0Dh,0Ah, 'O resultado e muito grande!', 0Dh,0Ah, 'use numeros de 0 a 8.',0
    fatorialn3:
    jmp     fatorialstart
    
    fatorialexit:
    lea si,fatorialmsg5
    call print_string
    
    mov ah, 0
    int 16h
    ret

FATORIAL endp
