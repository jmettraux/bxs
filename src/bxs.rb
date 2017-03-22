
bxsinfo = (Marshal.load(File.read('.bxsinfo')) rescue nil) || {}
#require 'pp'; pp bxsinfo

if ARGV == %w[ read ] || ARGV == %w[ r ]
  require 'pp'; pp bxsinfo
  exit 0
end

#exec(bxsinfo[:cmd]) if ARGV == bxsinfo[:argv]

SRCDIR =
  File.dirname(__FILE__)
BASE =
  [
    "bundle exec rspec",
    "--require #{File.join(SRCDIR, 'rspec_dot_errors_formatter.rb')}",
    "--format DotErrorsFormatter --out .errors",
    "--format documentation --out .rspec.out",
    "--format documentation "
  ].join(' ')

lines =
  (File.readlines('.rspec.out') rescue [])
lines = lines
  .collect(&:strip)
  .drop_while { |l| l != 'Failed examples:' } \
  [2..-2] || []
lines = lines
  .collect { |l| l.gsub(/\x1b\[\d+(;\d+)?m/, '') }
  .collect { |l| l.match(/\Arspec ([^ ]+)/)[1] }
#require 'pp'; pp lines

index = bxsinfo[:index] || {}; lines.each_with_index do |l, i|
  fn, ln = l.split(':')
  index[":#{ln}"] = l
  index[i] = l
  index[File.basename(fn, '.rb')[0..-6]] = fn
end

fnames = index
  .select { |k, v| k.is_a?(String) && ! k.match(/\A:/) }
#require 'pp'; pp index


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
    else
      (
        fnames.find { |k, v| k == arg } ||
        fnames.find { |k, v| k.index(arg) } ||
        fail(ArgumentError.new("no spec fname matching #{arg}"))
      )[1]
    end << ' '
  parg = arg
end

bxsinfo[:argv] = ARGV
bxsinfo[:cmd] = cmd
bxsinfo[:lines] = lines
bxsinfo[:index] = index
#require 'pp'; pp bxsinfo
File.open('.bxsinfo', 'wb') { |f| f.write(Marshal.dump(bxsinfo)) }

#p cmd; exit 0
exec(cmd)

