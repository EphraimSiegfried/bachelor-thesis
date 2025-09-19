#import "@preview/dmi-basilea-thesis:0.1.1": *

#show: thesis.with(
  draft: true,
  title: "Gachix: A content-addressable binary cache for Nix over Git",
  author: "Ephraim Siegfried",
  email: "e.siegfried@unibas.ch",
  supervisor: "Dr. Erick Lavoie",
  examiner: "Prof. Dr. Christian Tschudin",
  faculty: "Department of Computer Science",
  website: "cn.dmi.unibas.ch",
  thesis-type: "Bachelor Thesis",
  research-group: "Computer Networks Group",
  date: datetime.today(),

  abstract: [
    This project develops a binary cache for Nix packages using Git's content-addressable filesystem.
    This approach improves upon traditional input-addressable packages by reducing memory usage and enhancing trust.
    Leveraging Git provides a key advantage: simple peer-to-peer replication of the binary cache across multiple nodes.
    The core work involves modeling package dependency graphs and user profiles within Git and creating an interface for Nix to interact with this system.
    The project will be evaluated through performance benchmarks measuring memory usage and package retrieval speed,
    alongside functional tests of the peer-to-peer replication and Nix interface.
  ],

  chapters: (
    include "content/introduction.typ",
    include "content/background.typ"
  ),

  bibliography-content: bibliography("refs.yml", style: "ieee", title: none)
)
