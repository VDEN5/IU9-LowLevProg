assume cs:code, ds:data

data segment
    text1 db "Input first string: $"
    text2 db 13, 10, "Input second string: $"
    newline db 0Dh, 0Ah, '$'
    str1 db 100, 99 dup('$')  
    str2 db 100, 99 dup('$')
    result_msg db 13, 10, "Length of the first string before any character from the second string: $"
data ends

code segment

strcspn proc
    push bp 
    mov bp, sp
    mov si, [bp+6]       ; str1
    mov di, [bp+4]       ; str2

    add si, 2            ; указатель на начало строки str1
    add di, 2            ; указатель на начало строки str2

    xor cx, cx           ; начальная длина до первого совпадения

check_loop:
    mov al, [si]         ; взять символ из str1
    cmp al, '$'          ; проверить конец строки
    je finish             ; Если конец строки, заканчиваем
    
    ; Проверка, есть ли al в str2
    mov bx, di           ; сохраняем указатель на str2
test_found:
    mov dl, [bx]         ; взять символ из str2
    cmp dl, '$'          ; проверить конец str2
    je not_found         ; Если конец str2, значит нет совпадений
    
    cmp al, dl           ; сравнить с символом str2
    je finish            ; Если нашли совпадение, то выходим
    
    inc bx               ; переходим к следующему символу str2
    jmp test_found       ; продолжаем проверку

not_found:
    inc cx               ; Увеличиваем счетчик длины, если совпадений не было
    inc si               ; Переход к следующему символу str1
    jmp check_loop       ; продолжаем проверку

finish:
    pop bp
    mov ax, cx           ; возвращаем длину
    ret             
strcspn endp

start:
    mov ax, data
    mov ds, ax

    ; Ввод первой строки
    mov ah, 09h
    mov dx, offset text1
    int 21h

    mov ah, 0Ah
    mov dx, offset str1
    int 21h
    
    push dx               ; адрес первой строки в стеке

    ; Ввод второй строки
    mov ah, 09h
    mov dx, offset text2
    int 21h
    
    mov ah, 0Ah
    mov dx, offset str2
    int 21h
    
    push dx               ; адрес второй строки в стеке

    call strcspn         ; вызов функции strcspn
    pop dx                ; убрать адрес второй строки
    push ax               ; сохраняем результат в стеке для дальнейшего использования

    ; Вывод результата
    mov ah, 09h
    mov dx, offset result_msg
    int 21h

    ; Обработка и вывод числа
    pop ax                ; получаем длину
    call print_number      ; вывод числа 

    mov ah, 09h
    mov dx, offset newline
    int 21h

    mov ax, 4C00h
    int 21h

print_number proc
    ; Преобразование числа в строку и вывод его на экран
    xor cx, cx           ; обнуляем счетчик

    mov bx, 10           ; основание
convert:
    xor dx, dx
    div bx                ; делим ax на 10
    push dx               ; сохраняем остаток
    inc cx                ; увеличиваем счетчик цифр
    test ax, ax
    jnz convert           ; продолжаем пока не закончилось число

print_loop:
    pop dx                ; получаем цифру
    add dl, '0'           ; преобразуем в символ
    mov ah, 02h
    int 21h               ; выводим символ
    loop print_loop       ; пока есть цифры для вывода 

    ret
print_number endp

code ends
end start
