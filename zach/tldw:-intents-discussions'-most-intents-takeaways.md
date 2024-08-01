---
title: TL;DW: Intents Discussions' Most Intents Takeaways
category: community
co_authors: zach
publish_date: 
image: media/image6.jpg
imageAlt: 
imageCaption: 
excerpt: Missed Intents Discussions but don’t have seven hours to watch all the videos? We’ve got you covered with the best takeaways from the very intents day of panels on protocols, distributed systems, cryptography, and applications related to intents.
---
<
*Missed Intents Discussions but don’t have seven hours to watch [all the videos](https://www.youtube.com/playlist?list=PL0JhdaMOBhSR0IkrXNx0XaHMjU34VO-2L)? We’ve got you covered with the best takeaways from the very intents day of panels on protocols, distributed systems, cryptography, and applications related to intents.*

Intents Discussions was an event held before EthCC 2024 in Brussels, bringing together founders, builders, researchers, and decentralization maximalists in discussions on the state of architectures, protocols, ecosystems, and the role intents will play.

<figure>
  <img src="media/image9.png" />
  <figcaption></figcaption>
</figure>

Things kicked off with an [introduction by Anoma cofounder Awa Sun Yin](https://www.youtube.com/watch?v=MLuPpHlyJ0g), who provided insight into the ultimate [vision of Anoma](https://anoma.net/vision-paper.pdf) from her perspective. Why do we need Anoma, she asked? To help move our economic infrastructures from ‘Game A’ (the current imbalanced, PvP, intermediated, fragile macro-economic system) to ‘Game B’, characterized by:

- More balanced alternatives to existing systems
- Turning PvP games into cooperative games
- Multidimensional coordination mechanisms
- Generalized infrastructure to solve collective action problems e.g. multipolar traps
- More alternatives to services and products from paperclip-maximizing corps
- Intermediaries are an option, not a requirement
- Infrastructure that scales for billions without trading off sovereignty and interoperability

She explained, “We realized that the technologies we’re building with decentralized protocols actually have the capabilities to replace or at least provide a really viable alternative to existing systems that have this imbalance between people and the system.”

<figure>
  <img src="media/image5.png" />
  <figcaption></figcaption>
</figure>

# P2P layers, intent gossip networks, and the edge of distributed systems

The day of panels got underway with a [discussion of P2P layers](https://www.youtube.com/watch?v=awN_cDu_Qbk), featuring [Sam Hart](https://x.com/hxrts) ([Skip](https://x.com/skipprotocol)/[Timewave](https://x.com/timewavelabs)), [Wondertan](https://x.com/true_wondertan) ([Celestia](https://x.com/CelestiaOrg)), [Marius Poke](https://x.com/marius_poke) ([Informal Systems](https://x.com/informalinc)) and [Tobias Heindel](https://x.com/graphomath) ([Heliax](https://heliax.dev/)). The main question of the hour? What makes a good P2P network vs a bad one. 

## What makes a good P2P network? Minimalism, efficiency, and resilience. 

For Wondertan, a good P2P layer should be minimal, and shouldn’t try to solve all the problems for you. It should be just a set of primitives/tooling that makes the minimal assumptions possible, and that you can develop more protocol specific things on top of. It should provide simple gossiping primitives that can be built upon and optimized for your use case. He referenced Anoma’s heterogeneous P2P design as a good example, with multiple domains and subdomains that can help each other in the event of an attack. Marius emphasized efficiency and the ability to protect against attacks, pointing out that users shouldn’t need to understand what’s happening underneath. 

What makes a bad P2P layer? The Inability to deal with flooding attacks, for one. Though solutions to this problem, if only partial, do exist: for example the introduction of randomness and the approach Anoma is taking with the heterogeneity of several domains. Tobias explained that this system of heterogeneous P2P domains means they can work together to form a stronger network – in the event of a flooding attack, one of the domains can alert the rest of the network and help mitigate the attack. 

Ultimately, Tobias emphasized, the question of what makes a good P2P network doesn’t make sense, because you have to have a very clear vision of  exactly what the P2P network is for. TWondertan reiterated this point: you can’t make a single P2P system that’s good for everything (using IPFS as an example).

## A network of networks

This brings us back to the idea, Sam said, of a network of networks, which is what Anoma is. In Anoma, Tobias points out, actors can participate in P2P in one of several domains depending on which specific role they’re playing (validator, intent gossiping, solving, counterparty discovery etc). Other solutions include having a single network with multiple mempool lanes, which is being done in CometBFT, Marius mentioned. 

<figure>
  <img src="media/image11.png" />
  <figcaption></figcaption>
</figure>

## Incentive design and altruism 
So what about incentives? Gossip is expensive, and people are paying for blockspace but not P2P. How do you determine incentives, and who’s going to pay for it? 

Marius explained that to do it in a decentralized way, you need to reach consensus on the state of your graph, figure out metrics of resource consumption, and use that to decide incentives. 

Tobias chimed in with a spicy take: the P2P layer should be a public good. It should be a public service like healthcare, offered by the community to anyone using it wisely. This could be a centralizing force, so it’s merely an ideal to strive for. 

So people should be altruistic and do a good job for free? Tobias mentioned the Chaos Computer Club in Germany as an example of communities providing free access to computers and the internet, as well as TLS certificates, where people volunteer to make your connection to the internet secure. 

Of course the whole notion of blockchains is that people act in rational economic self interest, and people are always trying to abuse the network. It’s not just the tragedy of the commons, there are malicious actors. So how do we protect against this? According to Wondertan: every node should have their own subjective way of measuring trust, like how humans do it in the real world. You can track metrics in P2P software and come up with a scoring system.

For Tobias, validators should be required to run p2p as part of the service they provide and potentially even be slashed if they don’t. In terms of design, in Anoma’s P2P and intent gossip system, the hierarchy of hierarchies goes down to every individual as a leaf in the binary trie. This atomicity reiterates the idea, as Sam said quoting Tobias, that “P2P networks are by the people, for the people.”

# Anoma’s founding story
The first ‘[campside chat](https://www.youtube.com/watch?v=PDFd0niOGZU)’ of the day was a discussion between [Erica Kang](https://x.com/ekang426) ([KrypoSeoul](https://x.com/kryptoseoul)) and Anoma cofounder [Adrian Brink](https://x.com/adrianbrink) on the founding story of Anoma. 

The inspiration for Anoma came from the state of the space in 2020, when progress was stalled and most projects were just making slightly different versions of the EVM. The realization was that users don’t have transactions, but intents, and Christopher Goes had been working on intents already with Wyvern Protocol, the intent matching system later adopted by projects like OpenSea. The original whitepaper followed in 2020. 

> *“As a founder, if you’re building something like this, you have to do a lot more leg work to explain it to people. When we started talking about intents in 2020 everybody was like, ‘what are intents?’ Fundamentally as a founder you have the choice, do you build within existing paradigms? You’re not going to push the space forward much but it’s much easier to explain to people. Or do you try to tackle the really hard problems that have a lot of upside if you solve them?”*

<figure>
  <img src="media/image4.png" />
  <figcaption></figcaption>
</figure>

Diving into Anoma’s information flow control, Adrian pointed out: 

> *“As nations and communities, we need to start caring about where our data leaks to, because data is one of the most valuable assets that you have. Over time, especially in a multipolar world order, this data can be easily abused. This is why information flow control is really going to matter long term….Right now we're still living in this happy world where mostly our data is used for good things, but I think that's going to change, and we want to have technology that's ready.”*

Adrian also gave some insight into Anoma’s roadmap, with the goal of having an Anoma testnet this year.

# The limits of cryptography and how they relate to intents
For the next panel, [Wei Dai](https://x.com/_weidai) ([1kx](https://x.com/1kxnetwork)), [Shumo Chu](https://x.com/shumochu) ([Nebra](https://x.com/nebrazkp)), [C-Node](https://x.com/colludingnode) ([Celestia](https://x.com/CelestiaOrg)), [Federico Carrone](https://x.com/fede_intern) ([Aligned Layer](https://x.com/alignedlayer)), [Louis Guthman](https://x.com/GuthL) ([Starkware](https://x.com/StarkWareltd)), and [Yulia Khalniyazova](https://x.com/vveiln) ([Heliax](https://heliax.dev/)) [dove into the limits of cryptography](https://youtu.be/_JqG69rdusg).

What are those limits? First and foremost: the slow speed and high cost of zk proving, including latency issues in multichain scenarios, which make adoption an economic disadvantage for many, particularly in the face of MEV timing games. Of course, progress is being made and promising areas of research do exist, particularly in getting closer to real time proving. 

Louis referenced recent breakthroughs by Starkware in developing a prover that is 100x faster than the company’s previous generation technology and 10-20x faster than anything available on the market. The theoretical limit and holy grail of proving, he explained, is being able to do proving within the time necessary for producing a single block, which would unlock the maximum potential for this technology. Another solution mentioned was the ability to spread computation over multiple chains working in parallel (sharding/multithreading).

<figure>
  <img src="media/image7.png" />
  <figcaption></figcaption>
</figure>

Panelists also discussed the limitations, trade-offs, and applicability of the various cryptographic technologies: zero-knowledge (ZK), multi-party computation (MPC), fully homomorphic encryption (FHE), and trusted execution environments (TEEs). While some preferred one over the other, domain-specificity and multi-pronged approaches were also emphasized as necessary given that the research and application of these technologies to blockchain protocols is still early and ongoing.

Yulia and others also provided a look into how Anoma uses cryptography, particularly for information flow control (IFC), in intent matching and settlement. At the P2P level, IFC enables intents to be matched without sharing the specifics of what each user wants, important not only for privacy but for making sure malicious actors can’t base their decisions around the content of intents. It also means solvers can subscribe to the specific types of intents they want to work with. On the settlement side, cryptography used in Taiga, an implementation of the Anoma Resource Machine (ARM), provides intent-level composability with predicates that provide guarantees that intents are satisfied.

# Intent-centric applications
So how do we bring intents to the application level? The [next panel](https://www.youtube.com/watch?v=RnHZVGPMc7Y) dove into existing and potential applications that benefit from intents with [Rob Sorrow](https://x.com/rsarrow) ([Volt](https://x.com/voltcapital)), [Zaki Manian](https://x.com/zmanian) ([Sommelier](https://x.com/sommfinance)), [Praneeth Srikanti](https://x.com/bees_neeth) ([Ethereal](https://x.com/etherealvc)), [Amin B](https://x.com/AminB_CH) ([SwissDAO](https://x.com/swissDAO)), and [Mike Ruzic](https://x.com/thespacecatjr) ([Heliax](https://heliax.dev/)).

<figure>
  <img src="media/image2.png" />
  <figcaption></figcaption>
</figure>

There was broad consensus that intents and intent-centric architectures have much to offer the application space, particularly when it comes to usability and the defragmentation of intent liquidity that exists with the current landscape of application-specific intents. Intents were discussed as a solution to several practical problems in protocol design, not the least being the centralizing tendencies of current solutions for matching intents. 

Zaki mentioned an example from the early days of Sommelier where users wanting to withdraw had to send a message on Discord, and strategists would then have to make decisions about where to pull liquidity from. Sommelier ended up building their own bespoke intent-matching framework, but Zaki stressed that the need to bootstrap your own intent infrastructure isn’t a long term solution for the space: for one, it’s incredibly difficult, and secondly it may invite unnecessary regulatory risk. 
What’s needed is a more general, distributed intent-centric infrastructure like what Anoma aims to deliver.

What are some unique applications for intents? A common theme on this question is the potential of matchmaking in general. Amin mentioned an app built for EthBerlin that enabled users to express preferences for being automatically matched with certain types of people rather than needing to scroll or swipe through attendees like on a dating app. Zaki recalled the internet of the 90s, highlighting the opportunity to get back to a more unified global marketplace: 

> *“Think about what the internet was like in the 90s. When the internet was a lot smaller, Craigslist was just a bulletin board to matchmake between all sorts of different weird preference functions…. Ebay in the 90s was this crazy place where you could buy anything. I think there’s a wanting to get back to this universal marketplace rather than a bunch of siloed, segmented marketplaces that only do 1 thing.”*

Rob reiterated this, pointing out the potential of building around human desires and preferences, being able to form communities around those desires and preferences, and having a global marketplace for matching between them. Praneeth also pointed out the importance of connecting domains that can’t be accurately represented by each other, e.g. the problem of oracles, and getting representations of commitments in 1 domain that get reflected in another domain. 

An important benefit of intent-centric architectures, according to Zaki, is the ability to have several UIs, each with their own preference functions, that can feed into the same solving system, something that can remove the fragmentation that currently exists between applications dealing with similar or complementary intents. As an example, he mentioned needing to run through 6 different travel apps that morning to find one that could get him to his destination. “What you would want is, yes there can be many apps and some of them specialize in letting you express different preferences, but there could be just 1 app that drivers use and pull all the order flow that matches for them.”

Praneeth stressed the danger of building a new system that merely carries over existing market structures from the real world vs creating new ones. 

The session closed with a recognition that building intent-centric apps will go through an initial ‘glass eating phase’ before the ecosystem of tooling and documentation matures enough to be welcoming to developers from outside the web3 ecosystem, but that this stage is a necessary step toward making sure we build things that are actually useful.

# Globalists vs sovereignists
Next, [Illia Polosukhin](https://x.com/ilblackdragon) ([NEAR](https://x.com/NEARProtocol)), [Ethan Buchman](https://x.com/buchmanster) ([Cosmos](https://x.com/cosmos)), Adrian Brink (Anoma), [Emmanuel Awosika](https://x.com/eawosikaa) (2077 Collective) dove into the importance of and interplay between globalism and sovereignty or localism, comparing the concepts both in terms of real world governance systems and blockchain/protocol architectures. 

<figure>
  <img src="media/image8.png" />
  <figcaption></figcaption>
</figure>

Some panelists had a slight tendency to favor one over the other, but there was also consensus that global solutions are useful for some things and local solutions for others. As Ethan explained:

> *“There’s a bit of a false dichotomy here. It’s a question of scale. You have different scales at which you need different kinds of political structures. It’s more about the scale at which sovereignty can be expected to be expressed…. It’s not so much globalists vs sovereignty, it’s how do we build systems that bridge these scales from local to global and back? The world is both global and local, it’s not one or the other. You actually need both and you need them for different kinds of conditions.”*

The key question then is what sorts of things should be organized globally vs locally? 

## Governance & identity
For governance, Adrian favors skewing as local as possible, using the Swiss system as an example of good local involvement and accessibility of decision making, contrasting that with the dangers of a one world government that alienates individuals from the governance process. “The further you get away from the individual, the more abstractions you have in the middle, the harder it is for individuals to understand them and the less trust individuals place in these systems,” he explained. Similarly, he argued against global identity, emphasizing that “identity is fundamentally local because it depends on what your local trust graph is.”

## Global standards
The benefits of globalism were mainly discussed in terms of globally recognized protocols and standards that can be adopted and adapted at the local level. 

Ethan emphasized that global standards can actually help the expression of local sovereignty and can be useful from a human rights perspective, because they can enable individuals to exit from corrupt local systems. He used the example of money in the medieval period: local kings all had their own local coinage, but since those coins contained precious metals that conformed to a global standard of value, there was an exit opportunity in the sense that people could trade or melt down those coins for use in other jurisdictions.

Adrian emphasized the important distinction between global standards and global security models: 

> *”We should agree on standards and architectures globally. It’s very convenient that the phone I bought in Switzerland works in the US and China. But it’s not because we have a single global security model, it’s because we agree on the same cellular backbone protocol.*

> *When people think ‘global security model,’ they always think of a thing you can interact with. I agree that globally we should agree on protocols, but generally this doesn’t mean there’s a single global chain or a single global consensus, it just means we have a single global protocol definition. Like TCP/IP: we all agree that this protocol exists and we all implement it in different languages, but there’s not a single global server that we must route our packets through… A single server and many servers running the same consensus are still a single server.”*

## Markets
What about markets? Illia asked. While local marketplaces are good, you have issues with price discovery and fragmented liquidity. So, you do also want a global marketplace as part of the protocol: a set of globally agreed primitives that everyone can customize, but still get full global interoperability and the ability to exit any particular local domain. 

Adrian brought it back to the design decisions of Anoma, which meet many of these desirable conditions: the ability to have local sovereignty while maintaining interoperability with the global system, the ability for applications to roam between different local and global security models, and the ability to remove the fragmentation of liquidity/state that exists in the current siloed blockchain landscape.

# The Solver Games
Next, [Apriori](https://x.com/apriori0x) ([Heliax](https://heliax.dev/)) dove into intent solving with [Markus Schmitt](https://x.com/_haikane_) ([PropellerHeads](https://x.com/PropellerSwap)), [Nathan Worsley](https://x.com/NathanWorsley_), [0xTaker](https://x.com/0xTaker) ([Aori](https://x.com/aori_io) https://x.com/aori_io), [Katia Banina ](https://x.com/katiabanina)([Bebop](https://x.com/bebop_dex)), [Vishwa Naik](https://x.com/hrojantorse) ([Anera Labs](https://x.com/intheanera)).

## Defining solvers
The panel kicked off with an attempt to define precisely what a solver is, with Apriori suggesting a definition from the recent [*An Analysis of Intents-based Markets*](https://arxiv.org/abs/2403.02525): ”Solvers are agents who compete to satisfy user orders which may include complicated user specified conditions.” 


Nathan suggested another: “Self interested actors who are financially incentivized and rewarded for their participation in optimization markets” and “someone who’s paid to take risk”. For Markus, the concept of competition isn’t necessary, suggesting that solvers are merely a mechanism you trust to outsource an optimization to. Vishwa countered by saying that, in his view, for solvers to exist in a marketplace it should be competitive; with markets as a mechanism designed around selfish actors. Nathan emphasized the ‘selfish actor’ part, since selfishness is one of the most reliable forces, while Katia pointed out the importance of solvers providing added value to the user.

## Are solvers and MEV searchers the same thing?
For Nathan, yes essentially. Markus countered by saying that, in the short term maybe yes these roles are basically the same, but long term as solver teams attempt to scale, this approach has a limited runway. “The worst code is written by searchers”, which is actually incentivized because otherwise you’re not working fast enough, he explained. Longer term, this breaks down, particularly in solving for multiple chains, where the difficulty of integrating multichain infrastructure kicks in. Long term then, there’s more overlap with infrastructure than with searching. 

For Vishwa, solving “flips the polarity that we’ve seen with MEV searchers: historically it's PvP, me against the user. Here it flips that polarity and I become a worker for the user.”

<figure>
  <img src="media/image10.png" />
  <figcaption></figcaption>
</figure>

## What makes a good solver? 
For Nathan, you need a passion for execution over impact: you’re not exactly changing the world but you play an important role in a highly competitive environment. The ability to continually optimize, increasing efficiency and profit, was also emphasized. 

Vishwa reiterated the growing importance of infrastructure, pointing out that what makes a good solver has evolved over time and is continuing to evolve, from aggregation to optimization to infrastructure. You need to work on all of these to be competitive, he explained, and infrastructure is more and more central. 

## Specialization vs centralization
A key theme discussed was the importance of specialization and the efficiency of separating different solver roles rather than consolidating them, as has happened with the current consolidation of capital and searching. Katia emphasized that markets trend toward greater sophistication. Different solvers may have a different vision, some are more like searchers, others are more like infrastructure providers, so the label of solver is too generic at the moment. 

Ultimately, panelists agreed on the importance of commodifying the market making function for evolving the space toward greater efficiency and value for the user. For Nathan, market makers are “the last people with power that we have to kill in the supply chain.” Markus argued that we shouldn’t kill them but rather incentivize them to do their actual job: internalizing true market signal into the price. Currently, he explained, their main job is arbitrage between exchanges, but they should be doing things like running predictive models, reading signals and interpreting them into the price. Nathan pushed back saying he doesn’t like the idea of turning market makers into oracles, given the hard problem of bringing information on chain this would give them an additional edge over the simple capital edge that they have today. 

Reiterating the importance of specialization and commoditization of roles, Markus wrapped up a discussion of the future of solving by saying that we shouldn’t have too many cross-chain solver roles. Cross-chain solving, he explained, involves too many functions vertically integrated into a single role. Instead the emphasis should be on composability. Indeed this is how things mostly work today: there are few truly cross-chain solvers, with one solver typically working on the bridge and another on the designation chain. Commoditizing each individual step in this way brings more efficiency into the market. 

# Campside chat with Vitalik Buterin, Christopher Goes, & Mike Ippolito
The headline chat for the day featured [Anoma cofounder Christopher Goes in conversation with Vitalik Buterin, moderated by Blockworks’s Mike Ippolito](https://youtu.be/uUwVal5gmbA). They covered a lot of ground, from lessons learned as protocol designers to the relationship between L1s, applications, and end users, and how that relates to the evolution of protocols. 

<figure>
  <img src="media/image3.png" />
  <figcaption></figcaption>
</figure>

Vitalik ran through his thought process, lessons learned, and design decisions when building Ethereum, which he summed up as attempting to avoid the mistakes of Bitcoin. Among the learnings and surprises, he admitted, was that “NFTs were a big surprise, I totally did not expect NFTs at all.”

Chris discussed Moxy Marlinspike’s talk “[The ecosystem is moving](https://www.youtube.com/watch?v=DdM-XTRyC9c)” in reference to his realization that “we have a need to iterate on the protocols fast enough that they can actually compete with Web2”, pointing out the difficulties of keeping up with Web2 via decentralized governance and social consensus processes. 

Vitalik countered this by pointing to the successes of Ethereum in conducting upgrades across an increasing number of client teams, doing a much better job than many expected. He sees decentralization in this context as a benefit rather than a hindrance: having 5 parallel teams gives you a larger pool of expertise that ends up helping you – something he learned gradually over time.

Chris agreed on this point, pointing to the benefit of having a diversity of perspectives, ideas, and org structures, referencing the Ethereum merge as the most complex distributed system upgrade ever, a major feat for decentralized governance. Pointing to the benefits of diversity, he shared his thoughts on the role Anoma can play for the Ethereum ecosystem:

> *”With Anoma, part of what we should do to be valuable to the ecosystem is to be different from Ethereum. The world has an Ethereum, we don't need another. We need something not only different but complementary in specific ways. We view part of our role as providing a different angle to the research discourse that can eventually meld, be complementary and become synthesized, but that starts from a different position, and in starting from a different position it can articulate a different perspective. Through synthesizing these we can come to a common understanding that bridges the gap between the theory of the Layer 1 and the theory of the user.”*

But the pace of development isn’t only affected by decentralization, he claimed. The coupling of protocol development with the launch of financial assets means you want to move slowly to avoid any issues. There’s something to be said for spending time to properly design a protocol before you launch it. The quest to launch token liquidity, where projects launch quickly without having thought through all the design problems, can make it much more difficult to make changes later given there’s a live token on the market. 

Beyond that, there’s the question of organizational and capital structures. Free market competition between protocols is valuable because it helps promote innovation, but there’s a disadvantage compared to centralized, vertically integrated corporations like Microsoft that can deliver products that users want because they are not, internally, coordinated like free markets. Chris suggests exploring alternative capital structures, somewhere in between the two extremes, to alleviate this. For Vitalik on the other hand, it’s completely possible to have different companies, within which the more conventional style of innovation can flourish, whose incentives are aligned with the ecosystem.

Another of the many topics discussed was the concept of unbundling, with Chris favoring unbundling things as much as possible at the protocol level to avoid artificially constraining the market, even if those things end up being coupled in practice. Unbundling, he explained, opens up many different directions for capital structures. 

He also stressed the need to explore different token models: “One reason that assets are so competitive with each other is that they are viewed typically as alternatives: that you sell A to get B or B to get A. But there’s nothing inherent to the identity of assets that forces them to be alternatives.”

To close the conversation, Mike asked the pair to share their thoughts on what will have made the space successful looking back in the future. For Vitalik, success is if we get to the point where Ethereum represents a credible alternative to the mainstream, at least on the level of impact as Linux, with at least a handful of useful applications. If it’s tribalism, dwindling idealism and monkey pictures forever without any lasting, valuable applications, on the other hand, he’ll consider that a failure. 

For Christopher, success will be if we can balance the need for both autonomy and interoperability. Currently communities and individuals need to trade their autonomy to get interoperability with the wider global system. If countries want to interoperate, they need to use SWIFT, if individuals want to interoperate, they need to use a bank. “Crypto can provide standardized protocols that allow communities to very cleanly delineate the parts they want to depend on others for and the parts they want to run themselves.” 

Beyond that: “In 15 years I would like to be completely irrelevant. Blockchain technology should be boring. It should be like a database conference; who here would go to a database conference?”

<figure>
  <img src="media/image1.png" />
  <figcaption></figcaption>
</figure>

With that call to make events like this obsolete, the day of intents discussions came to an end, but guests continued to hang around the venue for several hours and chat, network, and enjoy the campside atmosphere, complete with a large tent and marshmallow roasting over an open fire. 

Panelists covered a lot of ground, providing a clear snapshot of the state of the space and what’s to come for the world of intents, protocols, applications, and beyond. We’re grateful for all the participants who joined and helped make this one of the most memorable and impactful events of EthCC week 2024. Until next time, keep up the intents-ity. 


>