#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [Gachix],
    subtitle: [A binary Cache for Nix over Git],
    author: [Ephraim Siegfried],
    date: "16.01.2026" ,
    institution: [University of Basel],
  ),
  config-colors(
    neutral-darkest: rgb("#000000"),
    neutral-dark: rgb("#202020"),
    neutral-light: rgb("#f3f3f3"),
    neutral-lightest: rgb("#ffffff"),
    primary: rgb("#0c4842"),
  ),
)

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)


#include "content/motivation.typ"
#include "content/background.typ"
#include "content/design.typ"
#include "content/results.typ"
