# GolfBlitz Upgrade Path solver

This application will tell you how to upgrade your GolfBlitz account in the most efficient way possible. By efficient, I mean with the least bux. At this point in time, it returns a result that NOBODY will ever take. This is simply because even though you spend less bux, you miss the benefit of the leveled-up powerups along the way. Because powerups are the least efficient purchase (see below), it defers upgrading powerups until very late, which nobody will want to do.

To build, use the dub build tool, downloaded from [code.dlang.org](https://code.dlang.org).

Or you can simply download the binaries from the [releases](https://github.com/schveiguy/gblevelup/releases) based on your platform I built the tool on MacOS, Linux, and Windows.

BIG NOTE: This is a COMMAND LINE application, which is very boring, but easy to write. If you are a visual person and try to run this by double clicking on it, be prepared for a window to come up and go away, and nothing left for you to see. In order to run this properly, you need to run a terminal program (or command line tool on Windows), and run it from there.

## How it works

This uses dynamic programming to determine all possible paths to a given state. A state is defined by the amount of cumulative XP, and the number of powerups at each level. The Dynamic Programming algorithm eliminates paths that are suboptimal by progressing one level at a time, thereby eliminating duplicates early. Each level is stored into a hash table, since the realm of possibilities is pretty sparse.

With all upgrades possible, it could consume much more memory, but we are limiting powerup upgrades to always upgrading the lowest level powerup next. This turns out to actually be the most efficient bux-wise as well, since lower level powerup upgrades are always more efficient than higher level ones (that is, the bux/xp ratio is always higher for later upgrades).

The more levels you wish to upgrade through, the longer the code runs and the more memory it needs. This is due to the increasing number of paths that can reach that level. On my Macbook Pro, it takes 20 seconds to create the optimal path from level 1 to 50, and uses 1GB of memory.

## Options

By default, the program starts a brand new character at level 1 with no XP and no upgraded powerups, and it calculates the optimal path to level 50.

* `--min X`: The starting level for the analysis
* `--max X`: The finishing level for the analysis
* `--xp X`: The starting XP as displayed on your profile screen. The cumulative XP will be calculated based on your starting level and XP.
* `--powerups L1,L2,L3,...`: How many powerups at level 1, level 2, level3, etc. Later levels can be omitted. For example, if your character has 1 level 1 powerup, 2 level 2 powerups, and 1 level 5 powerup, you would write `--powerups 1,2,0,0,1`. Do not write any spaces.

Note that the bux spent to get to the target level do not take into account how many bux you spent before the initial state.
