== Git
Git is advertised as a distributed version control system. More generally, it is a tool for manipulating a directed acyclic graph of objects and replicating these objects across repositories.

=== Objects
Git stores objects in a append-only manner. Objects can only be added to the object database and never be modified. There are four types of objects in Git:
- *Blob (Binary Large Object)*: A blob is a sequence of bytes. It is used to store file data. Its semantics, e.g. whether the file is executable or a symlink, is stored in the object that points to the blob, i.e. a tree.
- *Tree*: Is a collection of pointers to trees or blobs. It associates a name and other metadata with each pointer.
- *Commit*: Is a data structure which points to exactly one tree. It also records the author of the commit, the time it was constructed and it can point to other commits which are called parents.
- *Reference*: Is a pointer to a Git object. *Direct References* can point to blobs, trees and commits. *Symbolic References* point to direct references.
Blobs, trees and commits are compressed and stored in the `.git/objects` directory. All objects in this directory are content addressed, i.e. they are identified by the hash of their contents. References are identified by their chosen name and are stored in `.git/refs`. @git-internals-objects


=== Replication <refspecs>

Git can replicate objects across multiple repositories. One of the replication protocols is the _fetch_ operation. With this operation, a repository can request and download objects from another repository, which are called remotes. The connection to remotes happens via HTTP or SSH. 

To specify which objects should be downloaded, a _refspec_ can be used. The _refspec_ specifies which remote references should be downloded to the local repository and how the received references should be named. This operation also downloads all objects which are reachable from the references speciefied. The _refspec_ is a string which is structured as `<remote_references>:<local_references>`. For example, the refspec `refs/foo:/refs/bar` copies the remote reference `refs/foo` and names it `refs/bar` locally and downloads all objects reachable from `refs/foo`. It is also possible to specify multiple references by using globs,  e.g. the reference `refs/heads/*` specifies all references which are in the namespace `refs/heads`.
