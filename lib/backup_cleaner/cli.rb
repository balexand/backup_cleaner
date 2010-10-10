require 'backup_cleaner'
require 'trollop'

module BackupCleaner
  module Cli
    def self.run
      opts = Trollop::options do
        banner <<-EOS
Cleans up backup files or folders within the specified folder. The names of these files/folders must include the backup date \
in a format like: YYYY-MM-DD. Any files/folders with names not matching this pattern will be left untouched. Between \
today and <days> days ago, all backups will be kept. Between today and <weeks> weeks ago, weekly backups will be kept. For \
all time, monthly backups will be kept. For weekly/monthly backups, the earliest available backup from the week/month will \
be kept. For example, if daily backups are present then weekly backups will be from Sunday and monthly backups will be from \
the 1st of the month.

This script can also handle backups from multiple projects in one directory as long as they are named differently. If files \
named aaa-2010-01-01.tar.gz and 2010-01-01.bbb.tar.bz2 exist then both will be kept. When comparing the names, only letters \
are considered. For example, aaa-2010-01-01.tar.gz and aaa-2010-01-01.12.12.12.tar.gz.2 are considered to be from the same \
backup project and unless these backups are from the last <days> days, one will be deleted.

Usage:
      clean_backups.rb [options] <folder>

where [options] are:
  EOS

        opt :days, "Number of days for which to keep daily backups", :type => :int, :default => 14
        opt :weeks, "Number of weeks for which to keep weekly backups", :type => :int, :default => 8
        opt :dry_run, "Don't really delete anything, just print out what would have been deleted", :short => :n
      end

      folder = ARGV.shift
      Trollop::die "No folder specified" unless folder

      # clean the backups
      BackupCleaner.clean_backups(folder, opts)
    end
  end
end