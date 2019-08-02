# coding: utf-8
class Webkitgtk < Formula
  desc "WebkitGTK+ is a full-featured port of the WebKit rendering engine, suitable for projects requiring any kind of web integration, from hybrid HTML/CSS applications to full-fledged web browsers. It’s the official web engine of the GNOME platform and is used in browsers such as Epiphany and Midori."
  homepage "https://webkitgtk.org/"

  version "2.22.7"
  url "https://webkitgtk.org/releases/webkitgtk-2.22.7.tar.xz"
  sha256 "4be6f7d605cd0a690fd26e8aa83b089a33ad9d419148eafcfb60580dd2af30ff"
  patch :DATA

  # build-time dependencies
  depends_on "cmake" => :build
  depends_on "gobject-introspection" => :build
  depends_on "ninja" => :build
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
  depends_on "icu4c"

  def install
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
      -GNinja
      -DPORT=GTK
      -DCMAKE_BUILD_TYPE=RelWithDebInfo
      -DENABLE_INTROSPECTION=OFF
      -DENABLE_GEOLOCATION=OFF
      -DENABLE_OPENGL=OFF
      -DENABLE_VIDEO=OFF
      -DENABLE_WEB_AUDIO=OFF
      -DUSE_LIBHYPHEN=OFF
      -DUSE_SYSTEM_MALLOC=ON
      -DCMAKE_CXX_FLAGS=-Wno-unused-lambda-capture
    ]

    mkdir "build" do
      system "cmake", *std_cmake_args, *args, ".."
      system "ninja", "install"
    end
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
diff -Naur a/Source/WTF/wtf/RAMSize.cpp b/Source/WTF/wtf/RAMSize.cpp
--- a/Source/WTF/wtf/RAMSize.cpp	2019-02-28 11:08:19.000000000 +0100
+++ b/Source/WTF/wtf/RAMSize.cpp	2019-03-12 19:41:46.000000000 +0100
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
diff -Naur a/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp b/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp
--- a/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp	2019-02-28 11:08:20.000000000 +0100
+++ b/Source/WebCore/page/scrolling/coordinatedgraphics/ScrollingStateNodeCoordinatedGraphics.cpp	2019-03-12 19:41:46.000000000 +0100
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
diff -Naur a/Source/WebCore/platform/PlatformWheelEvent.h b/Source/WebCore/platform/PlatformWheelEvent.h
--- a/Source/WebCore/platform/PlatformWheelEvent.h	2019-02-28 11:08:20.000000000 +0100
+++ b/Source/WebCore/platform/PlatformWheelEvent.h	2019-03-12 19:43:22.000000000 +0100
@@ -213,6 +213,8 @@

 #if PLATFORM(COCOA) || PLATFORM(GTK)

+#if ENABLE(ASYNC_SCROLLING)
+
 inline bool PlatformWheelEvent::isEndOfNonMomentumScroll() const
 {
     return m_phase == PlatformWheelEventPhaseEnded && m_momentumPhase == PlatformWheelEventPhaseNone;
@@ -222,6 +224,9 @@
 {
     return m_phase == PlatformWheelEventPhaseNone && m_momentumPhase == PlatformWheelEventPhaseBegan;
 }
+
+#endif
+
 #endif

 } // namespace WebCore
diff -Naur a/Source/WebCore/platform/graphics/OpenGLShims.h b/Source/WebCore/platform/graphics/OpenGLShims.h
--- a/Source/WebCore/platform/graphics/OpenGLShims.h	2017-05-10 21:32:44.000000000 +0200
+++ b/Source/WebCore/platform/graphics/OpenGLShims.h	2019-03-12 19:41:46.000000000 +0100
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
diff -Naur a/Source/WebCore/platform/gtk/PlatformWheelEventGtk.cpp b/Source/WebCore/platform/gtk/PlatformWheelEventGtk.cpp
--- a/Source/WebCore/platform/gtk/PlatformWheelEventGtk.cpp	2019-02-28 11:08:20.000000000 +0100
+++ b/Source/WebCore/platform/gtk/PlatformWheelEventGtk.cpp	2019-03-12 19:43:45.000000000 +0100
@@ -116,7 +116,11 @@
 FloatPoint PlatformWheelEvent::swipeVelocity() const
 {
     // The swiping velocity is stored in the deltas of the event declaring it.
+# if ENABLE(ASYNC_SCROLLING)
     return isTransitioningToMomentumScroll() ? FloatPoint(m_wheelTicksX, m_wheelTicksY) : FloatPoint();
+# else
+    return FloatPoint();
+# endif
 }

 }
diff -Naur a/Source/WebCore/platform/gtk/ScrollAnimatorGtk.cpp b/Source/WebCore/platform/gtk/ScrollAnimatorGtk.cpp
--- a/Source/WebCore/platform/gtk/ScrollAnimatorGtk.cpp	2019-02-28 11:08:20.000000000 +0100
+++ b/Source/WebCore/platform/gtk/ScrollAnimatorGtk.cpp	2019-03-12 19:42:38.000000000 +0100
@@ -132,6 +132,7 @@
         return (event.timestamp() - otherEvent.timestamp()) > scrollCaptureThreshold;
     });

+# if ENABLE(ASYNC_SCROLLING)
     if (event.isEndOfNonMomentumScroll()) {
         // We don't need to add the event to the history as its delta will be (0, 0).
         static_cast<ScrollAnimationKinetic*>(m_kineticAnimation.get())->start(m_currentPosition, computeVelocity(), m_scrollableArea.horizontalScrollbar(), m_scrollableArea.verticalScrollbar());
@@ -142,6 +143,7 @@
         static_cast<ScrollAnimationKinetic*>(m_kineticAnimation.get())->start(m_currentPosition, event.swipeVelocity(), m_scrollableArea.horizontalScrollbar(), m_scrollableArea.verticalScrollbar());
         return true;
     }
+# endif

     m_scrollHistory.append(event);

diff -Naur a/Source/WTF/wtf/Optional.h b/Source/WTF/wtf/Optional.h
--- a/Source/WTF/wtf/Optional.h	2019-02-28 11:08:20.000000000 +0100
+++ b/Source/WTF/wtf/Optional.h	2019-03-12 19:42:38.000000000 +0100
@@ -277,12 +277,14 @@
 constexpr nullopt_t nullopt{nullopt_t::init()};


+# if !defined(_LIBCPP_VERSION) || _LIBCPP_VERSION < 7000
 // 20.5.8, class bad_optional_access
 class bad_optional_access : public std::logic_error {
 public:
   explicit bad_optional_access(const std::string& what_arg) : std::logic_error{what_arg} {}
   explicit bad_optional_access(const char* what_arg) : std::logic_error{what_arg} {}
 };
+# endif // _LIBCPP_VERSION < 7000


 template <class T>
