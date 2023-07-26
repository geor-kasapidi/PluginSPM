import ArgumentParser
import CryptoKit
import Foundation
import System

@main
struct MyCommand: ParsableCommand {
    mutating func run() throws {
        try self.recreateOutputDir()

        var code: [String] = [
            "import Foundation",
            "import CryptoKit",
        ]

        let files = try self.collectFilesToProtect()

        for file in files {
            let inName = file.lastPathComponent
            let outName = UUID().uuidString
            let key = SymmetricKey(size: .bits256)

            try self.encrypt(file: file, outName: outName, key: key)

            code.append(self.generateAccessCodeForFile(
                outName: outName,
                inName: inName,
                key: key
            ))
        }

        try self.save(generatedCode: code)
    }

    // MARK: - Properties

    @Option(completion: CompletionKind.file(), transform: URL.init(fileURLWithPath:))
    private var inputDir: URL

    @Option(completion: CompletionKind.file(), transform: URL.init(fileURLWithPath:))
    private var outputDir: URL

    // MARK: - Private functions

    private func recreateOutputDir() throws {
        try? FileManager.default.removeItem(at: self.outputDir)
        try FileManager.default.createDirectory(at: self.outputDir, withIntermediateDirectories: true)
    }

    private func collectFilesToProtect() throws -> [URL] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: self.inputDir,
            includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey]
        )

        return try urls.filter { url in
            let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey])

            return resourceValues.isHidden == false && resourceValues.isRegularFile == true
        }
    }

    private func encrypt(file: URL, outName: String, key: SymmetricKey) throws {
        let fileData = try Data(contentsOf: file)
        let cryptedBox = try ChaChaPoly.seal(fileData, using: key)
        let sealedBox = try ChaChaPoly.SealedBox(combined: cryptedBox.combined)
        try sealedBox.combined.write(to: self.outputDir.appendingPathComponent(outName), options: .atomic)
    }

    private func stringRepresentationOf(key: SymmetricKey) -> String {
        let keyBytes: [UInt8] = key.withUnsafeBytes { .init($0) }
        let keyHexs = keyBytes.map { "0x\(String($0, radix: 16, uppercase: false))" }
        return "[\(keyHexs.joined(separator: ", "))]"
    }

    private func generateAccessCodeForFile(outName: String, inName: String, key: SymmetricKey) -> String {
        """
        public func load_\(self.convertToFuncName(rawString: inName))() throws -> Data {
            let data = try Data(contentsOf: Bundle.module.url(forResource: "\(outName)", withExtension: nil)!)
            let sealedBox = try ChaChaPoly.SealedBox(combined: data)
            return try ChaChaPoly.open(sealedBox, using: .init(data: \(self.stringRepresentationOf(key: key))))
        }
        """
    }

    private func convertToFuncName(rawString: String) -> String {
        rawString
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }

    private func save(generatedCode: [String]) throws {
        try generatedCode.joined(separator: "\n\n").write(
            to: self.outputDir.appendingPathComponent("Generated.swift"),
            atomically: true,
            encoding: .utf8
        )
    }
}
