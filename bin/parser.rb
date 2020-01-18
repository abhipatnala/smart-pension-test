#!/usr/bin/env ruby

require "ipaddress"

SUPPORTED_FILE_EXTENTIONS = ['.txt','.log'].freeze

def parse_weblog(log_file)
  check_file_extention(log_file)

  stats_hash = Hash.new do |hash, key|
    hash[key] = {
      total_views: 0,
      unique_ips: [],
      unique_ip_count: 0
    }
  end

  File.readlines(log_file).each do |line|
    url, ip = line.split(" ")

    if IPAddress.valid? ip
      update_stats_hash(stats_hash, ip, url)
    end

  end

  most_visits, unique_visits = get_most_visits(stats_hash), get_unique_visits(stats_hash)

end

def get_most_visits(stats_hash)
  sorted_hash =  stats_hash.sort_by{|_key, value| -value[:total_views]}

  sorted_hash.map{ |key, value| [key, value[:total_views]] }.to_h
end

def get_unique_visits(stats_hash)
  sorted_hash =  stats_hash.sort_by{|_key, value| -value[:unique_ip_count]}

  sorted_hash.map{ |key, value| [key, value[:unique_ip_count]] }.to_h
end

def check_file_extention(file_path)
  file_extention = File.extname(file_path).downcase

  unless SUPPORTED_FILE_EXTENTIONS.include?(file_extention)
    raise ArgumentError, "Invalid file path"
  end
end

def update_stats_hash(stats_hash, ip, url)
  stats_hash[url][:total_views] += 1
  if !stats_hash[url][:unique_ips].include? ip
    stats_hash[url][:unique_ip_count] += 1
    stats_hash[url][:unique_ips] << ip
  end
end

if $0 == __FILE__
  raise ArgumentError, "Please file path of" \
    "server log to parse" unless ARGV.length == 1

  most_visits, unique_visits = parse_weblog(ARGV[0])

  puts most_visits
  puts unique_visits
end
