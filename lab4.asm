; Файл lab4.asm
.model small
.stack 100h

.data
    Xq db 2               ;2 Количество сдвигов
    Rq db 12;3
    msg1 db 'shift R to X: $'
    msg4 db 13, 10, '$'
.code
SHIFT MACRO a, b 
  LOCAL SHIFT_LOOP 
  push cx        ; Сохраняем регистры 
  push si 
 
  mov si, OFFSET a    ; Указатель на значение a 
  mov al, [si]      ; Загружаем a в al 
  mov cl, b         ; Сдвиг по количеству из b 
 
  cmp b, 0          ; Сравниваем b с 0 
  jl DIVIDE_BY_TWO   ; Если b отрицательное, переходим к делению на 2 
  jmp SHIFT_LOOP     ; Иначе продолжаем сдвиг влево 
 
DIVIDE_BY_TWO:
;neg cl 
  neg cl              ; Меняем знак (так как b отрицательное, делим на 2 - b раз)
  mov bl, 2           ; Делитель (2)  
  xor ah, ah          ; Очищаем ah, чтобы деление произошло корректно  
DIVIDE_LOOP:  
  div bl              ; Делим (al) на 2  
  dec cl              ; Уменьшаем счетчик   
  jnz DIVIDE_LOOP     ; Повторяем, пока cl не станет 0  
  jmp END_SHIFT    
SHIFT_LOOP: 
  add al, al       ; Умножаем al на 2 (сдвиг влево на 1) 
  loop SHIFT_LOOP   ; Повторяем до cx  
END_SHIFT: 
  mov [si], al      ; Сохраняем результат обратно в a 
  pop si            ; Восстанавливаем регистры 
  pop cx 
ENDM
PRINT_NUM PROC
    push ax
    push bx
    push cx
    push dx
    
    test al, al        ; Проверяем знак
    jns positive
    push ax
    mov dl, '-'        ; Выводим минус
    mov ah, 02h
    int 21h
    pop ax
    neg al             ; Делаем число положительным
positive:
    mov bl, 10
    xor ah, ah
    div bl             ; Делим на 10
    push ax            ; Сохраняем остаток
    cmp al, 0          ; Если частное не 0
    jne recursive      ; продолжаем рекурсию
    pop ax             ; Иначе восстанавливаем число
    mov dl, ah         ; и выводим последнюю цифру
    add dl, '0'
    mov ah, 02h
    int 21h
    jmp print_done
recursive:
    call PRINT_NUM     ; Рекурсивный вызов для оставшейся части
    pop ax             ; Восстанавливаем остаток
    mov dl, ah         ; и выводим его
    add dl, '0'
    mov ah, 02h
    int 21h
print_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_NUM ENDP

main PROC
    mov ax, @data
    mov ds, ax
    SHIFT Rq, Xq
    mov dx, OFFSET msg1
    mov ah, 09h
    int 21h
    mov al, Rq
    call PRINT_NUM
    mov dx, OFFSET msg4
    mov ah, 09h
    int 21h
    mov ax, 4C00h
    int 21h
main ENDP
END main
