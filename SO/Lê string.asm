name "Ler e imprime arquivo txt"

org  100h

jmp inicio

s1 DB 100,?, 100 dup(' ')
fname DB 30,?, 30 dup(' ') 
handle DW ?
inicio:
jmp m
msg DB 0Dh,0Ah,"Entre com o nome do arquivo: $"
m: 
mov dx,offset msg
mov ah,9
int 21h

;ler o nome do arquivo

mov dx,offset fname
mov ah,0ah
int 21h

xor bx,bx
mov bl,fname[1]
mov fname[bx+2],0 

;abre o arquivo

mov al,0
mov ah,3dh
mov dx,offset fname+2
int 21h
jc erro
mov handle,ax

;ler bytes do arquivo

mov ah,3fh
mov bx,handle
xor cx,cx
mov cl,s1[0]
mov dx, offset s1[2]
int 21h
jc erro
mov s1[1],al

;fecha arquivo

jmp m2
msg2 db 0Dh,0Ah,"Lidos do arquivo: $"
m2:
mov dx,offset msg2
mov ah,9
int 21h

xor bx,bx
mov bl,s1[1]
mov s1[bx+2],'$'

;imprime a string

mov dx,offset s1[2]
mov ah,9
int 21h
jmp ok

erro:

jmp m3
msg3 DB 0Dh,0Ah,"error...",0Dh,0Ah,'$'
m3: 
mov dx,offset msg3
mov ah,9
int 21h 

ok:     
 
jmp m4
msg4 DB 0Dh,0Ah,"Precione qualquer tecla...",0Dh,0Ah,'$'
m4: 
mov dx,offset msg4
mov ah,9
int 21h

mov ah,0
int 16h 

mov ah,4ch
int 21h