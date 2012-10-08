require 'rubygems'
require 'linode'
require 'yaml'
require 'ostruct'

BASE_DIR = File.expand_path(File.dirname(__FILE__))
config = OpenStruct.new(YAML::load_file(File.join(BASE_DIR, 'config.yml')))

interface_list_commands = {
  :ifconfig => {
    :command => 'ifconfig',
    :regex => /^(\w+).+\n.+inet addr:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
  },

  :ip => {
    :command => 'ip addr show',
    :regex => /^\d+: (\w+): .+\n.+\n.+inet (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
  }
}

def determine_ip_address(interface, interface_list_commands = {})
  if interface.nil? or interface == ''
    `curl --silent icanhazip.com`.chomp
  else
    determine_ip_with_commands(interface, interface_list_commands)
  end
end

def determine_ip_with_commands(interface, interface_list_commands)
  successful_command = nil
  output = nil

  interface_list_commands.each_pair do |command, command_hash|
    next unless command_exists?(command.to_s)
    output = `#{command_hash[:command]}`

    if $? == 0
      successful_command = command
      break
    else
      puts "Could not run `ip addr show`"
    end
  end
  raise "Could not determine IP address for #{interface}" if successful_command.nil? 
  
  matches = output.scan(interface_list_commands[successful_command][:regex]).flatten
  interface_key = matches.index(interface)
  raise "Could not determine IP address for #{interface}" if interface_key.nil?
  matches[interface_key + 1]
end

def command_exists?(command)
  `which #{command}`
  $?.to_i == 0
end

begin
  print "Connecting to Linode... "
  linode = Linode.new(:api_key => config.api_key)
  puts "OK"
rescue Exception => error
  puts error.message
  exit 1
end

print "Locating domain #{config.domain}... "
matches = linode.domain.list.select{ |d| d.domain == config.domain }
raise "No matches for #{config.domain}." if matches.length == 0
raise "Too many matches for #{config.domain}. Found #{matches.length}." if matches.length > 1

domain = matches.first
puts "ID #{domain.domainid}"

print "Locating A records: #{config.names_to_change.join(', ')}... "
resources = linode.domain.resource.list(:DomainId => domain.domainid).select { |r| 
  config.names_to_change.include?(r.name)
}
puts "Found #{resources.length} matching domain(s)"

print "Determining external IP address... "
external_ip = determine_ip_address(config.external_interface, interface_list_commands)
puts external_ip

puts "Updating A records:"
resources.each do |resource|
  print "  #{resource.name}.#{domain.domain}... "
  if external_ip == resource.target
    puts "No change needed"
  else
    response = linode.domain.resource.update(
      :DomainId => domain.domainid, 
      :ResourceId => resource.resourceid,
      :Target => external_ip
    )

    if response.errorarray.nil?
      puts "Updated!"
    else
      puts "Errors: #{response.errorarray.join(', ')}"
    end
  end
end

puts "Operation complete!"
