= Conclusion

In this thesis, we demonstrated that Git’s object model can be effectively used to implement a binary cache, which we named Gachix. Gachix operates as a peer-to-peer system that serves build artifacts to Nix clients without requiring a local Nix installation; instead, it populates its cache via other Gachix peers and Nix daemons.

For storing packages we mapped Nix store objects such as directories and files to equivalent trees and blobs. This approach enabled content-addressable storage, resulting in an 82% reduction in storage size compared to the traditional Nix store.

In order to track the dependencies between packages, we have used commit objects. We associate every package with exactly one commit, where the commit tree contains the contents of the package and the parents of the commit represent the packages's runtime dependencies. This has the benefit of efficiently retrieving the dependency closure of a package and also simplifies the synchronization  between peers. 

Furthermore, we demonstrated that Git trees and blobs can be efficiently transformed into Nix Archives (NARs). This facilitates rapid package delivery to clients; in our benchmarks, Gachix frequently outperformed existing binary cache implementations in terms of serving speed.

Future work should focus on achieving full feature parity with standard Nix binary caches. This includes implementing NAR compression and adding support for missing endpoints, such as `.ls`. Additionally, the replication protocol could be optimized by designing heuristics that prioritize peer contact based on latency. Finally, the trust model could be strengthened by implementing package verification within the distributed system.
