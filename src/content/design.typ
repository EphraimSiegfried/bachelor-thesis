#import "@preview/dmi-basilea-thesis:0.1.1": *

= Design

== Mapping Nix to Git

This chapter introduces how Nix concepts are mapped to the Git object model. @nix-filesystem displays a simple Nix store with a package called _foo_ which depends on packages _libfoo_ and _bar_. This section shows which transformations are taken to have an equivalent model in Git which is represented in @gachix-git-model.

Just like the Git object database, the Nix Store is an immutable collection of data. Apart from packages the Nix store also stores source files, links and other types of objects. Since a binary cache only serves binary packages, we can focus on only those type of objects. 

Every top-level entry in the Nix store is uniquely addressable by some hash. There exist also files which are not uniquely addressable, which are inside those directories (e.g. a directory called 'bin'). When mapping Nix entries to Git objects we have to make sure that the corresponding objects in Git are also uniquely addressable. Fortunately, this is already the case in Git, because Git uses the hash of the data content to address it.

#figure(image("../diagrams/nix-filesystem.drawio.svg", width: 40%), caption: "Nix Store") <nix-filesystem>

=== Packages
A Nix package is either a single file executable or a directory containing an executable. In Git, files can be mapped to blobs. This mapping will lose file metadata information: When constructing a blob from a file, and then reconstructing the file, it cannot be known whether the file is executable. There are many ways to solve this issue. One way to solve this, is to always assume that top-level files are executable, because the binary cache only serves executables. When sending the Nar of a top-level file to a client, we can always mark it as executable. Another way to solve this, is to construct a Git tree with the blob of the file as the single entry. In this tree, we can mark the blob as executable. In order to distinguish this tree from other trees, the blob in this special tree can be named with a unique magic value which marks the tree and the blob as a single file executable. The latter approach is favourable, because as presented in @dependency-management we will create commits for each package, and commits can only point to trees and not blobs.

Package directories can be mapped to Git trees. These directories can contain symbolic links, files and other directories. Directories can be mapped to trees, symbolic links and files can be mapped to blobs, while metainfo such as the name of the objects can be stored in the trees. 

Notice that after mapping Nix store entries to Git objects, the size of the database will have decreased. One reason is that Git compresses its objects. Another reason is that all objects in Git are content addressed. If two package directories in the Nix store contain a file with the exact same content, Git will store this file as a blob only once. The package directories will be mapped to trees which point to the same blob.

#figure(image("../diagrams/gachix-git-model.drawio.svg", width: 80%), caption: [Gachix Git object model after transformaing Nix store in @nix-filesystem])<gachix-git-model>

=== Dependency Management <dependency-management>
In order to track which packages have which runtime dependencies, Nix manages a Sqlite database. This database tracks which Nix paths have references to other paths in the Nix store. This information helps Nix to copy package closures to other stores and it prevents deleting packages which have references to them. In Gachix this dependency management is achieved using commit objects. For each package, a commit object is created where the commit tree is the tree containing the package contents as described above. The parents of the commit are the dependencies of the package which are also represented as commits. To find out what the dependency closure of a package called 'foo' is, we can recursively follow the parent pointers which is equivalent to running `git log <foo-commit-hash>`. To enable easy replication, we'll need to ensure that every package is associated with exactly one commit hash (more in @replication-protocol). To ensure this, for every commit on each replica the commit message, the time stamp and the author field of the commit are set to constant values. 

As a binary cache, Gachix needs to locate the corresponding commit hash given a Nix package hash, because the Nix binary cache interface requires that Nix packages are requested by the Nix hash. To maintain a mapping between Nix hashes and commit hashes I propose two solutions. One solution is to create a Git tree which serves as an index. This special tree has all package commits as entries where the name of each entry is the respective Nix hash. With this special tree we can quickly lookup a package. A downside of this approach is that for each new entry the tree has to be copied(and the new entry be appended), because we cannot alter objects in the Git database. Another solution is to create a Git reference for each package which points to the corresponding commit object. The name of each reference contains the Nix hash. This approach also allows fast lookups. It is faster and requires less space since no objects have to be copied after package deletion or insertion. If we want to delete a package, we only have to remove the reference and call the garbage collector and Git will remove all objects associated with that package since these objects won't be reachable from a reference anymore. Because of these positive properties, Gachix uses the second approach.

=== User Profiles
Although this is not used in Gachix, an equivalent of Nix profiles and user environments can be achieved with the use of Git references. We can create a reference namespace (let's say for example _refs/myprofile_) containing symbolic references to direct references (e.g. _refs/myprofile/foo_ pointing to _refs/\<foo-nix-hash\>/pkg_) which point to package commits. The symbolic references in this namespace point to the packages the user wishes to have in the environment. We can then create a worktree by merging all commits reachable from this reference namespace. This worktree is identical to the contents of _/nix/store_ except that only active packages are contained in it. // maybe use different word than active

== Cache Interface

To integrate Gachix into the existing Nix ecosystem as a binary cache, it is easiest to implement the same API that the existing binary caches provide (see @binary-cache-interface). With this interface, a Nix user can add the URL of the Gachix service to the set of _substitutors_. Everytime the user adds a package, Nix will ask Gachix for package availability and fetch it if it is available.

The binary cache needs to serve metadata about the packages which is called Narinfo in Nix. Usually in other cache implementations the narinfo is computed on demand. In Gachix everytime a package is added to Gachix, the Narinfo is computed once and it is stored as a blob. Additionally, to associate this blob with a package, a reference is added under _refs/\<package-nix-hash\>/narinfo_ which points to this blob directly. Everytime a Narinfo is requested (with `GET /<package-nix-hash>.narinfo`) for a given Nix hash, Gachix serves the contents of this blob which it gets through this reference.

The Narinfo contains an URL, under which the nar of a package can be downloaded. This link usually contains the hash of the Nar of the package. But because this endpoint can be chosen arbitrarily, I decided to put the hash of the package tree instead. It would also be possible to put the hash of the package commit, which would enable sending the whole package closure to the client. But since Nix only expects the contents of the requested package and not its dependencies, it is enough and faster to include the tree hash in the URL. The Nix user can then request a package with ` GET refs/nar/\<tree-hash\>.nar`. Gachix then directly accesses the tree, converts it to a nar and sends the archive to the client. The user can verify whether the hash corresponds to the package by unpacking the received nar, converting it to a Git tree and comparing the tree hash with the hash in the URL.

With the request `HEAD /<package-nix-hash>.nar` a client can ask the cache if it has the corresponding package. This request is handled by checking whether a reference exists containing the requested hash.


== Replication Protocol <replication-protocol>

