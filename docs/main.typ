#import "../lib.typ": *
#import "utils.typ": *

#set page(height: auto, margin: 0.2in, fill: white)
#let example-blocks = state("example-blocks", ())
#let output-counter = counter("output")

#let output(content, step: true) = {
  locate(loc => {
    let cnt = output-counter.at(loc).last()
    let example-number = example-blocks.at(loc).len()
    if cnt == example-number {
      content
    }
  })
  if step {
    output-counter.step()
  }
}

#let inline-code(content) = box(
  radius: 0.25em,
  fill: white.darken(3%),
  inset: 0.25em,
  baseline: 0.25em,
  content,
)

#set text(font: "Linux Libertine")
#let normal-show(content) = {
  output-counter.update(1)
  example-blocks.update(old => {
    old.push(content.text)
    old
  })
  locate(loc => {
    let prefix = example-blocks.at(loc).slice(0, -1).join("\n\n")
    example-with-source(
      prefix: prefix,
      content.text,
      lib: lib,
      direction: ltr,
      output: output,
    )
  })
}
#show raw.where(lang: "example"): normal-show

#let tada-box = box.with(stroke: black, inset: 2pt, baseline: 0.35em)
#show "TaDa": [#tada-box[Ta]#tada-box[Da]]

= Overview
TaDa provides a set of simple but powerful operations on rows of data.

Key features include:

- *Arithmetic expressions*: Row-wise operations are as simple as string expressions with field names

- *Aggregation*: Any function that operates on an array of values can perform row-wise or
  column-wise aggregation

- *Data representation*: Handle displaying currencies, floats, integers, and more
  with ease and arbitrary customization


= Table manipulation
TaDa provides two main ways to construct tables -- from columns and from rows:

== Hello world
_Note: This and all following examples wrap  rendered content in #inline-code[`#output[...]`] blocks. This is purely a helper function for the documentation, and is *not required* in your own code._
```example
#let column-data = (
  name: ("Bread", "Milk", "Eggs"),
  price: (1.25, 2.50, 1.50),
  quantity: (2, 1, 3),
)
#let row-data = (
  (name: "Bread", price: 1.25, quantity: 2),
  (name: "Milk", price: 2.50, quantity: 1),
  (name: "Eggs", price: 1.50, quantity: 3),
)
#let td = table-data-from-columns(column-data)
// Equivalent to:
// #let td = TableData(rows: row-data)

// Show using the `table` attribute
#output(td.table)
```

== Using `__index`

TaDa will automatically add an `__index` field to each row. This is useful for showing auto-incrementing row numbers and filtering operations:

```example
#td.field-info.at("__index").insert("title", "\#")
#td.field-info.at("__index").insert("hide", false)
#let td = TableData(..td)
#output(td.table)
```

== Title formatting
You can pass any `content` as a field's `title`. *Note*: if you pass a string, it will be evaluated as markup.
```example
#let fmt = heading.with(outlined: false)

#let titles = (
  name: (title: fmt("Name")),
  price: (title: fmt("Price")),
  quantity: (title: fmt("Qty")),
  ..td.field-info,
)
#let td = TableData(..td, field-info: titles)
#output(td.table)
```

== Value formatting

=== `type`
Type information can have attached metadata that specifies alignment, display formats, and more. Available types and their metadata are:
#default-type-info

```example
#td.field-info.at("price").insert("type", "currency")
#let td = TableData(..td)
#output(td.table)
```

== Transposing
`transpose` is supported, but keep in mind if columns have different types, an error will be a frequent result. To avoid the error, explicitly pass `ignore-types: true`. You can choose whether to keep field names as an additional column by passing a string to `fields-name` that is evaluated as markup:

```example
#output[
  #transpose(td, ignore-types: true, fields-name: "").table
]
```

=== Currency and decimal locales
You can account for your locale by updating `default-currency`, `default-hundreds-separator`, and `default-decimal`:
```example
#output[
  American: #format-currency(12.5)
  
  #default-currency.update("€")
  European: #format-currency(12.5)
]
```

These changes will also impact how `currency` and `float` types are displayed in a table.

=== `display`
If your type is not available or you want to customize its display, pass a `display` function that formats the value, or a string that accesses `value` in its scope:
  
```example
#td.field-info.at("quantity").insert(
  "display",
  val => ("One", "Two", "Three").at(val - 1),
)

#let td = TableData(..td)
#output(td.table)
```

=== `align` etc.
You can pass `align` and `width` to a given field's metadata to determine how content aligns in the cell and how much horizontal space it takes up. In the future, more `tablex` setup arguments will be accepted.

```example
#let adjusted = td
#adjusted.field-info.at("name").insert("align", center)
#adjusted.field-info.at("name").insert("width", 1fr)
#output[
  #TableData(..adjusted).table
]
```

== Deeper `tablex` customization
TaDa uses `tablex` to display the table. So any argument that `tablex` accepts can be
passed to TableData as well:

```example
#let mapper = (index, row) => {
  let fill = if index == 0 {white.darken(15%)} else {none}
  row.map(cell => (..cell, fill: fill))
}
#let td = TableData(
  ..td,
  tablex-kwargs: (
    map-rows: mapper,
    auto-vlines: false,
  ),
)
#output(td.table)
```

== Subselection
You can select a subset of fields to display:

```example
#output[
  #subset(td, indexes: (0,2), fields: ("__index", "name", "price")).table
]
```

Rows can also be selected by whether they fulfill a field condition:
```example
#output[
  #filter(td, expression: "price < 1.5").table
]
```

= Operations

== Expressions
The easiest way to leverage TaDa's flexibility is through expressions. They can be strings that treat field names as variables, or functions that take keyword-only arguments.
  - *Note*! you must `collect` before showing a table to ensure all expressions are computed:
- *Note*! When passing functions, every field is passed as a named argument to the function. So, make sure to capture unused fields with `..rest` (the name is unimportant) to avoid errors.

```example
#let td = with-field(
  td,
  "total",
  expression: "price * quantity",
  title: fmt("Total"),
  type: "currency",
)

// Expressions can build off other expressions, too
#let taxed = with-field(
  td,
  "Tax",
  // Expressions can be functions, too
  expression: (total: none, ..rest) => total * 0.2,
  title: fmt("Tax"),
  type: "currency",
)

// Extra field won't show here!
// #output(taxed.table)
// Computed expressions must be collected
#output(collect(taxed).table)
```

== Chaining
It is inconvenient to require several temporary variables as above, or deep function nesting, to perform multiple operations on a table. TaDa provides a `chain` function to make this easier:

```example
#let totals = chain(td,
  concat.with(
    field: "total",
    expression: "price * quantity",
    title: fmt("Total"),
    type: "currency",
  ),
  concat.with(
    field: "tax",
    expression: "total * 0.2",
    title: fmt("Tax"),
    type: "currency",
  ),
  concat.with(
    field: "after tax",
    expression: "total + tax",
    title: fmt("w/ Tax"),
    type: "currency",
  ),
  // Don't forget to collect before taking
  // a subset!
  collect,
  subset.with(
    fields: ("name", "total", "after tax")
  ),
)

#output(totals.table)
```

== Aggregation
Row-wise and column-wise reduction is supported through `agg`:

```example
#let grand-total = chain(
  totals,
  agg.with(
    using: array.sum,
    fields: "total"
  ),
  // use "item" to extract the value when
  // a table has exactly one element,
  item
)
#output[
  *Grand total: #format-currency(grand-total)*
]
```

It is also easy to aggregate over multiple fields:
```example
#let agg-rows = agg(
  totals,
  using: array.sum,
  fields: ("total", "after tax"),
  axis: 0,
  title: "#repr(function)\(#field\)"
)

#output(agg-rows.table)
```

= Roadmap
#let cb = box(stroke: black, width: 0.65em, height: 0.65em, baseline: 0.65em)
#set list(marker: cb)
- `apply` for value-wise transformations
- Reconcile whether `field-info` should be required
- `pivot`/`melt`
- `merge`/`join`