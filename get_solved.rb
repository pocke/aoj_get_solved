# Copyright 2014, pocke
# Licensed MIT
# http://opensource.org/licenses/mit-license.php

require 'open-uri'
require 'nokogiri'
require 'optparse'
require_relative 'xml_hash'

def get_problem_ids(user_id)
  result = []
  i = 0
  loop do
    buf = REXML::Document.new(open("http://judge.u-aizu.ac.jp/onlinejudge/webservice/status_log?user_id=#{user_id}&limit=100&start=#{i}")).to_hash[:status_list][:status]
    buf.each do |b|
      b.each do |key, val|
        val.gsub!("\n", '')
      end
    end
    result.concat buf
    break unless buf.size == 100
    i += 100
  end
  result
end

def get_source(id)
  h = Nokogiri::HTML(open("http://judge.u-aizu.ac.jp/onlinejudge/review.jsp?rid=#{id}"))
  h.css('#code').text.chomp.chomp
end

def make_problem_tree(user_id, dir)
  probs = get_problem_ids(user_id)
  thread_list = []
  probs.each do |prob|
    thread_list << Thread.new do
      begin
        prob[:source] = get_source(prob[:run_id])
        puts "get source #{prob[:run_id]}"
      rescue SocketError
        puts 'error'
        sleep 1
        retry
      end
    end
  end
  thread_list.each{|t|t.join}

  Dir.chdir(dir) do
    probs.each do |prob|
      Dir.mkdir(prob[:problem_id]) unless Dir.exist?(prob[:problem_id])
      suffix = case prob[:language]
        when 'C';            'c'
        when 'C++', 'C++11'; 'cpp'
        when 'JAVA';         'java'
        when 'C#';           'cs'
        when 'D';            'd'
        when 'Ruby';         'rb'
        when 'Python';       'py'
        when 'PHP';          'php'
        when 'JavaScript';   'js'
        end
      status = case prob[:status]
        when 'Accepted';                               'AC'
        when 'Wrong Answer', 'WA: Presentation Error'; 'WA'
        when 'Time Limit Exceeded';                    'TL'
        when 'Memory Limit Exceeded';                  'ML'
        when 'Runtime Error';                          'RE'
        when 'Compile Error';                          'CE'
        end
      File::open(File::join(prob[:problem_id], "#{prob[:run_id]}#{status}.#{suffix}"), 'w') do |f|
        f.write(prob[:source])
      end
    end
  end
end

OPTS = {}
OptionParser.new do |o|
  o.on('-u USER', '--user=USER') {|v| OPTS[:user] = v}
  o.on('-d DIR', '--dir=DIR') {|v| OPTS[:dir] = v}
  
  o.parse!(ARGV)
end
raise 'not found required option.' unless OPTS[:user] and OPTS[:dir]

make_problem_tree(OPTS[:user], OPTS[:dir])
