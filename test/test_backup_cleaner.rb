require 'helper'
require 'backup_cleaner'
require 'mocha'

class TestBackupCleaner < Test::Unit::TestCase

  should "raise ArgumentError if invalid args passed to constructor" do
    valid_opts = {:days => 14, :weeks => 2, :dry_run => true}
    valid_folder = File.expand_path(Dir.pwd)

    BackupCleaner.clean_backups(valid_folder, valid_opts)

    # folder doesn't exist
    assert_raises(ArgumentError) do
      BackupCleaner.clean_backups('/paththatdoesntexist-asoiugsaoifaweasfoo', valid_opts)
    end

    # folder should be a String, not NilClass
    assert_raises(TypeError) do
      BackupCleaner.clean_backups(nil, valid_opts)
    end

    # missing days
    assert_raises(ArgumentError) do
      BackupCleaner.clean_backups(valid_folder, valid_opts.reject {|k,v| k == :days})
    end

    # days of invalid type
    assert_raises(ArgumentError) do
      BackupCleaner.clean_backups(valid_folder, valid_opts.merge(:days => "3"))
    end

    # missing weeks
    assert_raises(ArgumentError) do
      BackupCleaner.clean_backups(valid_folder, valid_opts.reject {|k,v| k == :weeks})
    end

    # weeks of invalid type
    assert_raises(ArgumentError) do
      BackupCleaner.clean_backups(valid_folder, valid_opts.merge(:weeks => nil))
    end
  end

  should "clean correct backups" do
    folder = "/foo/bar"

    # mock todays date
    fake_today_time = Time.parse("1981-12-18")
    fake_today = fake_today_time.to_date
    Time.expects(:current).at_least_once.returns(fake_today_time)

    # create mock entries in a directory
    entries = (0..180).collect {|i| "aaa-#{(fake_today-i).strftime('%Y-%m-%d')}.tar.gz"}
    entries += ["1980-03-03-foo.tar.bz2", "1980-03-20-foo.tar.bz2",
                "1980-03-03-bar.tar.bz2", "1980-03-20-bar.tar.bz2", "1980.03.21.2.bar.tar.bz2.3", "1981-03-15-bar.tar.bz2",
                "nodate.txt"]
    Dir.expects(:entries).once.with(folder).returns(entries)
    File.expects(:directory?).at_least_once.with(folder).returns(true)

    # we expect this list of entries to be deleted
    dates_to_delete =
      (22..30).collect {|i| "1981-06-%02d" % i} +
      (2..31).collect {|i| "1981-07-%02d" % i} +
      (2..31).collect {|i| "1981-08-%02d" % i} +
      (2..30).collect {|i| "1981-09-%02d" % i} +
      (2..31).collect {|i| "1981-10-%02d" % i} +
      (2..7).collect {|i| "1981-11-%02d" % i} +
      (9..14).collect {|i| "1981-11-%02d" % i} +
      (16..21).collect {|i| "1981-11-%02d" % i} +
      (23..28).collect {|i| "1981-11-%02d" % i} +
      ["1981-11-30"] +
      (2..3).collect {|i| "1981-12-%02d" % i}

    entries_to_delete = dates_to_delete.collect {|date| "aaa-#{date}.tar.gz"}

    entries_to_delete += ["1980-03-20-foo.tar.bz2", "1980-03-20-bar.tar.bz2", "1980.03.21.2.bar.tar.bz2.3"]

    entries_to_delete.each do |entry|
      FileUtils.expects(:rm_rf).with(File.join(folder, entry)).once
    end

    backup_cleaner = BackupCleaner.clean_backups(folder, :days => 14, :weeks => 5)
  end

  should "not delete anything if :dry_run specified" do
    folder = "/foo/bar"
    entries = ["1980-03-03-bar.tar.bz2", "1980-03-20-bar.tar.bz2"]
    Dir.expects(:entries).once.with(folder).returns(entries)
    File.expects(:directory?).at_least_once.with(folder).returns(true)

    # assert that nothing is deleted
    FileUtils.expects(:rm_rf).never

    backup_cleaner = BackupCleaner.clean_backups(folder, :days => 14, :weeks => 5, :dry_run => true)
  end

  should "return correct week number if week_ordering_number is called" do
    # make private method public for testing
    BackupCleaner.class_eval "public_class_method :week_ordering_number"

    assert BackupCleaner.week_ordering_number(Date.new(2010, 12, 26)) == 201052
    assert BackupCleaner.week_ordering_number(Date.new(2011, 01, 01)) == 201052
    2.upto(8) {|i| assert BackupCleaner.week_ordering_number(Date.new(2011, 1, i)) == 201101}
    assert BackupCleaner.week_ordering_number(Date.new(2011, 1, 9)) == 201102

    BackupCleaner.class_eval "private_class_method :week_ordering_number"
  end
end
