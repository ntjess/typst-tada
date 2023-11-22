#import "@preview/tablex:0.0.6": tablex, cellx, rowspanx
#import "helpers.typ": unique-row-keys, filtered-dict

#let default-currency = state("currency-state", "$")
#let default-hundreds-separator = state("separator-state", ",")
#let default-decimal = state("decimal-state", ".")


#let format-float(number, hundreds-separator: auto, decimal: auto, digits: 2) ={
  // Adds commas after each 3 digits to make
  // pricing more readable
  if hundreds-separator == auto {
    hundreds-separator = default-hundreds-separator.display()
  }
  if decimal == auto {
    decimal = default-decimal.display()
  }

  let integer-portion = str(calc.abs(calc.trunc(number)))
  let num-length = integer-portion.len()
  let num-with-commas = ""

  for ii in range(num-length) {
    if calc.rem(ii, 3) == 0 and ii > 0 {
      num-with-commas = hundreds-separator + num-with-commas
    }
    num-with-commas = integer-portion.at(-ii - 1) + num-with-commas
  }
  // Another "round" is needed to offset float imprecision
  let fraction = calc.round(calc.fract(number), digits: digits + 1)
  let fraction-int = calc.round(fraction * calc.pow(10, digits))
  if fraction-int == 0 {
    fraction-int = ""
  } else {
    fraction-int = decimal + str(fraction-int)
  }
  let formatted = num-with-commas + fraction-int
  if number < 0 {
    formatted = "-" + formatted
  }
  formatted
}

#let format-currency(number, currency: auto, ..args) = {
  if currency == auto {
    currency = default-currency.display()
  }
  let out = format-float(calc.abs(number), ..args)
  if number < 0 {
    out = "(" + out + ")"
  }
  currency + out
}

#let format-percent(number, ..args) = {
  format-float(number * 100, ..args) + "%"
}

#let format-string = eval.with(mode: "markup")

#let default-type-info = (
  string: (default: "", display: format-string),
  float: (display: /*format-float*/ auto, align: right),
  integer: (display: /*format-float*/ auto, align: right),
  percent: (display: format-percent, align: right),
  currency: (display: format-currency, align: right),
  index: (align: right),
)

#let supplement-field-info-from-rows(field-info, rows) = {
  let encountered-fields = unique-row-keys(rows)
  for field in encountered-fields {
    let existing-info = field-info.at(field, default: (:))
    let type-str = existing-info.at("type", default: auto)
    if type-str == auto {
      let values = rows.filter(row => field in row).map(row => row.at(field))
      let types = values.map(value => type(value)).dedup()
      if types.len() > 1 {
        panic("Field " + repr(field) + " has multiple types: " + repr(types))
      }
      type-str = repr(types.at(0))
    }
    let defaults-for-field = default-type-info.at(type-str, default: (:))
    for key in defaults-for-field.keys() {
      if key not in existing-info {
        existing-info.insert(key, defaults-for-field.at(key))
      }
    }
      field-info.insert(field, existing-info)
    }
  field-info
}


#let _value-to-display(value, value-info, row) = {
  let display-func = value-info.at("display", default: auto)
  if type(display-func) == str {
    value = eval(
      display-func,
      mode: "markup",
      scope: (value: value, format-float: format-float, format-currency: format-currency),
    )
  } else if display-func != auto {
    value = display-func(value)
  }
  value
}


#let _field-info-to-tablex-kwargs(field-info) = {
  let get-eval(dict, key, default) = {
    let value = dict.at(key, default: default)
    if type(value) == "string" {
      eval(value)
    }
    else {
      value
    }
  }

  let (names, aligns, widths) = ((), (), ())
  for (key, info) in field-info.pairs() {
    if "title" in info {
      key = info.at("title")
      if type(key) == str {
        key = eval(key, mode: "markup")
      }
    }
    names.push(key)
    let default-align = if info.at("type", default: none) == "string" { left } else { right }
    aligns.push(get-eval(info, "align", default-align))
    widths.push(get-eval(info, "width", auto))
  }
  // Keys correspond to tablex specs other than "names" which is positional
  (names: names, align: aligns, columns: widths)
}

#let display(td, ..tablex-kwargs) = {
  let (rows, field-info) = (td.rows, td.field-info)
  field-info = supplement-field-info-from-rows(field-info, rows)

  let encountered-keys = unique-row-keys(rows)
  // Order by field specification
  encountered-keys = field-info.keys().filter(
    key => key in encountered-keys and not field-info.at(key).at("hide", default: false)
  )
  let field-info = filtered-dict(field-info, keys: encountered-keys)
  let rows-with-fields = rows.map(filtered-dict.with(keys: encountered-keys))
  
  let out = rows-with-fields.map(row => {
    row.pairs().map(
      // `pair` is a tuple of (key, value) for each field in the row
      pair => _value-to-display(pair.at(1), field-info.at(pair.at(0)), row)
    )
  })

  let col-spec = _field-info-to-tablex-kwargs(field-info)
  let names = col-spec.remove("names")
  tablex(..col-spec, ..tablex-kwargs, ..names, ..out.flatten())
}