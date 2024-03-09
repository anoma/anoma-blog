---
title: Demystifying ZEXE
publish_date: 2021-07-12T00:00:00.000Z
category: cryptography
excerpt: ZEXE is a ledger-based system that allows for the running of multiple applications atop the same ledger in a way that transactions reveal no information about the particular computations which are performed.
image: media/Untitled-17.png
---

## Introduction

ZEXE is a ledger-based system that allows users to execute arbitrary computations offline and produce transactions that attest to the correctness of these computations via the use of zero-knowledge proofs. ZEXE's approach aims to achieve not only data privacy (hiding all of the user data), but also **function privacy**, which stands for the inability (of an observer) to distinguish functions executed offline from one another. Private offline computations might represent state transitions of various applications (e.g. tokens, markets, elections, etc), all running on top of the same ledger.

## From Zerocoin to Zerocash and beyond

### Zerocoin

One of the ways to improve the anonymity properties of a cryptocurrency is to use a _mixer_ which obfuscates a user's transaction history. To mix, users send their coins to an intermediary and retrieve different coins deposited by other users. Zerocoin was designed as a decentralized mixer for Bitcoin. By a series of exchanges like bitcoin **→** zerocoin **→** bitcoin, a user replaces the old coins with the same amount of new ones that cannot be linked to the coins which were sent to the mix. The unlinkability property is achieved through the use of zero-knowledge proofs and commitment schemes.

##### **Bitcoin → zerocoin**

To mint a zerocoin from a bitcoin, you generate a serial number $sn$ (which uniquely identifies the coin), create a commitment $COMM_r(sn)$ with the use of some randomness $r$, and send a commitment transaction to the ledger.

##### **Zerocoin → bitcoin**

To redeem a coin, you have to prove in zero-knowledge that you know the value $r$ such that $COMM_r(sn)$ exists on the ledger. You put the proof into a transaction along with the serial number $sn$ and send it to the ledger. Since $r$ is hidden under zero-knowledge proof, it is impossible to know which of the committed coins has been redeemed, and, as a result, it is impossible to find a link to the initial bitcoin. Publishing $sn$ ensures that no coin is spent twice.

### Zerocash

Zerocash is a digital currency scheme that allows direct payments of any amount and is based on Zerocoin. To create a full-fledged payment system based on the Zerocoin protocol, Zerocash introduces some functionalities, like the ability to send coins from one user to another or to send an arbitrary amount of a certain coin in just one transaction. Zerocash provides strong data privacy guarantees by hiding the coin values and user identities. ZEXE can be seen a generalization of Zerocash that achieves data and function privacy.

## What is function privacy, anyway?

In Zerocash, each transaction contains a zero-knowledge proof that proves value conservation in this transaction, namely, that the sum of all spent coin values equals the sum of all of the created coin values: $\sum_i v_i^{old} = \sum_j v_j^{new}$. If Alice wants to give $x$ coins to Bob and Charlie, Bob receives $y$ coins from Alice, and Charlie receives $z$ coins from Alice, it has to be that $x = y + z$. The value conservation predicate represents some kind of computation over the coin values. Imagine now that we have two user-defined assets, $A_1$ and $A_2$, that use the same ledger to store transactions (e.g. the Ethereum platform which supports many contracts, each of which represents a distinct currency). Even if each of them adopted a Zerocash-like protocol to achieve data privacy, the transaction would still reveal which exact token has been exchanged, $A_1$ or $A_2$, or, in other words, what computation has been executed. _Function privacy stands for the inability to distinguish one type of computation from another_. In that case, function privacy would not hold. In Zerocash, function privacy is achieved for trivial reasons: having only one type of computation performed in every transaction means that transactions are not distinguishable by looking at the computation performed in it.

## Achieving function privacy

What we want is to have multiple types of computations on the same ledger. But if we just start performing various computations without additional changes, function privacy would not hold. To achieve function privacy for a ledger with multiple transaction functions, a new cryptographic primitive called **decentralized private computation** (DPC) is introduced. DPC can be seen as a generalization of the Zerocash approach that makes anonymous execution of arbitrary computations on arbitrary data units possible.

### From coins to records

A **record** is a unit of data with an arbitrary payload. Records are a generalized notion of a coin, but instead of holding a integer coin value $v$, a record holds an arbitrary payload $p$. Like coins, records have an owner, they can be created and consumed, and each transaction has records as input and output values (as in the UTXO model). As in Zerocash, to create a record, you have to send a commitment to the ledger, and the record's serial number is revealed when the record is consumed, while the corresponding randomness is hidden by a zero-knowledge proof. Records can be used for various kinds of computations. To achieve function privacy in the presence of multiple functions, we need a way to make these computations indistinguishable from one another. The trick here is to use a universal function and store the "real" functions as a payload of the record. All of the transactions in the system would then implement just one function, the universal one, and all of the details related to the real functions are hidden in the payload. The _record nano-kernel_ (RNK) defines a set of rules for computing on records.

## The record nano-kernel (RNK)

Each record has a _payload_, a _birth predicate_ $\Phi_b$ and a _death predicate_ $\Phi_d$. A birth predicate has to be satisfied when the record is being created, and a death predicate has to be satisfied when the record is being consumed. The RNK ensures that both conditions are met, so that during the whole lifetime of a record, particular constraints are being enforced. Predicates can see the contents of the entire transaction, which include:

- contents of every record (its payload, birth and death predicates, etc)

- _transaction memorandum_: shared memory that is published on the ledger (e.g. commitments, serial numbers of consumed records)

- _auxiliary input_: shared memory that is not published on the ledger

Based on the input data, predicates can decide which kinds of interactions with the record are permitted and which are prohibited, which allows records to communicate with each other in a secure manner. For example, a record may decide to not interact with records with a payload that does not satisfy certain properties, or allow interactions only with the records that have certain types of birth or death predicates. A transaction is considered valid only if death predicates of all consumed records and birth predicates of all created records are simultaneously satisfied. To prove its validity, each transaction contains a zero-knowledge proof that attests to the satisfaction of these predicates. To achieve efficiency, one layer of recursive proof composition is used. That means there are actually two proofs present: the inner one proves that the predicates are satisfied as requested, and the outer one proves that the inner proof is valid. The inner proof can be computed offline, and the outer proof ensures that it is computed correctly. Both inner and outer proofs are succinct, which means that verifying them is cheap. The outer proof has to be zero-knowledge, and because of that, the inner proof does not have to be.

### Records in details

Each record has its own address public key $apk$ that specifies the owner of the record. As in Zerocash, to create a record, one has to create a commitment $cm$ to the data the record contains, and to consume a record, one must reveal its serial number $sn$, which cannot be computed without the address secret key $ask$ that corresponds to the $apk$. That means only the person that holds $ask$ can consume the record. Address secret key $ask = (sk_{PRF}, r_{pk})$ consists of a secret PRF key $sk_{PRF}$ and commitment randomness $r_{pk}$. The address public key $apk = COMM_{r_{pk}}(sk_{PRF})$ is a perfectly hiding commitment to $sk_{PRF}$ with randomness $r_{pk}$. The key $sk_{PRF}$ is used to compute record's serial number: $sn = PRF_{sk_{PRF}}(\rho)$, where $\rho$ is a serial number nonce that is also stored in the record. To sum up, a record contains a:

- address public key $apk = COMM_{r_{pk}}(sk_{PRF})$

- birth predicate $\Phi_b$

- death predicate $\Phi_d$

- data payload

- serial number nonce $\rho$

- commitment $cm$ to all of the above

### Dummy records

Dummy records are a feature that came from old protocols where the number of inputs and outputs were constant for each transaction. In ZEXE, dummy records can be freely created, but consuming them requires the satisfaction of their death predicate. Data stored in dummy records are not checked and are not used anywhere. A nice feature of dummy records is that they hide the real number of inputs and outputs of a transaction, since there is no mechanism to distinguish dummy records from non-dummy records. A user can only know an upper bound of the number of non-dummy records created/consumed in the transaction. Dummy records might also be useful to implement some logic in predicates.

## Delegable DPC

To ensure that the birth and death predicates are satisfied, the user has to provide a corresponding zero-knowledge proof, which is a problem for users of weak devices (e.g. mobile phones). The delegable DPC scheme aims to solve this problem. Delegable DPC scheme allows a user to delegate the creation of a proof to a worker and then include the proof in the transaction. The core idea is to split the secret key $ask$ , so that the part needed to produce a cryptographic proof is separate from the part needed to authorize the transaction, then give the worker the first part and keep the second part hidden. This way, the worker can only produce a proof, but cannot use it to create a transaction since the worker has no access to the remaining part of the secret key. To achieve this, **randomizable signatures** are used. Randomizable signatures allow the randomization of public keys and signatures to prevent linking across multiple signatures. Each user is given a signing key pair $pk_{SIG}, sk_{SIG}$, where $pk_{SIG}$ is embedded into the $apk$ , and $sk_{SIG}$ is used for transaction authorization only. Now the user sends the data needed to produce a proof (including the secret key $sk_{PRF}$) to a worker, signs the produced proof with the secret key $sk_{SIG}$, randomizes the resulting signature, and includes it in the final transaction. Since the worker does not know the signing key $sk_{SIG}$, it is impossible to produce a valid transaction.

### Randomizable signatures

The idea behind randomizable signature schemes is that every time we compute a signature of a message, we update both the public key and signature so that the randomized public key can be used to verify the randomized signature, but the value of both is different from the previous ones. For example, consider a Schnorr signature scheme. Suppose we have a signing keypair $(pk = g^x, sk=x)$ and the signature is computed as $\sigma = (s = k - xe, e = H(g^k||m))$, where $k$ is some random scalar. We can randomize the public key and signature using a random value $r_{SIG}$ (in case of ZEXE, $r_{SIG}=PRF_{sk_{PRF}}(\rho)$) as such: $\hat{pk} = pk * g^{r_{SIG}}$ $\hat{\sigma} = (s - e*r_{SIG}, e)$ Informally, having a signature $(s, e)$ and public key $pk_{SIG}$, the signature verification algorithm looks like:

- compute $r_v = g^spk_{SIG}^e$

- compute $e_v = H(r_v || m)$

- check if $e == e_v$

If we have a randomized signature $\hat{\sigma} = (\hat{s}, e)$ and the corresponding randomized public key $\hat{pk}_{SIG}$, the public key randomness cancels the signature randomness: $\hat{r}_v = g^{\hat{s}} * \hat{pk}_{SIG}^e = g^{s - e*r_{SIG}}* g^{xe + e*r_{SIG}} = g^{s + xe} = g^s * pk_{SIG}^e = r_v$ Note that the signature and public key have to be randomized with the same value $r_{SIG}$ to match.

### Threshold and blind transactions from delegable DPC

The delegable DPC scheme enables the creation of threshold and blind transactions. A transaction is called threshold if there are $n > 1$ parties that hold shares of the authorization key $sk_{SIG}$ and any $t$ of them is enough to sign the transaction. Since the randomization occurs after the key and the signature has been created, it is enough to use the existing protocols for threshold or blind signatures, and then randomize it. In order to produce a threshold transaction using a delegable DPC scheme, one must use a signature scheme that allows for _threshold key generation_ and _threshold signing_ algorithms. To create a blind transaction, a signature scheme that has a _blind signing_ algorithm must be used.

## Use case 1: user-defined assets

To wrap things up, let's consider some ZEXE use cases. To create a custom system on top of DPC, we have to define rules for that system. To do that, we define birth and death predicates and describe the expected content of a record's payload. So, the system is defined by the content of records. First, we consider a transaction format where there are exactly two input and two output records. For a record that represents a coin of a user-defined asset, we create a birth predicate that is called Mint-or-Conserve. It is called that because it can work in two modes: mint mode and conserve mode. In mint mode, the birth predicate creates an initial supply $\textrm{v}$ of the asset and a unique asset identifier $id$. The payload of the output genesis record is $(id, \textrm{v}, v = \textrm{v})$ where $v$ is the record's value. A unique asset identifier $id$ is derived from the serial numbers of consumed input records: $id = COMM_r(sn_1 || sn_2)$. Since serial numbers are unique values, a binding commitment property guarantees that the value of $id$ is unique as well. In conserve mode, MoC checks that for all records in this transaction with the same MoC, and the same asset id the value conserves (just like in Zerocash, the sum of the values of input records equals the sum of output records values). So, if Alice wants to send some of tokens to Bob, Alice creates a transaction with an input record to consume, a dummy input record, and two output records: the first one is owned by Bob, and the second one is owned by Alice and represents the remaining tokens.

## Use case 2: private DEXs

Now that we can create user-defined assets, how do we exchange them? We will use a decentralized exchange (DEX), a ledger-based application that allows trading digital assets. To implement a private DEX, in addition to the MoC birth predicate we define exchange-or-cancel (EoC) death predicate. Called in exchange mode, EoC allows consumption of the record by exchanging it for some units of another asset $A_2$. In cancel mode, EoC allows canceling the exchange by sending the tokens to a specified address $apk$ (back to the owner).

### Intent-based DEXs

In _intent-based_ DEXs, there is an index table where makers publish their intents to trade (e.g. 5 units of asset $A_1$ for 10 units of asset $A_2$). An interested taker T can contact the maker M, agree on the terms, and produce a transaction. 1. M publishes the intent to trade 5 units of $A_1$ for 10 units of $A_2$ 2. T contacts M to agree on trade terms, creates a record with 10 units of $A_2$ and an EoC death predicate that specifies the record can only be spent if exchanged for 5 units of $A_1$ and sends it to M with all the information that needed to redeem the record 3. Now M can create an exchange transaction with the EoC predicate in exchange mode or cancel the exchange with the EoC predicate in cancel mode. Since the predicates and the payload of the records are hidden under the zero-knowledge proof, no private information is revealed. Note that M does not have to create a transaction right away, and until the moment of the actual exchange, token prices might change (e.g. 5 units of $A_1$ were equivalent to 10 units of $A_2$ when T created a record, but later 5 units of $A_1$ were equivalent to just 5 units of $A_2$), so the exchange becomes more profitable for one of the parties and, conversely, less profitable for the other.

### Order-based DEXs

In _order-based_ DEXs, makers publish the records along with the information needed to redeem them upfront in an order book. In _open-book_ DEXs, the taker picks an order from the order book, while in _closed-book_ DEXs a taker is matched with a giver off-chain by the order book operator.

### Open-book DEXs

1. If M wishes to trade 5 units of $A_1$ for 10 units of $A_2$, she creates a record with 5 units of $A_1$, an EoC death predicate that specifies the record can only be spent if exchanged for 10 units of $A_2$ and publishes it in an order book along with the information needed to redeem the record.

2. T can create an exchange transaction with the EoC death predicate in exchange mode, or cancel the exchange with the EoC predicate in cancel mode. Since the predicates and the payload of the records are hidden under the zero-knowledge proof, no private information is revealed, but since the transaction reveals the serial number of the record, it can be linked with the order (the serial number is a part of the data required to know to redeem a record) which reveals the assets and amounts being exchanged.

### Closed-book DEXs

1. If M wishes to trade 5 units of $A_1$ for 10 units of $A_2$, she creates a record with 5 units of $A_1$, an EoC death predicate that specifies the record can only be spent if exchanged for 10 units of $A_2$ and sends it to the order book along with the information needed to redeem the record.

2. Now T publishes a record with 10 units of $A_2$ and an EoC death predicate that specifies the record can only be spent if exchanged for 5 units of $A_1$, and sends it to the order book along with the information needed to redeem the record.

3. An order book operator creates a transaction that consumes the matching records. Since orders are not published, the amounts and assets are revealed only to the order book operator.

# Final thoughts

With the addition of function privacy to the data privacy property, ZEXE allows multiple applications to use the same ledger in a way that the transactions belonging to one application are indistinguishable from the transactions of the other application, which enhances the anonymity guarantees for both. The introduced design enables ways for applications to interact with each other naturally, by programming the terms and conditions in birth and death predicates. Offline computations with the use of succinct zero-knowledge proofs allow the system to be efficient, and the delegating option lowers the system requirements and hence expands the set of devices able to participate.

_Written by Yulia Khalniyazova, zero-knowledge cryptography researcher & protocol developer at _[_Heliax_](https://heliax.dev/)_, the team building _[_Anoma_](https://twitter.com/anoma)_._

_If you're interested in zero-knowledge cryptography, cutting-edge cryptographic protocols, or engineering positions in Rust, check out _[_the open positions at Heliax_](https://heliax.dev/jobs)_._
