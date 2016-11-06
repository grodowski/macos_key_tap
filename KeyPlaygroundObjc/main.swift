//
//  main.swift
//  KeyPlaygroundObjc
//
//  Created by Jan Grodowski on 06/11/2016.
//  Copyright © 2016 Jan Grodowski. All rights reserved.
//
// capturing keys with sudo: http://stackoverflow.com/a/31898592/3526316
// posting key events: http://stackoverflow.com/a/25070476/3526316
//
// This proof of concept runs as root and captures system wide keyboard events.
// Additionally, it will print 😱 to the key event queue every second. Amazing.

import Foundation

func dispatchEvent(chars: Array<UniChar>) {
    let src = CGEventSource(stateID: CGEventSourceStateID.hidSystemState)
    guard let evt = CGEvent(keyboardEventSource: src, virtualKey: 0x52, keyDown: true) else { // 0
        print("Unable to initialize CGEvent")
        exit(1)
    }
    evt.keyboardSetUnicodeString(stringLength: 2, unicodeString: chars) // Override virtualKey
    evt.post(tap: CGEventTapLocation.cghidEventTap)
}

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    print("Key event: ", event.getIntegerValueField(.keyboardEventKeycode))
    return Unmanaged.passRetained(event)
}

func createTap() -> CFMachPort? {
    let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
    return CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: CGEventMask(eventMask),
        callback: myCGEventCallback,
        userInfo: nil
    )
}

DispatchQueue.global(qos: .background).async {
    print("Starting background listener... 🔊➡️👂") // Some day it will receive events from the remote keyboard
    let charArray = Array("😱".utf16)
    while (true) {
        dispatchEvent(chars: charArray)
        sleep(1)
    }
}

guard let eventTap = createTap() else {
    print("Failed to create event tap, do you have root access? 🔑❓")
    exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)
CFRunLoopRun()
