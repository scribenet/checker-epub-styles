#!/usr/bin/env ruby

require 'nokogiri'
require 'crass'
require 'zip'

class EpubStylesChecker
  def initialize(epub)
    @epub = epub
    @htmls = []
    @csses = []
    @styles = []
    @css_selectors = []
  end

  def check
    sort_epub_entries
    get_tags
    get_selectors
    missing_styles
  end

  def sort_epub_entries
    Zip::File.open(@epub) do |zip_file|
      zip_file.each do |entry|
        add_css_file(entry) if entry.name[/.css$/]
        add_html_file(entry) if entry.name[/.x?html$/]
      end
    end
  end

  def add_html_file(entry)
    text = entry.get_input_stream.read
    doc = Nokogiri.HTML(text)
    @htmls << doc
  end

  def get_tags
    @htmls.each do |html|
      @styles += html.css("[class]").map{ |element| element['class'] }.uniq
    end
  end

  def add_css_file(entry)
    text = entry.get_input_stream.read
    css = Crass.parse(text)
    @csses << css
  end

  def get_selectors
    @csses.each do |css|
      selectors = css.select{ |x| x[:selector] }\
                     .map{ |x| x[:selector][:value].split(/,\s*/) }\
                     .flatten
      @css_selectors += selectors.map{ |x| x.gsub(/^[^\.]*\./, '') }
    end
  end

  def missing_styles
    @styles.uniq - @css_selectors.uniq
  end
end

$message = 'The following styles are classes in your HTML files but are not represented in the CSS:'
$quiet = false

def write_to_log(epub, missing)
  File.open("#{epub}.missing_styles.log",'w') do |f|
    f.write($message)
    f.write("\n")
    f.write(missing.join("\n"))
  end
end

def write_to_std(epub, missing)
  if $quiet != true
    puts "\n+-------------------------------"
    puts "|"
    puts "|  E-Pub Filename: #{epub}"
    puts "|"
    puts "|  Missing Styles Count   : #{missing.length}"
    if missing.length > 0
      puts "|  Missing Styles Listing :"
      missing.each do |css|
        puts "|  - #{css}"
      end
    end
    puts "|"
    puts "+-------------------------------\n\n"
    puts "Log file written to: #{epub}.missing_styles.log\n\n"
  end
end

Dir.glob('*.epub').each do |epub|
  checker = EpubStylesChecker.new(epub)
  missing = checker.check
  write_to_log(epub, missing)
  write_to_std(epub, missing)
end
