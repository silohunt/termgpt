class Termgpt < Formula
  desc "Platform-aware shell tool that converts natural language to Unix commands using local LLM"
  homepage "https://github.com/silohunt/termgpt"
  url "https://github.com/silohunt/termgpt/archive/v0.9.1.tar.gz"
  sha256 "8eff7f9daa7fb413238d37e2153b4ceebb39660531b3af6658f87695f840adef"
  license "MIT"
  version "0.9.1"

  depends_on "jq"
  depends_on "curl"
  depends_on "python@3.12" => :recommended

  def install
    # Install main executables
    bin.install "bin/termgpt"
    bin.install "bin/termgpt-init"
    bin.install "bin/termgpt-shell"
    bin.install "bin/termgpt-history"
    
    # Install libraries to lib/termgpt
    (lib/"termgpt").install Dir["lib/*"]
    
    # Install post-processing system
    (lib/"termgpt").install "post-processing"
    
    # Install shared resources
    (share/"termgpt").install Dir["share/termgpt/*"]
    
    # Install documentation
    man1.install "man/man1/termgpt.1"
    doc.install "README.md"
    doc.install "doc/README.md" => "TECHNICAL.md"
  end

  def caveats
    <<~EOS
      TermGPT requires Ollama to run. Install and configure it:
        brew install ollama
        ollama serve &
        termgpt init

      To get started:
        termgpt "find all python files larger than 1MB"
        termgpt shell  # Interactive REPL mode

      For configuration and advanced usage:
        man termgpt
    EOS
  end

  test do
    # Test basic functionality
    assert_match "termgpt #{version}", shell_output("#{bin}/termgpt --version")
    assert_match "TermGPT - Natural language to shell command converter", shell_output("#{bin}/termgpt --help")
    
    # Test init functionality
    assert_match "TermGPT", shell_output("#{bin}/termgpt-init --help")
    
    # Test shell functionality
    assert_match "termgpt shell", shell_output("#{bin}/termgpt-shell --help")
  end
end