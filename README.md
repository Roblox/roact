<h1 align="center">Roact</h1>
<div align="center">
	<a href="https://github.com/Roblox/roact/actions"><img src="https://github.com/Roblox/roact/workflows/CI/badge.svg" alt="GitHub Actions Build Status" /></a>
	<a href="https://coveralls.io/github/Roblox/roact?branch=master"><img src="https://coveralls.io/repos/github/Roblox/roact/badge.svg?branch=master" alt="Coveralls Coverage" /></a>
	<a href="https://roblox.github.io/roact"><img src="https://img.shields.io/badge/docs-website-green.svg" alt="Documentation" /></a>
</div>

<div align="center">
	<a href="https://reactjs.org">React</a> React'ten ilham alan Roblox Lua için bildirime dayalı bir kullanıcı arabirimi kitaplığı.
</div>

<div>&nbsp;</div>

## Yükleme

### Yöntem 1: Model Dosyası (Roblox Studio)
* [GitHub sürümler sayfasından](https://github.com/Roblox/Roact/releases) en son sürüme eklenen `rbxm` model dosyasını indirin.
* Modeli Studio'da "ReplicatedStorage" gibi bir yere yerleştirin

### Yöntem 2: Dosya Sistemi
* `src` dizinini kod tabanınıza kopyalayın
* Klasörü "Roact" olarak yeniden adlandırın
* Dosyaları bir yerle senkronize etmek için [Rojo](https://github.com/LPGhatguy/rojo) gibi bir eklenti kullanın

## [Dokümantasyon](https://roblox.github.io/roact)
Ayrıntılı kılavuz ve örnekler için [resmi Roact belgelerine](https://roblox.github.io/roact) bakın.

```lua
local LocalPlayer = game:GetService("Players").LocalPlayer

local Roact = require(Roact)

-- Tam ekran metin etiketini açıklayan sanal ağacımızı oluşturun.
local tree = Roact.createElement("ScreenGui", {}, {
	Label = Roact.createElement("TextLabel", {
		Text = "Hello, world!",
		Size = UDim2.new(1, 0, 1, 0),
	}),
})

-- Sanal ağacımızı gerçek örneklere dönüştürün ve bunları PlayerGui'ye koyun.
Roact.mount(tree, LocalPlayer.PlayerGui, "HelloWorld")
```

## License
Roact, Apache 2.0 lisansı altında mevcuttur. Ayrıntılar için [LICENSE.txt](LICENSE.txt)'e bakın.
