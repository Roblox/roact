return function(dependencies)
  local Roact = dependencies.Roact
  local ElementKind = dependencies.ElementKind
  local Markers = dependencies.Markers

  return {
    type = {
      kind = ElementKind.Host,
      className = "TextButton",
    },
    props = {
      [Roact.Event.Activated] = Markers.AnonymousFunction,
      [Roact.Event.MouseButton1Click] = Markers.AnonymousFunction,
      [Roact.Change.AbsoluteSize] = Markers.AnonymousFunction,
      [Roact.Change.Visible] = Markers.AnonymousFunction,
    },
    children = {},
  }
end