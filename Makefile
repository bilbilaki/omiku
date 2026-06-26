SHELL := powershell.exe
.SHELLFLAGS := -NoProfile -ExecutionPolicy Bypass -Command

ROOT_DIR := $(CURDIR)
STATUS_DIR := $(ROOT_DIR)/tlib
GITWRAPPER_DIR := $(ROOT_DIR)/vfslib
WINDOWS_STATUS_LIB := $(ROOT_DIR)/windows/libextractor.dll
WINDOWS_GIT_LIB := $(ROOT_DIR)/windows/libgit.dll

ANDROID_JNILIBS_DIR := $(ROOT_DIR)/android/app/src/main/jniLibs
ANDROID_API ?= 21
NDK_HOST_TAG ?= windows-x86_64

# Build both status and git libraries
.PHONY: all status  android    android-arm64    android-arm64-myanimelib   list-status  clean-status

all: status 

status: android list-status

# Android builds for status library
android: android-arm64 android-arm64-myanimelib

android-arm64:
	New-Item -ItemType Directory -Force '$(ANDROID_JNILIBS_DIR)/arm64-v8a' | Out-Null; 	$$env:GOOS='android'; $$env:GOARCH='arm64'; $$env:CGO_ENABLED='1'; 	$$env:CC="C:/Users/esil/Documents/sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/$(NDK_HOST_TAG)/bin/aarch64-linux-android$(ANDROID_API)-clang.cmd"; go -C '$(STATUS_DIR)' build -buildmode=c-shared -trimpath -o '$(ANDROID_JNILIBS_DIR)/arm64-v8a/libextractor.so' .
android-x64:
	New-Item -ItemType Directory -Force '$(ANDROID_JNILIBS_DIR)/x86_64' | Out-Null; 	$$env:GOOS='android'; $$env:GOARCH='amd64'; $$env:CGO_ENABLED='1'; 	$$env:CC="C:/Users/esil/Documents/sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/$(NDK_HOST_TAG)/bin/x86_64-linux-android$(ANDROID_API)-clang.cmd";go -C '$(STATUS_DIR)' build -buildmode=c-shared -trimpath -o '$(ANDROID_JNILIBS_DIR)/x86_64/libextractor.so' .
android-x86:
	New-Item -ItemType Directory -Force '$(ANDROID_JNILIBS_DIR)/x86' | Out-Null; 	$$env:GOOS='android'; $$env:GOARCH='386'; $$env:CGO_ENABLED='1'; 	$$env:CC="C:/Users/esil/Documents/sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/$(NDK_HOST_TAG)/bin/i686-linux-android$(ANDROID_API)-clang.cmd"; go -C '$(STATUS_DIR)' build -buildmode=c-shared -trimpath -o '$(ANDROID_JNILIBS_DIR)/x86/libextractor.so' .


android-arm64-myanimelib:
	New-Item -ItemType Directory -Force '$(ANDROID_JNILIBS_DIR)/arm64-v8a' | Out-Null; 	$$env:GOOS='android'; $$env:GOARCH='arm64'; $$env:CGO_ENABLED='1'; 	$$env:CC="C:/Users/esil/Documents/sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/$(NDK_HOST_TAG)/bin/aarch64-linux-android$(ANDROID_API)-clang.cmd"; go -C '$(GITWRAPPER_DIR)' build -buildmode=c-shared  -trimpath -o  '$(ANDROID_JNILIBS_DIR)/arm64-v8a/vfslib.so' .
android-x64-myanimelib:
	New-Item -ItemType Directory -Force '$(ANDROID_JNILIBS_DIR)/x86_64' | Out-Null; 	$$env:GOOS='android'; $$env:GOARCH='amd64'; $$env:CGO_ENABLED='1'; 	$$env:CC="C:/Users/esil/Documents/sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/$(NDK_HOST_TAG)/bin/x86_64-linux-android$(ANDROID_API)-clang.cmd";go -C '$(GITWRAPPER_DIR)' build -buildmode=c-shared  -trimpath -o  '$(ANDROID_JNILIBS_DIR)/x86_64/vfslib.so' .
android-x86-myanimelib:
	New-Item -ItemType Directory -Force '$(ANDROID_JNILIBS_DIR)/x86' | Out-Null; 	$$env:GOOS='android'; $$env:GOARCH='386'; $$env:CGO_ENABLED='1'; 	$$env:CC="C:/Users/esil/Documents/sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/$(NDK_HOST_TAG)/bin/i686-linux-android$(ANDROID_API)-clang.cmd"; go -C '$(GITWRAPPER_DIR)' build -buildmode=c-shared  -trimpath -o  '$(ANDROID_JNILIBS_DIR)/x86/vfslib.so' .

list-status:
	Write-Host 'Status native outputs:'; 	Write-Host ' $(ANDROID_JNILIBS_DIR)/arm64-v8a/vfslib.so'; Write-Host '  $(ANDROID_JNILIBS_DIR)/arm64-v8a/libextractor.so';


clean-status:
	Remove-Item -Force -ErrorAction SilentlyContinue '$(ANDROID_JNILIBS_DIR)/arm64-v8a/libextractor.so', '$(ANDROID_JNILIBS_DIR)/arm64-v8a/vfslib.so'

