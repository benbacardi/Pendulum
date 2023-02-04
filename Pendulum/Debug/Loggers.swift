//
//  Loggers.swift
//  Pendulum
//
//  Created by Ben Cardy on 04/11/2022.
//

import Foundation
import os.log

private var subsystem = Bundle.main.bundleIdentifier!

let appLog = OSLog(subsystem: subsystem, category: "App")
let appLogger = Logger(appLog)
let dataLog = OSLog(subsystem: subsystem, category: "Data")
let dataLogger = Logger(dataLog)
let sqlLog = OSLog(subsystem: subsystem, category: "SQL")
let sqlLogger = Logger(sqlLog)
let cloudKitLog = OSLog(subsystem: subsystem, category: "CloudKit")
let cloudKitLogger = Logger(cloudKitLog)
let storeLog = OSLog(subsystem: subsystem, category: "Store")
let storeLogger = Logger(storeLog)
