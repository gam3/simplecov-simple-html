require 'cgi'
require 'fileutils'
require 'digest/sha1'
require 'time'
require 'simplecov'

require 'rexml/xpath'
require 'rexml/document'

require 'pp'

# Ensure we are using a compatible version of SimpleCov
if Gem::Version.new(SimpleCov::VERSION) < Gem::Version.new("0.7.1")
  raise RuntimeError, "The version of SimpleCov you are using is too old. Please update with `gem install simplecov` or `bundle update simplecov`"
end

class SimpleCov::Formatter::SimpleHTMLFormatter
  include REXML
  def fixup_path(source_doc)
      source_doc.each_element('//link') do |e|
        e.add_attribute('href', e.attribute('href').to_s.sub('VERSION', SimpleCov::Formatter::SimpleHTMLFormatter::VERSION))
      end
      source_doc.each_element('//script') do |e|
        e.add_attribute('src', e.attribute('src').to_s.sub('VERSION', SimpleCov::Formatter::SimpleHTMLFormatter::VERSION))
      end
  end
  def format(result)
    Dir[File.join(File.dirname(__FILE__), '../public/*')].each do |path|
      FileUtils.cp_r(path, asset_output_path)
    end
    File.open(File.join(File.dirname(__FILE__), '../views/source.html.in'), "r") do |ifile|
      source_doc = REXML::Document.new ifile
      fixup_path(source_doc)
      result.source_files.each do |source_file|
        doc = source_doc.deep_clone
	doc.each_recursive do |e|
#puts "Class #{e.attribute('class').to_s}" if e.attribute('class')
	  case e.attribute('class').to_s
	  when 'filename'
	    e.text = shortened_filename source_file.filename
	  when 'covered_percent'
	    e.text = source_file.covered_percent.round(2).to_s
	  when 'lines_of_code'
	    e.text = source_file.lines_of_code
	  when 'covered_lines'
	    e.text = source_file.covered_lines.size
	  when 'missed_lines'
	    e.text = source_file.missed_lines.size
	  end
	end
	ol = doc.get_elements('//div/pre/ol')[0]
	li = doc.get_elements('//div/pre/ol/li')[0]
	ol.delete_element(li)
	source_file.lines.each_with_index do |line|
	  nli = li.deep_clone
	  nli.add_attribute("class", line.status)
	  nli.add_attribute("data-linenumber", line.number)
	  nli.add_attribute("data-hits", line.coverage ? line.coverage : '')
	  nli.get_elements('code')[0].text = CGI.escapeHTML(line.src.chomp)
	  if line.covered?
	    nli.get_elements('span')[0].text = line.coverage
	  elsif line.skipped?
	    nli.get_elements('span')[0].text = line.coverage
	  else
	    nli.delete_element(nli.get_elements('span')[0])
	  end
	  ol << nli
	end
        filename = File.join(output_path, shortened_filename(source_file.filename).gsub('/', '_') + '.html')
#	FileUtils.mkdir_p(File.dirname(filename))
        File.open(filename, 'w') do |ofile|
	  ofile.puts doc.to_s
	end
      end
    end
    File.open(File.join(File.dirname(__FILE__), '../views/index.html.in'), "r") do |ifile|
      doc = REXML::Document.new ifile
      fixup_path(doc)
      body = doc.root.elements['body/div']
      body.each_element do |e|
	if e.attribute('class')
	  case e.attribute('class').to_s
	  when 'timestamp'
	    e.each_element do |e|
	      case e.name.to_s
	      when 'abbr'
		time = Time.now
		e.add_attribute('title', time.iso8601)
		e.text = time.iso8601
	      end
	    end
	  when 'group_tabs'
	    e.each_element do |li|
	      e.delete_element li
	    end
	  else
puts "warning Class #{ e.attribute('class').to_s}"
	  end
	end
	if e.attribute('id')
	  case e.attribute('id').to_s
	  when 'content'
            file_list_container = e.get_elements("//div[@class='file_list_container']")[0]
            file_list_container.add_attribute('id', 'AllFiles')
#	    x = file_list_container.deep_clone
	    x = file_list_container
	    x.each_element do |e|
	      case e.name
	      when 'h2'
	        e.each_recursive do |e|
		  case e.attribute('class').to_s
		  when 'group_name'
		    e.text = 'All Files'
		  end
		end
	      when 'table'
		tbody = e.get_elements('//tbody')[0]
		e.each_element('//tbody/tr') do |tr|
		  tbody.delete_element tr
		  result.source_files.each do |source_file|
		    ntr = tr.deep_clone
		    x = ntr.get_elements('//td')
                    filename = x[0].get_elements('a')[0]
		    filename.text = shortened_filename source_file.filename
		    filename.add_attribute('href', shortened_filename(source_file.filename).gsub('/', '_') + '.html')
		    x[1].add_attribute('class', coverage_css_class(source_file.covered_percent))
		    x[1].text = source_file.covered_percent.round(2)
		    x[2].text = source_file.lines.count
		    x[3].text = source_file.covered_lines.size + source_file.missed_lines.count
		    x[5].text = source_file.covered_lines.size
		    x[4].text = source_file.missed_lines.size
		    x[6].text = source_file.covered_strength
		    tbody << ntr
		  end
		end
	      else
#puts e
	      end
	    end
	  when 'footer'
	    e.each_element do |e|
	      case e.attribute('id').to_s
	      when 'simplecov_version'
		e.text = SimpleCov::VERSION
	      when 'result.command_name'
	        e.text = result.command_name
	      else 
#puts e
	      end
	    end
	  else
puts "Id #{ e.attribute('id').to_s }"
	  end
	end
      end
      File.open(File.join(output_path, "index.html"), "w+") do |ofile|
	ofile.puts doc.to_s
      end
    end
    puts output_message(result)
  end

  def output_message(result)
    "Coverage report generated for #{result.command_name} to #{output_path}. #{result.covered_lines} / #{result.total_lines} LOC (#{result.covered_percent.round(2)}%) covered."
  end

  def xxx(y)
    a = 1
    puts y
  end

  private

  # Returns the an erb instance for the template of given name
  def template(name)
    puts "template(#{name})"
#    ERB.new(File.read(File.join(File.dirname(__FILE__), '../views/', "#{name}.erb")))
  end

  def output_path
    SimpleCov.coverage_path
  end

  def asset_output_path
    return @asset_output_path if defined? @asset_output_path and @asset_output_path
    @asset_output_path = File.join(output_path, 'assets', SimpleCov::Formatter::SimpleHTMLFormatter::VERSION)
    FileUtils.mkdir_p(@asset_output_path)
    @asset_output_path
  end

  def assets_path(name)
    File.join('./assets', SimpleCov::Formatter::SimpleHTMLFormatter::VERSION, name)
  end

  # Returns the html for the given source_file
  def formatted_source_file(source_file)
    template('source_file').result(binding)
  end

  # Returns a table containing the given source files
  def formatted_file_list(title, source_files)
    title_id = title.gsub(/^[^a-zA-Z]+/, '').gsub(/[^a-zA-Z0-9\-\_]/, '')
    title_id # Ruby will give a warning when we do not use this except via the binding :( FIXME
    template('file_list').result(binding)
  end

  def coverage_css_class(covered_percent)
    if covered_percent > 90
      'green'
    elsif covered_percent > 80
      'yellow'
    else
      'red'
    end
  end

  def strength_css_class(covered_strength)
    if covered_strength > 1
      'green'
    elsif covered_strength == 1
      'yellow'
    else
      'red'
    end
  end

  # Return a (kind of) unique id for the source file given. Uses SHA1 on path for the id
  def id(source_file)
    Digest::SHA1.hexdigest(source_file.filename)
  end

  def timeago(time)
    "<abbr class=\"timeago\" title=\"#{time.iso8601}\">#{time.iso8601}</abbr>"
  end

  def shortened_filename(source_file_name)
    source_file_name.gsub(SimpleCov.root, '.').gsub(/^\.\//, '')
  end

  def link_to_source_file(source_file)
    %Q(<a href="##{id source_file}" class="src_link" title="#{shortened_filename source_file}">#{shortened_filename source_file}</a>)
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
require 'simplecov-simple-html/version'
