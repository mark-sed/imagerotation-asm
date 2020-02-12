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

;; Constants

;; Global uninitialized variables
;section .bss
;align 64

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
        sub rsp, 16                              ;; Make space for variables

        %define width rbp-16
        %define height rbp-12
        %define angle_sin rbp-8
        %define angle_cos rbp-4

        push r11
        push r12

        vpextrd [angle_sin], xmm0, 0x4          ;; Extract angle into stack                          
        mov eax, edx
        sar eax, 1                              ;; Divide width by 2
        mov dword[width], eax                   ;; Store width to stack
        mov eax, ecx
        sar eax, 1
        mov dword[height], eax                  ;; Store height to stack

        ;; Calculate sin and cos of angle using FPU (AVX does not have trigonometric functions)
        finit                                   ;; Init FPU                                       
        fild dword[width]
        fild dword[height]
        fld dword[angle_sin]                    ;; Load angle twice for sin and cos
        fld dword[angle_sin]
        fsin                                    ;; Calculate sin of angle
        fstp dword[angle_sin]                   ;; Store angle back to stack
        fcos                                    ;; Calculate cos of angle
        fstp dword[angle_cos]                   ;; Store cos
        
        fstp dword[height]
        fstp dword[width]

        vbroadcastss ymm0, [angle_sin]          ;; sin(angle)
        vbroadcastss ymm1, [angle_cos]          ;; cos(angle)

        vbroadcastss ymm2, [width]              ;; Load width/2
        vbroadcastss ymm3, [height]             ;; and height/2

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

        finit
        xor r8, r8                              ;; y loop counter
.for_y:
        cmp r8, rcx
        jae .for_y_end                          ;; y >= height
        xor r9, r9                              ;; x loop counter
        vmovaps ymm6, [__CONST_1_8]             ;; Load for x loop starting numbers
.for_x: 
        add r9, 8
        cmp r9, rdx
        ja .for_x_end                          ;; x >= width
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
