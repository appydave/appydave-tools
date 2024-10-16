# GPT Context Usage Guide

This guide provides a comprehensive reference for using the `gpt_context` tool. Below you'll find examples of different use cases and command line invocations to help you effectively use `gpt_context` for gathering and organizing your project files. These examples will help you remember how to leverage various options available in `gpt_context`.

## Overview

`gpt_context` is a command line utility designed to collect, filter, and organize context from different files within a project. It allows for gathering files based on include and exclude patterns, visualizing the project structure, and exporting collected information in multiple formats, such as content, tree, or JSON.

### Common Options
- **`-i` or `--include`**: Specify patterns or files to include (multiple entries allowed).
- **`-e` or `--exclude`**: Specify patterns or files to exclude (multiple entries allowed).
- **`-f` or `--format`**: Define output format (`content`, `tree`, or `json`). If not provided, then `tree` followed by `content` is used by defaultboth are used by default.
- **`-d` or `--debug`**: Enable debug mode (e.g., `info`, `params`, `debug`). The default is `info` and this is how output to console is invoked. (Yes I know, it should be part of the --output option as well)
- **`-o` or `--output`**: Set the output target (`clipboard` or a file path). The default is `clipboard`, I know this is potentially desctructive.
- **`-l` or `--line-limit`**: Limit the number of lines included from each file.
- **`-b` or `--base-dir`**: Set the base directory to gather files from. Current working directory is used if not supplied

## Usage Examples

### 1. Gathering File Contents
To gather the content of specific files and print it to the console, you can use the `-f content` format option:

```sh
$ gpt_context -i "**/gpt_context.rb" -i "**/gpt_context/*.rb" -d -f content
```
**Explanation**: This command collects the content of all Ruby files matching the specified patterns (`gpt_context.rb` and files in the `gpt_context` directory). It includes debug output (`-d`) to log the content to the console during execution. The is stored in the clipboard in content format.

### 2. Displaying Directory Structure as a Tree
To visualize the structure of the included files as a tree, use the `-f tree` option:

```sh
$ gpt_context -i "**/gpt_context.rb" -i "**/gpt_context/*.rb" -d -f tree
```
**Explanation**: This command collects files based on the patterns and using the `-d` prints them in a tree-like structure. The tree is also loaded into the clipboard by default. This is useful for understanding the overall organization of files within the project. 

### 3. Exporting File Data as JSON
You can export the gathered file data as JSON by using the `-f json` format option, along with specifying an output file:

```sh
$ gpt_context -i "**/gpt_context.rb" -i "**/gpt_context/*.rb" -f json -o somefile.json
```
**Explanation**: This command collects files and outputs the gathered data in JSON format. The result is saved to `somefile.json` (`-o somefile.json`). There is no `-d` so there will be no console output, also the `-o` will replace the default which is `clipboard` and so the only output in this case is the file which will go into the working directory. This is helpful when you need a structured representation of your project files, such as for further processing or analysis.

### 4. Combining Multiple Formats
You can generate multiple formats at once by specifying them in a comma-separated list:

```sh
$ gpt_context -i "**/gpt_context.rb" -i "**/gpt_context/*.rb" -f tree,content
```
**Explanation**: This command gathers the files and produces both a tree view and concatenated content output. The combined output can help visualize both the structure and content of your project files. This would be the default if you did not use `-f`, but interestling you can reverse them `-f content,tree` if you want the tree at the bottom of the concatenated output.

### 5. Limiting the Number of Lines Collected
To limit the number of lines collected from each file, use the `-l` option:

```sh
$ gpt_context -i "**/*.rb" -l 10
```
**Explanation**: This command gathers the first 10 lines from each Ruby file in the current directory and its subdirectories. This can be useful for getting an overview without including complete files.

### 6. Setting the Working Directory
You can specify a base directory to gather files from by using the `-b` option:

```sh
$ gpt_context -b "lib/" -i "**/*.rb" -f tree
```
**Explanation**: This command sets the base directory to `lib/` and gathers all Ruby files within it, displaying the output in a tree format. This helps scope your collection to a specific part of your project.

## Debugging Tips
- **Debugging Mode**: The `-d` option can be followed by levels like `info`, `params`, or `debug` to control the verbosity of debug output.
  - `params`: Prints out the parameters being used.
  - `debug`: Provides detailed output, which can be helpful for troubleshooting issues.

Example:
```sh
$ gpt_context -i "**/*.rb" -d debug -f content
```
This will provide detailed debug output while collecting file contents.

## Output Targets
- **Clipboard**: By default, if no output target is specified, the content is copied to the clipboard.
- **File Output**: Use the `-o` option with a file path to save the output to a file.

Example:
```sh
$ gpt_context -i "**/*.rb" -o output.txt
```
This saves the gathered content to `output.txt`.

## Summary
The `gpt_context` tool is versatile for gathering, visualizing, and exporting project context in various formats. Whether you need a structured view of your files, a quick JSON export, or just the content concatenated, these examples should help you remember how to leverage the tool's full capabilities effectively.

Feel free to expand this guide with more examples as you explore new ways to use `gpt_context`!

## References

- [ChatGPT Documentation](https://chatgpt.com/c/670f2150-08b4-8002-b2d7-04aff6fe304f)