# coding: utf-8
# topsearchqueries.rb
# 2010-02-20

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
    a_term = {'days'=>"過去7日分", 'week'=>"2 週間前", 'month'=>"#{xi}月"}
    a_search = {'1'=>"すべての検索", '2'=>"ウェブ検索", '3'=>"携帯端末", '4'=>"ブログ検索"}
    a_domain = {'all'=>"すべての Google ドメイン", 'google'=>'google'}
    @file = h['f']
    @term = a_term[h['t']] ||= "過去7日分"
    @domain = a_domain[h['d']] ||= "すべての Google ドメイン"
    @search = a_search[h['s']] ||= "すべての検索"
    (h['n'].nil?) ? @num = 10 : @num = h['n'].to_i
    @title = ""
    @words = Hash.new(0)
  end

  def base
    return nil unless @file
    return nil unless File.exist?(@file)
    IO.foreach(@file){|line|
      next if /^,場所/.match(line)
      x = line.split(",\"")
      area_str, words_str = x[0], x[1]
      term, domain, search = area_str.split(",")
      next unless term == @term
      next unless search == @search
      next unless domain.include?(@domain)
      @title << "#{term}, #{domain}, #{search}\n"
      get_words(words_str)
    }
    return output unless @words.empty?
    print "Nothing.\n\n"
  end

  def get_words(str)
    str.split(/\]/).each{|x|
      next if x.empty?
      ary = x.split(",")
      word, n = ary.first, ary.last
      next unless word =~ /\[/
      @words[word.gsub(/\[/,'').strip] += n.strip.to_i
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
    h = @words.sort_by{|k,v| v}.reverse[0..@num-1]
    h.each_with_index{|x,n| to_s([n+1, x].flatten)}
    output_sum(h)
  end

  def output_sum(h)
    s1, s2, s3 = get_sum(@words.values), get_sum(h.map{|x| x[1]}), h.size
    a1, a2, a3 = ["1", s3, s2], [@num+1, @words.size, s1-s2], ["Total", s1]
    print hyphen
    printf "[%-3d\..%3d]\s%d\n" % a1
    (printf "[%-3d\..%3d]\s%d\n" % a2 ) unless a2[2] < 1
    printf "[%8s]\s\%d clicks\n" % a3
  end

end

TopSearchQueries.new(arg).base
