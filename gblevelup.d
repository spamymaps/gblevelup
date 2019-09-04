import std.algorithm;
import std.string;
import std.array;
import std.conv;

// |level|common|rare|epic|bux|xp|xptonextlevel|
enum xpData = 
`|1|1|1|1|5|4|8|
|2|2|1|1|6|5|10|
|3|3|1|1|7|6|14|
|4|4|1|1|8|7|20|
|5|6|2|1|10|8|28|
|6|7|2|1|15|9|38|
|7|8|2|1|25|10|50|
|8|10|2|1|30|11|65|
|9|11|3|1|35|12|85|
|10|12|3|1|40|14|110|
|11|14|4|1|50|16|140|
|12|16|4|1|60|20|170|
|13|18|5|2|80|25|200|
|14|20|6|2|100|30|240|
|15|22|8|2|150|40|280|
|16|24|10|2|200|50|320|
|17|26|12|3|250|65|360|
|18|28|14|3|300|80|400|
|19|30|16|3|400|100|450|
|20|32|18|3|500|120|500|
|21|34|20|4|600|150|550|
|22|38|22|4|800|200|600|
|23|45|24|5|1000|250|650|
|24|56|26|6|1500|300|700|
|25|64|28|7|2000|350|750|
|26|72|30|8|3000|400|800|
|27|84|33|9|4000|450|920|
|28|100|36|10|5000|500|1100|
|29|128|40|12|6000|600|1300|
|30|160|50|14|8000|700|1500|
|31|190|60|16|10000|800|1700|
|32|220|70|18|12000|900|1900|
|33|256|80|20|15000|1000|2100|
|34|356|100|24|30000|1100|2300|
|35|500|120|28|45000|1200|2500|
|36|650|150|32|60000|1300|2700|
|37|800|200|36|80000|1500|2900|
|38|1000|250|40|100000|1700|3100|
|39|1300|300|44|120000|1900|3300|
|40|1600|350|48|140000|2100|3500|
|41|2000|400|52|160000|2300|3800|
|42|2500|500|56|180000|2500|4100|
|43|3000|600|60|200000|2700|4500|
|44|3500|700|64|220000|2900|5000|
|45|4000|800|68|240000|3100|6000|
|46|4500|900|72|260000|3300|7000|
|47|5000|1000|76|280000|3500|8000|
|48|5500|1100|80|300000|3700|10000|
|49|6000|1200|84|320000|3900|12000|`;

// |level|cards|bux|xp|
enum powerupData =
`|2|4|5|4|
|3|8|10|5|
|4|16|30|6|
|5|32|80|8|
|6|64|250|16|
|7|128|750|40|
|8|256|2300|100|
|9|512|8000|300|
|10|1000|30000|700|
|11|2000|80000|1500|
|12|4000|200000|3000|`;


T parseRecord(T)(string record)
{
    T result;
    auto r = record
        .splitter('|')
        .filter!(a => a.strip.length > 0)
        .map!(a => a.to!int);
    static foreach(i; 0 .. result.tupleof.length)
    {
        result.tupleof[i] = r.front; r.popFront;
    }
    return result;
}

struct LevelData
{
    int level;
    int common;
    int rare;
    int epic;
    int bux;
    int xp;
    int nextLevelxp;
}

struct PowerupData
{
    int level;
    int cards;
    int bux;
    int xp;
}

auto levels = xpData.splitter.map!(a => parseRecord!LevelData(a)).array;
auto powerups = powerupData.splitter.map!(a => parseRecord!PowerupData(a)).array;

struct state
{
    // how many powerups are at the given level
    int[12] powerups;
    int xp;
}

struct buxcards
{
    int bux;
    int cards;

    int opCmp(buxcards other) const
    {
        if(other.bux == bux)
        {
            if(other.cards == cards)
                return 0;
            return other.cards > cards ? -1 : 1;
        }
        return other.bux > bux ? -1 : 1;
    }
}

int buyPowerup(ref state s)
{
    foreach(i; 0 .. powerups.length)
    {
        if(s.powerups[i])
        {
            --s.powerups[i];
            ++s.powerups[i+1];
            s.xp += powerups[i].xp;
            return powerups[i].bux;
        }
    }
    return 0;
}

void main(string[] args)
{
    import std.stdio;
    auto maxlevel = args[1].to!int;
    if(maxlevel < 1 || maxlevel > 50)
        writeln("need level between 1 and 50");
    // first, fix the level up xp numbers, we want cumulative xp
    foreach(i; 1 .. levels.length)
        levels[i].nextLevelxp += levels[i-1].nextLevelxp;

    buxcards[state] memo1; // current level
    buxcards[state] memo2; // next level
    state start;
    start.powerups[0] = 3;
    memo1[start] = buxcards(0, 0);
    auto maxxp = levels[$-1].nextLevelxp;
    foreach(level ; 0 .. maxlevel-1)
    {
        auto ld = levels[level];
        // are we gaining a new powerup at this level
        auto newPowerup = ld.level > 1 && ld.level <= 37 && ((ld.level - 1) % 4 == 0);
        foreach(curstate, baseBux; memo1)
        {
            if(newPowerup)
                // new level 1 powerup
                ++curstate.powerups[0];

            // maxSkins is the maximum number of skins needed to level up to
            // the next level if all we did was buy skins.
            int maxSkins = ((ld.nextLevelxp - curstate.xp) + ld.xp - 1) / ld.xp;

skinloop:
            foreach(skins; 0 .. maxSkins + 1)
            {
                // buy this many skins
                auto newstate = curstate;
                newstate.xp += ld.xp * skins;
                auto newBuxCards = baseBux;
                newBuxCards.bux += skins * ld.bux;
                newBuxCards.cards += skins;
                while(newstate.xp < ld.nextLevelxp)
                {
                    auto b = buyPowerup(newstate);
                    if(b == 0)
                        // can't buy any more powerups, so this possibility isn't valid (this probably won't happen)
                        break skinloop;
                    newBuxCards.bux += b;
                }

                // get to the next level
                if(auto v = newstate in memo2)
                {
                    *v = min(*v, newBuxCards);
                }
                else
                    memo2[newstate] = newBuxCards;
            }
        }

        // clear memo1, and swap the two memos
        memo1.clear;
        swap(memo1, memo2);
    }
    // find cheapest result
    buxcards cheapest;
    cheapest.bux = int.max;
    foreach(k, v; memo1)
        cheapest = min(cheapest, v);

    foreach(k, v; memo1)
    {
        if(v == cheapest)
            writefln("%s => %s", k, v);
    }
}
