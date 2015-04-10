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

Dir.glob('*.epub').each do |epub|
  checker = EpubStylesChecker.new(epub)
  missing = checker.check
  File.open("#{epub}.missing_styles.log",'w') do |f|
    f.write(missing.join("\n"))
  end
end
