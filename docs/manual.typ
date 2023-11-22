#import "@preview/tidy:0.1.0"
#import "utils.typ": *
#let module = tidy.parse-module(read("../lib.typ"), scope: (lib: lib))

#show raw.where(lang: "example"): content => {
  set text(font: "Linux Libertine")
  example-with-source(content.text, lib: lib, direction: ltr)
}

#show raw.where(lang: "example-ttb"): content => {
  set text(font: "Linux Libertine")
  example-with-source(content.text, lib: lib)
}

#show-module-fn(module, "TableData", style: tidy.styles.minimal)