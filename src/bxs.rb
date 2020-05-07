
require 'pp'
require 'yaml'

puts
puts `ruby -v`
puts

#puts "v" * 80
#pp ARGV
#puts "^" * 80


def re_encode_to_utf8(s)
  (s.valid_encoding? ?
    s :
    s.encode('UTF-16be', invalid: :replace, replace: '?')
  ).encode('UTF-8')
end


bxspre =
  (File.readlines('.bxspre')
    .find { |l| l.strip.length > 0 && ! l.match(/^\s*#/) }
    .strip rescue nil)

bxsinfo = (YAML.load(File.read('.bxsinfo.yaml')) rescue nil) || {}
bxsenvs = (YAML.load(File.read('.bxsenvs.yaml')) rescue nil) || {}

if %w[ read r ].find { |e| ARGV == [ e ] }
  pp bxsinfo
  exit 0
end
if %w[ index i ].find { |e| ARGV == [ e ] }
  lim = bxsinfo[:lines].size; lim = 14 if lim > 14
  (0..lim).each do |i|
    puts "%2d - %s" % [ i, bxsinfo[:index][i] ]
  end
  exit 0
end
if %w[ all a ].find { |e| ARGV == [ e ] }
  lim = bxsinfo[:lines].size; lim = 14 if lim > 14
  (0..28).each do |i|
    dash = i <= lim ? '=' : '-'
    v = bxsinfo[:index][i]; break unless v
    puts "%2d %s %s" % [ i, dash, v ]
  end
  exit 0
end
if %w[ paths ].find { |e| ARGV == [ e ] }
  puts bxsinfo[:index]
    .select { |k, v| k.is_a?(Integer) }
    .values
    .uniq
    .take(1)
  exit 0
end
#if %w[ f ].find { |e| ARGV == [ e ] }
#  pp bxsinfo[:file]
#  exit 0
#end

#exec(bxsinfo[:cmd]) if ARGV == bxsinfo[:argv]

SRCDIR =
  File.dirname(__FILE__)
BASE =
  [ bxspre,
    'bundle exec rspec',
    #"jruby -J-Xmx5012m -S bundle exec rspec",
    '-I .',
    "--require #{File.join(SRCDIR, 'rspec_dot_errors_formatter.rb')}",
    '--format DotErrorsFormatter --out .errors',
    #'--format documentation --out .rspec.out',
    '--color --tty',
    '--format documentation ' ]
      .compact
      .join(' ')

lines =
  (File.readlines('.rspec.out') rescue [])
lines = lines
  .collect { |l| re_encode_to_utf8(l).strip }
  .drop_while { |l| l != 'Failed examples:' } \
  [2..-1] || []
lines = lines
  .collect { |l| l.gsub(/\x1b\[\d+(;\d+)?m/, '') }
  .inject([]) { |a, l| m = l.match(/\Arspec ([^ ]+)/); a << m[1] if m; a }
#puts "-" * 80; pp lines; puts "-" * 80

index = bxsinfo[:index] || {}; lines.each_with_index do |l, i|
  fn, ln = l.split(':')
  index[":#{ln}"] = l
  index[i] = l
  index[File.basename(fn, '.rb')[0..-6]] = fn
end

fnames = index
  .select { |k, v| k.is_a?(String) && ! k.match(/\A:/) }
#pp index


cmd = BASE
parg = nil

ARGV.each do |arg|
  narg = arg
  cmd <<
    if %w[ -w ].include?(arg)
      narg = nil
      arg
    elsif (parg && parg.match(/\A--?[a-z]/)) || arg.match(/\A--?[a-z]/)
      arg.index(' ') ? arg.inspect : arg
    elsif arg == '.'
      File.read('.vimspec').strip
    elsif arg.match(/\A(file|fi|f)\z/)
      File.read('.vimspec').strip.split(':').first
    elsif arg.match(/\A(\.\/)?spec\//)
      arg
    elsif arg.match(/\A(last|la|l)\z/)
      lines[-1] ||
      fail(ArgumentError.new("no last spec"))
    elsif arg.match(/\A\d+\z/)
      index[arg.to_i] ||
      fail(ArgumentError.new("no spec ##{arg}"))
    elsif arg.match(/\A-\d+\z/)
      lines[arg.to_i] ||
      fail(ArgumentError.new("no spec ##{arg}"))
    elsif arg.match(/\A:\d+\z/)
      index[arg] ||
      fail(ArgumentError.new("no spec matching #{arg}"))
    elsif arg == 'f'
      bxsinfo[:file] ||
      fail(ArgumentError.new("no particular spec file"))
    elsif bxsenvs[arg]
      ''
    else
      (
        fnames.find { |k, v| k == arg } ||
        fnames.find { |k, v| k.index(arg) } ||
        fail(ArgumentError.new("no spec fname matching #{arg}"))
      )[1]
    end << ' '
  if e = bxsenvs[arg]; cmd = e << ' ' << cmd; end
  parg = narg
end

file = cmd.split.select { |w| w.match(/\A\.\/spec\//) }.last
file = file.split(':').first if file

bxsinfo[:argv] = ARGV
bxsinfo[:cmd] = cmd
bxsinfo[:file] = file
bxsinfo[:lines] = lines
bxsinfo[:index] = index
#pp bxsinfo
File.open('.bxsinfo.yaml', 'wb') { |f| f.write(YAML.dump(bxsinfo)) }

cmd += ' 2>&1 | tee .rspec.out'

puts(cmd)
exec(cmd)

