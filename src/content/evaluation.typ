= Evaluation


== Functional Comparison to other Cache implementations <other-caches>

There are a few projects which implement the Nix binary cache interface. The most notable ones are:

- *nix-serve*: This is the first cache implementation developped by Eelco Dolstra (i.e. the founder of Nix). #footnote[https://github.com/edolstra/nix-serve] It is written in Perl.
- *nix-serve-ng*: This is the successor of nix-serve. It is written in Haskell. #footnote[https://github.com/aristanetworks/nix-serve-ng]
- *harmonia*: This is a modern implementation of the binary cache interface with many features. #footnote[https://github.com/nix-community/harmonia] It is written in Rust.

A notable difference between Gachix and the caches presented above is the other caches directly use the Nix store for storing packages. If a Nix user wants to serve her packages with Gachix, she has to copy the packages from the Nix store to Gachix. With the other implementations, this is not necessary.

On the other hand, the benefit of using Gachix is that it does not rely on any Nix infrastructure (such as the Nix store) and it can be deployed on a Unix machine without Nix installed. All other implementations expect that Nix is installed on the host machine.

== Execution Speed

To test whether the retrieval speed of packages is acceptable, Gachix was compared against the cache services presented in @other-caches. 

=== Package retrieval

In this benchmark 500 random packages from the official Nix registry were added to the Nix store and to the Gachix cache. Each cache service was then started and for each package the Narinfo and the Nar was fetched. The average fetch time for Narinfo is presented in @avg-narinfo-fetch-time.

#figure(image("../diagrams/avg-narinfo-fetch-time.png", width: 100%), caption: [Average Narinfo Fetch Time by Cache Service])<avg-narinfo-fetch-time>

The average Narinfo retrieval speed is around 0.001 for almost all services except _nix-serve_, which is quite slow. This is probably because Perl (the language that nix-serve was written in) is an interpreted language and all other languages are compiled.

The average package fetch time by cache service is shown in @avg-pkg-fetch-time. We can see that _harmonia_ is the fastest cache service on average closely followed by _gachix_. It is interesting that _gachix_ performs so well because it needs to decompress Git objects when constructing the Nars which the other services on't have to because everything in the Nix store is stored as plain files. 

#figure(image("../diagrams/avg-pkg-fetch-time.png", width: 100%), caption: [Average Package Fetch Time by Cache Service])<avg-pkg-fetch-time>

The pie chart in @fastest-services shows which services were the fastest. We can see that _gachix_, _harmonia_ and _nix-serve-ng_  have an almost equal number of times where they served packages the fastest. Nevertheless _gachix_ has shown to be the fastest most times.  

#figure(image("../diagrams/fastest-services.png", width: 100%), caption: [Average Package Fetch Time by Cache Service])<fastest-services>

Thus we can conclude that _gachix_ is reasonably fast and can compete with other products in this area. 

// #figure( table(  
//   columns: (1fr, auto, auto),
//   inset: 10pt,
//   align: horizon,
//   table.header(
//     [*Service*], [*Package Retrieval Speed*], [*Narinfo Retrieval Speed*]
//   )
//   , [nix-serve], [0.122157], [0.001182],
//     [nix-serve-ng], [0.120619], [0.008471],
//     [harmonia], [0.086700], [0.001321],
//     [gachix], [0.072806], [0.001087]
// )
// , caption: [Average Package and Narinfo Fetch Time by Cache Service])<avg-fetch-time>

// #figure(image("../diagrams/average-fetch-time.png", width: 100%), caption: [Average Package and Narinfo Fetch Time by Cache Service])<avg-fetch-time>




=== Package upload

== Functional Tests

