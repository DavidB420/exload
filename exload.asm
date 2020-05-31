;Extended loader for DavidDOS Made by David Badiei
org 4000h

;check disk params
mov byte [bootdev],dl
cmp dl,0
je start
push es
mov ah,8
int 13h
pop es
and cx,3fh
mov word [SectorsPerTrack],cx
mov dl,dh
xor dh,dh
add dx,1
mov word [Sides],dx

start:
mov si,userPrompt
call print_string

mov cx,0
mov di,progFN
call getinput

call loadprog

doneprog:
ret

bootdev db 0
userPrompt db 'Enter file name: ',0

print_string:
mov ah,0eh
loop:
lodsb
test al,al
jz done
int 10h
jmp loop
done:
ret

getinput:
	mov ah,0
	int 16h
	cmp al,08h
	je delchar
	cmp al,0dh
	je entpress
	cmp al,3fh
	je getinput
	mov ah,0eh
	int 10h
	stosb
	inc cx
	jmp getinput
	delchar:
		cmp cx,0
		je getinput
		mov ah,0eh
		mov al,08h
		int 10h
		mov al,20h
		int 10h
		mov al,08h
		int 10h
		sub cx,1
		dec di
	    mov byte [di], 0
		jmp getinput
	entpress:
	   mov al,0
	   stosb
	   mov ah,0eh
	   mov al,0dh
	   int 10h
	   mov al,0ah
	   int 10h
	   ret

loadprog:
mov si,progFN
mov di,fat12fn
call makefnfat12
skipmakefat12:
mov ax,19
call twelvehts2
mov dl,byte [bootdev]
mov ah,2
mov al,14
mov si,disk_buffer
mov bx,si
int 13h
mov di,disk_buffer
mov si,fat12fn
mov bx,0
mov ax,0
findfn:
mov cx,11
cld
repe cmpsb
je foundfn
inc bx
add ax,32
mov si,fat12fn
mov di,disk_buffer
add di,ax
cmp bx,224
jle findfn
foundfn:
mov ax,32
mul bx
mov di,disk_buffer
add di,ax
push ax
mov ax,word [di+1ch]
mov word[fileSize],ax
pop ax
mov ax,word [di+1Ah]
mov word [cluster],ax
push ax
mov ax,1
call twelvehts2
mov dl,byte [bootdev]
mov ah,2
mov al,9
mov si,fat
mov bx,si
int 13h
pop ax
push ax
mov di,file
mov bx,di
call twelvehts
push es
mov ax,1000h
mov es,ax
mov ax,0201h
int 13h
pop es
mov bp,0
pop ax
loadnextclust:
mov cx,ax
mov dx,ax
shr dx,1
add cx,dx
mov bx,fat
add bx,cx
mov dx,word [bx]
test ax,1
jnz odd
even:
and dx,0fffh
jmp end
odd:
shr dx,4
end:
mov ax,dx
mov word [cluster],dx
call twelvehts
add bp,512
mov si,file
add si,bp
mov bx,si
push es
mov ax,1000h
mov es,ax
mov ax,0201h
int 13h
pop es
mov dx,word [cluster]
mov ax,dx
cmp dx,0ff0h
jb loadnextclust
mov dl,byte [bootdev]
mov ax,0003h
int 10h
push ds
push es
mov ax,1000h
mov ds,ax
mov es,ax
call 1000h:4000h
pop es
pop ds
jmp doneprog

SectorsPerTrack dw 18
Sides dw 2
fileSize dw 0
cluster dw 0
fat12fn times 13 db 0
progFN times 13 db 0
disk_buffer equ 2000h
fat equ 0ac00h
file equ 4000h

makefnfat12:
call getStringLength
xor dh,dh
sub si,dx
call makeCaps
sub si,dx
mov cx,0
mov bx,di
copytonewstr:
lodsb
cmp al,'.'
je extfound
stosb
inc cx
jmp copytonewstr
extfound:
cmp cx,8
je addext
addspaces:
mov byte [di],' '
inc di
inc cx
cmp cx,8
jl addspaces
addext:
lodsb
stosb
lodsb
stosb
lodsb
stosb
mov al,0
stosb
ret

getStringLength:
mov dl,0
loopstrlength:
cmp byte [si],0
jne inccounter
cmp byte [si],0
je donestrlength
jmp loopstrlength
inccounter:
inc dl
inc si
jmp loopstrlength
donestrlength:
ret

makeCaps:
cmp byte [si],0
je doneCaps
cmp byte [si],61h
jl notatoz
cmp byte [si],7ah
jg notatoz
sub byte [si],20h
notatoz:
inc si
jmp makeCaps
doneCaps:
ret

twelvehts:
add ax,31
twelvehts2:
push bx
push ax
mov bx,ax
mov dx,0
div word [SectorsPerTrack]
add dl,01h
mov cl,dl
mov ax,bx
mov dx,0
div word [SectorsPerTrack]
mov dx,0
div word [Sides]
mov dh,dl
mov ch,al
pop ax
pop bx
mov dl,byte [bootdev]
ret
