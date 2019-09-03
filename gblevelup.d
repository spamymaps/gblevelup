import std.algorithm;
import std.string;
import std.array;
import std.conv;

// |level|common|rare|epic|bux|xp|xptonextlevel|
enum xpData = `|1|1|1|1|5|4|8|
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
|42|2500|500|56|180000|2500|4100|`;

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
    int level;
    int skins;
    int xp;
}



// is there a powerup added at the given level
bool powerupAtLevel(int level)
{
    return (level - 1) % 4 == 0;
}

void main(string[] args)
{
    auto maxlevel = args[1].to!int;
    import std.stdio;
    // first, fix the level up xp numbers, we want cumulative xp
    foreach(i; 1 .. levels.length)
        levels[i].nextLevelxp += levels[i-1].nextLevelxp;

    int[state] memo;
    state start;
    start.level = 1;
    start.powerups[0] = 3;
    memo[start] = 0;
    auto maxxp = levels[$-1].nextLevelxp;
    void update(ref state s, int bux)
    {
        if(auto v = s in memo)
        {
            *v = min(*v, bux);
        }
        else
        {
            memo[s] = bux;
        }
    }
    foreach(xp; 0 .. maxxp)
    {
        auto curKeys = memo.keys;
        foreach(k; curKeys)
        {
            if(k.xp == xp)
            {
                auto baseBux = memo[k];
                auto ld = levels[k.level - 1];
                void addxp(ref state s, int xp)
                {
                    s.xp += xp;
                    if(s.xp >= ld.nextLevelxp)
                    {
                        ++s.level;
                        if(powerupAtLevel(s.level))
                        {
                            // new level 1 powerup added
                            ++s.powerups[0];
                        }
                    }
                }
                memo.remove(k);
                if(k.level > maxlevel)
                    return;
                if(k.level == maxlevel)
                    writefln("%s => %s", k, baseBux);
                // try adding a new hat/skin
                auto ns = k;
                ++ns.skins;
                addxp(ns, ld.xp);
                update(ns, baseBux + ld.bux);

                // try upgrading any powerups
                foreach(pl; 0 .. k.powerups.length - 1)
                {
                    if(k.powerups[pl])
                    {
                        // try upgrading this one
                        auto pu = k;
                        --pu.powerups[pl];
                        ++pu.powerups[pl+1];
                        addxp(pu, powerups[pl].xp);
                        update(pu, baseBux + powerups[pl].bux);
                    }
                }
            }
        }
    }

    foreach(k, v; memo)
        writefln("%s => %s", k, v);
}
