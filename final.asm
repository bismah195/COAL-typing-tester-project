INCLUDE Irvine32.inc



blackColor     EQU 0
greenColor     EQU 10
cyanColor      EQU 11
redColor       EQU 12
yellowColor    EQU 14
whiteColor     EQU 15


bellChar       EQU 07h       ; Produces beep sound
enterChar      EQU 0Dh       ; Carriage return (Enter key)
lineFeedChar   EQU 0Ah       ; Line feed for new line


fileNormal      EQU 80h
shareRead       EQU 1
shareWrite      EQU 2
openAlways      EQU 4
writeAccess     EQU 40000000h
appendAccess    EQU 4
invalidHandle   EQU -1
fileEnd         EQU 2




.data

; Welcome Messages
welcomeMsg      BYTE "===========================================",0Dh,0Ah
                BYTE "       TYPING SPEED GAME          ",0Dh,0Ah
                BYTE "===========================================",0Dh,0Ah,0

askNameMsg      BYTE 0Dh,0Ah,"Enter your name: ",0
helloMsg        BYTE "Hello, ",0
readyMsg        BYTE "! Get ready to type.",0Dh,0Ah,0

instructionMsg  BYTE 0Dh,0Ah,"Type the sentence exactly.",0Dh,0Ah
                BYTE "Timer (30s) starts on first key press...",0Dh,0Ah,0

timeUpMsg       BYTE 0Dh,0Ah,"TIME IS UP!",0Dh,0Ah,0
levelDoneMsg    BYTE 0Dh,0Ah,"Level Completed!",0Dh,0Ah,0

levelOneMsg     BYTE 0Dh,0Ah,"--- LEVEL 1 EASY ---",0Dh,0Ah,0
levelTwoMsg     BYTE 0Dh,0Ah,"--- LEVEL 2 MEDIUM ---",0Dh,0Ah,0
levelThreeMsg   BYTE 0Dh,0Ah,"--- LEVEL 3 HARD ---",0Dh,0Ah,0

pressKeyMsg     BYTE 0Dh,0Ah,"Press any key to continue...",0Dh,0Ah,0

accuracyMsg     BYTE "Accuracy: ",0
speedMsg        BYTE "Speed (WPM): ",0
percentChar     BYTE "%",0Dh,0Ah,0
perfectMsg      BYTE 0Dh,0Ah,"PERFECT MATCH: ",0

bestScoreMsg    BYTE "Congrats, ",0
finalScoreMsg   BYTE "'s best WPM across levels: ",0
scoreLine       BYTE "===========================================",0Dh,0Ah,0

fileName        BYTE "best_scores.txt",0
fileSavedMsg    BYTE 0Dh,0Ah,"Score saved!",0Dh,0Ah,0
fileErrorMsg    BYTE 0Dh,0Ah,"Could not save score!",0Dh,0Ah,0

; Buffers
scoreText       BYTE 12 DUP(0)
fileBuffer      BYTE 150 DUP(0)
digitStack      BYTE 12 DUP(0)

; Typing sentences (longer for medium and hard)
sentenceEasy    BYTE "The cat sat on the mat",0
sentenceMedium  BYTE "A quick brown fox jumps over the lazy dog in the evening while the sun sets behind the mountains",0
sentenceHard    BYTE "Complex algorithms require precise logical reasoning, careful attention to detail, and fast skills to avoid mistakes in coding",0

playerName      BYTE 50 DUP(0)
typedText       BYTE 200 DUP(0)  ; Increased size to fit longer sentences

; Timing and stats variables
startTime       DWORD ?
currentTime     DWORD ?
elapsedTime     DWORD ?
timeLimit       DWORD 30000     ; 30 seconds in milliseconds

correctCount    DWORD ?
typedCount      DWORD ?
accuracyPercent DWORD ?
wpmValue        DWORD ?
bestWpmValue    DWORD 0

bytesWritten    DWORD ?
fileHandleVar   DWORD ?






.code
main PROC
    call showWelcome       ; Display welcome screen
    call getName           ; Ask for player name

    call levelOne          ; Easy level
    call levelTwo          ; Medium level
    call levelThree        ; Hard level

    call showBestWpm       ; Show overall best WPM
    call saveScoreToFile   ; Save best score to file

    exit
main ENDP



; Show Welcome Screen

showWelcome PROC
    mov edx, OFFSET welcomeMsg
    call WriteString
    ret
showWelcome ENDP



; Get Player Name

getName PROC
    mov edx, OFFSET askNameMsg
    call WriteString

    mov edx, OFFSET playerName
    mov ecx, SIZEOF playerName
    call ReadString
    mov byte ptr [playerName+eax],0    ; Null terminate input

    mov edx, OFFSET helloMsg
    call WriteString
    mov edx, OFFSET playerName
    call WriteString
    mov edx, OFFSET readyMsg
    call WriteString
    ret
getName ENDP





levelOne PROC
    mov edx, OFFSET levelOneMsg
    call WriteString
    mov edx, OFFSET sentenceEasy
    call runTyping
    mov edx, OFFSET sentenceEasy
    call showStats
    call waitKey
    ret
levelOne ENDP

levelTwo PROC
    mov edx, OFFSET levelTwoMsg
    call WriteString
    mov edx, OFFSET sentenceMedium
    call runTyping
    mov edx, OFFSET sentenceMedium
    call showStats
    call waitKey
    ret
levelTwo ENDP

levelThree PROC
    mov edx, OFFSET levelThreeMsg
    call WriteString
    mov edx, OFFSET sentenceHard
    call runTyping
    mov edx, OFFSET sentenceHard
    call showStats
    call waitKey
    ret
levelThree ENDP


; Run Typing Logic

runTyping PROC
    push edx
    mov edx, OFFSET instructionMsg
    call WriteString
    pop edx

    ; Set typing text color to yellow
    mov eax, yellowColor + (blackColor*16)
    call SetTextColor
    call WriteString
    mov eax, whiteColor + (blackColor*16)
    call SetTextColor

    call Crlf
    call Crlf

    mov esi,0
    mov elapsedTime,0

    ; Wait for first key press to start timer
    call ReadChar
    cmp al, enterChar
    je finishedTyping
    mov typedText[esi],al
    call WriteChar
    inc esi
    call GetMseconds
    mov startTime,eax        ; Store start time in ms

typingLoop:
    call ReadChar
    mov bl,al
    call GetMseconds
    mov currentTime,eax
    sub eax,startTime
    cmp eax,timeLimit        ; Check if 30s expired
    ja timeUp
    mov al,bl
    cmp al,enterChar
    je finishedTyping
    mov typedText[esi],al
    call WriteChar
    inc esi
    cmp esi,SIZEOF typedText-1
    jae finishedTyping
    jmp typingLoop

timeUp:
    mov al,bellChar
    call WriteChar
    mov eax, redColor + (blackColor*16)
    call SetTextColor
    mov edx, OFFSET timeUpMsg
    call WriteString
    mov eax,timeLimit
    mov elapsedTime,eax
    jmp cleanTyping

finishedTyping:
    mov edx, OFFSET levelDoneMsg
    call WriteString
    call GetMseconds
    sub eax,startTime
    mov elapsedTime,eax       ; Total typing time in ms

cleanTyping:
    mov typedText[esi],0      ; Null terminate typed input
    ret
runTyping ENDP








; Calculate and Display Stats

showStats PROC
    pushad
    mov esi, OFFSET typedText
    mov edi, edx
    mov correctCount,0
    mov typedCount,0

; Compare typed characters with original sentence
checkLoop:
    mov al,[esi]
    cmp al,0
    je calcStats
    inc typedCount
    mov bl,[edi]
    cmp bl,0
    je mismatch
    cmp al,bl
    jne mismatch
    inc correctCount
mismatch:
    inc esi
    cmp byte ptr [edi],0
    je skipInc
    inc edi
skipInc:
    jmp checkLoop

; Calculate Accuracy and WPM
calcStats:
    cmp typedCount,0
    je noInput
    mov eax,correctCount
    mov ebx,100
    mul ebx
    mov ebx,typedCount
    div ebx
    mov accuracyPercent,eax
    cmp elapsedTime,0
    jne okTime
    mov elapsedTime,1
okTime:
    mov eax,typedCount
    mov ebx,12000            ; 60 sec * 200 chars factor for WPM
    mul ebx
    mov ebx,elapsedTime
    div ebx
    mov wpmValue,eax
    cmp eax,bestWpmValue
    jle skipBest
    mov bestWpmValue,eax
skipBest:

    jmp displayResults

noInput:
    mov accuracyPercent,0
    mov wpmValue,0

displayResults:
    call Crlf
    mov eax,cyanColor + (blackColor*16)
    call SetTextColor
    mov edx, OFFSET accuracyMsg
    call WriteString
    mov eax,accuracyPercent
    call WriteDec
    mov edx, OFFSET percentChar
    call WriteString
    mov edx, OFFSET speedMsg
    call WriteString
    mov eax,wpmValue
    call WriteDec
    call Crlf

    cmp accuracyPercent,100
    jne resetColor
    mov eax,greenColor + (blackColor*16)
    call SetTextColor
    mov edx, OFFSET perfectMsg
    call WriteString
    mov edx, OFFSET typedText
    call WriteString
    call Crlf
resetColor:
    mov eax,whiteColor + (blackColor*16)
    call SetTextColor
    popad
    ret
showStats ENDP






; Display Best WPM

showBestWpm PROC
    pushad
    call Crlf
    mov eax,yellowColor + (blackColor*16)
    call SetTextColor
    mov edx, OFFSET bestScoreMsg
    call WriteString
    mov edx, OFFSET playerName
    call WriteString
    mov edx, OFFSET finalScoreMsg
    call WriteString
    mov eax,bestWpmValue
    call WriteDec
    call Crlf
    mov eax,whiteColor + (blackColor*16)
    call SetTextColor
    popad
    ret
showBestWpm ENDP






; Save Score to File

saveScoreToFile PROC
    pushad

    ; Convert WPM number to string
    mov eax,bestWpmValue
    mov edi, OFFSET scoreText
    mov ecx,0
    cmp eax,0
    jne convertLoopStart
    mov byte ptr [edi],'0'
    inc edi
    inc ecx
    jmp convertDoneAll

convertLoopStart:
    mov ebx, OFFSET digitStack
convertLoop:
    cmp eax,0
    je convertDone
    xor edx,edx
    mov ebp,10
    div ebp
    add dl,'0'
    mov [ebx],dl
    inc ebx
    inc ecx
    jmp convertLoop
convertDone:
    dec ebx
reverseLoop:
    cmp ecx,0
    je convertDoneAll
    mov al,[ebx]
    mov [edi],al
    inc edi
    dec ebx
    dec ecx
    jmp reverseLoop
convertDoneAll:
    mov byte ptr [edi],0

; Prepare file buffer [CRLF][Name]: [Score]
    mov esi, OFFSET playerName
    mov edi, OFFSET fileBuffer
    mov byte ptr [edi], enterChar
    inc edi
    mov byte ptr [edi], lineFeedChar
    inc edi

nameLoop:
    lodsb
    cmp al,0
    je appendColon
    mov [edi],al
    inc edi
    jmp nameLoop
appendColon:
    mov byte ptr [edi],':'
    inc edi
    mov byte ptr [edi],' '
    inc edi
    mov esi, OFFSET scoreText

scoreLoop:
    lodsb
    cmp al,0
    je bufferDone
    mov [edi],al
    inc edi
    jmp scoreLoop
bufferDone:
    mov ebp,edi

; Open, append and write file
    INVOKE CreateFile,ADDR fileName,appendAccess,shareRead OR shareWrite,0,openAlways,fileNormal,0
    mov ebx,eax
    cmp eax,invalidHandle
    je fileError
    INVOKE SetFilePointer,ebx,0,0,fileEnd
    mov ecx,ebp
    sub ecx,OFFSET fileBuffer
    INVOKE WriteFile,ebx,ADDR fileBuffer,ecx,ADDR bytesWritten,0
    INVOKE CloseHandle,ebx
    mov edx, OFFSET fileSavedMsg
    call WriteString
    jmp doneSaving

fileError:
    mov edx, OFFSET fileErrorMsg
    call WriteString

doneSaving:
    popad
    ret
saveScoreToFile ENDP




waitKey PROC
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call ReadChar
    call Clrscr
    ret
waitKey ENDP




END main