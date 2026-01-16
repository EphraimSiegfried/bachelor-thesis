#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

= Results

== Results Overview

=== Results
+ Gachix achieves the *lowest median latency* but shows *slower average* performance. 
+ Gachix is *more storage efficient* than other cache services.
+ Gachix can be *deployed on any Unix machine*, including on systems without Nix installed. 
+ Gachix is *transparent*: It can be used with the Nix interface.

---
== Package Retrieval Latency

=== Methodology
+ Randomly select 650 packages from the Nixpkgs registry (from two releases)
+ Install them along with every required dependency $arrow.r$ *5123 packages* in total
+ Add them to the Gachix cache
+ Start each cache service and *measure end-to-end latency* of NAR retrieval of each package

---

=== Results
#table(
  columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
  inset: 6pt,
  align: (left, right, right, right, right, right, right),
  stroke: none,
  table.hline(stroke: 1pt),
  [*Cache Service*], [*Median*], [*p95*], [*p99*], [*Max*], [*Mean*], [*Std*],
  table.hline(stroke: 0.5pt),
  [gachix], [#highlight[4.812]], [142.129], [840.199], [#highlight[9931.217]], [#highlight[49.347]], [327.198],
  [harmonia], [8.530], [119.514], [604.240], [3316.529], [41.912], [146.475],
  [nix-serve], [42.063], [101.205], [447.337], [2749.474], [57.757], [107.114],
  [nix-serve-ng], [7.689], [105.879], [616.550], [4832.431], [#highlight[37.989]], [182.101],
  table.hline(stroke: 1pt),
)

---


#set align(center)
#image("../diagrams/size_vs_latency.png", width:80%)


== Package Storage

#set align(left)
=== Methodology
- Same as in the previous benchmark
- Add 5123 packages to the Nix store and to Gachix
- Measure size of `.git` and sum of the size of all packages in Nix store

---

=== Result
- Sum of package sizes in the Nix store is 77.87 GB
- Size of `.git` repository is 13.45 GB
- *Size reduction of 82.72%*
- 21.84% of Git objects had an indegree > 1
