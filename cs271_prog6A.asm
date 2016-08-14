TITLE Program 6A (cs271_prog6A.asm)
; CS271-400 Program 6A (Due 03/15/15)
; Author: Susan Kuretski (kuretsks@onid.oregonstate.edu)
; Date 3/11/15
; Description: Write a small test program that gets 10 valid integers
; from the user and stores the numeric values in an array. The program
; then displays the integers, their sum and their average. 
;	1. Implement and test your own ReadVal and WriteVal procedures
;		for unsigned integers.
;	2. Implement macros getString and displayString (may use Irvine's
;		ReadString and WriteString)
;	3. getString should display a prompt, then get the user's keyboard
;		input into a memory location
;	4. displayString should store the string in a specified memory location
;	5. readVal should invoke getString macro to get the user's string of digits.
;		It should then convert the digit string to numeric, while validating.
;	6. writeVal should convert a numeric value to a string of digits and invoke
;		displayString macro to produce the output


INCLUDE Irvine32.inc

MAX_NUM = 4294967295

getString MACRO varName
	push ecx
	push edx
	mov edx, OFFSET varName
	mov ecx, (SIZEOF varName) - 1
	call ReadString
	pop edx
	pop ecx
ENDM
	
displayString MACRO buffer
	push edx
	mov edx, OFFSET buffer
	call WriteString
	call CrLf
	call CrLf
	pop edx
ENDM

.data

	introMsg		BYTE		"Program 6A: Designing Low-Level I/O Procedures", 0
	authorMsg		BYTE		"Writen by Susan Kuretski", 0
	instructMsg	BYTE		"Please provide 10 unsigned decimal integers.", 0dh, 0ah
				BYTE		"Each number needs to be small enough to fit inside a 32-bit", 0dh, 0ah
				BYTE		"register. After you have finished inputting the numbers,", 0dh, 0ah
				BYTE		"the list of integers, their sum and their average will be displayed.", 0
	userPrompt	BYTE		"Please enter an unsigned number: ", 0
	errorMsg		BYTE		"Error: you did not enter an unsigned number or it was too big.", 0dh, 0ah
				BYTE		"Please try again.", 0
	arrayMsg		BYTE		"Contents of array: ", 0
	meanMsg		BYTE		"Mean: ", 0
	sumMsg		BYTE		"Sum: ", 0

	numArray		DWORD	10 DUP(?)
	numArraySz	DWORD	10
	numStrg		BYTE		11 DUP(?)
	userNum		DWORD	?
	numStrgSize	DWORD	?
	mean			DWORD	?
	meanStrg		BYTE		10 DUP(?)
	sum			DWORD	? 
	sumStrg		BYTE		10 DUP(?)
	temp			BYTE		10 DUP(?)

.code
   main PROC
   	call Intro
; Get user input
		mov ecx, 10					; loop 10 times for 10 numbers
		mov esi, OFFSET numArray			; To store numerical input after conversion
	getInput:
		call getNumber			
		mov numStrgSize, (LENGTHOF numStrg) - 1
		push OFFSET numStrg
		push numStrgSize 

		call CharToNum					; changing user's number string to numerical value
		mov userNum, edx
		cmp userNum, MAX_NUM			; comparing number to max
		jb getMoreInput
			tooBig:					; Message if too big
				displayString errorMsg
				jmp getInput
		getMoreInput:					
			mov [esi], edx				; Storing numerical value to array
			add esi, 4
			loop getInput				; Continue to fill array
; Calculate and Show Sum
	push OFFSET numArray
	push LENGTHOF numArray
	call calcSum						; Calculates numerical num from numerical array
	mov sum, eax

	push sum
	push OFFSET sumStrg
	push OFFSET temp
	call NumToString					; Converts numerical sum to string
	displayString sumMsg
	displayString sumStrg
; Calculate and Show Average
	push sum
	push numArraySz
	call CalcMean						; Calculates mean based on numerical sum
	mov mean, eax

	push mean
	push OFFSET meanStrg
	push OFFSET temp
	call NumToString					; Converts numerical mean to string
	displayString meanMsg
	displayString meanStrg

; Display Array as String
	push numArraySz
	push OFFSET numArray
	push OFFSET arrayMsg
	call PrintList						; Prints numerical array
; Display goodbye message

   exit
main ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
Intro PROC
; Description: Displays welcome message and instructions to user. Users
; displayString MACRO with messages 
; Pre-conditions: nothing
; Returns: nothing
	; Display welcome message
		displayString introMsg
		displayString authorMsg
	; Display instructions
		call CrLf
		displayString instructMsg
		call CrLf
		ret

Intro ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
Validate PROC,
	pString: PTR BYTE
; Description: checks a string to see if it contains all numbers
; Pre-conditions: pointer to byte string
; Returns: ebx = 0 if all numbers in string, ebx = 1 if non-numerical
; values are there
	push ecx
	push eax
	push esi
	mov esi, pString
	mov ebx, 0
	L1:
		lodsb
		cmp al, 30h
		jb notNumber
		cmp al, 39h
		ja notNumber
		jmp L1
	notNumber:					; if character not between ASCII 0-9, show error and reprompt
		cmp al, 00h
		je L2
		displayString errorMsg
		mov ebx, 1
	L2:
	pop esi
	pop eax
	pop ecx
	ret

Validate ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
getNumber PROC
; Description: Gets users string number and validates it
; Pre-conditions: none
; Returns: none
	push ebp
	mov ebp, esp
	push ebx
	getValid:
		displayString userPrompt
		getString numStrg
	chechValid:
		invoke Validate, OFFSET numStrg		; checks if number string is valid
		cmp ebx, 1						; ebx will be 1 if invalid (see Validate Proc)
		je getValid
	pop ebx		
	mov esp, ebp
	pop ebp
	ret
getNumber ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
CalcMean PROC
; Description: calculates mean from num (ebp + 12)/ num2 (ebp + 8)
; Pre-condition: push num and num2 on stack
; Returns: mean in EAX
	push ebp
	mov ebp, esp
	push edx
	push ebx
	mov eax, [ebp + 12]			; numerical sum of array
	mov ebx, [ebp + 8]			; size of array
	mov edx, 0
	div ebx					; sum/number of elements = mean
	pop ebx
	pop edx
	mov esp, ebp
	pop ebp
	ret 8

CalcMean ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
CalcSum PROC
; Description: calculates the sum of numbers in an array
; Pre-conditions: array pushed (ebp + 12), size of array (ebp + 8)
; Returns: sum in EAX
	push ebp
	mov ebp, esp
	push esi
	push ecx
	mov esi, [ebp + 12]			; numerical array
	mov ecx, [ebp + 8]			; size of array

	contSum:
		add eax, [esi]			; eax will continue to accumulate values
		add esi, 4
		loop contSum
	pop ecx
	pop esi
	mov esp, ebp
	pop ebp
	ret 8

CalcSum ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
accumulator_local EQU DWORD PTR [ebp - 4]
ten_local EQU DWORD PTR [ebp - 8]
CharToNum PROC
; Description: changes a character to a number i.e. '3' (33h) to 3
; Pre-conditions: string primitive pushed (ebp + 12), size of string (ebp + 8)
; Returns: number in edx
	push ebp
	mov ebp, esp
	sub esp, 8
	push esi
	push ecx

	cld
	mov esi, [ebp + 12]		; string primitive
	mov ecx, [ebp + 8]		; string length
	mov edx, 0
	mov ten_local, 10
;----------------------------------------------------
;	Function similar to this: 
;		int accum = 0;
;		for(int i = 0; string[i] != '\0'; i++)
;			accum = accum * 10 + string[i] - '0';
;		return accum;
;----------------------------------------------------
	Loop1:
		lodsb			
		cmp al, 0h		; compare byte to 00h
		je Loop2			; if end of string jump to end
		movsx ebx, al		; move byte to ebx
		mov eax, edx		
		mul ten_local		
		add eax, ebx
		sub eax, 30h
		mov edx, eax
		loop Loop1
	Loop2:
		pop ecx
		pop esi
		mov esp, ebp
		pop ebp
	ret 8 

CharToNum ENDP
;--------------------------------------------------------------------
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
;--------------------------------------------------------------------
ten_local EQU DWORD PTR [ebp -4]

NumToString PROC
; Description: Converts a number to a character array
; Pre-conditions: passes char array (ebp + 12), temp array (ebp + 8) (for reversing), and numerical
; value (ebp + 16) as parameters on stack
; Returns: nothing
	push ebp
	mov ebp, esp
	sub esp, 4
	pushad
	mov eax, [ebp + 16]	; num
	mov edi, [ebp + 8]	; temp
	mov ten_local, 10

	moreChars:
		cmp eax, 00h
		je complete
		mov dx, 0
		div ten_local
		add edx, 48
		mov [edi], edx
		inc edi
		jmp moreChars
	complete:
	invoke Str_length, ADDR temp
	mov esi, [ebp + 8]
	mov edi, [ebp + 12]
	mov ecx, eax
	cld
	dec eax
	add esi, eax 
	reverse:
		mov al, [esi]
		mov [edi], al
		dec esi
		inc edi
		loop reverse
	popad
	mov esp, ebp
	pop ebp
	ret 8
NumToString ENDP
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
		mov al, ','
		call WriteChar
		mov al, ' '
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

END main