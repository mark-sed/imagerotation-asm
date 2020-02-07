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
global rotate_mc_image		;; Monochromatic image rotation function

;; Macros

;; Constants

;; Global uninitialized variables
section .bss
align 64

;; Global variables
section .data

;; Code
section .text


;; ROTATE_MC_IMAGE 
;; Rotates monochrome image by an arbitary angle in radians
;;
;; @param
;;      uint8_t **src       - RDI - Source image
;;      uint8_t **dst       - RSI - Destination image
;;      ulong width         - RDX - Width of the image
;;      ulong height        - RCX - Height of the image
;;	float angle         - XMM0? - Rotation angle
rotate_mc_image:
    push rbp
    mov rbp, rsp
    

    pop rbp
    ret
; end of rotate_mc_image
