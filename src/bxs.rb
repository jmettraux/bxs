
require 'pp'

bxsinfo = (Marshal.load(File.read('.bxsinfo')) rescue nil) || {}

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
#if %w[ f ].find { |e| ARGV == [ e ] }
#  pp bxsinfo[:file]
#  exit 0
#end

#exec(bxsinfo[:cmd]) if ARGV == bxsinfo[:argv]

SRCDIR =
  File.dirname(__FILE__)
BASE =
  [
    "bundle exec rspec",
    "--require #{File.join(SRCDIR, 'rspec_dot_errors_formatter.rb')}",
    "--format DotErrorsFormatter --out .errors",
    #"--format documentation --out .rspec.out",
    "--color --tty",
    "--format documentation "
  ].join(' ')

lines =
  (File.readlines('.rspec.out') rescue [])
lines = lines
  .collect(&:strip)
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
  cmd <<
    if (parg && parg.match(/\A-[a-z]/)) || arg.match(/\A-[a-z]/)
      arg
    elsif arg.match(/\Aspec\//)
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
    else
      (
        fnames.find { |k, v| k == arg } ||
        fnames.find { |k, v| k.index(arg) } ||
        fail(ArgumentError.new("no spec fname matching #{arg}"))
      )[1]
    end << ' '
  parg = arg
end

file = cmd.split.select { |w| w.match(/\A\.\/spec\//) }.last
file = file.split(':').first if file

bxsinfo[:argv] = ARGV
bxsinfo[:cmd] = cmd
bxsinfo[:file] = file
bxsinfo[:lines] = lines
bxsinfo[:index] = index
#pp bxsinfo
File.open('.bxsinfo', 'wb') { |f| f.write(Marshal.dump(bxsinfo)) }

cmd += ' 2>&1 | tee .rspec.out'

puts(cmd)
exec(cmd)

