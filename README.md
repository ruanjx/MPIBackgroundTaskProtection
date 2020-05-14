# MPIBackgroundTaskProtection

## How to use

Drag the `UIApplication + MPIBackgroundTaskProtection` category files into the your project. 

## Documentation

In my application, some SDKs don't use the background task correctly, which caused a leak and was killed by the watchdog.

This category hooks three methods `beginBackgroundTaskWithName:expirationHandler:`, `beginBackgroundTaskWithExpirationHandler:`, and `endBackgroundTask:` to ensure that the `endBackgroundTask:` method is called.
