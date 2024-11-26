require 'io/console'

input_prompts_filename = "prompts.txt"
input_prompts_filename = '/Users/davidcruwys/dev/ai-prompts/midjourney/documentation/clean-prompts/input.txt'
output_prompts_filename = '/Users/davidcruwys/dev/ai-prompts/midjourney/documentation/clean-prompts/processed.txt'

count = 1

File.readlines(input_prompts_filename).each do |line|
  raw_prompt = line.strip

  prompt = "/imagine prompt: #{raw_prompt}"

  display_prompt = "#{count} :: #{prompt}"
  puts display_prompt

  IO.popen('pbcopy', 'w') { |f| f << prompt }
  File.open(output_prompts_filename, 'a') { |f| f.puts raw_prompt }

  count += 1

  lines = File.readlines(input_prompts_filename)
  lines.delete_at(0)
  File.open(input_prompts_filename, 'w') { |f| f.write(lines.join) }


  if count % 8 == 0
    puts "Press any key to continue..."
    STDIN.getch
    puts "\n"
  else
    sleep(5)
  end
end
  