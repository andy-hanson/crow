# Set up

Run `npm install` in the `client` and `server` directories.

# Installing

TODO

# Debugging

To debug the VSCode extension:

* Run `code noze-vscode` to open vscode in the directory containing this readme.
* Open the debugger pane on the left. Ensure it breaks on uncaught exceptions.
* Choose the "Client + Server" configuration and run. This will open a new window.
* In the original window, run the command "Output: Focus on Output View".
* In the debugger pane to the left, toggle between the client and server processes to check for output from each.

## Running the Sample

- Run `npm install` in this folder. This installs all necessary npm modules in both the client and server folder
- Open VS Code on this folder.
- Press Ctrl+Shift+B to compile the client and server.
- Switch to the Debug viewlet.
- Select `Launch Client` from the drop down.
- Run the launch config.
- If you want to debug the server as well use the launch configuration `Attach to Server`
- In the [Extension Development Host] instance of VSCode, open a document in 'plain text' language mode.
	- Type `j` or `t` to see `Javascript` and `TypeScript` completion.
	- Enter text content such as `AAA aaa BBB`. The extension will emit diagnostics for all words in all-uppercase.
