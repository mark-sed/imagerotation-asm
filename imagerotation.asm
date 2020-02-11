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

;; Constants

;; Global uninitialized variables
;section .bss
;align 64

;; Global variables
section .data
align 64
__CONST_1_8     dd 0, 1, 2, 3, 4, 5, 6, 7
__CONST_8       dd 8, 8, 8, 8, 8, 8, 8, 8

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
;;          float angle         - XMM0 - Rotation angle
rotate_mc_image:
        push rbp
        mov rbp, rsp
        sub rsp, 16                              ; Make space for angle, width and height

        %define width rbp-16
        %define height rbp-12
        %define angle_sin rbp-8
        %define angle_cos rbp-4

    
        vpextrd [angle_sin], xmm0, 0x4          ; Extract angle into stack                          
        ;; Calculate sin and cos of angle using FPU (AVX does not have trigonometric functions)
        finit                                   ; Init FPU                                       
        fld dword[angle_sin]                    ; Load angle twice for sin and cos
        fld dword[angle_sin]
        fsin                                    ; Calculate sin of angle
        fstp dword[angle_sin]                   ; Store angle back to stack
        fcos                                    ; Calculate cos of angle
        fstp dword[angle_cos]                   ; Store cos

        vbroadcastss ymm0, [angle_sin]          ; sin(angle)
        vbroadcastss ymm1, [angle_cos]          ; cos(angle)

        sar edx, 1                              ; width/2
        sar ecx, 1                              ; height/2
        mov edx, dword[width]
        mov ecx, dword[height]
        vbroadcastss ymm2, [width]              ; Load width/2
        vbroadcastss ymm3, [height]             ; and height/2

        vmulps ymm4, ymm2, ymm1                 ; width/2 * cos(angle)
        vmulps ymm5, ymm3, ymm0                 ; height/2 * sin(angle)
        vsubps ymm6, ymm2, ymm5                 ; width/2 - (height/2 * sin(angle))
        vsubps ymm4, ymm6, ymm4                 ; width/2 - height/2 * sin(angle) - width/2 * cos(angle)

        vmulps ymm6, ymm1, ymm3                 ; height/2 * cos(angle)
        vmulps ymm7, ymm0, ymm2                 ; width/2 * sin(angle)
        vsubps ymm6, ymm6, ymm7                 ; (height/2 * cos(angle)) - (width/2 * sin(angle))
        vsubps ymm5, ymm3, ymm6                 ; height/2 - height/2 * cos(angle) - width/2 * sin(angle)

        vmovaps ymm6, [__CONST_1_8]             ; Load for x loop starting numbers
        vmovaps ymm7, ymm6                      ; Copy for y loop
        vmovaps ymm15, [__CONST_8]              ; Load loop increments

        mov rsp, rbp
        pop rbp
        ret
; end of rotate_mc_image
