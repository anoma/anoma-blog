---
title: Abstract Intent Machines
publish_date: 2024-02-23
category: distributed-systems
image: media/intent-machines-01.webp
excerpt: As part of our ongoing research into intents, we've formulated what we believe to be a minimal framework for describing intent processing. In this post, we introduce the concept of an "intent machine", entities capable of processing user intents and transforming system state accordingly.
---

Intents, abstract entities encapsulating a user’s desires, are at the core of Anoma's design goals. The dream of intents is to have a financial system capable of understanding all its user's desires and evolving the network to meet those desires as best as possible.

Intents can range from a trader’s desire to swap assets at a favorable exchange rate, to a user’s condition to release funds only upon the successful completion of a programmed task, to complex combinations of logical, temporal, and financial stipulations often found in smart contracts and automated marketplaces. In the context of a contract enforcing the existence of a sophisticated institution, such as voting systems or decentralized corporate-like entities, more ambitious intents may express desires related to fairness, eﬀiciency, trade-offs, etc.

As part of our ongoing research into intents, we've formulated what we believe to be a minimal framework for describing intent processing. In our recent paper, we introduce the concept of an "intent machine", entities capable of processing user intents and transforming system state accordingly. In their most general form, we define intent machines as a kind of coalgebra.

Coalgebras are a very general mathematical framework for capturing a variety of things, from differential equations, to automata, to the semantics of modal logic. It unifies many ideas under a single banner. For our purposes, many abstract machines can be formulated as a coalgebra. Given a functor, $F$, which can be used to transform some type of thing into another, any function of the form $S \rightarrow F(S)$, for any $S$, is called an "$F$-coalgebra". As a basic example if $F = \text{List}$, then a function $\mathbb{N} \rightarrow \text{List}(\mathbb{N})$ which, for example, copies a number $n$ into a list of length $n$, would be an example of a $\text{List}$-coalgebra.

We may view a coalgebra as a generalized state transition function. Given some type of state, $S$, a coalgebra that takes an $S$ as input will return new $S$'s in a structured way. Given some kind of probability distribution over $S$, $D(S)$, a non-deterministic function of type $S \rightarrow D(S)$, sometimes called a "Markov kernel", is a $D$-coalgebra. We can view each application of the function as a nondeterministic step. As another example, we may imagine a function that waits for an input of type $A$ during each transition. A function of the type $S \rightarrow S^A$ would be an example of a $-^A$-coalgebra.

Given a functor $F$, we may define the infinite data structure that repeatedly iterates $F$; the greatest fixed point of $F$. Given a fixed coalgebra, we may repeatedly apply and map it over the $F$ to build up an element of this type. Such an infinite type represents the static, possibly branching history of the state transitions as defined by the coalgebra. Such a structure defines the behavior of a coalgebra and allows us to define when two machines whose transition function is defined as a coalgebra are equivalent. With a notion of history in hand, we may also define a kind of temporal logic, where we may prove statements about what must happen, what might happen, what will always happen, etc, given a fixed coalgebra. And, in fact, one may observe that the powerset is a functor, that relations may be expressed as a function of the form $S \rightarrow \mathcal{P}(S)$. This gives $\mathcal{P}$-coalgebraic presentation of many modal logics via their Kripke semantics.

Coalgebra is a very broad subject, and I only hope to entice readers who are not familiar with it. For a broad overview of the subject, see the book "[Introduction to coalgebra](https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=623299ff461f365da3972b401fa68b85b4897a11)" by Bart Jacobs.

So, how do we describe intent machines? We assume some notion of state, $S$, a non-determinism functor, $D$, and a notion of intention batch, $B$, and a transition function $S \rightarrow D(B \times S)^B$. An intent machine is then a pair consisting of type $S \times (S \rightarrow D(B \times S)^B)$. The idea behind this definition is that, given a network state, $s : S$, and a batch of intents to process, $b : B$, we can nondeterminically transition to a new state, along with some output batch. This should be specialized, but at this stage, we have enough structure to define sequential, parallel, and conditional forms of composition, allowing us to build up more complex intent machines from simpler ones.

To get closer to capturing intents themselves, we can be more specific about what $B$ is. It should be a set of intents, $B = \mathcal{P}(I)$, where $I$ is the type of intents. What should $I$ be? At the very least, it should express an opinion about the current and future states of the system. Therefore, there should, at the very least, be a function that takes an $I$ and returns a function $S \rightarrow S \rightarrow \star \cup [0, 1]$. What this will do is take a current and future state, and return a $\star$ (the unit type) in case the intent isn't satisfied, and otherwise returns a value between $0$ and $1$ indicating how satisfied it is with the proposed transition.

This may not be all there is to an intent. In a typical resource swap, where a resource could be, for example, some currency or an NFT, an intent may hold control of some part of the state; it may have permission to create or destroy resources as part of a swap execution. Therefore, we may also have a function that takes an $I$ and returns a function $S \rightarrow S$, executing a partial swap. This has implications for speculatively matching to find transitions that maximally satisfy interacting intents. This will be more relevant for the game theory of solving, which will be future work.

We can implement a simple toy instantiation of an intent machine for demonstration. The state can be any structure we want; we can use natural numbers as an example. For the sake of simplicity, we'll let the intents just be weighted relations between natural numbers. At each step, the machine gets a batch of intents and uses a solver to maximize the weight of satisfied intents. We'll implement this in Python using OR-Tools.

To keep it simple, we will assume we have the same four intents at each step, desiring:

• The next state should be even.
• The next state should be odd.
• The next state should differ by 1 from the last.
• The next state should be 1 or 2 greater than the last. If 2 greater, full score, if 1 greater, half score, otherwise, no score.

We will have a stream of inputs which is just a set of these 4 intents, repeated forever.

We may formalize this as an ILP problem. To demonstrate this, we will use the SCIP prover.

```python
from ortools.linear_solver import pywraplp
```

To make boolean variables correspond to our desired propositions, we will use the "Big M" method. For demo purposes, M does not need to be that large;

```python
M = 1000
```

The intents themselves can be formulated as functions that add constraints to the solver. For demo purposes, the constraints are added to the solver, and it's the booleans linked to the constraints that are returned. The scores are tied to the booleans themselves, where, at most, one boolean is true. The current state is taken in as a constant argument, while a variable for the next state is taken as an additional argument so all the constraints can talk about the same next state.

```python
def even_constraint(last_state, next_state_var, solver):
    n = solver.IntVar(0, solver.infinity(), 'n_even')
    b = solver.BoolVar('b_even')
    solver.Add(next_state_var - 2 * n <= M * (1 - b))
    solver.Add(next_state_var - 2 * n >= -M * (1 - b))
    return [(b, 1)]

def odd_constraint(last_state, next_state_var, solver):
    n = solver.IntVar(0, solver.infinity(), 'n_odd')
    b = solver.BoolVar('b_odd')
    solver.Add(next_state_var - 2 * n - 1 <= M * (1 - b))
    solver.Add(next_state_var - 2 * n - 1 >= -M * (1 - b))
    return [(b, 1)]

def two_changes_constraint(last_state, next_state_var, solver):
    b_2_greater = solver.BoolVar('b_2_greater')
    b_1_greater = solver.BoolVar('b_1_greater')
    b_no_change = solver.BoolVar('b_no_change')

    solver.Add(next_state_var - (last_state + 2) <= M * (1 - b_2_greater))
    solver.Add(next_state_var - (last_state + 2) >= -M * (1 - b_2_greater))
    solver.Add(next_state_var - (last_state + 1) <= M * (1 - b_1_greater))
    solver.Add(next_state_var - (last_state + 1) >= -M * (1 - b_1_greater))
    solver.Add(next_state_var - last_state <= M * (1 - b_no_change))
    solver.Add(next_state_var - last_state >= -M * (1 - b_no_change))

    return [(b_2_greater, 1), (b_1_greater, 0.5), (b_no_change, 0)]

def one_more_or_less_constraint(last_state, next_state_var, solver):
    b1 = solver.BoolVar('b_one_more')
    b2 = solver.BoolVar('b_one_less')

    solver.Add(next_state_var - (last_state + 1) <= M * (1 - b1))
    solver.Add(next_state_var - (last_state + 1) >= -M * (1 - b1))
    solver.Add(next_state_var - (last_state - 1) <= M * (1 - b2))
    solver.Add(next_state_var - (last_state - 1) >= -M * (1 - b2))

    return [(b1, 1), (b2, 1)]
```

The machine itself has essentially the same formulation as the theory; being a function taking a state and a batch of intents, represented as a dictionary mapping constraint names to functions. These intents are then called to modify the solver state to include the new constraints. The sum of the booleans scaled by weight is then used as an objective function, and a new state, along with a list of satisfied intents is returned. There's also a 30-second timeout, but the demo takes only microseconds.

```python
def machine(state, constraints_dict):
    solver = pywraplp.Solver.CreateSolver('SCIP')
    if not solver:
        raise Exception('SCIP solver not available.')

    solver.SetTimeLimit(30000)

    next_state_var = solver.IntVar(0.0, solver.infinity(), 'next_state_var')

    objective = solver.Objective()
    objective.SetMaximization()

    bool_vars = {}  # Dictionary to store solver boolean variables

    for name, constraint_func in constraints_dict.items():
        for b, w in constraint_func(state, next_state_var, solver):
            bool_vars[b] = name  # Store the constraint name
            objective.SetCoefficient(b, w)

    status = solver.Solve()

    total_objective = objective.Value()

    satisfied_constraints = []

    if status in [pywraplp.Solver.OPTIMAL, pywraplp.Solver.FEASIBLE, pywraplp.Solver.ABNORMAL]:
        new_state = next_state_var.solution_value()
        for b in bool_vars.keys():
            if b.solution_value() > 0.5:
                satisfied_constraints.append(bool_vars[b])  # Get the constraint name
        return new_state, satisfied_constraints, total_objective
    else:
        return state, [], total_objective
```

as a usage example, we can put all our constraints into the batch;

```python
constraints_dict = {
  'even': even_constraint,
  'odd': odd_constraint,
  'two_changes': two_changes_constraint,
  'one_more_or_less': one_more_or_less_constraint
  }
```

we can then run

```python
new_state, satisfied, total_objective = machine(5.0, constraints_dict)
print(f"New state: {new_state}, Satisfied constraints: {satisfied}, Total Objective: {total_objective}")
```

getting the output

```python
New state: 6.0, Satisfied constraints: ['even', 'two_changes', 'one_more_or_less'],
Total Objective: 2.4999999999999996
```

We may then implement a function to actually run the machine on a stream of batches;

```python
def run_machine_in_sequence(initial_state, list_of_constraints_dicts):
    current_state = initial_state
    output_states = []
    all_satisfied_constraints = []

    for constraints_dict in list_of_constraints_dicts:
        new_state, satisfied_constraints, total_objective = machine(current_state, constraints_dict)
        output_states.append(new_state)
        all_satisfied_constraints.append((satisfied_constraints, total_objective))
        current_state = new_state  # Update the current state for the next iteration

    return output_states, all_satisfied_constraints
```

This function will repeatedly stream batches from an input list and update the state accordingly. The history of states and satisfied constraints will then be outputted after the list of batches is exhausted. We can see how the state evolves over time with

```python
run_machine_in_sequence(0, [constraints_dict for x in range(10)] )
```

This is just going to repeat the batch with all 4 intents 10 times. It will output.

```python
([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0],
[(['odd', 'two_changes', 'one_more_or_less'], 2.5),
(['even', 'two_changes', 'one_more_or_less'], 2.5),
(['odd', 'two_changes', 'one_more_or_less'], 2.5),
(['even', 'two_changes', 'one_more_or_less'], 2.5),
(['odd', 'two_changes', 'one_more_or_less'], 2.4999999999999996),
(['even', 'two_changes', 'one_more_or_less'], 2.4999999999999996),
(['odd', 'two_changes', 'one_more_or_less'], 2.5),
(['even', 'two_changes', 'one_more_or_less'], 2.5),
(['odd', 'two_changes', 'one_more_or_less'], 2.4999999999999996),
(['even', 'two_changes', 'one_more_or_less'], 2.4999999999999996)])
```

It never seeks to satisfy the full "two-greater" constraint. Doing so would only gain 0.5 while losing 1 from not satisfying the one-more-or-less constraints. We can, at this point, create arbitrary streams of batches to get more interesting histories, if desired.

Later in the [paper](https://zenodo.org/records/10654543), we describe more practical instantiations of intent machines for the purposes of barter mechanisms. I encourage anyone interested in that to read the paper for those details.

This work lays the foundation for future work on the game theory of intent solving. But that's a story for the future; one that's yet to be written. So that's where I'll end this, for now.
