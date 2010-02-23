#!/usr/bin/local/ruby19
# coding: utf-8
# 2010-02-24

exit unless Encoding.default_external.name == 'UTF-8'
arg = ARGV
arg.delete("")
$LOAD_PATH.delete(".")
dir = File.dirname(File.expand_path($PROGRAM_NAME))
readf = File.join(dir, 'README')
if arg[0] =~ /\-h|\-\-help/
  exit unless File.exist?(readf)
  print IO.read(readf); exit
end
exit if arg.size < 2

class TopSearchQueries

  def initialize(arg)
    m, h = '', {}
    arg.each{|x| (m = /^-(.*)/.match(x); next) if /^-/.match(x); h[m[1]] = x if m}
    x = /month(.*)/.match(h['t'])
    (xi = x[1].to_i; h['t'] = 'month') if x
    a_term = {'week'=>"過去7日分", 'week2'=>"2 週間前", 'week3'=>"3 週間前", 'month'=>"#{xi}月", 'all'=>'all'}
    a_domain = {'all'=>"すべての Google ドメイン", 'google'=>'google'}
    a_search = {'1'=>"すべての検索", '2'=>"ウェブ検索", '3'=>"携帯端末", '4'=>"ブログ検索"}
    @file, @title = h['f'], ""
    @term = a_term[h['t']] ||= a_term['week']
    @domain = a_domain[h['d']] ||= a_domain['all']
    @search = a_search[h['s']] ||= a_search['1']
    (h['n'].nil?) ? @num = 10 : @num = h['n'].to_i
    @words1, @words2 = Hash.new(0), Hash.new(0)
  end

  def base
    return nil unless @file
    return nil unless File.exist?(@file)
    IO.foreach(@file){|line|
      next if /^,場所/.match(line)
      x = line.split(",\"")
      area_str, words_str, qw_str = x[0], x[1], x[2]
      term, domain, search = area_str.split(",")
      (next unless term == @term) unless @term == 'all'
      next unless search == @search
      next unless domain.include?(@domain)
      @title << "#{term}, #{domain}, #{search}\n"
      get_words1(words_str)
      get_words2(qw_str)
    }
    return output unless @words1.empty?
    print "Nothing.\n\n"
  end

  def get_words1(str)
    str.split(/\]/).each{|x|
      ary = x.strip.gsub(/\[/, '').split(",")
      next if ary.size < 2
      @words1[ary.first] += ary.last.strip.to_i
    }
  end

  def get_words2(str)
    return nil unless str
    str.split(/\]/).each{|x|
      ary = x.strip.gsub(/\[/, '').split(",")
      next if ary.size < 2
      @words2["*\s"+ary.first] += ary.last.strip.to_i
    }
  end

  def to_s(ary)
    printf "%3d,\s%s\s%d\n" % ary
  end

  def hyphen
    ("-"*30 + "\n")
  end

  def get_sum(ary)
    return ary.inject(0){|sum, x| sum + x}
  end

  def output
    print hyphen, @title, hyphen
    @words2.each{|k,v| to_s([0, k, v].flatten)} 
    h = @words1.sort_by{|k,v| v}.reverse[0..@num-1]
    h.each_with_index{|x,n| to_s([n+1, x].flatten)}
    output_sum(h)
  end

  def output_sum(h)
    s1, s2, s3 = get_sum(@words1.values), get_sum(h.map{|x| x[1]}), h.size
    a1, a2, a3 = ["1", s3, s2], [@num+1, @words1.size, s1-s2], ["Total", s1]
    print hyphen
    printf "[%-3d\..%3d]\s%d\n" % a1
    (printf "[%-3d\..%3d]\s%d\n" % a2 ) unless a2[2] < 1
    printf "[%8s]\s\%d clicks\n" % a3
  end

end

TopSearchQueries.new(arg).base
