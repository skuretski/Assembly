TITLE Program 5 (cs271_prog5.asm)
; Author: skuretski
; Date 2/22/15
; Description: Write a program to perform the following tasks:
;   1. Introduce the program
;   2. Get a user request in the range [min = 10... max = 200]
;   3. Generate request random integers in the range [lo = 100, hi = 999]
;      storing them in consecutive elements of an array (use indirect addressing)
;   4. Display the list of integers before sorting. 10 per line.
;   5. Sort the list in descending order.
;   6. Calculate and display the median value, rounded to the nearest int.
;   7. Display the sorted list. 10 per line. 
;   8. Median (for an even sized array) is a float number

INCLUDE Irvine32.inc

MAX_INPUT = 200
MIN_INPUT = 10
MAX_RANGE = 999
MIN_RANGE = 100

.data
	progName	BYTE		"Sorting Random Numbers by", 0
	author	BYTE		"skuretski", 0
	instruct	BYTE		"This program generates a list of random numbers in the range 100-999, ", 0dh, 0ah
			BYTE		"displays the original list, sorts the list, and calculates the median ", 0dh, 0ah
			BYTE		"value. Finally, it displays the list sorted in descending order.", 0
	prompt	BYTE		"How many numbers do you want generated? (10-200)", 0
	error	BYTE		"Out of range.", 0
	userNum	DWORD	?
	list		DWORD	200 DUP(?)
	unsorted	BYTE		"Unsorted Numbers: ", 0
	sorted	BYTE		"Sorted Numbers: ", 0
	medianMsg	BYTE		"Median: ", 0

.code
   main PROC

   call Randomize 
   ; Introduction
		call Introduction
		call CrLf
   ; Get User Data
		push OFFSET userNum
		call GetUserInput
		call CrLf
		call CrLf
   ; Fill array with Pseudo-Random Numbers 
		push OFFSET list
		push userNum
		call FillArray
   ; Display Unsorted Array
		push userNum
		push OFFSET list
		push OFFSET unsorted
		call PrintList
		call CrLf
		call CrLf
   ; Sort Array
		push userNum
		push OFFSET list
		call SortArray
   ; Display List
		push userNum
		push OFFSET list
		push OFFSET sorted
		call PrintList
		call CrLf
		call CrLf
   ; Display Median
		push userNum
		push OFFSET list
		push OFFSET medianMsg
		call Median
   exit
   main ENDP
;--------------------------------------------------------------------
Introduction PROC
; Displays program name, programmer's name, and program description.
; Pre-conditions: progName, author, and instruct are defined globally.
; Returns: Nothing
;--------------------------------------------------------------------
	push		edx
	mov		edx, OFFSET progName
	call		WriteString
	mov		edx, OFFSET author
	call		WriteString
	call		CrLf
	call		CrLf
	mov		edx, OFFSET instruct
	call		WriteString
	call		CrLf
	call		CrLf
	pop		edx
	ret
Introduction ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;--------------------------------------------------------------------
Validate PROC,
	val: DWORD
; Description: Sets ebx to 1 if the user's number is within range, or
; sets to 0 if user's number is out of range
; Pre-conditions: DWORD value as parameter pushed onto stack
; Returns: returns 1 if within range, 0 if without range in EBX
;--------------------------------------------------------------------
	push		edx
	cmp		val, MAX_INPUT			
	jg		errorMsg			; if val > MAX_INPUT
	cmp		val, MIN_INPUT
	jl		errorMsg			; if val < MIN_INPUT
	mov		ebx, 1			; sets ebx to 1 if no errors
	jmp		noErrors
	errorMsg:
			call CrLf
			mov edx, OFFSET error
			call WriteString	; print out error message
			call CrLf
			mov ebx, 0		; sets ebx to 0 if out of range
	noErrors:
	pop edx
	ret

Validate ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
GetUserInput PROC
; Description: Gets and stores user's desired amount of random numbers (10-200).
; Will prompt error message if out of range.
; Pre-conditions: prompt is defined globally, accepts desired amount of random
; numbers by reference (ebp + 8). 
; Returns: user's desired number 
;--------------------------------------------------------------------
	push		ebp
	mov		ebp, esp
	pushad
	getValid:
		mov		edx, OFFSET prompt
		call		WriteString
		call		CrLf
		call		ReadInt			; Gets user's number
		mov		ecx, [ebp + 8]		; Storing untouched user's num variable to ecx (pushed as parameter)
		mov		[ecx], eax		; Storing user's entry into user's num variable
	validProc:
		invoke	Validate, [ecx]	; Checks if within range
		cmp		ebx, 0
		je		getValid			; If not in range, re-prompt
	popad 
	pop		ebp
	ret		4

GetUserInput ENDP

;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;--------------------------------------------------------------------
FillArray PROC 
; Description: fills an array with desired number of random integers (100-999)
; Pre-conditions: accepts array by reference, and desired number
; of random numbers by value.
; Returns: Array of desired size with random integers (100-999)
;--------------------------------------------------------------------
	push ebp
	mov	ebp, esp
	pushad
	mov edi, [ebp + 12]		; storing array to edi
	mov ecx, [ebp + 8]		; storing userNum to ecx for loop counter
	cmp ecx, 0
	jle	L2
	L1:	; Filling array with random numbers (100-999)
		mov		eax, MAX_RANGE
		sub		eax, MIN_RANGE
		inc		eax
		call		RandomRange
		add		eax, MIN_RANGE
		mov		[edi], eax	; storing random number in array
		add		edi, 4		; incrementing to next spot in array
		loop		L1
	L2:
	popad
	pop ebp
	ret 8
		
FillArray ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;--------------------------------------------------------------------

SortArray PROC 
; Description: Sorts an array in descending order.
; Pre-conditions: Accepts array (ebp + 8) and number of elements (ebp + 12) 
; as parameters
; Returns: Array sorted in descending order
;--------------------------------------------------------------------
	push ebp
	mov ebp, esp
	pushad
	mov ecx, [ebp + 12]			; storing number of elements into ecx
	dec ecx
	; Bubble sort execution
	L1:
		push ecx
		mov esi, [ebp + 8]		; storing array into esi
	L2:
		mov eax, [esi]			
		cmp [esi + 4], eax
		jle L3
		xchg eax, [esi + 4]
		mov [esi], eax
	L3:
		add esi, 4
		loop L2
		pop ecx
		loop L1
	L4:
	popad
	pop ebp
	ret 8
		
SortArray ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;--------------------------------------------------------------------
array_sub_local EQU DWORD PTR [ebp - 4]		; local variable to keep track of array subscript

; Numbers to store locally to calculate a median for an even sized array
numberOne_local EQU DWORD PTR [ebp - 8]		
numberTwo_local EQU DWORD PTR [ebp - 12]

; Local variables to find the mean and round it
median_local EQU REAL4 PTR [ebp - 16]
oneThousand_local EQU DWORD PTR [ebp - 20]
two_local EQU DWORD PTR [ebp - 24]

Median PROC
; Description: Determines median of array
; Pre-conditions: Accepts array size, array, and message as parameters 
; Returns: Nothing. Prints out median of array. 
;--------------------------------------------------------------------
	push ebp
	mov ebp, esp
	sub esp, 24
	pushad
	mov eax, [ebp + 16]		; Putting userNum parameter in ebx
	mov esi, [ebp + 12]		; Putting array in esi 
	mov edx, [ebp + 8]		; Putting medianMsg in edx
	mov array_sub_local, 0	; Array subscript
	mov oneThousand_local, 1000
	mov two_local, 2

	call WriteString
	call CrLf
	mov edx, 0			; Clearing edx register for division
	mov ebx, 2			; Putting 2 in ebx for division
	div ebx				; Dividing array size by 2
	mov array_sub_local, eax	; Storing result 
	cmp edx, 0			; Odd or Even?
	jne isOdd				; If remainder, then odd 
	isEven:
		; Storing the middle two numbers and numberOne_local and numberTwo_local
		mov eax, array_sub_local		; storing first middle number's position into eax
		mov ebx, 4
		mul ebx					; multiply position by 4 (using DWORD array)
		mov ecx, [esi + eax]		; Finding value at calculated position
		mov numberOne_local, ecx		; Storing value into numberOne
		sub eax, 4				
		mov ecx, [esi + eax]		; Find the left adjacent number of middle
		mov numberTwo_local, ecx		; Storing value into numberTwo

		; Calculating median with floating point unit

		finit
		fild numberOne_local	; first middle number
		fiadd numberTwo_local	; second middle number
		fidiv two_local		; dividing sum by 2

		; Rounding float number

		fimul oneThousand_local	; multiplying result by 1000
		frndint				; rounding to nearest integer
		fidiv oneThousand_local	; dividing by 1000
		fst median_local		; store result to median_local
		call WriteFloat
		jmp continueProc 

	isOdd:
		mov eax, array_sub_local		; storing middle number's position in array
		mov ebx, 4
		mul ebx					; multiply position by four (using DWORD array)
		mov eax, [esi + eax]		; find the value in the array
		call WriteDec
	continueProc: 
		call CrLf
		call CrLf
	popad
	mov esp, ebp
	pop ebp
	ret 12

Median ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;--------------------------------------------------------------------
counter_local EQU DWORD PTR [ebp - 4]	; for row size purposes
PrintList PROC
; Description: Prints array 
; Pre-conditions: Accepts array, message, and array size as paramters
; (size [ebp + 16], array [ebp + 12], message [ebp + 8])
; Returns: Nothing. Prints array
;--------------------------------------------------------------------
	push ebp
	mov	ebp, esp
	sub esp, 4
	pushad
	mov esi, [ebp + 12]		; storing array to esi
	mov edx, [ebp + 8]		; storing message to edx
	mov ecx, [ebp + 16]		; storing array size to ecx
	mov counter_local, 0	; counter = 0 to keep track of row size
	call WriteString
	call CrLf
	printLoop:
		cmp counter_local, 10
		jne cont
		mov counter_local, 0
		call CrLf
		cont:
		mov eax, [esi]
		call WriteDec
		mov al, TAB
		call WriteChar
		inc counter_local
		add	esi, 4
		loop printLoop
	call CrLf
	popad
	mov esp, ebp
	pop ebp
	ret 12
		
PrintList ENDP
;--------------------------------------------------------------------
END main



