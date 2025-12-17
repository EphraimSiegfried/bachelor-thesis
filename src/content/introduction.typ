
= Introduction <introduction>

This project is motivated by the idea that many features that the Nix package manager offers can be implemented using Git's internal object model. This idea is explored in _Gachix_, a binary cache for Nix, which is the subject of this thesis. 

_Gachix_ uses Git as a backend storage for Nix packages. By mapping the Nix store's structure directly onto Git objects (blobs, trees, and commits), this project seeks to bridge the gap between these two worlds. It is not a replacement of the Nix store. Its main purpose is to serve pre-built binaries and other artifacts to clients which have the Nix package manager installed. 

Using Git as a backend storage has the following benefits:

- The storage of package is more efficient. Gachix leverages Git’s inherent deduplication and compression capabilities.
// Using Git in the backend for storing packages reduces the storage size compared to the current way Nix stores packages.



