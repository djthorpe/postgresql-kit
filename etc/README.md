
There are a few scripts in this folder for building and testing.

  * `build-frameworks.sh` will build all iOS and Mac frameworks.
	This will build for Release, not Debug.
  * `test-frameworks.sh` will run the unit tests for the frameworks. This will
    build for Debug, not Release.
  * `build-macapps.sh` will build the Mac OSX applications for Release.
  * `build-iosapps.sh` will build the iOS applications for Release.

Any of these commands will return the message `** BUILD FAILED **` or
`** BUILD SUCCEEDED **` on completion. For those which failed, please file
issues on GitHub with the text of the build log.

The other scripts in this folder are used as part of the build process.



