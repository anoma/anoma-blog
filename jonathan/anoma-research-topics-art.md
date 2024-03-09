---
title: Tracing Anoma Research Topics (ART)
publish_date: 2024-02-16
category: community
image: media/art-01.png
excerpt: ARTs serve as a constant reminder that knowledge is our most valuable resource—and sharing it is our greatest strength. By opening our research in ART reports, we commit to promoting a more resilient and transparent ecosystem around Anoma.
---

A few weeks ago, we launched Anoma Research Topics (ART), a hub for collecting and documenting our research and development efforts, capturing every key step along the way. With this post, we seek to describe the structure of ART both in order to invite external participation and in the hope that this kind of system may be useful for others. Also, I want to give you a brisk walk on how ART came to be, the problems it addresses internally, and its significance to Anoma. For those eager to explore further, we invite you to visit the [ART website](https://art.anoma.net).

**What is ART?**

In line with Anoma's commitment to promoting public goods through open-source projects, ART is an [open-access](https://zenodo.org/communities/anoma-research?q=&l=list&p=1&s=10&sort=newest),[ lightweight, peer-reviewed](https://art.anoma.net/curation-policy.html#submission-process) index of reports. While primarily written and reviewed by Anoma's researchers and engineers, it is open to anyone who wishes to participate.

The ART collection covers [various topics](https://art.anoma.net/scope.html), from distributed systems and cryptography to compilers and blockchains, mapping the theoretical foundations upon which Anoma is built. It is Anoma's core knowledge base, and it is growing. This is what ART represents to us, and each report within is an ART in itself.

**Why does ART exist in the first place?**

Over the past two years, Anoma has developed [numerous ideas and projects](https://github.com/anoma/), and as a concept, [it has evolved](https://anoma.net/talks). The need for a structured system to document ongoing research efforts became clear to us during our Valencia retreat in early 2023 and was further discussed after attending [ETHPrague](https://docs.juvix.org/0.5.5/blog/ethprague/) and ETHCC 2023. The creation of ART for Anoma came about naturally following various discussions and concerns raised during the development process in the last quarter of last year. While I played a significant role in giving ART its [shape](https://research.anoma.net/t/the-anoma-research-topics-community/200), it was truly a collaborative effort with the amazing support of the Anoma team.

**How did ART begin?**

ART began in Autumn 2023. At that time, Anoma had three active compiler projects for three new programming languages using three different technologies by three sub-teams: [Juvix](https://docs.juvix.org) in Haskell, [Geb](https://github.com/anom/geb) in Lisp, and [VampIR](https://github.com/anoma/vamp-ir) in Rust. Together, they offered an end-to-end [solution](https://github.com/anoma/juvix-e2e-demo) that could compile intents as [declarative programs into arithmetic circuits](https://docs.juvix.org/0.5.5/blog/vampir-circuits/), support ZK proofs to some extent, and native binaries for transparent execution, depending on user choice.

During the development process of these compilers, we faced technical issues and risks. We had to question whether we knew up front how feasible the compilers were and whether new techniques would have to be developed to achieve Anoma's needs. But the answers to these questions were rather unclear.

In fact, if you scroll the [list of published ARTs](https://art.anoma.net/list.html) from bottom to top, you will notice a clear pattern. The first few ARTs are all about compilers, all written to address some of these questions. These ARTs helped us make crucial decisions afterward.

While creating compilers can be enjoyable, it requires a lot of time, brain, and resources. After completing our first ART, we wrote a series of papers focusing on our compiler stack: [Geb Pipeline](https://art.anoma.net/list.html#paper-8262747), [Rethinking VampIR](https://art.anoma.net/list.html#paper-8262747), and [VampIR Bestiary](https://art.anoma.net/list.html#paper-8262747). By the end of 2023, these ARTs and further discussions led us to stop the active development of Geb Lisp implementation and VampIR; remember, these were the two primary Juvix backends.

So, although it can be challenging, canceling projects is sometimes necessary. In Anoma, we have seen many positive outcomes from doing so. Indeed, Anoma is better structured internally as a team now; it has a much clearer development roadmap, and following our example above with Juvix, Geb, and VampIR, we now have a better understanding of what we need for Anoma v1 to be feasible and what a compiler for privacy-preserving intents must be able to do.

**Don't Reinvent The Wheel?**

If you think of ART as just a pre-print server to store papers, you are missing out on its full potential. ART is certainly way less sophisticated than other well-known platforms like [Arxiv](https://arxiv.org/), [IACR](https://iacr.org/), and [OpenReview](https://openreview.net/). And even when those platforms have a much broader reach for sure, ART sets itself apart by being Anoma's internal hub. We watch the submissions and the entire editorial and review process take place. This approach ensures that ongoing work is quickly shared across all of our Anoma teams first. In fact, our [peer review process](https://art.anoma.net/review-diagram.html) has become a critical component of our research efforts.

In particular, ART provides a peer review process oriented towards different goals than typical peer review processes of academic conferences or journals, goals which far better serve our overall organizational needs. There are two key differences:

- Academic peer review is sub-discipline-specific and oriented towards logical consistency with and linguistic legibility to the research literature of a particular sub-discipline. ART peer review is oriented towards cross-disciplinary synthesis and holistic relation to the overall Anoma concept.
- Academic peer review cycles are measured in months, while ART peer review cycles are measured in weeks or days. Speed of iteration is crucial for us in order to align timelines across research, engineering, and product functions within Heliax and Anoma.

The practices of companies such as [Microsoft](https://www.microsoft.com/en-us/research/publications/?), which shares its research to a certain extent alongside entities like [Galois](https://galois.com/reports/) and those focusing on topics similar to ours, such as [Ethereum](https://ethereum.org/en/community/research) and [Geometry](https://geometry.dev/notebook), feature research practices that are similar in some aspects and different in others. In particular, we invite members of the research communities surrounding the blockchain industry to both participate in ART and remix the concept into new iterations. Peer review can be an extremely efficient method of knowledge dissemination and research cross-pollination, but it must be designed with one’s specific purpose in mind in order to further it effectively.

**Conclusion**

ART is part of our recent efforts to [transition Anoma from a research project into a viable product](https://www.microsoft.com/en-us/research/uploads/prod/2021/09/Microsoft-Research-Plan.pdf). It helps to distinguish between the research and engineering problems Anoma faces and to address these issues at the appropriate place in the research, engineering, and product pipeline. [Each ART](https://zenodo.org/communities/anoma-research?q=&l=list&p=1&s=10&sort=newest) is there to support this transition, to tackle issues like intent solving, better compilation strategies for functional programs down to zero-knowledge proofs, to learn from successes and failures, and to deal with the unknown. We can now focus on combining all the Lego pieces to make Anoma viable.

ARTs serve as a constant reminder that knowledge is our most valuable resource—and sharing it is our greatest strength. By opening our research in ART reports, we commit to promoting a more resilient and transparent ecosystem around Anoma. If you read ARTs, join us in the [Anoma research forums](https://research.anoma.net/). Feel free to voice your concerns, address uncertainties, and help us improve the specs and any other area that requires improvement. We invite you all to participate! You can learn everything about the ART process on the [website](https://art.anoma.net/).

That’s all, folks. Back to work!

**Acknowledgements**

Thank you to Christopher Goes and apriori for feedback and review.
