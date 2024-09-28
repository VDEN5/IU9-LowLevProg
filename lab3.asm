.model small
.stack 100h

.data
    array dw 1, -2, 3, -4, 5, -6, 7, -8, 9, -10
    array_size dw 10
    count dw 0
    msg1 db 'numbers of positive: $'
    msg2 db '0$'

.code
main proc
    mov ax, @data
    mov ds, ax

    mov cx, array_size       ; Загружаем размер массива в CX
    mov si, 0                 ; Инициализируем SI для доступа к массиву

count_positive:
    mov bx, [array + si]      ; Загружаем элемент массива в BX
    cmp bx, 0                ; Сравниваем элемент с 0
    jl next                  ; Если меньше 0, переходим к следующему элементу
    inc count                ; Увеличиваем счетчик положительных элементов
next:
    add si, 2                ; Переходим к следующему элементу массива
    loop count_positive      ; Повторяем цикл до тех пор, пока CX не станет 0

    ; Вывод результата
    mov ah, 9                ; Вывод строки
    lea dx, msg1             ; Загружаем адрес сообщения 1 в DX
    int 21h

    cmp count, 0             ; Сравниваем счетчик с 0
    je zero_count            ; Если count равен 0, переходим к выводу "0"

    mov ax, count             ; Загружаем счетчик в AX для вывода
    mov bx, 10              ; Делитель для перевода в десятичную систему
    mov cx, 0                ; Счетчик цифр в числе
    mov dx, 0                ; Остаток от деления

convert_decimal:
    div bx                   ; Делим AX на 10
    push dx                  ; Сохраняем остаток в стеке
    inc cx                   ; Увеличиваем счетчик цифр
    test ax, ax              ; Проверяем, равен ли результат деления 0
    jnz convert_decimal     ; Если не равен 0, продолжаем деление

print_decimal:
    pop dx                   ; Извлекаем остаток из стека
    add dx, '0'              ; Преобразуем остаток в ASCII-код символа
    mov ah, 2                ; Вывод символа
    mov dl, dl              ; Загружаем ASCII-код в DL
    int 21h
    dec cx                   ; Уменьшаем счетчик цифр
    jnz print_decimal       ; Если счетчик не 0, продолжаем вывод
    jmp exit

zero_count:
    mov ah, 9                ; Вывод строки
    lea dx, msg2             ; Загружаем адрес сообщения 2 в DX
    int 21h

exit:
    mov ah, 4ch              ; Прекращаем программу
    int 21h

main endp
end main
