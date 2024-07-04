---
title: Controller Tags and Cross-Chain Resources
category: distributed-systems
co_authors: 
publish_date: 
image: media/
imageAlt: 
imageCaption: 
excerpt: 
---
# Controller Tags and Cross-Chain Resources

Here we set out to _generalize_ the "wrapped tokens" from [IBC](https://github.com/cosmos/ibc/blob/8d9d3b6fe7309b034df8457760b3bbd11d24b8e1/archive/papers/2020-05/build/paper.pdf#L2) and [ICS20](https://github.com/cosmos/ibc/blob/main/spec/app/ics-020-fungible-token-transfer/README.md).
We create a sound and efficient way to safely transfer arbitrary mutable digital objects (not just tokens) between mutually distrusting chains, tracking precisely how "trustworthy" each object is, and what "promises" each chain has made. 
Our approach is based on [taint tracking](http://www.tcse.cn/~wsdou/papers/2022-dsn-dista.pdf) and _endorsement_ from [Information Flow Control](https://en.wikipedia.org/wiki/Information_flow_(information_theory)) research, with the added twist that modern blockchains can have the power to _review_ and _verify_ histories of other chains, using [recursive ZKPs](https://eprint.iacr.org/2021/370), [optimistic proofs](https://www.coindesk.com/tech/2024/03/19/optimism-finally-starts-testing-fault-proofs-at-heart-of-design-and-of-criticism/), or simply fully replicating the other chain's state machine.

TODO: actual ART-report link

The full details are in our [technical report](https://www.dropbox.com/scl/fi/84mxa8jb7muiar76twg16/art_controllers-9.pdf?rlkey=xcaj31k59riay7cvqwwi73s13&dl=0), but here we explain what properties we are trying to maintain, why we think these properties are important, and how they fit into the larger Anoma ecosystem, while touching only briefly on some of the machinery under the controller tag operations.



## Introduction
In [distributed systems](https://en.wikipedia.org/wiki/Distributed_computing), [mutable digital objects](https://en.wikipedia.org/wiki/Object_(computer_science)) typically require some [state machine](https://www.cs.cornell.edu/fbs/publications/SMSurvey.pdf) to decide on their definitive current state.
This [state machine can be replicated](https://en.wikipedia.org/wiki/State_machine_replication) to enhance availability and fault tolerance.
We call the authoritative state machine of a digital object its _controller_.

For example: bank accounts are mutable digital objects; their controller is the bank's database.
Tokens and NFTs are objects; their controller is a blockchain. 
Most of the files on most computers could be called mutable digital objects, and the controller of each is the computer it's stored on.

Without some kind of controller, different parties may have contradictory notions of what the state is, and no way to reconcile them.
In a distributed system, some controllers may be [Byzantine](https://en.wikipedia.org/wiki/Byzantine_fault), and make duplicitous or incoherent statements about state. 
In general, an object is only as _trustworthy_ as its controller: if Alice's bank account says she has lots of money, but Bob doesn't trust Alice's bank, then Alice's "money" doesn't mean much to Bob. 

In general, applications can only use objects on the same controller: ethereum transactions only use ethereum smart contracts and accounts, and so on.  
Unfortunately, when applications need to share a controller  to interact, there is an incentive to push all applications onto one controller trustworthy enough (and with enough throughput) for everyone. 
Attempts to create such a controller typically require trust in a single authority (e.g. [AWS](https://aws.amazon.com/appsync/)) or an extremely expensive global consensus (e.g., [Ethereum](https://github.com/ethereum/wiki/wiki/White-Paper)) and remain inadequate for some applications:
 JP Morgan does not trust Ethereum to control their accounts, [which is why they maintain their own generic application controller](https://www.jpmorgan.com/onyx/about).
In fact, it is unlikely that _all_ worthwhile applications will ever agree on a controller who can manage all of their state.
This is why interoperability is so important: the internet works not because we all trust some single authority to manage all of it but because many different applications in different trust domains can interact. 

Here we are concerned with cases where objects _transfer_ between controllers: we have to track controllers may have affected each object.
If there are any properties or invariants the object is supposed to maintain, there are the controllers that may have "messed up" the object. 
In the simplest case, we might imagine tagging each object with a set of _affecting controllers_.
In general, if an application (or a user) trusts all the affecting controllers in an object's tag, it can rely on that object.
A simple but effective set of rules would be:
- When an object is created, its affecting controllers set is whatever controller is authoritative for the object.
- When an object transfers to a new controller, we add the new controller to its affecting controllers.
- If an object updates its state based on the state of other objects (e.g. receiving a bank transfer from another account), we add the affecting controllers from all dependency objects to this object's affecting controllers. 
This solution is very similar to [taint tracking](http://www.tcse.cn/~wsdou/papers/2022-dsn-dista.pdf) or in Programming Language & Distributed Systems research: each object is "tainted" by its affecting controllers, and contributes that "taint" to everything that depends on it. 

The tricky part is in _removing_ controllers from objects' tags.
A common case in blockchain systems is to move an object from some chain (let's call it _base chain_) to some other chain (let's call it _L2_), do some stuff, and then move the object back to _base chain_. 
We then want _base chain_ to somehow "review" the changes made on _L2_, and somehow be able to treat the object like it was never on _L2_ at all.
We need to remove _L2_ from the object's tag.
In [Information Flow Control](https://en.wikipedia.org/wiki/Information_flow_(information_theory)) research, this is similar to _endorsement_, [a fairly well-explored problem](https://doi.org/10.1145/3133956.3134054).



<figure>
    <img src="media/wrapping-unwrapping.png" alt="wrapping and unwrapping a token as it's transferred across chains" />
  <figcaption>with [IBC](https://github.com/cosmos/ibc/blob/8d9d3b6fe7309b034df8457760b3bbd11d24b8e1/archive/papers/2020-05/build/paper.pdf#L2) and [ICS20](https://github.com/cosmos/ibc/blob/main/spec/app/ics-020-fungible-token-transfer/README.md), users can transfer tokens between chains, "destroying" the original, and creating "wrapped" tokens, which are "unwrapped" when they are transferred back. 
</figcaption>
</figure>
TODO: better IFC-style wrapping/unwrapping diagram

The blockchain setting, however, introduces a unique twist: instead of relying on _trust_ as the main basis for endorsement, modern blockchains can have the power to _review_ and _verify_ histories of other chains, using [recursive ZKPs](https://eprint.iacr.org/2021/370), [optimistic proofs](https://www.coindesk.com/tech/2024/03/19/optimism-finally-starts-testing-fault-proofs-at-heart-of-design-and-of-criticism/), or simply fully replicating the other chain's state machine.
This means that we can remove controllers from objects' tags not because of some trust relationship, but because the right controllers remaining in the tag have reviewed the relevant controllers, and promised not to endorse any contradictory forks. 

TODO: actual ART-report link

In our [technical report](https://www.dropbox.com/scl/fi/84mxa8jb7muiar76twg16/art_controllers-9.pdf?rlkey=xcaj31k59riay7cvqwwi73s13&dl=0), we define rules and procedures for creating, updating, transferring, and tracking the state of tagged objects, and prove that our rules maintain safety properties including _causal resource history_ and _consistent controller tags_.
In this blog post, we explain what properties we are trying to maintain, why we think these properties are important, and how they fit into the larger Anoma ecosystem. 
We will touch on some of the machinery under the controller tag operations, but leave most of those details to the [technical report](https://www.dropbox.com/scl/fi/84mxa8jb7muiar76twg16/art_controllers-9.pdf?rlkey=xcaj31k59riay7cvqwwi73s13&dl=0).

## System Model
### Resources

TODO: for the blog post, this section could be shorter somehow. 

The digital objects we use in Anoma are called [resources](https://zenodo.org/doi/10.5281/zenodo.10498990).
We can encode extremely general mutable state with resources, but resources themselves are fairly simple.
Resources have very limited mutable state: they are _not yet created_ by default, can transition to _created_, and then to _consumed_.
However, each resource can carry arbitrary immutable data, specified by the resource's unique ID (which can be a hash).
Each resource's _controller tag_ is part of this immutable data.

Resources transition between these states in transactions ordered by controllers.
Each resource's tag therefore specifies a single controller that can order transactions for each type of transition, ensuring there is a single authority in charge of deciding whether each transition has or has not occurred:
- The resource's _creating controller_ determines if the resource has been created.
- The resource's _terminal controller_ determines if the resource has been consumed.
Transactions which perform a state transition but are ordered by the wrong controller are _invalid_.

Each controller's state carries cryptographic accumulators (e.g. [Merkle roots](https://doi.org/10.1007/3-540-48184-2_32)) representing the set of resources created by transactions ordered by this controller and the set of resources consumed.
If a resource is neither created nor consumed, it is _not yet created_.
As part of their immutable data, resources can have complex proof obligations (which we call _resource logics_) determining when they can be created or consumed, and these may depend on the state of other resources.
A resource logic can for example, specify exactly what programs can consume this resource: it would require a proof that the resources created are precisely the outputs of running a particular program with the consumed resources as inputs.
Such a proof might be as simple as a full execution trace of the program, or as complex as a [zero-knowledge proof](https://eprint.iacr.org/2021/370).
Through these logics, resources can encode fairly arbitrary state, not limited to scalar registers or tokens, while still allowing [ZKP-style confidential transactions](https://zenodo.org/doi/10.5281/zenodo.10498990).

### Transactions
All state updates occur in [Transactions](https://en.wikipedia.org/wiki/Database_transaction): atomic updates that designate a set of _input_ resources (which must be previously _created_) that are _consumed_, and a set of _output_ resources (which must not yet have been created) which are _created_.
Transactions can only update state controlled by one controller, and must include checkable proofs that the relevant resource logics of each resource created or consumed are satisfied.
However, input resources may have been _created_ in a transaction on another controller.
Therefore, controllers can sync with one another, allowing transactions to check if resources on other controllers have been created.
These updates can be asynchronous, so it is possible a transaction will not immediately be able to prove that a resource has been created.


### Controllers
Controllers order transactions: each controller decides on an ever-growing sequence of transactions defining the execution _trace_, and thus the current state, of a state machine.
Controllers do not necessarily compute and store this state themselves, although it may be efficient to do so.
Committing to an ever-growing sequence of transactions, however, does require that controllers keep _some_ state, to ensure they do not _fork_: commit two contradictory traces (neither is a prefix of the other).
Forks are the essence of, for example, [double-spend attacks](https://dahliamalkhi.wordpress.com/wp-content/uploads/2016/08/blockchainbft-beatcs2017.pdf).
A controller which commits invalid transactions or forks can be called _unsafe_ or [Byzantine](https://en.wikipedia.org/wiki/Byzantine_fault).




