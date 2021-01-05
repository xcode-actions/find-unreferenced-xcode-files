/*
 * main.swift
 * find-unreferenced-xcode-files
 *
 * Created by François Lamboley on 30/05/2018.
 * Copyright © 2018 Frizlab. All rights reserved.
 */

import Foundation

import ArgumentParser
import CoreData
import StreamReader
import SystemPackage
import XcodeProjKit



struct FindUnreferencedXcodeFiles : ParsableCommand {
	
	static var configuration = CommandConfiguration(
		abstract: "Reads filenames from stdin and checks that each filename is used in the given xcodeproj."
	)
	
	@Flag(name: .customShort("0"), help: "Expect the filenames to be separated by a NULL-char.")
	var zero: Bool = false
	
	@Argument
	var xcodeprojPath: String
	
	func run() throws {
		/* First we read the Xcode project */
		let xcodeprojURL = URL(fileURLWithPath: xcodeprojPath)
		let xcodeproj = try XcodeProj(xcodeprojURL: xcodeprojURL)
		
		var standardBuildSettings = BuildSettings.standardDefaultSettings(xcodprojURL: xcodeprojURL).flattened
		for name in ["SDKROOT", "BUILT_PRODUCTS_DIR"] {
			standardBuildSettings[name] = standardBuildSettings[name] ?? "/tmp/DUMMY_" + name
		}
		
		let fileURLs = try xcodeproj.managedObjectContext.performAndWait{ () -> Set<URL> in
			let fetchRequest: NSFetchRequest<PBXFileElement> = NSFetchRequest(entityName: "PBXFileElement")
			return try Set(xcodeproj.managedObjectContext.fetch(fetchRequest).compactMap{
//				if $0.parent == nil && ($0 as? PBXGroup)?.projectForMainGroup == nil {
//					return nil
//				}
				return try $0.resolvedPathAsURL(xcodeprojURL: xcodeprojURL, variables: standardBuildSettings).absoluteURL
			})
		}
//		let fm = FileManager.default
//		for u in fileURLs {
//			let path = u.path
//			if !fm.fileExists(atPath: path) {
//				print("warning: file referenced in project does not seem to exist: \(path)")
//			}
//		}
		
		/* Funnily enough, using a FileHandle stream reader will block when using a
		 * Terminal and sending the paths manually until ctrl-D has been sent, but w/
		 * a FileDescriptor stream reader we have no issue. Of course when sending
		 * through a pipe or other, both solutions work. */
		let fileDescriptor = FileDescriptor(rawValue: FileHandle.standardInput.fileDescriptor /* FileDescriptor.standardInput does not exist in 0.0.1 */)
		let streamReader = FileDescriptorReader(stream: fileDescriptor, bufferSize: 1024, bufferSizeIncrement: 512, readSizeLimit: nil)
		while try !streamReader.hasReachedEOF() {
			let e = try streamReader.readData(upTo: [zero ? Data([0]) : Data("\n".utf8)], matchingMode: .anyMatchWins, failIfNotFound: true, includeDelimiter: false)
			_ = try streamReader.readData(size: e.delimiter.count) /* Read the delimiter */
			guard !e.data.isEmpty else {continue}
			guard let p = String(data: e.data, encoding: .utf8) else {continue}
			if !fileURLs.contains(URL(fileURLWithPath: p).absoluteURL) {print(p)}
		}
	}
	
}

FindUnreferencedXcodeFiles.main()
