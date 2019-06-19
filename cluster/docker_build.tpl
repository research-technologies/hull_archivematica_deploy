require 'json'
require 'date'

build = ${do_build}

images = "${images}".split(',')

# Alternative approach, build if the image is older than an hour
# images.each do | image |
#   images_list =  `docker images`
#   next unless images_list.include?(images.first)
#   output = `docker image inspect #{image}`  
#   json = JSON.parse(output) unless output.nil?
#   one_hour_ago_time = (DateTime.now - (1.0/24))
#   created_time = DateTime.parse(json.first['Created'])
#   if created_time > one_hour_ago_time
#     build = 0
#   end
# end

if build != 0
  `cd .. && docker-compose build`
  puts 'New images built'
else
  puts 'New images have not been built'
end