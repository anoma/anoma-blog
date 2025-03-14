# Growing Mempools on Trees: local first FTW

Let us consider a simple
mathematical model for running a tree of frequent batch auctions.
We start with a single global pool and split it up into 
pairs of pools that are run by half the number of operators;
then, we repeat this process to obtain a tree of interconnected mempools.

![Our idealized one-dimensional world sphere: green operators on a black circle and their hierarchy of pools that form a binary tree.](MempoolHierarchiesInAnSVG.svg){width=1.5in}

A child pool is more than twice as fast as its parent pool;
this is because of quadratic complexity of consensus
and reduced round trip time.
Thus, 
each order can be processed once on each level of the hierarchy
_without loosing time,_ in expectation.
As a consequence,
in the usual setting of utility functions,
the [Von Neumann–Morgenstern utility theorem](https://en.wikipedia.org/wiki/Von_Neumann%E2%80%93Morgenstern_utility_theorem), and 
[discounted utility](https://en.wikipedia.org/wiki/Discounted_utility),
the hierarchical mempools do perform well concerning expected social welfare,
based on some simple simulations.
Moreover, 
note that the described arrangement of mempools is *literally* local first,
because order flow is propagated from local to global,
one step at a time.

Let us look at three scenarios
to understand for when such structured mempools can be useful.

1. If pairs of matching orders arise on opposing sides of the circle _only,_
then clearly, there is no point in having a hierarchical mempool,
because matching orders will always travel all the way to the root pool.
In this case,
we only need the global pool.

2. On the other extreme,
if matching orders always occur in proximity to each other,
we only need sufficiently many "discrete" local pools, 
i.e., without connections between the pools whatsoever!

3. Last but not least, 
as indicated by simulation results,
there is a sweet spot when about 50% of orders are filled in each pool,
if we model orders as [Poisson point processes](https://en.wikipedia.org/wiki/Poisson_point_process).

Last but not least, 
the design may also be of interest
as a means towards fast pre-confirmations.
If nothing else, it gives some fresh food for thought.

