Polipoid
========

Polipoid brings the Polipo HTTP proxy to Android. Polipo lets you do useful things such as cache web pages for offline access and should generally speed up browsing a little.

<a href="https://f-droid.org/packages/com.polipoid/" target="_blank">
<img src="https://f-droid.org/badge/get-it-on.png" alt="Get it on F-Droid" height="80"/></a>

## Building

Polipoid acts as a thin wrapper around the 'Polipo' HTTP proxy. The code is written in the Xtend programming language and is built using Maven. Consequently, to build it you will need in addition to the SDK:

  - The Android NDK (or a polipo binary which will run on the Android system you're targeting).
  - Maven installed and set up to use the Android Support Repository (see below).

## Build Polipo binary

We need a copy of the Polipo binary which will run on the machine you're building for. Once it's built just put it in the root of the assets/ directory. The following steps should take you through the process. See `$NDK/docs/STANDALONE-TOOLCHAIN.html` for more info.

1. Run the following to set up your toolchains, $NDK is the root of your NDK installation:

   ```bash
    mkdir /tmp/toolchain-9-arm
    mkdir /tmp/toolchain-9-x86
    $NDK/build/tools/make-standalone-toolchain.sh --platform=android-9 --arch=arm --install-dir=/tmp/toolchain-9-arm
    $NDK/build/tools/make-standalone-toolchain.sh --platform=android-9 --arch=x86 --install-dir=/tmp/toolchain-9-x86
   ```

2. Go to the `polipo/` direcory in the polipoid source and run the following:

   ```bash
    make clean
    PATH=/tmp/toolchain-9-arm/bin:$PATH CC=arm-linux-androideabi-gcc EXTRA_DEFINES="-fvisibility=default -fPIE -U __linux__" LDFLAGS="-rdynamic -fPIE -pie" make polipo
    cp polipo ../src/main/assets/polipo-arm

    make clean
    PATH=/tmp/toolchain-9-x86/bin:$PATH CC=i686-linux-android-gcc EXTRA_DEFINES="-fvisibility=default -fPIE -U __linux__" LDFLAGS="-rdynamic -fPIE -pie" make polipo
    cp polipo ../src/main/assets/polipo-x86
   ```

3. Finally to allow the application to run on an Android version earlier than 5.0.0 you will also need to build the 'run_pie' executables for both Arm and x86 CPU architectures. Go to the `src/main/run-pie` directory and run the following:

   ```bash
   /tmp/toolchain-9-arm/bin/arm-linux-androideabi-gcc -o run_pie-arm run_pie.c
   /tmp/toolchain-9-x86/bin/i686-linux-android-gcc -o run_pie-x86 run_pie.c
   cp run_pie-arm ../assets/run_pie-arm
   cp run_pie-x86 ../assets/run_pie-x86
   ```

## Setup Maven

In addition to installing Maven you will need to make sure the "Android Support Repository" is installed. You can do this by opening the "Android SDK Manager", expanding "Extras" and downloading "Android Support Repository". Now, assuming you've got your ANDROID_HOME environment variable set, you should be all set up.

Another option is to run the https://github.com/mosabua/maven-android-sdk-deployer/ to install the artifacts to your ~/.m2/repository directory.

## Build APK

Once you've done all the above, all you should have to do to build the APK is run `mvn package` to build `target/polipoid.apk`.

To deploy this APK to your android device or emulator you can run `mvn android:deploy`. During development I tend to just use Eclipse for this though.


Developing
==========

Initial setup
-------------

I use Eclipse to develop the application, and you can too, once you've got Building working. After you've done the following steps you can import the code and act like it's a normal Android project. You will need to perform the following steps:

1. Install the Eclipse Marketplace Client: https://www.eclipse.org/mpc/
2. Install the Android Development Tools: Search for 'Android Development' in the Eclipse Marketplace (Help -> Eclipse Marketplace).
3. Install the Android for Maven Eclipse plugin: Search for 'android m2e' in the Eclipse Marketplace (Help -> Eclipse Marketplace).
4. Install the Eclipse Xtend plugin : Search for 'Eclipse Xtend' in the Eclipse Marketplace (Help -> Eclipse Marketplace).

If the Xtend support doesn't work, you might need to download the Eclipse pre-packaged with Xtend off the Xtend website, then install the 'Andmore' plugin on top of that.

Debugging
---------

The project is written in Xtend, which gets converted to .java before in turn getting compiled to normal Java .class files. The .xtend files live in src/, and generated .java lives in gen/. To follow stack traces you will need to look at the generated files. Also breakpoints only seem to work when set on the .java (as of writing).

Releasing
=========

To release the project to the Fdroid repo do the following:

1. Ensure the versionCode and versionName fields have been updated in AndroidManifest.xml.
2. Git tag your revision.
3. Update the metadata in https://gitlab.com/fdroid/fdroiddata/blob/master/metadata/com.polipoid.txt to contain the latest build instructions. Ensure the build version and number are included both in the new entry and in the "Current Version" field at the bottom.
