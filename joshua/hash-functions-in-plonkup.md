---
title: Hash Functions in Plonkup
publish_date: 2021-12-20T00:00:00.000Z
category: cryptography
image: media/dalle.webp
excerpt: A quick overview of the proving system and show how to write a circuit that computes a small part of a common hash function that benefits greatly from the inclusion of lookups alongside arithmetic gates.
---

## Introduction

Plonkup is a new zero-knowledge proving system that combines Plonk with Plookup, allowing Plonk's arithmetic and custom gates to coexist with lookup gates enabled by Plookup. Some expensive components of zk-SNARK circuits, like hash functions, can be expressed more efficiently using lookups and arithmetic together. In this article I will give a quick overview of the proving system and show how to write a circuit that computes a small part of a common hash function that benefits greatly from the inclusion of lookups alongside arithmetic gates.

## Plonk

Plonk is a proving system from Gabizon, Williamson, and Ciobotaru first formulated in 2019 which allows a universal, updatable trusted-setup. The trusted-setup is public data, created in a multiparty computation "ceremony", which can be used to create and verify proofs. It is called _trusted_ because a setup can be compromised if all of its creators collude. (If even one participant is honest then the setup is secure).

_Universality_ means that a single trusted-setup cermony can be used by any circuit below a certain size. Without this property a new ceremony would need to be performed for each circuit.

_Updatability_ means an existing trusted-setup can be updated in a new ceremony, potentially with new participants, and is secure as long as even one participant, in any update, was honest.

These two properties address the most common security concerns with zk-SNARK trusted-setups and makes collusion much more difficult.

Plonk, like most other proving systems, uses _arithmetic circuits_ to represent computations. Arithmetic circuits use two gates, + and ×, to express all operations done in the circuit. Complex computations require many, many gates to represent them and can take quite awhile to prove. Certain operations, like the bit-wise arithmetic often used in cryptographic hash functions, cannot be expressed very efficiently as an arithmetic circuit. Circuits that use multiple hash functions can grow to an enormous size and may take minutes to prove. (This bottle-neck applies to any proving system using arithmetic gates, not just Plonk.)

Plonk has two major parts to its circuit: arithmetic gates and copy constraints. The arithmetic gates are easily checked using a single polynomial constraint. Copy constraints, which hook arithmetic gates together, are used to build a _permutation polynomial_ which check the validity of all the copy constraints at once.

## Plookup

Plookup is its own proving system from Gabizon and Williamson that is very similar to Plonk, but dispenses with the arithmetic circuit and instead can be used to prove that each element in a list of queries exists in a public lookup table.

Plookup doesn't use arithmetic gates, but it has its own permutation polynomial that checks that lookup queries are legitimate.

With lookups, operations that are inefficient as arithmetic circuits, like range proofs and bit-wise operations, become much more efficient.

## Why combine two protocols?

The number of gates in a circuit is a primary factor in the amount of time it takes to create a proof. Some operations we might want to use in a circuit can be written using fewer gates depending on the method.

Take XOR for instance. Many cryptographic hash functions we'd like to model in a circuit, like SHA or Blake, make liberal use of XOR. To show that three 8-bit values $a,b$ and $c$satisfy $a\oplus b = c$ using Plonk arithmetic gates only you would first need to constrain each bit of the inputs using 16 gates, then perform 8 single-bit XOR operations with 8 more gates, and packing the resulting bits back together with an additional 7 gates, for a grand total of 31 gates per XOR.

Using a Rank-1 Constraint System (R1CS) is a bit better in this case, because of unlimited addition we can replace the final 7 gates with a single rank-1 constraint, giving 25 total constraints.

With Plookup and an 8-bit XOR lookup table, however, this can be done in a _single gate_.

Some other operations, like point addition on an embedded elliptic curve, are already pretty efficient using arithmetic gates alone. To maximize efficiency we'd like to use both lookup gates and arithmetic gates in the same circuit.

## Plonkup Circuits

A Plonkup circuit consists of several parts.

_Wires_ are vectors containing the Prover's private inputs. The wires can be thought of as columns of a large matrix. We'll use three wires in these examples which we will call $a,b$ and $c$.

In this matrix a row is a tuple of private inputs that must satisfy any constraints that are turned on for this row.

_Selectors_ are vectors which turn on or off constraints for each row. A one at index 47 of the multiplication selector means that row 47 must satisfy a multiplication constraint, like $a_{47}\cdot b_{47} = c_{47}$.

_Copy constraints_ are simple equations that link the values of entries in one row with those in another, say $c_1=a_9$ for instance.

Finally, the lookup table is another matrix with the same number of columns as the Prover has wires. A lookup table with three columns can simulate a function with two inputs and one output. A row $(r,s,t)$ in a lookup table simulating the function $f$ means that $f(r,s) = t$.

## An Example Circuit

Let's show how to construct a small Plonkup circuit that does something useful. In the Blake2 hash, 32-bit words are XORed with one another and the resulting bits are rotated some number of places. This is a perfect operation to use as a small example of a Plonkup circuit.

## Lookup Table

Since our table is simulating XOR, a valid row of the lookup table will look like $(a,b,a\oplus b)$. We will need to cycle through all possiblities of $a$ and $b$. If $a$ and $b$ were 32 bits each we would have a lookup table with $2^{32}\times 2^{32}$ rows. Each row has three entries, and each entry is an element of a scalar field for some ellipitic curve, typically 256 bits or larger. For 256-bit entries our table will be a slim, reasonable, totally-not-universe-breaking 1.5 zebibytes.

So we'll need to make our table a little smaller. Let's use just 8 bits for $a$ and $b$ giving us a table of $2^{16}$ rows and and a total size of just 6 mebibytes. An example row of the table would be $(13, 255, 242)$ if we use decimal integers to stand in place of the 256-bit scalar field elements for convenience.

## Gates

**32-bit XOR**

To XOR two 32-bit numbers we split each number into four 8-bit chunks and use four lookup gates to compute the XOR. Then we need to pack the four chunks back together to get the 32-bit result. Let's call our two 32-bit inputs $x$ and $y$ and divide them into four parts each so that $x = x_3|x_2|x_1|x_0$ and $y = y_3|y_2|y_1|y_0$. We compute the four XORs as $z_3 = x_3 \oplus y_3$, $z_2 = x_2 \oplus y_2$, $z_1 = x_1 \oplus y_1$, and $z_0 = x_0 \oplus y_0$. Then our four XOR gates will be:

$$
\text{lookup}(x_3, y_3, z_3)\\\text{lookup}(x_2, y_2, z_2)\\\text{lookup}(x_1, y_1, z_1)\\\text{lookup}(x_0, y_0, z_0)
$$

Now we need to pack the results of the XOR back together into one 32-bit value. We'll pair the two upper and two lower chunks together, left-shift the higher chunks of each pair by 8 bits and add the lower chunks to get two 16-bit values. Then we repeat with a 16-bit shift and addition to get our final 32-bit result.

A bit shift is just multiplication by a power of two, so we can do the packing with a few addition gates. Plonkup supports scalar multiplication in an addition gate by putting the scalars into the selectors for the left, right, and output variables. An addition gate like $\text{add}((l,x),(r,y),(o,z))$ will enforce the constraint $lx+ry+oz = 0$.

Our bit-packing addition gates will look like this:

$$
\text{add}((2^8, y_3)(1,y_2),(-1,z_\text{hi}))\\\text{add}((2^8, y_1)(1,y_0),(-1,z_\text{lo}))\\\text{add}((2^{16}, z_\text{hi})(1,z_\text{lo}),(-1,z))
$$

**Bit Rotation**

A bit rotation can be tought of as a "swap" of two chunks of bits. If we're careful, we can use a field element to represent each of the two chunks rather than breaking them down bit-by-bit. This swap is a left rotation by however many bits are in $z_\text{up}$ (or a right rotation by the number of bits in $z_\text{down}$).

$$
z = z_\text{up}|z_\text{down}\\w = z_\text{down}|z_\text{up}
$$

The operation denoted by ∣ is concatenation of the bit representations of $z_\text{up}$ and $z_\text{down}$, but we can use field elements to represent $z_\text{up}$ and $z_\text{down}$ and never need to mess with the bits at all. Using field elements we can express the concatenations using these simple formulas:

$$
z = 2^{n-k}z_\text{up}+z_\text{down}\\w = 2^{k}z_\text{down} + z_\text{up}
$$

As long as the bit representations of $z_\text{up}$ and $z_\text{down}$ are actually $k$ and $n-k$ bits respectively these formulas correctly compute the leftwards rotation by $k$ bits.

The last thing to do is check the bit lengths of $z_\text{up}$ and $z_\text{down}$. Unfortunately they will be different lengths most of the time and will require two additional range lookup tables or some extra constraints to adapt them to use the same additional range lookup table. Neither of these is ideal. Thankfully, it turns out that constraining the input and output variables $z$ and $w$ to $n$ bits also constrains $z_\text{up}$ and $z_\text{down}$ to their correct bit lengths. Since these variables are the same size we can use the same range lookup table for both. Furthermore, if $z$ is the output of a previous step of the circuit it may already be range constrained. This is the exact case we find ourselves in if we follow an XOR with a rotation.

The XOR lookup necessarily bounds the range of its output, which is another stroke of luck. We can re-use the XOR lookup table to function as a range lookup table for ranges in multiple of 8 bits. If $a$ and $b$ are both less than $2^8$ then $(a, b, a\oplus b)$ will be a row in the lookup table. We can check two field elements with each XOR lookup gate.

One of the rounds in Blake2s uses a rotation of 7 bits. Assuming $z$ is constrained to 32 bits by earlier constraints, we can start with two addition gates.

The Prover computes $z_\text{up}$ and $z_\text{down}$ so that $z = z_\text{up}|z_\text{down}$ and so that $z_\text{up}$ and $z_\text{down}$ are the correct number of bits. Then our addition gates will be:

$$\text{add}((2^{25}, z_\text{up}),(1,z_\text{down}),(-1,z))\\\text{add}((2^7, z_\text{down}),(1,z_\text{up}),(-1,w))$$

Then the Prover computes 8-bit pieces $w_3,\ldots,w_0$ so that $w=w_3|w_2|w_1|w_0$ and computes to XORs $w_3\oplus w_2$ and $w_1\oplus w_0$. Then we have two lookup gates showing all four chunks are less than 8 bits:

$$
\text{lookup}(w_3, w_2,w_3\oplus w_2)\\\text{lookup}(w_1, w_0,w_1\oplus w_0)
$$

Then we show the 8-bit chunks were correctly computed with three more addition gates:

$$
\text{add}((2^8, w_3), (1,w_2),(-1,w_\text{hi}))\\\text{add}((2^8, w_1),(1,w_0),(-1,w_\text{lo}))\\\text{add}((2^{16}, w_\text{hi}),(1,w_\text{lo}),(-1,w))
$$

## **Putting it All Together**

Using an 8-bit XOR lookup table (which does double-duty as an 8-bit range table) we can express $w = \text{rot}_7(x\oplus y)$ for 32-bit $x,y,w$ using these 14 constraints:

$$
\begin{align*}&\text{lookup}(x_3, y_3, z_3)\\&\text{lookup}(x_2, y_2, z_2)\\&\text{lookup}(x_1, y_1, z_1)\\&\text{lookup}(x_0, y_0, z_0)\\&\text{add}((2^8, y_3)(1,y_2),(-1,z_\text{hi}))\\&\text{add}((2^8, y_1)(1,y_0),(-1,z_\text{lo}))\\&\text{add}((2^{16}, z_\text{hi})(1,z_\text{lo}),(-1,z))\\&\text{add}((2^{25}, z_\text{up}),(1,z_\text{down}),(-1,z))\\&\text{add}((2^7, z_\text{down}),(1,z_\text{up}),(-1,w))\\&\text{lookup}(w_3, w_2,w_3\oplus w_2)\\&\text{lookup}(w_1, w_0,w_1\oplus w_0)\\&\text{add}((2^8, w_3), (1,w_2),(-1,w_\text{hi}))\\&\text{add}((2^8, w_1),(1,w_0),(-1,w_\text{lo}))\\&\text{add}((2^{16}, w_\text{hi}),(1,w_\text{lo}),(-1,w))\end{align*}
$$

## Comparison to R1CS

Let's compare this to the same circuit expressed using a Rank-One Constraint System as in Groth16. R1CS has a few advantages and several disadvantages. An advantage is that R1CS allows unlimited additions in a single constraint, so a single R1CS constraint can replace several of the addition constraints we used in our Plonkup-based circuit. A drawback is that R1CS doesn't support lookups or efficient range gates, so the XOR operations and range proofs need to be done bit-by-bit. By my count, an R1CS version of the same circuit would require 2×32 bit constraints for range proofs,32 bit-wise XOR constraints, and 1 rotation-and-bit-packing constraint. Overall an R1CS version of this circuit would need almost seven times as many constraints at. While R1CS constraints aren't exactly comparable one-to-one with Plonkup constraints with respect to Prover time, using 1/7th the number of gates will certainly be a major improvement.

## Drawbacks

Plonkup's lookup table adds some overhead to the cost of constructing a proof and to the proof size. This 8-bit XOR lookup table has $2^16$ rows which is fairly large. In a large, complex circuit where XOR is used many times a table of that size may be worth it, but such a large table is decidedly wasteful for this tiny example ciruit. A 4-bit table would be quite small at only $2^8$ rows but would roughly double the number of constraints needed in the circuit to 26, still pretty small.

## Final Thoughts

Plonk is a highly adaptable and flexible proving system which admits endless custom configurations, such as Plonkup, which can dramatically improve performance for certain operations. There will likely be many more iterations of Plonk that address all sorts of little inefficiencies or are really effective for certain specialized circuits. Multiple modes of proof accumulation, recursion, and circuit optimization will come next. These features will enable Anoma to be a maximally private and scalable protocol.

_Written by Joshua Fitzgerald, zero-knowledge cryptography researcher & protocol developer at _[_Heliax_](https://heliax.dev/?ref=blog.anoma.net)_, the team building _[_Anoma_](https://twitter.com/anoma?ref=blog.anoma.net)_._

_If you're interested in zero-knowledge cryptography, cutting-edge cryptographic protocols, languages for circuits, or engineering positions in Rust, check out _[_the open positions at Heliax_](https://heliax.dev/jobs?ref=blog.anoma.net)_._
