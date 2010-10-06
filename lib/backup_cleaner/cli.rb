require 'trollop'

module BackupCleaner
  module Cli
    def self.run
      opts = Trollop::options do
        banner <<-EOS
Cleans up backup files or folders within the specified folder. The names of these files/folders must start with the date \
in the following format: YYYY-MM-DD. Any files/folders with names not matching this pattern will be left untouched. Daily \
backups will be kept for the specified number of days and weekly backups will be kept for the specified number of weeks. \
Monthly backups will be kept forever.

Usage:
      clean_backups.rb [options] <folder>
where [options] are:
  EOS

        opt :days, "Number of days for which to keep daily backups", :type => :int, :default => 14
        opt :weeks, "Number of weeks for which to keep weekly backups", :type => :int, :default => 8
        opt :dry_run, "Don't really delete anything, just print out what would have been deleted", :short => :n
        opt :test, "Just run the unit tests"
      end
    end
  end
end