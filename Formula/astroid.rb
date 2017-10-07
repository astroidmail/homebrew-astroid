class Astroid < Formula
  desc "A graphical threads-with-tags style, lightweight and fast, email client for notmuch, inspired by sup and others"
  homepage "http://astroidmail.github.io/"

  # not necessary for homebrew but nice to only bump it in one place
  version "0.9.1"
  url "https://github.com/astroidmail/astroid/archive/v#{version}.tar.gz"
  sha256 "7d58a813a9e8f840475226a254743e0caf50f1baf830256ce17e135b71f34714"
  head "https://github.com/astroidmail/astroid.git"

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "libsass"
  depends_on "libpeas"
  depends_on "notmuch"
  depends_on "boost"
  depends_on "vte3"
  depends_on "webkitgtk@2.4.11"
  depends_on "gtkmm3"
  depends_on "gnome-icon-theme"

  def install
    ENV.append_path "PKG_CONFIG_PATH", "/usr/local/opt/webkitgtk@2.4.11//lib/pkgconfig"
    ENV.append_path "BOOST_ROOT", "/usr/local/"

    args = [
      "--prefix=#{prefix}",
      "-Ddisable-embedded-editor=true",
      "-Ddisable-plugins=true",
      "-Ddisable-tests=true",
    ]
    system "meson", "build", *args
    system "sed", "-i", "-e", "s/boost_log\ /boost_log-mt\ /g", "build/build.ninja"
    system "ninja -C build install"
  end

  test do
    system "false"
  end
end
