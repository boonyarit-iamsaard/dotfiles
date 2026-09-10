# Android SDK environment and Java compatibility

Research checked on 2026-09-10 against first-party documentation and source.

## Local verification

On this workstation, the existing React Native 0.86 / Expo SDK 57 checkout was
tested with the same Gradle task and no clean between runs:

- With `JAVA_HOME` pointing to Temurin 25.0.4.1,
  `:react-native-screens:configureCMakeDebug[arm64-v8a]` failed because AGP
  treated Java's restricted-method warning as an `IllegalStateException`.
- With only `JAVA_HOME` changed to the Scoop Temurin 17 installation, the full
  `:react-native-screens:configureCMakeDebug` task completed successfully for
  all four Android ABIs.

This differential run isolates the Gradle runtime JDK as the cause of the
reported failure. CMake still emitted path-length warnings, but they did not
fail the task.

## Android SDK environment

- Set `ANDROID_HOME` to the SDK installation directory. Android calls
  `ANDROID_SDK_ROOT` deprecated and says that, when both variables exist,
  Android Studio and the Android Gradle plugin check that their values agree.
  New configuration should therefore persist `ANDROID_HOME` and omit
  `ANDROID_SDK_ROOT`; retain the latter only for a known legacy consumer, with
  the same value.
  ([Android environment-variable reference](https://developer.android.com/tools/variables))
- On Windows, React Native 0.86 documents the default SDK location as
  `%LOCALAPPDATA%\Android\Sdk` and explicitly adds
  `%LOCALAPPDATA%\Android\Sdk\platform-tools` to the user `Path`.
  ([React Native 0.86 Windows setup](https://reactnative.dev/docs/0.86/set-up-your-environment#3-configure-the-android_home-environment-variable))
- For the tools used by this repository, the useful modern `Path` entries are
  `%ANDROID_HOME%\platform-tools` (`adb`/`fastboot`), `%ANDROID_HOME%\emulator`
  (`emulator`), and `%ANDROID_HOME%\cmdline-tools\latest\bin`
  (`sdkmanager`/`avdmanager`). Android documents the command-line tools at
  `cmdline-tools/<version>/bin`, describes them as the replacement for the old
  `tools` package, and documents `cmdline-tools/latest/bin/sdkmanager` for local
  use; React Native documents the `emulator` and `platform-tools` entries.
  ([Android command-line tools](https://developer.android.com/tools),
  [Android `sdkmanager`](https://developer.android.com/tools/sdkmanager),
  [React Native 0.86 setup](https://reactnative.dev/docs/0.86/set-up-your-environment#3-configure-the-android_home-environment-variable))

## React Native 0.86 / Expo SDK 57 Java compatibility

- Expo SDK 57 contains React Native 0.86.
  ([Expo SDK 57 release notes](https://expo.dev/changelog/sdk-57))
- The framework-level recommendation is **JDK 17**. React Native 0.86 says it
  recommends JDK 17 and warns that higher JDK versions may cause problems.
  Expo's Android setup likewise installs OpenJDK 17, and Expo's SDK 57 EAS
  Android image runs Java 17.
  ([React Native 0.86 environment setup](https://reactnative.dev/docs/0.86/set-up-your-environment#java-development-kit),
  [Expo Android setup](https://docs.expo.dev/workflow/android-studio-emulator/#install-jdk),
  [Expo build-server image](https://docs.expo.dev/build-reference/infrastructure/#android-server-images))
- React Native 0.86's Gradle plugin pins Android Gradle Plugin (AGP) 8.12.0.
  Google's compatibility table gives AGP 8.12 a minimum/default JDK of 17 and a
  minimum/default Gradle of 8.13.
  ([React Native 0.86 version catalog](https://github.com/facebook/react-native/blob/v0.86.0/packages/gradle-plugin/gradle/libs.versions.toml),
  [AGP 8.12 compatibility](https://developer.android.com/build/releases/agp-8-12-0-release-notes#compatibility))
- Expo SDK 57's bare template uses Gradle 9.3.1. Gradle's compatibility matrix
  says Java 17 is supported for running Gradle from 7.3 onward, Java 21 from 8.5
  onward, and Java 25 from 9.1 onward. Thus Gradle 9.3.1 itself can run on JDK
  17 through 25, but that is a Gradle-runtime range, not a React Native or Expo
  endorsement of every JDK in it.
  ([Expo SDK 57 Gradle wrapper](https://github.com/expo/expo/blob/sdk-57/templates/expo-template-bare-minimum/android/gradle/wrapper/gradle-wrapper.properties),
  [Gradle Java compatibility matrix](https://docs.gradle.org/current/userguide/compatibility.html#java_runtime))

## Decision for these dotfiles

Use **JDK 17** for React Native 0.86 / Expo SDK 57 Android builds. Keep JDK 25
as the workstation default for other development and switch the current
PowerShell session to 17 for Android builds. JDK 21 is within the underlying
Gradle runtime's supported range and meets AGP's minimum, but neither React
Native 0.86 nor Expo SDK 57 recommends it over 17. JDK 25 is also accepted by
Gradle 9.3.1, so the claim that the stack's official supported range is exactly
"17-21" is not supported by these primary sources; React Native's own warning
about higher versions is the reason not to use 25 for this React Native stack.
