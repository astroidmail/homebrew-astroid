# coding: utf-8
class Webkitgtk < Formula
  desc "WebkitGTK+ is a full-featured port of the WebKit rendering engine, suitable for projects requiring any kind of web integration, from hybrid HTML/CSS applications to full-fledged web browsers. It’s the official web engine of the GNOME platform and is used in browsers such as Epiphany and Midori."
  homepage "https://webkitgtk.org/"

  stable do
    url "https://webkitgtk.org/releases/webkitgtk-2.22.5.tar.xz"
      # sha256 "345487d4d1896e711683f951d1e09387d3b90d7cf59295c0e634af7f515e99ba"
    patch :DATA
  end

  # build-time dependencies
  depends_on "cmake" => :build
  depends_on "gobject-introspection" => :build
  depends_on "ninja" => :build if build.head?     # only use ninja if building devel
  depends_on "pkg-config" => :build

  # run-time dependencies
  depends_on "gtk+3"
  depends_on "enchant"
  depends_on "gettext"
  depends_on "intltool"
  depends_on "itstool"
  depends_on "libcroco"
  depends_on "libepoxy"
  depends_on "libgcrypt"
  depends_on "libgpg-error"
  depends_on "libnotify"
  depends_on "libsecret"
  depends_on "libtasn1"
  depends_on "libtiff"
  depends_on "libtool"
  depends_on "libsoup"
  depends_on "pango"
  depends_on "sqlite"
  depends_on "webp"
  depends_on "woff2"

  #icu4u
  #gettext
  #/usr/local/include

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel

    # https://github.com/WebKit/webkit#building-the-gtk-port
    #
    # DISabling the following faetures, which are on by default:
    # - ENABLE_GEOLOCATION since it requires geoclue, but no formula for it exists
    # - ENABLE_OPENGL since macOS provides CGL, but WebkitGTK+ builds against either GLX or EGL only
    # - USE_LIBHYPHEN since no formula for it exists
    # - ENABLE_VIDEO and ENABLE_WEB_AUDIO since they would require gstreamer and tons of plugins for the codecs
    # - ENABLE_INTROSPECTION since GObject introspection causes the build to break
    #
    # ENabling the following faetures, which are off by default:
    # - USE_SYSTEM_MALLOC since the WebkitGTK+ tarball does not contain the required bmalloc files
    #
    args = %w[
      -DPORT=GTK
      -DCMAKE_BUILD_TYPE=RelWithDebInfo
      -DENABLE_INTROSPECTION=OFF
      -DENABLE_GEOLOCATION=OFF
      -DENABLE_OPENGL=OFF
      -DENABLE_VIDEO=OFF
      -DENABLE_WEB_AUDIO=OFF
      -DUSE_LIBHYPHEN=OFF
      -DUSE_SYSTEM_MALLOC=ON
    ]

    # only use ninja if building devel (ninja is possibly faster)
    args += [
      "-GNinja"
    ] if build.head?

    system "cmake", *args, *std_cmake_args, "-H.", "-Bbuild"
    # system "cmake", *std_cmake_args, "--build", "build", "--target", "install"
    chdir "build" do
      system "make", "install"
    end

    # mkdir "build" do
    #   system "cmake", "..", *(std_cmake_args + extra_args)
    #   system "make", "install"
    # end

    # system "make", "install" # if this fails, try separate make/make install steps
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test webkitgtk`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end

###
# The following patches are needed because...
#
__END__
diff -x '*~' -Naur webkitgtk-2.22.2-orig/Source/WTF/wtf/RAMSize.cpp webkitgtk-2.22.2/Source/WTF/wtf/RAMSize.cpp
--- webkitgtk-2.22.2-orig/Source/WTF/wtf/RAMSize.cpp	2018-02-19 08:45:30.000000000 +0100
+++ webkitgtk-2.22.2/Source/WTF/wtf/RAMSize.cpp	2018-07-02 20:00:42.000000000 +0200
@@ -33,7 +33,13 @@
 #include <windows.h>
 #elif defined(USE_SYSTEM_MALLOC) && USE_SYSTEM_MALLOC
 #if OS(UNIX)
+#if OS(DARWIN)
+// macOS uses a bsd-style sysctl(2), which resembles POSIX
+#include <sys/sysctl.h>
+#else
+// the default for other unix-ish systems is svr4-style sysinfo(2)
 #include <sys/sysinfo.h>
+#endif // OS(DARWIN)
 #endif // OS(UNIX)
 #else
 #include <bmalloc/bmalloc.h>
@@ -56,9 +62,18 @@
     return status.ullTotalPhys;
 #elif defined(USE_SYSTEM_MALLOC) && USE_SYSTEM_MALLOC
 #if OS(UNIX)
+#if OS(DARWIN)
+    // macOS uses a bsd-style sysctl(2), which resembles POSIX
+    int64_t hw_memsize;
+    size_t len = sizeof(hw_memsize);
+    sysctlbyname("hw.memsize", &hw_memsize, &len, NULL, 0);
+    return (size_t)hw_memsize;
+#else
+    // the default for other unix-ish systems is svr4-style sysinfo(2)
     struct sysinfo si;
     sysinfo(&si);
     return si.totalram * si.mem_unit;
+#endif // OS(DARWIN)
 #else
 #error "Missing a platform specific way of determining the available RAM"
 #endif // OS(UNIX)
diff -x '*~' -Naur webkitgtk-2.22.2-orig/Source/WebCore/platform/graphics/OpenGLShims.h webkitgtk-2.22.2/Source/WebCore/platform/graphics/OpenGLShims.h
--- webkitgtk-2.22.2-orig/Source/WebCore/platform/graphics/OpenGLShims.h	2018-02-19 08:45:32.000000000 +0100
+++ webkitgtk-2.22.2/Source/WebCore/platform/graphics/OpenGLShims.h	2018-07-03 17:58:07.000000000 +0200
@@ -20,8 +20,13 @@
 #ifndef OpenGLShims_h
 #define OpenGLShims_h

+#if OS(DARWIN)
+#include <OpenGL/gl.h>
+#include <OpenGL/glext.h>
+#else
 #include <GL/gl.h>
 #include <GL/glext.h>
+#endif

 #if defined(GL_ES_VERSION_2_0)
 // Some openGL ES systems miss this typedef.
diff -x '*~' -Naur webkitgtk-2.22.2-orig/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp webkitgtk-2.22.2/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp
--- webkitgtk-2.22.2-orig/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp	2018-08-06 16:07:41.000000000 +0200
+++ webkitgtk-2.22.2/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp	2018-10-04 17:45:07.000000000 +0200
@@ -30,7 +30,7 @@
 #include "NotImplemented.h"
 #include "ScrollingStateTree.h"

-#if USE(COORDINATED_GRAPHICS)
+#if ENABLE(ASYNC_SCROLLING) || USE(COORDINATED_GRAPHICS)

 namespace WebCore {

@@ -56,4 +56,4 @@

 } // namespace WebCore

-#endif // USE(COORDINATED_GRAPHICS)
+#endif // ENABLE(ASYNC_SCROLLING) || USE(COORDINATED_GRAPHICS)
