# encodeing: utf-8
require 'rexml/xpath'
require 'rexml/document'
require 'fileutils'

require 'simplecov-simple-html/version'

# Ensure we are using a compatible version of SimpleCov
if Gem::Version.new(SimpleCov::VERSION) < Gem::Version.new("0.7.1")
  raise RuntimeError, "The version of SimpleCov you are using is too old. Please update with `gem install simplecov` or `bundle update simplecov`"
end

# A simple HTML formater for SimpleCov
# There a coverage file created for each ruby file tested
class SimpleCov::Formatter::SimpleHTMLFormatter
  include REXML
  # fixup the path
  # @param [REXML::Document] source_doc 
  # @return [void]
  def fixup_path(source_doc)
    source_doc.each_element('//link') do |e|
      e.add_attribute('href', e.attribute('href').to_s.sub('VERSION', SimpleCov::Formatter::SimpleHTMLFormatter::VERSION))
    end
    source_doc.each_element('//script') do |e|
      e.add_attribute('src', e.attribute('src').to_s.sub('VERSION', SimpleCov::Formatter::SimpleHTMLFormatter::VERSION))
    end
    nil
  end
  # Format the coverage results
  # @param [SimpleCov::Result] result The SimpleCov::Result
  # @return [void]
  # @note Creates a directory and serveral files
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
          case e.attribute('class').to_s
          when 'filename'
            e.text = shortened_filename source_file.filename
          when 'covered_percent'
            e.text = source_file.covered_percent.round(2).to_s
            e.parent.attributes['style'] = "color: #{ coverage_css_class(source_file.covered_percent) };"
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

          nli.get_elements('code')[0].text = line.src
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
        FileUtils.mkdir_p(File.dirname(filename))
        File.open(filename, 'w') do |ofile|
          ofile.puts doc.to_s
        end
      end
    end
    groups = [ "All Files" ] +  result.groups.each_key.to_a
    a = Array.new
    a = a.push [ "All Files", result.source_files ]
    a += result.groups.to_a
    groups_hash = Hash[ a ]

    File.open(File.join(File.dirname(__FILE__), '../views/index.html.in'), "r") do |ifile|
      data = ifile.read
      groups.each_with_index do |name, i|
        doc = REXML::Document.new data
        source_files = groups_hash[name]
        fixup_path(doc)
        doc.xpath
        body = doc.root.elements['body/div']
        XPath.each(body, '//*[@class="source_files_covered_percent"]') do |element|  
          element.text = source_files.covered_percent.round(2)
          element.parent.attributes['class'] = coverage_css_class(source_files.covered_percent)
        end
        XPath.each(body, '//*/span[@class="covered_strength_value"]') do |x|  
          x.text = source_files.covered_strength.round(2)
          x.parent.attributes['class'] =  strength_css_class(source_files.covered_strength)
        end
        XPath.each(body, '//*/span[@class="files_total"]') do |x|  
	  x.text = source_files.size
	end
        XPath.each(body, '//*/span[@class="file_lines"]') do |x|  
	  x.text = source_files.lines_of_code
	end
        XPath.each(body, '//*/span[@class="covered_lines"]') do |x|  
	  x.text = source_files.covered_lines
	end
        XPath.each(body, '//*/span[@class="missed_lines"]') do |x|  
	  x.text = source_files.missed_lines
	end
        XPath.each(body, '//*/ul[@class="group_tabs"]').each do |x|  
#p x.to_s
	end
        body.each_element do |body_element|
          if body_element.attribute('class')
            case body_element.attribute('class').to_s
            when 'timestamp'
              body_element.each_element do |e2|
                case e2.name.to_s
                when 'abbr'
                  time = Time.now
                  e2.add_attribute('title', time.iso8601)
                  e2.text = time.iso8601
                end
              end
            when 'group_tabs'
	      fli = nil
              body_element.to_a.each do |li|
                case li
		when REXML::Element
	          fli = li.dup unless fli
                  body_element.delete_element li
		when REXML::Text
                  body_element.delete li
		else
                  raise 'unknown'
		end
              end
	      groups.each_with_index do |g, gi|
		g_source_files = groups_hash[g]
		nli = fli.deep_clone
		if g == name
		  nli.attributes['class'] = 'active'
		end
		nli.each_element('a/span[@class="tab_group_name"]') do |x|
		  x.text = g
		end
		nli.each_element('a/span[@class="color"]') do |x|
		  x.attributes['class'] = coverage_css_class(g_source_files.covered_percent)
		end
		nli.each_element('a/span/span[@class="tab_coverage"]') do |x|
		  x.text = g_source_files.covered_percent.round(2)
		end
		nli.each_element('a') do |x|
		  if gi > 0
		    x.attributes['href'] = 'index%d.html' % gi
		  else
		    x.attributes['href'] = 'index.html'
		  end
		end
		body_element.add_element nli
	      end
            end
          end
          if body_element.attribute('id')
            case body_element.attribute('id').to_s
            when 'content'
              file_list_container = body_element.get_elements("//div[@class='file_list_container']")[0]
              file_list_container.add_attribute('id', 'AllFiles')
  #           x = file_list_container.deep_clone
              x = file_list_container
              x.each_element do |e1|
                case e1.name
                when 'h2'
                  e1.each_recursive do |e2|
                    case e2.attribute('class').to_s
                    when 'group_name'
                      e2.text = name
                    end
                  end
                when 'table'
                  tbody = e1.get_elements('//tbody')[0]
                  body_element.each_element('//tbody/tr') do |tr|
                    tbody.delete_element tr
                    source_files.each do |source_file|
                      ntr = tr.deep_clone
                      x = ntr.get_elements('//td')
                      filename = x[0].get_elements('a')[0]
                      filename.text = shortened_filename source_file.filename
                      filename.add_attribute('href', shortened_filename(source_file.filename).gsub('/', '_') + '.html')
                      x[1].add_attribute('class', coverage_css_class(source_file.covered_percent))
                      x[1].text = source_file.covered_percent.round(2)
                      x[2].text = source_file.lines.count
                      x[3].text = source_file.covered_lines.size + source_file.missed_lines.count
                      x[4].text = source_file.covered_lines.size
                      x[5].text = source_file.missed_lines.size
                      x[6].text = source_file.covered_strength
                      tbody << ntr
                    end
                  end
                else
  #puts e
                end
              end
            when 'footer'
              body_element.each_element do |e|
                case body_element.attribute('id').to_s
                when 'simplecov_version'
                  body_element.text = SimpleCov::VERSION
                when 'result.command_name'
                  body_element.text = result.command_name
                else 
  #puts body_element
                end
              end
            else
  puts "Id #{ body_element.attribute('id').to_s }"
            end
          end
        end
        if i == 0
          ofilename = 'index.html'
        else
          ofilename = "index#{i}.html"
        end
        File.open(File.join(output_path, ofilename), "w+") do |ofile|
          ofile.puts doc.to_s
        end
      end
    end
    puts output_message(result)
    nil
  end

  # Generate the coverage report text
  # @param [SimpleCov::Result] result The SimpleCov::Result
  # @return [String] the coverage report
  def output_message(result)
    "Coverage report generated for #{result.command_name} to #{output_path}. #{result.covered_lines} / #{result.total_lines} LOC (#{result.covered_percent.round(2)}%) covered."
  end

private

  # Returns the an erb instance for the template of given name
  # @deprecated
  def template(name)
    raise "template(#{name})"
  end

  # @return [String] the path where the coverage report will be generated
  def output_path
    SimpleCov.coverage_path
  end

  # @return [String] the path where the assests are stored
  def asset_output_path
    return @asset_output_path if defined? @asset_output_path and @asset_output_path
    @asset_output_path = File.join(output_path, 'assets', SimpleCov::Formatter::SimpleHTMLFormatter::VERSION)
    FileUtils.mkdir_p(@asset_output_path)
    @asset_output_path
  end

  # @return [String] the path to a particular asset
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
  # @return [String] Digest::SHA1.hexdigest of the source_file
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

