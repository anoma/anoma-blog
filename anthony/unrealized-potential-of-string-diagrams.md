---
title: The Unrealized Potential of String Diagrams for ZKVMs
publish_date: ???
category: compilers
image: media/string_puppet.webp
excerpt: This post will describe string diagrams and explain why they are a well suited for designing ZKVMs.
---

## Trees Considered Harmful

By the end of this post, I want to convince the reader that there are better forms of syntax than abstract syntax trees; namely, graphical ones. I'll also touch on how this may influence better ZKVM designs.

First, *what's so bad about trees?* 

Historically, most languages in mathematics have been constructed using abstract syntax trees, or ASTs. The very definition of a grammar in most computer science contexts assumes that any term of any language must be structured like a tree. Most of the time, this seems fine, but a century of hacks have had to be invented to compensate for the deficiencies of trees.

I think the easiest place to see this is in the combinator calculus. Variables remain a persistant issue for theory, and much ink has been spilt trying to treat variables, or really, variable names, coherently. Issues related to scoping and shadowing formally complicate the syntactical aspects of mathematics which most simply take for granted. Among the earliest methods for managing them is to simply eliminate them. From this, we get the original combinator calculus invented by Skonfinkle. Conceptually similar systems were invented over the last century for similar reasons, such as [predicate functor logic](https://en.wikipedia.org/wiki/Predicate_functor_logic). These allow one to reason through symbol manipulation without needing named variables, but one must spend an inordinate effort dealing with a convoluted origami just to get separate ends of trees to communicate.

Another approach to eliminating the variables created by quantifiers in first-order logic is [Relation algebra](https://en.wikipedia.org/wiki/Relation_algebra). This system is extremely interesting, and has been developed these days largely under the guise of the algebra of programming.

- [Components and acyclicity of graphs. An exercise in combining precision with concision](https://www.sciencedirect.com/science/article/pii/S2352220821000936)

however, it has some obvious downsides. The core relation algebra is not as expressive as the full first-order logic. It's equivalent to the first-order logic when restricted to three variables. One can midigate this issue by manually introducing a notion of tuple, along with some relations describing tuple manipulation (forking, projecting, etc.). This puts one in a similar place to combinator logics where one is forced to deal with an awkward yoga of point-free operators to do things which would be taken for granted in a setting with variable binding.

Is this inconvenience necessary for variable elimination? The answer is "no", but it seems the historical assumption was "yes", and so we saw the emergence of variable binders. The most popular alternative to combinator calculus is the lambda calculus. In this system, variables are not eliminated, but, instead, the syntax is altered to allow leaves of the syntax tree to connect back onto a leaf elsewhere in the tree. Such modified trees are called "[abstract binding trees](http://www.cs.cmu.edu/~rwh/pfpl/abbrev.pdf#page=22)". Such trees have appeared in many places. First-order formulas with quantifiers are also examples of ABTs. An even earlier example of such a syntax is that of integrals which bind their variable of integration.

Abstract binding trees are a much more obvious example of a hack. It's a half-hearted step away from trees and toward graphs. ABTs are trees that wish they were graphs.

ABTs also introduce force some odd conceptual problems. Variable bindings are always scoped. This matters for something like quantification and integration where there's an intended semantics, but it makes less sense for lambda expressions. Why are bindings in the lambda calculus scoped? It's just a rewrite system; it's perfectly consistent to allow all variables to be treated globally, so long as each lambda binder has a uniquly named variable. Of course, doing a unique name check is a bit of a complication, but this is, as will be seen later, a flaw stemming from using trees rather than graphs.

Quantifiers also have weird scoping issues. In classical FOL, all quantifiers can be moved outside the formula. So long as all the variables of a quantifier are in scope, the exact position of the quantifier doesn't actually matter. In this sense, quantifiers can be considered as essentially free-floating relative to the quantifier-free part of the formula. However, trees require that everything in an expression be connected through the root, so the quantifiers are always pegged somewhere arbitrary. Trees often force one to keep track of more structure than is actually present.

Trees also encourage methods which are bad for dealing with and reasoning about resources. Consider the rewrite rules;


* $b(x, y) ↦ x$

* $x ↦ b(x, x)$

That first rule deletes an arbitrary amount of information, $y$, and that second copies an arbitrary amount of information, $x$. These rules are perfectly consistent, but one cannot effectively capture resource usage using these types of rules. It's not hard to correct these problems; one could pattern match on $x$ and $y$ and introduce an intermediate duplication/unzipper construct to deal with the components piecemeal. Such constructs are awkward and ugly; my point, though, is that the most natural and easiest thing to do when working with trees leads to technical debt. By contrast, these rules would simply not make sense in a graphical setting. One cannot simply delete a $y$, as it may connect back onto $x$. One can not simply duplicate $x$, as it may connect to other things elsewhere in the graph expression. To deal with deletion and duplication coherently when working with graphs, one must create local rewrite rules, which we'll see are quite simple. If we care about resources, graphs force us to do the right thing while trees encourage us to do the wrong thing.

Enough complaining. What's the solution? Well, graphs, ya, but not just graphs. Consider what turning a tree into a graph implies.

[component name="anthony/tree-graph"]

If we had an expression like `b(x, y)`, we would create a node labeled `b` which connects to the graphs corresponding to `x` and `y`. The `b` node would also have an additional edge going toward the root of whatever expression it appears in. In the original expression, `x` and `y` are ordered, and are also clearly distinct from the root of the expression; not so in the graph representation. By just using an ordinary graph, we've lost essential structure. So we need a graph where each node orders its edges. When a structured graph has nodes with a specific number of edges with a fixed order, we call the edges of a node "ports". This also allows us to generalize tree grammars in a sensible way, buy restricting our graph to those built from nodes with specific ports of specific types.

[component name="anthony/tree-port-graph"]

This kind of graph is what I have in mind when I say "string diagram". It is in this sense that string diagrams may be considered "graphical" generalizations of "arborial" (tree-like) syntax.

- [An Introduction to String Diagrams for Computer Scientists](https://arxiv.org/abs/2305.08768)

In practice, string diagrams tend to have a bit more structure. Mainly a partitioning of the edges of each node into "source" and "target" sets so that each node can act as a morphism of a monoidial category. However, this is not essential for this post so I will not dwell on it.


## How String Diagrams Fix Issues Caused by Trees

Going back through the previous issues I had. Let's start with deletion and duplication. For deletion, we need an eraser node, e, along with a rewrite rule along the lines of;

<image src="media/string-diagram-rewrite-rule-e.svg" width="100%"></image> 

In this way, the eraser can spread, scanning through graph deleting nodes it encounters piecemeal. In practice, there will be some limitation, where the eraser rewrite will only apply when its connected to some "principle" port of n. This prevents the eraser from simply deleting the whole graph if its present at all.

Duplication is only slightly more complicated ;

<image src="media/string-diagram-rewrite-rule-d.svg" width="100%"></image> 

One can view the eraser as the special case where the duplicator is duplicating into 0 subgraphs.

With these in hand, we can see how to improve the lambda calculus. With a built-in duplicator and eraser, we only need to add linear lambda binders to our language. This ends up being quite simple. We only need to specify how nodes representing linear lambda binders interact with nodes representing application. We can turn the rewrite $(\lambda x. y)z ↦ y[x/z]$ into

<image src="media/linear-beta-reduction.svg" width="100%"></image> 

This also doesn't recreate the naming problems. There are no names for the variables appearing in string diagrams. All variables become strings/edges connecting nodes, and these variables are "named" by their position within the diagram. This eliminates the need for names without eliminating variables themselves. So we've acomplished the original goal of combinator calculus without its inefficiencies.

This also gets rid of unnecessary scoping.

[component name="anthony/tree-binder-graph"]

Taking this seriously as a model of computation, we get the symmetric interaction combinators and its varients;

- [Observational equivalence and full abstraction in the symmetric interaction combinators](https://lmcs.episciences.org/1150/pdf)

Using string diagrams, much more elegant presentations of "quantifier-free" first order logic can be made. I put that in quotes since quantifiers still exist as specific node constructs, but the underlying calculus is most similar to relational algebra without the inefficiencies of point-free syntax. The details are a bit too much to cover here, but see

- [Diagrammatic Algebra of First Order Logic](https://arxiv.org/abs/2401.07055)

There is also a strict increase in expressiveness by switching to string diagrams instead of trees. Most applications won't see this, but, for example, the first-order theory of finite automata cannot have a finite axiomatization if one uses trees for its syntax, but it can if one uses string diagrams instead.

- [A Finite Axiomatisation of Finite-State Automata Using String Diagrams](https://arxiv.org/abs/2211.16484)

The string diagram setting is a genuine generalization of the ordinary algebraic setting.

## What Makes String Diagrams Efficient for Arithmetization?

What makes a ZKVM efficient to arithmetize in the first place? At first glance, looking at a Von-Neuman architecture, it seems like an insurmountable task. You have some ram with potentially several gigabytes of memory, and then you have to project this through time, creating a trace which scales multiplicatively with space and time. Thankfully, it's easy to design an architecture which mitigates these issues. Rather than starting with a given, fully explicated state, just start with all 0s. Then, have your opcodes only modify one address at a time. Then your trace can be a list of modifications, "this address turned into this because of that opcode". One needs to set up check to ensure the old values are correctly looked up, but this is now independent of the memory size and only proportional to time. Since the registers can be modified in less restricted ways, one may still have to state their values at every step, but that's much smaller.

What makes this efficient is that a single step of computation has a fixed amount of work it needs to do. During PLONKish arithmetization, for example, we'd shove our trace into a big matrix. The complexity of a single step of computation is going to dictate the width of this matrix. Naively, each row will have to store everything about the state modified during that step. This forces us to use a model of computation that can't do an unbounded amount of work in a single step. So the SK combinator calculus with the $Sxyz ↦ xz(yz)$ rule that copies an arbitraryly large $z$ in a single step is out. The height is just the length of the trace, and that's unpredictable.

There are, of course, many clever ways around this. I was recently pointed to this as a way to arithmetize combinator calculi in a different way than I suggest.

- [EDEN - a practical, SNARK-friendly combinator VM and ISA](https://eprint.iacr.org/2023/1021.pdf)

Based on my understanding, it's using a combinatorial construction which exploits an isomorphism between tree expressions and Dyck words to linearize tree expressions in a way that's more SNARK friendly. I think there is a lot of potential in using latice paths, pattern-avoiding permutations, and other linear combinatorial objects to create effective arithmetizations for higher-dimensional combinatorial structures. I don't want to give the impression that this post is about "the one true way". I think it's better than alternatives I've seen, but there's so much low hanging fruit all over the design space that's worth exploring.

Finding a good arithmetization can be cast as the problem of fitting your check into as thin a matrix as possible. We have a structure, $D$, that we want to check with a predicate, $P$. We want to create a function, $f$, that turns any given $D$ into a matrix, and devise a predicate over matricies, $P'$, such that $P'(m) \equiv (\exists d. P(d) \wedge f(d) = m)$. Ideally, the width of $f(d)$ should be $O(1)$ with respect to the size of $d$. Of course, we also want $P'$ to be equivalent to a low-degree polynomial equation, but I'm going to ignore that for now.

Let's get a bit more technical about what a string diagram is. In its simplest form, we have a list of nodes, each having a list of ports. The wiring can be characterized in a few ways. Often, the ports will be partitioned into "input" and "output" (or "positive" and "negative") and the wiring is just a bijection between the input and output ports. Without such a partition, we can instead characterize the wiring as an automorphism over the ports such that no port is mapped onto itself. String diagrams will often have additional structure, but this is the basic idea. This captures string diagrams as a streightforward combinatorial object.

A rewrite rule consists of a pair of sub-graphs wired into a boundary. This boundary is shared between both sides of the rewrite rule. We can define a rewrite rule as a triple consisting of a list of input nodes, a list of output nodes, a boundary with its own list of ports, and two automorphisms; one over the sum of input and boundary ports and the other over output and boundary ports. We may also have an additional requirements, such as having no boundary port be mapped onto another boundary port.

Given a set of rewrite rules, we can then ask what a trace looks like. A trace can be viewed as a string diagram where rewrite rules are nodes. The input nodes of the rule become input ports on the node, and output nodes become output ports. The ports are typed by the type of nodes. The trace is a string diagram for this type of node, where the wiring is a set of bijections, for each type of node t, between the input ports of type t and the output ports of type t. The starting and ending nets of the trace can be viewed as nodes with no input (respectively, output) ports. After ordering the rewrite rules temporally, we can take a slice of the trace diagram to get an image of the nodes in the diagram at that point in time.

That's the core data structure. This isn't enough to guarantee the trace is valid, but the additional structural checks are asymptotically linear in the number of rewrites. We may observe that we can follow the bijections in the trace diagram to get a cycle of ports in the slices of the trace. Starting on a port in the input, we can follow the trace wiring to get a node of the same type in the input of the rewrite. If the internal wiring connects to the boundary, we continue following the wires to the port of an output node; otherwise, we end up at the port of an input node. We then continue by following the trace wiring to a new rewrite rule. If we distinguish between each node in each slice by numbering it according to the rewrite rule that produced it, then the internal wirings of all the rewrite rules produce a bijection between all the slice ports. Since we can follow the trace wiring between slice ports as well, we get a second bijection between the slice ports. By composing these bijections, we get a new bijection. Because it is a bijection between finite sets, following it will eventually get you back to where you started. This means we get a cycle of ports. We can imagine these port cycles as defining the boundary of sheets filling in the space between the strings in the trace diagram.

The core check that we must make to ensure the trace is valid is simply that every port cycle has exactly one occurrence of an internal wiring rewrite between input nodes, and this happens at a slice higher than everything else in that port cycle. When this happens, that means the rewrite is deleting an edge. This check is just ensuring that every edge is only deleted once and never occurs after that. Depending on what else the diagrams represent, there may be more checks on the structure, but this is the start.

I explicate what this looks like in the context of interaction combinators in this paper;

- [Arithmetization of Functional Program Execution via Interaction Nets in Halo 2](https://eprint.iacr.org/2022/1211)

## Final Thoughts: What Should a ZKVM do?

String diagrams exist for a wide variety of applications these days, for [quantum computation](https://arxiv.org/pdf/2312.03653), [classical physics](https://arxiv.org/abs/2404.16140), [linear algebra](https://dl.acm.org/doi/pdf/10.1145/3290338), [logic](https://arxiv.org/pdf/2211.12629), and many other things. One can create a universal circuit for these domains by arithmetizing their respective string diagram formalisms. In this way, we may get notions of verifiable statements which go beyond merely executing a program.

As part of a future project, I plan on describing a ZKVM for full first-order logic, where the circuits encode proofs of statements. An ordinary program trace can be formulated in such a setting, but we are free to make broader logical deductions. What we often want to express when defining a smart contract are propositions. Turning those propositions into program trace verifications works fine, but it's just one part of the design space which can be broadened. This idea is explored somewher it work such as the usage of Matching Logic in the [Universal Truth Framework](https://runtimeverification.com/mission-and-vision/pc-vision.pdf). It seems to me that using string diagrams, we have many options for formulating logics and algebras in a way that's more naturally suited for creating universal curcuits.

