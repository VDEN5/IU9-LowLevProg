; TASM:
; TASM /m PM.asm
; TLINK /x /3 PM.obj
; PM.exe

        .386p                                  ; Разрешить привилегированные инструкции i386

; СЕГМЕНТ КОДА (для Real Mode)
; ----------------------------------------------------------------------------------
RM_CODE     segment     para public 'CODE' use16
        assume      CS:RM_CODE,SS:RM_STACK    ; Предположим, что сегмент кода и стек
   
@@start:
                    mov                 AX,03h   ; Установить текстовый режим 80x25 + очистка экрана
                    int                 10h       

; Открываем линию A20 (для 32-х битной адресации):
        in      AL,92h                       ; Читаем состояние A20 в AL
        or      AL,2                          ; Включаем линию A20
        out     92h,AL                        ; Записываем измененное состояние обратно в регистр

; Вычисляем линейный адрес метки ENTRY_POINT (точка входа в защищенный режим):
        xor     EAX,EAX                       ; Обнуляем регистр EAX
        mov     AX,PM_CODE                    ; AX = номер сегмента PM_CODE
        shl     EAX,4                         ; EAX = линейный адрес PM_CODE
        add     EAX,offset ENTRY_POINT        ; EAX = линейный адрес ENTRY_POINT
        mov     dword ptr ENTRY_OFF,EAX       ; Сохраняем его в переменной

; Теперь надо вычислить линейный адрес GDT (для загрузки регистра GDTR):
        xor     EAX,EAX                       ; Обнуление EAX
        mov     AX,RM_CODE                    ; AX = номер сегмента RM_CODE
        shl     EAX,4                         ; EAX = линейный адрес RM_CODE
        add     AX,offset GDT                 ; Теперь EAX = линейный адрес GDT

; Линейный адрес GDT кладем в заранее подготовленную переменную:
        mov     dword ptr GDTR+2,EAX          ; Сохраняем адрес GDT в GDTR

; Собственно, загрузка регистра GDTR:
        lgdt        fword ptr GDTR            ; Загружаем GDT

; Запрет маскируемых прерываний:
        cli                                     ; Отключение прерываний

; Запрет немаскируемых прерываний:
        in      AL,70h
        or      AL,80h
        out     70h,AL

; Переключение в защищенный режим:
        mov     EAX,CR0                       ; Читаем регистр CR0 в EAX
        or      AL,1                          ; Устанавливаем бит 0 для перехода в защищенный режим
        mov     CR0,EAX                       ; Записываем обратно в регистр CR0

; Загрузить новый селектор в регистр CS
        db      66h                           ; Префикс изменения разрядности операнда
        db      0EAh                          ; Опкод команды JMP FAR
ENTRY_OFF   dd      ?                        ; 32-битное смещение для перехода
        dw      00001000b                    ; Селектор первого дескриптора (CODE_descr)

; ТАБЛИЦА ГЛОБАЛЬНЫХ ДЕСКРИПТОРОВ:
GDT:  
; Нулевой дескриптор (обязательно должен присутствовать в GDT!):
NULL_descr  db      8 dup(0)                ; Нулевой дескриптор
CODE_descr  db      0FFh,0FFh,00h,00h,00h,10011010b,11001111b,00h  ; Дескриптор кода
DATA_descr  db      0FFh,0FFh,00h,00h,00h,10010010b,11001111b,00h  ; Дескриптор данных
MY_descr1   db      0FFh,0FFh,01h,00h,00h,10010000b,11001111b,00h  ; Другой дескриптор 1
MY_descr2   db      0FFh,0FFh,02h,00h,00h,10010001b,11001111b,00h  ; Другой дескриптор 2

GDT_size    equ         $-GDT                ; Размер GDT
 
GDTR        dw      GDT_size-1              ; 16-битный лимит GDT
   dd      ?                                 ; Здесь будет 32-битный линейный адрес GDT

RM_CODE         ends
; -----------------------------------------------------------------------------
 
; СЕГМЕНТ СТЕКА (для Real Mode)
; -----------------------------------------------------------------------------
RM_STACK       segment          para stack 'STACK' use16
            db     100h dup(?)         ; 256 байт под стек - достаточно
RM_STACK       ends
; -----------------------------------------------------------------------------
 
; СЕГМЕНТ КОДА (для Protected Mode)
; -----------------------------------------------------------------------------
PM_CODE     segment     para public 'CODE' use32
        assume      CS:PM_CODE,DS:PM_DATA   ; Предположим, что сегменты кода и данных

base proc
    mov esi, edx                     ; Загружаем адрес в ESI
    xor eax, eax                     ; Обнуление EAX
    mov ah, byte ptr [esi + 7]      ; Получаем определенные байты
    mov al, byte ptr [esi + 4]
    rept 16                          ; Процесс выполнения 16 раз
        shl eax, 1
    endm
    mov ah, byte ptr [esi + 3]      ; Получаем еще определенные байты
    mov al, byte ptr [esi + 2]
    ret
endp

dls proc
    mov esi, edx                     ; Загружаем адрес в ESI
    xor eax, eax                     ; Обнуление EAX
    mov al, byte ptr [esi + 5]      ; Получаем информацию из дескриптора
    shl al, 1                        ; Сдвигаем значение влево
    rept 6                           ; Выполняем 6 раз
        shr al, 1                    ; Сдвигаем значение вправо
    endm
    ret                              ; Возврат из процедуры
endp

present proc
    mov esi, edx                     ; Загружаем адрес в ESI
    xor eax, eax                     ; Обнуление EAX
    mov al, byte ptr [esi + 5]      ; Получаем информацию о представленности
    rept 7                           ; Выполняем 7 раз
        shr al, 1                    ; Сдвигаем значение вправо
    endm
    ret                              ; Возврат из процедуры
endp

avl proc
    mov esi, edx                     ; Загружаем адрес в ESI
    xor eax, eax                     ; Обнуление EAX
    mov al, byte ptr [esi + 6]      ; Получаем информацию о доступности
    rept 3                           ; Выполняем 3 раза
        shl al, 1                    ; Сдвигаем значение влево
    endm
    rept 7                           ; Выполняем 7 раз
        shr al, 1                    ; Сдвигаем значение вправо
    endm
    ret                              ; Возврат из процедуры
endp

bits proc
    mov esi, edx                     ; Загружаем адрес в ESI
    xor eax, eax                     ; Обнуление EAX
    mov al, byte ptr [esi + 6]      ; Берем значение из дескриптора
    shl al, 1                        ; Сдвигаем значение влево
    rept 7                           ; Выполняем 7 раз
        shr al, 1                    ; Сдвигаем значение вправо
    endm
    ret                              ; Возврат из процедуры
endp

mode proc
    mov esi, edx                     ; Загружаем адрес в ESI
    xor eax, eax                     ; Обнуление EAX
    mov al, byte ptr [esi + 5]      ; Получаем режим из дескриптора
    rept 4                           ; 
        shl al, 1                    ; Сдвигаем значение влево
    endm
    rept 4                           ; 
        shr al, 1                    ; Сдвигаем значение вправо
    endm
    ret                              ; Возврат из процедуры
endp

limit proc
    mov esi, edx                     ; Загружаем адрес в ESI
    xor eax, eax                     ; Обнуление EAX
    mov al, byte ptr [esi + 6]      ; Считываем лимит
    rept 4                           ; 
        shl al, 1                    ; Сдвигаем значение влево
    endm
    rept 8                           ; 
        shl eax, 1                    ; Удваиваем лимит
    endm
    mov ah, byte ptr [esi + 1]      ; Получаем лимит старших байтов
    mov al, byte ptr [esi]           ; Получаем лимит младших байтов
    push bx                          ; Сохраняем BX
    mov bl, byte ptr [esi + 6]      ; Загружаем информацию о лимите
    rept 7                           ; 
        shr bl, 1                    ; Уменьшаем лимит
    endm
    add eax, 1                       ; Увеличиваем EAX на 1
    cmp bl, 1                        ; Сравниваем с 1
    je multy                         ; Если совпадает, переход к multy
    jmp skip
    multy:
        imul eax, 1000h              ; Умножаем на 4096
    skip:
    pop bx                           ; Восстанавливаем BX
    ret                              ; Возврат из процедуры
endp
 
maths proc
    push edx                         ; Сохраняем EDX
    cmp al, 10                       ; Проверяем значение AL
    mov ah, al                       ; Сохраняем его в AH
    jl notadd                       ; Если меньше, переходим к notadd
    add al, 7                        ; Иначе, корректируем
    notadd:
    add al, 30h                      ; Переводим в символ
    mov [edi], al                   ; Сохраняем в видеопамяти
    mov dl, ch                       ; Устанавливаем DL равным CH
    add dl, 1                        ; Увеличиваем по счетчику символов
    cmp dl, 16                       ; Проверяем предел
    jl write                         ; Если меньше 16, записываем
    sub dl, 15                       ; Иначе вычитаем
    write:
    mov [edi + 1], dl                ; Записываем символ
    mov al, ah                       ; Реконструируем значение для возврата
    pop edx                         ; Восстанавливаем EDX
    ret                              ; Возврат из процедуры
endp

basepr proc
    push eax
    push ebx
    push ecx
    push edx
    mov ebx, eax                     ; Сохраняем EAX в EBX для расчетов
    cmp eax, 0FFFFFFFFh             ; Проверяем значение на максимум
    irp count, <28, 24, 20, 16, 12, 8, 4, 0>
        mov eax, ebx                 ; Копируем значение из EBX обратно в EAX
        rept count
            shr eax, 1               ; Сдвиг EAX
        endm
        call maths                   ; Вызываем процедуры для расчетов
        add EDI, 2                   ; Увеличиваем адрес для вывода
        rept count
            shl eax, 1               ; Возврат на прошлое значение
        endm
        sub ebx, eax                 ; Корректируем значение EBX
    endm
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret                              ; Возврат из процедуры
endp

dlspr proc
    push eax
    push ebx
    push ecx
    push edx
    mov ebx, eax                     ; Сохраняем EAX в EBX
    cmp eax, 0FFFFFFFFh             ; Проверяем значение на максимум
    irp count, <1, 0>
        mov eax, ebx                 ; Копируем значение из EBX
        rept count
            shr eax, 1               ; Сдвиг в сторону
        endm
        call maths                   ; Вызываем процедуры для расчетов
        add EDI, 2                   ; Увеличиваем адрес для вывода
        rept count
            shl eax, 1               ; Возврат на прежнее значение
        endm
        sub ebx, eax                 ; Корректируем EBX
    endm
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret                              ; Возврат из процедуры
endp

dataxpr proc
    cmp al, 2                        ; Проверяем значение AL
    jge data01                       ; Если больше или равно 2, переходим к data01
    push ax
    mov al, 27                        ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call anyxxpr                     ; Вызываем процедуру
    ret
    data01:
    sub al, 2                        ; Уменьшаем AL
    push ax
    mov al, 32                        ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call anyxxpr                     ; Вызываем процедуру
    ret
endp

datapr proc
    cmp al, 4                        ; Проверяем значение AL
    jge data1                        ; Если больше или равно 4, переходим к data1
    push ax
    push dx
    mov [edi], 24                    ; Сохраняем информацию о символе ↑
    mov dl, ch                       ; Устанавливаем DL равным CH
    add dl, 1                        ; Увеличиваем по счетчику
    cmp dl, 16                       ; Проверяем предел
    jl write1                       ; Если меньше 16, записываем
    sub dl, 15                       ; Иначе вычитаем
    write1:
    mov [edi + 1], dl                ; Записываем информацию в видеопамяти
    add EDI, 2                       ; Увеличиваем адрес
    pop dx
    pop ax
    call dataxpr                     ; Вызываем процедуру
    ret
    data1:
    sub al, 4                        ; Уменьшаем AL
    push ax
    push dx
    mov [edi], 25                    ; Сохраняем информацию о символе ↑
    mov dl, ch                       ; Устанавливаем DL равным CH
    add dl, 1                        ; Увеличиваем по счетчику
    cmp dl, 16                       ; Проверяем предел
    jl write2                       ; Если меньше 16, записываем
    sub dl, 15                       ; Иначе вычитаем
    write2:
    mov [edi + 1], dl                ; Записываем информацию в видеопамяти
    add EDI, 2                       ; Увеличиваем адрес
    pop dx
    pop ax
    call dataxpr                     ; Вызываем процедуру
    ret
endp

anyxxpr proc
    cmp al, 1                        ; Проверка значения AL
    je code001                       ; Если равно 1, переходим к code001
    push ax
    mov al, 23                       ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    ret
    code001:
    sub al, 1                        ; Уменьшаем AL
    push ax
    mov al, 10                       ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    ret
endp

codexpr proc
    cmp al, 2                        ; Проверяем значение AL
    jge code01                       ; Если больше или равно 2, переходим к code01
    push ax
    mov al, 14                       ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call anyxxpr                     ; Вызываем процедуру
    ret
    code01:
    sub al, 2                        ; Уменьшаем AL
    push ax
    mov al, 27                       ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call anyxxpr                     ; Вызываем процедуру
    ret
endp

codepr proc
    cmp al, 4                        ; Проверяем значение AL
    jge code1                        ; Если больше или равно 4, переходим к code1
    push ax
    mov al, 23                       ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call codexpr                     ; Вызываем процедуру
    ret
    code1:
    sub al, 4                        ; Уменьшаем AL
    push ax
    mov al, 12                       ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call codexpr                     ; Вызываем процедуру
    ret
endp

modepr proc
    push eax
    push ebx
    push ecx
    push edx
    cmp al, 8                        ; Проверяем значение AL
    jge code                          ; Если больше или равно 8, переходим к режиму кода
    push ax
    mov al, 13                        ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call datapr                     ; Вызываем процедуру
    jmp return
    code:
    sub al, 8                        ; Уменьшаем AL
    push ax
    mov al, 12                        ; Устанавливаем AL
    call maths                      ; Вызываем процедуру
    add EDI, 2                       ; Увеличиваем адрес
    pop ax
    call codepr                     ; Вызываем процедуру
    return:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret                              ; Возврат из процедуры
endp

logic proc ;; EDX - адрес регистра, BX - оффсет в видеопамяти
    push edx                        ; Сохраняем EDX
    call base                       ; Вызываем процедуру base
    mov EDI, 012000h               ; Устанавливаем адрес для видеопамяти
    add EDI, eBX                   ; Увеличиваем адрес в соответствии с BX
    call basepr                     ; Вызываем процедуру basepr
    add edi, 2                     ; Увеличиваем адрес
    call limit                      ; Вызываем процедуру limit
    call basepr                     ; Вызываем процедуру basepr
    add edi, 2                     ; Увеличиваем адрес
    call mode                       ; Вызываем процедуру mode
    call modepr                     ; Вызываем процедуру modepr
    add edi, 2                     ; Увеличиваем адрес
    call dls                        ; Вызываем процедуру dls
    call dlspr                      ; Вызываем процедуру dlspr
    add edi, 2                     ; Увеличиваем адрес
    call present                    ; Вызываем процедуру present
    call maths                      ; Вызываем процедуру maths
    add edi, 4                     ; Увеличиваем адрес
    call avl                        ; Вызываем процедуру avl
    call maths                      ; Вызываем процедуру maths
    add edi, 4                     ; Увеличиваем адрес
    call bits                       ; Вызываем процедуру bits
    call maths                      ; Вызываем процедуру maths
    pop edx                        ; Восстанавливаем EDX
    ret                              ; Возврат из процедуры
endp 

ENTRY_POINT:
; Загружаем сегментные регистры селекторами на соответствующие дескрипторы:
                 mov           AX,00010000b      ; Селектор на второй дескриптор (DATA_descr)
     mov           DS,AX                         ; Вантажить его в DS        
     mov           ES,AX                         ; То же самое в ES

; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; Создать каталог страниц
                mov        EDI,00100000h               ; Устанавливаем адрес для каталога страниц
    mov        EAX,00101007h               ; Адрес таблицы страниц (0 = 1 Мб + 4 Кб)
    stosd                              ; Записать первый элемент каталога
    mov        ECX,1023                    ; Остальные элементы каталога -
    xor        EAX,EAX                     ; Нули
    rep                 stosd               ; Записываем нулевые значения
; Заполнение таблицы страниц 0
                mov        EAX,00000007h               ; 0 - адрес страницы 0
    mov        ECX,1024                    ; Число страниц в таблице
fill_page_table:
    stosd                              ; Записать элемент таблицы
    add        EAX,00001000h               ; Добавить к адресу 4096 байтов
    loop                fill_page_table        ; И повторить для всех элементов
; Поместить адрес каталога страниц в CR3
                mov        EAX,00100000h               ; Базовый адрес = 1 Мб
    mov        CR3,EAX                    ; Загружаем в регистр CR3
; Включить страничную адресацию,
                mov        EAX,CR0
                or        EAX,80000000h
                mov           CR0,EAX                ; Включаем страницу в CR0

; Теперь изменить физический адрес страницы 12000h на 0B8000h
                mov        EAX,000B8007h
    mov        ES:00101000h+012h*4,EAX   ; Изменение адреса страницы

        xor     EAX,EAX                     ; Обнуляем EAX
        sgdt    fword ptr GDTAddr           ; Получение адреса GDT
        mov     di, offset GDTAddr          ; Загружаем адрес GDT в DI
        mov     ax, word ptr [di]           ; Получаем лимит GDT
        add     di, 2                       ; Переход к следующему значению в GDT
        mov     edx, dword ptr [di]        ; Получаем адрес GDT
        inc     ax                          ; Увеличиваем LIM
        mov     ch, 8                       ; Задаем значение для цикла
        div     ch                          ; Разделяем значение LIM на 8
        mov     cl, al                     ; Получаем оставшуюся часть
        mov     ch, 0                       ; Обнуляем CH
        xor     ebx, ebx                    ; Обнуляем BX (целевой адрес)
        mov     BX, 640                     ; Устанавливаем количество пикселей
        cycle: ;; CL CH - контроль цикла, EDX - адрес таблицы, BX - оффсет в видеопамяти
            call logic                      ; Вызываем процедуру logic
            add edx, 8                      ; Переход к следующему элементу таблицы
            add bx, 160                     ; Увеличиваем адрес видеопамяти
            inc ch                          ; Увеличиваем значение
            cmp cl, ch                      ; Сраниваем значения
            jne cycle                       ; Если не равны, повторяем цикл
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
mess1:
; Вывод mes1 по стандартному адресу (начало видеопамяти 0B8000h)
    mov            EDI,012000h                ; Для команды movsw, EDI = начало видеопамяти
    mov            ESI,PM_DATA                 ; Загружаем сегмент данных в ESI
    shl            ESI,4                        ; Увеличиваем смещение ESI на 4
    add            ESI,offset mes1             ; ESI = адрес начала mes1
    mov            ECX,mes_len                 ; Длина текста в ECX
    rep            movsw                       ; Копируем сообщение из DS:ESI в ES:EDI (видеопамять)

; Вывод mes2 по нестандартному адресу 12000h:
mess2:
    mov            EDI,0120A0h                ; 12000h (можем считать это 0B8000h + A0h)
    mov            ESI,PM_DATA                 ; Загружаем сегмент с данными в ESI
    shl            ESI,4                        ; Увеличиваем смещение ESI на 4
    add            ESI,offset mes2             ; ESI = адрес начала mes2
    mov            ECX,mes_len                 ; Длина текста в ECX
    rep            movsw                       ; Копируем сообщение в нестандартный адрес

; Повторяем процесс для mes3:
    mov            EDI,012140h                 ; Присваиваем адрес для вывода mes3
    mov            ESI,PM_DATA 
    shl            ESI,4
    add            ESI,offset mes3 
    mov            ECX,mes_len 
    rep            movsw                       
                                               ; Копируем сообщение в нестандартный адрес

; Повторяем процесс для mes4:
    mov            EDI,0121E0h                 ; Присваиваем адрес для вывода mes4
    mov            ESI,PM_DATA 
    shl            ESI,4
    add            ESI,offset mes4
    mov            ECX,mes_len
    rep            movsw                       ; Копируем сообщение в нестандартный адрес
   
    jmp            $                           ; Погружаемся в вечный цикл
PM_CODE         ends
; -------------------------------------------------------------------------------------
 
; СЕГМЕНТ ДАННЫХ (для Protected Mode)
; -------------------------------------------------------------------------------------
PM_DATA         segment        para public 'DATA' use32
        assume         CS:PM_DATA
 
GDTAddr dw ?                             ; Адрес глобального дескриптора
        dd ?                             ; 32-битный линейный адрес GDT

; Сообщение, которое мы будем выводить на экран (оформим его в виде блока повторений irpc):
mes1:
irpc            mes1,          <1 - BASE address, 2 - LIMIT, 3 - MODE>  
                db             '&mes1&',0Bh
endm
mes2:
irpc            mes2,          <4 - Up/Down/Conformed/Not conformed>                 
                db             '&mes2&',0Bh
endm
mes3:
irpc            mes3,          <5- Read/Write + read/Execute only 6-Available/Not available>               
                db             '&mes3&',0Bh
endm
mes4:
irpc            mes4,          <7-DPL, 8-Present, 9-Available bit, 10- 32-bit mode>               
                db             '&mes4&',0Bh
endm

mes_len         equ            80                  ; Длина в байтах
PM_DATA         ends
; ----------------------------------------------------------------------------------------------  
                end         @@start    
