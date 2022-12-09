TITLE Designing Low-Level I/O Procedures    (Proj6_wumag.asm)

; Author: Maggie Wu
; Last Modified: 12/1/2022
; OSU email address: wumag@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6                Due Date: 12/4/2022
; Description: This program finds the sum of 10 signed decimal integers (32-bit) and their average values. The user
; inputs the integers and this program will display the list of integers, their sum, and their average value.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt, then get the user’s keyboard input into a memory location .
;
; Preconditions: none
;
; Receives:
; mUserPrompt = prompt address
; mInputAddress = input address
; mInputBuffer = number of bytes in the buffer
; mInputLength = number of bytes entered
;			
; Returns: 
; mInputAddress = generated string address
; ---------------------------------------------------------------------------------

mGetString MACRO mUserPrompt:REQ, mInputAddress:REQ, mInputBuffer:REQ, mInputLength:REQ
	; save registers
	pushad

	; display prompt
	mov		EDX, mUserPrompt
	call	WriteString

	; read string
	mov		EDX, mInputAddress
	mov		ECX, mInputBuffer
	call	ReadString
	mov		mInputLength, EAX

	; restore registers
	popad
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints the string.
;
; Preconditions: none
;
; Receives:
; mInputAddress = input address
;			
; Returns: none
; ---------------------------------------------------------------------------------

mDisplayString MACRO mInputAddress:REQ
	; save register
	push	EDX

	; display string
	mov		EDX, mInputAddress
	call	WriteString

	; restore register
	pop		EDX
ENDM

LO_ASCII				= 48
HI_ASCII				= 57

.data
introMessage	BYTE	"PROGRAMMING ASSIGNMENT 6: Designing Low-Level I/O Procedures by Maggie Wu",13,10,13,10
				BYTE	"Please enter 10 signed decimal integers.",13,10
				BYTE	"Each number needs to be small enough to fit into a 32 bit register.",13,10
				BYTE	"After you have finished inputting, I will show aaa list of the ",13,10
				BYTE	"integers, their sum, and their average value.",13,10,13,10,0
promptMessage	BYTE	"Enter a signed number: ",0
retryMessage	BYTE	"Wanna try again?: ",0
errorMessage	BYTE	"ERROR: That wasn't a signed number or your number was too big.",13,10,0
arrayMessage	BYTE	13,10,"You entered the following numbers: ",13,10,0
sumMessage		BYTE	13,10,"The sum of these numbers is: ",0
avgMessage		BYTE	13,10,"The truncated average is : ",0
goodbye			BYTE	13,10,13,10,"See ya later!",13,10,0
inputString		BYTE	13 DUP(0)
outputString	BYTE	13 DUP(0)
reverseString	BYTE	13 DUP(0)
comma			BYTE	", ",0
inputInt		SDWORD	0
inputLen		DWORD	?
intArray		SDWORD	10 DUP(?)
sum				SDWORD	0
average			SDWORD	0

.code
main PROC 
	; display introduction
	mDisplayString OFFSET introMessage

	mov		ECX, 10
	mov		EDI, OFFSET intArray

_getVals:
	push	OFFSET inputString
	push	SIZEOF inputString
	push	OFFSET inputInt
	push	OFFSET inputLen
	push	OFFSET promptMessage
	push	OFFSET retryMessage
	push	OFFSET errorMessage
	call	ReadVal	

	; store the results in arrays
	mov		EDX, inputInt
	mov		[EDI], EDX
	add		EDI, TYPE intArray
	loop	_getVals

	; find sum and average
	push	OFFSET intArray
	push	TYPE intArray
	push	OFFSET sum
	push	OFFSET average
	call	DoCalculations

	; display numbers
	mDisplayString OFFSET arrayMessage
	mov		ESI, OFFSET intArray
	mov		EDX, [ESI]
	add		ESI, TYPE intArray
	push	EDX
	push	OFFSET outputString
	push	OFFSET reverseString
	call	WriteVal
	mov		ECX, 9

_displayVals:
	mDisplayString OFFSET comma
	mov		EDX, [ESI]
	add		ESI, TYPE intArray
	push	EDX
	push	OFFSET outputString
	push	OFFSET reverseString
	call	WriteVal
	loop	_displayVals

	; display sum
	mDisplayString OFFSET sumMessage
	mov		EDX, sum
	push	EDX
	push	OFFSET outputString
	push	OFFSET reverseString
	call	WriteVal

	; display average
	mDisplayString OFFSET avgMessage
	mov		EDX, average
	push	EDX
	push	OFFSET outputString
	push	OFFSET reverseString
	call	WriteVal

	; display goodbye message
	mDisplayString OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
; 
; Validates user input and converts ASCII digit characters to its signed numeric value. 
;
; Preconditions: none
;
; Postconditions: none
;
; Receives: 
;			[ebp+32] = input buffer address
;			[ebp+28] = input buffer size
;			[ebp+24] = input number address
;			[ebp+20] = number length address
;			[ebp+16] = prompt address 
;			[ebp+12] = retry address
;			[ebp+8] = error address 
;
; returns: inputInt
; ---------------------------------------------------------------------------------

ReadVal PROC
	; save registers
	push	EBP
	mov		EBP, ESP
	push	ESI
	push	EDI
	push	ECX
	push	EDX
	push	EAX
	push	EBX

	; get user input
	mGetString [EBP+16], [EBP+32], [EBP+28], [EBP+20]
	
_validate:
	; setup registers
	mov		ESI, [EBP+32]
	mov		EDI, [EBP+24]
	mov		ECX, [EBP+20]
	mov		EBX, 1
	mov		EDX, 0

	; check if length is between 0-12
	cmp		ECX, 0
	je		_reprompt
	cmp		ECX, 12
	jge		_reprompt

	; check if first character is + or -
	lodsb	
	dec		ECX
	cmp		AL, '-'
	je		_negativeSign
	cmp		AL, '+'
	je		_nextCheck
	inc		ECX
	jmp		_noSign
	
_negativeSign:
	mov		EBX, -1

_nextCheck:
	lodsb

_noSign:
	; check that next character is a number, then convert 
	cmp		AL, HI_ASCII
	jg		_reprompt
	cmp		AL, LO_ASCII
	jl		_reprompt
	sub		AL, LO_ASCII	

	; multiply input number by 10
	push	EBX
	push	EAX
	mov		EAX, EDX
	mov		EDX, 0
	mov		EBX, 10
	imul	EBX
	cmp		EDX, 0			; check for overflow
	jne		_reprompt
	mov		EDX, EAX		
	pop		EAX

	; add the new number and check carry flag
	movsx	EBX, AL
	add		EDX, EBX
	jo		_overflow		
	pop		EBX
	loop	_nextCheck
	jmp		_valid

_overflow:
	; skip checks/valid loop if overflow
	pop		EBX

_reprompt:
	mov		EDX, 0										; reset
	mDisplayString [EBP+8]								; display error message
	mGetString	[EBP+12], [EBP+32], [EBP+28], [EBP+20]  ; reprompt for another input
	jmp		_validate

_valid:
	; adjust if negative and store the value
	mov		EAX, EDX
	imul	EBX
	mov		[EDI], EAX

	; restore registers
	pop		EBX
	pop		EAX
	pop		EDX
	pop		ECX
	pop		EDI
	pop		ESI
	pop		EBP
	ret		28

ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: DoCalculations
; 
; Finds the sum and rounded average of an array.
;
; Preconditions: none
;
; Postconditions: none
;
; Receives: 
;			[ebp+20] = intArray address
;			[ebp+16] = type of intArray
;			[ebp+12] = sum address
;			[ebp+8] = average address
;
; returns: sum and average
; ---------------------------------------------------------------------------------

DoCalculations PROC
	; save registers
	push	EBP
	mov		EBP, ESP
	push	ESI
	push	EDI
	push	ECX
	push	EAX

	; setup registers
	mov		ESI, [EBP+20]
	mov		ECX, 10
	mov		EAX, 0

_sumLoop:
	; find and store sum
	add		EAX, [ESI]
	add		ESI, [EBP+16]
	loop	_sumLoop
	mov		EDI, [EBP+12]
	mov		[EDI], EAX

	; find and store avg
	mov		ECX, 10
	cdq	
	idiv	ECX
	mov		EDI, [EBP+8]
	mov		[EDI], EAX

	; restore registers and return
	pop		EAX
	pop		ECX
	pop		EDI
	pop		ESI
	pop		EBP
	ret		16

DoCalculations ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
; 
; Reads a signed int, converts to string, and outputs to the screen.
;
; Preconditions: none
;
; Postconditions: Output string and reverse string variables will be changed.
;
; Receives: 
;			[ebp+16] = signed integer
;			[ebp+12] = output string
;			[ebp+8] = reverse string
;
; returns: none
; ---------------------------------------------------------------------------------

WriteVal PROC
	
	; save registers 
	push	EBP
	mov		EBP, ESP
	push	EDX
	push	EAX
	push	EBX
	push	ECX
	push	EDI
	push	ESI

	; find if + or -
	mov		EDX, [EBP+16]
	cmp		EDX, 0
	jl		_negative
	mov		AL, '+'
	jmp		_setup

_negative:
	mov		AL, '-'
	neg		EDX

_setup:
	push	EAX
	mov		ECX, 0
	mov		EDI, [EBP+8]

_nextDigit:
	; divide the number by 10
	mov		EAX, EDX
	mov		EBX, 10
	cdq
	idiv	EBX

	; store remainder
	push	EAX
	mov		EAX, EDX
	add		AL, LO_ASCII
	stosb
	pop		EAX
	inc		ECX
	mov		EDX, EAX
	cmp		EAX, 0
	jne		_nextDigit

	; check if we need to add the negative sign
	pop		EAX
	cmp		AL, '-'
	je		_addNeg
	jmp		_skipSign

_addNeg:
	stosb
	inc		ECX

_skipSign:
	; setup the registers
	mov		ESI, [EBP+8]
	add		ESI, ECX
	dec		ESI
	mov		EDI, [EBP+12]

_reverseString:
	std
	lodsb
	cld
	stosb
	loop	_reverseString
	mov		AL, 0					; reset string
	stosb
	
	mDisplayString [EBP+12]

	; restore registers
	pop		ESI
	pop		EDI
	pop		ECX
	pop		EBX
	pop		EAX
	pop		EDX
	pop		EBP

	ret		16

WriteVal ENDP

END main