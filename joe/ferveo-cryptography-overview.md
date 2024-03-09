---
title: Ferveo Cryptography Overview
publish_date: 2021-08-16T00:00:00.000Z
category: cryptography
image: media/dalle.png
excerpt: Ferveo includes a custom-designed distributed key generator & custom-designed threshold decryption scheme intended to meet the performance & security requirements of the underlying consensus mechanism.
---

## **Introduction**

The issues of front running, "miner extractable value", and other forms of blockchain arbitrage are well known as finance applications move onto blockchains. Because transactions appear in the mempool prior to their inclusion on-chain, validators (or others willing to pay higher fees) can generally alter the transaction order to suit their own interests.

Ideally, transactions do not become publicly revealed until they are executed on the network. Consider a hypothetical scenario where a single, trusted entity publicly executes transactions in the exact order they are received. This trusted entity can generate a public-private keypair; transactions can be encrypted to this keypair, and the trusted entity can decrypt and execute the transactions in the order they are received. However, in a decentralized network, keeping transactions encrypted until ready to be executed is more of a challenge.

Suppose a proof-of-stake blockchain, with 100 equally staked validators, securely operates under the assumption that at least 67 validators are not faulty. We would like our decryption process to operate under the same assumption: transactions are decrypted and executed in the order they are received if and only if at least 67 validators are not faulty.

In a proof-of-stake blockchain, there is a natural way to achieve this: distributed key generation and threshold cryptography. The validator set generates a shared public key along with individual **shares** of the corresponding distributed private key. Anyone can encrypt transactions using the distributed public key, and only large enough subsets of validators are able to decrypt the transaction.

Assuming that at least 67 validators do not collude to decrypt transactions early, the validators can commit to an ordering of transactions prior to decryption. Once a block of transactions is proposed, those 67 validators can engage in the decryption protocol, recovering the unencrypted transactions and executing them in the committed ordering. Since the contents of the transactions are only decrypted once the protocol commits to decrypt and execute them in a particular order, a validator cannot insert their own transactions in the same block once they discover the contents of another transaction.

## **Secret sharing**

How is it possible for 100 different validators to share parts of a private key, such that only 67 of them can decrypt? The answer begins with Shamir secret sharing, a clever scheme wherein 100 people can share a secret value \( \alpha \), an element of some finite field $\mathbb{F}$, such that every subset of 67 people can reconstruct the secret, but every subset of at most 66 people cannot.

Let us assume that a trusted dealer, Alice, knows the important secret $\alpha$ and wishes to share it among many parties. Then Alice may construct a polynomial $p(x)$:

$$
p(x) = \alpha + \alpha*1 x + \alpha_2 x^2 + \ldots + \alpha*{66} x^{66}
$$

where $\alpha_1, \ldots, \alpha_{66}$ are uniformly random elements of the same finite field as $\alpha$. Alice can distribute the value $p(1)$ to the first person, $p(2)$ to the second person, and so on. Note that $p(0)$ is the secret value $\alpha$, but each person gets an evaluation of $p$ which "mixes" the secret value $\alpha$ with the other coefficients of $p$. Since there are many different possible values of $\alpha_1, \ldots, \alpha_{66}$​, learning $p(i)$ for $i \ne 0$ does not reveal any information about $\alpha$. Indeed, even if 66 people compared their evaluation values together, there are $|\mathbb{F}|$ potential polynomials with exactly those 66 evaluation points, each with a different value at 0, and so every subset of 66 people possesses no information about the actual value of $\alpha$.

However, we know that a degree 66 polynomial is always uniquely determined by 67 distinct evaluations; therefore, every subset of 67 persons can interpolate their evaluations, and discover the secret $\alpha$.

## **Distributed key generation**

Secret sharing is an important tool used to share a private key among multiple entities. A trusted dealer, Alice, can distribute shares of a distributed private key; however, in the real world the dependence on a trusted dealer is undesireable. Indeed, there are many ways that a malicious dealer Eve could mess up the secret sharing:

1. Eve could send evaluations of different polynomials to different people
2. Eve could send some people correct evaluations of the polynomial, but send nothing to other people
3. Eve knows the secret value $\alpha$ and can do nefarious things with it

A malicious dealer Eve could obstruct the distributed key generation process, preventing it from producing valid key shares; censoring key shares from specific validators, lowering the resilience of a distributed key; or the secret key is known outside of the desired 67 validator quorum.

Therefore, we need to construct a protocol based on secret sharing, but with much better properties:

1. Everyone should be able to verify that their evaluation came from the same polynomial $p$ as everyone else's
2. Everyone should be able to verify that everyone else received their evaluations successfully
3. No one should know the generated private key

With these 3 properties, the distributed key generation achieves the desired goal: if at least 67 of 100 validators honestly follow the protocol, a secret distributed key will be successfully produced, and all 100 validators can obtain their private key share uncensored. In case Eve attempts any malfeasance, her efforts would be detected.

### **Verifying consistency of evaluations**

Each participant must be able to verify that the dealer used a single polynomial to obtain all evaluations.

The first property can be achieved by using a _polynomial commitment_ to commit to the polynomial $p$_._ Let $\mathbb{G}$ be an elliptic curve group, with a prime order generator of order $\mathbb{F}$. Then the commitment vector:

$$
C*p = ([\alpha] G, [\alpha_1] G, [\alpha_2] G, \ldots [\alpha*{66}] G )
$$

commits to the polynomial $p$ without revealing its coefficients. However, if an evaluation $p(i)$ is revealed to someone, then that evaluation can be verified by taking the inner product of $(1, i, i^2, \ldots, i^{66})$ with $C_p$​ and comparing to $[p(i)] G$:

$$
[p(i)] G = [\alpha] G + [\alpha_1 i] G+ [\alpha_2 i^2] G+ \ldots + [\alpha_{66} i^{66}] G
$$

If an alleged evaluation $p(i)$ is not actually the evaluation of $p$ at _$i$_, then this equality check will fail with high probability. Therefore, as long as everyone agrees on the shared polynomial commitment $C_p$​, then they know their evaluation $p(i)$ came from the same polynomial as everyone else's.

### **How to verify everyone received their evaluations successfully**

This property, called _public verifiability_ of the secret sharing, is more challenging to achieve.

Suppose that Eve, the untrusted dealer, broadcasts their secret sharing to everyone by posting the polynomial commitment and evaluations on the blockchain; then at least everyone will agree on the polynomial commitment, but the individual evaluations must be _encrypted_ to each recipient (otherwise, if everyone knows the evaluations, anyone can interpolate to recover the secret).

One potential approach is to use Diffie-Hellman key exchange and symmetric cryptography, such as an AES or ChaCha cipher, to encrypt the evaluations. However, these encryptions are not publicly verifiable; only the intended recipient can decrypt the evaluation and check it against the commitment. This is a problem in a distributed setting; if a recipient happens to be offline, Eve could have sent encrypted garbage to them, and no one else would know! This can be mitigated with additional liveness assumptions, a _complaint_ mechanism for bad dealers, and cryptoeconomic incentives to behave properly, but is overall not ideal in the blockchain context.

Fortunately, [publicly verifiable distributed key generation schemes](https://eprint.iacr.org/2021/005) can achieve public verifiable secret sharing (PVSS) when using a _bilinear map_ (called a pairing) on a pairing-friendly elliptic curve, such as BLS12-381.

In a PVSS scheme, evaluations are encrypted using a scheme where only the intended receipient can decrypt the evaluation, but everyone else can still check the encrypted evaluation against the committed polynomial.

The full PVSS scheme was previously explained in [Demystifying Aggregatable DKG](https://anoma.network/blog/demystifying-aggregatable-distributed-key-generation/).

Fortunately in the blockchain setting, the full Aggregatable DKG scheme is not needed, and we can get the same result with a simplified approach (more on this shortly).

The downside of this PVSS scheme is that no one can fully decrypt their evaluations $p(i)$; instead, recipients decrypt their evaluations to an elliptic curve point $[p(i)] H$ where _$H$_ is a fixed generator. Therefore, the distributed key shares and the distributed private key $[p(0)] H$ are _group elements_ instead of field elements. This makes it difficult to use many public key cryptographic schemes that expect the private key to consist of field elements.

While there are some [PVSS schemes](https://eprint.iacr.org/2021/339) which share field elements in a publicly verifiable way, it turns out that is not necessary, and the simpler group elements are sufficient (and in some ways, even better!)

We will call a polynomial commitment to $p$, along with publicly verifiable encrypted evaluations of $p$, an instance of _PVSS_.

### **Ensuring no one knows the private key**

No matter which secret sharing approach is used, the dealer will always know the coefficients of the polynomial used, and therefore will always know the secret constant term. However, we can use the fact that the PVSS scheme is _additively homomorphic_: adding two polynomials can be done by simply adding the corresponding coefficients of each polynomial, to get the coefficients of the new polynomial. Further, an evaluation at _$i$_ of the sum of two polynomials is equal to the sum of their evaluations at* $i$*; and because elliptic curve points are additively homomorphic as well, the commitment of the sum of two polynomials is the elementwise sum of their commitments!

Therefore, each coefficient, evaluation, encrypted evaluation, or commitment in a secret sharing may be added with a corresponding value from _another_ secret sharing, to obtain completely valid values of a new secret sharing. If 67 different participants each generate and evaluate their own polynomial $p_j$​, then the coefficients of the summed polynomial $p = p_1 + \ldots + p_{67}$​ are completely secret: even if 66 participants reveal their secret polynomials to each other, it's not enough information to recover $p$.

### **Aggregating PVSS instances**

A major performance issue with distributed key generation arises from _pairwise_ verification; although there may be only 100 validators, and 67 of them acting as dealers of PVSS instances, a straightforward pairwise verification requires 6600 PVSS verification operations for all the validators to verify the correctness of all the secret sharings, a rather expensive cost.

Using the additively homomorphic property of PVSS, the Aggregatable DKG approach observes that the verification steps may be performed by an _aggregator_, who produces an aggregated PVSS instance that is the sum of other PVSS instances, and others only need to check the validity of the aggregated instance (and that the aggregation was done correctly).

In the asynchronous setting, this is somewhat nontrivial, as everyone must agree on the set of PVSS instances to use; on a synchronized blockchain, it's simpler. The unverified PVSS instances are all posted to the blockchain; an aggregator verifies all the posted PVSS instances and posts an aggregation.

## **Threshold cryptography**

Once enough PVSS instances are aggregated on the blockchain, the _public key_ $[p(0)] G$ is revealed, and validators possess their _private key share_ $[p(i)] H$..

While the validators can certainly do polynomial interpolation to recover the _private key_ $[p(0)] H$, the validators should use their generated shares of the private key to create _decryption shares_ of each transaction. Then the interpolation of decryption shares recovers the plaintext of each transaction. The decryption shares are only useful for decrypting a single ciphertext; the private key and private key shares remain secret, and future ciphertexts can also be encrypted to the corresponding public key.

The primary concern with the threshold decryption procedure is _performance_; because of the overhead of each validator doing their share of the threshold decryption protocol, the overall protocol must be extremely lightweight, in order to accommodate hundreds of transactions being decrypted by hundreds of validators, within block timings of only a few seconds.

However, the cutting-edge schemes used in [Ferveo](https://github.com/anoma/ferveo) are designed to be compatible with the elliptic curve group element private keys produced by our PVSS DKG. Threshold public key encryption schemes are not new: [one that uses field private keys](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.119.1717&rep=rep1&type=pdf) and an [identity-based scheme](https://crypto.stanford.edu/~dabo/pubs/papers/ibethresh.pdf) influence a new high performance, chosen ciphertext secure scheme for modern Type 3 pairing-friendly elliptic curves such as BLS12-381.

### **Overview**

Let $e: \mathbb{G}_1 \times \mathbb{G}_2 \rightarrow \mathbb{G}_T$ be the pairing on BLS12-381, and $H_{\mathbb{G}_2}$​​ be a hash-to-group function that hashes to $\mathbb{G}_2$​. $G \in \mathbb{G}_1$​ and $H \in \mathbb{G}_2$​ are the public generators that were used in the distributed key generation.

A threshold encryption scheme allows the encrypter to derive a **shared secret\***$s$\* from the threshold public key $Y = [p(0)]G$, such that 67 validators holding private key shares $Z_i = [p(i)] H$ can also derive the shared secret. Both encrypter and decrypter can use the shared secret to derive a symmetric key.

### **To derive a shared secret**

1. Let _$r$_ be a random scalar
2. Let $s = e([r] Y, H)$
3. Let $U = [r] G$
4. Let $W = [r] H_{\mathbb{G}_2} (U)$

The public key portion of the ciphertext is $(U,W)$ and the derived shared secret is $s$.

### **To Validate a Ciphertext (for Chosen Ciphertext Security)**

Chosen ciphertext security requires that invalid or maliciously crafted ciphertexts are rejected. Given a ciphertext $(U,W)$, validators should check that $e(U, H_{\mathbb{G}_2} (U)) = e(G, W)$ to confirm ciphertext validity.

### **Threshold Decryption**

To derive a shared secret from a ciphertext $(U,W)$, a validator must

1. Check ciphertext validity of $(U,W)$.
2. Construct $C_i = e(U, Z_i)$.

Once 67 values of $C_i$ are available, they can be combined to obtain $s = \prod C_i^{\lambda_i(0)}$ where $\lambda_i(0)$ is the _Lagrange coefficient_ that interpolates over the evaluation domain of those 67 validators. Note that the shared secret is an element of the multiplicative subgroup $\mathbb{G}_T$​.

## **Final Thoughts**

Ferveo includes both a custom-designed distributed key generator and custom-designed threshold decryption scheme intended to meet the performance and security requirements of the underyling consensus mechanism. When optimizations, aggregations, and amortizations are added to the schemes, the distributed key generation and threshold decryption operations achieve the performance needed to run at scale on a production blockchain.

_Written by Joe Bebel, zero-knowledge cryptography researcher & protocol developer at _[_Heliax_](https://heliax.dev/)_, the team building _[_Anoma_](https://twitter.com/anoma)_. _

_If you're interested in zero-knowledge cryptography, cutting-edge cryptographic protocols, or engineering positions in Rust, check out _[_the open positions at Heliax_](https://heliax.dev/jobs)_._
