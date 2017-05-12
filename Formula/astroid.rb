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

  # Currently requires gmime 2.6.x
  resource "gmime" do
    url "https://download.gnome.org/sources/gmime/2.6/gmime-2.6.23.tar.xz"
    sha256 "7149686a71ca42a1390869b6074815106b061aaeaaa8f2ef8c12c191d9a79f6a"
  end


  def install
    resource("gmime").stage do
      system "./configure", "--prefix=#{prefix}/gmime"
      system "make", "install"
      ENV.append_path "PKG_CONFIG_PATH", "#{prefix}/gmime/lib/pkgconfig"
    end
    # these libraries are named differently in macOS
    inreplace "SConstruct", "boost_thread", "boost_thread-mt"
    inreplace "SConstruct", "boost_log'", "boost_log-mt'"

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
