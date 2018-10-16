# Bindings

## API Proposal

### Roact.createBinding()

`createBinding(initialValue) -> Binding`

where

`Binding.getValue() -> value`

`Binding.map(mappingFunction)` where `mappingFunction(value) -> resultingValue`

`Binding.setValue(value)`

### Roact.createRef()

`createRef() -> Ref`

where Ref is just a limited binding

`Ref.getValue() -> value`