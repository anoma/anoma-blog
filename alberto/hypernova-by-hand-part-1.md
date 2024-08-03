# HyperNova by hand

## Part 1: Sum-check for [CCS](https://eprint.iacr.org/2023/552.pdf) instances

The [sum-check protocol](https://dl.acm.org/doi/pdf/10.1145/146585.146605) is like one of those magic tricks that, despite having been exposed to how it works, it still makes your mind do some acrobatics every time you see it applied.

Furthermore many problems can be transformed into instances of Sumcheck, making this amazing algorithm surprisingly applicable. 

Since the sum-check lies at the core of the [HyperNova](https://eprint.iacr.org/2023/573.pdf)'s folding techniques, we will dive first into its details so that we can omit them later on.

### Transforming any check into a sumcheck 

The goal of the sum-check is to check that an untrusted prover has computed the following equation correctly, where $f \in K[X_1,...,X_l]$ is a multivariate polynomial:
$\begin{align*}
T &= \sum_{x \in \{0,1\}^l} f(x) \\ 
&= \sum_{x_1 \in \{0,1\}} \sum_{x_2 \in \{0,1\}} ... \sum_{x_l \in \{0,1\}} f(x_1, x_2, ..., x_l)
\end{align*}$
After $l$ rounds, the protocol allows the verifier to check $f(r_1,...,r_l) = c$, for some random $r_i \in \mathbb{F}$, which with high probability implies the original equation.

Say we have a polynomial $f$ encoding a vector of evaluations $v = [v_1,..., v_{n}]$ such that for all $x_i$ in some subdomain $H$, $f(x_i) = v_i$. In our setting, a prover wants to convince a verifier that this is the case (i.e. $\forall x_i \in H. f(x_i) = 0$). This is known as a zero-check. 

Note that we can always transform the check $f(x_i) = v_i$ into a zero-check since $f(x_i) - v_i = 0$.

For example, in vanilla Plonk, $f$ is a univariate polynomial that encodes an execution trace and $H$ is a subset of the roots of unity of some prime field (e.g. $H := \{\omega^1,\omega^2,\omega^3,\omega^4,\omega^5,\omega^6,\omega^7,\omega^8\}$).

In HyperPlonk (a variant of Plonk that transforms the zero-checks in the protocol into sumchecks) $H$ becomes a boolean hypercube $\{0,1\}^l$ (i.e. all the $l$ combinations of zeroes and ones), and $f$ a multivariate polynomial of some degree $d$ such that $\forall x \in \{0,1\}^l. f(x) = 0$.
For example, if $l$ is set to 3, then $\{0,1\}^3 := \{(0,0,0), (0,0,1), (0,1,0), (0,1,1), (1,0,0), (1,0,1), (1,1,0), (1,1,1)\}$.

To apply the sumcheck protocol, we need a statement of the form $\sum_{x\in \{0,1\}^l} f(x) = 0$.

It is clear that if $\forall x\in \{0,1\}^l. f(x) = 0$ then $\sum_{x\in \{0,1\}^l} f(x) = 0$, but the converse doesn't necessarily hold. For example, $f((0,0,1)) = -1$, $f((0,1,0)) = 1$ and $f(x) = 0$ otherwise makes $\sum_{x\in \{0,1\}^l} f(x) = 0$ but $f(x) \neq 0$ for some $x\in \{0,1\}^l$.

To overcome this, we define a different multilinear polynomial
$\widetilde{eq} : \mathbb{F}^l \times \mathbb{F}^l \to \mathbb{F}$ with $\widetilde{eq}(X_1, X_2) := 1$ if $X_1 = X_2$ where $X_1, X_2 \in \{0,1\}^l$ and $\widetilde{eq}(X_1, X_2) := 0$ if $X_1 \neq X_2$ where $X_1, X_2 \in \{0,1\}^l$. That is
$\widetilde{eq}(X_1, X_2) := \prod_{j=1}^l ((1-X_{1_j})(1-X_{2_j}) + X_{1_j} X_{2_j})$. We use a tilde \~ over a function $g$ to emphasise that $\widetilde{g}$ is a multilinear polynomial.

The new polynomial $\widetilde{eq}$ together with the sumcheck protocol allows us to get the desired zero-check, $\forall x \in H. f (x) = 0$, as follows:

We define a new polynomial $h(X) := \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, X)$, where $X \in \mathbb{F}^l$. Note that $X$ is a variable while $x$ is not. $h$ is known as a multilinear extension of $f$ in the boolean hypercube, since $\forall X\in \{0,1\}^l. h(X) = f(X)$. For example, if $X = (1,0,1)$, then $h((1,0,1)) = \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, (1,0,1)) = f((1,0,1))$.

Since $\forall x\in \{0,1\}^l. f(x) = 0$, and $\forall X\in \{0,1\}^l. h(X)=f(X)$, then $\forall X\in \{0,1\}^l. h(X) = 0$. The main difference between $f$ and $h$ is that $f$ is a *multivariate* polynomial of (potentially high) degree $d$, whereas $h$ is a multilinear polynomial.

We know that a univariate polynomial $g$ of $k>1$ coefficients in uniquely determined by $k$ evaluations, and it is of degree $k-1$. Similarly, a multilinear polynomial $h$ of $k$ coefficients is uniquely determined by $k$ evaluations. In this case, $h(Y) := \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, Y)$ has $2^l$ coefficients (most of them zero) and so it is uniquely determined by $2^l$ evaluations. Since $\forall \{0,1\}^l. h(Y) = f(Y) = 0$, then $h$ must necessarily be the zero polynomial, $h = 0$.

The verifier has reduced his task to checking that $h$ is indeed the zero polynomial, which is a simpler problem. By the Schwartz-Zippel lemma, we can verify that $h$ is the zero polynomial with high probability by evaluating $h$ at a random point $r \in \mathbb{F}^l$. That is, $h(r) := \sum_{x \in \{0,1\}^l} f(x) \cdot \widetilde{eq}(x, r)$ must be equal to zero. Here is where we use the sum-check protocol.

So if $h(r) = 0$, this implies with high probability that $h = 0$, which implies that $\forall Y \in \{0,1\}^l. h(Y) = 0$, which implies that $\forall x\in \{0,1\}^l. f(x) = 0$, thus proving the original statement with high probability (w.h.p.). In short,

$h(r) = 0 \overset{w.h.p}{\Longrightarrow} h = 0 \Longrightarrow \forall Y \in \{0,1\}^l . h(Y) = 0 \Longrightarrow \forall x\in \{0,1\}^l. f(x) = 0$. 


## Example: Fibonacci++

CCS ([Customisable Constraint System](https://eprint.iacr.org/2023/552.pdf)) relations are a generalisation of R1CS relations and can be represented as follows:
$\begin{equation}     \sum_{i=0}^{q-1} c_i \cdot \circ_{j \in S_i} M_j \cdot z = \mathbf{0} \end{equation}$
where $z := (w, x, 1) \in \mathbb{F}^n$, $x \in \mathbb{F}^{l}$ being the public inputs and $w \in \mathbb{F}^{m - l - 1}$ the private inputs.

where:

* $M_j \cdot z$ denotes matrix-vector multiplication,
* $\circ$ denotes the Hadamard product between vectors, and 
* $\mathbf 0$ is an $m$-sized vector with entries equal to the the additive identity $0_{\mathbf F}\in \mathbb{F}$.


Expanded, a CCS equation looks like:
$\begin{equation*}     c_0 \cdot \overbrace{(M_{j_{0}} \cdot z \circ ... \circ M_{j_{|{S_{0}}|-1}} \cdot z)}^{j_i \in S_0} + ... + c_{q-1} \cdot \overbrace{(M_{j_{0}} \cdot z \circ ... \circ M_{j_{|{S_{q-1}}|-1}} \cdot z)}^{j_i \in S_{q-1}} = \mathbf{0} \end{equation*}$.

The following recurrence relation will help us to illustrate the workings sum-check protocol for CCS instances as is used in [HyperNova](https://eprint.iacr.org/2023/573.pdf), and serves us as a good example to fold.

```rust
// i-th iteration
f(x_2, x_1, y_2, y_1) {
    x = x_1 + x_2 // Fibonacci
    y = y_1 * y_2 // Multiplicative Fibonacci
    t = x * y     // Fibonacci x (Multiplicative Fibonacci)
    (x, y, t)
}
```

We want to prove the result of iterating $n$ times over $f$, starting with some initial values, so first we need to arithmetise this statement (e.g. using CCS). We will see later how folding is achieved in HyperNova. For now, we will focus on proving a single iteration, in particular, starting from the initial values $x_2 = 0, x_1 = 1, y_2=2, y_1=3$, the second iteration yields $x_2=1, x_1=1, x=2, y_2=3, y_1=6, y=18, t=36$.

This combined recurrence relation can easily be represented as an R1CS relation, that is, $(A \cdot z) \circ (B\cdot z) = (C \cdot z)$, where:
- $z := [x_2, x_1, x, y_2, y_1, y, t, 1] = [1, 1, 2, 3, 6, 18, 36, 1]$
- $A := \begin{bmatrix}   1 & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}$
- $B := \begin{bmatrix}   0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 \\   0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}$
- $C := \begin{bmatrix}   0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}$

That is,
$\begin{align}  
\overbrace{\begin{bmatrix}   1 & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}  }^A 
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z \circ &
\overbrace{\begin{bmatrix}   0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 \\   0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}}^B  
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z \\
=& \overbrace{\begin{bmatrix}   0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}}^C 
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z \end{align}$

We have a particular interest in having our rows and columns of size $2^m$ for some $m$, since the sum-check protocol runs over the boolean hypercube. In this case, $m = 4 = 2^2$ is the number of constraints (i.e. rows) and $n = 8 = 2^3$ is the number of witnesses (i.e. columns) as well as the size of the vector $z$. Note that we have added a dummy row is $[0 ,..., 0]$ for $A, B, C$ (it could be any other vector as long as the R1CS relation holds trivially).


Any R1CS can be stated as a CCS relation. In our example, this translates to $1 \cdot (M_1 \cdot z \circ M_2 \cdot z) + (-1) \cdot (M_3 \cdot z) = \mathbf{0}$. Notice that is an R1CS relation $(A \cdot z) \circ (B\cdot z) = (C \cdot z)$.

A CCS relation is of the form $S_{CCS} = (m, n, N, l, t, q, d, [M_1, ..., M_t], [S_1,...,S_q], [c_1, ..., c_q])$, where $n, m$ are the rows and columns of the matrices $M_i$. 

In our case, $m = 4$ and $n = 8$ (as seen above), are the rows and columns of the $t=3$ matrices $M_1, M_2, M_3$.  $\{M_1, M_2\}$ are multiplied and added to $\{M_3\}$, so $S_1 = \{1, 2\}, S_2 = \{3\}$. Since there are two addends $S_1$ and $S_2$, $q =2$. The other parameters are less relevant for our exposition but worth mentioning for completeness: 
- $N = 10$ is the number of non-zero entries in $M_i$,
- $d=2$ is the upper bound of the cardinality of each $S_i$.
- $l=8$ is the number of public inputs (we'll see how to achieve zero-knowledge later)

We want to turn this matrix-vector problem statement into a sum over the boolean hypercube. We begin by creating multilinear extensions $\widetilde{M_i}$ of $M_i$ and $\widetilde{z}$ of $z$ such that the multilinear polynomial $f_i : \mathbb{F}^{\log m} \to \mathbb{F}$, $f_i(X) := \sum_{y \in \{0, 1 \}^{\log n}} \widetilde{M_i}(X, y) \cdot \widetilde{z}(y)$,
is a multilinear extension of our matrix-vector product $M_i \cdot z$. 

Since $m=2^2$ and $n=8 = 2^3$, then $\log m = 2$, $\log n = 3$, and $f_i : \mathbb{F}^2 \to \mathbb{F}$, $f_i(X_1, X_2)= \sum_{y_1 \in \{0, 1 \}}\sum_{y_2 \in \{0, 1 \}}\sum_{y_3 \in \{0, 1 \}} \widetilde{M_i}((X_1, X_2), (y_1, y_2, y_3)) \cdot \widetilde{z}(y_1, y_2, y_3)$. 

Note that a matrix $M$ can be seen as a function $M : \{0,1\}^{\log m} \times \{0,1\}^{\log n} \to \mathbb{F}$, since for each row $m_i$ and column $n_j$ we can derive the element $M(m_i, n_j)$ from the matrix $M$. $M$ is isomorphic to $M' : \{0,1\}^{\log (m \cdot n)} \to \mathbb{F}$ and thus can be represented as such (note that $\log (m \cdot n) = \log m + \log n$). In our example, the elements of $M$ are booleans (either $0$ or $1$), but think of them as embedded in $\mathbb{F}$. As in the HyperNova paper, we will denote $s := \log m$ and $s' := \log n$.

Thus the multilinear extension $\widetilde{M_i}$ of $M_i$ is defined as 
$\begin{align*}
\widetilde{M_i}(X, Y) &:= \sum_{x \in \{0, 1 \}^{s}} \sum_{y \in \{0, 1 \}^{s'}} M_i(x, y) \cdot \widetilde{eq}(x, X) \cdot \widetilde{eq}(y, Y)
\end{align*}$

which is equivalent to $\widetilde{M'}(X) := \sum_{x \in \{0, 1 \}^{s + s'}} M'_i(x) \cdot \widetilde{eq}(x, X)$ if $M_i$ were considered as a vector $M'_i$ of size $s+s'$.

On the other hand, $\widetilde{z}(Y) := \sum_{y \in \{0, 1 \}^{s'}} z(y) \cdot \widetilde{eq}(y, Y)$.

In our example, $s=2, s'=3$ and
$\begin{align*}
\widetilde{M_i}((X_1, X_2), (Y_1, Y_2, Y_3)) := &\sum_{x_1 \in \{0, 1 \}}\sum_{x_2 \in \{0, 1 \}} \\
& \sum_{y_1 \in \{0, 1 \}} \sum_{y_2 \in \{0, 1 \}} \sum_{y_3 \in \{0, 1 \}} M_i((x_1, x_2), (y_1, y_2, y_3)) \cdot \widetilde{eq}((x_1, x_2), (X_1, X_2)) \cdot \widetilde{eq}((y_1, y_2, y_3), (Y_1, Y_2, Y_3)) \\
\end{align*}$
$\widetilde{z}((Y_1, Y_2, Y_3)) := \sum_{y_1 \in \{0, 1 \}}\sum_{y_2 \in \{0, 1 \}}\sum_{y_3 \in \{0, 1 \}} z((y_1, y_2, y_3)) \cdot \widetilde{eq}((y_1, y_2, y_3), (Y_1, Y_2, Y_3))$.

The CCS relation we want to check, $1 \cdot (M_1 \cdot z \circ M_2 \cdot z) + (-1) \cdot (M_3 \cdot z) = \mathbf{0}$,
is thus turned into 
$\begin{align*}
G((X_1, X_2)) := & 1 \cdot (\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}(y)) \\  + & (-1) \cdot (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((X_1, X_2), y) \cdot \widetilde{z}(y)) = \mathbf{0}
\end{align*}$

The prover wants to prove that $G((x_1, x_2)) = 0$ for all $x_1, x_2 \in \{0,1\}$ using the sum-check. That is $G((0,0))= G((0,1))= G((1,0))= G((1,1))=0$.

As expected, we extend the multivariate polynomial $G : \{0,1\} \times \{0,1\} \to \mathbb{F}$ of degree 2 into a multilinear polynomial $h : \mathbb{F} \times \mathbb{F} \to \mathbb{F}$: 
$\begin{align}
h((X_1, X_2)) &:= \sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} G((x_1, x_2)) \cdot \widetilde{eq}((X_1, X_2), (x_1, x_2)) \\
&=  G((0, 0)) \cdot \widetilde{eq}((X_1, X_2), (0, 0)) \\
&+ G((0, 1)) \cdot \widetilde{eq}((X_1, X_2), (0, 1)) \\
&+ G((1, 0)) \cdot \widetilde{eq}((X_1, X_2), (1, 0)) \\
&+ G((1,1)) \cdot \widetilde{eq}((X_1, X_2), (1, 1))
\end{align}$

Note that there would be no harm in doing such transformation if $G$ were already multilinear. If a polynomial $G \in \mathbb{F}[x_1,..., x_s]$ is multilinear, then $G(X) = \sum_{x\in \{0,1\}^s} G(x) \cdot \widetilde{eq}(x, X)$ (see lemma 6 of [1] for a proof).

As we did earlier, now $h(X)$ is a multilinear extension that encodes the $4$ evaluations ($\{(0,0), (0,1), (1,0), (1,1) \}$) of $G$ into its coefficients, so it is uniquely determined by $4$ evaluations (i.e. a polynomial of $n$ coefficients is of degree $n - 1$, thus uniquely defined by $n$ evaluations). Since $\forall x_1, x_2 \in \{0,1\}. h((x_1, x_2)) = G((x_1, x_2)) = 0$, then $h$ must necessarily be the zero polynomial $h = 0$.

By the Schwartz-Zippel lemma, we can evaluate $h((X_1, X_2)) = \sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}}  G((x_1, x_2)) \cdot \widetilde{eq}((X_1, X_2), (x_1, x_2)) = 0$ at a random point $\beta := (\beta_1, \beta_2) \in \mathbb{F}^2$ to prove that $h$ is indeed the zero polynomial. That is, if

$\begin{align}
h((\beta_1, \beta_2)) &= \sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}}  G((x_1, x_2)) \cdot \widetilde{eq}((\beta_1, \beta_1), (x_1, x_2)) \\
&= G((0, 0)) \cdot \widetilde{eq}((\beta_1, \beta_2), (0, 0)) \\
&+ G((0, 1)) \cdot \widetilde{eq}((\beta_1, \beta_2), (0, 1)) \\
&+ G((1, 0)) \cdot \widetilde{eq}((\beta_1, \beta_2), (1, 0)) \\
&+ G((1,1)) \cdot \widetilde{eq}((\beta_1, \beta_2), (1, 1)) \\
&= 0
\end{align}$

then $h(X_1, X_2) = 0$ with high probability.

Note that $\widetilde{eq}((\beta_1, \beta_2), (x_1, x_2)) = ((1-\beta_1)(1-x_1) + \beta_1 x_1) \cdot ((1-\beta_2)(1-x_2) + \beta_2 x_2)$ may not be zero if $\beta_1, \beta_2 \notin \{0,1\}$.

Let $Q(X_1, X_2) := G((X_1, X_2)) \cdot \widetilde{eq}((\beta_1, \beta_2), (X_1, X_2))$. We use the sum-check to prove that $\sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} Q(x_1, x_2) = 0$


<!-- TODO: We don't need to do this  -->
<!-- Let's prove that $h(X_1, X_2) = 0$ for all $X_1, X_2 \in \{0,1\}$ now using the sum-check protocol.

The problem statement becomes $\sum_{x_1 \in \{0,1\}} \sum_{x_2 \in \{0,1\}} h((x_1, x_2)) = 0$. -->



- **Round 1**: The prover $P$ sends the verifier $V$ a univariate polynomial $s_1(X_1)$ claiming to be equal to $Q_1(X_1) := \sum_{x_2 \in \{0,1\}} Q(X_1, x_2)$. That is, we keep the first variable unbound while summing up the values over the boolean hypercube. The verifier first checks that $s_1(0) + s_1(1)$ matches the expected result, i.e. $s_1(0) + s_1(1) = 0$ and checks $s_1 = Q_1$ by checking that $Q_1$ and $s_1$ agree at a random point $r_1$ (Schwartz-Zippel lemma). The verifier can compute directly $s_1(r_1)$ but doesn't know what $Q_1$ is, so the check $s_1 = Q_1$ must be done recursively.
- **Round 2 (final)**: The new claim is that $s_1(r_1) := \sum_{x_2 \in \{0,1\}} Q(r_1, x_2)$, so $P$ sends $V$ a univariate $s_2(X_2)$ (again by sending $(0,0,0)$) which he claims to be equal to  $Q_2(X_2) := Q(r_1, X_2)$. The verifier first checks that $s_1(r_1)$ is indeed $s_2(0) + s_2(1)$ and sends a random challenge $r_2$ to check that $s_2(r_2) = Q_2(r_2)$. There is no more need for recursion, since the verifier may now evaluate $Q(r_1, r_2) = Q_2(r_2)$. But how? (Spoiler: another sum-check!)


The verifier has access to the CCS relation $S_{CCS}$, and in particular to $M_1, M_2, M_3$ and $z$ thus he could construct by himself:

$\begin{align*}
G((r_1, r_2)) = & 1 \cdot (\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r_1, r_2),  y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y)) \\  + & (-1) \cdot (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((r_1, r_2), y) \cdot \widetilde{z}(y)) 
\end{align*}$ 

and thus compute $Q((r_1, r_2)) = G((r_1, r_2)) \cdot \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2))$

However, computing $\sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y)$ for $i \in \{1,2,3\}$ is more work than the verifier wishes to do. So he engages in a sum-check protocol with the prover. In particular, the prover computes 

$\begin{align}
T_i &= \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y) \\
&= \sum_{y_1 \in \{0, 1 \}} \sum_{y_2 \in \{0, 1 \}} \sum_{y_3 \in \{0, 1 \}} \widetilde{M_i}((r_1, r_2), (y_1, y_2, y_3)) \cdot \widetilde{z}((y_1, y_2, y_3)) \\
\end{align}$.

- **Round 1**: The prover $P$ sends the verifier $V$ a univariate polynomial $q_1(Y_1)$ to be equal to $f_1(Y_1) := \sum_{y_2 \in \{0,1\}}\sum_{y_3 \in \{0,1\}} \widetilde{M_i}((r_1, r_2), (Y_1, y_2, y_3)) \cdot \widetilde{z}((Y_1, y_2, y_3))$. That is, we keep the first variable unbound while summing up the values over the boolean hypercube. The verifier first checks that $q_1(0) + q_1(1)$ matches the expected result, i.e. $q_1(0) + q_1(1) = T_i$ and checks $q_1 = f_1$ by checking that $f_1$ and $q_1$ agree at a random point $r'_1$ (Schwartz-Zippel lemma). The verifier can compute directly $q_1(r'_1)$ but doesn't know what $f_1$ is, so the check $q_1 = f_1$ must be done recursively.
- **Round 2**: The new claim is that $q_1(r'_1) := \sum_{y_2 \in \{0,1\}}\sum_{y_3 \in \{0,1\}} \widetilde{M_i}((r_1, r_2), (r'_1, y_2, y_3)) \cdot \widetilde{z}((r'_1, y_2, y_3))$, so $P$ sends $V$ a univariate $q_2(Y_2)$ claimed to be equal to  $f_2(Y_2) := \sum_{y_3 \in \{0,1\}}\widetilde{M_i}((r_1, r_2), (r'_1, Y_2, y_3)) \cdot \widetilde{z}((r'_1, y_2, y_3))$. The verifier first checks that $q_1(r'_1)$ is indeed $q_2(0) + q_2(1)$ and sends a random challenge $r'_2$ to check that $q_2(r'_2) = f_2(r'_2)$. 
- **Round 3**: Finally, we check that $q_2(r'_2) := \sum_{y_3 \in \{0,1\}} \widetilde{M_i}((r_1, r_2), (r'_1, r'_2, y_3)) \cdot \widetilde{z}((r'_1, r'_2, y_3))$. $P$ sends $V$ a univariate $q_3(Y_3)$ claimed to be equal to  $f_3(Y_3) := \widetilde{M_i}((r_1, r_2), (r'_1, r'_2, Y_3)) \cdot \widetilde{z}((r'_1, r'_2, Y_3))$. The verifier first checks that $q_2(r'_2)$ is indeed $q_3(0) + q_3(1)$ and using a random value $r'_3$, he can compute on his own $f_3(r'_3)$ and check that $q_3(r'_3)$ is indeed equal to $f_3(r'_3)$, thus $q_3 = f_3$.

After engaging in a sum-check for each 
$T_i = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}(y)$, the verifier then can check 

$\begin{align*}
G((r_1, r_2)) &= 1 \cdot (\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r_1, r_2),  y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((r_1, r_2), y) \cdot \widetilde{z}(y)) \\
& + (-1) \cdot (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((r_1, r_2), y) \cdot \widetilde{z}(y)) \\
&= T_1 \cdot T_2 - T_3
\end{align*}$

And thus compute directly the remaining check in the first sum-check:

$\begin{align*}
s_2(r_2) = Q((r_1, r_2)) &= G((r_1, r_2)) \cdot \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2)) \\
&= (T_1 \cdot T_2 - T_3) \cdot \widetilde{eq}((\beta_1, \beta_2), (r_1, r_2))
\end{align*}$

which in turn verifies that the CCS relation encoding our fibonacci iteration holds.

Note that the verifier can batch the three sum-checks for $T_i$ above into a single sum-check instead using a random linear combination. 




<!-- TODO: Do we need to run the sum-check for each M_1 x z? -->

[1]: HyperNova paper