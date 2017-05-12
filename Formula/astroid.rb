class Astroid < Formula
  desc "A graphical threads-with-tags style, lightweight and fast, email client for notmuch, inspired by sup and others"
  homepage "http://astroidmail.github.io/"

  # not necessary for homebrew but nice to only bump it in one place
  version "0.9.1"
  url "https://github.com/astroidmail/astroid/archive/v#{version}.tar.gz"
  sha256 "7d58a813a9e8f840475226a254743e0caf50f1baf830256ce17e135b71f34714"
  head "https://github.com/astroidmail/astroid.git"

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

    # Currently requires gmime 2.6.x. Use the library built with notmuch:
    # see https://github.com/astroidmail/homebrew-astroid/pull/7
    ENV.append_path "PKG_CONFIG_PATH", "/usr/local/opt/notmuch/gmime/lib/pkgconfig"

    args = [
      "--propagate-environment",
      "--prefix=#{prefix}",
      "--disable-embedded-editor",
      "--disable-plugins",
      "--release=v#{version}",
    ]
    # overwrite --release if --HEAD with `git` magic variable for SCons
    args += [ "--release=git" ] if build.head?
    scons "install", *args
  end

  test do
    system "false"
  end
end
