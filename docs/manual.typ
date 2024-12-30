#import "@preview/tidy:0.4.0"
#import "../lib.typ" as tada
#import "_doc-style.typ"
// https://github.com/ntjess/showman.git
#import "@preview/showman:0.1.2": formatter

#let _HEADING-LEVEL = 1

#show raw.where(lang: "example"): it => {
  heading(level: _HEADING-LEVEL + 2)[Example]
  it
}
#outline(indent: 1em, depth: _HEADING-LEVEL + 1)

#include "./overview.typ"

#for file in ("tabledata", "ops", "display") {
  let module = tidy.parse-module(
    read("../src/" + file + ".typ"),
    scope: (
      tada: tada,
      ..dictionary(tada.display),
      ..dictionary(tada.helpers),
      ..dictionary(tada),
    ),
  )
  heading[Functions in #raw(file + ".typ", block: false)]
  tidy.show-module(module, first-heading-level: _HEADING-LEVEL, show-outline: false)
}
