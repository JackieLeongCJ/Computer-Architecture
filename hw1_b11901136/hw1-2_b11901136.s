.globl __start

.rodata
    msg0: .string "This is HW1-2: \n"
    msg1: .string "Enter offset: "
    msg2: .string "Plaintext:  "
    msg3: .string "Ciphertext: "
.text

################################################################################
  # print_char function
  # Usage: 
  #     1. Store the beginning address in x20
  #     2. Use "j print_char"
  #     The function will print the string stored from x20 
  #     When finish, the whole program with return value 0

print_char:
    addi a0, x0, 4
    la a1, msg3
    ecall
  
    add a1,x0,x20
    ecall

  # Ends the program with status code 0
    addi a0,x0,10
    ecall
    
################################################################################

__start:
  # Prints msg
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
    add a6, a0, x0
    
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall
    
    addi a0,x0,8
    li a1, 0x10150
    addi a2,x0,2047
    ecall
  # Load address of the input string into a0
    add a0,x0,a1


################################################################################ 
  # Write your main function here. 
  # a0 stores the begining Plaintext
  # x16 stores the offset
  # Do store beginning address 66048 (=0x10200) into x20 
  # ex. j print_char
init:
  li x20, 66048
  add x28, a0, x0  #x28 = a0 , stores the base address of array
  add x5, x0, x20  #cursor adress to ans array
  addi x8, x0, 48  #space count
  
whileloop:
  lb x29, 0(x28)    #x29 = char of x28
  addi x30, x0, 10  #x30 = 10 char: /n
  addi x31, x0, 32  #x31 = 32 char: ' '
  addi x9, x0, 122
  addi x15, x0, 97
  
  beq x29, x30, print_char
  beq x29, x31, space
  add x7, x29, x16  #shifted char in x7
  blt x9, x7, overflow1 #the char is more than z
  blt x7, x15, overflow2
  sb x7, 0(x5)
  addi x28, x28, 1
  addi x5, x5, 1
  beq x0, x0, whileloop
  
space:
  sb x8, 0(x5)
  addi x8, x8, 1
  addi x28, x28, 1
  addi x5, x5, 1
  beq x0, x0, whileloop
  
overflow1:
  addi x7, x7, -26
  sb x7, 0(x5)
  addi x28, x28, 1
  addi x5, x5, 1
  beq x0, x0, whileloop

overflow2:
  addi x7, x7, 26
  sb x7, 0(x5)
  addi x28, x28, 1
  addi x5, x5, 1
  beq x0, x0, whileloop
  
################################################################################

