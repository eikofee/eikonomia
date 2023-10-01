# Eikonomia
*pun between "eiko" and "enkanomiya" which is also the name used by enka.network fetching genshin in-game data.*

This is a piece of software aiming at:
1. Fetching equipment regularly of my characters using enka.network and saving them into a local database
2. Providing this parsed data locally and continuously with API and stuff to be read using (my) Excel spreadsheet
3. Computing additional data easily notably regarding the quality of the artifacts which is currently not that intuitive and a bit wonky on my spreadsheet.
4. Entertaining me with the Julia language, and allowing me to play a bit with Docker.

## Dependencies
- Docker

## Installation

Pre-built Docker image is available on DockerHub : https://hub.docker.com/repository/docker/eikofee/eikonomiya/general

First run 
```
docker build -t eikonomiya .
```
then
```
docker run -ite GENSHIN_UID=<uid> -p 8080:<port> eikonomiya
```
where `<uid>` is your UID in-game (usually bottom right of the screen) and `<port>` is the local port to send GET requests to (8080 by default).

After that, ensure that your in-game namecard has characters in it, and that `Show Character Details` is turned on (on the bottom right of the namecard UI).

Then wait a bit and your character data should be accessible from Enka network.
You can try to access this data from this container in your web browser using `localhost:<port>/refresh` followed by `localhost:<port>/chars`. See below for more information on available paths.

## API
Current routes are temporary. When whitespaces are necessary, use `+` instead (e.g. `name=Hu Tao` -> `name=Hu+Tao`)
- `/ping` greets with a hello world
- `/char?name=<charName>` gives data about character `charName`
- `/chars` gives data about all saved characters
- `/refresh` queries data from enka network and overwrite existing characters information
- ~~`/clear` erases all saved data~~
- `/ratingRule?name=<charName>&[statName]=[value]` registers a new artefact rating rule for character `charName`, where multiple `statName` weigh a specific value in the rating (see below)
- `/rate[?name=<charName>]` computes the rating of character `charName`, or every character if unspecified. Be sure to register rating rules beforehand, characters without rules will be skipped.
- `/rule?name=<charName>` gives the rule saved for character `charName`.
- `/rules` lists all saved rules.



## Artefact rating rule
It's actually simple.
First, you gives a weigh to each rollable substat (by default 0) according to which stat is good or not for a character.

Then, a *potential* is computed based on the substat rolls you got on your artefact. For example, suppose you have a Crit Rate% of 10.5%. A Crit Rate% roll can go up to 3.9%, so the potential of this substat is 10.5/3.9=~2.69.

Each potential is then being multiplied by the weigh you chose previously, so potentials are now weighted by their importance for the character and useless substats are not being considered.
The final rating is the sum of theses weighted potential divided by the maximum potential you could have on this artefact.

The maximum potential is the sum of the four highest weight values you could have on this artefact (if the higher stat is already on the main stat, then we take the next higher one). The highest weight from these four is then multiplied by 6, to emulate the fact you could have rolled on this substat at +4,+8,+12,+16 and +20, every time for the best value possible.

The result of this division can be read as a percentage.