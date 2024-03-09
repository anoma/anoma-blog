---
title: Demystifying HybridDKG - A Distributed Key Generation Scheme
publish_date: 2021-05-10T13:11:00.000Z
category: cryptography
excerpt: HybridDKG is one of the latest distributed key generation schemes and can operate in an asynchronous environment, making it the most viable DKG scheme to use over the internet.
image: media/dalle.webp
---

## Introduction

In a [previous post](https://anoma.network/blog/demystifying-aggregatable-distributed-key-generation/), we discussed important VSS and DKG constructs and presented the Aggregatable DKG. Now that the reader better understands DKG, this article elaborates on a different DKG scheme called HybridDKG, as published in [Distributed Key Generation in the Wild](https://eprint.iacr.org/2012/377.pdf).

HybridDKG is a DKG that operates under the asynchronous communication model which is a much more realistic model than the synchronous model that most other DKG schemes rely on. Its underlying VSS, called HybridVSS, is based on [AVSS](https://eprint.iacr.org/2002/134.pdf), which is the component of HybridDKG that allows it to operate asynchronously. Since HybridDKG is operating under the asynchronous model, it requires both its VSS and DKG protocols to use consensus mechanisms in order for the nodes to agree on the secrets.

## Assumptions

As with every cryptographic contruct, HybridDKG relies on certain assumptions in order to prove its security properties.

### Communication model

HybridDKG uses the asynchronous model of communication, in which clocks of nodes may not be accurate (meaning they can be out of sync) and messages can be delayed for arbitrary period of time. In this model, it is assumed that the adversary manages the communication channels and can delay messages as it wishes. HybridDKG assumes that a real-world adversary cannot control communication channels for all the honest nodes and, thus, that the adversary (eventually) delivers all the messages between two uncrashed nodes.

A stricter assumption, named weak synchrony, is used only in order to prove the protocol's liveness. Under the weak synchrony assumption, the time difference $delay(T)$ between the time a message was sent ($T$) and the time it is received doesn't grow indefinitely over time.
Weak synchrony is not necessary for the protocol's correctness.

It is also assumed that all communication is authenticated and the adversary is unable to spoof messages.

### Faults

HybridDKG can tolerate non-byzantine node crashes, non-byzantine broken communication links and byzantine faults. It groups non-byzantine crashes and non-byzantine single broken communication links under the same fault type. The byzantine adversary is considered static, meaning that it cannot change its choice of nodes as time progresses.

The protocol can tolerate:

- Up to $t$ byzantine nodes
- Up to $f$ non-byzantine crashed nodes and non-byzantine failed connections at any given instant in time
- $d(\kappa)$ maximum number of crashes an adversary is allowed to perform during its lifetime

The number of the participants is:

$$
n \ge 3t+2f+1
$$

### Adversary

An assumption introduced by the specific polynomial commitment scheme used in this HybridVSS is that the adversary is computationally bounded on the DLP with a security parameter $\kappa$.

## Prerequisites

We first list some mathematical properties that will be useful later on:

- To reconstruct a univariate polynomial of degree $t$ we need $t+1$ points on that polynomial
- Having a bivariate polynomial $\phi(x,y)$ of degree $2t$, we can generate univariate polynomials by fixing the value of $x$ (or $y$):
  $a_{x=x'}(y) = \phi(x', y)$
- If the bivariate polynomial is symmetric, it holds that $\phi(x,y) = \phi(y,x)$
- From the above we can derive that for a symmetric $\phi$ it holds $a_{x'}(y) = a_{y}(x')$

## HybridVSS

In the asynchronous model, each node follows two assumptions: that enough nodes will get their shares and there will be enough nodes participating in reconstruction. In order to remove the need to make assumptions, HybridVSS takes it a step further and provides a mechanism for nodes to keep track of how many other nodes are participating and their states instead of relying on the above assumptions.

We will now define the sharing, reconstruction, and recovery phases of HybridVSS. All the messages described below are tagged with a unique session ID $(P_d, \tau)$, with $P_d$ being the session's dealer and $\tau$ a unique number.

### Sharing

### Initialization

The dealer $P_d$:

- produces a random symmetric bivariate polynomial $\phi(x,y) = \sum_{i,j=0}^t\phi_{ij}x^iy^j$ with the secret encoded in as the constant factor $\phi(0,0) = \phi_{00}$.
- calculates a homomorphic commitment $C$ to the polynomial which is a matrix with $C_{ij} = g^{\phi_{ij}}$.
  $C$ can be used by nodes to verify that:
- a given univariate polynomial $a_i(x)=\displaystyle\sum_{l=0}^t a_{i,l}x^l$ belongs to $\phi$ by checking:
  $g^{a_{i,l}} \stackrel{?}{=} \displaystyle\prod_{j=0}^t(C_{jl})^{i^j}, \forall l\in[0,t]$
- a given value $\alpha$ corresponds to $\phi(m,i)$ by checking:
  $g^\alpha \stackrel{?}{=} \displaystyle\prod_{j,l=0}^t(C_{jl})^{m^ji^l}$

### Dealing

$P_d$ then deals to each node $P_i$ a univariate polynomial $a_i(x) = \phi(x,i)$ by sending a message called $\mathbf{send}$.
This message also delivers $C$.
$C$ is also sent with all other type of messages between nodes so that any two participants can verify the dealer’s commitment and prevent a malicious dealer from segregating the nodes by sharing different commitments.

Each $P_i$ that receives a $\mathbf{send}$, verifies $a_i(x)$ using $C$.
This polynomial provides a way for $P_i$ to generate a point that belongs to the polynomial $a_j(x)$ of another node $P_j$ since $a_i(j) = a_j(i)$ due to $\phi$'s symmetry.

Gossip-based validation and consensus

Each $P_i$ that receives a valid $\mathbf{send}$ message, sends a message called $\mathbf{echo}$ to each node $P_j$ to inform them of the fact that the dealer got in touch.
$\mathbf{echo}$ carries $a_i(j)$ as a proof that it was dealt a valid $a_i(x)$.

After sending $\mathbf{echo}$ to all nodes, $P_i$ enters a listening state, where it listens for two kinds of messages, $\mathbf{echo}$ and $\mathbf{ready}$.

For every received $\mathbf{echo}$ from a node $P_j$ the receiver $P_i$:

- verifies $a_j(i)$ against $C$ and if verified, it stores the point $(j, a_j(i))$ in a set $A_c^i \xleftarrow{}{(j, a_j(i))}_j$
- if enough ($\lceil\frac{n+t+1}{2}\rceil$) valid $\mathbf{echo}$ messages with the same commitment $C$ are received to convince $P_i$ that enough nodes were reached by the dealer, it uses the points in $A_c^i$ to interpolate a polynomial $\bar{a}_i(x)$
- sends a $\mathbf{ready}$ to all other nodes carrying a point $\bar{a}_i(j)$ as a proof of the fact that it received enough $\mathbf{echo}$s

For every received and verified $\mathbf{ready}$, $P_i$:

- stores the received point $\bar{a}_j(i)$ in the same set $A_c^i$
- if enough ($t+1$) $\mathbf{ready}$ messages with the same commitment $C$ are received to be able to interpolate a polynomial of degree $t$, $P_i$ interpolates $\bar{a}_i(x)$
- sends a $\mathbf{ready}$ that carries $\bar{a}_i(j)$ to each node $P_j$
- if enough $\mathbf{ready}$ messages ($n-t-f$) with the same commitment $C$ are received for $P_i$ to be convinced that enough nodes know that enough nodes are participating, it calculates its share $s_i = \bar{a}_i(0)$ and stops.

### Additional notes

A node terminates the sharing process if it has received $(n-t-f)$ $\mathbf{ready}$ messages. Here, the node makes sure that there is a sufficient amount of honest nodes with shares. In other words, it makes sure that the participating honest nodes form a majority in the presence of up to $t$ byzantine adversaries and up to ff crashed nodes.

If a node received a $\mathbf{ready}$ from another node, it implies that the other node has sent an echo and it was never received. I.e., a $\mathbf{ready}$ implies an $\mathbf{echo}$. It is possible for a node to finish the sharing phase by only receiving enough ready messages. In this case, it needs to interpolate $\bar{a}_i(x)$ in order to calculate its share, since the interpolation in $\mathbf{echo}$ processing didn't happen. This is the reason behind the interpolation step in processing a $\mathbf{ready}$ message.

An important note is that a node will only process the first $\mathbf{send}$, $\mathbf{echo}$ and $\mathbf{share}$ messages it received from a specific node $P_i$ during a session $(P_d, \tau)$. This is to make sure that:

- nodes' $\mathbf{echo}$ and $\mathbf{ready}$ counters cannot be manipulated by an adversary by repeating messages
- any recovery messages in circulation will not modify the systems state (this will become clear in the recovery subsection below)

### Reconstruction

Let's first explain how the shares relate to the secret.
The share of $P_i$ is $s_i = \bar{a}_i(0) = \bar{a}_0(i)$, which means that given $t+1$ shares we can interpolate $\bar{a}_0(x) = \phi(0,x)$.
We can then evaluate this polynomial to $0$ to get the secret $s=\bar{a}_0(0)=\phi(0,0)$.

To reconstruct the secret, each node sends its share $s_i$ to all other nodes using the message $\mathbf{reconstruct_{share}}$. It also listens for $\mathbf{reconstruct_{share}}$ messages. For each received $\mathbf{reconstruct_{share}}$ from a node $P_j$, it will first verify $a_j(0)$ against the commitment $C$:
$g^{s_i} \stackrel{?}{=} \displaystyle\prod_{j=0}^t(C_{j0})^{m^j}$
and if the point is verified, it will store it.
When the node has collected $t+1$ points, it is ready to interpolate $\bar{a}_0(x)$ and then obtain the secret $\bar{a}_0(0)$.

### Recovery

We denote $d(\kappa)$ ($\kappa$ is the system's security parameter) the maximum number of crashes an adversary is allowed to perform during its lifetime.

During recovery, the previously crashed node will ask the help of other nodes in replaying its previous communication. Each node keeps a record of all outgoing messages along with their intended recipients in a set $B$, and $B_l$ indicates the subset of $B$ intended for the node $P_l$. Additionally, each node maintains two counters $cnt$ and $cnt_l$. The former tracks the number of overall (system-wide) help requests and the latter the number of help requests sent by each node $P_l$.

A crashed node that just recovered will first send a $\mathbf{help}$ message to all nodes. It will also replay messages in $B$. When a node receives the $\mathbf{help}$ message it will first make sure that the help limits are not exceeded: $cnt \le (t+1)d(\kappa)$ and $cnt_l \le d(\kappa)$ and if these checks pass, it will replay all messages in $B_l$, thus helping to replay the message history that is relevant to the recovered node.

With the above in mind we can see that, if recovery messages were to be processed, many, if not all, packet counters would count a recovered node twice.

## HybridDKG

As with other DKG constructions, HybridDKG makes all nodes HybridVSS dealers. Each node generates a collection of shares from several HybridVSS instances and its final share will be the sum of those shares. Unlike DKGs operating in the synchronous setting, the asynchronous model introduces the requirement of agreement on at least $(t+1)$ successful HybridVSS instances for a set of honest nodes. An additional complexity of the asynchronous setting is the the need to differentiate between crashed and slow nodes.

HybridDKG introduces a role called leader ($\mathcal{L}$), which is responsible for making a proposal of a set of finished HybridVSS instances to be used. Since the leader might be malicious or crash, a leader-change mechanism is introduced. Nodes use timeouts to decide if a leader should be considered crashed.

HybridVSS is extended with a message, $\mathbf{shared}$ which is sent by every node that finishes the HybridVSS sharing phase. It carries all the $\mathbf{ready}$ messages for the session $(P_d,\tau)$ and signatures over them, which helps the leader to provide a validity proof of its proposal.

HybridDKG uses two phases, the optimistic and the pessimistic phase: the former is responsible for the key generation and is where crash recoveries take place; the latter is responsible for executing potential leader-change operations.

#### Optimistic phase

#### HybridVSS execution

The optimistic phase starts by each node $P_d$ becoming a dealer of a HybridVSS session for a secret $s_d$. At the end of a HybridVSS session, each node $P_i$ broadcasts a $(P_d, \tau, \mathbf{shared}, C_d, s_{i,d}, R_d)$ message. The set $R_d$ includes $n−t−f$ signed $\mathbf{ready}$ messages for session $(P_d,\tau)$, $s_{i,d}$ is the share of node $P_i$ and $C_d$ is its commitment. All nodes collect $P_d$ and $R_d$ of received $\mathbf{shared}$ messages:
$\hat{Q} \xleftarrow{} \hat{Q}\cup{P_d}$
$\hat{R} \xleftarrow{} \hat{R}\cup{R_d}$

#### VSS proposal

Once $\mathcal{L}$ has processed $t+1$ $\mathbf{shared}$ messages, it will broadcast a $\mathbf{send}$ message, proposing the set of VSS instances that these $\mathbf{shared}$ messages correspond to. This message is HybridDKG specific and not to be confused with the $\mathbf{send}$ message of HybridVSS.
$\mathbf{send}$ carries $\hat{Q}$ which constitutes $\mathcal{L}$'s proposal on the set of HybridVSS instances to use. It also carries $\hat{R}$ as a proof that the sessions referred by $\hat{Q}$ are valid.

#### Leader-change condition

Any node, apart from $\mathcal{L}$, that processed $t+1$ $\mathbf{shared}$ messages will start a local timer that stops after $delay(T)$. If a node's timer stops before the node has reached the end of the protocol, the node assumes that the leader has either crashed or is malicious and requests a leader change. A leader-change request is performed by broadcasting a $\mathbf{lead_{ch}}$ message. We defer explaining the leader-change logic until we finish the optimistic phase.

#### Gossip-based validation and consensus

All nodes, apart from $\mathcal{L}$, will start listening for $\mathbf{send}$, $\mathbf{echo}$ and $\mathbf{ready}$ messages. Again, these messages are HybridDKG specific and not to be confused with their synonymous HybridVSS. Conceptually though, these messages serve the same purposes as in HybridVSS.

An $\mathbf{echo}$ message is send upon receipt of a valid $\mathbf{send}$. The purpose of $\mathbf{echo}$ is to inform the receiver that the sender was reached by $\mathcal{L}$ with a valid proposal. $\mathbf{echo}$ carries the proposed set $\mathcal{Q}$.

A $\mathbf{ready}$ message is send by nodes that have received enough ($\lceil\frac{n+t+1}{2}\rceil$) $\mathbf{echo}$ messages for the same set $Q$ or enough ($t+1$) $\mathbf{ready}$ messages for the same set $Q$. At this point, the node knows that the protocol can finish successfully, since it knows enough participating nodes and the $\mathbf{ready}$ message informs the receivers of that fact. The node will also update its $\hat{Q}$ set to $Q$, since at this point the set is agreed, and keep the relevant signed $\mathbf{echo}$ or $\mathbf{ready}$ messages as a proof. This update of the set serves as a note upon which VSS instances were agreed and is used during a leader change (more on that at the section explaining the pessimistic phase).

#### Shares construction

Finally, when a node receives enough ($n-t-f$) $\mathbf{ready}$ messages, it can finish the sharing protocol by calculating its share:
$s_i = \displaystyle\sum_{P_d \in Q}s_{i,d}$
and its commitment matrix, generated by the commitment matrices of each HybridVSS instance:
$C = C_{p,q} = \prod_{P_d \in Q}(C_d)_{p,q}$

#### Pessimistic phase

A node enters this phase when it becomes unsatisfied with the current leader. The reasons for this dissatisfaction can be due to a time out or the receipt of an invalid message from the leader.

A predefined cyclic permutation of nodes is assumed to be agreed upfront. For simplicity, we will assume that leaders are sorted in a simple ascending order.

When entering this phase, the node will broadcast a message, called $\mathbf{lead_{ch}}$, informing other nodes that it proposes a leader change. The messages carries the proposed leader $\mathcal{\bar{L}}$ to which the nodes want to change. A dissatisfied node proposes the node that is next (in the ordering) of its current leader.

Two things need to be agreed between nodes: if the leader change is happening and, if so, which node will be the new leader.

A node that receives $t+f+1$ $\mathbf{lead_{ch}}$ messages will be convinced that a leader change is happening and will broadcast a $\mathbf{lead_{ch}}$ proposing the smallest proposed leader it received. If the node receives $t+f+1$ $\mathbf{lead_{ch}}$ messages proposing the same leader, it will accept that leader since consensus on the leader is reached.
Then, if the node is not the next leader, it will restart its counter and enter the optimistic mode.

In the case the node is the next leader, it will use the previously stored $\hat{Q}$ set as the VSS set to use. It will broadcast a $\mathbf{send}$ message with this set and the accompanying signed packets ($\mathbf{shared}$, $\mathbf{echo}$ or $\mathbf{ready}$) as a proof and then enter the optimistic mode.

#### Crash recovery

For recovery of a crashed node, the exact same approach with HybridVSS is used.

#### Reconstruction

Reconstruction of a HybridDKG secret is performed the same way as in HybridVSS. Each node broadcasts its share and collects shares from other nodes. When a node has collected enough shares, it will interpolate the corresponding polynomial and evaluate it at $0$ to calculate the secret.

## Performance

### HybridVSS

Assuming no crashes and thus no recovery messages:
The size of HybridVSS messages is dominated by the size of the commitment $C$ which has $\frac{t(t+1)}{2}$ group elements and thus the protocol's bit complexity is $\mathcal{O}(\kappa n^4)$. An improvement exists that reduces the bit complexity down to $\mathcal{O}(\kappa n^3)$ by using a collision-resistant hash function ([AVSS](https://eprint.iacr.org/2002/134.pdf), Sec. 3.4).
In the following calculations, we assume that this improvement is used. The message complexity is $\mathcal{O}(n^2)$.

Taking into account the recovery messages, the message complexity becomes $\mathcal{O}(tdn^2)$ and the the bit complexity $\mathcal{O}(κtdn^3)$ were $d = d(\kappa)$.

### HybridDKG

With up to $n$ VSS instances being able to complete and with no pessimistic phases taking place we have $\mathcal{O}(tdn^3)$ message complexity and $\mathcal{O}(κtdn^4)$ bit complexity.

Counting in pessimistic phases, we have at most $\mathcal{O}(d)$ leader changing operations. Each leader change operation has $\mathcal{O}(tdn^2)$ message and $\mathcal{O}(κtdn^3)$ bit complexity. Thus the overall overhead of the pessimistic phase is $\mathcal{O}(td^2n^2)$ message and $\mathcal{O}(κtd^2n^3)$ bit complexity.

Adding the pessimistic overhead to HybridDKG complexities, we end up with $\mathcal{O}(tdn^2(n + d))$ message and $\mathcal{O}(κtdn^3(n + d))$ bit complexities.

_Written by George Gkitsas, previously a zero-knowledge cryptography researcher & protocol developer at _[_Heliax_](https://heliax.dev/)_, the team building the _[_Anoma_](https://anoma.net)_ Protocol._

_If you're interested in zero-knowledge cryptography and cutting-edge cryptographic protocols engineering positions in Rust, check out the _[_open positions at Heliax_](https://heliax.dev/jobs)_._
