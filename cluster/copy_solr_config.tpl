require 'azure/storage/file'
require 'json'
require 'tempfile'

# xxx

@storage_acount_name = ''
@storage_account_key = ''

def storage_account
  puts 'Getting list of storage accounts'
  command = `az storage account list -g ${azure_resource_group_name}`
  storage_accounts = JSON.parse(command).collect {|a| a['name']}
  storage_accounts.each do | sa |
    puts "Checking #{sa} for our share"
    command = `az storage share list --account-name "#{sa}"`
    JSON.parse(command).each do | share |
      if share['name'] == '${share_name}'
        puts "Setting the login variables for #{sa}"
        command = `az storage account keys list -g ${azure_resource_group_name} -n "#{sa}"`
        @storage_account_name = sa
        @storage_account_key = JSON.parse(command).first['value']
      end
    end
  end
end

def setup_client 
  @client = Azure::Storage::File::FileService.create(
  storage_account_name: "#{@storage_account_name}", 
  storage_access_key: "#{@storage_account_key}",
  default_endpoints_protocol: 'https'
  )
end

def create_directory
  puts 'Creating solr_config directory'
  @client.create_directory('${share_name}', 'solr_config')
  @client.create_directory('${share_name}', 'solr_config/hhc')
  @client.create_directory('${share_name}', 'solr_config/hyrax')
rescue StandardError  
  @client.get_directory_metadata('${share_name}', 'solr_config')
end

def create_files
  puts 'Creating files for hhc_solr'
  Dir.glob("../hhc_solr/conf/*").each do | f |
    if File.file?(f)
      content = ::File.open(f, 'rb') { |file| file.read }
      puts 'create file on client:' << File.basename(f) << " " << f
      file = @client.create_file('${share_name}', 'solr_config/hhc', File.basename(f), content.size)
      @client.put_file_range('${share_name}', 'solr_config/hhc', file.name, 0, content.size - 1, content)
    end
  end
  puts 'Creating files for hyrax_solr'
  Dir.glob("../hyrax_solr/config/*").each do | f |
    if File.file?(f)
      content = ::File.open(f, 'rb') { |file| file.read }
      file = @client.create_file('${share_name}', 'solr_config/hyrax', File.basename(f), content.size)
      @client.put_file_range('${share_name}', 'solr_config/hyrax', file.name, 0, content.size - 1, content)
    end
  end
rescue StandardError => e  
  puts e.message
end

storage_account
setup_client
create_directory
create_files
