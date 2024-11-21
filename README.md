# Shower Controller
A responsive application for controlling my Mira Mode shower.

This project is serving two purposes
- To provide me with an app for controlling my shower that I think is more user friendly than the one provided by the manufacturer
- To give me a reason to learn a bit about what's required for iOS development (this is my first iOS app, and first experience of swift)

This is WORK IN PROGRESS.  Given it's 'tinkering' origins, there's no tests etc that would normally be done for a professional piece of work.

## Bluetooth Protocol
- [Documented Here](https://github.com/nhannam/shower-controller-documentation)

The 4 byte id used for pairing requests is not currently commited in this project.  This can be found by sniffing bluetooth packets for a pairing request and brute forcing the CRC.

## Dependencies
- [AsyncBluetooth](https://github.com/manolofdez/AsyncBluetooth)
- [crc-swift](https://github.com/QuickBirdEng/crc-swift)
- [swift-async-algorithms](https://github.com/apple/swift-async-algorithms)
