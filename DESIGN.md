Pontifications
==============
There are a few parts to a MUD:

1. The service. This is what handles the nuts and bolts of the MUD -- telnet, GMCP, etc.
2. The mechanics. This is like "players control one character each; combat works like this; leveling up works like that."
3. The base content. This is what the dev team creates. It's things like "NPC Baobab is a sapient tree of level 27 and drops 2d4 buckets of livingwood sap when it dies." Or "Metropolis is an area comprised of the following rooms, with this weather pattern."
4. The game state. Things like "room Metropolis/DailyPlanet/lobby currently contains player naster.spem."

Now, when we create content, we have two desires that somewhat conflict:
* We want to be able to see our changes quickly.
* We want a good editor.

It's hard to make a good editor over telnet. It's hard to show changes quickly
when you're using a local text editor and a remote service.

So what would be nice is providing either a convenient way to run locally while
editing, or a non-telnet interface that's nicer for editing.

(Consuming content, relatively speaking, is easy.)

Interesting bits for the game state: some is durable and some isn't. For instance:
* Player metadata (credentials etc) is durable.
* Player character data (level, description, etc) is durable.
* NPC character data is usually not durable.
* Room data is usually not durable (but player housing is).
* Item data is only durable when it's attached to something durable.


Base content
============
We load base content from a series of coffeescript files. (I think. I'll try it.)

We also 

