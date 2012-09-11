include RapiDoc::RapiConfig

namespace :rapi_doc do
  desc "Generate the config files"
  task :setup do
    if File.directory?(config_dir)
      puts "#{BASE_DIR}/#{File.basename(config_dir)} exists"
    else
      FileUtils.mkdir(config_dir)
    end
    %w(config_file layout_file class_layout_file frameset_file main_file).each do |type_file|
      target_file = send(type_file, :target)
      template_file = send(type_file, :template)
      if File.exist? target_file
        puts "#{BASE_DIR}/#{File.basename(target_file)} exists"
      else
        FileUtils.cp template_file, config_dir
        puts "Generated #{BASE_DIR}/#{File.basename(template_file)}" # TODO Add instructions for users to update the config file
      end
    end
  end
  desc "Generate the API Documentation"
  task :generate do
    begin
      yml = YAML::load(File.open(config_file(:target)))
    rescue
      puts "It seems that you don't have the config files yet. Please run rake rapi_doc:setup"
    end

    # Generating documentations
    if yml
      resources = []
      yml.keys.each do |key|
        resources << RapiDoc::ResourceDoc.new(key, yml[key]["location"], yml[key]["doc_path"])
      end

      # generate the apidoc
      RapiDoc::RAPIDoc.new(resources)
    end
  end
end
