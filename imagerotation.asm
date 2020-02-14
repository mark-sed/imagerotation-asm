;; Image rotation algorithm module. 
;;
;; Compiler used: NASM version 2.13
;; Made for: 64-bit Linux with C caling convention
;;
;; @file imagerotation.asm
;; @author Marek Sedlacek (xsedla1b)
;; @date February 2020
;; @email xsedla1b@fit.vutbr.cz 
;;        mr.mareksedlacek@gmail.com
;;

;; Exported functions
global rotate_mc_image          ;; Monochromatic image rotation function

;; Macros
;; MOVE_PIXEL
;; Moves pixel from src to dst
;; @param
;;      1 - imm8 for vpextrd
;;      2 - x xmm
;;      3 - y xmm
%macro move_pixel 3
        vpextrd eax, %2, %1                     ;; Get 1st x
        vpextrd r10, %3, %1                     ;; Get 1st y
        cmp eax, 0                              ;; Check boundries
        jl %%skip
        cmp eax, edx
        jge %%skip
        cmp r10, 0
        jl %%skip
        cmp r10, rcx
        jge %%skip
        mov r11, qword[rdi+rax*8]               ;; src[src_x]
        mov al, byte[r11+r10]                   ;; al = src[src_x][src_y]
        mov r11, qword[rsi+r9*8]                ;; dst[x]
        mov byte[r11+r8], al                    ;; dst[x][y] = src[src_x][src_y]
%%skip:
        inc r9
%endmacro

;; Global variables
section .data
align 64
__CONST_1_8     dd 0., 1., 2., 3., 4., 5., 6., 7.
__CONST_8       dd 8., 8., 8., 8., 8., 8., 8., 8.
__CONST_1       dd 1., 1., 1., 1., 1., 1., 1., 1.

;; Code
section .text


;; ROTATE_MC_IMAGE 
;; Rotates monochrome image by an arbitary angle in radians
;;
;; @param
;;      uint8_t **src       - RDI  - Source image
;;      uint8_t **dst       - RSI  - Destination image
;;      uint  width         - EDX  - Width of the image
;;      uint  height        - ECX  - Height of the image
;;      float angle         - XMM0 - Rotation angle
rotate_mc_image:
        push rbp
        mov rbp, rsp
        sub rsp, 80                             ;; Make space for variables

        %define y_src rbp-80
        %define x_src rbp-72
        %define y0 rbp-64
        %define x0 rbp-56
        %define y_sinx0 rbp-48
        %define y_cosy0 rbp-40
        %define y rbp-32
        %define x rbp-24
        %define width2 rbp-16
        %define height2 rbp-12
        %define angle_sin rbp-8
        %define angle_cos rbp-4

        push r11
        push r12

        vpextrd [angle_sin], xmm0, 0x4          ;; Extract angle into stack                          
        mov eax, edx
        sar eax, 1                              ;; Divide width by 2
        mov dword[width2], eax                  ;; Store width to stack
        mov eax, ecx
        sar eax, 1
        mov dword[height2], eax                 ;; Store height to stack

        ;; Calculate sin and cos of angle using FPU (AVX does not have trigonometric functions)
        fninit                                  ;; Init FPU    
        fild dword[width2]
        fild dword[height2]
        fld dword[angle_sin]                    ;; Load angle twice for sin and cos
        fld dword[angle_sin]
        fsin                                    ;; Calculate sin of angle
        fstp dword[angle_sin]                   ;; Store angle back to stack
        fcos                                    ;; Calculate cos of angle
        fstp dword[angle_cos]                   ;; Store cos
        
        fst dword[height2]                      ;; Keep width and height
        fxch st0, st1
        fst dword[width2]                       

        ;; Calculate x0 and y0
        fld dword[angle_sin]
        fmul st1                                ;; width/2 * sin
        fld dword[angle_cos]
        fmul st2                                ;; width/2 * cos
        fld dword[angle_sin]
        fmul st4                                ;; height/2 * sin
        fld dword[angle_cos]
        fmul st5                                ;; height/2 * cos
        fld dword[width2]
        fsub st3                                ;; width/2 - width/2*cos
        fsub st2                                ;; width/2 - width/2*cos - height/2*sin
        fld dword[height2]
        fsub st2                                ;; height/2 - width/2*cos
        fadd st5                                ;; height/2 - width/2*cos + width/2*sin
        
        fstp dword[y0]
        fstp dword[x0]

        vbroadcastss ymm0, [angle_sin]          ;; sin(angle)
        vbroadcastss ymm1, [angle_cos]          ;; cos(angle)

        vbroadcastss ymm2, [width2]             ;; Load width/2
        vbroadcastss ymm3, [height2]            ;; and height/2

        vmulps ymm4, ymm2, ymm1                 ;; width/2 * cos(angle)
        vmulps ymm5, ymm3, ymm0                 ;; height/2 * sin(angle)
        vsubps ymm6, ymm2, ymm5                 ;; width/2 - (height/2 * sin(angle))
        vsubps ymm4, ymm6, ymm4                 ;; x0 = width/2 - height/2 * sin(angle) - width/2 * cos(angle)

        vmulps ymm6, ymm1, ymm3                 ;; height/2 * cos(angle)
        vmulps ymm7, ymm0, ymm2                 ;; width/2 * sin(angle)
        vsubps ymm6, ymm6, ymm7                 ;; (height/2 * cos(angle)) - (width/2 * sin(angle))
        vsubps ymm5, ymm3, ymm6                 ;; y0 = height/2 - height/2 * cos(angle) - width/2 * sin(angle)

        vxorps ymm7, ymm7                       ;; Set y loop values to start at 0
        vmovaps ymm15, [__CONST_8]              ;; Load loop increments
        vmovaps ymm14, [__CONST_1]

        xor r8, r8                              ;; y loop counter
.for_y:
        cmp r8, rcx
        jae .for_y_end                          ;; y >= height
        xor r9, r9                              ;; x loop counter
        vmovaps ymm6, [__CONST_1_8]             ;; Load for x loop starting numbers
.for_x: 
        add r9, 8
        cmp r9, rdx
        ja .for_x_end                           ;; x >= width
        ; Calculate source x and y coordinates
        vmulps ymm8, ymm1, ymm6                 ;; cos(angle) * x
        vmulps ymm9, ymm0, ymm7                 ;; sin(angle) * y
        vaddps ymm8, ymm8, ymm9                 ;; cos(angle) * x + sin(angle) * y
        vaddps ymm8, ymm8, ymm4                 ;; cos(angle) * x + sin(angle) * y + x0

        vmulps ymm9, ymm1, ymm7                 ;; cos(angle) * y
        vmulps ymm10, ymm0, ymm6                ;; sin(angle) * x
        vsubps ymm9, ymm9, ymm10                ;; cos(angle) * y - sin(angle) * x
        vaddps ymm9, ymm9, ymm5                 ;; cos(angle) * y - sin(angle) * x + y0
        ;; Extract coordinates and check if the coordinates are in the picture
        vcvttps2dq ymm8, ymm8                   ;; Convert float values to ints
        vcvttps2dq ymm9, ymm9
        
        vextracti128 xmm10, ymm8, 0x0           ;; Extract x coordinates to xmm10 and xmm11    
        vextracti128 xmm11, ymm8, 0x1
        vextracti128 xmm12, ymm9, 0x0           ;; Extract y coordinates to xmm12 and xmm13
        vextracti128 xmm13, ymm9, 0x1
        
        sub r9, 8                               ;; Adjust x coordinate
        move_pixel 0x0, xmm10, xmm12            ;; Move pixels from src to dst
        move_pixel 0x1, xmm10, xmm12
        move_pixel 0x2, xmm10, xmm12
        move_pixel 0x3, xmm10, xmm12
        move_pixel 0x0, xmm11, xmm13
        move_pixel 0x1, xmm11, xmm13
        move_pixel 0x2, xmm11, xmm13
        move_pixel 0x3, xmm11, xmm13

        vaddps ymm6, ymm6, ymm15                ;; Increment x values
        jmp near .for_x 
.for_x_end:
        ;; Do rest in serial if needed
        fninit
        sub r9, 8                               ;; Bring x back to correct value
        mov qword[y], r8

        fld dword[angle_sin]                    ;; Load angles
        fld dword[angle_cos]

        ;; Precalculate y*cos and y*sin+x0
        fild qword[y]
        fmul st1
        fld dword[y0]
        fadd st1
        fstp qword[y_cosy0]
        
        fild qword[y]
        fmul st3
        fld dword[x0]
        fadd st1
        fstp qword[y_sinx0]
.for_x_serial:
        cmp r9, rdx
        jae .for_x_serial_end                   ;; x >= width
        
        fninit                                  ;; Incorrect values are loaded if there is not finit        
        fld dword[angle_sin]                    ;; Load angles
        fld dword[angle_cos]
        mov qword[x], r9                        ;; Update x on stack
        
        fild qword[x]
        fmul st1                                ;; x * cos
        fild qword[x]                           
        fmul st3                                ;; x * sin
        fld qword[y_cosy0]
        fsub st1                                ;; cos*y+y0 - x*sin
        fld qword[y_sinx0]
        fadd st3                                ;; sin*y*x0 + x*c
        fistp qword[x_src]
        mov rax, qword[x_src]                   ;; Extract x_src and y_src
        fistp qword[y_src]
        mov r10, qword[y_src]                   
        
        cmp eax, 0                              ;; Check boundries
        jl .xsskip
        cmp eax, edx
        jge .xsskip
        cmp r10, 0
        jl .xsskip
        cmp r10, rcx
        jge .xsskip
        mov r11, qword[rdi+rax*8]               ;; src[src_x]
        mov al, byte[r11+r10]                   ;; al = src[src_x][src_y]
        mov r11, qword[rsi+r9*8]                ;; dst[x]
        mov byte[r11+r8], al                    ;; dst[x][y] = src[src_x][src_y]
.xsskip:

        inc r9
        jmp short .for_x_serial
.for_x_serial_end:
        vaddps ymm7, ymm7, ymm14                ;; Increment y values
        inc r8                                  ;; Increment y counter
        jmp near .for_y
.for_y_end:       

        pop r12
        pop r11
        mov rsp, rbp
        pop rbp
        ret
; end of rotate_mc_image
