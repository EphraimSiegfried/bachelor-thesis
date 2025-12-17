#import "@preview/dmi-basilea-thesis:0.1.1": *
== Nix

Nix is a declarative and purely functional package manager founded by Eelco Dolstra. @dolstra-phd  The main purpose of Nix is to solve reproducibility shortcomings of other package managers. When packaging an application with RPM for example, the developer is supposed to declare all the dependencies, but there is no guarantee that the declaration is complete. There might be a shared library provided by the local environment which is a dependency the developer does not know of. The issue is that the app will build and work correctly on the machine of the developer but might fail on the end user's machine. To solve this issue, Nix provides a functional language with which the developer can declaratively define all software components a package needs. Nix then ensures that these dependency specifications are complete and that Nix expressions are deterministic, i.e. building a Nix expressions twice yields the same result. @nixos-how-nix-works

=== Nix Store <nix-store>
The Nix store is a read-only directory (usually located at `/nix/store`) where Nix stores objects. Store objects are source files, build artifacts (e.g. binaries) and derivations among other things. These objects can refer to other objects (e.g. dependencies in binaries). To prevent ambiguity, every object has a unique identifier, which is a hash. This hash is reflected in the path of the object, which is constructed as `/nix/store/<nix-hash>-<object-name>-<object-version>`. @nixdev-objects

There are two primary methods for computing the hash. The standard approach is to hash the derivation associated with the store object. A derivation is a file specifying the build recipe and the complete graph of dependencies; essentially, this hashes the inputs. @nixdev-input-address There is also an experimental feature where the hash is computed directly from the final contents of the built object itself. @nixdev-content-address The former scheme is known as input-addressing, and the latter as content-addressing.


=== Deployment Pipeline

To produce a package in Nix, a derivation has to be produced. A derivation is a build plan that specifies how to create one or more output objects in the Nix store (it has the `.drv` extension).  It also pins down the run and build time dependencies and specifies what the path of the output will be. It is an intermediate artifact generated when a Nix package expression is evaluated, analogous to an object file (`*.o`) in a C compilation process. 

To build a derivation, Nix first ensures all dependent derivations are built. It then runs the builder in an isolated sandbox. In the sandbox only exclusively declared build and runtime dependencies can be accessed (e.g. `/bin` gets pruned from the environment variable `PATH`) and network access is limited. This makes component builders pure; when the deployer fails to specify a dependency explicitly, the component will fail deterministically. @dolstra-phd The result of the build process is an object in the Nix store. Subsequently, we denote the output objects as artifacts.
 
#figure(image("../diagrams/nix-pipeline.drawio.svg", width: 80%), caption: "Nix Deployment Pipeline") <nix-pipeline>

If an author wants to share a package with others, the author needs to put the Nix expression which produces the artifact in a public registry. The official Nix registry called _Nixpkgs_ is the place where most packages get published. It is maintained as a Git repository stored on GitHub. To add a package there, the author needs to make a pull request with the new package expression to be added. The expression gets reviewed by a trusted set of community members. Once accepted, the Nix expression will be added to the registry.

Users can build packages by specifying the registry and the name of the package. Nix will download the expression from the registry and produce a derivation. The derivation specifies the path of the artifact in the Nix store. To avoid building the artifacts locally, which can take a long time, users can benefit from binary caches, which are called substituers in Nix. With the default installation of Nix, there is only one substituer which is the official binary cache. #footnote[https://cache.nixos.org/] This cache has most artifacts which are in the official Nixpkgs registry. These official artifacts are build on Hydra, which is a continous build system. Using the package identifier retrieved from the derivation, Nix will fetch the package from the binary cache.

Package authors can also publish Nix expressions on a private registry and publish artifacts on a custom binary cache such as Cachix, which is a platform which both hosts and manages binary caches. #footnote[https://www.cachix.org]. The benefit of publishing on the Nixpkgs registry is that artifacts will be made available at the official cache, which is set as trusted and available in every Nix installation.


=== Nix Archive (NAR) Format <nar>

Nix has a custom format for deserializing files and directories which is called Nix Archive (NAR). It is usually used to send packages over the network. It does not compress the contents of files.
The specification of the Nix Archive is displayed in @nar-bnf. The specification closely follows the Extended Backus-Naur form, except for the _str_ function, which writes the size of the bytes to be written, the byte sequence specified and a padding of 0s to a multiple of 8 bytes. @nixdev-nar

#figure(
```
nar = str("nix-archive-1"), nar-obj;

nar-obj = str("("), nar-obj-inner, str(")");

nar-obj-inner
  = str("type"), str("regular") regular
  | str("type"), str("symlink") symlink
  | str("type"), str("directory") directory
  ;

regular = [ str("executable"), str("") ], str("contents"), str(contents);

symlink = str("target"), str(target);

(* side condition: directory entries must be ordered by their names *)
directory = str("type"), str("directory") { directory-entry };

directory-entry = str("entry"), str("("), str("name"), str(name), str("node"), nar-obj, str(")");

```, caption: [Specification of the Nix Archive]) <nar-bnf>

=== Narinfo <narinfo>

A Narinfo is a plaintext metadata file used in Nix binary caches to describe a store object and its associated NAR file. It contains key-value pairs separated by newlines, providing information for retrieving and verifying binary package data. @binary-cache-spec It contains the following keys:

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

=== Binary Cache Interface <binary-cache-interface>

The Nix binary cache interface exposes a set of HTTP endpoints that allow clients to retrieve package metadata and contents. @binary-cache-spec

The core endpoints of the API are:

- `GET /<store-hash>.narinfo` Retrieves the Narinfo (metadata) for a specific store path. The `<store-hash>` corresponds to the unique hash substring found in a package's `/nix/store` path.
- `HEAD /<store-hash>.narinfo` Efficiently checks if a specific package exists in the cache without downloading the full metadata body.
- `GET /<url>` Downloads the compressed NAR (Nix Archive). The exact path for this endpoint is defined dynamically within the URL field of the previously fetched Narinfo file. While the path is configurable, it often follows the pattern `GET /nar/<hash>.nar.<compression>`.


=== Daemon Protocol <daemon-protocol>

The Nix daemon is a service which runs runs Nix specific operations on behalf of non-root users. Most of the operations it can execute, can also be run via the Nix command line interface (CLI). 

The main purpose of the Nix daemon is for multi-user Nix installations. In this mode the Nix store is owned by some privileged user to prevent other users to manipulate the Nix store in a malicious way (e.g. install a Trojan horse). When users use the Nix CLI, control is forwarded to the Nix daemon which is run under the owner of the Nix store. In this scenario, commands to the Nix daemon are dispatched through interprocess communication either via the socket (located at `/nix/var/nix/daemon-socket/socket`). @nixdev-multi-user

There is also another usage of the Nix daemon. Nix is able to connect to remote Nix machines and perform operations on them. The initializer can for example order builds (`nix build --builders <remote-url>`) on the remote machine and fetch packages from the remote store (`nix copy --from <remote-url> <nix-path>`). Internally, Nix does this by connecting to the remote machine via SSH and starting the Nix daemon with `nix daemon --stdio`. This command starts a Nix daemon on the remote machine and makes the remote daemon listen on standard I/O. Subsequently, both nodes communicate via the Nix daemon protocol. @nix-ssh-store

The Nix protocol starts with a handshake, where both parties agree on the protocol version they will use. They also exchange some configuration options. Subsequently there are 47 operations the parties can issue by sending the corresponding Opcode. @nix-daemon-opcodes
