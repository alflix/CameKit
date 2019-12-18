//
//  CKError.swift
//  CameKit
//
//  Created by John on 10/01/2019.
//  Copyright © 2019 CameKit. All rights reserved.
//

import Foundation

public enum CustomError: Error {
    case captureDeviceNotFound
    case error(String)
}
