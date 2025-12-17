#import "@preview/dmi-basilea-thesis:0.1.1": *
#import "@preview/algorithmic:1.0.7"
#import algorithmic: style-algorithm, algorithm-figure

= Design <design>

== Mapping Nix to Git <nix-to-git>

This chapter introduces how Nix concepts are mapped to the Git object model. @nix-filesystem displays a simple Nix store with a package called _foo_ which depends on packages _libfoo_ and _bar_. This section shows which transformations are taken to have an equivalent model in Git which is represented in @gachix-git-model.

Much like the Git object database, the Nix Store is an immutable collection of data. Apart from packages the Nix store also stores source files, derivations, links and other types of objects. Since a binary cache only serves binary packages, we can focus on only those type of objects. 

Every top-level entry in the Nix store is uniquely addressable by some hash. There exist also files which are not uniquely addressable, which are inside those directories (e.g. a directory called 'bin'). When mapping Nix entries to Git objects we have to make sure that the corresponding objects in Git are also uniquely addressable. Fortunately, this is already the case in Git, because object in Git are content-addressed.

#figure(image("../diagrams/nix-filesystem.drawio.svg", width: 40%), caption: "Nix Store") <nix-filesystem>

=== Packages
A Nix package is either a single file executable or a directory containing an executable. In Git, files can be mapped to blobs. This mapping will lose file metadata information: When constructing a blob from a file, and then reconstructing the file, it cannot be known whether the file is executable. 

One way to solve this, is to always assume that top-level files are executable, because the binary cache only serves executables. When sending the NAR of a top-level file to a client, we can always mark the file as executable. 

Another way to solve this, is to construct a Git tree with the blob of the file as the single entry. In this tree, we can mark the blob as executable. In order to distinguish this tree from other trees, the blob in this special tree can be named with a unique magic value which marks the tree and the blob as a single file executable. The latter approach is favourable, because as presented in @dependency-management we will create commits for each package, and commits can only point to trees and not blobs.

Package directories can be mapped to Git trees. These directories can contain symbolic links, files and other directories. Directories can be mapped to trees, symbolic links and files can be mapped to blobs, while metainfo such as the name of the objects can be stored in the trees. 

Notice that after mapping Nix store entries to Git objects, the size of the database will have decreased. One reason is that Git compresses its objects. Another reason is that all objects in Git are content addressed. If two package directories in the Nix store contain a file with the exact same content, Git will store this file as a blob only once. The package directories will be mapped to trees which point to the same blob.

#figure(image("../diagrams/gachix-git-model.drawio.svg", width: 80%), caption: [Gachix Git object model after transforming the Nix store shown in @nix-filesystem])<gachix-git-model>

=== Dependency Management <dependency-management>
In order to track which packages have which runtime dependencies, Nix manages a Sqlite database. This database tracks which Nix paths have references to other paths in the Nix store. @nix-db-schema This information helps Nix to copy package closures to other stores. A package closure is a set of store paths that are directly or transitively reachable from that store path. @nixdev-glossary Keeping track of references also prevents deleting packages which have references to them.

In Gachix this dependency management is achieved using commit objects. For each package, a commit object is created where the commit tree is the tree containing the package contents as described above. The parents of the commit are the dependencies of the package which are also represented as commits. To find out what the dependency closure of a package called 'foo' is, we can recursively follow the parent pointers which is equivalent to running `git log <foo-commit-hash>`. To enable easy replication, we'll need to ensure that every package is globally associated with exactly one commit hash regardless of when and where it was created (more in @replication-protocol). To ensure this, for every commit on each replica the commit message, the time stamp and the author field of the commit are set to constant values. 

As a binary cache, Gachix needs to locate the corresponding commit hash given a Nix store package hash, because the Nix binary cache interface expects that packages are requested by the store hash. To maintain a mapping between store hashes and commit hashes we have considered two solutions. One solution is to create a Git tree which serves as an index. This special tree has all package commits as entries where the name of each entry is the respective Nix hash. With this special tree we can quickly lookup a package. A downside of this approach is that for each new entry the tree has to be copied (and the new entry be appended), because we cannot alter objects in the Git database.

Another solution is to create a Git reference for each package which points to the corresponding commit object. The name of each reference contains the Nix hash. This approach also allows fast lookups. It is faster and requires less space since no objects have to be copied after package deletion or insertion. If we want to delete a package, we only have to remove the reference and call the garbage collector. The garbage collector will remove all objects which are not reachable from any reference. Because of these positive properties, Gachix uses the second approach.

=== User Profiles
Although this is not used in Gachix, an equivalent of Nix profiles and user environments can be achieved with the use of Git references. We can create a reference namespace (let's say for example _refs/myprofile_) containing symbolic references to direct references (e.g. _refs/myprofile/foo_ pointing to _refs/\<foo-nix-hash\>/pkg_) which point to package commits. The symbolic references in this namespace point to the packages the user wishes to have in the environment. We can then create a worktree by merging all commits reachable from this reference namespace. This worktree is identical to the contents of _/nix/store_ except that only active packages are contained in it. // maybe use different word than active

== Cache Interface

To integrate Gachix into the existing Nix ecosystem as a binary cache, it is easiest to implement the same API that the existing binary caches provide (see @binary-cache-interface). With this interface, a Nix user can add the URL of the Gachix service to the set of _substitutors_. Everytime the user adds a package, Nix will ask Gachix for package availability and fetch it if it is available.

=== Narinfo endpoint <narinfo-endpoint>
The binary cache needs to serve metadata about the packages which is called Narinfo in Nix (See @narinfo). While many cache implementations compute Narinfo files on demand, Gachix computes the Narinfo only once. A blob containing the Narinfo is created immediately when a package is added. 

Additionally, to associate the blob with a package, a reference is added under _refs/<package-nix-hash>/narinfo_ pointing directly to that blob. Whenever a Narinfo is requested for a specific Nix store hash (via `GET /<package-store-hash>.narinfo`), Gachix resolves this reference to serve the blob's contents.

With the request `HEAD /<package-store-hash>.nar` a client can ask the cache if it has the corresponding package. This request is handled by checking whether a reference exists containing the requested hash.

=== NAR endpoint

A Narinfo file provides a URL for downloading a package’s NAR, typically using the NAR hash as the identifier. But because this endpoint can be chosen arbitrarily, we decided to put the hash of the package tree instead. It would also be possible to put the hash of the package commit, which would enable sending the whole package closure to the client. But since Nix only expects the contents of the requested package, it is enough and faster to include the tree hash in the URL. The Nix user can request a package with ` GET refs/nar/\<tree-hash\>.nar`. Gachix then directly accesses the tree, converts it to a NAR and sends the archive to the client. This approach maintains integrity by allowing the user to verify the download: they can simply unpack the NAR, convert the resulting directory back into a Git tree, and ensure the calculated tree hash matches the one provided in the URL.

== Replication Protocol <replication-protocol>

This section explains how packages are added to the cache and replicated across peers. Gachix itself does not build packages and relies on external services. Gachix can communicate to the local Nix daemon, to remote Nix daemons and to remote Gachix peers (i.e. Git repositories managed by Gachix). With the Nix daemon protocol, Gachix can request metadata of store paths (e.g. runtime dependencies) and retrieve a package from the Nix store in the NAR format. With Gachix peers, Gachix uses the Git protocol to replicate commits and to fetch whole package dependency closures.

There is no policy yet on when Gachix adds packages to its repository. In the current version, it has to be manually run in the command line. A possible policy would be to always try to add a package when a Nix user requests one via the HTTP interface and it does not exist on the local repository. Gachix should then fetch the package from trusted replicas or may build it using the daemon protocol.

=== Constructing Package Closures <constructing-package-closures>

The current algorithm of adding a package closure is displayed in @add-closure-algo. The algorithm receives the Nix store hash as an argument. It returns the commit ID associated with that package if it is able to fetch the closure of the package. If this is not able to do so, it returns _NIL_. It tries to recursively add package contents to the Git repository. At its core, it is similar to a depth first search algorihm (See lines 19-28 in @add-closure-algo). The algorithm iterates through a package's direct dependencies (line 21). For  each dependency $d$, it makes a recursive call to _add_closure(d)_ (line 23). This means it fully processes one dependency, including all its dependencies, before moving to the next direct dependency in the list. Once it has collected all commit hashes of the dependencies, it constructs a commit using the hash collection as parent commits (line 26). 


#show: style-algorithm
#algorithm-figure(
  "Add package closure",
  vstroke: .5pt + luma(200),
  {
    import algorithmic: *
    Procedure(
      "add_closure",
      ("path"),
      {
        If(FnInline[package_exists][nix_hash], {
          Return(FnInline[commit_oid][nix_hash])
        })
        Comment([Ask gachix peers in the set P if they have already replicated the package closure])
        For([$ p in P$], {
          If(FnInline([has_package],[p, nix_hash]), {
            Return(FnInline[fetch_closure][nix_hash]) 
          })
        })
        Comment([Ask Nix daemons in the set D if they can provide package contents])
        Assign([package], [NIL])
        For([$ d in D$], {
          If(FnInline([has_package],[d, nix_hash]), {
            Assign([package], FnInline[fetch_package][nix_hash])
            Break
          })
        })
        Comment([Return None if there doesn't exist a daemon which can build the package])
        If([package = NIL], {
         Return([NIL])
        })
        
        Comment([Get the nix hash of all dependent packages])
        Assign([dependencies], {FnInline([package.dependencies],[])})
        Assign([parents],[${}$])
        For([$ d in "dependencies"$], {
          Comment([Recursively fetch all commit oids])
          Assign([dep_commit_oid], FnInline([add_closure],[d]))
          Comment([A dependency could not be built/fetched, so we have to return None])
          If([dep_commit_oid = NIL], {
           Return([NIL])
          })
          Line($"parents" union {"dep_commit_oid"}$)
        })
       Assign([commit_oid], FnInline([commit],[package.tree, parents]))
       Line(FnInline([add_reference],[path, commit_oid]))
       Return([commit_oid])
      }
        
    )
  }
) <add-closure-algo>

There are three base cases of the recursive algorithm. The algorithm does not recurse if it finds a leaf in the package dependency tree, i.e. a package without dependencies. It does also not recurse if a package already exists in the local repository (lines 2-4). Another base case is when the package can be retrieved from peer replicas (lines 6-10).

The algorithm can be extended to request packages from trusted binary caches beyond the Gachix ecosystem. Additionally, performance can be optimized by implementing a heuristic that orders peer contact based on proximity, thereby minimizing latency.

=== Fetching Packages from Replicas

This section explains what the _fetch_closure_ function does in @add-closure-algo on line 8. Its main task is to fetch commits and references associated with a package. We will present two algorithms which perform this task. The first one is short and fast, but does not work because of an upstream Git bug. The second will be the one which is used in the current implementation.

We can fetch packages by using refspecs (see @refspecs). With the refspec _refs/\<nix-store-hash\>/\*:refs/\<nix-store-hash\>/\*_ we specify that we want all references under the remote Nix hash namespace. Each such namespace has a _pkg_ and a _narinfo_ reference (see @dependency-management and @narinfo-endpoint). Git will fetch the blob from the _narinfo_ reference and it will fetch all commits reachable from _pkg_. With this we will have all package contents from the whole package closure. What we will not have are the references to the dependencies of the package. For example, if a package _foo_ has the dependency _bar_ and we fetch with `git fetch peer refs/<nix-foo-hash>/*:refs/<foo-nix-hash>/*` we will receive the package contents of _foo_ and _bar_ but not the reference namespace _refs/\<bar-nix-hash\>_. To also get references from dependencies, we could add the namespace _refs/\<nix-hash\>/deps_ containing symbolic references to all dependent packages. In the example above, when a peer constructs the package _foo_, it should also add the symbolic references _refs/\<foo-nix-hash\>/deps/\<bar-nix-hash\>/pkg_ and _refs/\<foo-nix-hash\>/deps/\<bar-nix-hash\>/narinfo_. With this approach we can recursively reach all references by symbolic references. The expected behavior is that when fetching all references from _refs/\<nix-hash\>/\*_ that all reachable references will also be fetched. Unfortunately, this is not the case because of a Git inconsistency which has been reported. When fetching symbolic references, Git resolves the symbolic reference to direct references @gitlab-issue-175. This makes this approach of fetching package unusable, as the references of the dependencies won't be fetched. But once this upstream bug is fixed, the explained method is a viable approach.

In the second approach there is no _deps_ namespace and Gachix fetches each reference explicitly. The initial fetch downloads all Git objects associated with the package closure. The subsequent fetches only download the references. The fetching of the references is done in a breadth-first-search manner.

=== Nix Daemons

If packages don't exist locally and no other replica has the package, it has to be fetched from a Nix store. The Nix daemon protocol can be used to achieve this. With this protocol, we can talk to the local Nix daemon (if one exists) via a socket or to remote Nix daemons via the SSH protocol. In the function _fetch_package_ in @add-closure-algo Gachix uses the Nix daemon protocol to fetch package metainfo information called "Path Info" in Nix and to download package contents in the NAR format. After receiving the NARs, Gachix  unpacks them to Git trees.
