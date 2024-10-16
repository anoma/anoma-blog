---
title: Anoma in Elixir
category: ecosystem
publish_date: 2024-10-08
image: media/DistOpFuture.png
excerpt: This article explains why Anoma is built using the Elixir programming language.
co_authors: agureev
---


## Summary

This article explains why Anoma is built using the [Elixir programming language](https://elixir-lang.org/):

1.   Elixir lets developers inspect the system while it's running, and
     update its running code without restarting.
2.   Elixir compiles to Erlang, a well-established programming system
     designed for building robust, fault-tolerant networked systems
     with a "let it crash" philosophy.
3.   There's a natural fit between Elixir's "agent model", and Anoma's
     architecture, which is based on message-passing "engines".
4.   As the structure of the language matches the design of the
     system, implementation complexity decreases.
5.  The above properties ease formal verification efforts.

Hence Elixir provides the right abstractions to build Anoma according
to its specification, and delivers a good developer experience while
promising support for future verification.


<a id="orgc06199d"></a>

# Anoma: Why Elixir?

Anoma is a _decentralized operating system with heterogeneous trust_.
It has the following properties:
1. It has to support a large network of interacting actors.
2. It has to be robust.
2. Its core components are "[engines](https://specs.anoma.net/latest/node_architecture/engines.html?h=engine)"

[Elixir](https://elixir-lang.org/), therefore, seems suitable for our implementation.

1. Its interactive environment supports both productive development
   practices and multi-agent system analysis.
2. The OTP basis fosters application robustness.
3. There is a correlation between engines and GenServers.

Let us explicate these points:


<a id="orgb7d7476"></a>

## Live Interactive Systems

When building any system, there are two core features a developer needs:

1. Understand how the system is operating.
2. Determine if there are mishaps when carrying out a design.

For most software projects, this means, accordingly:

1. Thinking about the code in abstract _(...which can be time-consuming)_.
2. Tracing through the system execution _(...which can be obscure)_.

Thankfully, [Elixir](https://elixir-lang.org/) rests on the
foundations of Erlang/OTP. In practical terms, this means that we get
a live interactive environment to ask questions about our system. The
specific features it lends us are:

1.  Hot code reloading
    -   This means that we can have the software running locally, and be able
        to change any part of it without having to shut down and restart
        the service. This is invaluable for trying to experiment with new
        ideas!
2.  Underlying environmental reflection
    -   The underlying reflection gives the system the information it
        needs to be able to report back. Without inroads to the system,
        an interactive system would quickly turn opaque!
3.  The entire system available (from parser to compiler, to
    visualization suite) from the user shell
    -   This allows a skilled engineer the ability to diagnose problems
        and see practical implications of what they are doing. This is
        a part of the [same technology that allowed people to debug a space
        probe 100 million miles away!](https://flownet.com/gat/jpl-lisp.html)
4.  A lack of artificial distinction between system and language.
    -   This means that the core functionality of the system is realized
        through the language itself, proving itself capable enough to
        compose a highly robust system.

Instead of having to simply sit and think about the architecture of
how the components of the implementation fit together, these tools
allow us to ask the underlying system, "Please give us the layout of
Anoma processes":

![img](media/observer-1.png)

The specifics of the diagram don't matter. What does is that the
system can reflect on itself, helping to explain the very system that
we are building. Meaning, that the implementation can be in dialog
with the builders to shape discussion around itself. For example what
if we were curious about one of those nodes in the diagram, what
information can we get from there?:

![img](media/observer-2.png)

As we can see, we now have diagnostics on the particular node along
with information about its **state**, **stack trace**, etc.

With these properties and features laid out, this makes Elixir quite
different from commonly used languages (Java, Rust, Python, etc.)

With that said, there are [genres of languages](https://wiki.c2.com/?ImageBasedLanguage) that exhibit the same
features some of which have [superior visualization techniques](https://gtoolkit.com/). What is
it about the Erlang/OTP system that makes them special compared to
them?


<a id="org19197a5"></a>

## Designing Robust Systems

To understand what makes [Elixir](https://elixir-lang.org/) special,
we first must go back to what problems Erlang and the Beam were meant
to solve. Joe Armstrong's thesis: [Making reliable distributed systems
in the presence of software
errors](https://erlang.org/download/armstrong_thesis_2003.pdf), lays
out their problem domain:

1.  The system must handle large numbers of concurrent activities
2.  Actions must be performed at a certain point in time or within a
    certain time.
3.  Systems may be distributed over several computers.
4.  The system is used to control hardware.
5.  The software systems are very large.
6.  The system exhibits complex functionality such as feature
    interaction.
7.  The system should be in continuous operation for many years.
8.  Software maintenance should be performed without stopping the
    system.
9.  There are stringent quality and reliability requirements
10. Fault tolerance both to hardware failures, and software errors,
    must be provided.

To tackle these problems he created a philosophy and
requirements that the underlying operating system and
language should have, creating Erlang/OTP.

To give a sample of the features the system has:

1.  The system has very cheap processes
        ```elixir
        iex(mariari@Gensokyo)10> :timer.tc(fn -> spawn(fn -> nil end) end)
        {10, #PID<0.1689.0>}
        ```

    -   This snippet shows a process takes only 10 microseconds to spawn!
2.  The architecture of the application is split into a series of
    processes, each process is often referred to as actors.
    -   Actors are interesting objects as here are their central properties:
        1.  They contain some state they maintain
        2.  They can send and receive messages
        3.  Messages are processed sequentially (order is guaranteed)
            between the same two actors!
3.  Processes are isolated. Meaning that if a process crashes, it does
    not affect other processes. [Erlang the movie](https://www.youtube.com/watch?v=BXmOlCy0oBM) gives a good example
    of this at play on their real systems!
4.  Processes are managed by a chain of [supervisors](https://www.erlang.org/doc/apps/stdlib/supervisor.html).
    -   Supervisors are interesting in that they look after many
        processes. When a process they
        are supervising crashes, they have policies on what happens to
        the other processes under their control.
    -   It was realized that actors on their own are not enough to make a
        robust system, and this is a crucial component that is missing
        from most other actor models.
5.  The mentality is "let it crash".
    -   With Supervisors, this is a very potent strategy for creating
        reliable and robust systems.
        -   When crashes happen early, we can isolate the errors, this is
            hard to do when one has an Either/Result/Maybe type, as stack
            information is often lost with those strategies. The supervisor
            then can restart the crashed component helping the system
            resume normal behavior.
        -   Further, since parts of the system being down can be normal, one
            typically thinks out a robust supervision system that lets the
            system gracefully degrade. A common example is having a full
            fledged system that does all the bells and whistles, however
            when some external service is down (say you query an external
            service for images or AI responses), then we can fall back on
            simpler behavior until the issue is solved.
        -   This also helps in the case of underlying hardware errors, as
            if something like a bit flip due to a cosmic ray were to
            happen to a high-integrity component, instead of the
            application crashing and stopping, the application could crash
            and sensible restart behavior can be had.
6.  The system has fair concurrency, with its own scheduler system.
    -   This means your processes aren't going to get starved of
        resources.

These are just a few of the features that make the Erlang/OTP system
stand out even among other interactive systems. Robustness is
essential for a large-scale system of interacting agents.

However, are there any Anoma-specific requirements that Elixir helps
fulfill? To answer this, we have to consult the
[specification](https://specs.anoma.net/latest/).

<a id="org3dd3410"></a>

## Implementing an Engine

Anoma is an idea, made concrete in a [protocol
specification](https://specs.anoma.net/latest/). It is the source of
truth that the implementation should follow. Its primary value is
being a model of an attractive idea, which will drive the users to
interact with the codebase.

Therefore it is of utmost importance that the implementation
corresponds as clearly and as naturally as possible to the
specification.  This is, what the user is looking for is an
instantiation of the presented proposal with desired properties. That
is, they need to be certain that a piece of code lying inside a
repository is an actual implementation of the system described.

To make this process easy, the engineers need to have a good interface
that makes establishing a connection between concepts central to the
specification and our code as trivial as possible.

For example, if you are interested in functions, it matters whether
you present id : Bool -> Bool as lambda x -> x or {{true, true},
{false, false}}. There is a reason why we don't use set theory
everywhere in mathematics. If you think of functions as something that
takes things in and pops things out, the type-theoretic approach is
probably easier to comprehend and work with.

Following this idea, a good requirement for the desired language is to
have a good first-class citizen corresponding to the central concept
of the specification: the
[engine](https://specs.anoma.net/latest/node_architecture/engines.html?h=engine). Almost
every functionality in the Anoma infrastructure is specified as a
functionality of a particular engine. E.g.  _Mempool behavior_ is
implemented through the _Mempool Engine_; _Transaction execution_ is
implemented through the _Execution Engine_.

An
[engine](https://specs.anoma.net/latest/node_architecture/engines.html?h=engine)
has several properties, which notably include:

1.  It is stateful
2.  It can receive messages
3.  It can send messages
4.  Messages are processed sequentially

So what is an engine? Something that looks like an agent, it seems!
Now what systems take agents as first-class citizens? From the
previous section, we now know that Erlang-based systems do that!

Having a good actor model of the language we use does not only allow
for an easier understanding of the codebase, greater engagement with
parties interested in Anoma development coming from the specification
side, it also grants us credence in future verification and auditing
work being done internally.

The formal verification efforts Anoma has are aimed not at the
verification of a particular implementation: implementations may
differ and canonical ones may change due to timely choices. Instead,
proving of system properties will be done through the formalization of
the Anoma specification. As it goes, a proof is only as good as the
initial formalization of the system. The closer the underlying
concepts of the specification and the implementation are, the more
believable it is that whatever we come to prove about Anoma will also
correspond to a proof about our Elixir implementation.


<a id="orgfdc8d20"></a>

## Conclusion

We have chosen Elixir to develop the Anoma node software. The Anoma
node consists of several independently moving pieces that have to be
orchestrated and connected (e.g., transaction execution, intra-node
communication, configuration, etc.). From a developer's
perspective it is beneficial to be able to introspect these individual
components at runtime, update them, and manipulate them.
Additionally, the Erlang VM offers us the basic building blocks to
build and connect such a system of independent processes in a robust
and scalable way.

The specification of Anoma dictates that any node consists of
different 'engines', which are isolated processes each responsible for
handling part of the Anoma node responsibilities.  The Erlang VM its
computational model of processes with shared-nothing memory maps
nearly 1:1 on the architecture proposed in the Anoma
specification. This means that the implementation of the specification
will have much less accidental complexity compared to other
computational models.

Thus, choosing the Erlang VM to implement the Anoma specification
offers us better developer UX and reduces the impedance mismatch
between the specification of Anoma and its physical implementation.
