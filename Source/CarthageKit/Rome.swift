//
//  Rome.swift
//  Carthage
//
//  Created by Bernard Gatt on 16/07/2016.
//  Copyright © 2016 Carthage. All rights reserved.
//

import Foundation
import RomeKit

struct Environment {
	
	let env = NSProcessInfo.processInfo().environment
	
	func currentDirectory() -> String? {
		return env["PWD"]
	}
	
	func downloadServer() -> String? {
		return env["ROME_DOWNLOAD"] ?? env["ROME_ENDPOINT"]
	}
}

class Rome {
	
	func getLatestByRevison(name: String, revision: String) -> Asset? {
		
		var romeAsset: Asset?
		let dispatchGroup = dispatch_group_create()
		let queue = dispatch_queue_create("", DISPATCH_QUEUE_CONCURRENT)
		
		dispatch_group_enter(dispatchGroup)
		
		RomeKit.Assets.getLatestAssetByRevision(name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!, revision: revision, queue: queue, completionHandler: { (asset, errors) in
			romeAsset = asset
			if romeAsset != nil {
				print("Found asset on Rome:", romeAsset!.id!)
			} else {
				print("Asset not found in Rome server, added to build list")
			}
			
			dispatch_group_leave(dispatchGroup)
		})
		
		dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER)
		
		return romeAsset
	}
	
	func downloadAsset(asset: Asset) -> NSURL? {
		
		let directoryURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(
			NSProcessInfo.processInfo().globallyUniqueString,
			isDirectory: true)
		
		do {
			try NSFileManager.defaultManager().createDirectoryAtURL(directoryURL, withIntermediateDirectories: true, attributes: nil)
			
			let tempAssetLocation = directoryURL.URLByAppendingPathComponent("\(asset.id!)\(asset.file_extension!)")
			
			if let serverUrl = Environment().downloadServer() {
				let downloadUrl = "\(serverUrl)\(asset.name!)/\(asset.revision!)/\(asset.id!).\(asset.file_extension!)"
				print("Downloading asset from:", downloadUrl)
				do
				{
					let data = try NSData(contentsOfURL: NSURL(string: downloadUrl)!, options: NSDataReadingOptions())
					
					try data.writeToFile(tempAssetLocation.path!, options: NSDataWritingOptions.DataWritingAtomic)
				} catch {
					print(error)
					return nil
				}
			} else {
				print("Error fetching download server URL")
				return nil
			}
			
			return tempAssetLocation
			
		} catch {
			return nil
		}
		
	}
	
}