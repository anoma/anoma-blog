---
title: The Unrealized Potential of String Diagrams in ZKVM design
publish_date: ???
category: compilers
image: media/string_puppet.webp
excerpt: This post will describe string diagrams and explain why they are a good starting point when it comes to designing ZKVMs.
---

## Trees Considered Harmful

By the end of this , I want to convince the reader that there are better forms of syntax (namely, graphical ones). By the end, I'll also touch on how this may influence better ZKVM design.

First, some issues with trees. Historically, most languages in mathematics have been constructed using abstract syntax trees, or ASTs. The very definition of a grammar in most computer science contexts assumes that any language must be structured like a tree. Most of the time, this seems fine, but a century of hacks have had to be invented to compensate for the deciciencies of trees.

I think the easiest place to see this is in the combinator calculus. Variables remain a persistant issue for theory, and much ink has been spilt trying to treat variables coherently. Among the earliest methods for managing them is to simply eliminate them. From this, we get the original combinator calculus invented by Skonfinkle. A conceptually similar system was also invented by Quine in the 1940s for similar reasons. [NOTE: Cite skonfinle and quine] It allows one to manipulate syntax, but one must spend an inordinate effort dealing with a convoluted origami just to get separate ends of trees to communicate with eachother.

[NOTE: Come up with more evocative phrasing for the convoluted]

A similar system exists to eliminate the need for quantifiers in first-order logic. "Relation algebra" is a variable free alternative to first-order logic. This system is extremely interesting [NOTE: Cite introduction.], however, it has some obvious downsides. The core relation algebra is not as expressive as the full first-order logic. It's equivalent to the first-order logic when restricted to only using three variables. One can fix this issue by manually introducing a notion of tuple, along with some relations describing, tuple manipulation (forking, projecting, etc.). This puts one in a similar place to combinator logics where one is forced to deal with an akward yoga of point-free operators to do basic things.

Is this inconvenience neccessary for variable elimination? The answer is not, but it seems the historical assumption was that the answer should be "yes", and so we saw the emergence of variable binders.

The most popular alternative to combinator calculus is the lambda calculus. In this system, variables are not eliminated, but, instead, the syntax is altered to allow leaves of the syntax tree to connect back onto a leaf elsewhere in the tree. Such modified trees are called "abstract binding trees" [NOTE: Cite Chapter on ABTs]. Such trees have appeared in many places. Quantifiers also bind their variables. Interestingly, quantifiers appeared under similar circumstances to lambda expressions. Prior to the invention of quantifiers by Charles Sanders Peirce, Peirce had presented first-order logic in terms of a variable-free relation algebra. [NOTE: Find citation for this] An even earlier example of such a syntax is that of integrals which bind their variable of integration.

Abstract binding trees are a much more obvious example of a hack. It's a half-hearted step away from trees and toward graphs. ABTs are trees that wish they were graphs.

ABTs also introduce odd conceptual problems. Variable bindings are always scoped. This matters for something like quantification and integration where there's an intended semantics, but it makes less sense for lambda expressions. Why are bindings in the lambda calculus scoped? It's just a rewrite system; it's perfectly consistent to allow all variables to be treated globally, so long as each lambda binder has a uniquly named variable. Of course, doing a unique name check is a bit of a complication, but this is, again, a flaw stemming from using trees rather than graphs.

Quantifiers also have weird scoping issues. In classical FOL, all quantifiers can be moved outiside the formula. So long as all the variables of a quantifier are in scope, the exact position of the quantifier doesn't actually matter. In this sense, quantifiers can be considered as essentially free-floating relative to the quantifier-free part of the formula. However, trees require that everything in an expression be connected through the root, so the quantifiers are always pegged somewhere arbitrary. Trees often force one to keep track of more structure than is actually present.

Trees are also worse at dealing with resources. Consider the rewrite rules;

```
b(x, y) ~~> x

x ~~> b(x, x)
```

That first rule deletes an arbitrary amount of information, `y`, and that second copies an arbitrary amount of information, `x`. These rules are perfectly consistent, but one cannot effectively capture resource usage using these types of rules. It's not hard to correct these problems; one could pattern match on x and y and introduce an intermediate duplication/unzipper construct to deal with the components peicemeal. Such constructs are akward and ugly; my point, though, is that the most natural and easiest thing to do when working with trees leads to technical debt. By contrast, these rules would simply not make sense in a graphical seting. One cannot simply delete a y, as it may connect back onto x. One can not simply duplicate x, as it may connect to other things elsewhere in the graph expression. To deal with deletion and duplication coherently when working with graphs, one must create local rewrite rules, which we'll see are quite simple. If we care about resources, graphs force us to do the right thing while trees encourage us to do the wrong thing.

<iframe src="scripts/tree-graph.html" width="100%" height="600px" frameborder="0"></iframe>

Enough complaining. What's the solution? Well, graphs, ya, but not just graphs. Consider what turning a tree into a graph implies. If we had an expression like `b(x, y)`, we would create a node labeled `b` which connects to the graphs corresponding to `x` and `y`. The `b` node would also have an additional edge going toward the root of whatever expression it appears in. In the original expression, `x` and `y` are ordered, and are also clearly distinct from the root of the expression; not so in the graph representation. By just using an ordinary graph, we've lost essential structure. So we need a graph where each node orders its edges. When a structured graph has nodes with a specific number of edges with a fixed order, we call the edges of a node "ports". This also allows us to generalize tree grammars in a sensible way, buy restriting our graph to those built from nodes with specific ports of specific types. This kind of graph is what I have in mind when I say "string diagram". It is in this sense that string diagrams may be considered "graphical" generalizations of "arborial" (tree-like) syntax.

[Cite: String diagrams for computer scientists]

In practice, string diagrams tend to have a bit more structure, which I'll talk about a bit, but that is the core idea.

## How String Diagrams Fix Issues Caused by Trees

Going back through the previous issues I had. Let's start with deletion and duplication. For deletion, we need an eraser node, e, along with a rewrite rule along the lines of;

```
||||	     |  |  |  |
 n	~~>  e  e  e  e
 |
 e
```
[NOTE: Replace with SVG]

In this way, the erasor can spread, scanning through graph deleting nodes it encounters peicemeal. In practice, there will be some limitation, where the eraser rewrite will only apply when its connected to some "prinicple" port of n. This prevents the erasor from simply deleting the whole graph if its preasent at all.

Duplication is only slightly more complicated ;

```
||||    	|	|	|	|
  n		d	d	d	d
  |    ~~>	|\\\   /|\\   //|\   ///| 
  d		n	n	n	n
||||		|	|	|	|
```

[NOTE: Replace with SVG]

One can view the eraser as the special case where the duplicator is duplicating into 0 subgraphs.

The presence of deletors and duplicators is called "frobinius structure" in the litturiture. [NOTE: CITATION?]

With these in hand, we can see how to improve the lambda calculus. With a built-in duplicator and erasor, we only need to add linear lambda binders to our language. This ends up being quite simple. We only need to specify how nodes representing lambda binders. We can turn the rewrite `(\x. y)z ~~> y[x/z]` into

```
(\x. y)z	z			(\x. y)z	z
|		|			|		|	
  	@				    \       /
  	|			~~>             X
  	L                                   /       \
|   		|			|               |
x		y                       x               y
```

This also gets rid of unneccesary scoping. This also doesn't recreate the naming problems. There are no names for the variable appearing in string diagrams. All variables become strings/edges connecting nodes, and these variables are "named" by their position within the diagram. This eliminates the need for names without eliminating variables themselves. So we've acomplished the original goal of combinator calculus without its inefficiencies.

Taking this seriously as a model of computation, we get the symmetric interaction combinators and its varients;

[CITE: SIC paper?]




There is also a strict increase in expressivness by switching to straing diagrams instead of trees. Most applications won't see this, but, for example, the first-order theory of finite automata cannot have a finite axiomatization if one uses trees for its syntax, but it can if one uses string diagrams instead.

[NOTE: CITATION]

## What Makes String Diagrams Efficient for Arithmetization?

## What Should a ZKVM do?
