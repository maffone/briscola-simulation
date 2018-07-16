# Briscola Simulation
Project repository for the course of Autonomous Systems, University of Bologna, A.Y. 2017/2018.
## Goal
This project aims to realize a software system in which four autonomous agents play a match of [_Briscola_](https://en.wikipedia.org/wiki/Briscola), one of the most popular card games in Italy.
## General Description
Each player is capable of reasoning on the cards in its hand to choose the best card to play. Players can also ask questions to their companion in order to cooperate to score the maximum amount of point at each turn, like in the real game. Each conversations is perceived by the opponents too, which can cooperate in turn. The card deck is managed by the dealer, an extra agent whose only purpose is to shuffle the deck at the beginning and distribute cards to the players throughout the match. The whole game is orchestrated by a referee, an extra agent which decrees the beginning of the match and tells the players when its their turn to play. The referee is also responsible for counting the point scored in every turn, assigning them to the right team and decreeing the winning team upon game end.
## Implementation
Players have been implemented as [_Jason_](http://jason.sourceforge.net/) agents and the whole match takes place through a [_TuCSoN_](http://apice.unibo.it/xwiki/bin/view/TuCSoN/WebHome) tuple centre, which reifies the game table: each card played on it, encoded by a tuple, is visible by all the players, along with the trump card. Conversations between players are stored in the tuple centre for the whole turn in which they were made, so that they can be perceived by everyone, opponents too. All the information that mustn't be available to all the agents is exchanged through _Jason_ messaged between the interested parties.
## How To Run
- First, [download](https://sourceforge.net/projects/jason/files/) the _Jason_ bundle and check all the settings through the configuration jar, modifying them accordingly to your preferences.
- Make sure to have the [Eclipse IDE](https://www.eclipse.org/) installed on your machine. Then, install the _Jason_ plugin: Help > Install new software... > Add... > type in the "Location"field
http://jason.sourceforge.net/eclipseplugin/juno/ > Click "Ok" and wait for the "jasonide" feature to appear, then tick the checkbox and step through the installation process.
- Clone this repository through the `git clone` command.
- Go to the root directory of the project and create a folder "libs". Download all the four jars in the release tab of this repository and place them inside the newly folder.
- In Eclipse, configure the project build path adding the fours jars as project dependencies.
- Open a shell in the "libs" directory and launch a _TuCSoN_ tuple centre, with default IP and port. ([How?](https://apice.unibo.it/xwiki/bin/view/TuCSoN/WebHome))
- In Eclipse, right click on the "briscolaSimulation.mas2j" file > Run Jason Application.
- Enjoy :)

Note: obviously you can download the jar files from elsewhere, except for the "t4jn.jar": we enhanced it in order to provide support for the _TuCSoN_ specification primitive `out_s`. Without it, the whole execution will be compromised.
