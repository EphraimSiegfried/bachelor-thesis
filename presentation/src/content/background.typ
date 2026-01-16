#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

= Background

== Nix

#slide[
  === Nix Package Manager
  - Declarative and *functional package manager*
  #pause
  - Enforces *reproducibility* in package builds:
    #pause
    - All dependendencies must be specified
    #pause
    - Building a Nix expression twice yields same result
    


][
  #meanwhile
  #set align(center)
  #image("../diagrams/nix_logo.svg", width: 50%)
]

---
#slide[
  === Nix Store
  - *Collection of packages* and other data
  #pause
  - Each entry is *immutable*
  #pause
  - Uniquely *identified by hash* of dependency graph
  #pause
  - Entries are of the form:

    `/nix/store/<hash>-<name>-<version>`

][
  #meanwhile
  #set align(center)
  #image("../diagrams/nix-filesystem.drawio.pdf", width:60%)
]

---

#slide[
  === Deployment Pipeline
  - Nix produces packages from Nix files
  - A Nix file is a build recipe for a package
  #pause
  - Building a package can take a long time #linebreak()
    $arrow.r$ Use binary caches to speed up builds
    


][
  #meanwhile
  #set align(center)
  #image("../diagrams/nix-pipeline-simplified.drawio.pdf", width: 80%)
]

---
#set align(left)
#slide[
  === Binary Cache Protocol
  - Occurs when executing: #linebreak()
    `nix build <some-package>`
  - Protocol over HTTPS
  #pause
  - User asks for *Narinfo*, which contains URL to package contents
  #pause
  - Receives package in the *Nix Archive* (NAR) format


][
  #meanwhile
  #set align(center)
  #image("../diagrams/binary-cache-protocol.drawio.pdf", width: 80%)

]


== Git

#set align(left)
=== Git
- Advertised as distributed version control system
#pause
- Instead a tool for: 
  - Manipulation of a *directed acyclic graph* (DAG)
  #pause
  - *Content-addressable objects* 
  #pause
  - *Replication* of these objects across repositories

---

#slide[
  === Git Objects: Blob and Tree
  - *Blob*: Sequence of bytes, usually stores files
  #pause
  - *Tree*: Collection of pointers to blobs or trees.

][
  #meanwhile
  #set align(center)
  #image("../diagrams/git-tree-blob.drawio.pdf", width:80%)
]

---

#slide[
  === Git Objects: Commit
  - *Commit* contains:
    - Pointer to *exactly one tree*
    #pause
    - *Parent Pointers*: Pointers to other commits
    #pause
    - Author (name and mail)
    - Timestamp
    - Message
][
  #meanwhile
  #set align(center)
  #image("../diagrams/git-commit.drawio.pdf", width:100%)
]

---

#slide[
  === Git Objects: Reference
  - *References*: Pointer to Git objects
  #pause
  - *Direct Reference*: Points to blobs, trees, commits (e.g. branches and tags)
  #pause
  - *Symbolic Reference*: Point to direct references (e.g. HEAD)
][
  #meanwhile
  #set align(center)
  #image("../diagrams/git-references.drawio.pdf", width:100%)
]

---
=== Git Objects
- Blobs, trees and commits are *immutable*
  #pause
- Blobs, trees and commits are *content-addressed* (stored in `.git/objects`)
- References are mutable and identified by a given name (stored in `.git/refs`)

---

=== Replication
- Synchronize objects with `git fetch <refspec>`
- Specify objects with *refspecs*:
  - Constructed as `<remote_references>`:`<local_references>`
  - Copies the specified remote references 
  - *Downloads all objects reachable* from the specified references
  - E.g. the command `git fetch refs/foo:refs/foo` copies refs/foo and downloads all object reachable from it
