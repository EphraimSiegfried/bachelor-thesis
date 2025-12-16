
= Related Work

== Snix <snix>

Snix is a re-implementation of Nix in Rust. Although differing internally, Snix implements most Nix interfaces such as the Nix binary interface and the interface to interract with registries such as Nixpkgs. It has individual modules with clear purposes and is more decoupled than the offficial Nix implementation. @snix-overview

It has a custom store implementation where all objects are content addressed. To store objects it uses a Merkle tree with objects similar to objects in Git. @snix-data-model It differs from Git by hashing objects with `BLAKE3` algorithm instead of `SHA1`. It also uses the canonical Protobuf serialization format for serializing trees instead of the error-prone tree encoding Git uses. Furthermore, for identifying blobs Git hashes the content of files with a Git specific prefix. The prefix makes the hash of the file very Git specific and not portable to other content-addressed systems. Snix avoids this by only hashing the file content. @snix-git-difference

Gachix and Snix are quite similar due to Gachix's use of Git for package storage. Snix gains the benefit of fixing Git's specific shortcomings but pays the cost of having to recreate a significant amount of "battle-tested" functionality that Git already provides.

== Laut



