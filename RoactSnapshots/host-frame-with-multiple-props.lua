return function(dependencies)
  local Roact = dependencies.Roact
  local ElementKind = dependencies.ElementKind
  local Markers = dependencies.Markers

  return {
    type = {
      kind = ElementKind.Host,
      className = "Frame",
    },
    props = {
      AnchorPoint = Vector2.new(0, 0.5),
      BackgroundColor3 = Color3.new(0.1, 0.2, 0.3),
      BackgroundTransparency = 0.205,
      ClipsDescendants = false,
      Size = UDim2.new(0.5, 0, 0.4, 1),
      SizeConstraint = Enum.SizeConstraint.RelativeXY,
      Visible = true,
      ZIndex = 5,
    },
    children = {},
  }
end