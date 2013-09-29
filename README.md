Polipoid brings the Polipo HTTP proxy to Android. Polipo lets you do useful things such as cache web pages for offline access and should generally speed up browsing a little.

Building
========

Polipoid acts as a thin wrapper around the 'Polipo' HTTP proxy. The code is written in the Xtend programming language and is built using Maven. Consequently, to build it you will need in addition to the SDK:

  - The Android NDK (or a polipo binary which will run on the Android system you're targeting).
  - Maven installed and set up to use the Android Support Repository (see below).

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

Setup Maven
-----------
In addition to installing Maven you will need to make sure the "Android Support Repository" is installed. You can do this by opening the "Android SDK Manager", expanding "Extras" and downloading "Android Support Repository". Now, assuming you've got your ANDROID_HOME environment variable set, you should be all set up.

Another option is to run the https://github.com/mosabua/maven-android-sdk-deployer/ to install the artifacts to your ~/.m2/repository directory.

Build APK
---------
Once you've done all the above, all you should have to do to build the APK is run `mvn package` to build `target/polipoid.apk`.

To deploy this APK to your android device or emulator you can run `mvn android:deploy`. During development I tend to just use Eclipse for this though.


Developing
==========

I use Eclipse to develop the application, and you can too, once you've got Building working. After you've done the following steps you can import the code and act like it's a normal Android project.

Setup Xtend plugin for Eclipse
------------------------------

Xtend is described as a modernized Java. It gets rid of a lot of the boilerplate code without adding a big runtime dependency (like Scala for example).

Install it by following the instructions on this page http://www.eclipse.org/xtend/download.html. The .xtend files live in src/, and generated .java lives in gen/. To follow stack traces you will need to look at the generated files. Also breakpoints only seem to work when set on the .java (as of writing).

Setup m2e-android plugin for Eclipse
------------------------------

This plugin is needed so that Eclipse knows about the maven included dependencies. You need the Eclipse marketplace plugin to install it. Then just search for android m2e and install. See http://rgladwell.github.io/m2e-android/
