# encoding: utf-8
require 'method_doc'
require 'doc_parser'

module RapiDoc
  # ResourceDoc holds the information a resource contains. It parses the class header and also the 
  # method documentation, which will be contained in MethodDoc.
  class ResourceDoc
    
    attr_reader :name, :resource_location, :controller_name, :function_blocks, :class_block
    
    # Initializes ResourceDoc.
    def initialize(name, resource_location, controller_name, options = {})
      @name = name
      @standard_methods = options[:standard_methods] || [:put, :post, :get, :delete]
      @resource_location, @controller_name = resource_location, controller_name
      @function_blocks = []
      @method_codes = []
      @header_code = ""
      
      unless File.exist?(controller_location)
        raise "Unable to find or open controller. Make sure it's set properly in config/rapidoc/config.yml File: #{controller_location}"
      end
    end
    
    # returns the location of the controller that is to be parsed
    def controller_location
      # @resource_location
      "#{::Rails.root.to_s}/doc/#{controller_name}"
    end
    
    def get_binding
      binding
    end
    
    # parse the controller
    def parse_apidoc!
      line_no = 0
      
      parser = DocParser.new
      order = 1
      File.open(controller_location).each do |line|
        case
        when line =~ /=begin apidoc/
          parser.start(order)
        when line =~ /=end/
          if parser.current_api_block.nil?
            puts "#{controller_location}:#{line_no} - No starttag for '=end' found"
            exit
          else
            case parser.current_scope
            when :class
              @class_block = parser.current_api_block
            when :function
              @function_blocks << parser.current_api_block
            end
            parser.reset_current_scope_and_api_block
            order += 1
          end
        when line =~ /class/
          parser.in_class = true
        when line =~ /::response-end::/, line =~ /::request-end::/, line =~ /::output-end::/
          parser.current_scope = :function
        else
          parser.parse(line)
        end
        
        line_no += 1
      end
      
      puts "Generated #{name}.html"
    end

    def generate_view!(resources, temp_dir)
       @resources = resources
       @header_code = get_parsed_header unless @class_block.nil?
       i = 1
       function_blocks.each do |mb|
         @method_codes << get_parsed_method(mb, i)
         i += 1
       end
       # write it to a file
       template = ""
       File.open(layout_file(:target)).each { |line| template << line }
       parsed = ERB.new(template).result(binding)
       File.open(File.join(temp_dir, name + ".html"), 'w') { |file| file.write parsed }
    end

    def get_parsed_header
      template = ""
      File.open(File.join(File.dirname(__FILE__), '..', 'templates', '_resource_header.html.erb')).each { |line| template << line }
      ERB.new(template).result(@class_block.get_binding)
    end

    def get_parsed_method(method_block, method_order)
      template = ""
      File.open(File.join(File.dirname(__FILE__), '..', 'templates', '_resource_method.html.erb')).each { |line| template << line }
      return ERB.new(template).result(method_block.get_binding)
    end

  end
end
