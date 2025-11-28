= Design

== Mapping Nix to Git
This chapter introduces how Nix concepts are mapped to the Git object model. Just like the Git object database, the Nix Store is an immutable collection of data. Apart from packages the Nix store also stores source files, links and other types of objects. Since a binary cache only serves binary packages, we can ignore these other types of objects. 

Every entry in the Nix store is uniquely addressable by some hash. We will call these entries top-level entries. When mapping Nix entries to Git entries we have to make sure that the corresponding objects in Git are also uniquely addressable. 
// Define what you mean with uniquely addressable

A Nix package is either a single file executable or a directory containing an executable. In Git, files can be mapped to blobs. This process will lose file metadata information: When constructing a blob from a file, and then reconstructing the file, we will not know whether the file was executable or not. Since files are stored in a binary cache setting, it can be assumed that 
