Polipoid brings the Polipo HTTP proxy to Android. Polipo lets you do useful things such as cache web pages for offline access and should generally speed up browsing a little.

Building
========

Polipoid acts as a thin wrapper around the 'Polipo' HTTP proxy. Also, the code is written in the Xtend programming language. Consequently, to build it you will need in addition to the SDK:

  - The Android NDK (or a polipo binary which will run on the Android system you're targeting)
  - Some way of compiling Xtend to java, I used the Xtend eclipse plugin

Build Polipo binary
-------------------

We need a copy of the Polipo binary which will run on the machine you're building for. Once it's built just put it in the root of the assets/ directory. The following steps should take you through the process. See `$NDK/docs/STANDALONE-TOOLCHAIN.html` for more info.

1. Run the following to set up your toolchain, $NDK is the root of your NDK installation:

    mkdir /tmp/toolchain
    $NDK/build/tools/make-standalone-toolchain.sh --platform=android-8 --install-dir=/tmp/toolchain

This will set up an ARM toolchain in /tmp/toolchain. If you're building for a different architecture, just add `--arch=x86` or whatever's appropriate.
2. Go to the `polipo/` direcory in the polipoid source and run the following:

    export PATH=/tmp/toolchain/bin:$PATH
    export CC=arm-linux-androideabi-gcc #or i686-linux-android-gcc if you're building x86
    EXTRA_DEFINES="-U __linux__" make polipo

If you get an error like "sysinfo not defined" when running make, you may have to edit the Polipo source (particularly util.c) to not use the sysinfo call. This is a bug in android versions 8 and below (fixed in v9). The EXTRA_DEFINES variable should hopefully take care of this though.

3. Now copy the polipo binary to the assets folder using `cp polipo ../assets/`

Setup Xtend for Eclipse
-----------------------

Xtend is described as a modernized Java. It gets rid of a lot of the boilerplate code without adding a big runtime dependency (like Scala for example).

Install it by following the instructions on this page http://www.eclipse.org/xtend/download.html. The .xtend files live in src/, and generated .java lives in gen/. To follow stack traces you will need to look at the generated files. Also breakpoints only seem to work when set on the .java (as of writing).

Exporting the APK
-----------------

Things should work fine if you use Eclipse's "Run As Android Application" menu. If you need to use Eclipse's 'Export' option (to make a release for example) you need to make sure that the project's "Java Build Path" contains the Xtend Library, but does not contain the "Android Private Libraries". You've forgotten to do this if you get an error like 'Multiple dex files define Lcom/google/common/annotations/Beta;'.
