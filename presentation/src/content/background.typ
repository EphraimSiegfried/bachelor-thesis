#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

= Background

== Nix

#slide[
  === Nix Package Manager
  - Functional Language
  #pause
  - Lol

][
  #meanwhile
  #set align(center)
  #image("../diagrams/nix_logo.svg", width: 50%)
]

---
#slide[
  === Nix Store
  - Collection of packages, source files etc.
  - Contains immutable
  #pause
  - Lol

][
  #meanwhile
  #set align(center)
  #image("../diagrams/nix-filesystem.drawio.pdf", width:60%)
]

---

#set align(center)
#image("../diagrams/nix-pipeline.drawio.pdf", width: 60%)


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
  === Git Objects
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
  === Git Objects: Reference
  === Git Objects
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
  === Git Objects
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

=== Replication
- Synchronize objects with `git fetch <remote_references>:<local_references>`
- Specify objects with *refspecs*:
  - Constructed as `<remote_references>`:`<local_references>`
  - Copies the specified remote references 
  - *Downloads all objects reachable* from the specified references
