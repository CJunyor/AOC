name "Armazena String"

org  100h

jmp start

s1        db 100,?, 100 dup(' ') 
t2        db 100,?, 100 dup(' ')
filename  db 30,?, 30 dup(' ')   ; file name should be in 8.3 - dos compatible format.


; file handle:
handle   dw   0


; set segment registers to code:
start:  mov ax, cs
        mov ds, ax
        mov es, ax

jmp m1
msg1    db  "Entre com a string: $"
m1:     mov dx, offset msg1
        mov ah, 9
        int 21h
; input a string:
        mov dx, offset s1
        mov ah, 0ah
        int 21h



jmp m2
msg2    db  0Dh,0Ah,"Entre com o nome do arquivo: $"
m2:     mov dx, offset msg2
        mov ah, 9
        int 21h
; input filename:
        mov dx, offset filename
        mov ah, 0ah
        int 21h

; set 0 to the end of the filename:
        xor bx, bx
        mov bl, filename[1]  ; get actual size.
        mov filename[bx+2], 0

; create new file:
        mov cx, 0
        mov ah, 3ch
        mov dx, offset filename+2
        int 21h
        jc  error
        mov handle, ax
; write buffer to file:
        mov ah, 40h
        mov bx, handle        
        mov dx, offset s1+2
        xor cx, cx
        mov cl, s1[1]
        int 21h
        jc  error
; close file
        mov bx, handle
        mov ah, 3eh
        int 21h
        jc error 
        jmp ok 
; print error message:
error:  jmp m5
        msg5    db  0Dh,0Ah,"error...",0Dh,0Ah,'$'
        m5:     mov dx, offset msg5
                mov ah, 9
                int 21h 
                
ok:               
jmp m4
msg4    db  0Dh,0Ah,"precione qualquer tecla...",0Dh,0Ah,'$'
m4:     mov dx, offset msg4
        mov ah, 9
        int 21h        
        mov ah, 0
        int 16h


; exit to the operating system:
        mov ah, 4ch
        int 21h
