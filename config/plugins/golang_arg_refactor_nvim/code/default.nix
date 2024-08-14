{
  lib,
  buildGoModule,
}:
buildGoModule rec {
  pname = "golang_arg_refactor_nvim";
  version = "0.1.0";

  src = ./.;

  # vendorSha256 = lib.fakeSha256;

  # vendorHash = lib.fakeHash;
  vendorHash = "sha256-U8snpKhfhSK3GNP9iZ09g8fNlp4lEX1ctrMtSex5fBE=";

  buildPhase = ''
    go build -mod=vendor -o ${pname} cmd/plugin/main.go
  '';

  installPhase = ''
    mkdir -p $out/{bin,plugin}
    cp ${pname}  $out/bin/${pname}
    cp plugin/hello.lua $out/plugin/hello.lua
  '';

  meta = with lib; {
    description = "A simple Neovim plugin written in Go";
    license = licenses.mit;
  };
}
