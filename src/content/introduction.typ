
= Introduction <introduction>

This project is motivated by the hypothesis that core features of the Nix package manager can be implemented using Git's internal object model. This concept is explored through the development of Gachix, a binary cache for Nix and the primary subject of this thesis.

Gachix uses Git as a backend storage system for Nix packages. By mapping the Nix store's structure directly onto Git objects (blobs, trees, and commits) this project aims to bridge the gap between these two technologies. Functionally, Gachix acts as a binary cache; it serves pre-built binaries and other artifacts to clients that have the Nix package manager installed. It is designed as a complementary tool, rather than a replacement for Nix or the local Nix store.

Adopting Git as a storage layer allows Gachix to inherit several advantageous features. Most notably, it leverages Git’s native deduplication and compression capabilities, which significantly reduces the size of the package database compared to a traditional Nix store. Furthermore, Gachix operates independently of a local Nix installation, allowing it to run on any machine. Finally, by using Git's synchronization protocol, Gachix enables efficient, peer-to-peer package replication and exchange across multiple nodes.
