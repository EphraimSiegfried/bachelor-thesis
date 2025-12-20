#import "@preview/dmi-basilea-thesis:0.1.1": *
= Evaluation

This section shows independently verifiable features of Gachix. The following claims about Gachix are made:

1. Gachix is faster in package retrieval than existing cache implementations in 47.4 % of the cases but slower on average. (@pkg-retrieval-latency)
2. Gachix is more storage efficient than other cache services. (@package-storage)
3. Gachix can be deployed on any Unix machine, including on systems without Nix installed. (@unix-deployment)
4. Gachix is transparent to Nix users as it can be used to fetch Nix packages using the Nix substituers interface. (@nix-transparency)

Because we compare Gachix with similar projects, we will present these projects in @other-caches. The specifications for the benchmarking environment are detailed in @machine-spec.

== Functional Comparison to other Cache implementations <other-caches>

There are a few projects which implement the Nix binary cache interface. The most notable ones are:

- *nix-serve*: This is the first cache implementation developped by Eelco Dolstra (i.e. the founder of Nix). #footnote[https://github.com/edolstra/nix-serve] It is written in Perl.
- *nix-serve-ng*: This is the successor of nix-serve. It is written in Haskell. #footnote[https://github.com/aristanetworks/nix-serve-ng]
- *harmonia*: This is a modern implementation of the binary cache interface with many features. #footnote[https://github.com/nix-community/harmonia] It is written in Rust.

A notable difference between Gachix and the caches presented above is the other caches directly use the Nix store for storing packages. If a Nix user wants to serve her packages with Gachix, she has to copy the packages from the Nix store to Gachix. With the other implementations, this is not necessary.

On the other hand, the benefit of using Gachix is that it does not rely on any Nix infrastructure (such as the Nix store) and it can be deployed on a Unix machine without Nix installed. All other implementations expect that Nix is installed on the host machine.

== Test Machine Specification <machine-spec>

#todo[write specs: hardware annd software]

== Package Retrieval Latency <pkg-retrieval-latency>

To test whether the retrieval speed of packages is acceptable, Gachix was compared against the cache services presented in @other-caches. 

=== Methodology

In this benchmark 1000 random packages from the official Nix registry were added to the Nix store and to the Gachix cache. Each cache service was then started and for each package the Narinfo and the NAR was fetched. The end-to-end latency (request sent to full response received) was measured for each request.

=== Result
The average fetch latency for Narinfo is presented in @avg-narinfo-fetch-time. The average Narinfo retrieval speed is around 0.001 for almost all services except _nix-serve_, which has an average latency of 0.0082 seconds. 

#figure(image("../diagrams/avg-narinfo-fetch-time.png", width: 100%), caption: [Average Narinfo Fetch Time by Cache Service])<avg-narinfo-fetch-time>

The average package fetch time by cache service is shown in @avg-pkg-fetch-time. With an average latency of 0.01159 seconds _harmonia_ is the fastest cache service on average closely followed by _gachix_, which has an average latency of 0.014278 seconds. 

#figure(image("../diagrams/avg-pkg-fetch-time.png", width: 100%), caption: [Average Package Fetch Time by Cache Service])<avg-pkg-fetch-time>

The pie chart in @fastest-services shows which services were the fastest among all services. The services _gachix_, _harmonia_ and _nix-serve-ng_  have an almost equal number of times where they served packages the fastest. Nevertheless _gachix_ has shown to be the fastest most times by having been fastest in 474 cases out of 1000.

#figure(image("../diagrams/fastest-services.png", width: 100%), caption: [Average Package Fetch Time by Cache Service])<fastest-services>

=== Discussion

The reason why _nix-serve_ has a much slower latency than the other services is probably because Perl (the language that nix-serve was written in) is an interpreted language and all other languages are compiled.

It is interesting that _gachix_ performs well in the package retrieval benchmark because it needs to decompress Git objects when constructing the NARs which the other services don't have to because everything in the Nix store is stored as decompressed.

Gachix demonstrates strong performance, achieving a package latency very near the best average and proving to be the fastest in the majority of test cases. It is interesting that _gachix_ performs well because it needs to decompress Git objects when constructing the NARs which the other services don't have to because everything in the Nix store is stored as decompressed. 

From the results we can conclude that _gachix_ is reasonably fast and can compete with other products in this area. 

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




== Package Storage <package-storage>

This benchmark compares the disk storage usage of Gachix to the cache services presented in @other-caches. Given that all services use the Nix store and Gachix uses Git as its primary storage for Nix packages, the comparison is more accurately one between the Nix store and the Git database.

=== Methodology

In this experiment, 1000 randomly selected packages were added to both the Nix store and Gachix.

To assess storage consumption, the total storage used by Gachix was measured by the size of its `.git` directory. This was compared against the sum of the size of all 1000 packages in the Nix store.

Note on Comparison: The sum of the package sizes in the Nix store serves as a lower-bound estimate for the storage required by other cache services. This estimate is conservative because it does not account for potential operational overhead or internal metadata that other caching mechanisms might introduce.


=== Result

The sum of the package sizes in the Nix store is 3.88 GB. The size of the `.git` repository is 0.68 GB. This is a size reduction of 82.47%.

=== Discussion

There are two reasons why we observe this size reduction. Firstly, Gachix compresses its objects using zlib. @git-internals-objects. The Nix store does not contain any compressed packages. 

Secondly, since the Git object database is a Merkle tree and every object is identified by its hash, identical files in the Nix store are only stored once in the Git database. This deduplication of files is also a reason why the size is smaller in Gachix.

== Deployment on any Unix Machine <unix-deployment>

This section shows that Gachix can be deployed on Unix machines without Nix installed.

=== Methodology

For this experiment a Dockerfile was written which can be found on the Gachix repository. #footnote[https://github.com/EphraimSiegfried/gachix/blob/master/Dockerfile] In this Dockerfile Gachix is built in an environment with Rust installed. After the Gachix binary is built, it is placed in a seperate Ubuntu container, where the binary will be run. The experiment proceeded as follows:

- Clone the Gachix source repository
- Build the docker container with `docker build <gachix-repository-path> . -t gachix`
- Run the container with `docker run gachix`
#todo[show that packages can be added to the binary cache, currently it starts the server with 0 packages. ]

=== Result
After executing these steps, we can see that Ubuntu container was able to replicate a package from a Nix host. It is also able to serve the package via the Nix binary interface.

=== Discussion
#todo[what should I write here?]

== Nix Transparency <nix-transparency>
This experiment verifies whether Gachix correctly implements the Nix binary interface. We confirm this by demonstrating that a user can successfully substitute (fetch) a package using the standard Nix command line tools backed by Gachix.

=== Methodology

In this test we add the package _hello_ (a standard lightweight example frequently used for testing) to Gachix.   We then use the `nix build` command which will try to substitute the package by using binary caches. The experiment proceeds through the following steps:

+ We create a key pair which is used for signing Narinfos with ``` nix-store --generate-binary-cache-key my-gachix-cache key.private key.public```
+ We add a package to Gachix with ``` GACHIX__STORE__SIGN_PRIVATE_KEY_PATH=key.private gachix add $(nix build nixpkgs#hello --no-link --print-out-paths)```. The subcommand `nix build nixpkgs#hello --no-link --print-out-paths` will add the package _hello_ to the Nix store and print the path of the package to _stdout_. The environment variable `GACHIX__STORE__SIGN_PRIVATE_KEY_FILE` tells Gachix where the private key is located (this could have also been configured using a YAML file).
+ We remove the package from the local Nix store to prevent a local cache hit and ensure the package must be fetched remotely.: `nix store delete nixpkgs#hello`
+ We can now start the Gachix HTTP binary cache server with `gachix serve`. By default this listens on: `http://localhost:8080`.
+ Finally, we fetch the hello package again, explicitly designating the Gachix server as the substituter: ``` nix build nixpkgs#hello --substituters http://localhost:8080 --trusted-public-keys $(cat key.public) -vv --no-link```. Substituters and trusted public keys are normally specified in a Nix configuration file but can be overridden in the command line.

Note that in this test the Nixpkgs registry is pinned to the commit hash `d9bc5c7dceb30d8d6fafa10aeb6aa8a48c218454`. However, this specific version does not affect the validity of the results.

=== Result

Upon running the final command, the output logs should display the following:
```
copying path '/nix/store/2bcv91i8fahqghn8dmyr791iaycbsjdd-hello-2.12.2' from 'http://localhost:8080'...
downloading 'http://localhost:8080/nar/cd533301f886090bb173bee7a3aaa67a2b140a8d.nar'...
```

=== Discussion
This output confirms that Nix successfully fetched the binary from Gachix. Without the `--substituters` and `--trusted-public-keys` flags, Nix would have ignored the server, built the package locally, and logged the compilation steps instead.

Notice that setting `trusted-public-keys` only works if the user executing the Nix command is marked as trusted.

