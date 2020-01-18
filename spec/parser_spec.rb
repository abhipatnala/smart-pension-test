require 'spec_helper'

require_relative '../bin/parser'

describe '#get_most_visits' do
  let (:stats_hash) do
    {
      "/help" => {
        total_views: 1,
        unique_ip_count: 1,
        unique_ips: ['127.0.0.2']
      },
      "/about" => {
        total_views: 2,
        unique_ip_count: 1,
        unique_ips: ['127.0.0.2']
      }
    }
  end
  let (:expected_result) do
    {
      "/about" => 2,
      "/help" => 1
    }
  end
  it 'returns hash of most_visits' do
    expect(get_most_visits(stats_hash)).to eq expected_result
  end
end

describe '#get_unique_visits' do
  let (:stats_hash) do
    {
      "/about" => {
        total_views: 1,
        unique_ip_count: 1,
        unique_ips: ['127.0.0.2']
      },
      "/help" => {
        total_views: 2,
        unique_ip_count: 2,
        unique_ips: ['127.0.0.2', '127.0.0.3']
      }
    }
  end
  let (:expected_result) do
    {
      "/help" => 2,
      "/about" => 1
    }
  end
  it 'returns hash of unique_visits' do
    expect(get_unique_visits(stats_hash)).to eq expected_result
  end
end

describe '#check_file_extention' do
  context "when supported file is passed" do
    let (:supported_files) { ["f1.txt", "f2.TXT", "f3.LOG", "f4.log"] }

    it 'does not raise exception' do
      supported_files.each do |extension|
        expect { check_file_extention(extension) }.not_to raise_exception
      end
    end
  end

  context "when supported file is passed" do
    let (:un_supported_files) { ["f1.pdf", "f2.exe", "f3.rb", "f4.py"] }

    it 'does not raise exception' do
      un_supported_files.each do |extension|
        expect { check_file_extention(extension) }.to raise_exception
      end
    end
  end
end

describe '#update_stats_hash' do
  let (:stats_hash) do
    {
      "/about" => {
        total_views: 1,
        unique_ip_count: 1,
        unique_ips: ['127.0.0.2']
      },
      "/help" => {
        total_views: 2,
        unique_ip_count: 2,
        unique_ips: ['127.0.0.2', '127.0.0.3']
      }
    }
  end

  context "when ip address is not unique" do
    let(:ip) { "127.0.0.2" }
    let(:url) { "/about" }

    it 'updates the total views of the url in stats hash' do
      update_stats_hash(stats_hash, ip, url)

      expect(stats_hash["/about"][:total_views]).to eq 2
    end

    it 'does not updates the unique ip count of the url in stats hash' do
      update_stats_hash(stats_hash, ip, url)

      expect{
        update_stats_hash(stats_hash, ip, url)
      }.not_to change{ stats_hash[url][:unique_ip_count] }.from(1)
    end

    it 'does not updates the unique ips of the url in stats hash' do
      update_stats_hash(stats_hash, ip, url)

      expect{
        update_stats_hash(stats_hash, ip, url)
      }.not_to change{ stats_hash[url][:unique_ips] }.from([ip])
    end
  end

  context "when ip address is unique" do
    let(:ip) { "127.0.0.4" }
    let(:url) { "/about" }
    it 'updates the total views of the url in stats hash' do
      update_stats_hash(stats_hash, ip, url)

      expect(stats_hash[url][:total_views]).to eq 2
    end

    it 'updates the unique ip count of the url in stats hash' do

      expect{
        update_stats_hash(stats_hash, ip, url)
      }.to change{ stats_hash[url][:unique_ip_count] }.from(1).to(2)
    end

    it 'updates the unique ips of the url in stats hash' do
      expect{
        update_stats_hash(stats_hash, ip, url)
      }.to change{
        stats_hash[url][:unique_ips]
      }.from(['127.0.0.2']).to( ['127.0.0.2', ip])
    end
  end
end

describe '#parse_weblog' do
  context "when input file contains all invalid ip address" do
    let(:file_path) { "#{RSPEC_ROOT}/fixtures/invalid_ips.log" }
    let(:url) { "/about" }

    it 'returns empty hash for most visits' do
      most_visits = parse_weblog(file_path)[0]

      expect(most_visits.empty?).to eq true
    end

    it 'returns empty hash for unique visits' do
      unique_visits = parse_weblog(file_path)[1]

      expect(unique_visits.empty?).to eq true
    end
  end

  context "when input file contains all valid ip address" do
    let(:file_path) { "#{RSPEC_ROOT}/fixtures/valid_ips.log" }
    let(:url) { "/about" }
    let(:expected_most_visits) do
      {
        "/help_page/1"=>5,
        "/contact"=>1,
        "/home"=>1,
        "/about/2"=>1,
        "/index"=>1
      }
    end

    let(:expected_unique_visits) do
      {
        "/help_page/1"=>3,
        "/contact"=>1,
        "/home"=>1,
        "/about/2"=>1,
        "/index"=>1
      }
    end

    it 'returns sorted stats hash for most visits' do
      most_visits = parse_weblog(file_path)[0]

      expect(most_visits).to eq expected_most_visits
    end

    it 'returns sorted stats hash for unique visits' do
      unique_visits = parse_weblog(file_path)[1]

      expect(unique_visits).to eq expected_unique_visits
    end
  end

    context "when input file contains mix of valid and invalid ip address" do
    let(:file_path) { "#{RSPEC_ROOT}/fixtures/valid_invalid_ips.log" }
    let(:url) { "/about" }
    let(:expected_most_visits) do
      {
        "/help_page/1"=>5,
        "/contact"=>1,
        "/home"=>1,
        "/about/2"=>1,
        "/index"=>1
      }
    end

    let(:expected_unique_visits) do
      {
        "/help_page/1"=>3,
        "/contact"=>1,
        "/home"=>1,
        "/about/2"=>1,
        "/index"=>1
      }
    end

    it 'returns sorted stats hash for most visits ignoring invalid ip entries' do
      most_visits = parse_weblog(file_path)[0]

      expect(most_visits).to eq expected_most_visits
    end

    it 'returns sorted stats hash for unique visits ignoring invalid ip entries' do
      unique_visits = parse_weblog(file_path)[1]

      expect(unique_visits).to eq expected_unique_visits
    end
  end
end
