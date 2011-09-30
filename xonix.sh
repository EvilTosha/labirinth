#!/bin/bash -i
# XONIX
# Matvej Kotov <matvej.kotov@gmail.com>, 2011

declare -r LAND_CHAR="\e[0;37;47m_"
declare -r SEA_CHAR="\e[0;34;44mX"
declare -r OPPONENT_CHAR="\e[1;33;44mo"
declare -r PLAYER_CHAR="\e[1;31;47mO"
declare -r CUTTING_PLAYER_CHAR="\e[1;31;44mO"
declare -r TRACK_CHAR="\e[1;33;44m+"
declare -r BACKGROUND="\e[47m"
declare -r TOP_SCORES_BAR_CHAR="\e[0;32;42m_"

declare -r -i MAP_X_POSITION=2
declare -r -i MAP_Y_POSITION=1
declare -r -i MAP_HEIGHT=$((LINES - 3))
declare -r -i MAP_WIDTH=$((COLUMNS - 4))
declare -r -i INIT_PLAYER_X=$((MAP_WIDTH / 2))
declare -r -i INIT_PLAYER_Y=0

declare -r -i INIT_COUNT_OPPONENTS=1
declare -r -i INIT_COUNT_LIVES=3
declare -i -r HINT_DELAY=100
declare -i -r DELAY=7
declare -r TIMEOUT="0.05"

declare -r KEY_HINT_MESSAGE="WSAD -- ???????????, X -- ?????"
declare -r CONTINUE_MESSAGE="N -- ?????? ????? ????, X -- ?????"
declare -r YOU_WON_MESSAGE="?? ????????! ??????? ???? ???:"
declare -r TOP_SCORES_MESSAGE_COLOR="\e[1;31;42m"
declare -r TOP_SCORES_COLOR="\e[1;32;42m"
declare -r TOP_SCORES_MESSAGE="?????? ??????????:"
declare -r LEVEL_MESSAGE="???????:"
declare -r SCORE_MESSAGE="????:"
declare -r LIVES_MESSAGE="?????:"
declare -r REMAIN_MESSAGE="????????:"
declare -r FOOTER_COLOR="\e[1;37;46m"
declare -r MESSAGE_COLOR="\e[1;31;47m"
declare -r EXIT_KEY='x'
declare -r NEW_GAME_KEY='n'
declare -r LEFT_KEY='a'
declare -r RIGHT_KEY='d'
declare -r UP_KEY='w'
declare -r DOWN_KEY='s'

declare -r -i LAND=0
declare -r -i SEA=1
declare -r -i TRACK=0
declare -r -i ANY=2
declare -r -i OPPONENT_AREA=2
declare -r -i MARK_0=3

declare -r STRUE=0
declare -r SFALSE=""

declare -i playerX
declare -i playerY
declare -i backPlayerX
declare -i backPlayerY
declare -i playerDX
declare -i playerDY

declare cutting=$SFALSE

declare -i countOpponents
declare -a opponents

declare -a map
declare -a tracks

declare -i score
declare -i level
declare -i countLives

declare -a topScores
declare -r TOP_SCORES_FILE_NAME='results.txt'
declare -i -r COUNT_TOP_SCORES=10
declare -i -r TOP_SCORES_WIDHT=30
function initOpponents() {
	local -i i=0
	local -i j
	while [[ i -ne countOpponents ]]; do
		opponents[4 * i    ]=$((RANDOM % (MAP_HEIGHT - 2) + 1)) # y
		opponents[4 * i + 1]=$((RANDOM % (MAP_WIDTH - 2)  + 1)) # x
		opponents[4 * i + 2]=$(((RANDOM % 2) * 2 - 1)) # dy
		opponents[4 * i + 3]=$(((RANDOM % 2) * 2 - 1)) # dx
		for ((j = 0; j < i; ++j)); do
			if [[ ${opponents[4 * i]} -eq ${opponents[4 * j]} && \
				${opponents[4 * i + 1]} -eq ${opponents[4 * j + 1]} ]]; then
				continue;
			fi
		done
		((++i))
	done
}

function drawString() {
	echo -ne "\e[$1;$2f$3"
}

function drawMapCell() {
	drawString $(($1 + MAP_Y_POSITION + 1)) $(($2 + MAP_X_POSITION + 1)) "$3"
}

function drawOpponent() {
	drawMapCell $1 $2 "$OPPONENT_CHAR"
}

function clearOpponent() {
	drawMapCell $1 $2 "$SEA_CHAR"
}

function drawPlayer() {
	if [[ $cutting ]]; then
		drawMapCell $playerY $playerX "$CUTTING_PLAYER_CHAR"
	else
		drawMapCell $playerY $playerX "$PLAYER_CHAR"
	fi
}

function clearPlayer() {
	if [[ $cutting ]]; then
		drawMapCell $playerY $playerX "$TRACK_CHAR"
	else
		drawMapCell $playerY $playerX "$LAND_CHAR"
	fi
}


function compare() {
	local -r -a pattern=($1)
	local -r -a x=($2)
	local -i i
	for ((i = 0; i < 8; ++i)); do
		if [[ ${pattern[i]} -ne ANY && ${pattern[i]} -ne ${x[i]} ]]; then
			return 1
		fi
	done
	return 0
}

rules=(
	# pattern dy dx
	"$ANY $SEA $SEA $ANY $SEA $ANY $ANY $ANY"  1  1
	"$ANY $LAND $ANY $ANY $SEA $ANY $SEA $SEA" -1  1
	"$SEA $SEA $ANY $SEA $LAND $ANY $ANY $ANY"  1 -1
	"$ANY $ANY $LAND $ANY $ANY $LAND $ANY $ANY"  0  0
	"$ANY $LAND $ANY $ANY $ANY $ANY $LAND $ANY"  0  0
	"$ANY $ANY $ANY $LAND $LAND $ANY $ANY $ANY"  0  0
	"$ANY $SEA $LAND $SEA $SEA $SEA $SEA $ANY" -1 -1
	"$ANY $LAND $LAND $SEA $LAND $SEA $SEA $ANY" -1 -1
	"$ANY $ANY $LAND $LAND $SEA $ANY $SEA $SEA" -1  1
	"$LAND $ANY $ANY $SEA $LAND $SEA $SEA $ANY" -1 -1
	"$ANY $LAND $ANY $SEA $LAND $SEA $SEA $ANY" -1 -1
	"$LAND $ANY $ANY $ANY $LAND $LAND $ANY $ANY"  0  0
	"$SEA $SEA $LAND $SEA $ANY $ANY $LAND $ANY"  1 -1
	"$ANY $LAND $ANY $ANY $LAND $LAND $ANY $ANY"  0  0
	"$LAND $ANY $LAND $ANY $ANY $ANY $LAND $ANY"  0  0
	"$ANY $ANY $LAND $LAND $ANY $ANY $LAND $ANY"  0  0
	"$LAND $ANY $ANY $ANY $LAND $ANY $LAND $ANY"  0  0
	"$ANY $LAND $ANY $LAND $ANY $ANY $ANY $LAND"  0  0
	"$ANY $LAND $ANY $SEA $ANY $SEA $SEA $LAND" -1 -1
	"$ANY $ANY $LAND $LAND $ANY $ANY $ANY $LAND"  0  0
	"$ANY $LAND $ANY $ANY $ANY $LAND $ANY $LAND"  0  0
)

declare -r -i COUNT_RULES=$((${#rules[*]} / 3))

function findRule() {
	local -r x=$1
	for ((i = 0; i < COUNT_RULES; ++i)); do
		if compare "${rules[i * 3]}" "$x"; then
			echo ${rules[i * 3 + 1]} ${rules[i * 3 + 2]}
			break
		fi
	done
}

function drawOpponents() {
	local -i i
	for ((i = 0; i < countOpponents; ++i)); do
		y=${opponents[4 * i]}
		x=${opponents[4 * i + 1]}
		drawOpponent $y $x
	done
}

function moveOpponents() {
	local -i i
	local -i y
	local -i x
	local -i dx
	local -i dy
	local -a cells
	local -a rule
	for ((i = 0; i < countOpponents; ++i)); do
		y=${opponents[4 * i]}
		dy=${opponents[4 * i + 2]}
		x=${opponents[4 * i + 1]}
		dx=${opponents[4 * i + 3]}
		clearOpponent $y $x
		cells[0]=${map[(y + dy) * MAP_WIDTH + x - dx]}
		cells[1]=${map[(y + dy) * MAP_WIDTH + x]}
		cells[2]=${map[(y + dy) * MAP_WIDTH + x + dx]}
		cells[3]=${map[y * MAP_WIDTH + x - dx]}
		cells[4]=${map[y * MAP_WIDTH + x + dx]}
		cells[5]=${map[(y - dy) * MAP_WIDTH + x - dx]}
		cells[6]=${map[(y - dy) * MAP_WIDTH + x]}
		cells[7]=${map[(y - dy) * MAP_WIDTH + x + dx]}
		rule=(`findRule "${cells[*]}"`)
		((dy *= rule[0]))
		((dx *= rule[1]))
		((y += dy))
		((x += dx))
 		opponents[4 * i]=$y
		opponents[4 * i + 2]=$dy
		opponents[4 * i + 1]=$x
		opponents[4 * i + 3]=$dx
		drawOpponent $y $x
	done
	if [[ $cutting ]]; then
		for ((i = 0; i < countOpponents; ++i)); do
			if [[ ${tracks[$((opponents[4 * i] * MAP_WIDTH + opponents[4 * i + 1]))]} ]]; then
				killPlayer
				break
			fi
		done
	fi
}

function initMap() {
	local -i i
	local -i j
	for ((i = 1; i < MAP_HEIGHT - 1; ++i)); do
		for ((j = 1; j < MAP_WIDTH - 1; ++j)); do
			map[i * MAP_WIDTH + j]=$SEA
			drawMapCell $i $j "$SEA_CHAR"
		done
	done
	for ((i = 0; i < MAP_HEIGHT; ++i)); do
		map[i * MAP_WIDTH]=$LAND
		map[i * MAP_WIDTH + MAP_WIDTH - 1]=$LAND
	done
	for ((j = 0; j < MAP_WIDTH; ++j)); do
		map[j]=$LAND
		map[(MAP_HEIGHT - 1) * MAP_WIDTH + j]=$LAND	
	done
}

function deleteFreeAreas() {
	local -a marks=()
	local -i mark=MARK_0
	local -i i
	local -i j
	local -i k
	local -i index
	local -i a
	local -i b
	local -i c	
	local -i d
	local -i e
	local -i m
	for ((i = 1; i < MAP_HEIGHT - 1; ++i)); do
		for ((j = 1; j < MAP_WIDTH - 1; ++j)); do
			index=$((i * MAP_WIDTH + j))
			if [[ ${tracks[index]} ]]; then
				map[index]=$LAND
			fi	
			a=${map[index]}
			b=${map[(i - 1) * MAP_WIDTH + j]}	
			c=${map[i * MAP_WIDTH + j - 1]}		
			if [[ a -eq SEA ]]; then
         			if [[ b -ne LAND && c -ne LAND ]]; then      
					if [[ ${marks[b]} -eq ${marks[c]} ]]; then
						map[index]=${marks[b]}
					else
						d=$(((b < c) ? b : c))
						e=$(((b < c) ? c : b))
						map[index]=${marks[d]}
						m=${marks[e]}
						for ((k = MARK_0; k < mark; ++k)); do
							if [[ ${marks[k]} -eq m ]]; then
								marks[k]=${marks[d]}
							fi
						done
					fi
				elif [[ b -eq LAND && c -eq LAND ]]; then
            				map[index]=$mark
					marks[mark]=$mark
					((++mark))
				elif [[ b -ne LAND && c -eq LAND ]]; then
					map[index]=${marks[b]}
				elif [[ b -eq LAND && c -ne LAND ]]; then
					map[index]=${marks[c]}
				fi
			fi
		done
	done
	for ((i = 0; i < countOpponents; ++i)); do
		m=${marks[${map[$(( ${opponents[4 * i]} * MAP_WIDTH + ${opponents[4 * i + 1]}))]}]}
		for ((j = 0; j < mark; ++j)); do
			if [[ ${marks[j]} -eq m ]]; then
				marks[j]=$OPPONENT_AREA
			fi
		done
	done
	local -i cell
	for ((i = 1; i < MAP_HEIGHT - 1; ++i)); do
		for ((j = 1; j < MAP_WIDTH - 1; ++j)); do
			index=$((i * MAP_WIDTH + j))
			cell=${map[index]}
			if [[ cell -eq LAND ]]; then
				if [[ ${tracks[index]} ]]; then
					drawMapCell $i $j "$LAND_CHAR"
				fi
			elif [[ ${marks[cell]} -eq OPPONENT_AREA ]]; then
				map[index]=$SEA
			else
				map[index]=$LAND
				drawMapCell $i $j "$LAND_CHAR"
			fi
		done
	done
}

function deletePath() {
	local -i i
	local -i j
	for ((i = 1; i < MAP_HEIGHT - 1; ++i)); do
		for ((j = 1; j < MAP_WIDTH - 1; ++j)); do
			index=$((i * MAP_WIDTH + j))
			if [[ ${tracks[index]} ]]; then
				drawMapCell $i $j "$SEA_CHAR"
			fi
		done
	done
}

function movePlayer() {
	local -r -i oldY=playerY
	local -r -i oldX=playerX
	local -r -i newY=$((playerY + playerDY))
	local -r -i newX=$((playerX + playerDX))
	clearPlayer
	if [[ newY -ge 0 && newY -le $((MAP_HEIGHT - 1)) ]]; then
		playerY=newY
	fi
	if [[ newX -ge 0 && newX -le $((MAP_WIDTH - 1)) ]]; then
		playerX=newX
	fi
	local index=$((playerY * MAP_WIDTH + playerX))
	if [[ $cutting ]]; then
		if [[ ${tracks[index]} ]]; then
			killPlayer
		elif [[ ${map[index]} -eq LAND ]]; then
			playerDY=0
			playerDX=0
			cutting=$SFALSE
			deleteFreeAreas
			calcRemainder
			drawFooter
		elif [[ ${map[index]} -eq SEA ]]; then
			tracks[index]=$TRACK
		fi
	else
		if [[ ${map[index]} -eq SEA ]]; then
			cutting=$STRUE
			tracks=()
			tracks[index]=$TRACK
			backPlayerY=oldY
			backPlayerX=oldX
		else
			playerDY=0
			playerDX=0
		fi
	fi
	drawPlayer
}

function killPlayer() {
	cutting=$SFALSE
	deletePath
	playerX=backPlayerX
	playerY=backPlayerY
	playerDY=0
	playerDX=0
	((--countLives))
	drawFooter
}

function drawFooter() {
	drawString $((LINES)) 1 "$FOOTER_COLOR\e[2K$LEVEL_MESSAGE $level\t$LIVES_MESSAGE $countLives\t\
$REMAIN_MESSAGE $remainder%\t$SCORE_MESSAGE $score"
}

function drawMessage() {
	drawString $((LINES - 1)) 2 "$MESSAGE_COLOR\e[2K$1"
}

function drawInput() {
	drawString $((LINES - 1)) 2 "$MESSAGE_COLOR\e[2K$1 "
	stty echo
	REPLY=""
	read
	stty -echo
}

function clearMessage() {
	drawString $((LINES - 1)) 1 "$BACKGROUND\e[2K"
}

function calcRemainder() {
	local -i i
	local -i j
	local -i count=0
	for ((i = 1; i < MAP_HEIGHT - 1; ++i)); do
		for ((j = 1; j < MAP_WIDTH - 1; ++j)); do
			if [[ ${map[i * MAP_WIDTH + j]} -eq SEA ]]; then
				((++count))
			fi
		done
	done
	local -i oldRemainder=remainder
	remainder=$(((count * 100) / ((MAP_WIDTH - 2) * (MAP_HEIGHT - 2))))
	((score += oldRemainder - remainder))
}


function initGame() {
	echo -e $BACKGROUND
	clear
	countOpponents=INIT_COUNT_OPPONENTS
	countLives=INIT_COUNT_LIVES
	level=1
	score=0
}

function readTopScores() {
	topScores=()
	if [[ -r "$TOP_SCORES_FILE_NAME" ]]; then
		readarray -t topScores < "$TOP_SCORES_FILE_NAME"
	fi
}

function writeTopScores() {
	(IFS=$'\n'; echo "${topScores[*]}" > "$TOP_SCORES_FILE_NAME")
}

function playerWon() {
	if [[ score -eq 0 ]]; then
		return 1
	fi
	if [[ ${#topScores[@]} -lt $((COUNT_TOP_SCORES * 2)) ]]; then
		return 0
	fi
	local -i i
	for ((i = 0; i < COUNT_TOP_SCORES; ++i)); do
		if [[ score -gt ${topScores[2 * i + 1]} ]]; then
			return 0
		fi
	done 
	return 1
}

function addPlayerToTopScores() {
	local -r name="$1"
	local -i i
	local -i pos
	for ((i = 0; i < COUNT_TOP_SCORES; ++i)); do
		if [[ score -gt ${topScores[2 * i + 1]} ]]; then
			break
		fi
	done
	pos=i
	for ((i = COUNT_TOP_SCORES - 1; i > pos; --i)); do
		topScores[2 * i]=${topScores[2 * i - 2]}
		topScores[2 * i + 1]=${topScores[2 * i - 1]}
	done
	topScores[2 * pos]="$name"
	topScores[2 * pos + 1]=$score
}

function drawTopScores() {
	local -i i
	local -i j
	for ((j = 0; j < COUNT_TOP_SCORES + 1; ++j)); do
		for ((i = 0; i < TOP_SCORES_WIDHT; ++i)); do
			drawString $((LINES / 2 - COUNT_TOP_SCORES / 2 + j)) \
				$((COLUMNS / 2 - TOP_SCORES_WIDHT / 2 + i)) \
				"$TOP_SCORES_BAR_CHAR"
		done
	done
	echo -ne $TOP_SCORES_MESSAGE_COLOR
	drawString $((LINES / 2 - COUNT_TOP_SCORES / 2)) \
		$((COLUMNS / 2 - ${#TOP_SCORES_MESSAGE} / 2)) \
		"$TOP_SCORES_MESSAGE"
	echo -ne $TOP_SCORES_COLOR
	for ((i = 0; i < COUNT_TOP_SCORES; ++i)); do
		drawString $((LINES / 2 - COUNT_TOP_SCORES / 2 + i + 1)) \
			$((COLUMNS / 2 - TOP_SCORES_WIDHT / 2 + 1)) \
			"${topScores[2 * i + 1]}"
		drawString $((LINES / 2 - COUNT_TOP_SCORES / 2 + i + 1)) \
			$((COLUMNS / 2 - TOP_SCORES_WIDHT / 2 + 9)) \
			"${topScores[2 * i]:0:TOP_SCORES_WIDHT - 10}"
	done
}

function finishGame() {
	readTopScores
	if playerWon; then
		drawInput "$YOU_WON_MESSAGE"
		clearMessage
		addPlayerToTopScores "$REPLY"
		writeTopScores
	fi
	drawTopScores
	drawMessage "$CONTINUE_MESSAGE"
	local -l key
	while true; do
		read -s -n 1 key
		case "$key" in
			$EXIT_KEY)	break 2;;
			$NEW_GAME_KEY)	break;;
		esac
	done
	clearMessage
}

function runGame() {
	while true; do
		initLevel
		runLevel
		if [[ countLives -eq 0 ]]; then
			break;
		fi
		finishLevel
	done
}

function initPlayer() {
	playerX=INIT_PLAYER_X
	playerY=INIT_PLAYER_Y
	playerDX=0
	playerDY=0
}

function initLevel() {
	initMap
	initPlayer
	initOpponents
	remainder=100
	drawPlayer
	drawOpponents
	drawFooter	
}

function finishLevel() {
	clearPlayer
	((++countLives))
	((++countOpponents))
	((++level))
}

function runLevel() {
	local -l key
	local -i time=0
	local -i timeHintShowed
	local -i newTime
	local hintIsShowed=$SFALSE
	while true; do
		key=""
		read -s -t $TIMEOUT -n 1 key
		newTime=$((`date +%s` * 100 + (10#`date +%N` / 10000000)))
		case "$key" in
			$UP_KEY)	playerDY=-1
					playerDX=0;;
			$DOWN_KEY)	playerDY=1
					playerDX=0;;
			$LEFT_KEY) 	playerDX=-1
					playerDY=0;;  
			$RIGHT_KEY)	playerDX=1
					playerDY=0;;
			$EXIT_KEY)	break 3;;
			"")		;;
			*)		drawMessage "$KEY_HINT_MESSAGE"
					timeHintShowed=newTime 
					hintIsShowed=$STRUE;;
		esac
		if [[ $((newTime - time)) -ge DELAY ]]; then
			movePlayer
			moveOpponents
			time=newTime
		fi
		if [[ $hintIsShowed ]] && [[ $((time - timeHintShowed)) -ge HINT_DELAY ]]; then
			clearMessage
			hintIsShowed=$SFALSE
		fi
		if [[ countLives -eq 0 ]]; then
			break 2
		fi
		if [[ remainder -le $((15 + 1 * countOpponents)) ]]; then
			break
		fi
	done
}

function initApplication() {
	stty -echo
}


function runApplication() {
	while true; do
		initGame
		runGame
		finishGame
	done
}

function finishApplication() {
	reset	
}

initApplication
runApplication
finishApplication
