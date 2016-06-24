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
We load base content from a series of coffeescript files. By using coffeescript, we can implement procedural generation trivially.

The base content load can stash some data to generate consistent data.

(How do I get *consistent* procedural generation in the face of algorithmic changes? Option 1 is to store everything. Option 2 is to )






Generating thematically consistent things
=========================================
The basic way to generate a thematically consistent thing (NPCs in a faction, buildings in a city, etc) is:
* Generate a feature space. Normalize the length of each dimension.
* Pick a point in that feature space. That's your kernel, your archetype.
* Pick a maximum radius.
* When creating an individual component, you choose a random point in its feature space.

For some things, this works pretty well. Features that lend themselves to total orderings. For others, not so much. Like building material -- do you put brick and cinder block side by side? Brick and stone? Brick and something else? Do I treat building material as several dimenions so you can get more neighbors? But that forces everything to have more neighbors.

So I don't just take the generic feature-space version all the time. For some features, I choose several options with relative frequencies.

What about subnexuses within the space? Like I want to pick the lizard-people out, and then I want to pick out lizard-people nobility. I apply my main thing for the faction, then make a subfaction within that faction. I can make several such subfactions.

I can separate things into several feature spaces. For instance, I want several races. I procedurally generate them, using things like skin type (feathers, hair, etc), weight, size, number of limbs... Then I procedurally generate a nationality, and that includes race as a feature.
