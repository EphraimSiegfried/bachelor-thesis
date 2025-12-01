#import "@preview/dmi-basilea-thesis:0.1.1": *
== Nix

Nix is a declarative and purely functional package manager. The main purpose of Nix is to solve reproducibility shortcomings of other package managers. When packaging an application with RPM for example, the developer is supposed to declare all the dependencies, but there is no guarantee that the declaration is complete. There might be a shared library provided by the local environment which is a dependency the developer does not know of. The issue is that the app will build and work correctly on the machine of the developer but might fail on the end user's machine. Nix provides a functional language with which the developer can declaratively define all software components a package needs. Nix ensures that these dependency specifications are complete and that Nix expressions are deterministic, i.e. building a Nix expressions twice yields the same result. @nixos-how-nix-works

=== The Nix Store <nix-store>
The Nix store is a read-only directory (usually located at `/nix/store`) where Nix store objects are stored, which are (most importantly) all binaries of a system and components for building the binaries. Store objects can refer to other store objects. Notably Nix ensures that references in binaries are unique paths to objects in the Nix store. This prevents undeclared dependencies and interference with the system environment. There are two major types of Nix stores, which depend on how these unique paths are stored. The prevalent way is to compute the path by hashing the package build dependency graph (see @input-addressing). There is also an experimental feature where the paths are computed by hashing the resulting binary (see @content-addressing).
#todo-missing[Add figure and example]

Since the hash is computed recursively, any change in the dependencies of an application is reflected in the hash. Thus the hash is a unique identifier for a configuration.

Nix builds the software components in a sandbox. It ensures that in the build process of a component only exclusively declared build and runtime dependencies can be accessed (e.g. `/bin` gets pruned from the environment variable `PATH`) and network access is limited. This makes component builders pure; when the deployer fails to specify a dependency explicitly, the component will fail deterministically. @dolstra-phd

=== Derivations

A derivation (a file with the `.drv` extension) is a build plan that specifies how to create one or more output objects in the Nix store. It is an intermediate artifact generated when a Nix package expression is evaluated, analogous to an object file (`*.o`) in a C compilation process. A derivation consists of:
- A name
- A set of paths to other `drv` files needed in order to build the object.
- An outputs specification, specifying which outputs should be produced, and various metadata about them.
- The system on which the executable will be run.
- The specification of the builder which will produce the object. This is usually a script which defines how to build the package (e.g. `builder.sh`), the shell which executes the script (e.g. `bash`) and all environment variables passed to the shell. @nixdev-derivation

To build a derivation, Nix first ensures all its input derivations are built. It then runs the builder in an isolated sandbox, providing only the resources declared in the derivation. The final result is a immutable output in the Nix store.

We call a derivation _pure_ if it produces the same output regardless of when, where, or by whom it is built, given the same inputs. This implies that in pure derivations there is no network access, since the URL content might change or the server might go down. A derivation is called _fixed_ if the output hash is known and declared before the build process and else it is called _floating_. @nixdev-derivation-outputs

There are different types of derivations, depending on how the derivation output is addressing. In the following the most important types of derivations are explained.

==== Input-Addressing Derivations <input-addressing>
In input-addressing derivations, the output path of the resulting Nix object is computed by hashing all its inputs, more specifically:
- The sources of all input components.
- The script that performes the build.
- Any arguments or environment variables passed to the build script.
- All build time dependencies. @dolstra-phd

Because the hash is computed before the build, input-addressing derivations are fixed. Any change to an input, even a dependency's dependency, alters the final hash, ensuring deterministic builds.

Furthermore, input-addressing derivations must be pure. To illustrate, consider a derivation that fetches a repository's latest commit. Its output is not guaranteed to be consistent over time, as new commits could alter the result. Input-addressing prevents such impurities by requiring all inputs to be fully defined and hashed at the time of derivation creation, thereby proving the build's reproducibility.

==== Content-Addressing Derivations <content-addressing>
The disadvantage of input-addressing derivations is that changes in the inputs that don't alter the resulting Nix object (e.g. a comment in the source code) will also alter the hash and force a rebuild of the derivation. This is prevented in content-addressing derivations which only hash the content of the resulting Nix object. It enables early cutoff, i.e. stopping a rebuild if it can be proven that the end result will be the same as a known object in the Nix store. @nixos-ca-derivations In content-addressing derivations the purity condition is lifted.  #todo[Explain why]

=== The Deployment Pipeline

== Binary Cache Interface <binary-cache-interface>
