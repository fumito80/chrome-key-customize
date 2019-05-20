F =
  XX: (selector, parent = document) -> [parent.querySelectorAll(selector)...]
  range: (from, to) -> [Array(to - from + 1)...].map((_, i) => i + from)
  pipe: (fn, fns...) -> (a) -> fns.reduce ((acc, fn2) -> fn2(acc)), fn(a)
  map: (f) -> (a) -> a.map f
  filter: (f) -> (a) -> a.filter f
  find: (f) -> (a) -> a.find f
  findIndex: (f) -> (a) -> a.findIndex f

decodeKbdCode = (kbdCode) -> [
  parseInt(kbdCode.substring(0, 2), 16)
  kbdCode.substring(2)
]

decodeKbdEvent = F.pipe(
  decodeKbdCode
  ([modifiers, scanCode]) ->
    [unshifted, shifted] = keys[scanCode]
    [1, 0, 3, 2] #, 4, 5, 6]
      .filter (i) -> modifiers & Math.pow(2, i)
      .map (i) -> modifierKeys[i]
      .concat (shifted if modifiers & 4) || unshifted
      .join(" + ")
)

transKbdEvent = F.pipe(
  decodeKbdCode
  ([modifiers, scanCode]) -> [
    modifierInits.filter((_, i) -> modifiers & Math.pow(2, i)).join("")
    keys[scanCode]
  ]
  ([keyCombo, [keyIdenfier]]) -> "[" + keyCombo + "]" + keyIdenfier
)
