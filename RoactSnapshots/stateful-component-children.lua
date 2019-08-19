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
          kind = ElementKind.Stateful,
          componentName = "CoolComponent",
        },
        hostKey = "Child",
        props = {
          label = {
            Text = "foo",
          },
        },
        children = {},
      },
    },
  }
end