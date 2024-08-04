---
title: SuperSpartan by Hand
publish_date: 2024-08-05
category: cryptography
image: media/super-spartan.jpeg
excerpt: The goal of this article is to dive into the techniques behind the SuperSpartan's polynomial IOP, which uses the sum-check protocol to prove CCS instances, by writing the protocol explicitely for a specific example. This is part 1 of a two-post series. These techniques used in SuperSpartan are at the core of the HyperNova protocol that will be explored in part 2.
---

> *I'd like to thank Nicolas Mohnblatt for brainstorming, discussing and reviewing this article, and for his many shared insights. I'm also thankful to Srinath Setty, Jamie Gabbay and Apriori for their generous feedback.*
> *This article wouldn't have been possible without them. All mistakes are my own.*

This article was originally written on a SageMath Jupyter notebook, which can be found [here](https://github.com/Acentelles/blogposts/tree/main/superspartan).

## Introduction

The [sum-check protocol](https://dl.acm.org/doi/pdf/10.1145/146585.146605) is like one of those magic tricks that, despite having been exposed to how it works, it still makes your mind do some acrobatics every time you see it applied.

Any polynomial equation can be transformed into an instance of the sum-check, making this amazing algorithm surprisingly applicable. 

Since the sum-check lies at the core of the [HyperNova](https://eprint.iacr.org/2023/573.pdf)'s folding techniques, we will dive first into its details on a simpler case: the checking of a [Customisable Constraint System (CCS)](https://eprint.iacr.org/2023/552.pdf) instance using the SuperSpartan’s polynomial IOP as described in their paper.

## Transforming any check into a sumcheck 

The goal of the sum-check is to check that an untrusted prover has computed the following equation correctly, where $f \in K[X_1,...,X_l]$ is a multivariate polynomial (not necessarily multilinear):

$\begin{aligned}
T &= \sum_{x \in \{0,1\}^l} f(x) \\ 
&= \sum_{x_1 \in \{0,1\}} \sum_{x_2 \in \{0,1\}} ... \sum_{x_l \in \{0,1\}} f(x_1, x_2, ..., x_l)
\end{aligned}$

After $l$ rounds, the protocol allows the verifier to check $f(r_1,...,r_l) = c$, for some random $r_i \in \mathbb{F}$, which with high probability implies the original equation, due to the [Schwartz-Zippel lemma](https://en.wikipedia.org/wiki/Schwartz%E2%80%93Zippel_lemma).

Say we have a polynomial $f$ encoding a vector of evaluations $v = [v_1,..., v_{n}]$ such that for all $x_i$ in some subdomain $H$, $f(x_i) = v_i$. In our setting, a prover wants to convince a verifier that this is the case (i.e. $\forall x_i \in H. f(x_i) = v_i$). If every $v_i = 0$, this is known as a zero-check. 

Note that we can always transform the check $f(x_i) = v_i$ into a zero-check since $f(x_i) - v_i = 0$.

For example, in vanilla [Plonk](https://eprint.iacr.org/2019/953.pdf), $f$ is a univariate polynomial that encodes an execution trace and $H$ is a subset of the roots of unity of some prime field (e.g. $H := \{\omega^1,\omega^2,\omega^3,\omega^4,\omega^5,\omega^6,\omega^7,\omega^8\}$).

In [HyperPlonk](https://eprint.iacr.org/2022/1355.pdf) (a variant of Plonk that transforms the zero-checks in the protocol into sumchecks), $H$ becomes a boolean hypercube $\{0,1\}^l$ (i.e. all the $l$ combinations of zeroes and ones), and $f$ a multivariate polynomial of some degree $d$ such that $\forall x \in \{0,1\}^l. f(x) = 0$.
For example, if $l$ is set to 3, then $H := \{0,1\}^3 = \{(0,0,0), (0,0,1), (0,1,0), (0,1,1), (1,0,0), (1,0,1), (1,1,0), (1,1,1)\}$

*To apply the sum-check protocol, we need a statement of the form $\sum_{x\in \{0,1\}^l} f(x) = 0$*.

It is clear that if $\forall x\in \{0,1\}^l. f(x) = 0$ then $\sum_{x\in \{0,1\}^l} f(x) = 0$, but the converse doesn't necessarily hold. For example, $f((0,0,1)) = -1$, $f((0,1,0)) = 1$ and $f(x) = 0$ otherwise makes $\sum_{x\in \{0,1\}^l} f(x) = 0$ but $f(x) \neq 0$ for some $x\in \{0,1\}^l$.

To overcome this, we define a different multilinear polynomial:

$
\begin{aligned}
\widetilde{eq} : &\mathbb{F}^l \times \mathbb{F}^l \to \mathbb{F} \\ 
&(X_1, X_2) \mapsto 1, \text{ if } X_1 = X_2, X_1, X_2 \in \{0,1\}^l \\ 
&(X_1, X_2) \mapsto 0, \text{ if } X_1 \neq X_2, X_1, X_2 \in \{0,1\}^l
\end{aligned}
$

That is

$\widetilde{eq}(X_1, X_2) := \prod_{j=1}^l ((1-X_{1_j})(1-X_{2_j}) + X_{1_j} X_{2_j})$. 

> We use a tilde \~ over a function $g$ to emphasise that $\widetilde{g}$ is a multilinear polynomial.


```python
k = GF(101)

R = PolynomialRing(k, 10, "x1, x2, y1, y2, y3, x11, x22, y11, y22, y33")
x1, x2, y1, y2, y3, x11, x22, y11, y22, y33 = R.gens()
```


```python
eqx = ((1 - x1)*(1 - x11) + x1*x11) * ((1 - x2)*(1 - x22) + x2*x22)
eqy = ((1 - y1)*(1 - y11) + y1*y11) * ((1 - y2)*(1 - y22) + y2*y22) * ((1 - y3)*(1 - y33) + y3*y33)

eqx(x1=1, x2=1, x11=1, x22=0)
```




    0



*The new polynomial $\widetilde{eq}$ together with the sum-check protocol will allow us to compute the desired zero-check,* $\forall x \in H. f (x) = 0$, as follows:

We define a new polynomial

$\begin{aligned}
h : &\mathbb{F}^l \to \mathbb{F} \\
& X \mapsto \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, X)
\end{aligned}$

> Note that $X$ is a variable while $x$ is not. $h$ is known as a multilinear extension of $f$ in the boolean hypercube, since $\forall X\in \{0,1\}^l. h(X) = f(X)$. That is, $f$ is defined over $\{0,1\}^l$ while $h$ is defined over $\mathbb{F}^l$. 

For example, if $X = (1,0,1)$, then $h((1,0,1)) = \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, (1,0,1)) = f((1,0,1))$.

Since $\forall x\in \{0,1\}^l. f(x) = 0$, and $\forall X\in \{0,1\}^l. h(X)=f(X)$, then $\forall X\in \{0,1\}^l. h(X) = 0$. 

*The main difference between $f$ and $h$ is that $f$ is a *multivariate* polynomial of (potentially high) degree $d$, whereas $h$ is a multilinear polynomial.*


> We know that a univariate polynomial $g$ of $k>1$ coefficients in uniquely determined by $k$ evaluations, and it is of degree $k-1$. Similarly, a multilinear polynomial $h$ of $k$ variables is uniquely determined by $2^k$ evaluations. 

In this case, $h(Y) := \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, Y)$ has $2^l$ coefficients (most of them zero) and so it is uniquely determined by $2^l$ evaluations. Since $\forall \{0,1\}^l. h(Y) = f(Y) = 0$, then $h$ is zero at $2^l$ points and must necessarily be the zero polynomial, $h = 0$.

**The verifier has reduced his task to checking that $h$ is indeed the zero polynomial, which is a simpler problem.**

By the Schwartz-Zippel lemma, we can verify that $h$ is the zero polynomial with high probability by evaluating $h$ at a random point $r \in \mathbb{F}^l$. 

That is, $h(r) := \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, r)$ must be equal to zero. Here is where we apply the sum-check protocol.

So **if $h(r) = 0$, this implies with high probability that $h = 0$, which implies that $\forall Y \in \{0,1\}^l. h(Y) = 0$, which implies that $\forall x\in \{0,1\}^l. f(x) = 0$, thus proving the original statement with high probability (w.h.p.).** In short,

$h(r) = 0 \overset{w.h.p}{\Longrightarrow} h = 0 \Longrightarrow \forall Y \in \{0,1\}^l . h(Y) = 0 \Longrightarrow \forall x\in \{0,1\}^l. f(x) = 0$.

## Example: A Fibonacci relation

The following recurrence relation is tailored to help us illustrate the workings sum-check protocol for CCS relations as is used in [HyperNova](https://eprint.iacr.org/2023/573.pdf). This example reflects the SuperSpartan’s polynomial IOP for CCS protocol described in the [CCS paper](https://eprint.iacr.org/2023/552.pdf).

```rust
// i-th iteration
fibonnaci(x_2, x_1, y_2, y_1) {
    x = x_1 + x_2 // Fibonacci
    y = y_1 * y_2 // Multiplicative Fibonacci
    t = x * y     // Fibonacci x (Multiplicative Fibonacci)
    (x, y, t)
}
```

> In the second part of this post, we will prove the result of iterating $n$ times over $f$, starting with some initial values, by applying the folding techniques in HyperNova.

For now, we focus on proving a single iteration, in particular, that which results from the initial values $x_2 = 0, x_1 = 1, y_2=2, y_1=3$ that outputs $x = 1, y=6, t=6$. 

So we first need to *arithmetise this statement*.

### A CCS primer

[Customisable Constraint System (CCS)](https://eprint.iacr.org/2023/552.pdf) relations are a generalisation of [R1CS](https://learn.0xparc.org/materials/circom/additional-learning-resources/r1cs%20explainer/) relations.

In particular, a *relation* $\mathcal{R}$ in CCS is composed by:

- a *structure* $s := ([M_1, ..., M_t], [S_1,...,S_q], [c_1, ..., c_q])$, plus some other bound parameters such as the number of rows $m$ and columns $n$ of the matrices $M_i$. 
- an *instance*, which consists of public inputs $\times \in \mathbb{F}^l$ and private inputs $\omega \in \mathbb{F}^m$.

that satisfies:

$\begin{aligned}     
\sum_{i=0}^{q-1} c_i \cdot \circ_{j \in S_i} M_j \cdot z = \vec{0}
\end{aligned}$

where:
* $z := (\omega, x, 1) \in \mathbb{F}^n$.
* $x \in \mathbb{F}^{l}$ are the public inputs.
* $\omega \in \mathbb{F}^{m - l - 1}$ are the private inputs.
* $M_j \cdot z$ denotes matrix-vector multiplication,
* $\circ$ denotes the Hadamard product between vectors 
* $\vec 0$ is an $m$-sized vector with entries equal to the the additive identity $0 \in \mathbb{F}$.

Expanded, a CCS equation looks like:

$\begin{aligned}     
c_0 \cdot \overbrace{(M_{j_{0}} \cdot z \circ ... \circ M_{j_{|{S_{0}}|-1}} \cdot z)}^{j_i \in S_0} + ... + c_{q-1} \cdot \overbrace{(M_{j_{0}} \cdot z \circ ... \circ M_{j_{|{S_{q-1}}|-1}} \cdot z)}^{j_i \in S_{q-1}} = \vec{0} 
\end{aligned}$.

In our case, $m = 4$ and $n = 8$ are the rows and columns of the $t=3$ matrices $M_1, M_2, M_3$.  $\{M_1, M_2\}$ are multiplied and added to $\{M_3\}$, so $S_1 = \{1, 2\}, S_2 = \{3\}$. Since there are two addends $S_1$ and $S_2$, $q =2$. 

### A Fibonacci CCS relation

The Fibonacci combined recurrence relation of our example can easily be represented as a CCS relation: 

$c_1 \cdot (M_1 \cdot z \circ M_2 \cdot z) + c_2 \cdot (M_3 \cdot z) = \vec{0}$

$\begin{aligned}  
& \overbrace{1}^{c_1} \cdot (\overbrace{\begin{bmatrix}   
1 & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}  }^{M_1} 
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z \circ
\overbrace{\begin{bmatrix}   0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 \\   0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}}^{M_2}  
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z) \\
+& \overbrace{(-1)}^{c_1} \cdot \overbrace{\begin{bmatrix}   0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}}^{M_3} 
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z
= \overbrace{\begin{bmatrix} 0 \\ 0 \\ 0 \\ 0 \\ 0 \\ 0 \\ 0 \\ 0 \end{bmatrix}}^{\vec{0}}
\end{aligned}$


> We have a particular interest in having our rows and columns of size $2^m$ for some $m$, since the sum-check protocol runs over the boolean hypercube. In this case, $m = 4 = 2^2$ is the number of constraints (i.e. rows) and $n = 8 = 2^3$ is the number of witnesses (i.e. columns) as well as the size of the vector $z$. 

> Note that we have added a dummy row is $[0 ,..., 0]$ for $M_1, M_2, M_3$ (it could be any other vector as long as the CCS relation holds trivially).



```python
M1 = Matrix(k, [
    [1,1,0,0,0,0,0,0],
    [0,0,0,0,1,0,0,0],
    [0,0,1,0,0,0,0,0],
    [0,0,0,0,0,0,0,0]
])

M2 = Matrix(k, [
    [0,0,0,0,0,0,0,1],
    [0,0,0,1,0,0,0,0],
    [0,0,0,0,0,1,0,0],
    [0,0,0,0,0,0,0,0]
])

M3 = Matrix(k, [
    [0,0,1,0,0,0,0,0],
    [0,0,0,0,0,1,0,0],
    [0,0,0,0,0,0,1,0],
    [0,0,0,0,0,0,0,0]
])

# First iteration
x = [0,1,1,2,3,6,6]
w = []
z1 = vector(k, x + w + [1])

# CCS relation check
1 * (M1*z1.column()).elementwise_product(M2*z1.column())-(M3*z1.column()) == vector([0,0,0,0]).column()
```


```python
m = M1.nrows()
n = M1.ncols()

(m, n)
```



### Transforming CCS relation into a sum-check

We want to turn this matrix-vector problem statement into a sum over the boolean hypercube. 

We begin by creating multilinear extensions $\widetilde{M_i}$ of $M_i$ and $\widetilde{z}$ of $z$ such that the multilinear polynomial

$\begin{aligned}
f_i : \mathbb{F}^{\log m} &\to \mathbb{F} \\
X &\mapsto \sum_{y \in \{0, 1 \}^{\log n}} \widetilde{M_i}(X, y) \cdot \widetilde{z}(y)
\end{aligned}$

is a multilinear extension of our matrix-vector product $M_i \cdot z$. 

Since $m=2^2$ and $n=8 = 2^3$, then $\log m = 2$, $\log n = 3$, and 

$\begin{aligned}
f_i : \mathbb{F}^2 &\to \mathbb{F} \\
(X_1, X_2) &\mapsto \sum_{y_1 \in \{0, 1 \}}\sum_{y_2 \in \{0, 1 \}}\sum_{y_3 \in \{0, 1 \}} \widetilde{M_i}((X_1, X_2), (y_1, y_2, y_3)) \cdot \widetilde{z}(y_1, y_2, y_3)
\end{aligned}$.


> Note that a matrix $M$ can be seen as a function $M : \{0,1\}^{\log m} \times \{0,1\}^{\log n} \to \mathbb{F}$, since for each row $m_i$ and column $n_j$ we can derive the element $M(m_i, n_j)$ from the matrix $M$. 
> As in the HyperNova paper, we will denote $s = \log m$ and $s' = \log n$.

The multilinear extensions $\widetilde{M_i}$ of $M_i$ and $\widetilde{z}$ of $z$ are defined as 

$\begin{aligned}
\widetilde{M_i}(X, Y) &:= \sum_{x \in \{0, 1 \}^{s}} \sum_{y \in \{0, 1 \}^{s'}} M_i(x, y) \cdot \widetilde{eq}(x, X) \cdot \widetilde{eq}(y, Y)
\end{aligned}$

$\widetilde{z}(Y) := \sum_{y \in \{0, 1 \}^{s'}} z(y) \cdot \widetilde{eq}(y, Y)$.

Setting $s= \log m = \log 4 = 2, s'= \log n = \log 8 = 3$ as in our example:

$$
\begin{aligned}
\widetilde{M_i}((X_1, X_2), (Y_1, Y_2, Y_3)) := &\sum_{x_1 \in \{0, 1 \}}\sum_{x_2 \in \{0, 1 \}} \\
& \sum_{y_1 \in \{0, 1 \}} \sum_{y_2 \in \{0, 1 \}} \sum_{y_3 \in \{0, 1 \}} M_i((x_1, x_2), (y_1, y_2, y_3)) \cdot \widetilde{eq}((x_1, x_2), (X_1, X_2)) \cdot \widetilde{eq}((y_1, y_2, y_3), (Y_1, Y_2, Y_3))
\end{aligned}
$$

$$
\widetilde{z}((Y_1, Y_2, Y_3)) := \sum_{y_1 \in \{0, 1 \}}\sum_{y_2 \in \{0, 1 \}}\sum_{y_3 \in \{0, 1 \}} z((y_1, y_2, y_3)) \cdot \widetilde{eq}((y_1, y_2, y_3), (Y_1, Y_2, Y_3))
$$


```python
# From-binary-to-decimal polynomials
row = x1 + 2*x2
col = y1 + 2*y2 + 4*y3

def Mi_linear(Mi):
    return sum([
            sum([
                sum([
                    sum([
                        sum([
                            Mi[Integer(row(x1=x1, x2=x2))][Integer(col(y1=y1,y2=y2,y3=y3))] * eqx(x1=x1,x2=x2,x11=x11,x22=x22) * eqy(y1=y1, y11=y11, y2=y2, y22=y22, y3=y3, y33=y33)
                        for y3 in [0,1]])
                    for y2 in [0,1]])
                for y1 in [0,1]])
            for x2 in [0,1]])
         for x1 in [0,1]])
```



```python
def z_linear(zi):
    return sum([
                sum([
                    sum([
                        zi[Integer(col(y1=y1,y2=y2,y3=y3))]* eqy(y1=y1, y11=y11, y2=y2, y22=y22, y3=y3, y33=y33)
                    for y3 in [0,1]])
                for y2 in [0,1]])
            for y1 in [0,1]])
```

Thus the multilinear extension $f_i$ of our matrix-vector product $M \cdot z$ is

$
f_i((X_1, X_2)) = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((X_1, X_2), y) \cdot \widetilde{z}(y)
$


```python
def Mi_z_prod(Mi, zi):
        return sum([
                sum([
                    sum([
                        Mi_linear(Mi)(y11=y1,y22=y2,y33=y3) * z_linear(zi)(y11=y1,y22=y2,y33=y3)
                    for y3 in [0,1]])
                for y2 in [0,1]])
            for y1 in [0,1]])
```

The CCS relation we want to check, 

$1 \cdot (M_1 \cdot z \circ M_2 \cdot z) + (-1) \cdot (M_3 \cdot z) = \vec{0}$

is thus turned into a polynomial equation

$\begin{aligned}
G((X_1, X_2)) := & 1 \cdot (\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}(y)) \\  + & (-1) \cdot (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((X_1, X_2), y) \cdot \widetilde{z}(y)) = 0
\end{aligned}$


```python
G = Mi_z_prod(M1, z1) * Mi_z_prod(M2, z1) - Mi_z_prod(M3, z1)
G
```


<!-- <span style="background-color:green">
    21*x11^2*x22^2 - 17*x11^2*x22 - 15*x11*x22^2 + 2*x11^2 + 11*x11*x22 - 2*x11
</span> -->

    21*x11^2*x22^2 - 17*x11^2*x22 - 15*x11*x22^2 + 2*x11^2 + 11*x11*x22 - 2*x11



The prover wants to prove that $G((x_1, x_2)) = 0$ for all $x_1, x_2 \in \{0,1\}$ using the sum-check. 

That is $G((0,0))= G((0,1))= G((1,0))= G((1,1))=0$.

As expected, we extend the multivariate polynomial $G : \{0,1\} \times \{0,1\} \to \mathbb{F}$ of degree $2$ into a multilinear polynomial 


$\begin{aligned}
h : \mathbb{F} \times \mathbb{F} &\to \mathbb{F} \\
((X_1, X_2)) &\mapsto \sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} G((x_1, x_2)) \cdot \widetilde{eq}((X_1, X_2), (x_1, x_2)) \\
&=  G((0, 0)) \cdot \widetilde{eq}((X_1, X_2), (0, 0)) \\
&+ G((0, 1)) \cdot \widetilde{eq}((X_1, X_2), (0, 1)) \\
&+ G((1, 0)) \cdot \widetilde{eq}((X_1, X_2), (1, 0)) \\
&+ G((1,1)) \cdot \widetilde{eq}((X_1, X_2), (1, 1)) \\
&= 0
\end{aligned}$

As we did earlier, now $h(X)$ is a multilinear extension that encodes the $4$ evaluations ($\{(0,0), (0,1), (1,0), (1,1) \}$) of $G$ into its coefficients, so it is uniquely determined by $4$ evaluations (i.e. a polynomial of $n$ coefficients is of degree $n - 1$, thus uniquely defined by $n$ evaluations). 

Since $\forall x_1, x_2 \in \{0,1\}. h((x_1, x_2)) = G((x_1, x_2)) = 0$, then $h$ must necessarily be the zero polynomial $h = 0$.


```python
h = sum([
        sum([
            G(x11=x11, x22=x22) * eqx(x11=x11, x22=x22)
            for x22 in [0,1]])
     for x11 in [0,1]])

h
```




    0



> Note that there would be no harm in doing such transformation if $G$ were already multilinear.
> If a polynomial $G \in \mathbb{F}[x_1,..., x_s]$ is multilinear, then $G(X) = \sum_{x\in \{0,1\}^s} G(x) \cdot \widetilde{eq}(x, X)$
> You can check lemma 6 of HyperNova for a proof.

By the Schwartz-Zippel lemma, we can evaluate 

$h((X_1, X_2)) = \sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}}  G((x_1, x_2)) \cdot \widetilde{eq}((X_1, X_2), (x_1, x_2)) = 0$ 

at a random point $\beta := (\beta_1, \beta_2) \in \mathbb{F}^2$ to prove that $h$ is indeed the zero polynomial. 

That is, if

$\begin{aligned}
h((\beta_1, \beta_2)) &= \sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}}  G((x_1, x_2)) \cdot \widetilde{eq}((\beta_1, \beta_1), (x_1, x_2)) \\
&= G((0, 0)) \cdot \widetilde{eq}((\beta_1, \beta_2), (0, 0)) \\
&+ G((0, 1)) \cdot \widetilde{eq}((\beta_1, \beta_2), (0, 1)) \\
&+ G((1, 0)) \cdot \widetilde{eq}((\beta_1, \beta_2), (1, 0)) \\
&+ G((1,1)) \cdot \widetilde{eq}((\beta_1, \beta_2), (1, 1)) \\
&= 0
\end{aligned}$

then $h(X_1, X_2) = 0$ with high probability.


```python
beta1 = k.random_element()
beta2 = k.random_element()

(beta1, beta2)
```




    (57, 23)



> Note that $\widetilde{eq}((\beta_1, \beta_2), (x_1, x_2)) = ((1-\beta_1)(1-x_1) + \beta_1 x_1) \cdot ((1-\beta_2)(1-x_2) + \beta_2 x_2)$ may not be zero if $\beta_1, \beta_2 \notin \{0,1\}$.

Let $Q(X_1, X_2) := G((X_1, X_2)) \cdot \widetilde{eq}((\beta_1, \beta_2), (X_1, X_2))$. 


```python
Q = G * eqx(x1=beta1,x2=beta2)
Q
```




    28*x11^3*x22^3 + 22*x11^3*x22^2 - 16*x11^2*x22^3 + 13*x11^3*x22 + 34*x11^2*x22^2 + 26*x11*x22^3 - 23*x11^3 + 29*x11^2*x22 - 43*x11*x22^2 - 38*x11^2 + 8*x11*x22 - 40*x11




> To help us refer to the different sum-checks conceptually, we give them different names:
- **Outer sum-check**: $0 = G(x)$ for all $x \in \{0,1\}^2$.
- **Inner sum-check**: $T_j = \sum_{y\in \{0,1\}^{3}} \widetilde{M}_j(r,y) \cdot \widetilde{z}(y)$

### Outer sum-check

The prover engages with the verifier in the following sum-check:

$\sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} Q(x_1, x_2) = 0$

which implies that $G((x_1, x_2)) = 0$ for all $x_1, x_2 \in \{0,1\}$.


```python
sum([ 
    sum([ Q(x11=x1, x22=x2) for x2 in [0,1]])
for x1 in [0,1]]) == 0
```




    True



#### Round 1

The prover $P$ sends the verifier $V$ a univariate polynomial $s_1(X_1)$ claiming to be equal to $Q_1(X_1) := \sum_{x_2 \in \{0,1\}} Q(X_1, x_2)$. That is, we keep the first variable unbound while summing up the values over the boolean hypercube. 


```python
Q1 = sum([ Q(x22=x2) for x2 in [0,1]])
s1 = Q1

s1
```




    17*x11^3 - 29*x11^2 + 12*x11



The verifier first checks that $s_1(0) + s_1(1)$ matches the expected result, i.e. $s_1(0) + s_1(1) = 0$.


```python
s1(x11=0) + s1(x11=1) == 0
```




    True



Then the verifier checks $s_1 = Q_1$ by checking that $Q_1$ and $s_1$ agree at a random point $r_1$ (Schwartz-Zippel lemma).


```python
r1 = k.random_element()
r1
```




    84



The verifier can compute directly $s_1(r_1)$ but doesn't know what $Q_1$ is, so the check $s_1 = Q_1$ must be done recursively.

#### Round 2

The new claim is that $s_1(r_1) := \sum_{x_2 \in \{0,1\}} Q(r_1, x_2)$, so $P$ sends $V$ a univariate $s_2(X_2)$ which he claims to be equal to  $Q_2(X_2) := Q(r_1, X_2)$.


```python
Q2 = Q(x11=r1)
s2 = Q2

s2
```




    -18*x22^3 + 37*x22^2 + 27*x22 - 20



The verifier first checks that $s_1(r_1)$ is indeed $s_2(0) + s_2(1)$


```python
s2(x22=0) + s2(x22=1) == s1(x11=r1)
```




    True



Then the verifier sends a random challenge $r_2$ to check that $s_2(r_2) = Q_2(r_2)$.


```python
r2 = k.random_element()
r2
```




    31



There is no more need for recursion, since the verifier can now evaluate 

$\begin{aligned}
Q_2(r_2) = Q((r_1, r_2)) =& \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \cdot G((r_1, r_2)) \\
=& \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \cdot ((\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y)) \\  - & \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((r_1, r_2), y) \cdot \widetilde{z}(y))
\end{aligned}$

However, the verifier doesn't want to compute the inner sums

$\sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y)$

for $i \in \{1,2,3\}$ by himself, so he engages in further sum-checks with the prover.

### Batching inner sum-checks

The prover is asked to compute the inner sum-checks

$\begin{aligned}
T_i &= \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y) \\
&= \sum_{y_1 \in \{0, 1 \}} \sum_{y_2 \in \{0, 1 \}} \sum_{y_3 \in \{0, 1 \}} \widetilde{M_i}((r_1, r_2), (y_1, y_2, y_3)) \cdot \widetilde{z}((y_1, y_2, y_3)) \\
\end{aligned}$

and to send $T_i$ to the verifier for $i \in \{1,2,3\}$ to sum-check it.


```python
def Ti_generator(Mi, zi):
    return sum([
        sum([
            sum([
                Mi_linear(Mi)(x11=r1, x22= r2, y11=y1,y22=y2,y33=y3) * z_linear(zi)(y11=y1,y22=y2,y33=y3)
            for y3 in [0,1]])
        for y2 in [0,1]])
    for y1 in [0,1]])

T1 = Ti_generator(M1, z1)
T2 = Ti_generator(M2, z1)
T3 = Ti_generator(M3, z1)
T1, T2, T3
```




    (33, -10, 10)



However, instead of engaging in separate sum-checks $T_i = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y)$ for each $i \in \{1,2,3\}$, the prover will batch them using a random element $\alpha$ generated by the verifier.

$\begin{aligned}
T_1 + \alpha \cdot T_2 + \alpha^2 \cdot T_3 =& \sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y) \\ 
+& \alpha \cdot \sum_{y \in \{0, 1 \}^3} \widetilde{M_2}((r_1, r_2), y) \cdot \widetilde{z}(y) \\
+& \alpha^2 \cdot \sum_{y \in \{0, 1 \}^3} \widetilde{M_3}((r_1, r_2), y) \cdot \widetilde{z}(y) \\
=& \sum_{y \in \{0, 1 \}^3} (\widetilde{M_1}((r_1, r_2), y) + \alpha \cdot \widetilde{M_2}((r_1, r_2), y) \\
+& \alpha^2 \cdot \widetilde{M_3}((r_1, r_2), y)) \cdot \widetilde{z}(y)
\end{aligned}$

Which proves with high probability that all $T_1, T_2, T_3$ are correctly computed from $\sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y)$.


```python
alpha = k.random_element()
alpha
```




    78




```python
T = T1 + alpha * T2 + alpha^2 * T3
T
```




    -2



#### Round 1

The prover $P$ sends the verifier $V$ a univariate polynomial $q_1(Y_1)$ to be equal to 

$\begin{aligned}
f_1(Y_1) &:= \sum_{y_2 \in \{0,1\}}\sum_{y_3 \in \{0,1\}} (\widetilde{M_1}((r_1, r_2), (Y_1, y_2, y_3)) \\
& \quad \quad \quad \quad \quad \quad \quad + \alpha \cdot \widetilde{M_2}((r_1, r_2), (Y_1, y_2, y_3)) \\
& \quad \quad \quad \quad \quad \quad \quad + \alpha^2 \cdot  \widetilde{M_3}((r_1, r_2), (Y_1, y_2, y_3))) \cdot \widetilde{z}((Y_1, y_2, y_3)) \\
\end{aligned}$ 

That is, we keep the first variable unbound while summing up the values over the boolean hypercube.


```python
f1 = sum([
        sum([
            Mi_linear(M1)(x11=r1, x22= r2, y22=y2,y33=y3) * z_linear(z1)(y22=y2,y33=y3) + 
            alpha * Mi_linear(M2)(x11=r1, x22= r2, y22=y2,y33=y3) * z_linear(z1)(y22=y2,y33=y3) +
            alpha^2 * Mi_linear(M3)(x11=r1, x22= r2, y22=y2,y33=y3) * z_linear(z1)(y22=y2,y33=y3)
        for y3 in [0,1]])
    for y2 in [0,1]])
q1 = f1

q1
```




    -2*y11^2 + 16*y11 - 8



The verifier first checks that $q_1(0) + q_1(1)$ matches the expected result, i.e. $q_1(0) + q_1(1) = T$.


```python
q1(y11=0) + q1(y11=1) == T
```




    True



Then the verifier checks $q_1 = f_1$ by checking that $f_1$ and $q_1$ agree at a random point $r'_1$ (Schwartz-Zippel lemma).


```python
r11 = k.random_element()
r11
```




    23



The verifier can compute directly $q_1(r'_1)$ but doesn't know what $f_1$ is, so the check $q_1 = f_1$ must be done recursively.

#### Round 2

The new claim is that 

$\begin{aligned}
q_1(r'_1) &= \sum_{y_2 \in \{0,1\}}\sum_{y_3 \in \{0,1\}} (\widetilde{M_1}((r_1, r_2), (r'_1, y_2, y_3))  \\
& \quad \quad \quad \quad \quad \quad + \alpha \cdot \widetilde{M_2}((r_1, r_2), (r'_1, y_2, y_3)) \\
& \quad \quad \quad \quad \quad \quad + \alpha^2 \cdot \widetilde{M_3}((r_1, r_2), (r'_1, y_2, y_3))) \cdot \widetilde{z}((r'_1, y_2, y_3)) \\
\end{aligned}$ 

so $P$ sends $V$ a univariate $q_2(Y_2)$ claimed to be equal to  

$\begin{aligned}
f_2(Y_2) &:= \sum_{y_3 \in \{0,1\}} (\widetilde{M_1}((r_1, r_2), (r'_1, Y_2, y_3)) \\
& \quad \quad \quad \quad + \alpha \cdot  \widetilde{M_2}((r_1, r_2), (r'_1, Y_2, y_3))  \\
& \quad \quad \quad \quad + \alpha^2 \cdot \widetilde{M_3}((r_1, r_2), (r'_1, Y_2, y_3))) \cdot \widetilde{z}((r'_1, Y_2, y_3)) \\
\end{aligned}$ 


```python
f2 = sum([
        Mi_linear(M1)(x11=r1, x22= r2, y11=r11, y33=y3) * z_linear(z1)(y11=r11,y33=y3) + 
        alpha * Mi_linear(M2)(x11=r1, x22= r2, y11=r11,y33=y3) * z_linear(z1)(y11=r11,y33=y3) +
        alpha^2 * Mi_linear(M3)(x11=r1, x22= r2, y11=r11,y33=y3) * z_linear(z1)(y11=r11,y33=y3)
    for y3 in [0,1]])
q2 = f2

q2
```




    27*y22^2 + 9*y22 + 37



The verifier first checks that $q_1(r'_1)$ is indeed $q_2(0) + q_2(1)$ 


```python
q2(y22=0) + q2(y22=1) == q1(y11=r11)
```




    True



Then sends a random challenge $r'_2$ to check that $q_2(r'_2) = f_2(r'_2)$.


```python
r22 = k.random_element()
r22
```




    96



#### Round 3

Finally, the prover claims that 

$\begin{aligned}
q_2(r'_2) &= \sum_{y_3 \in \{0,1\}} (\widetilde{M_1}((r_1, r_2), (r'_1, r'_2, y_3))  \\
& \quad \quad \quad \quad + \alpha \cdot \widetilde{M_2}((r_1, r_2), (r'_1, r'_2, y_3))  \\
& \quad \quad \quad \quad + \alpha^2 \cdot \widetilde{M_3}((r_1, r_2), (r'_1, r'_2, y_3))) \cdot \widetilde{z}((r'_1, r'_2, y_3)) \\
\end{aligned}$ 

so $P$ sends $V$ a univariate $q_3(Y_2)$ claimed to be equal to  

$\begin{aligned}
f_3(Y_3) &:= (\widetilde{M_1}((r_1, r_2), (r'_1, r'_2, Y_3)) \\
&+ \alpha \cdot \widetilde{M_2}((r_1, r_2), (r'_1, r'_2, Y_3))  \\
&+ \alpha^2 \cdot \widetilde{M_3}((r_1, r_2), (r'_1, r'_2, Y_3))) \cdot \widetilde{z}((r'_1, r'_2, Y_3)) \\
\end{aligned}$ 


```python
f3 = Mi_linear(M1)(x11=r1, x22= r2, y11=r11, y22=r22) * z_linear(z1)(y11=r11,y22=r22) + alpha * Mi_linear(M2)(x11=r1, x22= r2, y11=r11,y22=r22) * z_linear(z1)(y11=r11,y22=r22) + alpha^2 * Mi_linear(M3)(x11=r1, x22= r2, y11=r11,y22=r22) * z_linear(z1)(y11=r11,y22=r22)

q3 = f3

q3
```




    -45*y33^2 - 33*y33 + 19



The verifier first checks that $q_2(r'_2)$ is indeed $q_3(0) + q_3(1)$


```python
q3(y33=0) + q3(y33=1) == q2(y22=r22)
```




    True



Then, using a random value $r'_3$, he can compute on his own $f_3(r'_3)$ and check that $q_3(r'_3)$ is indeed equal to $f_3(r'_3)$, thus $q_3 = f_3$.


```python
r33 = k.random_element()
r33
```




    84



That is, that $f_3(r'_3) = \widetilde{M_i}((r_1, r_2), (r'_1, r'_2, r'_3)) \cdot \widetilde{z}((r'_1, r'_2, r'_3))$, which the verifier can easily compute.


```python
c1 = Mi_linear(M1)(x11=r1, x22= r2, y11=r11, y22=r22,y33=r33) * z_linear(z1)(y11=r11,y22=r22,y33=r33) + alpha * Mi_linear(M2)(x11=r1, x22= r2, y11=r11,y22=r22,y33=r33) * z_linear(z1)(y11=r11,y22=r22,y33=r33) + alpha^2 * Mi_linear(M3)(x11=r1, x22= r2, y11=r11,y22=r22,y33=r33) * z_linear(z1)(y11=r11,y22=r22,y33=r33)

c1 == q3(y33=r33)
```




    True



Thus, the verifier has checked that

$\begin{aligned}
T_1 + \alpha \cdot T_2 + \alpha^2 \cdot T_3 =& \sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y) \\ 
+& \alpha \cdot \sum_{y \in \{0, 1 \}^3} \widetilde{M_2}((r_1, r_2), y) \cdot \widetilde{z}(y) \\
+& \alpha^2 \cdot \sum_{y \in \{0, 1 \}^3} \widetilde{M_3}((r_1, r_2), y) \cdot \widetilde{z}(y)
\end{aligned}$

so he can trust that all $T_1, T_2, T_3$ derive from $\sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y)$, and use them in the remaining step of the outer sum-check.

### Final check

We were left in the outer sum-check with the verifier wanting to compute

$\begin{aligned}
s_2(r_2) = Q_2(r_2) =& Q((r_1, r_2)) \\
=& \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \cdot G((r_1, r_2)) \\
=& \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \\
\cdot & ((\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y)) \\  - & \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((r_1, r_2), y) \cdot \widetilde{z}(y))
\end{aligned}$

However, he needed help from the prover to compute

$T_i := \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y)$

After batching the inner sum-checks into a single grand inner sum-check, the verifier has now proof of $T_1, T_2$ and $T_3$, so can easily compute

$\begin{aligned}
Q((r_1, r_2)) =& \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \cdot G((r_1, r_2)) \\
=& \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \\
&\cdot ((\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y)) \\
&- \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((r_1, r_2), y) \cdot \widetilde{z}(y)) \\
=& \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \cdot (T_1 \cdot T_2 - T_3)
\end{aligned}$




```python
Q(x11=r1, x22=r2) == (T1 * T2 - T3) * eqx(x11=r1, x22=r2, x1=beta1, x2=beta2)
```




    True



Which proves the original claim that the CCS relation for the Fibonacci example $1 \cdot (M_1 \cdot z \circ M_2 \cdot z) + (-1) \cdot (M_3 \cdot z) = \vec{0}$ holds.

That is,

$\begin{aligned}
Q((r_1, r_2)) &= \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \cdot (T_1 \cdot T_2 - T_3) \\
&\overset{w.h.p}{\Longrightarrow} \sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} Q(x_1, x_2) = 0 \\
&\Longrightarrow \forall x_1, x_2 \in \{0,1\}. G((x_1, x_2)) = 0 \\
&\Longrightarrow 1 \cdot (M_1 \cdot z \circ M_2 \cdot z) + (-1) \cdot (M_3 \cdot z) = \vec{0}
\end{aligned}$

> There are two ways in which a verifier may evaluate these multi-linear extension of CCS matrices: 
> 1. if matrices are *structured* the verifier evaluates them in logarithmic time
> 2. if matrices are *unstructured*, the prover can prove evaluations of MLE of sparse matrices in linear time using memory checking techniques (see Spark compiler in the [Spartan paper](https://eprint.iacr.org/2019/550.pdf)).

### Conclusion

We made it! To recap, we have shown in this article how:

**1.** Any polynomial equation can be transformed into a (bunch of) sum-checks, by leveraging the properties of multilinear polynomials and the Schwartz-Zippel lemma.

**2.** A CCS relation can be transformed into a sum of a multilinear polynomial over the boolean hypercube and proved using the sum-check protocol.

During the outer sum-check
$\sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} Q(x_1, x_2) = 0$ the verifier was eventually be confronted to compute $Q(r)$ for some $r \in \mathbb{F}^{2}$. 
    
Since $Q(r) = G(r) \cdot \widetilde{eq}((\beta_1, \beta_2), r)$ the verifier had to compute $\sum_{y\in \{0,1\}^{3}} \widetilde{M}_j(r,y) \cdot \widetilde{z}(y)$ for $j \in \{1,2,3\}$. Thus he asked for help to the prover, and engaged in a batched inner sum-check.

**The main idea of HyperNova will be to fold or delay the computation of any inner sum-check**. This will be explored in the next article.

Thanks for reading!
