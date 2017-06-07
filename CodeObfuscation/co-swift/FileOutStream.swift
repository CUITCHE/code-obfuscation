//
//  FileOutStream.swift
//  CodeObfuscation
//
//  Created by hejunqiu on 2017/6/7.
//  Copyright © 2017年 CHE. All rights reserved.
//

import Foundation

fileprivate let COFOSFieldObfusedMD5 = "filesold"
fileprivate let COFOSFieldObfuseMD5  = "files"
fileprivate let COFOSFieldSelfMD5    = "self"

fileprivate func _md5(_ content: NSString) -> String? {
    let str = NSString(format: "%@%lu", content, content.length).md5
    return str
}

fileprivate func _md5_for_self(_ content: NSString) -> String? {
    var range = content.range(of: "[self] = ")
    if range.location == NSNotFound {
        return nil
    }
    range.location = NSMaxRange(range)
    range.length = 32
    let `self` = content.replacingCharacters(in: range, with: "") as NSString?
    return self?.md5
}

struct FileOutStream {
    fileprivate var headerFilename = ""
    fileprivate var selfLocation : String.Index?

    fileprivate let filepath : String
    fileprivate let originalFileContent : String
    fileprivate var gen: String?
    fileprivate var relateFilepaths = [String]()
    fileprivate var attributed : [String: Any]? = nil

    public var needGenerateObfuscationCode : Bool {
        get {
            return gen != nil
        }
    }

    init?(filepath: String) {
        do {
            try originalFileContent = String.init(contentsOfFile: filepath)
        } catch {
            print(error)
            return nil
        }
        self.filepath = filepath
    }
}

extension FileOutStream {
    mutating func read() {
        if attributed == nil {
            attributed = [String: Any]()
        } else {
            return
        }
        var cohFileSearchEndIndex = 0
        var scanner = Scanner.init(string: self.originalFileContent)
        if scanner.scanUpTo("[self] =", into: nil) {
            cohFileSearchEndIndex = scanner.scanLocation
            scanner.scanString("[self] =", into: nil)
            var selfMd5: NSString?
            scanner.scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines, into: &selfMd5)
            if let selfmd5 = selfMd5 as String?, let curCOHMd5 = _md5_for_self(self.originalFileContent as NSString) {
                self.attributed?[COFOSFieldSelfMD5] = curCOHMd5
                // coh文件校验
                if selfmd5 != curCOHMd5 {
                    gen = String()
                }
            } else {
                gen = String()
            }
        }

        scanner = Scanner.init(string: originalFileContent.substring(to: originalFileContent.index(originalFileContent.startIndex, offsetBy: cohFileSearchEndIndex)))
        var oldmd5 = [String: String]()
        while scanner.scanUpTo("[", into: nil) {
            scanner.scanString("[", into: nil)
            var filename : NSString?
            scanner.scanUpTo("]", into: &filename)

            scanner.scanUpTo("= ", into: nil)
            scanner.scanString("= ", into: nil)

            var md5: NSString?
            scanner.scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines, into: &md5)
            if let _filename = filename as String?, let _md5 = md5 as String? {
                if _filename != "self" {
                    oldmd5[_filename] = _md5
                }
            }
        }
        self.attributed?[COFOSFieldObfusedMD5] = oldmd5
    }

    mutating public func worthParsingFile(_ filecontent: String, filename: String) -> Bool {
        let newmd5 = _md5(filecontent as NSString)
        var newmd5s = self.attributed?[COFOSFieldObfuseMD5] as! Dictionary<String, Any>?
        if newmd5s == nil {
            newmd5s = [String: Any]()
            self.attributed?[COFOSFieldObfuseMD5] = newmd5s
        }
        newmd5s![filename] = newmd5
        // TODO: 由于当前设计缺陷，暂且决策每次都需要重新生成混淆数据
        if gen == nil {
            gen = String()
        }
        return true
    }

    mutating public func begin() {
        guard self.needGenerateObfuscationCode else {
            return
        }
        var enterRange = originalFileContent.range(of: "\n")
        for _ in 0..<6 {
            if enterRange?.isEmpty == false {
                enterRange = originalFileContent.range(of: "\n",
                                                       options: NSString.CompareOptions.init(rawValue: 0),
                                                       range: enterRange!.lowerBound..<originalFileContent.endIndex,
                                                       locale: nil)
            }
        }
        if enterRange?.isEmpty == false {
            gen?.append(originalFileContent.substring(with: originalFileContent.startIndex..<enterRange!.lowerBound))
        }
        gen?.append("\n//  DO NOT TRY TO MODIFY THIS FILE!\n");

        for (key, obj) in self.attributed?[COFOSFieldSelfMD5] as! Dictionary<String, String> {
            gen?.append(String.init(format: "//  [%@] = %@\n", key, obj))
        }
        gen?.append("//  [self] = ")
        selfLocation = gen?.endIndex
        headerFilename = (filepath as NSString).lastPathComponent.replacingOccurrences(of: ".coh", with: "_coh")

        // 写头文件header 宏
        gen?.append(String.init(format: "#ifndef %@\n" +
                                        "#define %@\n\n", headerFilename, headerFilename))

        // 生成COF的必用宏
        writeMacroHelper("CO_CONFUSION_CLASS");
        writeMacroHelper("CO_CONFUSION_CATEGORY");
        writeMacroHelper("CO_CONFUSION_PROPERTY");
        writeMacroHelper("CO_CONFUSION_METHOD");

        if Arguments.arguments.onlyDebug == false {
            gen?.append("#if !defined(DEBUG)\n")
        }
    }

    mutating public func writeObfuscation(code: [String: String]) {
        for (key, obj) in code {
            writeFakeText(obj, realText: key)
        }
    }

    mutating public func end() {
        if Arguments.arguments.onlyDebug == false {
            gen?.append("#endif\n\n")
        }
        gen?.append(String.init(format: "#endif /* %@ */", headerFilename))

        if let md5 = _md5(gen! as NSString) {
            gen?.insert(contentsOf: String.init(format: "%@\n\n", md5).characters, at: selfLocation!)
        }

        do {
            try gen?.write(toFile: filepath, atomically: true, encoding: .utf8)
        } catch {
            print(error)
        }
    }

    mutating private func writeFakeText(_ fake: String, realText real: String) {
        gen?.append(String.init(format: "#ifndef %@\n" +
                                        "#define %@ %@\n" +
                                        "#endif\n\n", real, real, fake))
    }

    mutating private func writeMacroHelper(_ macro: String) {
        gen?.append(String.init(format: "#ifndef %@\n" +
                                        "#define %@\n" +
                                        "#endif\n\n", macro, macro))
    }
}
