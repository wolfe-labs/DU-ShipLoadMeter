# Ship Load Meter for Dual Universe

Just a small script to show your ship's current load against it's maximum theorical capacity, which takes into account your engines thrust, lift, brakes and other parameters into account.

## Installation

You can download the latest stable version of the script from the Releases section on GitHub or the latest development version under "Actions". Please keep in mind that development builds may be buggy.

The minimal setup requires that you have a Programming Board for the script linked in the following order:

1. **Core Unit:** Your ship's Core Unit. It is required to extract information about the ship mass and other parameters.
2. **Main Screen:** The screen you'll be using to control the script via touch input, ideally placed on your ship's dashboard.

Optionally you can also add extra screens that will just replicate the contents of the main screen, those are not interactive. You can also add lights that will act as indicators of the ship being overweight.

In both cases the setup is very straightforward, just link them to your Programming Board and be happy, the script will figure out all other details by itself!

## Options

If you open the "Edit Lua Parameters" screen you will be presented with some settings to make the script behave closer to your liking, they are:

- `Target_Gs` is the same value that many use as reference on the ship building parameters. For example, if when you are building your ship you aim for 3.0g on its stats when full, then put `3.0` on this field. This value is constant and is used to determine the maximum weight of your ship and properly display how much cargo you can fit.

- `CustomBackground` turns on/off the option of having your own image as background. Please see next item for more details.

- `CustomBackgroundUrl` contains the actual URL to your custom background. Please keep in mind that due to the way Lua parameters work, after setting this to an URL you will not be able to change it anymore via the Edit Lua Parameters screen. To fix this you will need to reinstall the script on your Programming Board and reconfigure it.