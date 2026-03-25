class Jump < Formula
  desc "Fast directory jumping tool with fuzzy matching and bookmark management"
  homepage "https://github.com/linnyh/jump"
  url "https://github.com/linnyh/jump.git", tag: "v0.1.0"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"
  version "0.1.0"

  depends_on "rust" => :build

  def install
    system "cargo", "install", "--locked", "--path", "."
  end

  def post_install
    # Install shell plugin
    (prefix/"jump.sh").write <<~SHELL
      #!/bin/bash
      # j shell plugin - add to ~/.zshrc or ~/.bashrc
      export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"
      source "#{opt_prefix}/share/jump/j.sh"
    SHELL
    (prefix/"share/jump")..mkpath
    (prefix/"share/jump/j.sh").write <<~SHELL
      #!/bin/bash
      # j shell plugin
      # 在 .zshrc 或 .bashrc 中 source 此文件

      export PATH="#{HOMEBREW_PREFIX}/bin:$PATH"

      _J_LAST_JUMP_DIR=""

      j() {
          if [[ "$1" == "-e" ]] || [[ "$1" == "--edit" ]]; then
              command j "$@"
              return $?
          fi

          if [[ "$1" == "--back" ]] || [[ "$1" == "-b" ]]; then
              if [[ -n "$_J_LAST_JUMP_DIR" ]]; then
                  cd "$_J_LAST_JUMP_DIR"
                  return $?
              else
                  echo "No previous jump directory" >&2
                  return 1
              fi
          fi

          local arg="$1"
          case "$arg" in
              ..|.|\.\.|\.\.) eval "cd $arg"; return $? ;;
              ../*) eval "cd $arg"; return $? ;;
              ./) eval "cd $arg"; return $? ;;
              /*) eval "cd $arg"; return $? ;;
              -) cd -; return $? ;;
          esac

          local current_dir="$(pwd)"
          local result
          result=$(command j --cwd "$current_dir" "$@")

          if [[ -z "$result" ]]; then
              return
          fi

          if [[ "$result" == cd\\ * ]]; then
              eval "$result"
              local cd_status=$?
              if [[ $cd_status -eq 0 ]]; then
                  _J_LAST_JUMP_DIR="$current_dir"
                  command j --record-current 2>/dev/null
              fi
          else
              echo "$result"
          fi
      }
    SHELL
    chmod 0644, "#{prefix}/share/jump/j.sh"
  end

  def caveats
    <<~EOS
      To enable cd-style commands (j .., j --back, etc.), add to your shell config:

      # For zsh (~/.zshrc)
      source #{opt_share}/jump/j.sh

      # For bash (~/.bashrc)
      source #{opt_share}/jump/j.sh
    EOS
  end

  test do
    assert_match "j", shell_output("#{bin}/j --version")
  end
end
