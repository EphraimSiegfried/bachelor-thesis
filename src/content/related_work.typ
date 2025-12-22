
= Related Work

== Snix <snix>

Snix is a re-implementation of Nix in Rust. Although differing internally, Snix implements most Nix interfaces such as the Nix binary interface and the interface to interract with registries such as Nixpkgs. It has individual modules with clear purposes and is more decoupled than the offficial Nix implementation. @snix-overview

It has a custom store implementation where all objects are content addressed. To store objects it uses a Merkle tree with objects similar to objects in Git. @snix-data-model It differs from Git by hashing objects with `BLAKE3` algorithm instead of `SHA1`. It also uses the canonical Protobuf serialization format for serializing trees instead tree encoding Git uses. Furthermore, for identifying blobs Git hashes the content of files with a Git specific prefix. The prefix makes the hash of the file very Git specific and not portable to other content-addressed systems. Snix avoids this by only hashing the file content. @snix-git-difference

Gachix and Snix are quite similar due to Gachix's use of Git for package storage. Snix gains the benefit of fixing Git's specific shortcomings but pays the cost of having to recreate a significant amount of "battle-tested" functionality that Git already provides.

== Extending Cloud Build Systems to Eliminate Transitive Trust

In the paper _Extending Cloud Build Systems to Eliminate Transitive Trust_, the authors address the issue of trust within the Nix package supply chain. @laut

Under the current trust model, each package possesses a fingerprint that consists of its input hashes and an output hash. This fingerprint is signed using the private key of a binary cache (or a Nix builder). A Nix user maintains a set of public keys for trusted caches, which allows them to verify that a package originates from a valid source. Once the signature is verified, the user implicitly trusts the mapping between the input hashes and the resulting output hash.

However, the authors highlight a critical limitation: the Nix user cannot currently verify whether a package was actually compiled by a trusted builder. To resolve this, the authors propose a solution that extends the signature mechanism, enabling the user to cryptographically verify that the package originated specifically from a trusted builder.

The new fingerprinting mechanism presented in the paper could be incorporated into future versions of Gachix. By doing so, a Nix user would no longer need to place trust in the Gachix instance itself, but could instead rely solely on the builder's signature.

