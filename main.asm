section .data
    var_a dq 0                                  ; n-1 число в фибоначи
    var_b dq 1                                  ; n число в фибоначи
    var_c dq 0                                  ; n+1 число в фибоначи

    reversed_output db 256 dup("?")             ; reversed вывод результата
    output_size dq 0                            ; размер вывода
    output db 256 dup("?")                      ; вывод результата

    step_10 dq 0
    digit dq 0
    counter dq 0

    var_result dq 0                             ; результат перевода
    var_in_size dq 0                            ; размер вводной строки
    
    prompt db "Enter your fib-number: ", 0      ; строка для ввода текста
    prompt_size equ $-prompt                    ; размер строки
    prompt_2 db "Your result is: ", 0           ; строка для ввода текста
    prompt_2_size equ $-prompt_2                ; размер строки
    error_string db "Your number is not valid! "; строка в случае ошибки
    error_string_size equ $-error_string        ; длина строки
    nline db 0ah, 0                             ; перевод строки
    nline_size equ $-nline                      ; размер строки

    input_buf2 db 64 dup("?")                     
    input_size2 dq 0


section .text
    global _start


; степень 10
_pow_10:
    pop rbx
    pop rcx
    push rbx

    mov rbx, 1  
    mov [step_10], rbx

    cmp rcx, 0
    je _pow_10_loop_end ; if 10^n, при n = 0, то идем в конец и выодим [step_10] = rbx = 1
    _pow_10_loop:
        mov rbx, [step_10]      ; rbx = step_10
        imul rbx, 10            ; rbx = rbx * 10
        mov [step_10], rbx      ; step_10 = rbx
        dec rcx                 ; rcx--
        cmp rcx, 0              ; if rcx != 0:
        jne _pow_10_loop        ;     goto _pow_10_loop
    _pow_10_loop_end:
    retn
    

; return (x / 10^n) % 10
_div_10:
    pop rbx
    pop rax ; n 
    push rbx

    push rax
    call _pow_10 

    mov eax, [var_result]   ; делимое eax
    
    cmp rax, 0
    je _div_10_check_it

    mov ecx, [step_10]      ; ecx - делитель = 10^n
    xor edx, edx            ; обнуляем edx
    div ecx                 ; делим (B(edx)+S(eax)) / ecx
    ; eax = x / 10^n

    cmp eax, 0
    je _div_10_exit
    
    _div_10_check_it:
        mov ecx, 10          ; ecx - делитель = 10
        xor edx, edx         ; обнуляем edx
        div ecx              ; елим (B(edx)+S(eax)) / 10
        add edx, 48
        mov [digit], edx
        retn
    
    _div_10_exit:
        mov rdx, 0
        mov [digit], rdx
        retn

; Вывод n числа фибоначи
_fib_range:
    pop rax   ;адрес возврата получаем
    pop rcx   ;счётчик
    push rax  ;возвращаем адрес возврата
    mov eax, 0        ; используем eax, а не rax, так как var_a, var_b, var_c - 32bit (1)
                      ; а если мы переполним это значение используя rax, то получим лишние 32 бит, что испортит всё
    mov [var_a], eax  ; var_a = eax = 0 | a = 0
    mov [var_c], eax  ; var_c = eax = 0 | c = 0
    mov eax, 1        ; аналогично с (1)
    mov [var_b], eax  ; var_b = eax = 1 | b = 1

    _loop_fib:
    ;   c = a + b        ; 32bit регистры, аналогично с (1)
        mov ebx, 0       ; ebx = 0           | c = 0
        mov eax, [var_a] ; eax = var_a       | a from memory
        add ebx, eax     ; ebx = ebx + eax   | c = c + a = 0 + a = a
        mov eax, [var_b] ; eax = var_b       | b from memory
        add ebx, eax     ; ebx = ebx + eax   | c = c + b = a + b
        mov [var_c], ebx ; var_c = ebx       | c to memory => c = a + b
        
    ;   a = b
        mov eax, [var_b] ; eax = var_b
        mov [var_a], eax ; var_a = eax = var_b => a = b
        
    ;   b = c
        mov eax, [var_c] ; eax = var_c
        mov [var_b], eax ; var_b = eax = var_c => b = c

    ;   rcx -= 1  if rcx != 0 goto _loop_fib else return var_c
        dec rcx
        cmp rcx, 0
        jne _loop_fib
        mov [var_c], ebx
        retn 


; Функция перевода на новую строку
_new_line:
    mov rax, 1
    mov rdi, 1
    mov rsi, nline
    mov rdx, nline_size
    syscall
    retn


; Функция вывода строки
_print:
    pop rax     ; адрес возвратьа извлекли  - 3 аргумент неявный
    pop rdx     ; кол-во символов в строке  - 2 аргумент
    pop rsi     ; строка                    - 1 аргумент
    push rax    ; адрес возврата вернули
    mov rax, 1
    mov rdi, 1
    syscall
    retn


_start:

    ;push x             ; Передаём номер числа фибоначи - x
    ;call _fib_range    ; Вызываем функцию с аргументом - результат в переменной var_c

    ; print(prompt)
    push prompt
    push prompt_size
    call _print

    mov eax, 3		        ; sys_read системный вызов для чтения
    mov ebx, 0		        ; используем stdin
    mov ecx, input_buf2  	; сохранить в ecx адрес буфера
    mov edx, 64           ; читать все 256 значений 
    int 80h               ; системный вызов | вызов к ядру call kernel

    mov [input_size2], eax

    mov rcx, [input_size2]      ; счётчик
    dec rcx                     ; избавляемся от последнего символа конца строки
    

    _char_loop_reverse:         ; цикл обратный по строке
        push rcx                ; сохраним счётчик в стеке
        movzx rax, byte [input_buf2 + rcx - 1]

        ; if rax == '1': goto _it_is_1
        cmp rax, 0x31           
        je _it_is_1
        ; elif rax == '0' goto _it_is_nothing
        cmp rax, 0x30
        je _it_is_nothing
        ; else throw error
        jmp _error_stop

        _it_is_1:
            ; получаем индекс input'а с конца 
            mov rax, [input_size2]
            sub rax, rcx
            
            ; вызываем функцию фибоначи от rax
            push rax
            call _fib_range

            ; добавляем результат функции к конечному и сохраняем
            mov eax, [var_c]
            mov ebx, [var_result]
            add ebx, eax
            mov [var_result], ebx

        _it_is_nothing:
            pop rcx                 ; достать счётчик
            dec rcx                 ; убавить счётчик на 1
            cmp rcx, 0              ; сравнить счётчик с 0
            jne _char_loop_reverse  ; если не равен 0, то пойти дальше
    
    mov ecx, 0

    _convert_digit_to_str:
        mov [counter], ecx
        
        push rcx
        call _div_10
        
        mov rcx, [counter]
        mov rax, [digit]
        
        cmp rax, 0
        je _end_convert_digit_to_str
        
        mov [reversed_output + rcx], rax
        
        mov rax, [output_size]
        inc rax
        mov [output_size], rax
        
        mov rcx, [counter]
        inc rcx
        jmp _convert_digit_to_str
    _end_convert_digit_to_str:

    mov rcx, [output_size]
    
    _reverse_string:
        mov rax, [output_size]
        sub rax, rcx
        mov rdx, [reversed_output + rcx - 1]
        mov [output + rax], rdx
        dec rcx
        cmp rcx, 0
        jne _reverse_string
    

    ; print(prompt)
    push prompt_2
    push prompt_2_size
    call _print

    mov rax, 1
    mov rdi, 1
    mov rsi, output
    mov rdx, [output_size]
    syscall

    ; \n - переход на новую строку
    call _new_line

    ;return 0 - вызод из программы
    mov eax, 60        
    mov rdi, 0
    syscall

    _error_stop:
        push error_string
        push error_string_size
        call _print
        call _new_line
        mov eax, 60        
        mov rdi, 0
        syscall
