
exec %{
  bundle exec rspec \
    --require ~/.bash/rspec_dot_errors_formatter.rb \
    --format DotErrorsFormatter --out .errors \
    --format d --out .rspec.out \
    --format d
}

