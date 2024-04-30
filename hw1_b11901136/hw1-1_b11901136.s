.globl __start

.rodata
    msg0: .string "This is HW1-1: T(n) = 3T(n/4) + 10n + 3, T(1)=T(2)=T(3) = 3\n"
    msg1: .string "Enter a number: "
    msg2: .string "The result is: "

.text


__start:
  # Prints msg0
    addi a0, x0, 4
    la a1, msg0
    ecall

  # Prints msg1
    addi a0, x0, 4
    la a1, msg1
    ecall

  # Reads an int
    addi a0, x0, 5
    ecall

########################################################################################### 
  # Write your main function here. 
  # Input n is in a0. You should store the result T(n) into t0
  # HW1-1 T(n) = 3T(n/4) + 10n + 3, T(1)=T(2)=T(3) = 3, round down the result of division
  # ex. addi t0, a0, 1

callfunc:
  jal x1, recursion
  beq x0,x0, exit

recursion:
  addi sp, sp -8
  sw x1, 4(sp)
  sw a0, 0(sp)
  addi x6, a0, -4  #x6 = n -4
  bge x6, x0, B1
  addi sp, sp, 8
  addi t0, x0, 3
  jalr x0, 0(x1)
  
B1:
  srli a0, a0, 2  #a0 = n/4
  jal x1, recursion  #call T(n/4), result in t0
  
  lw a0, 0(sp)
  lw x1, 4(sp)
  addi sp, sp, 8
  
  addi x6, x0, 3
  mul x6, x6, t0   #x6 = t0 * 3
  addi x8, x0, 10 #x8 = 10
  mul x8, x8, a0  #x8 = 10 * n
  addi x8,x8, 3   #x8 = n * 10 + 3
  add t0, x6, x8   #result in t0
  jalr x0, 0(x1)

exit:

###########################################################################################

result:
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall

  # Prints the result in t0
    addi a0, x0, 1
    add a1, x0, t0
    ecall
    
  # Ends the program with status code 0
    addi a0, x0, 10
    ecall