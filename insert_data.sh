#!/bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Function to insert a team and return its id
INSERT_TEAM() {
  TEAM_NAME=$1
  TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$TEAM_NAME'")
  if [[ -z $TEAM_ID ]]; then
    INSERT_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$TEAM_NAME') RETURNING team_id")
    TEAM_ID=$(echo $INSERT_RESULT | awk '{print $1}')
  fi
  echo $TEAM_ID
}

# Truncate tables to start fresh
$PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY;"

# Load data from CSV file and insert into the database
cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  if [[ $YEAR != "year" ]]; then
    WINNER_ID=$(INSERT_TEAM "$WINNER")
    OPPONENT_ID=$(INSERT_TEAM "$OPPONENT")
    INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS)")
    if [[ $INSERT_GAME_RESULT == "INSERT 0 1" ]]; then
      echo "Inserted into games, $YEAR $ROUND: $WINNER vs $OPPONENT"
    fi
  fi
done
