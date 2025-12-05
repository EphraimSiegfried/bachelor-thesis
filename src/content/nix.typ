#import "@preview/dmi-basilea-thesis:0.1.1": *
== Nix

Nix is a declarative and purely functional package manager. The main purpose of Nix is to solve reproducibility shortcomings of other package managers. When packaging an application with RPM for example, the developer is supposed to declare all the dependencies, but there is no guarantee that the declaration is complete. There might be a shared library provided by the local environment which is a dependency the developer does not know of. The issue is that the app will build and work correctly on the machine of the developer but might fail on the end user's machine. To solve this issue, Nix provides a functional language with which the developer can declaratively define all software components a package needs. Nix then ensures that these dependency specifications are complete and that Nix expressions are deterministic, i.e. building a Nix expressions twice yields the same result. @nixos-how-nix-works
#todo[Add explicit dolstra reference]

=== Nix Store <nix-store>
The Nix store is a read-only directory (usually located at `/nix/store`) where Nix stores objects. Store objects are source files, build artifacts (e.g. binaries) and derivations among other things. These objects can refer to other objects (e.g. dependencies in binaries). To prevent ambiguity, every object has a unique identifier, which is a hash. This hash is reflected in the path of the object, which is constructed as `/nix/store/<nix-hash>-<object-name>-<object-version>`.

There are two major ways of computing the hash. The prevalent way is to hash the package build dependency graph. #todo[explain dependency graph]. There is also an experimental feature where it is computed by hashing the store object contents. In the first case the addressing scheme is called input-addressing and in the latter content-addressing.


=== Deployment Pipeline

To produce a package in Nix, a derivation has to be produced. A derivation is a build plan that specifies how to create one or more output objects in the Nix store (it has the `.drv` extension). It also pins down the run and build time dependencies and specifies what the path of the output will be. It is an intermediate artifact generated when a Nix package expression is evaluated, analogous to an object file (`*.o`) in a C compilation process.

To build a derivation, Nix first ensures all dependent derivations are built. It then runs the builder in an isolated sandbox. In the sandbox only exclusively declared build and runtime dependencies can be accessed (e.g. `/bin` gets pruned from the environment variable `PATH`) and network access is limited. This makes component builders pure; when the deployer fails to specify a dependency explicitly, the component will fail deterministically. The result of the build process is an object in the Nix store. @dolstra-phd #todo[define artifact]

#figure(image("../diagrams/nix-pipeline.drawio.svg", width: 80%), caption: "Nix Deployment Pipeline") <nix-pipeline>

#todo[replace package author with furix]
A package author might wish to share her package with others. To do this, the author needs to share the package in a registry. The official Nix registry is maintained as a Git repositorystored on Github. To add a package there, the author needs to make a pull request with the new package expression to be added. The expression gets reviewed by a trusted set of community members. Once accepted, the new package will be added to the registry.

Users can build packages by specifying the registry and the name of the package. Nix will download the expression from the registry and produce a derivation. The derivation specifies the path of the output artifact in the Nix store. To avoid building the artifacts locally, which can take a long time, users can benefit from binary caches, which are called substituers in Nix. With the default installation of Nix, there is only one substituer which is the #link("https://cache.nixos.org/")[official binary cache]. This cache has most artifacts which are in the official Nixpkgs registry. These official artifacts are build on Hydra, which is a continous build system. Using the package identifier retrieved from the derivation, Nix will fetch the package from the binary cache.

Package authors can also publish packages on a private registry and publish artifacts on a custom binary cache such as #link("https://www.cachix.org")[Cachix].#todo[say what cachix is] The benefit of using the official registry is that they will be made available at the official cache, which is set as trusted and available in every Nix installation.

=== Binary Cache Interface <binary-cache-interface>

The Nix binary cache interface provides a set of endpoints with which a user can retrieve metadata of packages and package contents.

Package contents are served in the Nar archive format @nixdev-nar. This format closely follows the abstract specification of a file system object tree.#todo[Improve explanation of Nar]

Package metadata is served in the Narinfo format. It is a key value mapping with the following keys:
- *StorePath*: The full store path
- *URL*: The URL of the NAR fetching endpoint, relative to the binary cache
- *Compression*: The compression format of the served NAR
- *FileHash*: The hash of the compressed NAR
- *FileSize*: The size of the compressed NAR
- *NarHash*: The hash of the NAR
- *NarSize*: The size of the NAR
- *Deriver*: The derivation which specifies the store object. It is the basename of the Nix path.
- *System*: The platform type of this binary, if known.
- *References*: A set of store paths which are direct runtime dependencies, separated by whitespace.
- *Sig*: A signature over the StorePath, NarHash, NarSize, and references fields usning ED25519 public-key signature system. 

The most important endpoints of the binary cache API are:

- `GET /<nix-hash>.narinfo`: Retrieves the Narinfo for a given Nix hash, i.e. the hash substring in the path of a package.
- `HEAD /<nix-hash>.narinfo`: Used to check whether a package exists.
- `GET /<url-in-narinfo>`: Returns the compressed nar. This endpoint is dependent on the endpoint given in the URL section of the Narinfo. Commonly, the endpoint is formed as `GET /nar/<nix-hash>.nar.<compression>`. @binary-cache-spec


=== Daemon Protocol
