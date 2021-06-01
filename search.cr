#          Copyright Blaze 2021.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

require "option_parser"

CHANNEL = Channel(Hash(String, Int32)).new
hashes = Hash(String, Int32).new
match : String = "*"
total : Int32 = 0

def search(files : Array(String))
  files.each do |f|
    spawn do
      unless File.directory?(f)
        lines = File.read_lines(f)
        CHANNEL.send Hash{f => lines.size}
      else
        search(Dir.glob("#{f}/*"))
      end
    end
  end
end

parser = OptionParser.parse do |parser|
    parser.banner = "Usage: #{PROGRAM_NAME} [...args]"

    # help switch
    parser.on("-h", "--help", "Gives information on usage") do
      puts parser
      exit
    end

    parser.on("-r <regex>", "--regex=<regex>", "Regex used to match files in the directory") { |r|
      match = r
    }

    parser.invalid_option do |flag|
      puts "ERROR: #{flag} is not a valid option."
      puts parser
      exit(1)
    end
end


parser.parse
# now find files that match the regex
files = Dir.glob(match)

search(files)

files.size.times do
  hashes = hashes.merge(CHANNEL.receive)
end

hashes.keys.sort.each do |key|
  total += hashes[key]
  puts "#{key}: #{hashes[key]} lines"
end

puts "\n#{total} lines for the match '#{match}'"
