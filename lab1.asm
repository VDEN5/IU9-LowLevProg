assume CS:code, DS:data 
 
data segment 
    a db 3 
    b db 5 
    c dw 4 
    d db 5 
    res db ? 
    temp dw ? 
    temp1 dw ? 
    dec_output_buffer db "0000$", 0 
    hex_output_buffer db "0000$", 0 
data ends 
 
code segment 
start: 
    mov AX, data 
    mov DS, AX 
    mov AH, 0 
 
    mov AL, b 
    mov BL, d 
    mul BL 
    mov temp, AX 
 
    ;mov AH, 0 ; Clear AH before dividing 
    mov AL, a 
    mov BL, 4 
    mul BL 
    mov CX, AX 
 
    mov AX, temp 
    add AX, CX
    add AX, c 
 
    mov res, AL 
 
    mov AL, res 
    mov AH, 0 
    mov DI, offset dec_output_buffer + 4 
 
convert_to_dec: 
    xor DX, DX 
    mov CX, 10 
    div CX 
    add DL, '0' 
    dec DI 
    mov [DI], DL 
 
    test AL, AL 
    jnz convert_to_dec 
 
    ;; вывод res в десятичной 
    mov AH, 09h 
    mov DX, DI 
    int 21h 
     
newline: 
    mov ah, 2 
    mov dl, 10 
    int 21h 
 
pre: 
 mov AL, res 
 mov AH, 0 
 mov DI, offset hex_output_buffer + 4 
  
convert_to_hex: 
    xor DX, DX 
    mov CX, 16 
    div CX 
    cmp DL, 10 
    jl not_letter 
    add DL, 'A' - 10 
    jmp write_hex_digit 
 
not_letter: 
    add DL, '0' 
 
write_hex_digit: 
    dec DI 
    mov [DI], DL 
 
    test AL, AL 
    jnz convert_to_hex 
 
    ; Вывод результата в 16-ричной системе 
    mov AH, 09h 
    mov DX, DI 
    int 21h 
     
exit: 
    mov AH, 4Ch 
    int 21h 
 
code ends 
end start