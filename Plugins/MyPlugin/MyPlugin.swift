import Foundation
import PackagePlugin

@main
struct MyPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        try [
            .prebuildCommand(
                displayName: "Protect app data",
                executable: context.tool(named: "mycommand").path,
                arguments: [
                    "--input-dir",
                    target.directory.appending("Files"),
                    "--output-dir",
                    context.pluginWorkDirectory.appending("Out"),
                ],
                outputFilesDirectory: context.pluginWorkDirectory.appending("Out")
            ),
        ]
    }
}
