
BASE =
  %{ bundle exec rspec \
       --require ~/.bash/rspec_dot_errors_formatter.rb \
       --format DotErrorsFormatter --out .errors \
       --format d --out .rspec.out \
       --format d }

lines = (File.readlines('.rspec.out') rescue [])
lines = nil if lines.empty?

if lines
  lines = lines
    .collect(&:strip)
    .drop_while { |l| l != 'Failed examples:' } \
    [2..-2]
    .collect { |l| l.gsub(/\x1b\[\d+(;\d+)?m/, '') }
    .collect { |l| l.match(/\Arspec ([^ ]+)/)[1] }
  #require 'pp'; pp lines
end

cmd = BASE

ARGV.each do |arg|
  if arg.match(/\A(last|la|l)\z/)
    cmd << lines[-1] << ' '
  elsif arg.match(/\A-?\d+\z/)
    l =
      lines[arg.to_i] ||
      fail(ArgumentError.new("no spec at line #{arg}"))
    cmd << lines[arg.to_i] << ' '
  elsif arg.match(/\A:\d+\z/)
    l =
      lines.find { |l| l.match(/\.rb#{arg}\z/) } ||
      fail(ArgumentError.new("no spec matching #{arg}"))
    cmd << l << ' '
  else
    cmd << arg << ' '
  end
end

#p cmd; exit 0
exec(cmd)

