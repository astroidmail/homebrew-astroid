class WebkitgtkAT2411 < Formula
  desc "webkitgtk for astroid"
  homepage "https://webkitgtk.org/"
  url "https://webkitgtk.org/releases/webkitgtk-2.4.11.tar.xz"
  sha256 "588aea051bfbacced27fdfe0335a957dca839ebe36aa548df39c7bbafdb65bf7"

  depends_on "gettext"
  depends_on "icu4c"
  depends_on "gtk+3"
  depends_on "libsoup"
  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  def install
    ENV.deparallelize

    icu4c = Formula["icu4c"]

    # build options without ./configure flags
    inreplace "Source/autotools/SetupWebKitFeatures.m4",
              "ENABLE_NETSCAPE_PLUGIN_API=1",
              "ENABLE_NETSCAPE_PLUGIN_API=0"

    # forwarding headers not working for ObjC
    inreplace "Source/JavaScriptCore/API/ObjCCallbackFunction.h",
              "#import <JavaScriptCore/JSCallbackFunction.h>",
              "#import <JavaScriptCore/API/JSCallbackFunction.h>"

    inreplace "Source/JavaScriptCore/API/JSBase.h",
              "JSC_OBJC_API_ENABLED",
              "JSC_OBJC_API_ENABLED_nei_takk"

    # put icu4c headers first so we don't try to mix and match with the
    # provided stand-ins
    inreplace "GNUmakefile.am",
              "-Wall -W -Wcast-align -Wchar-subscripts -Wreturn-type",
              "-I#{icu4c.include} -Wall -W -Wcast-align -Wchar-subscripts -Wreturn-type"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--disable-introspection",
                          "--disable-x11-target",
                          "--enable-quartz-target",
                          "--disable-video",
                          "--disable-web-audio",
                          "--disable-credential-storage",
                          "--disable-geolocation",
                          "--disable-gles2",
                          "--disable-webkit2"

    mkdir_p "DerivedSources/webkit"
    mkdir_p "DerivedSources/Platform"

    system "make"
    system "make", "install"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test webkitgtk-astroid`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
