//
//  ObfuscationDatabase.swift
//  obfuse-code
//
//  Created by hejunqiu on 2017/8/28.
//  Copyright © 2017年 hejunqiu. All rights reserved.
//

import Foundation

public protocol AbstractDatabaseCreation {
    var creationSql: Array<String> { get }
}

open class AbstractDatabase: AbstractDatabaseCreation {
    public var creationSql: Array<String> { return [] }

    public let db: FMDatabase
    public let databsePath: String

    init?(filepath: String) {
        guard type(of: self) != AbstractDatabase.self else {
            return nil
        }
        let fm = FileManager.default
        if fm.fileExists(atPath: filepath) == false {
            do {
                try fm.createDirectory(atPath: (filepath as NSString).deletingLastPathComponent, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
                return nil
            }
            guard fm.createFile(atPath: filepath, contents: nil, attributes: nil) else {
                printc.println(text: "Create db file failed!", marks: .red)
                return nil
            }
        }
        databsePath = filepath
        db = FMDatabase.init(path: filepath)
        guard db.open() else {
            printc.println(text: db.lastErrorMessage(), marks: .red)
            return nil
        }
        for sql in self.creationSql {
            guard db.executeStatements(sql) else {
                printc.println(text: "Create sql failed.", marks: .red)
                return nil
            }
        }
        printc.println(text: "Create db at \(filepath)")
    }
}

class ObfuscationDatabase: AbstractDatabase {
    enum ObfuscationType {
        case `class`, category, property, method, `protocol`
    }
    let bundleIdentifier: String
    let appVersion: String

    init?(filepath: String, bundleIdentifier: String, appVersion: String) {
        self.bundleIdentifier = bundleIdentifier
        self.appVersion       = appVersion
        super.init(filepath: (((filepath as NSString).appendingPathComponent(bundleIdentifier) as NSString).appendingPathComponent(appVersion) as NSString).appendingPathComponent("\(Date()).db"))
    }
}

extension ObfuscationDatabase {
    func insert(filename: String, real: String, fake: String, type: ObfuscationType, location: String = "") {
        if self._createTable(with: filename) {
            self._insert(to: filename, with: (real, fake, location), type: "\(type)")
        }
    }

    fileprivate func _createTable(with tableName: String) -> Bool {
        let sql = "CREATE TABLE IF NOT EXISTS \(tableName)(real Text NOT NULL,fake Varchar(4096) NOT NULL,location Text NOT NULL,type Text NOT NULL);"
        guard db.executeStatements(sql) else {
            printc.println(text: db.lastErrorMessage(), marks: .yellow)
            return false
        }
        return true
    }

    @discardableResult
    fileprivate func _insert(to table: String, with obfuscation: (real: String, fake: String, location: String), type: String) -> Bool {
        let sql = "INSERT INTO \(table)(real, fake, location, type) VALUES(?,?,?,?);"
        guard db.executeUpdate(sql, withArgumentsIn: [obfuscation.real, obfuscation.fake, obfuscation.location, type]) else {
            printc.println(text: db.lastErrorMessage(), marks: .yellow)
            return false
        }
        return true
    }
}
