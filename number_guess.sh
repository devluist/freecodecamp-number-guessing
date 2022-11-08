#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( RANDOM % 1000 ))
NUMBER_GUESSES=1


############################################

echo "Enter your username:"
read USR

USERNAME=$($PSQL "SELECT username FROM game WHERE username = '$USR'")


#############################################

# if user is not in database
if [[ -z $USERNAME ]]; then
    USERNAME=$USR
    RESPONSE=$($PSQL "INSERT INTO game (username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
    BEST_GAME=0

    echo "Welcome, $USERNAME! It looks like this is your first time here."

else
    # if user IS in database
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM game WHERE username = '$USERNAME'")
    BEST_GAME=$($PSQL "SELECT best_game FROM game WHERE username = '$USERNAME'")

    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.";
fi


#############################################
MENU () {
    FN_GUESS
}

echo "Guess the secret number between 1 and 1000:"
read GUESS

FN_TRY_AGAIN () {
    echo $1
    read GUESS
    FN_GUESS
}

FN_GUESS () {
    if [[ $GUESS =~ ^[0-9]+$ ]]; then
        while [[ $GUESS -ne $SECRET_NUMBER ]]; do

            if [[ $GUESS =~ ^[0-9]+$ ]]; then 
                if [ $GUESS -lt $SECRET_NUMBER ]; then
                    echo "It's higher than that, guess again:"
                else
                    echo "It's lower than that, guess again:"
                fi

                read GUESS
                NUMBER_GUESSES=$(( NUMBER_GUESSES + 1 ))
            else
                FN_TRY_AGAIN "That is not an integer, guess again:"
            fi
        done
    else
        FN_TRY_AGAIN "That is not an integer, guess again:"
    fi
}

FN_GUESS
GAMES_PLAYED=$(( GAMES_PLAYED + 1 ));


#############################################

RESPONSE=$($PSQL "UPDATE game SET games_played = '$GAMES_PLAYED' WHERE username = '$USERNAME'");

# if number of guesses is lower than prevous matches, then save it
if [[ $NUMBER_GUESSES -le $BEST_GAME ]]; then
    RESPONSE=$($PSQL "UPDATE game SET best_game = '$NUMBER_GUESSES' WHERE username = '$USERNAME'");

else
    # if this is the first game, I need to catch it with this equality to zero
    if [[ $BEST_GAME -eq 0 ]]; then
        RESPONSE=$($PSQL "UPDATE game SET best_game = '$NUMBER_GUESSES' WHERE username = '$USERNAME'")
    fi
fi

echo "You guessed it in $NUMBER_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!";
