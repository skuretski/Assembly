TITLE Program 4 
; Author: skuretski
; Date: 2/10/15
; Description: Write a program that calculates prime numbers. 
;	The user is intstructed to enter the number of primes to 
;	be displayed, and is prompted to enter an int in the range
;	of 1-200. The user enters a number and the program verifies
;	that 1 <= n <= 200. If the number is out of range, then the 
;	user is re-prompted until there is a value in the specified
;	range. The program then calculates and displays all of the prime
;	numbers up to and including the nth prime. The results should be
;	displayed 10 primes per line with at least 3 spaces between the 
;	numbers.
;	1. Procedure using parameters
;	2. Local variables used
;	3. Columns aligned

INCLUDE Irvine32.inc

MAX_NUM = 200

.data
	progName	BYTE		"Prime Numbers by ", 0
	author		BYTE		"skuretski", 0
	instruct	BYTE		"Enter the number of prime numbers you would like to see.", 0dh, 0ah
						BYTE		"I'll accept up to 200 primes.", 0
	userNum		DWORD		?
	farewell	BYTE		"Program ending. Cheers from ", 0
	error			BYTE		"Number must be 1-200. Try again.", 0

.code
   main PROC

   ; Introduction
		call		Introduction
   ; Get User Data
		call		getUserData
		call		CrLf
   ; Show Primes
		push		userNum
		call		showPrimes
   ; Farewell
		call goodbye

   exit
main ENDP
;------------------------------------------------------------------------
Introduction PROC
; Displays program name and programmer's name, and program instructions
; Pre-conditions: progName and author are defined 
; Returns: Nothing
;------------------------------------------------------------------------
	pushad
	mov		edx, OFFSET progName
	call		WriteString
	mov		edx, OFFSET author
	call		WriteString
	call		CrLf
	call		CrLf
	popad
	ret
	
	Introduction ENDP
;------------------------------------------------------------------------
validate PROC,
	val: DWORD
; Sets ebx to 1 is the user's number is within range; sets ebx to 0 if
; user's number is out of range
; Pre-conditions: DWORD value as parameter (checks value against range)
; Post-conditions: returns 1 if within range, returns 0 if not in the
; EBX register
;------------------------------------------------------------------------
		cmp		val, MAX_NUM
		jg		errorMsg
		cmp		val, 0
		jle		errorMsg
		mov		ebx, 1		; set ebx to 1 if within range
		jmp		noErrors
	errorMsg:
		call		CrLf
		mov		edx, OFFSET error
		call		WriteString	; display error message to user
		call		CrLf
		mov		ebx, 0		; set ebx to 0 if out of range
	noErrors:
		ret

validate ENDP

;------------------------------------------------------------------------
getUserData PROC
; Gets the user's number for the number of prime numbers desired, checks if
; user's number is within range. Will re-prompt if not within range. 
; *******USES VALIDATE PROCEDURE*******
; Pre-conditions: instruct declared (provides information to user), userNum 
; declared 
; Returns:
;	Number of prime numbers desired to see (userNum) in eax
;------------------------------------------------------------------------
	getValid:	
		mov		edx, OFFSET instruct
		call		WriteString
		call		CrLf
		call		ReadInt				
		mov		userNum, eax
	validProc:
		invoke	validate, userNum		; calls validate procedure with userNum
		cmp		ebx, 0				; ebx is 1 if within range, 0 if out of range
		je		getValid				; if not valid, repeats again
		ret
	getUserData ENDP

;------------------------------------------------------------------------
isPrime PROC,
	number1: DWORD,
	number2: DWORD
; Returns 1 if number is prime; returns 0 if not a prime number.
; This format: number1 % number2 == 0 
; ******** RETURNED IN EAX REGISTER *********
; Pre-conditions: number1 and number2 as parameters
; Returns: 1 if prime, 0 if not prime. In EAX register
	mov	eax, number1					; parameter 1
	mov	ebx, number2					; parameter 2
	mov	edx, 0
	div	ebx
	cmp	edx, 0						; seeing if remainder if zero or not
	jz	yesPrime				
	jnz	notPrime
	yesPrime:
		mov eax, 1					; if no remainder, then eax is 1
		jmp leavePrimeCheck
	notPrime:
		mov eax, 0					; if remainder, then eax is 0
	leavePrimeCheck:
		ret

isPrime ENDP
;------------------------------------------------------------------------
;------------------------------------------------------------------------
; LOCAL VARIABLES FOR SHOW PRIMES PROCEDURE
; Counter keeps count of number of number of divisors
; Number1 is the dividend
; Number2 is the divisor
; PrimeCount keeps track of the number of prime numbers found
;------------------------------------------------------------------------
counter_local EQU DWORD PTR [ebp - 4]
number1_local EQU DWORD PTR [ebp - 8]
number2_local EQU DWORD PTR [ebp - 12]
prime_count_local EQU DWORD PTR [ebp - 16]
showPrimes PROC	
; Prints out the user's desired number of prime numbers.
; **** Uses isPrime PROC ****
; Pre-conditions: pushes user's desired number before call (at [ebp + 8])
; Post-conditions: prints out desired number of prime numbers. 10 nums per
; row
	push ebp
	mov ebp, esp
	sub esp, 16									; save room for local variables
	mov	number1_local, 1							; set number1 to 1
	mov	number2_local, 1							; set number2 to 1
	mov	prime_count_local, 0						; prime count is zero
	outerLoop:
		mov	counter_local, 0						; resets counter to zero if we move on to a new dividend
		mov	ecx, number1_local						; sets ECX to dividend for looping
	innerLoop:
		invoke isPrime, number1_local, number2_local		; call isPrime (num1 is dividend, num2 is divisor)
		cmp		eax, 1							; sees if isPrime returns 1 or 0 
		jne		continueInner						; if 0 (has remainder), continue
		inc		counter_local						; if 1 (has no remainder), increment divisor counter
	continueInner:
		inc		number2_local						; increments divisor
		LOOP		innerLoop							; continues dividing by newly updated divisor
	continueOuter:
		cmp		counter_local, 2					; checks if dividend has exactly 2 divisors
		je		printNumber						; if prime, then print number
		jne		L2								; if not prime, then continue loop at L2
		printNumber:
				mov		eax, number1_local
				call		WriteDec
				mov		al, TAB					
				call		WriteChar
				inc		prime_count_local
				mov		eax, prime_count_local
				mov		ebx, 10
				mov		edx, 0
				div		ebx
				cmp		edx, 0
				jne		L2
				newLine:	
					call		CrLf
		L2:
		inc		number1_local						; increment dividend
		mov		number2_local, 1					; sets divisor to one again
		mov		ebx, prime_count_local	
		cmp		ebx, [ebp + 8]						; compare prime count to user's number
		jne		outerLoop							; if not equal, keep dividing to find more primes
	mov esp, ebp
	pop ebp
	ret 4		; go to return address (pushed userNum onto stack before call)


showPrimes ENDP
;------------------------------------------------------------------------
;------------------------------------------------------------------------
goodbye PROC
; Prints a farewell message to user
; Pre-conditions: defined variable farewell that contains message and
; author with author's name
; Returns: nothing
	pushad
	call		CrLf
	mov		edx, OFFSET farewell
	call		WriteString
	mov		edx, OFFSET author
	call		WriteString
	call		CrLf
	popad
	ret
goodbye ENDP
;------------------------------------------------------------------------

END main
