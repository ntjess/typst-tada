#import "@preview/tidy:0.1.0"
#import "../lib.typ" as tada
#import "_doc-style.typ"
// https://github.com/ntjess/showman.git
#import "@local/showman:0.1.0": formatter

#let _HEADING-LEVEL = 1

#show raw.where(lang: "example"): it => {
  heading(level: _HEADING-LEVEL + 2)[Example]
  it
}
#outline(indent: 1em, depth: _HEADING-LEVEL + 1)

#include("./overview.typ")

// overview applies its own template show, so scope this only to the module docs
#show: formatter.template.with(
  // theme: "dark",
  eval-kwargs: (
    direction: ltr,
    scope: (tada: tada, display: tada.display),
    unpack-modules: true,
  ),
)

#for file in ("tabledata", "ops", "display") {
  let module = tidy.parse-module(read("../src/" + file + ".typ"), scope: (tada: tada))
  heading[Functions in #raw(file + ".typ", block: false)]
  tidy.show-module(module, first-heading-level: _HEADING-LEVEL, show-outline: false, style: _doc-style)
}