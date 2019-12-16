require "mkmf"

# append_cppflags "-O3 -I#{Gem.loaded_specs["bit_utils"].full_gem_path}/ext"

File.write "Makefile", dummy_makefile(?.).join
unless Gem::Platform.local.os == "darwin" && Gem::Version.new(RUBY_VERSION) == Gem::Version.new("2.3.8")
else
  begin
    # https://github.com/rbenv/rbenv/issues/1199
    append_cppflags "-I#{Dir.glob("#{`rbenv root`.chomp}/sources/#{`rbenv version-name`.chomp}/*/").first}"
  rescue
  else
    create_makefile "idhash"
    # Why this hack?
    # 1. Because I want to use Ruby and ./idhash.bundle for tests, not C.
    # 2. Because I don't want to bother users with two gems instead of one.
    File.write "Makefile", <<~HEREDOC + File.read("Makefile")
      .PHONY: test
      test: all
      \t$(RUBY) -r./lib/dhash-vips.rb ./lib/dhash-vips-post-install-test.rb
    HEREDOC
  end
end

# Cases to check:
# 0. all is ok
# 1. not macOS && rbenv
# 2. `` error and so abort
# 3. exception in append_cppflags
# 4. failed compilation
# 5. failed tests
# `rm -rf idhash.o idhash.bundle pkg && bundle exec rake install` # idk why errors
# `rm -f idhash.o idhash.bundle Makefile && ruby extconf.rb && make`
# `bundle exec rake -rdhash-vips -e "p DHashVips::IDHash.method(:distance3).source_location"`