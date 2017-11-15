class Astroid < Formula
  desc "A graphical threads-with-tags style, lightweight and fast, email client for notmuch, inspired by sup and others"
  homepage "http://astroidmail.github.io/"

  # not necessary for homebrew but nice to only bump it in one place
  version "0.9.1"
  url "https://github.com/astroidmail/astroid/archive/v#{version}.tar.gz"
  sha256 "7d58a813a9e8f840475226a254743e0caf50f1baf830256ce17e135b71f34714"
  head "https://github.com/astroidmail/astroid.git"

  depends_on "cmake" => :build
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

    args = [
      "-DCMAKE_BUILD_TYPE:STRING=Release",
      "-DCMAKE_INSTALL_PREFIX:PATH=#{prefix}",
      "-DDISABLE_EMBEDDED_EDITOR:BOOL=OFF",
      "-DDISABLE_LIBSASS:BOOL=OFF",
      "-DDISABLE_PLUGINS:BOOL=OFF",
      "-DDISABLE_TERMINAL:BOOL=OFF",
      "-DENABLE_PROFILING:BOOL=OFF",
      "-H.",
      "-Bbuild",
      "-GNinja",
    ]
    system "cmake", *args
    system "cmake", "--build", "build", "--target", "install"
  end

  test do
    system "false"
  end
end
