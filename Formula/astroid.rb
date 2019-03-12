class Astroid < Formula
  desc "A graphical threads-with-tags style, lightweight and fast, email client for notmuch, inspired by sup and others"
  homepage "http://astroidmail.github.io/"

  # not necessary for homebrew but nice to only bump it in one place
  version "0.14"
  url "https://github.com/astroidmail/astroid/archive/v#{version}.tar.gz"
  # sha256 "f2ab06859e3d2d6a8e947b6fd640de61b8c49cd0ebbbaaa2df9527ce2efa40db"
  head "https://github.com/astroidmail/astroid.git"

  depends_on "cmake" => :build
  # only use ninja if building devel
  depends_on "ninja" => :build if build.head?
  depends_on "libsass"
  depends_on "libpeas"
  depends_on "notmuch"
  depends_on "boost"
  depends_on "vte3"
  depends_on "webkitgtk"
  depends_on "gtkmm3"
  depends_on "gnome-icon-theme"
  depends_on "protobuf-c"

  def install

    args = [
      "-DCMAKE_BUILD_TYPE:STRING=Release",
      "-DCMAKE_INSTALL_PREFIX:PATH=#{prefix}",
      "-DDISABLE_EMBEDDED_EDITOR:BOOL=OFF",
      "-DDISABLE_LIBSASS:BOOL=OFF",
      "-DDISABLE_PLUGINS:BOOL=OFF",
      "-DDISABLE_TERMINAL:BOOL=OFF",
      "-DENABLE_PROFILING:BOOL=OFF",
      "-DDISABLE_DOCS=ON",
      "-GUnix\ Makefiles",
    ]
  # only use ninja if building devel, ninja is possibly faster
    args += [
      "-DCMAKE_BUILD_TYPE:STRING=Debug",
      "-GNinja",
    ] if build.head?
    system "cmake", *args, "-H.", "-Bbuild"
    system "cmake", "--build", "build", "--target", "install"
  end

  test do
    system "false"
  end
end
