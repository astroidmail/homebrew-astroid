class WebkitgtkAT2411 < Formula
  desc "webkitgtk for astroid"
  homepage "https://webkitgtk.org/"
  url "https://webkitgtk.org/releases/webkitgtk-2.4.11.tar.xz"
  sha256 "588aea051bfbacced27fdfe0335a957dca839ebe36aa548df39c7bbafdb65bf7"

  bottle do
    # NOTE: when you merge this PR, be sure to update the the URL below to:
    #       https://github.com/astroidmail/homebrew-astroid/raw/master/bottles
    #       (and to remove this note, of course)
    #
    root_url "https://github.com/c-alpha/homebrew-astroid/raw/webkitgtk%402.4.11-bottle/bottles"
    sha256 "92e3b2c6c9ce1de8f66ee0671aa9cbea12acb6e6e93178c98648c57e742e5792" => :high_sierra
  end
  
  depends_on "gettext"
  depends_on "icu4c"
  depends_on "gtk+3"
  depends_on "libsoup"
  depends_on "webp"
  depends_on "pkg-config" => :build
  depends_on "autoconf" => :build
  depends_on "automake" => :build

  patch :p0, :DATA

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

__END__
------------------------------------------------------------------------
r216187 | annulen@yandex.ru | 2017-05-05 00:33:41 +0900 (Fri, 05 May 2017) | 28 lines

Fix compilation with ICU 59.1
https://bugs.webkit.org/show_bug.cgi?id=171612

Reviewed by Mark Lam.

ICU 59.1 has broken source compatibility. Now it defines UChar as
char16_t, which does not allow automatic type conversion from unsigned
short in C++ code.

--- Source/JavaScriptCore/API/JSStringRef.cpp.orig  2016-04-10 06:48:36 UTC
+++ Source/JavaScriptCore/API/JSStringRef.cpp
@@ -37,7 +37,7 @@ using namespace WTF::Unicode;
 JSStringRef JSStringCreateWithCharacters(const JSChar* chars, size_t numChars)
 {
     initializeThreading();
-    return OpaqueJSString::create(chars, numChars).leakRef();
+    return OpaqueJSString::create(reinterpret_cast<const UChar*>(chars), numChars).leakRef();
 }

 JSStringRef JSStringCreateWithUTF8CString(const char* string)
@@ -62,7 +62,7 @@ JSStringRef JSStringCreateWithUTF8CString(const char*
 JSStringRef JSStringCreateWithCharactersNoCopy(const JSChar* chars, size_t numChars)
 {
     initializeThreading();
-    return OpaqueJSString::create(StringImpl::createWithoutCopying(chars, numChars)).leakRef();
+    return OpaqueJSString::create(StringImpl::createWithoutCopying(reinterpret_cast<const UChar*>(chars), numChars)).leakRef();
 }

 JSStringRef JSStringRetain(JSStringRef string)
@@ -83,7 +83,7 @@ size_t JSStringGetLength(JSStringRef string)

 const JSChar* JSStringGetCharactersPtr(JSStringRef string)
 {
-    return string->characters();
+    return reinterpret_cast<const JSChar*>(string->characters());
 }

 size_t JSStringGetMaximumUTF8CStringSize(JSStringRef string)
--- Source/JavaScriptCore/runtime/DateConversion.cpp.orig 2013-08-03 16:10:38 UTC
+++ Source/JavaScriptCore/runtime/DateConversion.cpp
@@ -107,7 +107,8 @@ String formatDateTime(const GregorianDateTime& t, Date
 #if OS(WINDOWS)
             TIME_ZONE_INFORMATION timeZoneInformation;
             GetTimeZoneInformation(&timeZoneInformation);
-            const WCHAR* timeZoneName = t.isDST() ? timeZoneInformation.DaylightName : timeZoneInformation.StandardName;
+            const WCHAR* winTimeZoneName = t.isDST() ? timeZoneInformation.DaylightName : timeZoneInformation.StandardName;
+            String timeZoneName(reinterpret_cast<const UChar*>(winTimeZoneName));
 #else
             struct tm gtm = t;
             char timeZoneName[70];
--- Source/WebKit2/Shared/API/c/WKString.cpp.orig 2016-04-10 06:48:37 UTC
+++ Source/WebKit2/Shared/API/c/WKString.cpp
@@ -55,7 +55,7 @@ size_t WKStringGetLength(WKStringRef stringRef)
 size_t WKStringGetCharacters(WKStringRef stringRef, WKChar* buffer, size_t bufferLength)
 {
     COMPILE_ASSERT(sizeof(WKChar) == sizeof(UChar), WKStringGetCharacters_sizeof_WKChar_matches_UChar);
-    return (toImpl(stringRef)->getCharacters(static_cast<UChar*>(buffer), bufferLength));
+    return (toImpl(stringRef)->getCharacters(reinterpret_cast<UChar*>(buffer), bufferLength));
 }

 size_t WKStringGetMaximumUTF8CStringSize(WKStringRef stringRef)
