.section ".word"
   /* Game state memory locations */
  .equ CURR_STATE, 0x90001000       /* Current state of the game */
  .equ GSA_ID, 0x90001004           /* ID of the GSA holding the current state */
  .equ PAUSE, 0x90001008            /* Is the game paused or running */
  .equ SPEED, 0x9000100C            /* Current speed of the game */
  .equ CURR_STEP,  0x90001010       /* Current step of the game */
  .equ SEED, 0x90001014             /* Which seed was used to start the game */
  .equ GSA0, 0x90001018             /* Game State Array 0 starting address */
  .equ GSA1, 0x90001058             /* Game State Array 1 starting address */
  .equ CUSTOM_VAR_START, 0x90001200 /* Start of free range of addresses for custom vars */
  .equ CUSTOM_VAR_END, 0x90001300   /* End of free range of addresses for custom vars */
  .equ RANDOM, 0x40000000           /* Random number generator address */
  .equ LEDS, 0x50000000             /* LEDs address */
  .equ SEVEN_SEGS, 0x60000000       /* 7-segment display addresses */
  .equ BUTTONS, 0x70000004          /* Buttons address */

  /* States */
  .equ INIT, 0
  .equ RAND, 1
  .equ RUN, 2

  /* Colors (0bBGR) */
  .equ RED, 0x100
  .equ BLUE, 0x400

  /* Buttons */
  .equ JT, 0x10
  .equ JB, 0x8
  .equ JL, 0x4
  .equ JR, 0x2
  .equ JC, 0x1
  .equ BUTTON_2, 0x80
  .equ BUTTON_1, 0x20
  .equ BUTTON_0, 0x40

  /* LED selection */
  .equ ALL, 0xF

  /* Constants */
  .equ N_SEEDS, 4           /* Number of available seeds */
  .equ N_GSA_LINES, 10       /* Number of GSA lines */
  .equ N_GSA_COLUMNS, 12    /* Number of GSA columns */
  .equ MAX_SPEED, 10        /* Maximum speed */
  .equ MIN_SPEED, 1         /* Minimum speed */
  .equ PAUSED, 0x00         /* Game paused value */
  .equ RUNNING, 0x01        /* Game running value */

.section ".text.init"
  .globl main

main:
  li sp, CUSTOM_VAR_END /* Set stack pointer, grows downwards */ 
  addi sp, sp, -8
  sw s0, 0(sp)
  sw s1, 4(sp)

  main_loop: 
  
  call reset_game
  call get_input
  mv s1, a0
  li s0, 0
  
  done: 
    mv a0, s1
    call select_action
    mv a0, s1
    call update_state
    call update_gsa
    call mask
    call draw_gsa
    call decrement_step
    mv s0, a0
    call get_input
    mv s1, a0
  
  beqz s0 , done
  
  j main_loop

  lw s0, 0(sp)
  lw s1, 4(sp)
  addi sp, sp, 8

/* BEGIN:auxiliary */
/* Place all auxiliary procedures and additional constants 
   that may be used by other procedures in this section */

/* BEGIN:invert_GSA_ID */
invert_GSA_ID:
  la t0, GSA_ID
  lw t1, 0(t0)
  xori t1, t1, 1
  sw t1, 0(t0)
  ret
/* END:invert_GSA_ID */

/* BEGIN:get_cell */
get_cell: 
  addi sp, sp, -4
  sw ra, 0(sp)
  
  mv t0, a0
  mv a0, a1 
  call get_gsa 
  srl a0, a0, t0
  andi a0, a0, 1
  
  lw ra, 0(sp)
  addi sp, sp, 4
  ret
/* END:get_cell */

/* END:auxiliary */

/* BEGIN:clear_leds */
clear_leds: 
  addi sp, sp, -8
  sw s0, 0(sp)
  sw s1, 4(sp)

  la s1, LEDS
  li s0, 0x7FF
  sw s0, 0(s1)

  lw s1, 4(sp)
  lw s0, 0(sp)
  addi sp, sp, 8
  ret
/* END:clear_leds */

/* BEGIN:set_pixel */
set_pixel:

addi sp, sp, -8
sw s0, 0(sp)
sw s1, 4(sp)

la s1, LEDS

li s0, 0b100000001
slli s0, s0, 8
andi a0, a0, 0b1111
andi a1, a1, 0b1111
slli a1, a1, 4
or s0, s0, a1
or s0, s0, a0

sw s0, 0(s1)

lw s1, 4(sp)
lw s0, 0(sp)
addi sp, sp, 8
ret
/* END:set_pixel */

/* BEGIN:wait */
wait: 
  li t0, 1
  slli t0, t0, 11
  la t1, SPEED
  lw t1, 0(t1)

wait_loop:
  sub t0, t0, t1 
  bgtz t0, wait_loop 

  ret 
/* END:wait */

/* BEGIN:set_gsa */
set_gsa:
addi sp, sp, -8
sw s0, 0(sp)
sw s1, 4(sp)

la s0, GSA_ID 
lw s0, 0(s0) 
beqz s0, tab0

tab1: 
la s1, GSA1
slli s0, a1, 2
add s1, s1, s0
sw a0, 0(s1)
j set_gsa_end 

tab0: 
la s1, GSA0
slli s0, a1, 2
add s1, s1, s0
sw a0, 0(s1)

set_gsa_end: 
lw s0, 0(sp)
lw s1, 4(sp)
addi sp, sp, 8
ret 
/* END:set_gsa */

/* BEGIN:get_gsa */
get_gsa:

addi sp, sp, -8
sw s0, 0(sp)
sw s1, 4(sp)

la s0, GSA_ID 
lw s0, 0(s0) 
beqz s0, get_gsa_tab0

get_gsa_tab1: 
la s1, GSA1
slli s0, a0, 2
add s1, s1, s0
lw a0, 0(s1)
j get_gsa_end 

get_gsa_tab0: 
la s1, GSA0
slli s0, a0, 2
add s1, s1, s0
lw a0, 0(s1)

get_gsa_end: 
lw s0, 0(sp)
lw s1, 4(sp)
addi sp, sp, 8
ret 
/* END:get_gsa */

/* BEGIN:draw_gsa */
draw_gsa:

addi sp, sp, -16
sw s0, 0(sp)
sw s1, 4(sp)
sw s2, 8(sp)
sw ra, 12(sp)

li s2, N_GSA_LINES
la s0, LEDS

draw_rows: 
addi s2, s2, -1
mv a0, s2
call get_gsa
slli s1, s2, 4
ori s1, s1, 0xF
ori s1, s1, (1<<8)
slli a0, a0, 16
or a0, a0,s1
sw a0, 0(s0)
bgtz s2, draw_rows
  
draw_gsa_end:
lw s0, 0(sp)
lw s1, 4(sp)
lw s2, 8(sp)
lw ra, 12(sp)
addi sp, sp, 16
ret 
/* END:draw_gsa */

/* BEGIN:random_gsa */
random_gsa:  
  addi sp, sp, -16
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw ra, 12(sp)

  li a1, N_GSA_LINES
  la s1, RANDOM

random_rows: 
  addi a1, a1, -1
  li s0, N_GSA_COLUMNS
  li a0, 0
random_nbr: 
  addi s0, s0, -1 
  lw s2, 0(s1)
  andi s2, s2, 1 
  sll s2, s2, s0 
  or a0, a0, s2
  bgtz s0, random_nbr
  call set_gsa
  bgtz a1, random_rows

random_done: 
  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw ra, 12(sp)
  addi sp, sp, 16
  ret
/* END:random_gsa */

/* BEGIN:change_speed */
change_speed:
  addi sp, sp, -16
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw s3, 12(sp)

  la s0, SPEED
  li s1, MAX_SPEED
  li s2, MIN_SPEED
  lw s3, 0(s0)
  
  beqz a0, increment_speed

decrement_speed: 
  beq s3, s2, change_speed_done
  addi s3, s3, -1 
  sw s3, 0(s0)
  j change_speed_done

increment_speed: 
  beq s3, s1, change_speed_done
  addi s3, s3, 1 
  sw s3, 0(s0)

change_speed_done: 
  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw s3, 12(sp)
  addi sp, sp, 16
  ret 
/* END:change_speed */

/* BEGIN:pause_game */
pause_game:
  la t0, PAUSE
  lw t1, 0(t0)
  xori t1, t1, 1
  sw t1, 0(t0)
  ret
/* END:pause_game */

/* BEGIN:change_steps */
change_steps:  
  la t1, CURR_STEP
  lw t0, 0(t1)

cs_units: 
  beqz a0, cs_tens
  addi t0, t0, 1

cs_tens:
  beqz a1, cs_hundreds
  addi t0, t0, (1 << 4)

cs_hundreds:
  beqz a2, cs_done
  addi t0, t0, (1 << 8)

cs_done:
  sw t0, 0(t1)
  ret
/* END:change_steps */

/* BEGIN:set_seed */
set_seed:
  addi sp, sp, -12
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw ra, 8(sp)

  la s0, SEEDS
  slli a0, a0, 2
  add s0, s0, a0
  lw s0, 0(s0) 

  li a1, N_GSA_LINES

loop_rows_set_gsa: 
  addi a1, a1, -1
  mv s1, a1
  slli s1, s1, 2
  add s1, s1, s0
  lw a0, 0(s1)
  call set_gsa
  bgtz a1, loop_rows_set_gsa

set_seed_done: 
  lw s0, 0(sp)
  lw s1, 4(sp)
  lw ra, 8(sp)
  addi sp, sp, 12
  ret 
/* END:set_seed */

/* BEGIN:increment_seed */
increment_seed:
  addi sp, sp, -16
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw ra, 12(sp)

  la s0, SEED
  lw s1, 0(s0)
  li s2, N_SEEDS 
  
  blt s1, s2, increment_seed_init

increment_seed_rand: 
  call random_gsa
  j increment_seed_done

increment_seed_init: 
  addi s1, s1, 1
  sw s1, 0(s0)
  beq s1, s2, increment_seed_rand
  mv a0, s1
  call set_seed 

increment_seed_done:
  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw ra, 12(sp)
  addi sp, sp, 16
  ret 
/* END:increment_seed */

/* BEGIN:update_state */
update_state:
  addi sp, sp, -32
  sw ra, 0(sp)
  sw s0, 4(sp)
  sw s1, 8(sp)
  sw s2, 12(sp)
  sw s3, 16(sp)
  sw s4, 20(sp)
  sw s5, 24(sp)
  sw s6, 28(sp)

  la s0, CURR_STATE 
  lw s1, 0(s0)
  
  li s2, INIT
  li s3, RAND
  li s4, RUN

  beq s1, s2, update_state_init
  beq s1, s3, update_state_rand
  beq s1, s4, update_state_run

update_state_init:
  la s1, SEED
  lw s1, 0(s1)
  li s2, N_SEEDS
  beq s1, s2, from_init_to_rand 
  andi s3, a0, JR
  bnez s3, from_to_run
  j update_state_done

update_state_rand:
  andi s3, a0, JR
  bnez s3, from_to_run
  j update_state_done
  
update_state_run:
  andi s4, a0, JB
  bnez s4, from_run_to_init
  j update_state_done

from_init_to_rand: 
  sw s3, 0(s0)
  j update_state_done

from_to_run:
  sw s4, 0(s0)
  la s1, PAUSE
  li s0, 1
  sw s0, 0(s1)
  j update_state_done

from_run_to_init:
  sw s2, 0(s0)
  call reset_game

update_state_done:
  lw ra, 0(sp)
  lw s0, 4(sp)
  lw s1, 8(sp)
  lw s2, 12(sp)
  lw s3, 16(sp)
  lw s4, 20(sp)
  lw s5, 24(sp)
  lw s6, 28(sp)
  addi sp, sp, 32
  ret 
/* END:update_state */

/* BEGIN:select_action */
select_action:
  addi sp, sp, -28
  sw ra, 0(sp)
  sw a0, 4(sp)
  sw s0, 8(sp)
  sw s1, 12(sp)
  sw s2, 16(sp)
  sw s3, 20(sp)
  sw s4, 24(sp)

  la s0, CURR_STATE 
  lw s1, 0(s0)

  li s2, INIT
  li s3, RAND
  li s4, RUN

  beq s1, s2, select_action_init
  beq s1, s3, select_action_rand
  beq s1, s4, select_action_run

select_action_init:
  andi s3, a0, JC 
  beqz s3, sai_skip
  call increment_seed
  lw a0, 4(sp)
  sai_skip: 
  j buttons_steps
  
select_action_rand: 
  andi s2, a0, JC 
  beqz s2, sa_rand_skip_random 
  call random_gsa
  lw a0, 4(sp)
  sa_rand_skip_random: 
  j buttons_steps

buttons_steps: 
  andi a1, a0, BUTTON_1
  andi a2, a0, BUTTON_2
  andi a0, a0, BUTTON_0
  call change_steps
  j select_action_done

select_action_run:
  mv s2, a0
  
  andi s3, s2, JC
  beqz s3, sar_skip_pause
  call pause_game
  sar_skip_pause:
  
  andi s3, s2, JR 
  beqz s3, sar_skip_incspeed
  li a0, 0
  call change_speed
  sar_skip_incspeed:
  
  andi s3, s2, JL 
  beqz s3, sar_skip_decrspeed
  li a0, 1
  call change_speed
  sar_skip_decrspeed: 
  
  andi s3, s2, JB
  beqz s3, sar_skip_reset
  call reset_game
  sar_skip_reset:
  
  andi s3, s2, JT
  beqz s3, sa_run_skip_random
  call random_gsa
  sa_run_skip_random:
  j select_action_done

select_action_done:
  lw ra, 0(sp)
  lw a0, 4(sp)
  lw s0, 8(sp)
  lw s1, 12(sp)
  lw s2, 16(sp)
  lw s3, 20(sp)
  lw s4, 24(sp)
  addi sp, sp, 28
  ret
/* END:select_action */

/* BEGIN:cell_fate */
cell_fate:
  li t0, 2
  li t1, 3
  beqz a1, dead_currstate

alive_currstate: 
  blt a0, t0, dead_nextstate
  bgt a0, t1, dead_nextstate
  li a0, 1
  j cell_fate_done
  
dead_currstate: 
  beq a0, t1, alive_nextstate
  li a0, 0
  j cell_fate_done

alive_nextstate: 
  li a0, 1
  j cell_fate_done

dead_nextstate:
  li a0, 0

cell_fate_done:
  ret
/* END:cell_fate */

/* BEGIN:find_neighbours */
find_neighbours:
  addi sp, sp, -28
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw s3, 12(sp)
  sw s4, 16(sp)
  sw s5, 20(sp)
  sw ra, 24(sp)

  mv s0, a0 
  mv s1, a1 
  li s2, 0 
  li s4, -1 

find_neighbours_y:
  li s3, -1 
  li s5, N_GSA_LINES
  
  add a1, s1, s4
  bgez a1, y_skip_lowerbound
  addi a1, a1, N_GSA_LINES
  y_skip_lowerbound:
  blt a1, s5, y_skip_upperbound
  addi a1, a1, -N_GSA_LINES
  y_skip_upperbound:

find_neighbours_x:
  li s5, N_GSA_COLUMNS
  
  add a0, s0, s3
  bgez a0, x_skip_lowerbound
  addi a0, a0, N_GSA_COLUMNS
  x_skip_lowerbound:
  blt a0, s5, x_skip_upperbound
  addi a0, a0, -N_GSA_COLUMNS
  x_skip_upperbound:
  
  or s5, s3, s4
  beqz s5, skip_centercell
  call get_cell
  add s2, s2, a0
  skip_centercell:
  
  li s5, 1
  addi s3, s3, 1
  ble s3, s5, find_neighbours_x
  addi s4, s4, 1
  ble s4, s5, find_neighbours_y

  mv a0, s0
  mv a1, s1
  call get_cell
  mv a1, a0
  mv a0, s2

  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw s3, 12(sp)
  lw s4, 16(sp)
  lw s5, 20(sp)
  lw ra, 24(sp)
  addi sp, sp, 28
  ret
/* END:find_neighbours */

/* BEGIN:update_gsa */
update_gsa:
  addi sp, sp, -20  
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw s3, 12(sp)
  sw ra, 16(sp)

  la s0, PAUSE
  lw s0, 0(s0)
  beqz s0, update_gsa_done

  li s0, N_GSA_LINES
  li s1, N_GSA_COLUMNS 
  
  update_gsa_rows: 
    addi s0, s0, -1
    li s2, 0 
    li s3, 0
  
  update_gsa_colums:
    mv a0, s2
    mv a1, s0

    call find_neighbours
    call cell_fate 

    sll a0, a0, s2        
    or  s3, s3, a0 

    addi s2, s2, 1
  blt s2, s1, update_gsa_colums
    mv a1, s0
    mv a0, s3
    
    call invert_GSA_ID
    call set_gsa 
    call invert_GSA_ID

  bgtz s0, update_gsa_rows

  call invert_GSA_ID

update_gsa_done:
  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw s3, 12(sp)
  lw ra, 16(sp)
  addi sp, sp, 20
  ret
/* END:update_gsa */

/* BEGIN:get_input */
get_input:
  la t1, BUTTONS
  lw a0, 0(t1)
  sw zero, 0(t1)
  ret
/* END:get_input */

/* BEGIN:decrement_step */
decrement_step:
  addi sp, sp, -4
  sw s0, 0(sp)

  li  a0, 0                 

  la  t0, CURR_STATE
  lw  t0, 0(t0)
  li  t1, RUN

  la  t2, PAUSE
  lw  t2, 0(t2)            

  beqz t2, only_display_step
  beq  t0, t1, decrement_step_running
  j    only_display_step

decrement_step_running:
  la  t0, CURR_STEP
  lw  t1, 0(t0)
  beqz t1, step_is_zero     
  addi t1, t1, -1
  sw   t1, 0(t0)
  j    only_display_step

step_is_zero:
  li   a0, 1  
  lw s0, 0(sp)   
  addi sp, sp, 4            
  ret

only_display_step:
  la  t0, CURR_STEP
  lw  t0, 0(t0)             
  la  s0, font_data         
  li  t2, 12                
  li  t6, 24                
  la  t4, SEVEN_SEGS
  li  t5, 0                 

loop_currstep:
  mv   t3, t0
  srl  t3, t3, t2         
  andi t3, t3, 0xF
  slli t3, t3, 2            
  add  t1, s0, t3
  lw   t1, 0(t1)            
  sll  t1, t1, t6           
  or   t5, t5, t1
  addi t2, t2, -4
  addi t6, t6, -8
  bgez t2, loop_currstep

  sw   t5, 0(t4) 
  lw s0, 0(sp)   
  addi sp, sp, 4        
  ret

/* END:decrement_step */

/* BEGIN:reset_game */
reset_game:
  addi sp, sp, -16 
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw ra, 12(sp)


  la s0, CURR_STEP
  li s1, 1
  sw s1, 0(s0)
  la s0, font_data
  slli s1, s1, 2
  add s1, s0, s1
  lw s1, 0(s1)
  li s2, 0x3F3F3F00
  or s1, s1, s2
  la s0, SEVEN_SEGS
  sw s1, 0(s0)

  la s0, CURR_STATE
  li s1, INIT
  sw s1, 0(s0)

  la s0, SEED
  sw zero, 0(s0)

  la s0, GSA_ID
  sw zero, 0(s0)
  
  li a0, 0
  call set_seed
  call draw_gsa
  
  la s0, PAUSE
  sw zero, 0(s0)
  
  la s0, SPEED
  li s1, MIN_SPEED
  sw s1, 0(s0)

  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw ra, 12(sp)
  addi sp, sp, 16
  ret
/* END:reset_game */

/* BEGIN:mask */
mask:
  addi sp, sp, -32  
  sw s0, 0(sp)
  sw s1, 4(sp)
  sw s2, 8(sp)
  sw s3, 12(sp)
  sw s4, 16(sp)
  sw s5, 20(sp)
  sw s6, 24(sp)
  sw ra, 28(sp)

  la s0, SEED
  lw s0, 0(s0) 
  slli s0, s0, 2 
  
  la s1, MASKS 
  add s0, s0, s1
  lw s0, 0(s0) 
  la s1, LEDS
  li s2, N_GSA_LINES
  

loop_mask_rows:
  addi s2, s2, -1
  slli s3, s2, 2
  add s3, s3, s0 
  lw s3, 0(s3) 
  mv a0, s2
  call get_gsa
  and a0, a0, s3
  mv a1, s2
  call set_gsa 
  li t0, 0xFFF
  xor s3, s3, t0
  slli s3, s3, 16
  slli s4, s2, 4
  ori s4, s4, 0xF
  ori s4, s4, (1 << 10)
  or s3, s3, s4
  sw s3, 0(s1)
bgtz s2, loop_mask_rows

  lw s0, 0(sp)
  lw s1, 4(sp)
  lw s2, 8(sp)
  lw s3, 12(sp)
  lw s4, 16(sp)
  lw s5, 20(sp)
  lw s6, 24(sp)
  lw ra, 28(sp)
  addi sp, sp, 32
  ret
/* END:mask */

/* 7-segment display */
font_data:
  .word 0x3F
  .word 0x06
  .word 0x5B
  .word 0x4F
  .word 0x66
  .word 0x6D
  .word 0x7D
  .word 0x07
  .word 0x7F
  .word 0x6F
  .word 0x77
  .word 0x7C
  .word 0x39
  .word 0x5E
  .word 0x79
  .word 0x71

  seed0:
	.word 0xC00
	.word 0xC00
	.word 0x000
	.word 0x060
	.word 0x0A0
	.word 0x0C6
	.word 0x006
	.word 0x000
  .word 0x000
  .word 0x000

seed1:
	.word 0x000
	.word 0x000
	.word 0x05C
	.word 0x040
	.word 0x240
	.word 0x200
	.word 0x20E
	.word 0x000
  .word 0x000
  .word 0x000

seed2:
	.word 0x000
	.word 0x010
	.word 0x020
	.word 0x038
	.word 0x000
	.word 0x000
	.word 0x000
	.word 0x000
  .word 0x000
  .word 0x000

seed3:
	.word 0x000
	.word 0x000
	.word 0x090
	.word 0x008
	.word 0x088
	.word 0x078
	.word 0x000
	.word 0x000
  .word 0x000
  .word 0x000


# Predefined seeds
SEEDS:
  .word seed0
  .word seed1
  .word seed2
  .word seed3

mask0:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
  .word 0xFFF
  .word 0xFFF

mask1:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x1FF
	.word 0x1FF
	.word 0x1FF
  .word 0x1FF
  .word 0x1FF

mask2:
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
	.word 0x7FF
  .word 0x7FF
  .word 0x7FF

mask3:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
  .word 0x000
  .word 0x000

mask4:
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0xFFF
	.word 0x000
  .word 0x000
  .word 0x000

MASKS:
  .word mask0
  .word mask1
  .word mask2
  .word mask3
  .word mask4