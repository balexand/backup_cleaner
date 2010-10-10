require 'active_support/time'
require 'fileutils'
require 'set'

module BackupCleaner
  DATE_PATTERN = /^(.*)(\d{4}[-\.]\d{2}[-\.]\d{2})(.*)$/

  Entry = Struct.new :name, :date, :prefix, :suffix
  GroupKey = Struct.new :date_property, :prefix, :suffix

  def self.clean_backups(folder, opts = {})
    days = opts[:days]
    weeks = opts[:weeks]
    dry_run = opts[:dry_run]

    raise ArgumentError, "'days' option must have an integer value" unless days.is_a? Integer
    raise ArgumentError, "'weeks' option must have an integer value" unless weeks.is_a? Integer
    raise ArgumentError, "#{folder} should be a directory" unless File.directory? folder

    entries = Dir.entries(folder).select { |name| DATE_PATTERN =~ name }.collect do |name|
      m = DATE_PATTERN.match(name)
      Entry.new(name, Date.parse(m[2]), m[1].gsub(/[^A-Za-z]/, ''), m[3].gsub(/[^A-Za-z]/, ''))
    end

    weekly_keepers = Set.new(first_by_date_property(entries, :week_ordering_number))
    monthly_keepers = Set.new(first_by_date_property(entries, :month_ordering_number))

    entries.each do |entry|
        unless entry.date >= days.days.ago.to_date ||
             (week_ordering_number(entry.date) >= week_ordering_number(weeks.weeks.ago.to_date) && weekly_keepers.member?(entry)) ||
             monthly_keepers.member?(entry)
        if dry_run
          puts "pretending to delete (dry_run) #{entry.name}"
        else
          puts "deleting #{entry.name}"
          FileUtils.rm_rf(File.join(folder, entry.name))
        end
      end
    end
  end

  def self.first_by_date_property(entries, property_name)
    # group entries by the specified date property plus file name prefix and suffix
    groups = {}
    entries.each do |entry|
      group_key = GroupKey.new send(property_name, entry.date), entry.prefix, entry.suffix
      groups[group_key] = {} unless groups.has_key? group_key
      groups[group_key].merge!({entry.date => entry})
    end

    # return the earliest date in each group
    groups.values.collect do |group|
      group[group.keys.sort.first]
    end
  end
  private_class_method :first_by_date_property

  def self.week_ordering_number(date)
    # cweek considers weeks to start on Monday; adjust so week starts on Sunday
    date += 1.day if date.wday == 0
    date.cweek + date.cwyear * 100
  end
  private_class_method :week_ordering_number

  def self.month_ordering_number(date)
    date.month + date.year * 100
  end
  private_class_method :month_ordering_number
end
