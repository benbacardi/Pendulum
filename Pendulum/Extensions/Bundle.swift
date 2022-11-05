//
//  Bundle.swift
//  Pendulum
//
//  Created by Alex Faber on 05/11/2022.
//

import Foundation

extension Bundle {

    var appName: String {
        return infoDictionary?["CFBundleName"] as! String
    }

    var bundleId: String {
        return bundleIdentifier!
    }

    var appVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as! String
    }

    var appBuildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }

}
