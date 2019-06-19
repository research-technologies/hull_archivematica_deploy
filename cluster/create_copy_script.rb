require 'azure/storage/file'
require 'json'

# xxx

@storage_acount_name = ''
@storage_account_key = ''

def storage_account
  puts 'Getting list of storage accounts'
  command = `az storage account list -g MC_hull-uat-hullculture_hull-uat-hullculture_northeurope`
  storage_accounts = JSON.parse(command).collect {|a| a['name']}
  storage_accounts.each do | sa |
    puts "Checking #{sa} for our share"
    command = `az storage share list --account-name "#{sa}"`
    JSON.parse(command).each do | share |
      if share['name'] == 'kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df'
        puts "Setting the login variables for #{sa}"
        command = `az storage account keys list -g MC_hull-uat-hullculture_hull-uat-hullculture_northeurope -n "#{sa}"`
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
  @client.create_directory('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config')
  @client.create_directory('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config', 'hhc')
  @client.create_directory('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config', 'hyrax')
rescue StandardError  
  @client.get_directory_metadata('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config')
end

def create_files
  puts 'Creating files'
  Dir.glob("../hhc_solr/conf/*").each do | f |
    if File.file?(f)
      content = ::File.open(f, 'rb') { |file| file.read }
      file = @client.create_file('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config/hhc', File.basename(f), content.size)
      @client.put_file_range('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config/hhc', file.name, 0, content.size - 1, content)
    end
  end
  Dir.glob("../hyrax_solr/config/*").each do | f |
    if File.file?(f)
      content = ::File.open(f, 'rb') { |file| file.read }
      file = @client.create_file('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config/hyrax', File.basename(f), content.size)
      @client.put_file_range('kubernetes-dynamic-pvc-6e35b970-92a0-11e9-ad1a-b21a2932c3df', 'solr_config/hyrax', file.name, 0, content.size - 1, content)
    end
  end
rescue StandardError => e  
  puts e.message
end

storage_account
setup_client
create_directory
create_files