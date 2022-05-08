;--------------------------------------------------------------------------
;
; Project: rpendleton/lc3-2048
; Description: An implementation of git.io/2048 created using LC-3.
; Created by: Ryan Pendleton (Dec 2014)
;
; License: MIT (see accompanying LICENSE file)
;
; This program was originally written for my final project while taking CS 2810
; (Computer Organization and Architecture) at Utah Valley University. A few
; semesters later, my professor asked if I would be willing to make my source
; public as a resource to future students, which led to this GitHub project.
;
; Since 2014, I've continued to explore LC-3 and have worked on several related
; projects. Although the source code remains largely similar to what I submitted
; for my final project back in 2014, I've made a few modifications to it as
; appropriate for these other projects.
;
; Along those lines, since I don't use Windows anymore, I haven't tested any of
; my recent modifications with the official LC-3 client. If you run into issues,
; I'd recommend looking through the Git history for the original version.
;
;--------------------------------------------------------------------------

.ORIG x3000

;--------------------------------------------------------------------------
; MAIN
; Initializes program
;--------------------------------------------------------------------------

MAIN
      LD    R6, STACK                     ; load stack pointer
      LEA   R5, BOARD                     ; load board pointer

      LEA   R0, INSTRUCTION_MESSAGE       ; show instructions
      PUTS

      LEA   R0, PROMPT_TYPE_MESSAGE       ; prompt for ANSI terminal
      JSR   PROMPT
      BRp   NEW

      STI   R0, CLEAR_STRING_PTR          ; disable ANSI screen clearing
      LD    R1, BOARD_LABELS_TBL_PTR_PTR  ; disable ANSI colors
      LD    R2, TEXT_BOARD_LABELS_TBL_PTR
      STR   R2, R1, #0

NEW   JSR   RESET_BOARD                   ; reset the board
LOOP  JSR   DISPLAY_BOARD                 ; display the board
      JSR   GET_KEY                       ; wait for for a move

      LD    R0, DEAD                      ; check if user is dead
      BRp   IS_DEAD
      BRnzp LOOP

IS_DEAD
      JSR   DISPLAY_BOARD                 ; display the board a final time
      LEA   R0, DEATH_MESSAGE             ; display the death message
      PUTS
      LEA   R0, PROMPT_DEATH_MESSAGE      ; prompt for a new game
      JSR   PROMPT
      BRp   NEW
      HALT

; global data
      STACK       .FILL x4000
;     GAME_STATE
            DEAD  .FILL x00
            BOARD .FILL x01         ; creates an initial game state that
                  .FILL x07         ; can be used to debug game logic
                  .FILL x08
                  .FILL x0F         ; these cells will normally be reset
                  .FILL x01
                  .FILL x06
                  .FILL x09
                  .FILL x0E
                  .FILL x02
                  .FILL x05
                  .FILL x0A
                  .FILL x0D
                  .FILL x03
                  .FILL x04
                  .FILL x0B
                  .FILL x0C

      CLEAR_STRING_PTR             .FILL       CLEAR_STRING
      BOARD_LABELS_TBL_PTR_PTR     .FILL       BOARD_LABELS_TBL_PTR
      TEXT_BOARD_LABELS_TBL_PTR    .FILL       TEXT_BOARD_LABELS_TBL

      PROMPT_TYPE_MESSAGE     .STRINGZ    "Are you on an ANSI terminal (y/n)? "
      PROMPT_DEATH_MESSAGE    .STRINGZ    "Would you like to play again (y/n)? "
      DEATH_MESSAGE           .STRINGZ    "\nYou lost :(\n\n"
      INSTRUCTION_MESSAGE     .STRINGZ    "Control the game using WASD keys.\n"

;--------------------------------------------------------------------------
; RESET_BOARD
; Resets the board and adds two random cells
; Clobbers r0, r1, r2, r3
;--------------------------------------------------------------------------

RESET_BOARD
      STR   R7, R6, #-1
      ADD   R6, R6, #-1

      AND   R0, R0, #0
      AND   R1, R1, #0
      ST    R0, DEAD
RESET_LOOP
      ADD   R2, R1, R5
      STR   R0, R2, #0
      ADD   R1, R1, #1
      ADD   R2, R1, #-16
      BRn   RESET_LOOP

RESET_RANDOM
      JSR   ADD_RANDOM_CELL
      JSR   ADD_RANDOM_CELL

      LDR   R7, R6, #0
      ADD   R6, R6, #1
      RET

;--------------------------------------------------------------------------
; GET_KEY
; Waits for the user to press a key, then updates the board based
; Clobbers r0, r1
;--------------------------------------------------------------------------

GET_KEY
      STR   R7, R6, #-1
      ADD   R6, R6, #-1

GET_KEY_LOOP
      GETC

      LD    R1, W_NEG
      ADD   R1, R0, R1
      BRz   UP

      LD    R1, A_NEG
      ADD   R1, R0, R1
      BRz   LEFT

      LD    R1, S_NEG
      ADD   R1, R0, R1
      BRz   DOWN

      LD    R1, D_NEG
      ADD   R1, R0, R1
      BRz   RIGHT

      BRnzp GET_KEY_LOOP

LEFT
      JSR   SLIDE_BOARD_LEFT
      BRnzp GET_KEY_CHECK
RIGHT
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD
      JSR   SLIDE_BOARD_LEFT
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD
      BRnzp GET_KEY_CHECK
UP
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD
      JSR   SLIDE_BOARD_LEFT
      JSR   ROTATE_BOARD
      BRnzp GET_KEY_CHECK
DOWN
      JSR   ROTATE_BOARD
      JSR   SLIDE_BOARD_LEFT
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD

GET_KEY_CHECK
      ADD   R0, R0, #0        ; R0 contains whether the move was valid
      BRnz  GET_KEY_LOOP      ; the move wasn't valid

GET_KEY_ADD_RANDOM
      JSR   ADD_RANDOM_CELL   ; R0 now contains how many spaces are empty
      ADD   R0, R0, #0        ; check for how many spaces are left
      BRp   GET_KEY_EXIT

GET_KEY_CHECK_DEATH
      JSR   CHECK_DEATH
      ST    R0, DEAD

GET_KEY_EXIT
      LDR   R7, R6, #0
      ADD   R6, R6, #1
      RET

; data
      W_NEG .FILL xFF89 ; ~x77+1
      A_NEG .FILL xFF9F ; ~x61+1
      S_NEG .FILL xFF8D ; ~x73+1
      D_NEG .FILL xFF9C ; ~x64+1

;--------------------------------------------------------------------------
; ROTATE_BOARD
; Rotates the board clockwise once
;--------------------------------------------------------------------------

ROTATE_BOARD
      STR   R0, R6, #-1
      ADD   R6, R6, #-1

      LDR   R0, R5, #1  ; push board[1]
      STR   R0, R6, #-1
      LDR   R0, R5, #2  ; push board[2]
      STR   R0, R6, #-2
      LDR   R0, R5, #3  ; push board[3]
      STR   R0, R6, #-3
      ADD   R6, R6, #-3 ; update stack

      LDR   R0, R5, x0  ; board[3] = board[0]
      STR   R0, R5, x3
      LDR   R0, R5, x4  ; board[2] = board[4]
      STR   R0, R5, x2
      LDR   R0, R5, x8  ; board[1] = board[8]
      STR   R0, R5, x1

      LDR   R0, R5, xC  ; board[0] = board[C]
      STR   R0, R5, x0
      LDR   R0, R5, xD  ; board[4] = board[D]
      STR   R0, R5, x4
      LDR   R0, R5, xE  ; board[8] = board[E]
      STR   R0, R5, x8

      LDR   R0, R5, xF  ; board[C] = board[F]
      STR   R0, R5, xC
      LDR   R0, R5, xB  ; board[D] = board[B]
      STR   R0, R5, xD
      LDR   R0, R5, x7  ; board[E] = board[7]
      STR   R0, R5, xE

      LDR   R0, R6, #0  ; board[F] = board[3] (from stack)
      STR   R0, R5, xF
      LDR   R0, R6, #1  ; board[B] = board[2] (from stack)
      STR   R0, R5, xB
      LDR   R0, R6, #2  ; board[7] = board[1] (from stack)
      STR   R0, R5, x7

      ADD   R6, R6, #3  ; restore stack

      LDR   R0, R5, #6  ; push board[6]
      STR   R0, R6, #-1
      ADD   R6, R6, #-1 ; update stack

      LDR   R0, R5, x5  ; board[6] = board[5]
      STR   R0, R5, x6
      LDR   R0, R5, x9  ; board[5] = board[9]
      STR   R0, R5, x5
      LDR   R0, R5, xA  ; board[9] = board[A]
      STR   R0, R5, x9
      LDR   R0, R6, #0  ; board[A] = board[6] (from stack)
      STR   R0, R5, xA

      ADD   R6, R6, #1  ; restore stack

      LDR   R0, R6, #0
      ADD   R6, R6, #1
      RET

;--------------------------------------------------------------------------
; SLIDE_BOARD_LEFT
; Slide the board to the left
; Returns r0 > 0 if the move was successful
;--------------------------------------------------------------------------

SLIDE_BOARD_LEFT
      STR   R7, R6, #-1       ; save registers
      STR   R1, R6, #-2
      ADD   R6, R6, #-2

      AND   R1, R1, #0        ; clear R1 to save if there was a change

      ADD   R0, R5, x0        ; slide first row
      JSR SLIDE_ROW_LEFT
      ADD   R1, R0, R1

      ADD   R0, R5, x4        ; slide second row
      JSR SLIDE_ROW_LEFT
      ADD   R1, R0, R1

      ADD   R0, R5, x8        ; slide third row
      JSR SLIDE_ROW_LEFT
      ADD   R1, R0, R1

      ADD   R0, R5, xC        ; slide fourth row
      JSR SLIDE_ROW_LEFT
      ADD   R0, R0, R1

      LDR   R1, R6, #0
      LDR   R7, R6, #1
      ADD   R6, R6, #2

      RET

;--------------------------------------------------------------------------
; SLIDE_ROW_LEFT
; Slides a row to the left
; Returns r0 = 1 if successful move
; Clobbers r2, r3, r4
;--------------------------------------------------------------------------

SLIDE_ROW_LEFT
      STR   R1, R6, #-1       ; save registers
      ADD   R6, R6, #-1

      AND   R1, R1, #0        ; clear R1 (cell counter)
      AND   R2, R2, #0        ; clear R2 (non-empty counter)
                              ; R3 is used to calculate pointers
                              ; R4 stores read cell values

SLIDE_CHECKSUM
      LDR   R4, R0, #0        ; calculate checksum board[0]
      ADD   R3, R4, R4        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1

      LDR   R4, R0, #1        ; calculate checksum board[1]
      ADD   R3, R3, R4        ; R3 += R4
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1

      LDR   R4, R0, #2        ; calculate checksum board[2]
      ADD   R3, R3, R4        ; R3 += R4
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1

      LDR   R4, R0, #3        ; calculate checksum board[3]
      ADD   R3, R3, R4        ; R3 += R4

      STR   R3, R6, #-1
      ADD   R6, R6, #-1

SLIDE_FIND_LOOP               ; shift all cells to left
      ADD   R4, R0, R1
      LDR   R4, R4, #0        ; get cell at row[non-incremented R1]
      BRnz  SLIDE_CHECK_NEXT
SLIDE_FOUND_BOX
      ADD   R3, R0, R2
      ADD   R2, R2, #1
      STR   R4, R3, #0
SLIDE_CHECK_NEXT
      ADD   R1, R1, #1
      ADD   R4, R1, #-4
      BRn   SLIDE_FIND_LOOP

      AND   R1, R1, #0        ; clear R1 (fill remaining cells with 0)
SLIDE_FILL_LOOP
      ADD   R4, R2, #-4       ; check for existing cells
      BRz   SLIDE_FIND_FIRST_MATCH
      ADD   R3, R0, R2
      ADD   R2, R2, #1
      STR   R1, R3, #0
      BRnzp SLIDE_FILL_LOOP

SLIDE_FIND_FIRST_MATCH
      LDR   R1, R0, #0
      LDR   R3, R0, #1
      BRz   SLIDE_FINISHED_MATCHING       ; if(no_cell) stop_matching
      NOT   R3, R3                        ; if(stack[-1] == stack[-2])
      ADD   R3, R3, #1                    ;
      ADD   R3, R1, R3                    ;
      BRnp  SLIDE_FIND_SECOND_MATCH       ; {
      ADD   R1, R1, #1                    ;     stack[-1]++;
      STR   R1, R0, #0                    ;
      LDR   R1, R0, #2                    ;     stack[-2] = stack[-3];
      STR   R1, R0, #1                    ;
      LDR   R1, R0, #3                    ;     stack[-3] = stack[-4];
      STR   R1, R0, #2                    ;
      AND   R1, R1, #0                    ;     stack[-4] = 0;
      STR   R1, R0, #3                    ;
                                          ; }
SLIDE_FIND_SECOND_MATCH
      LDR   R1, R0, #1
      LDR   R3, R0, #2
      BRz   SLIDE_FINISHED_MATCHING       ; if(no_cell) stop_matching
      NOT   R3, R3                        ; if(stack[-2] == stack[-3])
      ADD   R3, R3, #1                    ;
      ADD   R3, R1, R3                    ;
      BRnp  SLIDE_FIND_THIRD_MATCH        ; {
      ADD   R1, R1, #1                    ;     stack[-2]++;
      STR   R1, R0, #1                    ;
      LDR   R1, R0, #3                    ;     stack[-3] = stack[-4];
      STR   R1, R0, #2                    ;
      AND   R1, R1, #0                    ;     stack[-4] = 0;
      STR   R1, R0, #3                    ;
                                          ; }
      BRnzp SLIDE_FINISHED_MATCHING
SLIDE_FIND_THIRD_MATCH
      LDR   R1, R0, #2
      LDR   R3, R0, #3
      BRz   SLIDE_FINISHED_MATCHING       ; if(no_cell) stop_matching
      NOT   R3, R3                        ; if(stack[-3] == stack[-4])
      ADD   R3, R3, #1                    ;
      ADD   R3, R1, R3                    ;
      BRnp  SLIDE_FINISHED_MATCHING       ; {
      ADD   R1, R1, #1                    ;     stack[-3]++;
      STR   R1, R0, #2                    ;
      AND   R1, R1, #0                    ;     stack[-4] = 0;
      STR   R1, R0, #3                    ;
                                          ; }

SLIDE_FINISHED_MATCHING
      LDR   R4, R0, #0        ; calculate checksum board[0]
      ADD   R3, R4, R4        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1

      LDR   R4, R0, #1        ; calculate checksum board[1]
      ADD   R3, R3, R4        ; R3 += R4
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1

      LDR   R4, R0, #2        ; calculate checksum board[2]
      ADD   R3, R3, R4        ; R3 += R4
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1
      ADD   R3, R3, R3        ; R3 << 1

      LDR   R4, R0, #3        ; calculate checksum board[3]
      ADD   R3, R3, R4        ; R3 += R4

      NOT   R3, R3
      ADD   R3, R3, #1
      LDR   R4, R6, #0
      AND   R0, R0, #0
      ADD   R3, R3, R4
      BRz   SLIDE_EXIT
      ADD   R0, R0, #1

SLIDE_EXIT
      LDR   R1, R6, #1
      ADD   R6, R6, #2
      RET

;--------------------------------------------------------------------------
; ADD_RANDOM_CELL
; Adds a random cell to the board
; Returns r0 = empty spaces remaining
; Clobbers r1, r2
;--------------------------------------------------------------------------

ADD_RANDOM_CELL
      STR   R7, R6, #-1
      ADD   R6, R6, #-1

      AND   R1, R1, #0  ; clear R1 (count empty)
      AND   R2, R2, #0  ; clear R2 (count total)

ADD_RANDOM_LOOP
      ADD   R0, R2, R5        ; get value at board[R2]
      ADD   R2, R2, #1
      STR   R0, R6, #-1       ; keep on stack in case empty
      LDR   R0, R0, #0
      BRp   ADD_RANDOM_NEXT
ADD_RANDOM_EMPTY
      ADD   R1, R1, #1        ; empty
      ADD   R6, R6, #-1       ; update stack
ADD_RANDOM_NEXT
      ADD   R0, R2, #-16
      BRn   ADD_RANDOM_LOOP

ADD_RANDOM_COUNTED
      ADD   R0, R1, #0        ; calculate random spot
      BRz   ADD_RANDOM_EXIT
      JSR   RAND_MOD
      ADD   R2, R0, R6        ; calculate pointer to spot

      LD    R0, RANDOM_4_MOD  ; determine which block to place
      JSR   RAND_MOD
      ADD   R0, R0, #0        ; check if == 0
      BRz   ADD_RANDOM_4
ADD_RANDOM_2
      AND   R0, R0, #0
      ADD   R0, R0, #1
      BRnzp ADD_RANDOM_RESTORE
ADD_RANDOM_4
      ADD   R0, R0, #2

ADD_RANDOM_RESTORE
      ; R0: 1 or 2, depending on block type
      ; R1: number of empty spots
      ; R2: pointer to stack spot

      LDR   R2, R2, #0  ; get destination address
      STR   R0, R2, #0  ; store new block in address
      ADD   R0, R1, #-1 ; subtract one from empty spaces since we filled one

ADD_RANDOM_EXIT
      ADD   R6, R6, R1  ; restore stack
      LDR   R7, R6, #0
      ADD   R6, R6, #1

      RET

; data
      RANDOM_4_MOD      .FILL xB ; (random() % 11 == 0, so 1/10 chance)

;--------------------------------------------------------------------------
; CHECK_DEATH
; Checks if there are plays available in a full board
; Returns r0 = 1 if dead, 0 if alive
;--------------------------------------------------------------------------

CHECK_DEATH
      STR   R7, R6, #-1                   ; save registers
      ADD   R6, R6, #-1

      AND   R4, R4, #0                    ; 1 if regular, 0 if rotated
      ADD   R4, R4, #1

CHECK_DEATH_LOOP
      ADD   R0, R5, x0                    ; check first row
      JSR   CHECK_DEATH_ROW
      BRz   DEATH_FINISHED_CHECKING

      ADD   R0, R5, x4                    ; check second row
      JSR   CHECK_DEATH_ROW
      BRz   DEATH_FINISHED_CHECKING

      ADD   R0, R5, x8                    ; check third row
      JSR   CHECK_DEATH_ROW
      BRz   DEATH_FINISHED_CHECKING

      ADD   R0, R5, xC                    ; check fourth row
      JSR   CHECK_DEATH_ROW
      BRz   DEATH_FINISHED_CHECKING

      ADD   R4, R4, #-1
      BRn   DEATH_FINISHED_CHECKING
      JSR   ROTATE_BOARD
      BRnzp CHECK_DEATH_LOOP

DEATH_FINISHED_CHECKING
      ADD   R4, R4, #0                    ; check to see if we rotated the board
      BRp   DEATH_EXIT

DEATH_ROTATE
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD
      JSR   ROTATE_BOARD

DEATH_EXIT
      LDR   R7, R6, #0
      ADD   R6, R6, #1
      ADD   R0, R1, #0
      RET

;--------------------------------------------------------------------------
; CHECK_DEATH_ROW
; Checks if there are plays available in a full row (pointed to by r0)
; Returns r1 = 1 if dead, 0 if alive
;--------------------------------------------------------------------------

CHECK_DEATH_ROW
      LDR   R2, R0, x0                    ; R2 = row[0]
      LDR   R3, R0, x1                    ; R3 = row[1]
      NOT   R3, R3
      ADD   R3, R3, #1                    ; R3 = -row[1]
      ADD   R1, R2, R3                    ; R1 = row[0] - row[1]
      BRz   DEATH_ROW_PLAYS_AVAILABLE

      LDR   R2, R0, x2                    ; R2 = row[2]
      ADD   R1, R2, R3                    ; R1 = row[2] - row[1]
      BRz   DEATH_ROW_PLAYS_AVAILABLE

      LDR   R3, R0, x3                    ; R3 = row[3]
      NOT   R3, R3
      ADD   R3, R3, #1                    ; R3 = -row[3]
      ADD   R1, R2, R3                    ; R1 = row[2] - row[3]
      BRz   DEATH_ROW_PLAYS_AVAILABLE

DEATH_ROW_NO_PLAYS
      AND   R1, R1, #0
      ADD   R1, R1, #1

DEATH_ROW_PLAYS_AVAILABLE
      RET

;--------------------------------------------------------------------------
; DISPLAY_BOARD
; Displays the board and clears the screen on an ANSI terminal
; Clobbers r0, r1, r2, r3
;--------------------------------------------------------------------------

DISPLAY_BOARD
      STR   R7, R6, #-1
      ADD   R6, R6, #-1

      LEA   R0, CLEAR_STRING  ; clear screen if on ANSI terminal
      PUTS

      LD    R1, BOARD_LABELS_TBL_PTR
      AND   R2, R2, #0

      LEA   R0, LINE_BORDER   ; display border
      PUTS
      LD    R0, NEW_LINE
      OUT

DISPLAY_NEXT_LINE
      LEA   R0, EMPTY_BORDER
      PUTS
      LD    R0, NEW_LINE
      OUT

      LEA   R0, LEFT_BORDER
      PUTS

DISPLAY_NEXT_SPACE
      LD    R0, SPACE
      OUT

      ADD   R3, R5, R2              ; R3 = board[R2++]
      LDR   R3, R3, #0
      ADD   R2, R2, #1

      ADD   R0, R1, R3              ; get the label from board_labels[R3]
      LDR   R0, R0, #0
      PUTS

      LD    R0, SPACE
      OUT

      ADD   R0, R2, #-4             ; end of first line
      BRz   DISPLAY_RIGHT_BORDER
      ADD   R0, R2, #-8             ; end of second line
      BRz   DISPLAY_RIGHT_BORDER
      ADD   R0, R2, #-12            ; end of third line
      BRz   DISPLAY_RIGHT_BORDER
      ADD   R0, R2, #-16            ; end of last line
      BRz   DISPLAY_RIGHT_BORDER
      BRnp  DISPLAY_NEXT_SPACE

DISPLAY_RIGHT_BORDER
      LEA   R0, RIGHT_BORDER
      PUTS

      ADD   R0, R2, #-16            ; end of last line
      BRnp  DISPLAY_NEXT_LINE

DISPLAY_BOTTOM_BORDER
      LEA   R0, EMPTY_BORDER
      PUTS
      LD    R0, NEW_LINE
      OUT
      LEA   R0, LINE_BORDER
      PUTS
      LD    R0, NEW_LINE
      OUT

DIS_FINISH
      LDR   R7, R6, #0
      ADD   R6, R6, #1
      RET

; data
;     SYSTEM_TYPE       ; first byte of clear string is either \e or \0
      CLEAR_STRING      .STRINGZ    "\e[2J\e[H\e[3J"
      LINE_BORDER       .STRINGZ    "+--------------------------+"
      EMPTY_BORDER      .STRINGZ    "|                          |"
      LEFT_BORDER       .STRINGZ    "| "
      RIGHT_BORDER      .STRINGZ    " |\n"

      SPACE             .FILL x20 ; space
      NEW_LINE          .FILL x0A ; new line

      ; will be reassigned to TEXT if and when ANSI is disabled
      BOARD_LABELS_TBL_PTR    .FILL ANSI_BOARD_LABELS_TBL

;--------------------------------------------------------------------------
; RAND_MOD
; Generates random number between 0 and r0 - 1 inclusively
; Returns r0 = random number
;--------------------------------------------------------------------------

RAND_MOD
      STR   R0, R6, #-1
      STR   R1, R6, #-2
      STR   R2, R6, #-3
      STR   R7, R6, #-4
      ADD   R6, R6, #-4

      LD    R0, RAND_SEED
      LD    R1, RAND_Q
      JSR   MOD_DIV           ; R0 = x % q

      LD    R1, RAND_A
      JSR   MULT              ; R0 = (x % q) * a
      ST    R0, RAND_SEED

      LDR   R1, R6, #3        ; get original R0
      JSR   MOD_DIV

      LDR   R7, R6, #0
      LDR   R2, R6, #1
      LDR   R1, R6, #2
      ADD   R6, R6, #4
      RET

; data
      RAND_INIT   .FILL x0000
      RAND_SEED   .FILL xC20D
      RAND_A      .FILL x0007
      RAND_M      .FILL x7FFF ; 2^15 - 1
      RAND_Q      .FILL x1249 ; M/A

;--------------------------------------------------------------------------
; PROMPT
; Prompts the user until they enter y/n
; Returns r0 = 0 if false, 1 if true, sets flags
;--------------------------------------------------------------------------

PROMPT
      STR   R0, R6, #-1       ; save registers
      STR   R1, R6, #-2
      STR   R7, R6, #-3
      ADD   R6, R6, #-3

PROMPT_LOOP                   ; prompt until y/n
      LDR   R0, R6, #2
      PUTS

      JSR   GETC_SEED
      OUT

      ADD   R1, R0, #0
      LD    R0, PROMPT_NEW_LINE
      OUT

      LD    R0, PROMPT_RESPONSE_y
      ADD   R0, R0, R1
      BRz   PROMPT_YES

      LD    R0, PROMPT_RESPONSE_n
      ADD   R0, R0, R1
      BRz   PROMPT_NO

PROMPT_INVALID
      ADD   R0, R1, #0
      OUT
      LEA   R0, PROMPT_INVALID_MESSAGE
      PUTS
      BRnzp PROMPT_LOOP

PROMPT_NO
      AND   R0, R0, #0
      BRnzp PROMPT_EXIT

PROMPT_YES
      AND   R0, R0, #0
      ADD   R0, R0, #1

PROMPT_EXIT
      LDR   R7, R6, #0        ; restore registers
      LDR   R1, R6, #1
      ADD   R6, R6, #3
      ADD   R0, R0, #0
      RET

; data
      PROMPT_INVALID_MESSAGE  .STRINGZ    " is not a valid input.\n\n"
      PROMPT_RESPONSE_y       .FILL xFF87 ; ~x79+1
      PROMPT_RESPONSE_n       .FILL xFF92 ; ~x6e+1
      PROMPT_NEW_LINE         .FILL x0A

;--------------------------------------------------------------------------
; GETC_SEED
; Seeds random number generator while getting a character from the keyboard
; Returns r0 = character
;--------------------------------------------------------------------------

GETC_SEED
      STR   R1, R6, #-1       ; save R1
      ADD   R6, R6, #-1

      AND   R1, R1, #0
GETC_SEED_LOOP                ; R1++ until character pressed
      ADD   R1, R1, #1
      LDI   R0, OS_KBSR
      BRzp  GETC_SEED_LOOP

      LD    R0, SEED_MASK
      AND   R1, R1, R0

      LDI   R0, OS_KBDR       ; get character
      ST    R1, RAND_SEED     ; save R1 to seed
      ST    R1, RAND_INIT     ; save initial for debugging

      LDR   R1, R6, #0        ; restore R1
      ADD   R6, R6, #1
      RET

; data
      OS_KBSR     .FILL xFE00
      OS_KBDR     .FILL xFE02
      SEED_MASK   .FILL x7FFF

;--------------------------------------------------------------------------
; MOD_DIV
; Performs r0 % r1 and r0/r1.
; Returns r0 = remainder, r1 = quotient
;--------------------------------------------------------------------------

MOD_DIV
      STR   R1, R6, #-1       ; save registers
      STR   R2, R6, #-2
      STR   R3, R6, #-3
      ADD   R6, R6, #-3

      NOT   R2, R1
      ADD   R2, R2, #1
      BRz   MOD_DIV_EX        ; halt if dividing by zero

      AND   R1, R1, #0        ; clear R1 (quotient)

MOD_DIV_LOOP
      ADD   R1, R1, #1
      ADD   R0, R0, R2        ; R0 -= R1
      BRp MOD_DIV_LOOP        ; R0 - R1 > 0, so keep looping
      BRz MOD_DIV_END         ; R0 = 0, so we finished exactly

                              ; R0 < 0, so we subtracted an extra one
      LDR   R2, R6, #2        ; add it back in
      ADD   R1, R1, #-1
      ADD   R0, R0, R2

MOD_DIV_END
      LDR   R3, R6, #0
      LDR   R2, R6, #1
      ADD   R6, R6, #3
      RET

MOD_DIV_EX
      HALT

;--------------------------------------------------------------------------
; MULT
; Performs multiplication using bit shifting
; Returns r0 = r0 * r1
;--------------------------------------------------------------------------

MULT
      ADD   R0, R0, #0
      BRz   MULT_ZERO   ; return 0 if R0 = 0
      ADD   R1, R1, #0
      BRz   MULT_ZERO   ; return 0 if R1 = 0

      STR   R1, R6, #-1 ; save registers
      STR   R2, R6, #-2 ; save registers
      STR   R3, R6, #-3
      STR   R4, R6, #-4
      ADD   R6, R6, #-4

      AND   R2, R2, #0  ; clear R2 (product)
      ADD   R3, R2, #1  ; set R3 = 1 (bit tester)

MULT_LOOP               ; for each bit in R0
      AND   R4, R0, R3        ; R4 = bit test(R0, R3)
      BRnz  #1                ; only execute next line if bit is set
      ADD   R2, R2, R1              ; product = product + R1
      ADD   R1, R1, R1        ; R1 << 1
      ADD   R3, R3, R3        ; R3 << 1
      BRp   MULT_LOOP

      ADD   R0, R2, #0  ; move product to R0

MULT_END
      LDR   R4, R6, #0  ; restore registers
      LDR   R3, R6, #1
      LDR   R2, R6, #2
      LDR   R1, R6, #3
      ADD   R6, R6, #4
      RET

MULT_ZERO
      AND   R0, R0, #0
      RET

;--------------------------------------------------------------------------
; DATA SEGMENT
; Containts data that's large enough to cause issues with PC-relative offsets
; in other areas of the program.
;--------------------------------------------------------------------------

; board label tables
      TEXT_BOARD_LABELS_TBL   .FILL TEXT_BOARD_LABELS_0
                              .FILL TEXT_BOARD_LABELS_1
                              .FILL TEXT_BOARD_LABELS_2
                              .FILL TEXT_BOARD_LABELS_3
                              .FILL TEXT_BOARD_LABELS_4
                              .FILL TEXT_BOARD_LABELS_5
                              .FILL TEXT_BOARD_LABELS_6
                              .FILL TEXT_BOARD_LABELS_7
                              .FILL TEXT_BOARD_LABELS_8
                              .FILL TEXT_BOARD_LABELS_9
                              .FILL TEXT_BOARD_LABELS_10
                              .FILL TEXT_BOARD_LABELS_11
                              .FILL TEXT_BOARD_LABELS_12
                              .FILL TEXT_BOARD_LABELS_13
                              .FILL TEXT_BOARD_LABELS_14
                              .FILL TEXT_BOARD_LABELS_15
                              .FILL TEXT_BOARD_LABELS_16

      ANSI_BOARD_LABELS_TBL   .FILL ANSI_BOARD_LABELS_0
                              .FILL ANSI_BOARD_LABELS_1
                              .FILL ANSI_BOARD_LABELS_2
                              .FILL ANSI_BOARD_LABELS_3
                              .FILL ANSI_BOARD_LABELS_4
                              .FILL ANSI_BOARD_LABELS_5
                              .FILL ANSI_BOARD_LABELS_6
                              .FILL ANSI_BOARD_LABELS_7
                              .FILL ANSI_BOARD_LABELS_8
                              .FILL ANSI_BOARD_LABELS_9
                              .FILL ANSI_BOARD_LABELS_10
                              .FILL ANSI_BOARD_LABELS_11
                              .FILL ANSI_BOARD_LABELS_12
                              .FILL ANSI_BOARD_LABELS_13
                              .FILL ANSI_BOARD_LABELS_14
                              .FILL ANSI_BOARD_LABELS_15
                              .FILL ANSI_BOARD_LABELS_16

; non-ANSI board labels
      TEXT_BOARD_LABELS_0     .STRINGZ    "    "
      TEXT_BOARD_LABELS_1     .STRINGZ    " 2  "
      TEXT_BOARD_LABELS_2     .STRINGZ    " 4  "
      TEXT_BOARD_LABELS_3     .STRINGZ    " 8  "
      TEXT_BOARD_LABELS_4     .STRINGZ    " 16 "
      TEXT_BOARD_LABELS_5     .STRINGZ    " 32 "
      TEXT_BOARD_LABELS_6     .STRINGZ    " 64 "
      TEXT_BOARD_LABELS_7     .STRINGZ    "128 "
      TEXT_BOARD_LABELS_8     .STRINGZ    "256 "
      TEXT_BOARD_LABELS_9     .STRINGZ    "512 "
      TEXT_BOARD_LABELS_10    .STRINGZ    "1024"
      TEXT_BOARD_LABELS_11    .STRINGZ    "2048"
      TEXT_BOARD_LABELS_12    .STRINGZ    "4096"
      TEXT_BOARD_LABELS_13    .STRINGZ    "8192"
      TEXT_BOARD_LABELS_14    .STRINGZ    "2^14"
      TEXT_BOARD_LABELS_15    .STRINGZ    "2^15"
      TEXT_BOARD_LABELS_16    .STRINGZ    "2^16"

; ansi board labels
      ANSI_BOARD_LABELS_0     .STRINGZ             "    "
      ANSI_BOARD_LABELS_1     .STRINGZ       "\e[37m 2  \e[0m"
      ANSI_BOARD_LABELS_2     .STRINGZ     "\e[1;37m 4  \e[0m"
      ANSI_BOARD_LABELS_3     .STRINGZ       "\e[31m 8  \e[0m"
      ANSI_BOARD_LABELS_4     .STRINGZ       "\e[31m 16 \e[0m"
      ANSI_BOARD_LABELS_5     .STRINGZ     "\e[1;31m 32 \e[0m"
      ANSI_BOARD_LABELS_6     .STRINGZ     "\e[1;31m 64 \e[0m"
      ANSI_BOARD_LABELS_7     .STRINGZ       "\e[33m128 \e[0m"
      ANSI_BOARD_LABELS_8     .STRINGZ       "\e[33m256 \e[0m"
      ANSI_BOARD_LABELS_9     .STRINGZ       "\e[33m512 \e[0m"
      ANSI_BOARD_LABELS_10    .STRINGZ     "\e[1;33m1024\e[0m"
      ANSI_BOARD_LABELS_11    .STRINGZ     "\e[1;33m2048\e[0m"
      ANSI_BOARD_LABELS_12    .STRINGZ     "\e[1;33m4096\e[0m"
      ANSI_BOARD_LABELS_13    .STRINGZ    "\e[37;40m8192\e[0m"
      ANSI_BOARD_LABELS_14    .STRINGZ    "\e[37;40m2^14\e[0m"
      ANSI_BOARD_LABELS_15    .STRINGZ    "\e[37;40m2^15\e[0m"
      ANSI_BOARD_LABELS_16    .STRINGZ    "\e[37;40m2^16\e[0m"

.END
