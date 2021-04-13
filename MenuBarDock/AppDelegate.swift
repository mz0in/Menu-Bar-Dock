//
//  AppDelegate.swift
//  MenuBarDock
//
//  Created by Ethan Sarif-Kattan on 02/03/2019.
//  Copyright © 2019 Ethan Sarif-Kattan. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

	let popover = NSPopover()
	var preferencesWindow = NSWindow()
	var userPrefs =  UserPrefs()
	var menuBarItems: MenuBarItems! // need reference so it stays alive
	var openableApps: OpenableApps!
	var runningApps: RunningApps!
	var regularApps: RegularApps!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		initApp()
		setupLaunchAtLogin()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		userPrefs.save()
	}

	func initApp() {
		userPrefs.load()
		menuBarItems = MenuBarItems(
 			userPrefsDataSource: userPrefs
		)
		menuBarItems.delegate = self

		runningApps = RunningApps(userPrefsDataSource: userPrefs)
		regularApps = RegularApps()

		openableApps = OpenableApps(userPrefsDataSource: userPrefs, runningApps: runningApps, regularApps: regularApps)
		openableApps.delegate = self

		updateMenuBarItems()
	}

	func setupLaunchAtLogin() {
		let launcherAppId = Constants.App.launcherBundleId
		let runningApps = NSWorkspace.shared.runningApplications

		SMLoginItemSetEnabled(launcherAppId as CFString, false) // needs to be set to false to actually create the loginitems.501.plist file, then we can set it to the legit value...weird
		SMLoginItemSetEnabled(launcherAppId as CFString, userPrefs.launchAtLogin)

		let isLauncherRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
		if isLauncherRunning {
			DistributedNotificationCenter.default().post(name: Notification.Name("killLauncher"), object: Bundle.main.bundleIdentifier!)
		}
	}

	private func updateMenuBarItems() {
		menuBarItems.update(openableApps: openableApps)
	}
}

extension AppDelegate: MenuBarItemsDelegate {
	func didSetAppOpeningMethod(_ method: AppOpeningMethod, _ app: OpenableApp) {
		userPrefs.appOpeningMethods[app.id] = method
		userPrefs.save()
	}

	func didOpenPreferencesWindow() {
		openPreferencesWindow()
	}

	func openPreferencesWindow() {
		if let viewController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: Constants.ViewControllerIdentifiers.preferences) as? PreferencesViewController {
			viewController.userPrefs = userPrefs
			if !preferencesWindow.isVisible {
				preferencesWindow = NSWindow(contentViewController: viewController)
				preferencesWindow.makeKeyAndOrderFront(self)
			}
			let controller = NSWindowController(window: preferencesWindow)
			controller.showWindow(self)
			NSApp.activate(ignoringOtherApps: true)// stops bugz n shiz i think
		}
	}
}

extension AppDelegate: OpenableAppsDelegate {
	func appsDidChange() {
		updateMenuBarItems()
	}
}
