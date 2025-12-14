= Implementation

This section explains how a binary cache was implemented using the ideas presented in @design. The objective was to create a store for Nix packages using Git and provide them using the common Nix cache interface. The name of this cache is Gachix and the source code is available on Github. #footnote[https://github.com/EphraimSiegfried/gachix]

The project is written in the Rust programming language. This compiled language is ideal for ressource-intensive tasks such as parsing a large number of Nar files. The language is also optimal for concurrent task, which is used in Gachix for serving multiple connections at once. Rust guarantees memory and thread safety. It eliminates many classes of bugs (e.g. use after free) at compile time.

=== Architecture

A high-level overview of the implementation can be seen in @gachix-architecture. The top-level boxes represent the most relevant modules in the code base and the nested boxes their most important functions.

The Command Line Interface (CLI) module gives a friendly interface for interacting with the cache. It also manages the state of the configuration for the binary cache. Gachix can be configured via environment variables or a YAML configuration file. The CLI module merges the configuration options comming from these different sources. With the CLI, the user can start the web server or add a package (and all its dependencies) to the cache.

#figure(image("../diagrams/gachix-architecture.drawio.svg", width: 80%), caption: "Gachix Architecture Overview") <gachix-architecture>


The web server implements the Nix binary interface ( See @binary-cache-interface) and serves clients which connect to it via HTTP. It makes requests to the internal package manager module and forwards responses from it to clients.

The package manager module is the core module. It is responsible for doing the Nix to Git mapping discussed in @nix-to-git. It also includes the _add_closure_ algorithm discussed in @constructing-package-closures. 

The Repository module is mainly a wrapper of the Rust library Git2 #footnote[https://github.com/rust-lang/git2-rs], which is a Rust wrapper of the C++ libgit implementation, which provides low-level Git operations. #footnote[https://libgit2.org/] The Repository module gives abstractions over common Git operations used for the binary cache, e.g. creating commit objects with constant author, message and date values.

The Nix Daemon module is responsible for communicating to either the local Nix daemon (i.e. the daemon which runs on the same machine as Gachix) or to remote Nix Daemons via the SSH protocol. It contains code for setting up SSH connections, retrieving metadata about store paths and retrieving store objects in the Nar archive format. It depends on a custom fork of a library which implements the Nix daemon protocol.#footnote[https://codeberg.org/siegii/gorgon/src/branch/main/nix-daemon]  The fork includes low-level code for retrieving the Nar which did not exist in the original library.

The Narinfo module constructs a Narinfo data structure from the Nix object metadata retrieved from the Nix daemon. It also is able to encode this metadata as a string, which is then stored as a blob in the Git database. Additionally, it signs the signature of the Narinfo and appends it to the narinfo (See @binary-cache-interface).

The Nar module transforms trees to nars and vice versa. It is used to transform nars retrieved from Nix daemons to equivalent Git trees. It encodes trees as Nars when Nix cache clients request packages. It does not have to load the whole Git tree onto memory because it is able to stream the nar, i.e. decode the tree in chunks and serve these chunks continously.


=== Concurrency

To increase the performance of the binary cache, it is crucial to handle requests concurrently. Concurrency can lead to inconsistent state or crashes if handled incorrectly. Inconsistent state happens most often when multiple threads modify the same objects. In Gachix this threat is eliminated by ensuring that threads never modify objects.

Let us consider the two most prevalent operations: Retrieving and adding packages. When a package is retrieved, Gachix looks up the corresponding reference, transfors the referred package tree into a Nar and streams it to the user. The only operations involved in this process are read operations. It does not cause conflict when multiple threads
read the same object at the same time.

Adding a package involves contacting other Gachix peers, fetching Git objects from them or fetching Nars and path metadata from Nix daemons. 


=== Nar

=== Nix Daemon Libraries

=== Content and Input Addressing Schemes

=== Limitations
