/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

import SwiftKeychainWrapper
import LocalAuthentication

// This file contains all of the settings available in the main settings screen of the app.

private var ShowDebugSettings: Bool = false
private var DebugSettingsClickCount: Int = 0

// For great debugging!
class HiddenSetting: Setting {
    let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }
}


class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileManager = NSFileManager.defaultManager()
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(documentsPath)
            for file in files {
                if file.startsWith("browser.") || file.startsWith("logins.") {
                    try fileManager.removeItemInDirectory(documentsPath, named: file)
                }
            }
        } catch {
            print("Couldn't delete exported data: \(error).")
        }
    }
}

class ExportBrowserDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        do {
            let log = Logger.syncLogger
            try self.settings.profile.files.copyMatching(fromRelativeDirectory: "", toAbsoluteDirectory: documentsPath) { file in
                log.debug("Matcher: \(file)")
                return file.startsWith("browser.") || file.startsWith("logins.")
            }
        } catch {
            print("Couldn't export browser data: \(error).")
        }
    }
}

// Opens the the license page in a new tab
class LicenseAndAcknowledgementsSetting: Setting {
    override var url: NSURL? {
        return NSURL(string: WebServer.sharedInstance.URLForResource("license", module: "about"))
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
    let profile: Profile

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: Strings.ShowTour, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        navigationController?.dismissViewControllerAnimated(true, completion: {
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                appDelegate.browserViewController.presentIntroViewController(true)
            }
        })
    }
}

// Opens the search settings pane
class SearchSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var style: UITableViewCellStyle { return .Value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine.shortName) }

    override var accessibilityIdentifier: String? { return "Search" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: Strings.DefaultSearchEngine, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController()
        viewController.model = profile.searchEngines
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class LoginsSetting: Setting {
    let profile: Profile
    ///var tabManager: TabManager!
    weak var navigationController: UINavigationController?

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var accessibilityIdentifier: String? { return "Logins" }

    init(settings: SettingsTableViewController, delegate: SettingsDelegate?) {
        self.profile = settings.profile
        ///self.tabManager = settings.tabManager
        self.navigationController = settings.navigationController

        let loginsTitle = Strings.Logins
        super.init(title: NSAttributedString(string: loginsTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]),
                   delegate: delegate)
    }

    private func navigateToLoginsList() {
        let viewController = LoginListViewController(profile: profile)
        viewController.settingsDelegate = delegate
        navigationController?.pushViewController(viewController, animated: true)
    }
}


class ClearPrivateDataSetting: Setting {
    let profile: Profile
    //var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        //self.tabManager = settings.tabManager

        let clearTitle = Strings.ClearPrivateData
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        //viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class PrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: Strings.Privacy_Policy, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: "https://www.brave.com/ios_privacy.html")
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

