#import "@preview/dmi-basilea-thesis:0.1.1": *
== Git
The official Git documentation advertises Git as a distributed version control system. More abstractly, it is a tool for manipulating a directed acyclic graph (DAG) of content-addressable objects and replicating these objects across repositories. With the internal tools provided by Git (so called plumbing commands), it is possible to use Git as a backend for applications which incorporate a similar DAG-based data structure.

=== Objects
Git objects are immutable and can only be added to the object database. There are four types of objects in Git:
- *Blob (Binary Large Object)*: A blob is a sequence of bytes. It is used to store file data. The metadata of the blob, e.g. whether the file is executable or a symlink, is stored in the object that points to the blob, i.e. a tree.
- *Tree*: A tree is a collection of pointers to trees or blobs. It associates a name and other metadata with each pointer.
- *Commit*: A commit is a record which points to exactly one tree. It also contains the author of the commit, the time it was constructed and it can point to other commits which are called parents.
- *Reference*: A reference is a pointer to a Git object. *Direct References* can point to blobs, trees and commits; they supersede what are commonly known as references and tags. *Symbolic References* point to direct references.
Blobs, trees and commits are compressed and stored in the `.git/objects` directory. All objects in this directory are content addressed, i.e. they are identified by the hash of their contents. References are identified by their chosen name and are stored in `.git/refs`. @git-internals-objects


=== Replication <refspecs>

Git can replicate objects across multiple repositories. One of the replication protocols is the _fetch_ operation. With this operation, a repository can request and download objects from another repository, which are called remotes. The connection to remotes happens via HTTP or SSH.

To specify which objects should be downloaded, a _refspec_ can be used. The _refspec_ specifies which remote references should be downloded to the local repository and how the received references should be named. This operation also downloads all objects which are reachable from the references speciefied. The _refspec_ is a string which is structured as `<remote_references>:<local_references>`. For example, the refspec `refs/foo:/refs/bar` copies the remote reference `refs/foo` and names it `refs/bar` locally and downloads all objects reachable from `refs/foo`. It is also possible to specify multiple references by using globs,  e.g. the reference `refs/heads/*` specifies all references which are in the namespace `refs/heads`. @git-internals-objects
