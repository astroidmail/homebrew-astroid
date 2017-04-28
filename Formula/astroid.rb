class Astroid < Formula
  desc "A graphical threads-with-tags style, lightweight and fast, email client for notmuch, inspired by sup and others"
  homepage "http://astroidmail.github.io/"

  url "https://github.com/astroidmail/astroid/archive/v0.9.tar.gz"
  sha256 "bb0bd5914af1f835393f101eff577ac5e0f35b67cc565ae0d6947a2d98ae9dd8"

  depends_on "scons" => :build
  depends_on "libsass"
  depends_on "libpeas"
  depends_on "notmuch"
  depends_on "boost"
  depends_on "vte3"
  depends_on "webkitgtk@2.4.11"
  depends_on "gtkmm3"
  depends_on "gnome-icon-theme"

  def install
    # these libraries are named differently in macOS
    inreplace "SConstruct", "boost_thread", "boost_thread-mt"
    inreplace "SConstruct", "boost_log'", "boost_log-mt'"

    args = [
      "--propagate-environment",
      "--prefix=#{prefix}",
      "--disable-embedded-editor",
      "--disable-plugins",
    ]
    scons "install", *args
  end

  test do
    system "false"
  end
end
