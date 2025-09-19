== Nix

Nix is a declarative and purely functional package manager. The main purpose of Nix is to solve reproducibility shortcomings of other package managers. When packaging an application with RPM for example, the developer is supposed to declare all the dependencies, but there is no guarantee that the declaration is complete. There might be a shared library provided by the local environment which is a dependency the developer does not know of. The issue is that the app will build and work correctly on the machine of the developer but might fail on the end user's machine. Nix provides a functional language with which the developer can declaratively define all software components a package needs. Nix ensures that these dependency specifications are complete and that Nix expressions are deterministic, i.e. building a Nix expressions twice yields the same result. @nixos-how-nix-works

// TODO: cite https://nixos.org/guides/how-nix-works/

=== The Nix Store

=== Derivations

=== The Deployment Pipeline
