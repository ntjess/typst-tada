/// Only used to extract example outputs from code blocks for use in the readme

#set page(height: auto, width: auto, margin: 0pt)
#{
  show: box.with(width: 0pt, height: 0pt, clip: true)
  include("./overview.typ")
}

#locate(loc => {
  let outputs = query(<example-output>, loc)
  for (ii, output) in outputs.enumerate() {
    pagebreak()
    block(output)
  }
})