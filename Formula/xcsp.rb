class Xcsp < Formula
  desc "Unified launcher for XCSP3 solvers"
  homepage "https://github.com/crillab/xcsplauncher"
  url "https://github.com/crillab/xcsplauncher/releases/download/v0.1.0/xcsp-macos" # <-- URL vers ton binaire macOS
  sha256 "YOUR_SHA256_SUM_HERE"
  license "LGPL-3.0-or-later"

  def install
    bin.install "xcsp-macos" => "xcsp"
    share.install "configs" => "xcsp/configs"
  end

  def post_install
    system "#{bin}/xcsp", "--bootstrap"
  end

  test do
    system "#{bin}/xcsp", "--help"
  end
end
