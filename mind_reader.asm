	.data
hello:		.asciiz "**Hello, would you like to play Mind Reader (y / N): "
hello2:		.asciiz "**Six cards will be displayed. After the last one, your number will be revealed**\n"
p:			.asciiz "**Then please think of a number between 1 and 63. Inclusively**\n"
p2:			.asciiz "Is your number on the card? (y / n): "
r:			.asciiz "Is the number you were thinking below?\n"
rp:			.asciiz "(y / n): "
clabel:		.asciiz "    CARD "
nl:			.asciiz "\n"
space:		.asciiz " "
cong:		.asciiz "Congratulations! You beat the machine or didnt read cards carefully enough\n\n"
uhoh:		.asciiz "Looks like i can read your mind! gotcha!\n\n"
err:		.asciiz "ERR, please insert y or n (case sensitive)\n\n"
range:		.word	63
cardlim:	.word	32
numcols:	.word	8
six:		.word	6
card: 		.space	256
opts: 		.space	256
buffer: 	.word	0

	.text
# MAIN
#####################################
main:
	jal promptUser				# jal to promptUser label

	li $s0, 0					# counter var
	lw $s1, cardlim				# 32 for each card
	lw $s2, numcols				# load in number of columns
	lw $s3, range				# 62 add one for the floor (1-63)
	li $s6, 0
	li $s7, 6

loop:
	addi $s4, $s4, 1			# loop counter, starts with 1
	jal nextCard				# run the card process
	lw $t0, six					# load break condition
	blt $s4, $t0, loop			# branch of loop hasnt gone 6 times
	
	li $s4, 0					# set counter
	jal pOpts					# debug list for indepth results
	li $s4, 0					# reset counter
	jal results					# link and jump to the result
	j exit						# never should execute but there just in case
######################################
# END main

# prompt user, init input
########################################
promptUser:
	li $v0, 4					# print a string
	la $a0, hello				# load in prompt
	syscall						# call it

	sw $zero, buffer			# make sure buffer is clear
	li $v0, 8					# read text
	la $a0, buffer				# load buffer for syscall result
	li $a1, 20					# unnecessarily large space for input
	syscall

	addi $t0, $zero, 110		# value for n
	addi $t7, $zero, 121		# value for y
	lb $t1, ($a0)				# grab first char of input to test
	beq $t1, $t0, exit			# if in is 0, exit program
	bne $t1, $t7, badInitInput  # check for bad input

	li $v0, 4					# print a string
	la $a0, p					# load a prompt
	syscall						# call it

	jr $ra						# return to main
###############################################
# END promptUser

# debug results
#############################################
inc:
	addi $s4, $s4, 1			# increment preceding loop
pOpts:
	beq $s4, $s3, breakout
	addi $t0, $s4, 1			# store index + 1
	li $v0, 1					# print int
	la $a0, ($t0)				# print index number + 1
	syscall						# call it

	li $v0, 4					# print a string
	la $a0, space				# load a space
	syscall						# call it

	li $t0, 4					# li 4
	addi $t2, $s4, 1			# store index + 1
	mul $t1, $t0, $t2			# multiply by for address

	lw $t0, opts($t1)			# load elimination value from address
	li $v0, 1					# print int
	la $a0, ($t0)				# print elim val 
	syscall						# call it

	li $v0, 4					# print string
	la $a0, nl					# print a newline
	syscall

	blt $s4, $s3, inc			# while still in range, loop

	jr $ra						# return to main
#############################################
# END debug results

# print the card
#################################################
printCard:
	bge $s0, $s1, breakout		# return if we count to 32

genRand:
	li $v0, 42					# service 42, random int
	lw $a1, range				# set range for random number
	syscall						# generate random int (returns in $a0)
	addi $a0, $a0, 1			# increment by one to be in the range

	addi $t2, $zero, 4			# load in byte mult for word
	mul $t1, $a0, $t2			# milt rand by word size

	lw $t0, card($t1)			# check if number is already on card
	bne $t0, $zero, genRand 	# if it is, get another random number

	addi $t0, $zero, 1			# else, make it 1
	sw $t0, card($t1)			# store it accordingly in the corresponding spot

	li $v0, 1					# print what number is stored in $a0
	syscall						# print it

	addi $s0, $s0, 1			# increment counter

	li $v0, 4					# print string
	la $a0, space				# print space
	syscall						# call it

	div $s0, $s2				# divide counter by 8
	mfhi $t0					# store remainder

	bne $t0, $zero, skipNL		# if remainer == 0, skip newline
	beq $s0, $zero, skipNL		# if counter == 0, skip newline

	li $v0, 4					# print string
	la $a0, nl					# load newline
	syscall						# call it

skipNL:
	j printCard					# loop until first branch condition is met
##########################################
# END card print

# Start card processing
##########################################
qArr:
	addi $t7, $s3, 1			# set the proper limit for this subroutine

rePromptProcessing:				# just in case of bad input
	li $v0, 4					# print a string
	la $a0, p2					# load in prompt
	syscall						# call it

	sw $zero, buffer			# clear buffer
	li $v0, 8					# read text
	la $a0, buffer				# load buffer in
	li $a1, 20					# unnecessarily large space for input
	syscall						# call it
	lb $t2, ($a0)				# grab first char of input to test
	addi $t0, $zero, 110		# value of n
	addi $t1, $zero, 121		# value of y
	beq $t2, $t0, subArr		# if guess IS NOT on card
	beq $t2, $t1, addArr		# if guess IS on card
	j badInputOnCard

subArr:							# eliminate all values present on card
	bgt $s0, $t7, breakout		# end of loop
	lw $t0, card($s6)			# load value by index from card array
	lw $t1, opts($s6)			# load value by index from card array

	beq $t0, $zero, skipSub		# if num from card (1), skip
	bne $t1, $zero, skipSub 	# if the value at this index is already eliminated, skip
	addi $t2, $zero, 1			# set bit
	sw $t2, opts($s6)			# store bit to eliminate the value of inex + 1

skipSub:
	sw $zero, card($s6)			# reset card array
	addi $s0, $s0, 1			# increment counter
	addi $s6, $s6, 4			# move index
	j subArr					# loop this for entire array

addArr:
	bgt $s0, $t7, breakout		# end of loop
	lw $t0, card($s6)			# load value by index from card array
	lw $t1, opts($s6)			# load value by index from card array

	bne $t0, $zero, skipAdd		# if it WAS NOT(0) in the card, skip
	bne $t1, $zero, skipAdd 	# if the value is still valid, skip
	addi $t2, $zero, 1			# set bit
	sw $t2, opts($s6)			# store bit to eliminate the value of inex + 1

skipAdd:
	sw $zero, card($s6)			# reset card array
	addi $s0, $s0, 1			# increment counter
	addi $s6, $s6, 4			# move index
	j addArr					# loop this for entire array

##########################################
# END card processing

# Setup to print card and subroutine calls to do so and process it
###########################################
nextCard:
	li $v0, 4					# print a string
	la $a0, clabel				# load in prompt
	syscall

	li $v0, 1					# print int
	la $a0, ($s4)				# load in card number
	syscall						# call it

	li $v0, 4					# print a string
	la $a0, nl					# load in a newline
	syscall

	move $s7, $ra				# save this return address to get back to main
	li $s6, 0					# (re)set index for arrays
	li $s0, 0					# (re)set number counter for each card
	jal printCard				# printcard subroutine
	li $s6, 0					# (re)set index for arrays
	li $s0, 0					# (re)set number counter for each card
	jal qArr					# process result subroutine

	jr $s7						# go back to main
##############################################
# END sign card process

# Result
############################################
results:
	li $v0, 4					# print string
	la $a0, r					# final prompt
	syscall						# call it
	j resLoop					# skip increment

incResLoop:
	addi $s4, $s4, 1			# increment preceding loop

resLoop:
	beq $s3, $s4, resLoopOver	# end loop condition

	li $t1, 4					# word size multiplier
	addi $t2, $s4, 1			# pre increment array index
	mul $t3, $t1, $t2			# find array position

	lw $t4, opts($t3)			# figure out if the value of that index is eliminated
	bne $t4, $zero, incResLoop 	# if it is, no point in not repeating the loop now
	
	li $v0, 1					# else, print that value
	la $a0, ($t2)					# load in saud value
	syscall						# call it

	li $v0, 4					# else, print that value
	la $a0, nl					# load a newline in
	syscall						# call it

	blt $s4, $s3, incResLoop 	# give that loop another iteration

resLoopOver:
	li $v0, 4					# otherwise, ask if the number thought of is displayed
	la $a0, rp	
	syscall						# call it

rePromptFinalRes:
	sw $zero, buffer			# clear buffer
	li $v0, 8					# read text
	la $a0, buffer				# use the buffer
	li $a1, 20					# unnecessary alotment for input
	syscall						# call it
	lb $t2, ($a0)				# grab that ascii char
	add $s4, $zero, $zero		# reset counter
	addi $t0, $zero, 110		# value for n
	addi $t1, $zero, 121		# value for y
	beq $t2, $t0, mindNotRead 	# if guess IS NOT in card
	beq $t2, $t1, mindRead  	# if guess IS in card
	j badFinalInput
	
###########################################
# END result

# Congratulate for beating machine
###########################################
mindNotRead:
	li $v0, 4					# print string
	la $a0, cong				# congratulate user for beating machine
	syscall						# call it
	jal clearOpts				# clear saved array in case of another attempt
	j main						# quick way to get to $ra from a branch
#########################################
# return back to main to start process over

# The machine knew
##########################################
mindRead:
	li $v0, 4					# print string
	la $a0, uhoh				# gloat to user
	syscall						# call it
	jal clearOpts				# clear saved array in case of another attempt
	j main						# quick way to get to $ra from a branch
#########################################
# return back to main to start process over

# Bad input handler for cards
##########################################
badInputOnCard:
	li $v0, 4					# print string
	la $a0, err					# err
	syscall						# call it

	j rePromptProcessing		# quick way to get to $ra from a branch
##########################################
# END bad card input handler

# Bad input handler for first prompt
##########################################
badInitInput:
	li $v0, 4					# print string
	la $a0, err					# err
	syscall						# call it

	j main						# quick way to get to $ra from a branch
##########################################
# END first input handler

# Bad input handler for final prompt
##########################################
badFinalInput:
	li $v0, 4					# print string
	la $a0, err					# err
	syscall						# call it

	j rePromptFinalRes			# quick way to get to $ra from a branch
##########################################
# END final input handler

# clear opts array
##########################################
optinc:
	addi $s4, $s4, 1			# increment preceding loop
clearOpts:
	beq $t7, $s4, main			# end loop condition
	addi $t0, $s4, 1			# increment value number

	li $t1, 4					# set up index
	mul $t0, $s4, 1				# clear it out

	sw $zero, opts($t3)			# reset value at index
	
	blt $s4, $s3, optinc		# repeat loop if no breakout
	jr $ra						# return in case both branches dont work
#############################################
# END cleaning process

# RETURN (for looping)
###########################################
breakout:
	li $v0, 4					# print newline
	la $a0, nl
	syscall						# call it

	jr $ra						# jum to return address
############################################
# END return 

# Syscall out of program
##############################################
exit:
	li $v0, 10					# exit program
	syscall
