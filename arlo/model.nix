{ pkgs }:
let
  model = pkgs.fetchurl {
    name = "arlo-qwen2.5-1.5b-q4_k_m.gguf";
    url = "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/91cad51170dc346986eccefdc2dd33a9da36ead9/qwen2.5-1.5b-instruct-q4_k_m.gguf";
    sha256 = "6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e";
  };
in pkgs.writeShellScriptBin "spaces-arlo-infer" ''
  exec ${pkgs.llama-cpp}/bin/llama-completion -m ${model} -f /dev/stdin \
    --grammar-file ${./operations.gbnf} --no-conversation --no-display-prompt \
    --simple-io --no-warmup --temp 0 -t 4 -c 4096 -n 48
''
