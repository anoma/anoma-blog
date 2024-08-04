---
title: HyperNova by Hand
category: cryptography
image: media/hypernova.jpeg
excerpt: Building on top of the techniques explored with SuperSpartan in part 1, the aim of this article is to unbundle the folding mechanism of the HyperNova protocol by writing it by hand. There is much wisdom hidden in the details.
---

> *I'd like to thank Nicolas Mohnblatt for brainstorming, discussing and reviewing this article, and for his many shared insights, and to Srinath Setty for providing the inspiration for this work and feedback.*
> *This article wouldn't have been possible without them. All mistakes are my own.*

This article was originally written on a SageMath Jupyter notebook, which can be found [here](https://github.com/Acentelles/blogposts/tree/main/hypernova).

## Folding CCS relations in HyperNova

In [part 1](./superspartan-by-hand.md), we managed to verify the validity of a CCS relation using the sum-check. The goal was to get ourselves familiar with the mechanics of the protocol. In particular, we saw that two sum-checks are run for such a CCS relation, and how the two sum-checks relate.

- **Outer sum-check**: $0 = G(x)$ for all $x \in \{0,1\}^2$.
- **(Batched) inner sum-checks**: $v_j = \sum_{y\in \{0,1\}^{3}} \widetilde{M}_j(r,y) \cdot \widetilde{z}(y)$

The goal of this post is to go beyond a single CCS instance to a folding of many as is done in the HyperNova paper. One of the main insights of folding in HyperNova is that we can accumulate or delay the computation of the inner sum-checks.

## Linearised Committed CCS (LCCCS)

Recall that a *relation* $\mathcal{R}$ in CCS is composed by:
- a *structure* $s := ([M_1, ..., M_t], [S_1,...,S_q], [c_1, ..., c_q])$, plus some other bound parameters such as the number of rows $m$ and columns $n$ of the matrices $M_i$. 
- an *instance*, which consists of public inputs $\times \in \mathbb{F}^l$ and private inputs $\omega \in \mathbb{F}^m$.

that satisfies that $(s, \times, \omega) \in \mathcal{R}_{CCS}$ if and only if for all $x \in \{0,1\}^{\log m}$

$\begin{aligned}
& \sum_{i=1}^q c_i \cdot (\prod_{j\in S_i} (\sum_{y\in \{0,1\}^{\log m}} \widetilde{M}_j(x,y) \cdot \widetilde{z}(y))) = 0
\end{aligned}$

where $\widetilde{z}(y)=\widetilde{(\omega, \times, 1)}(y)$

In HyperNova, CCS relations are modified for folding:

- A *Linearised CCS* relation $\mathcal{R}_{LCCS}$ contains only inner linear sum-checks. Concretely,

$\begin{aligned}
(s, (u, x, r, \{v_1,...,v_t\}), \widetilde{w}) \in \mathcal{R}_{LCCS} 
\iff v_i = \sum_{y \in \{ 0,1\}} \widetilde{M_i}(r, y) \cdot \widetilde{z}(y)
\end{aligned}$.

> One can think of an LCCS instance as an object that encapsulates the inner sum-checks that are left after computing the outer sum-check of a CCS instance. 

- A *Committed CCS* relation $(C, s, \times, \omega) \in \mathcal{R}_{CCCS}$ is a CCS instance where a commitment to the witness $\omega$ is also presented in the instance.
- A *Linearised Committed CCS* instance $(C, s, (u, x, r, \{v_1,...,v_t\}), \widetilde{w}) \in \mathcal{R}_{LCCCS}$ is a linearised instance with a commitment to the witness $\omega$ of the instance.

## Multi-folding for CCS construction

Folding in HyperNova takes an *accumulated* relation $R_1 \in \mathcal{R}_{LCCCS}$ and a new, incoming relation $R_2 \in \mathcal{R}_{CCCS}$, and returns a new accumulated relation $R_3 \in \mathcal{R}_{LCCCS}$.

$\begin{aligned}
f : \mathcal{R}_{LCCCS} \times \mathcal{R}_{CCCS} &\to \mathcal{R}_{LCCCS} \\
(R_1, R_2) &\mapsto R_3 
\end{aligned}$

More precisely, a folding step will require us to prove the sums in:
- $R_1 \in \mathcal{R}_{LCCCS}$: $v_i = \sum_{y \in \{ 0,1\}} \widetilde{M_i}(r, y) \cdot \widetilde{z}(y)$
- $R_2 \in \mathcal{R}_{CCCS}$: $\sum_{i=1}^q c_i \cdot (\prod_{j\in S_i} (\sum_{y\in \{0,1\}^{\log m}} \widetilde{M}_j(x,y) \cdot \widetilde{z}(y))) = 0$

while delaying some of the sum-checks for later steps, which are encoded in $R_3 \in \mathcal{R}_{LCCCS}$.

## Folding Fibonacci

To illustrate the workings of folding in HyperNova, we'll perform two iterations of our Fibonacci example:

```rust
// i-th iteration
fibonacci(x_2, x_1, y_2, y_1) {
    x = x_1 + x_2 // Fibonacci
    y = y_1 * y_2 // Multiplicative Fibonacci
    t = x * y     // Fibonacci x (Multiplicative Fibonacci)
    (x, y, t)
}
```

Recall that a Fibonacci iteration arithmetises in CCS as follows:

$\begin{aligned}  
& \overbrace{1}^{c_1} \cdot \overbrace{\begin{bmatrix}   
1 & 1 & 0 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 1 & 0 & 0 & 0 \\ 0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}  }^{M_1} 
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z \circ
\overbrace{\begin{bmatrix}   0 & 0 & 0 & 0 & 0 & 0 & 0 & 1 \\   0 & 0 & 0 & 1 & 0 & 0 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}}^{M_2}  
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z \\
+& \overbrace{(-1)}^{c_1} \cdot \overbrace{\begin{bmatrix}   0 & 0 & 1 & 0 & 0 & 0 & 0 & 0 \\   0 & 0 & 0 & 0 & 0 & 1 & 0 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 \\  \end{bmatrix}}^{M_3} 
\overbrace{\begin{bmatrix} x_2 \\ x_1 \\ x \\ y_2 \\ y_1 \\ y \\ t \\ 1 \end{bmatrix}}^z
= \overbrace{\begin{bmatrix} 0 \\ 0 \\ 0 \\ 0 \\ 0 \\ 0 \\ 0 \\ 0 \end{bmatrix}}^{\vec{0}}
\end{aligned}$

> Multi-folding refers to the property that instances of different structures can be folded together. However, the structure $s_i$ for each instance in our fibonacci example will be the same. That is, $s = s_1 = s_2 = ([\widetilde{M}_1, \widetilde{M}_2, \widetilde{M}_3], [S_1, S_2], [c_1, c_2])$, where $S_1 = \{1, 2\}$, $S_2 = \{ 3 \}$, $c_1 = 1$, $c_2 = -1$.


```python
# Necessary boilerplate from our last post
k = GF(101)

R = PolynomialRing(k, 10, "x1, x2, y1, y2, y3, x11, x22, y11, y22, y33")
x1, x2, y1, y2, y3, x11, x22, y11, y22, y33 = R.gens()

eqx = ((1 - x1)*(1 - x11) + x1*x11) * ((1 - x2)*(1 - x22) + x2*x22)
eqy = ((1 - y1)*(1 - y11) + y1*y11) * ((1 - y2)*(1 - y22) + y2*y22) * ((1 - y3)*(1 - y33) + y3*y33)

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
```

Recall also that the multilinear extensions $\widetilde{M_i}$ of $M_i$ and $\widetilde{z}$ of $z$ are defined as 

$\begin{aligned}
\widetilde{M_i}(X, Y) &:= \sum_{x \in \{0, 1 \}^{s}} \sum_{y \in \{0, 1 \}^{s'}} M_i(x, y) \cdot \widetilde{eq}(x, X) \cdot \widetilde{eq}(y, Y)
\end{aligned}$

$\widetilde{z}(Y) := \sum_{y \in \{0, 1 \}^{s'}} z(y) \cdot \widetilde{eq}(y, Y)$.

And that to apply the sum-check, the CCS relation 

$1 \cdot (M_1 \cdot z \circ M_2 \cdot z) + (-1) \cdot (M_3 \cdot z) = \vec{0}$

is thus turned into a polynomial equation

$\begin{aligned}
G((X_1, X_2)) := & 1 \cdot (\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}(y)) \\  + & (-1) \cdot (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((X_1, X_2), y) \cdot \widetilde{z}(y)) = \vec{0}
\end{aligned}$


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

def z_linear(zi):
    return sum([
                sum([
                    sum([
                        zi[Integer(col(y1=y1,y2=y2,y3=y3))]* eqy(y1=y1, y11=y11, y2=y2, y22=y22, y3=y3, y33=y33)
                    for y3 in [0,1]])
                for y2 in [0,1]])
            for y1 in [0,1]])

def Mi_z_prod(Mi, zi):
        return sum([
                sum([
                    sum([
                        Mi_linear(Mi)(y11=y1,y22=y2,y33=y3) * z_linear(zi)(y11=y1,y22=y2,y33=y3)
                    for y3 in [0,1]])
                for y2 in [0,1]])
            for y1 in [0,1]])
```

## Iteration 1 (base case)

As we did in our previous post, we provide the initial values $x_2 = 0, x_1 = 1, y_2=2, y_1=3$ to the Fibonacci step function, which outputs $x = 1, y=6, t=6$.

The ingredients for our first iterations are:

- **Accumulated relation** $R_1 = \bot \in \mathcal{R}_{LCCCS}$
- **Incoming relation** $R_2 = (s, C_2, \times_2) \in \mathcal{R}_{CCCS}$
- **Accumulated instance** $\widetilde{z}_1 = \bot$ 
- **Incoming instance** $\widetilde{z}_2 = \widetilde{(\omega_2, \times_2, 1)}$, where $\omega_2 = ()$ and $\times_2 = (0,1,1,2,3,6,6)$.


```python
public_x2 = [0,1,1,2,3,6,6]
private_w2 = []
z2 = vector(k, private_w2 + public_x2 + [1])
z2
```




    (0, 1, 1, 2, 3, 6, 6, 1)



### Checking $R_1 \in \mathcal{R}_{LCCCS}$

In this first iteration or base case, our accumulated instance $R_1$ is empty, so there is no sum-check to run.

### Checking for $R_2 \in \mathcal{R}_{CCCS}$

The prover wants to prove that $G((x_1, x_2)) = 0$ for all $x_1, x_2 \in \{0,1\}$ using the sum-check. 

That is $G((0,0))= G((0,1))= G((1,0))= G((1,1))=0$, where

$\begin{aligned}
G((X_1, X_2)) := & \sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}_2(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_2}((X_1, X_2), y) \cdot \widetilde{z}_2(y) \\  
-& (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((X_1, X_2), y) \cdot \widetilde{z}_2(y)) = 0
\end{aligned}$


```python
G = Mi_z_prod(M1, z2) * Mi_z_prod(M2, z2) - Mi_z_prod(M3, z2)
G
```




    21*x11^2*x22^2 - 17*x11^2*x22 - 15*x11*x22^2 + 2*x11^2 + 11*x11*x22 - 2*x11



As we did in the previous post, we compute the multilinear extension of $G((X_1,X_2))$, $h((X_1,X_2)) = \sum_{x_1,x_2 \in \{0,1\}} \widetilde{eq}((X_1,X_2),(x_1,x_2)) \cdot G((x_1, x_2))$.

Checking that $h$ is the zero polynomial implies with high probability that for all $x \in \{ 0,1\}^2$, $G(x) = 0$.


```python
h = sum([
        sum([
            G(x11=x11, x22=x22) * eqx(x11=x11, x22=x22)
            for x22 in [0,1]])
     for x11 in [0,1]])

h
```




    0



To check that $h = 0$, we can apply the Swartz-Zippel lemma and evaluate $h$ at a random point $\beta := (\beta_1, \beta_2)$. 

Thus, the verifier samples a random challenge $\beta := (\beta_1, \beta_2)$.


```python
beta1 = k.random_element()
beta2 = k.random_element()

(beta1, beta2)
```




    (91, 30)



The prover computes $h((\beta_1,\beta_2))$ and sends it to the verifier. The goal of the verifier is to check that $h((\beta_1,\beta_2))$ is indeed this sum:

$h((\beta_1,\beta_2)) = \sum_{x_1,x_2 \in \{0,1\}} \widetilde{eq}((\beta_1,\beta_2),(x_1,x_2)) \cdot G((x_1, x_2))$

Equivalently, it is checking that $\sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} Q(x_1, x_2) = 0$ where

$Q(X_1, X_2) := G((X_1, X_2)) \cdot \widetilde{eq}((\beta_1, \beta_2), (X_1, X_2))$


```python
Q = G * eqx(x1=beta1,x2=beta2)
Q
```




    39*x11^3*x22^3 + 17*x11^3*x22^2 - 5*x11^2*x22^3 - 4*x11^3*x22 + 5*x11^2*x22^2 - 39*x11*x22^3 + 6*x11^3 + 41*x11^2*x22 + 6*x11*x22^2 - 38*x11^2 + 41*x11*x22 + 32*x11




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




    -37*x11^3 - 35*x11^2 - 29*x11



The verifier first checks that $s_1(0) + s_1(1)$ matches the expected result, i.e. $s_1(0) + s_1(1) = 0$


```python
s1(x11=0) + s1(x11=1) == 0
```




    True



The verifier checks $s_1 = Q_1$ by checking that $Q_1$ and $s_1$ agree at a random point $r_1$ (Schwartz-Zippel lemma)


```python
r1 = k.random_element()
r1
```




    95



The verifier can compute directly $s_1(r_1)$ but doesn't know what $Q_1$ is, so the check $s_1 = Q_1$ must be done recursively.

#### Round 2 (final)

The new claim is that $s_1(r_1) := \sum_{x_2 \in \{0,1\}} Q(r_1, x_2)$

The prover sends the verifier a univariate $s_2(X_2)$ which he claims to be equal to  $Q_2(X_2) := Q(r_1, X_2)$.


```python
Q2 = Q(x11=r1)
s2 = Q2

s2
```




    13*x22^3 + 7*x22^2 - 27*x22 - 28



The verifier first checks that $s_1(r_1)$ is indeed $s_2(0) + s_2(1)$


```python
s2(x22=0) + s2(x22=1) == s1(x11=r1)
```




    True



The verifier sends a random challenge $r_2$ to check that $s_2(r_2) = Q_2(r_2)$.


```python
r2 = k.random_element()
r2
```




    70



There is no more need for recursion, since the verifier may now evaluate $Q(r_1, r_2) = Q_2(r_2)$.

However, to compute $Q_2(r_2)$ the verifier must know the value of the sums

$\begin{aligned}
v_i &= \sum_{y_1 \in \{0, 1 \}} \sum_{y_2 \in \{0, 1 \}} \sum_{y_3 \in \{0, 1 \}} \widetilde{M_i}((r_1, r_2), (y_1, y_2, y_3)) \cdot \widetilde{z}_2((y_1, y_2, y_3)) \\
\end{aligned}$

To assist the verifier in this computation, the prover computes 
$v_i = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r_1, r_2), y) \cdot \widetilde{z}_2(y)$ and sends them to the verifier.


```python
def v_generator(Mi, zi):
    return sum([
        sum([
            sum([
                Mi_linear(Mi)(x11=r1, x22= r2, y11=y1,y22=y2,y33=y3) * z_linear(zi)(y11=y1,y22=y2,y33=y3)
            for y3 in [0,1]])
        for y2 in [0,1]])
    for y1 in [0,1]])

v1 = v_generator(M1, z2)
v2 = v_generator(M2, z2)
v3 = v_generator(M3, z2)

(v1,v2,v3)
```




    (37, -48, -8)



### Accumulating sum-checks into $R_3 \in \mathcal{R}_{LCCCS}$

Instead of engaging in a sum-check now, they construct $R_3 \in \mathcal{R}_{LCCCS}$, which serves as an accumulation of these inner sum-checks:

$R_3 = (s, C_3, (u_3, \times_3, (r_1, r_2), \{v_1,v_2,v_3\}))$

where $C_3 = C_2$, $u_3 = 1$, $\times_3 = \times_2$.

So, by checking $R_3$ in a future step, the verifier will verify that $v_1, v_2, v_3$ were computed correctly, thus avoiding running any inner sum-check at this step. **Folding for the win!**


```python
u3 = 1
public_x3 = public_x2
```

## Iteration 2 (iterative case)

- **Accumulated relation** $R'_1 = R_3 = (s, C_3, (u_3, \times_3, (r_1, r_2), \{v_1,v_2,v_3\})) \in \mathcal{R}_{LCCCS}$
- **Incoming relation** $R'_2 = (s, C'_2, \times'_2) \in \mathcal{R}_{CCCS}$
- **Accumulated instance** $\widetilde{z}'_1 = \widetilde{(\omega_3, \times_3, u_3)}$
- **Incoming instance** $\widetilde{z}'_2 = \widetilde{(\omega'_2, \times'_2, 1)}$ where $\omega'_2 = ()$ and $\times'_2 = (1,1,2,3,6,18,36)$.


```python
public_xx1 = public_x3
zz1 = vector(k, public_xx1 + [] + [1])
zz1
```




    (0, 1, 1, 2, 3, 6, 6, 1)




```python
public_xx2 = [1,1,2,3,6,18,36]
zz2 = vector(k, public_xx2 + [] + [1])
zz2
```




    (1, 1, 2, 3, 6, 18, 36, 1)



### Checking $R'_1 \in \mathcal{R}_{LCCCS}$

The verifier wants to check that $v_i = H'_i((r_1, r_2))$, where $H'_i(x) = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}(x, y) \cdot \widetilde{z}'_1(y)$, as the prover claims.

By *lemma 6* of the HyperNova paper, since $H_i$ is a multilinear polynomial in two variables, 

$H_i((X_1, X_2)) = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}} \widetilde{eq}((X_1, X_2), (x_1, x_2)) \cdot H_i((x_1, x_2))$

So the prover is tasked to convince the verifier that

$v_i = H_i((r_1, r_2)) = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  L_i((x_1, x_2))$

where
$L_i((X_1, X_2)) = \widetilde{eq}((r_1, r_2), (X_1, X_2)) \cdot H_i((X_1, X_2))$


```python
def H_generator(Mi, zi):
    return sum([
        sum([
            sum([
                Mi_linear(Mi)(y11=y1,y22=y2,y33=y3) * z_linear(zi)(y11=y1,y22=y2,y33=y3)
            for y3 in [0,1]])
        for y2 in [0,1]])
    for y1 in [0,1]])

H1 = H_generator(M1, zz1)
H2 = H_generator(M2, zz1)
H3 = H_generator(M3, zz1)

(H1, H2, H3)
```




    (-3*x11*x22 + 2*x11 + 1,
     -7*x11*x22 + x11 + 5*x22 + 1,
     -11*x11*x22 + 5*x11 + 5*x22 + 1)




```python
L1 = eqx(x1 = r1, x2= r2) * H1
L2 = eqx(x1 = r1, x2= r2) * H2
L3 = eqx(x1 = r1, x2= r2) * H3

(L1, L2, L3)
```




    (-33*x11^2*x22^2 - 43*x11^2*x22 + 10*x11*x22^2 - 24*x11^2 - 28*x11*x22 + 32*x11 - 37*x22 + 22,
     24*x11^2*x22^2 - 6*x11^2*x22 + 11*x11*x22^2 - 12*x11^2 - 38*x11*x22 + 17*x22^2 + 10*x11 - 28*x22 + 22,
     -20*x11^2*x22^2 - 15*x11^2*x22 - 43*x11*x22^2 + 41*x11^2 + 29*x11*x22 + 17*x22^2 - 3*x11 - 28*x22 + 22)




```python
# Sanity check
H1(x11= r1, x22=r2) == sum([ sum([ L1(x11=x1, x22=x2) for x2 in [0,1]])for x1 in [0,1]])
```




    True



### Batching sum-checks in $R'_1 \in \mathcal{R}_{LCCCS}$

Instead of engaging in three separate sum-checks, the verifier samples a random element $\gamma \in \mathbb{F}$, and the three sums $\sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  L_i((x_1, x_2))$ for $i \in \{1,2,3\}$ are simultaneously checked together by using a random linear combination of $L_i$, $g_1(x) = \sum_{j \in \{1,2,3\}} \gamma^j \cdot L_j(x)$

Checking that 

$\sum_{j \in \{1,2,3\}} \gamma^j \cdot v_j = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  g_1((x_1, x_2))$

implies with high probability that

$v_i = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  L_i((x_1, x_2))$ 

for each $i \in \{1,2,3\}$.


```python
gamma = k.random_element()
gamma
```




    23




```python
g1 = gamma * L1 + gamma^2 * L2 + gamma^3 * L3
g1
```




    -12*x11^2*x22^2 - 20*x11^2*x22 - 12*x11*x22^2 - 24*x11^2 + 9*x11*x22 - 5*x22^2 + 27*x11 - 11*x22 + 48




```python
sum([ 
    sum([ g1(x11=x1, x22=x2) for x2 in [0,1]])
for x1 in [0,1]]) == gamma * v1 + gamma^2 * v2 + gamma^3 * v3
```




    True



The prover thus sends the sum $\sum_{j \in \{1,2,3\}} \gamma^j \cdot v_j$ to the verifier. 

Note that the verifier is delaying these checks for now. They will later be further batched with other sum-checks from $R'_2$.

### Checking $R'_2 \in \mathcal{R}_{CCCS}$

As we did for $R_2$, the verifier aims to check that $0 = G'(X), X \in \{ 0,1\}^2$, where

$\begin{aligned}
G'((X_1, X_2)) := & \sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}'_2(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_2}((X_1, X_2), y) \cdot \widetilde{z}'_2(y) \\  - & (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((X_1, X_2), y) \cdot \widetilde{z}'_2(y)) = 0
\end{aligned}$

$\widetilde{z}'_2 = \widetilde{(\omega'_2, \times'_2, 1)}$ where $\omega'_2 = ()$ and $\times'_2 = (1,1,2,3,6,18,36)$

This is equivalent to checking that $\sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} Q'(x_1, x_2) = 0$ where

$Q'(X_1, X_2) := G'((X_1, X_2)) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (X_1, X_2))$, since

$\sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} G'((x_1, x_2)) \cdot \widetilde{eq}((X_1, X_2), (x_1, x_2))$ is a multilinear polynomial, thus uniquely determined, so it is equal to zero. Thus we apply the Schwartz-Zippel lemma by randomly evaluate it to $(\beta'_1, \beta'_2)$.


```python
GG = Mi_z_prod(M1, zz2) * Mi_z_prod(M2, zz2) - Mi_z_prod(M3, zz2)
GG
```




    19*x11^2*x22^2 + 9*x11^2*x22 - x11*x22^2 + 8*x11^2 - 27*x11*x22 - 8*x11



The verifier samples a random challenge $\beta' := (\beta'_1, \beta'_2)$.


```python
beta11 = k.random_element()
beta22 = k.random_element()

(beta11, beta22)
```




    (26, 39)




```python
QQ = GG * eqx(x1=beta11,x2=beta22)
QQ
```




    -26*x11^3*x22^3 + 36*x11^3*x22^2 - x11^2*x22^3 + 36*x11^3*x22 - 43*x11^2*x22^2 + 6*x11*x22^3 + 50*x11^3 + 21*x11^2*x22 + 20*x11*x22^2 - 25*x11^2 - 49*x11*x22 - 25*x11



### Batching sum-checks in $R'_1 \in \mathcal{R}_{LCCCS}$ and  $R'_2 \in \mathcal{R}_{CCCS}$


We now batch:
- The *remaining batched check* on $R'_1$, $g_1(x) = \sum_{j \in \{1,2,3\}} \gamma^j \cdot L_j(x)$
- The *new check* $G'(x) = 0$

Using a random linear combination $g(x) = g_1(x) + \gamma^4 Q'(x)$.

As expected, proving the new sum:

$\sum_{j \in \{1,2,3\}} \gamma^j \cdot v_j + \gamma^4 \cdot 0 = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  g((x_1, x_2))$

will in turn prove with high probability the batched checks.


```python
g = g1 + gamma^4 * QQ
g
```




    -28*x11^3*x22^3 + 31*x11^3*x22^2 + 30*x11^2*x22^3 + 31*x11^3*x22 - 35*x11^2*x22^2 + 22*x11*x22^3 + 15*x11^3 - 44*x11^2*x22 - 6*x11*x22^2 + 19*x11^2 - 36*x11*x22 - 5*x22^2 - 31*x11 - 11*x22 + 48



$v = \sum_{j \in \{1,2,3\}} \gamma^j \cdot v_j + \gamma^4 \cdot 0$


```python
v = (gamma^1 * v1 + gamma^2 * v2 + gamma^3 * v3) + gamma^4 * 0
v
```




    30




```python
sum([ 
    sum([ g(x11=x1, x22=x2) for x2 in [0,1]])
for x1 in [0,1]]) == v
```




    True



#### Round 1
Prover sends $s'_1$ claiming to be $g'_1$

$g'_1(X_1) := \sum_{x_2 \in \{0,1\}} g(X_1, x_2)$


```python
gg1 = sum([ g(x22=x2) for x2 in [0,1]])
ss1 = gg1

ss1
```




    -37*x11^3 - 11*x11^2 + 19*x11 - 21



The verifier first checks that $s'_1(0) + s'_1(1)$ matches the expected result, i.e. $s'_1(0) + s'_1(1) = v$


```python
ss1(x11=0) + ss1(x11=1) == v
```




    True



The verifier checks $s'_1 = g'_1$ by checking that $g'_1$ and $s'_1$ agree at a random point $r'_1$ (Schwartz-Zippel lemma)


```python
rr1 = k.random_element()
rr1
```




    64



The verifier can compute directly $s'_1(r'_1)$ but doesn't know what $g'_1$ is, so the check $s'_1 = g'_1$ must be done recursively.

#### Round 2 (final)

The new claim is that $s'_1(r'_1) := \sum_{x_2 \in \{0,1\}} g(r'_1, x_2)$

The prover sends the verifier a univariate $s'_2(X_2)$ which he claims to be equal to  $g'_2(X_2) := g(r'_1, X_2)$.


```python
gg2 = g(x11=rr1)
ss2 = gg2

ss2
```




    -x22^3 - 22*x22^2 - 28*x22 - 36



The verifier first checks that $s'_1(r_1)$ is indeed $s'_2(0) + s'_2(1)$


```python
ss2(x22=0) + ss2(x22=1) == ss1(x11=rr1)
```




    True



The verifier sends a random challenge $r'_2$ to check that $s'_2(r'_2) = g'_2(r'_2)$.


```python
rr2 = k.random_element()
rr2
```




    67



There is no more need for recursion, since the verifier may now evaluate $g(r'_1, r'_2) = g'_2(r'_2)$.

However, to compute $g'_2(r'_2)$ the verifier must know the value of the sums

$\sigma_i = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot \widetilde{z}'_1(y)$

$\theta_i = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y)$

for $i \in \{1,2,3\}$, since

$
\begin{aligned}
s'_2(r'_2) &= g'_2(r'_2) \\ 
&= g((r'_1, r'_2)) \\
&= g_1((r'_1, r'_2)) + \gamma^4 Q'((r'_1, r'_2)) \\
&= \sum_{j \in \{1,2,3\}} \gamma^j \cdot L_j((r'_1, r'_2)) + \gamma^4 G'((r'_1, r'_2)) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (r'_1, r'_2)) \\
&= \sum_{j \in \{1,2,3\}} \gamma^j \cdot \widetilde{eq}((r_1, r_2), (r'_1, r'_2)) \cdot H_j((r'_1, r'_2)) \\ 
&+ \gamma^4 \cdot (\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_2}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y)) \\ 
&- (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y)))) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (r'_1, r'_2))) \\
&= (\gamma \cdot \sigma_1 + \gamma^2 \cdot  \sigma_2 + \gamma^3 \cdot \sigma_3) \cdot \widetilde{eq}((r_1, r_2), (r'_1, r'_2)) \\ 
&+ \gamma^4 \cdot (\theta_1 * \theta_2 - \theta_3) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (r'_1, r'_2)))
\end{aligned}
$

To assist the verifier, the prover sends $\sigma_i$ and $\theta_i$.


```python
def v_generator(Mi, zi):
    return sum([
        sum([
            sum([
                Mi_linear(Mi)(x11=rr1, x22= rr2, y11=y1,y22=y2,y33=y3) * z_linear(zi)(y11=y1,y22=y2,y33=y3)
            for y3 in [0,1]])
        for y2 in [0,1]])
    for y1 in [0,1]])

sigma1 = v_generator(M1, zz1)
sigma2 = v_generator(M2, zz1)
sigma3 = v_generator(M3, zz1)

theta1 = v_generator(M1, zz2)
theta2 = v_generator(M2, zz2)
theta3 = v_generator(M3, zz2)

(sigma1, sigma2, sigma3), (theta1, theta2, theta3)
```




    ((-9, -23, 49), (-18, 45, 3))




```python
g(x11=rr1, x22=rr2) == (gamma * sigma1 + gamma^2 * sigma2 + gamma^3 * sigma3) * eqx(x1=r1, x2=r2, x11=rr1, x22=rr2) + gamma^4 * (theta1 * theta2 - theta3) * eqx(x1=beta11, x2=beta22, x11=rr1, x22=rr2)
```




    True



To avoid doing many sum-checks, the verifier samples a random challenge $\rho$ and reduces the task to checking

$\sigma_i + \rho \cdot \theta_i = \sum_{y \in \{0,1\}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y))$


```python
rho = k.random_element()
rho
```




    45



### Accumulating sum-checks into $R'_3 \in \mathcal{R}_{LCCCS}$

Instead of engaging in a sum-check now, we construct $R'_3 \in \mathcal{R}_{LCCCS}$, which serves as an accumulation of all the remaining inner sum-checks:

$R'_3 = (s, C'_3, (u'_3, \times'_3, (r'_1, r'_2), \{v'_1,v'_2,v'_3\}))$

where
- $C'_3 = C'1 + \rho \cdot C_2$
- $u'_3 = 1 + \rho \cdot 1$
- $\times'_3 = \times'_1 + \rho \cdot \times'2$
- $v'_i = \sigma_i + \rho \cdot \theta_i$

Checking the $R'_3$ relation is equivalent to checking

$v'_i = \sum_{y \in \{0,1\}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y))$

for all $i \in \{1,2,3\}$.


```python
u3 = 1 + rho
public_xx3 = public_xx1 + rho * public_xx2
vv1 = sigma1 + rho * theta1
vv2 = sigma2 + rho * theta2
vv3 = sigma3 + rho * theta3
```

## Verifying the folded instance

<div class="alert alert-block alert-info">
Note that until now, the prover and verifier have only been engaging in outer sum-checks, but haven't engaged in any inner sum-check yet; they have been delaying or accumulating them.
</div>

We are left with a linearised CCCS relation $R'_3$. Since our goal was only to compute two iterations, we can finally compute the sum-check on this instance. Had we wanted to run more iterations, we would accumulate these sum-checks further.

$v'_i = \sum_{y \in \{0,1\}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y))$

where $v'_i = \sigma_i + \rho \cdot \theta_i$

Note that checking $v'_i$ implies checking both $\sigma_i$ and $\theta_i$ with high probability.

By batching all $v'_i$ with a random linear combination, checking 

$\begin{aligned}
v'_1 + \alpha v'_2 + \alpha^2 v'_3 &= \sum_{y \in \{0,1\}^3} \widetilde{M_1}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
&+ \alpha \cdot \sum_{y \in \{0,1\}^3} \widetilde{M_2}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
&+ \alpha^2 \cdot \sum_{y \in \{0,1\}^3} \widetilde{M_3}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
\end{aligned}$ 

implies with high probability that 

$v'_i = \sum_{y \in \{0,1\}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y))$

which in turn implies that $\sigma_i$ and $\theta_i$ for $i \in \{1,2,3\}$ are computed correctly as the prover previously claimed.

### Batching sum-checks from $R'_3 \in \mathcal{R}_{LCCCS}$

The verifier samples $\alpha \in \mathbb{F}$ randomly to check

$\begin{aligned}
v' &= \sum_{y \in \{0,1\}^3} \widetilde{M_1}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
&+ \alpha \cdot \sum_{y \in \{0,1\}^3} \widetilde{M_2}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
&+ \alpha^2 \cdot \sum_{y \in \{0,1\}^3} \widetilde{M_3}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
&= \sum_{y \in \{0,1\}^3} (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \cdot (\widetilde{M_1}((r'_1, r'_2), y) \\
& \quad \quad \quad \quad + \alpha \cdot \widetilde{M_2}((r'_1, r'_2), y) + \alpha^2 \cdot \widetilde{M_3}((r'_1, r'_2), y))
\end{aligned}$


```python
alpha = k.random_element()
alpha
```




    81




```python
vv = sum([
        sum([
            sum([
                Mi_linear(M1)(x11=rr1, x22= rr2, y11=y1,y22=y2,y33=y3) * (z_linear(zz1)(y11=y1,y22=y2,y33=y3) + rho * z_linear(zz2)(y11=y1,y22=y2,y33=y3)) +
                alpha * Mi_linear(M2)(x11=rr1, x22= rr2, y11=y1,y22=y2,y33=y3) * (z_linear(zz1)(y11=y1,y22=y2,y33=y3) + rho * z_linear(zz2)(y11=y1,y22=y2,y33=y3)) +
                alpha^2 * Mi_linear(M3)(x11=rr1, x22= rr2, y11=y1,y22=y2,y33=y3) * (z_linear(zz1)(y11=y1,y22=y2,y33=y3) + rho * z_linear(zz2)(y11=y1,y22=y2,y33=y3))
            for y3 in [0,1]])
        for y2 in [0,1]])
    for y1 in [0,1]])

vv
```




    17



#### Round 1

$\begin{aligned}
v'_{11} &= \sum_{y_2 \in \{0,1\}} \sum_{y_3 \in \{0,1\}} \widetilde{M_1}((r'_1, r'_2), (Y_1, y_2, y_3)) \cdot (\widetilde{z}'_1((Y_1, y_2, y_3)) + \rho \cdot \widetilde{z}'_2((Y_1, y_2, y_3))) \\
&+ \alpha \cdot \sum_{y_2 \in \{0,1\}} \sum_{y_3 \in \{0,1\}} \widetilde{M_2}((r'_1, r'_2), (Y_1, y_2, y_3)) \cdot (\widetilde{z}'_1((Y_1, y_2, y_3)) + \rho \cdot \widetilde{z}'_2((Y_1, y_2, y_3))) \\
&+ \alpha^2 \cdot \sum_{y_2 \in \{0,1\}} \sum_{y_3 \in \{0,1\}} \widetilde{M_3}((r'_1, r'_2), (Y_1, y_2, y_3)) \cdot (\widetilde{z}'_1((Y_1, y_2, y_3)) + \rho \cdot \widetilde{z}'_2((Y_1, y_2, y_3)))
\end{aligned}$

Prover sends $q_1$ claiming to be equal to $v'_{11}$


```python
vv11 = sum([
        sum([
            Mi_linear(M1)(x11=rr1, x22= rr2, y22=y2,y33=y3) * (z_linear(zz1)(y22=y2,y33=y3) + rho * z_linear(zz2)(y22=y2,y33=y3)) +
                alpha * Mi_linear(M2)(x11=rr1, x22= rr2, y22=y2,y33=y3) * (z_linear(zz1)(y22=y2,y33=y3) + rho * z_linear(zz2)(y22=y2,y33=y3)) +
                alpha^2 * Mi_linear(M3)(x11=rr1, x22= rr2, y22=y2,y33=y3) * (z_linear(zz1)(y22=y2,y33=y3) + rho * z_linear(zz2)(y22=y2,y33=y3))
        for y3 in [0,1]])
    for y2 in [0,1]])
q1 = vv11

q1
```




    32*y11^2 - 28*y11 - 44



Verifier checks that $q_1(0) + q_1(1) = v'$


```python
q1(y11=0) + q1(y11=1) == vv
```




    True



Verifier computes a random element $r''_1$ to check that $q_1$ is actually $v'$


```python
rrr1 = k.random_element()
rrr1
```




    77



#### Round 2

$\begin{aligned}
v'_{12} &= \sum_{y_3 \in \{0,1\}} \widetilde{M_1}((r'_1, r'_2), (r''_1, Y_2, y_3)) \cdot (\widetilde{z}'_1((r''_1, Y_2, y_3)) + \rho \cdot \widetilde{z}'_2((r''_1, Y_2, y_3))) \\
&+ \alpha \cdot \sum_{y_3 \in \{0,1\}} \widetilde{M_2}((r'_1, r'_2), (r''_1, Y_2, y_3)) \cdot (\widetilde{z}'_1((r''_1, Y_2, y_3)) + \rho \cdot \widetilde{z}'_2((Y_1, Y_2, y_3))) \\
&+ \alpha^2 \cdot \sum_{y_3 \in \{0,1\}} \widetilde{M_3}((r'_1, r'_2), (r''_1, Y_2, y_3)) \cdot (\widetilde{z}'_1((r''_1, Y_2, y_3)) + \rho \cdot \widetilde{z}'_2((r''_1, Y_2, y_3)))
\end{aligned}$


Prover sends $q_2$ claiming to be equal to $v'_{12}$


```python
vv12 = sum([
        Mi_linear(M1)(x11=rr1, x22= rr2, y11=rrr1,y33=y3) * (z_linear(zz1)(y11=rrr1,y33=y3) + rho * z_linear(zz2)(y11=rrr1,y33=y3)) + 
        alpha * Mi_linear(M2)(x11=rr1, x22= rr2, y11=rrr1,y33=y3) * (z_linear(zz1)(y11=rrr1,y33=y3) + rho * z_linear(zz2)(y11=rrr1,y33=y3)) +
        alpha^2 * Mi_linear(M3)(x11=rr1, x22= rr2, y11=rrr1,y33=y3) * (z_linear(zz1)(y11=rrr1,y33=y3) + rho * z_linear(zz2)(y11=rrr1,y33=y3))
    for y3 in [0,1]])
q2 = vv12

q2
```




    -3*y22^2 + 36*y22 + 46



Verifier checks that $q_2(0) + q_2(1) = q_1(r''_1)$


```python
# Verifier checks 
q2(y22=0) + q2(y22=1) == q1(y11=rrr1)
```




    True



Verifier computes a random element $r''_2$ to check that $q_2$ is actually $v'_{12}$


```python
rrr2 = k.random_element()
rrr2
```




    5



#### Round 3
$$
v'_{13} = \widetilde{M_1}((r'_1, r'_2), (r''_1, r''_2, y_3)) \cdot (\widetilde{z}'_1((r''_1, r''_2, y_3)) + \rho \cdot \widetilde{z}'_2((r''_1, r''_2, y_3)))
$$

Prover sends $q_3$ claiming to be equal to $v'_{13}$


```python
vv13 = Mi_linear(M1)(x11=rr1, x22= rr2, y11=rrr1,y22=rrr2) * (z_linear(zz1)(y11=rrr1,y22=rrr2) + rho * z_linear(zz2)(y11=rrr1,y22=rrr2)) + alpha * Mi_linear(M2)(x11=rr1, x22= rr2, y11=rrr1,y22=rrr2) * (z_linear(zz1)(y11=rrr1,y22=rrr2) + rho * z_linear(zz2)(y11=rrr1,y22=rrr2)) + alpha^2 * Mi_linear(M3)(x11=rr1, x22= rr2, y11=rrr1,y22=rrr2) * (z_linear(zz1)(y11=rrr1,y22=rrr2) + rho * z_linear(zz2)(y11=rrr1,y22=rrr2))
q3 = vv13

q3
```




    2*y33^2 + 29*y33 + 31



Verifier checks that $q_3(0) + q_3(1) = q_2(r''_2)$


```python
q3(y33=0) + q3(y33=1) == q2(y22=rrr2)
```




    True



Verifier computes a random element $r''_3$ to check that $q_3$ is actually $v'_{13}$


```python
rrr3 = k.random_element()
rrr3
```




    30



The verifier can compute now on his own

$\begin{aligned}
&\widetilde{M_1}((r'_1, r'_2), (r''_1, r''_2, r''_3)) \cdot (\widetilde{z}'_1((r''_1, r''_2, r''_3)) + \rho \cdot \widetilde{z}'_2((r''_1, r''_2, r''_3))) \\
&+ \alpha \cdot \widetilde{M_2}((r'_1, r'_2), (r''_1, r''_2, r''_3)) \cdot (\widetilde{z}'_1((r''_1, r''_2, r''_3)) + \rho \cdot \widetilde{z}'_2((r''_1, r''_2, r''_3))) \\
&+ \alpha^2 \cdot \widetilde{M_3}((r'_1, r'_2), (r''_1, r''_2, r''_3)) \cdot (\widetilde{z}'_1((r''_1, r''_2, r''_3)) + \rho \cdot \widetilde{z}'_2((r''_1, r''_2, r''_3))) \\
&= (\widetilde{M_1}((r'_1, r'_2), (r''_1, r''_2, r''_3)) + \alpha \cdot \widetilde{M_2}((r'_1, r'_2), (r''_1, r''_2, r''_3)) \\
&+ \alpha^2 \cdot \widetilde{M_3}((r'_1, r'_2), (r''_1, r''_2, r''_3))) \cdot (\widetilde{z}'_1((r''_1, r''_2, r''_3)) + \rho \cdot \widetilde{z}'_2((r''_1, r''_2, r''_3)))
\end{aligned}$ 


and check that $q(r''_3)$ is indeed that random linear combination.


```python
c1 = Mi_linear(M1)(x11=rr1, x22= rr2, y11=rrr1,y22=rrr2, y33=rrr3) * (z_linear(zz1)(y11=rrr1,y22=rrr2, y33=rrr3) + rho * z_linear(zz2)(y11=rrr1,y22=rrr2, y33=rrr3)) + alpha * Mi_linear(M2)(x11=rr1, x22= rr2, y11=rrr1,y22=rrr2, y33=rrr3) * (z_linear(zz1)(y11=rrr1,y22=rrr2, y33=rrr3) + rho * z_linear(zz2)(y11=rrr1,y22=rrr2, y33=rrr3)) + alpha^2 * Mi_linear(M3)(x11=rr1, x22= rr2, y11=rrr1,y22=rrr2, y33=rrr3) * (z_linear(zz1)(y11=rrr1,y22=rrr2, y33=rrr3) + rho * z_linear(zz2)(y11=rrr1,y22=rrr2, y33=rrr3))

c1 == q3(y33=rrr3)
```




    True



### The Domino Effect

> For reference:
> - $\begin{aligned}
    G'((X_1, X_2)) := & \sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((X_1, X_2), y) \cdot \widetilde{z}'_2(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_2}((X_1, X_2), y) \cdot \widetilde{z}'_2(y) \\  - & (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((X_1, X_2), y) \cdot \widetilde{z}'_2(y)) = 0
    \end{aligned}$
> - $Q'(X_1, X_2) := G'((X_1, X_2)) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (X_1, X_2))$
> - $L_i((X_1, X_2)) = \widetilde{eq}((r_1, r_2), (X_1, X_2)) \cdot H_i((X_1, X_2))$
> - $H_i((X_1, X_2)) := \sum_{y\in \{0,1\}^3} \widetilde{M}_i((X_1, X_2),y) \cdot \widetilde{z}'_1(y)$
> - $\sigma_i = H_i((r'_1, r'_2)) = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot \widetilde{z}'_1(y)$
> - $\theta_i = L_i((r'_1, r'_2)) = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y)$
> - $g_1((X_1, X_2)) = \sum_{j \in \{1,2,3\}} \gamma^j \cdot L_j((X_1, X_2))$
> - $g((X_1, X_2)) = g_1((X_1, X_2)) + \gamma^4 Q'((X_1, X_2))$
        

The verifier has now checked that $v'_1, v'_2, v'_3$ from $R'_3$ are the values that the prover claimed by checking their random linear combination. This in turn implies that $\sigma_1, \sigma_2, \sigma_3$ and $\theta_1, \theta_2, \theta_3$ are indeed the values that the prover's claimed. Thus, the verifier is assured about the validity of the sum-checks from $R'_1 \in \mathcal{R}_{LCCCS}$ and $R'_2 \in \mathcal{R}_{CCCS}$

In other words, by checking that 

$\sum_{j \in \{1,2,3\}} \gamma^j \cdot v_j + \gamma^4 \cdot 0 = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}} g((x_1, x_2))$, for $g(x) = g_1(x) + \gamma^4 Q'(x)$,

the verifier is thus implicitely verifying all claims of $R'_1 \in \mathcal{R}_{LCCCS}$ and $R'_2 \in \mathcal{R}_{CCCS}$, which are encoded in $g_1$ and $Q'(x)$, respectively. We can apply recursively this logic, since $R_3 = R'_1$, which checks $R_2 \in \mathcal{R}_{CCCS}$ and $R_1 \in \mathcal{R}_{LCCCS}$.

More precisely, checking 

$\begin{aligned}
v' = v'_1 + \alpha v'_2 + \alpha^2 v'_3 &= \sum_{y \in \{0,1\}^3} \widetilde{M_1}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
&+ \alpha \cdot \sum_{y \in \{0,1\}^3} \widetilde{M_2}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y)) \\
&+ \alpha^2 \cdot \sum_{y \in \{0,1\}^3} \widetilde{M_3}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y))
\end{aligned}$ 

implies with high probability that

$v'_i = \sum_{y \in \{0,1\}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot (\widetilde{z}'_1(y) + \rho \cdot \widetilde{z}'_2(y))$

which implies with high probability that

- $\sigma_i = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot \widetilde{z}'_1(y)$
- $\theta_i = \sum_{y \in \{0, 1 \}^3} \widetilde{M_i}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y)$

which allows the verifier to verify that

$
\begin{aligned}
s'_2(r'_2) &= g'_2(r'_2) \\ 
&= g((r'_1, r'_2)) \\
&= g_1((r'_1, r'_2)) + \gamma^4 Q'((r'_1, r'_2)) \\
&= \sum_{j \in \{1,2,3\}} \gamma^j \cdot L_j((r'_1, r'_2)) + \gamma^4 G'((r'_1, r'_2)) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (r'_1, r'_2)) \\
&= \sum_{j \in \{1,2,3\}} \gamma^j \cdot \widetilde{eq}((r_1, r_2), (r'_1, r'_2)) \cdot H_j((r'_1, r'_2)) \\ 
&+ \gamma^4 \cdot (\sum_{y \in \{0, 1 \}^3} \widetilde{M_1}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y) \cdot \sum_{y \in \{0, 1 \}^{3}} \widetilde{M_2}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y)) \\ 
& \quad \quad \quad \quad - (\sum_{y \in \{0, 1 \}^{3}} \widetilde{M_3}((r'_1, r'_2), y) \cdot \widetilde{z}'_2(y)))) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (r'_1, r'_2))) \\
&= (\gamma \cdot \sigma_1 + \gamma^2 \cdot  \sigma_2 + \gamma^3 \cdot \sigma_3) \cdot \widetilde{eq}((r_1, r_2), (r'_1, r'_2)) \\ 
& \quad \quad + \gamma^4 \cdot (\theta_1 * \theta_2 - \theta_3) \cdot \widetilde{eq}((\beta'_1, \beta'_2), (r'_1, r'_2)))
\end{aligned}
$

which he previously assumed to be true, from the values $\sigma_i$ and $\theta_i$ given by the prover.

This implies that

$\sum_{j \in \{1,2,3\}} \gamma^j \cdot v_j + \gamma^4 \cdot 0 = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  g((x_1, x_2)) = g_1(x) + \gamma^4 Q'(x)$

which implies with high probability that

$\begin{aligned}
\sum_{j \in \{1,2,3\}} \gamma^j \cdot v_j = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  g_1((x_1, x_2)) &\overset{w.h.p}{\Longrightarrow} v_i = \sum_{x_1 \in \{0, 1 \}} \sum_{x_2 \in \{0, 1 \}}  L_i((x_1, x_2)) \text{ for } i \in \{1,2,3\} \\
&\Longrightarrow v_i = H_i((r_1, r_2)) \text{ for } i \in \{1,2,3\} \\
&\Longrightarrow R'_1 \in \mathcal{R}_{LCCCS} \text{ is a valid instance.} \\
&\Longrightarrow R_1 \in \mathcal{R}_{LCCCS}, R_2 \in \mathcal{R}_{CCCS} \text{ are valid instances. }
\end{aligned}$ 

and
$\begin{aligned}
\sum_{x_1 \in \{0,1\}}\sum_{x_2 \in \{0,1\}} Q'(x_1, x_2) &\Longrightarrow \forall x_1, x_2 \in \{0,1\}. G'((x_1, x_2)) = 0 \\
&\Longrightarrow R'_2 \in \mathcal{R}_{CCCS} \text{ is a valid instance.}
\end{aligned}$ 

## Summary

We made it, again! We have managed to fold two iterations of our Fibonacci example and then verify the folding protocol by sum-checking the final linearised CCCS relation $R'_3$.

At each iteration, the incoming relation $R^{(k)}_2 \in \mathcal{R}_{CCCS}$ generates random values $r^{(k)} \in \mathbb{F}$ that are propagated to the next accumulated relation $R^{(k+1)}_1 \in \mathcal{R}_{LCCCS}$. This serves as the glue that makes the domino effect possible.

We batched many of the sum-checks into a single sum-check using a random linear combination of the sums, thus avoiding unnecessary computation when needed.

There was a lot of work and wit put into SuperSpartan and HyperNova. I hope this post contributes to spread the understanding of such inspiring work.

Thanks for reading!
