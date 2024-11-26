# GPT Context Usage Guide

> References: [ChatGPT Documentation](https://chatgpt.com/c/670f2150-08b4-8002-b2d7-04aff6fe304f)

This guide provides a comprehensive reference for using the `gpt_context` tool. Below you'll find examples of different use cases and command line invocations to help you effectively use `gpt_context` for gathering and organizing your project files. These examples will help you remember how to leverage various options available in `gpt_context`.

## Overview

`gpt_context` is a command line utility designed to collect, filter, and organize context from different files within a project. It allows for gathering files based on include and exclude patterns, visualizing the project structure, and exporting collected information in multiple formats, such as content, tree, or JSON.

### Common Options
- **`-i` or `--include`**: Specify patterns or files to include (multiple entries allowed).
- **`-e` or `--exclude`**: Specify patterns or files to exclude (multiple entries allowed).
- **`-f` or `--format`**: Define output format (`content`, `tree`, or `json`). If not provided, then `tree` followed by `content` is used by default.
- **`-d` or `--debug`**: Enable debug mode (e.g., `info`, `params`, `debug`). The default is `info` and this is how output to console is invoked. (Yes, I know, it should be part of the `--output` option as well).
- **`-o` or `--output`**: Set the output target (`clipboard` or a file path). The default is `clipboard` (I know this is potentially destructive).
- **`-l` or `--line-limit`**: Limit the number of lines included from each file.
- **`-b` or `--base-dir`**: Set the base directory to gather files from. Current working directory is used if not supplied.

## Usage Examples

### 1. Gathering File Contents
To gather the content of specific files and print it to the console, you can use the `-f content` format option:

```sh
$ gpt_context -i "**/gpt_context.rb" -i "**/gpt_context/*.rb" -d -f content
```
**Explanation**: This command collects the content of all Ruby files matching the specified patterns (`gpt_context.rb` and files in the `gpt_context` directory). It includes debug output (`-d`) to log the content to the console during execution. The result is stored in the clipboard in content format.

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
**Explanation**: This command collects files and outputs the gathered data in JSON format. The result is saved to `somefile.json` (`-o somefile.json`). There is no `-d` so there will be no console output; also, the `-o` will replace the default which is `clipboard` and so the only output in this case is the file which will go into the working directory. This is helpful when you need a structured representation of your project files, such as for further processing or analysis.

### 4. Combining Multiple Formats
You can generate multiple formats at once by specifying them in a comma-separated list:

```sh
$ gpt_context -i "**/gpt_context.rb" -i "**/gpt_context/*.rb" -f tree,content
```
**Explanation**: This command gathers the files and produces both a tree view and concatenated content output. The combined output can help visualize both the structure and content of your project files. This would be the default if you did not use `-f`, but interestingly, you can reverse them `-f content,tree` if you want the tree at the bottom of the concatenated output.

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

## Class-Level Usage Examples

In addition to the command line interface, the `gpt_context` tool provides classes that can be used directly in Ruby code for greater flexibility. Here are some examples of how to use the main classes involved in `gpt_context`.

### 1. Using `FileCollector`
The `FileCollector` class can be used to gather files programmatically. Below is an example of how to instantiate and use the `FileCollector` class.

```ruby
require 'appydave/tools'

# Set up options for FileCollector
options = Appydave::Tools::GptContext::Options.new(
  include_patterns: ['**/*.rb'],
  exclude_patterns: ['spec/**/*'],
  format: 'content',
  line_limit: 20,
  working_directory: Dir.pwd
)

# Create a new FileCollector instance
collector = Appydave::Tools::GptContext::FileCollector.new(options)

# Gather the file content
content = collector.build

# Output the collected content
puts content
```
**Explanation**: This script sets up `Options` with specific parameters (including which files to include/exclude and the format), and then creates a `FileCollector` instance to gather the content. The gathered content is printed to the console.

### 2. Setting Up `Options`
The `Options` class is crucial for configuring how the `FileCollector` behaves. Here’s how you can use the `Options` class:

```ruby
require 'appydave/tools'

# Create options with specific settings
options = Appydave::Tools::GptContext::Options.new(
  include_patterns: ['lib/**/*.rb'],
  exclude_patterns: ['lib/excluded/**/*.rb'],
  format: 'tree,content',
  line_limit: 10,
  debug: 'info',
  output_target: ['clipboard'],
  working_directory: 'lib'
)

# Display options
pp options
```
**Explanation**: The `Options` class provides named parameters to specify how files should be gathered. This script creates an `Options` instance, which can then be used by `FileCollector` or other components of the tool.

### 3. Using `OutputHandler`
The `OutputHandler` class is responsible for handling the output after files are gathered. Here is how to use it:

```ruby
require 'appydave/tools'

# Create options and gather content using FileCollector
options = Appydave::Tools::GptContext::Options.new(
  include_patterns: ['**/*.rb'],
  format: 'content',
  output_target: ['output.txt']
)

collector = Appydave::Tools::GptContext::FileCollector.new(options)
content = collector.build

# Handle output using OutputHandler
output_handler = Appydave::Tools::GptContext::OutputHandler.new(content, options)
output_handler.execute
```
**Explanation**: This script collects content using `FileCollector` and then uses `OutputHandler` to save the gathered content to `output.txt`. The `OutputHandler` manages different output targets, such as clipboard or files, based on the specified options.

### 4. Combining Classes for Complete Workflow
Here’s an example of combining `Options`, `FileCollector`, and `OutputHandler` to automate the entire workflow:

```ruby
require 'appydave/tools'

# Step 1: Create Options
options = Appydave::Tools::GptContext::Options.new(
  include_patterns: ['**/*.rb'],
  exclude_patterns: ['**/test/**/*.rb'],
  format: 'json',
  output_target: ['output.json'],
  debug: 'params'
)

# Step 2: Gather Files using FileCollector
collector = Appydave::Tools::GptContext::FileCollector.new(options)
content = collector.build

# Step 3: Output Results using OutputHandler
output_handler = Appydave::Tools::GptContext::OutputHandler.new(content, options)
output_handler.execute
```
**Explanation**: This complete example demonstrates how to use `Options` to configure the gathering process, `FileCollector` to collect the files, and `OutputHandler` to manage the output. This approach can be useful for programmatically automating context collection tasks in more complex workflows.

