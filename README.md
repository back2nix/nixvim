## Если у вас не установлен nix

### Для Linux
- https://nixos.org/download/#nix-install-linux
```nix
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Для Mac
- https://nixos.org/download/#nix-install-macos
```
sh <(curl -L https://nixos.org/nix/install)
```

## Как запускать nvim из этого репо?

```
nix run github:back2nix/nixvim
```
- или

```
git clone https://github.com/back2nix/nixvim
cd nixvim
nix run .
# или с параметрами
nix run . -- cmd/any/file.go
# или просто сбилдить
nix build
./result/bin/nvim
```
## asciinema video

[![asciicast](https://asciinema.org/a/Dg6RxATpQgSRQvQtyWgG1uB0d.svg)](https://asciinema.org/a/Dg6RxATpQgSRQvQtyWgG1uB0d)

## Screenshots

![image](https://github.com/user-attachments/assets/13fce37a-82cf-4495-9d19-1ee0a100dcd2)
![Screenshot from 2024-07-17 00-04-11](https://github.com/user-attachments/assets/6f3ed364-b985-412f-be80-3cb5e4037fed)
![Screenshot from 2024-07-17 00-04-39](https://github.com/user-attachments/assets/4badc450-900e-4a54-ad7d-d7976349ca01)
![image](https://github.com/user-attachments/assets/cc065ec0-ce20-4338-a45b-7b0d99ee32dd)
![image](https://github.com/user-attachments/assets/9d9ed1c2-43f3-46be-94a0-c00b7b7d50dd)
![image](https://github.com/user-attachments/assets/223b0c0f-3c60-44de-a10b-d5b28abec714)
![image](https://github.com/user-attachments/assets/b168def4-a0ee-4f99-a34e-501275976d43)
