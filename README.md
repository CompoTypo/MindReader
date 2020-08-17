# MIND READER GAME
The purpose of the game is to guess the number the player is thinking.  

[![Watch the video!](https://img.youtube.com/vi/cHizh3md76I/maxresdefault.jpg)](https://youtu.be/cHizh3md76I)

## DELIVERABLES
-User thinks of a number between 1 and 63  
-Afterwards, the first 4x8 card will be displayed showing random numbers from target range  
-6 rounds of cards will be displayed, at the end of each the user will be prompted to whether their number was present on said card  

## SOLUTION
Each card is represented as an array with space for all values in the given range.  
If a certain value exists in the card, the index equal to the value in the array is equal to 1, 0 otherwise (not in card).  
A seperate array acting as another boolean counter keeps track of all the rounds.  
If the user says the card presents their number, we check all present cooresponding indices and vice versa for number not present.  

## USAGE
I used the [MARS IDE ](https://courses.missouristate.edu/KenVollmar/MARS/) to write and execute this piece of code.  