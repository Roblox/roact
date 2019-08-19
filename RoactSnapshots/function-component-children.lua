return function(dependencies)
  local Roact = dependencies.Roact
  local ElementKind = dependencies.ElementKind
  local Markers = dependencies.Markers
  
  return {
    type = {
      kind = ElementKind.Host,
      className = "Frame",
    },
    props = {},
    children = {
      {
        type = {
          kind = ElementKind.Function,
        },
        hostKey = "LabelA",
        props = {
          Text = "I am label A",
        },
        children = {},
      },
      {
        type = {
          kind = ElementKind.Function,
        },
        hostKey = "LabelB",
        props = {
          Text = "I am label B",
        },
        children = {},
      },
    },
  }
end