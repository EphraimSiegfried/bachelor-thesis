#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

= Design

== Mapping Nix to Git

=== Nix to Git
- Goal: Store Nix packages in a Git database.
- Map files to blobs
- Map directories to trees
- Model dependencies between packages using commit pointers


---

#set align(center)
#image("../diagrams/nix-filesystem.drawio.pdf", width:35%)

---
#slide[
  #image("../diagrams/nix-filesystem-foo.pdf", width:100%)
][
  #image("../diagrams/gachix-git-model-tree-ps66.pdf", width:100%)
]

---
#image("../diagrams/nix-filesystem-fooman.pdf", width:50%)

---

#image("../diagrams/gachix-git-model-tree-all.pdf", width:70%)

---
#slide[
  #image("../diagrams/nix-filesystem-deps.pdf", width:80%)
][
  #image("../diagrams/gachix-git-model-commits-all.pdf", width:100%)
]
---
== Dependency Management

#set align(left)
=== Dependency Management
- Every package is associated with exactly one commit object
- Parents of the commit are dependencies of the package
- To ensure a global bijective mapping between commit hash and package: #linebreak()
  Set commit message, timestamp, and author field to constant values
#pause
- Maintain mapping between Nix hashes and commit hashes using references in the form: #linebreak()
  `refs/<nix-hash>/pkg`



---
#set align(center)
#image("../diagrams/gachix-git-model.drawio.pdf")

== Binary Cache Protocol
#set align(left)

=== Binary Cache Protocol
- Everytime a package is added to the Git database, the Narinfo is constructed and the reference `/refs/<nix-hash>/narinfo` points to it
- The server transforms package into Nix Archive (NAR) and streams it to the user

---

#set align(center)
#image("../diagrams/gachix-binary-cache-protocol.pdf", width:80%)

== Replication

