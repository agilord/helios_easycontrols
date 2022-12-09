Read status and set levels on Helios KWL devices that run easyControls 3.0 (HTTP interface).

## Features

- Read the current status of supply and extract air percent and RPMs.
- Sets the target supply and extract air percent.

## Additional information

The package uses headless Chrome (via `package:puppeteer`) to access the device.

In its current form it is advised to not access the device frequently, as
it seems to overload the KWL server and "freezes" it. Every 15-30 minutes
seems to be fine.

Contributing to improve the package is more than welcome!
