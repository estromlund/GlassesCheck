# Glasses Check

### What is this?
I always forget to wear my "computer glasses" when I'm on my computer. This is an OS X app to help with that.

It uses OpenCV to detect if you are wearing glasses. Right now, it is hard configured to do this on startup and at certain intervals.

If it doesn't detect glasses, it will nag you until you put them on.

### Building it
You will need to have the OpenCV framework installed. There are a few ways to do this, but I used Homebrew with a simple:

````bash
brew update && brew install opencv
````

If your frameworks are installed to any special locations, you may need to change the `Header Search Path`, `Framework Search Path` and `Library Search Path` values in Xcode's Project Settings.

Beyond that, all you need is to install the project dependencies:
````bash
bundle install
pod install
````

### Technical Details
This is an OS X (10.10+) "menu bar app" with no GUI outside of the NSStatusItem that sits in the system menu bar.

It uses OpenCV to do eyeglass detection, and ReactiveCocoa to bring it all together.
