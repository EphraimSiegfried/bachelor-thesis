#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [Gachix],
    subtitle: [A Binary Cache for Nix over Git],
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
  // config-common(handout: true),
)


#set heading(numbering: numbly("{1}.", default: "1.1"))
#show outline.entry: it => {
  let all-headings = query(heading)
  let last-heading-loc = all-headings.last().location()
  if it.element.location() == last-heading-loc {
    none
  } else {
    it
  }
}
#title-slide()

= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)
#set heading(numbering: (..nums) => {
  let n = nums.pos().len()
  if n <= 2 {
    numbering("1.", ..nums)
  } else {
    none
  }
})


#include "content/motivation.typ"
#include "content/background.typ"
#include "content/design.typ"
#include "content/results.typ"

#set heading(numbering: none)
= Thank you for your attention! 
