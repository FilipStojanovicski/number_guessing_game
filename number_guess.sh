#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
echo "Enter your username:"
read USERNAME
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")

# Read user information
if [[ -z $USER_INFO ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  IFS="|" read GAMES_PLAYED BEST_GAME  <<< $USER_INFO
  GAMES_PLAYED=$(echo $GAMES_PLAYED | sed -r 's/^ *| *$//g')
  BEST_GAME=$(echo $BEST_GAME | sed -r 's/^ *| *$//g')
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo -e "Guess the secret number between 1 and 1000:"

# Generate secret number and initialize total guesses
SECRET_NUMBER=$(( 1 + $RANDOM % 1000 ))
NUMBER_OF_GUESSES=0

GUESS_NUMBER() {
  read NUMBER_GUESS
  if ! [[ "$NUMBER_GUESS" =~ ^[0-9]+$ ]]
  then
    echo -e "That is not an integer, guess again:"
    GUESS_NUMBER
  elif [[ $SECRET_NUMBER -eq $NUMBER_GUESS ]]
  then
    NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
    echo -e "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
  elif [[ $SECRET_NUMBER -lt  $NUMBER_GUESS ]]
  then 
    NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
    echo -e "It's lower than that, guess again:"
    GUESS_NUMBER
  elif [[ $SECRET_NUMBER -gt $NUMBER_GUESS ]]
  then
    NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
    echo -e "It's higher than that, guess again:"
    GUESS_NUMBER
  fi
}

GUESS_NUMBER

# If user does not exist create a new user
if [[ -z $USER_INFO ]]
then
  CREATE_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 1, $NUMBER_OF_GUESSES);")
else
  # If number of guesses is less than their best game, we replace it as their new best
  if [[ $NUMBER_OF_GUESSES -lt $BEST_GAME || -z $BEST_GAME ]]
  then
    BEST_GAME=$NUMBER_OF_GUESSES
  fi
  # Add one to the new number of games
  GAMES_PLAYED=$((GAMES_PLAYED + 1))

  UPDATE_USER=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE username='$USERNAME';")
fi

