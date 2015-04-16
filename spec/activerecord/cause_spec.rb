require 'spec_helper'

describe ActiveRecord::Cause do
  let(:stringio) { StringIO.new }
  let(:logger) { Logger.new(stringio) }
  before do
    ActiveRecord::Base.logger = logger
  end

  context "If caused by path that matches `match_paths`" do
    before do
      ActiveRecord::Cause.match_paths = [/_spec/]
    end

    it 'Log SQL with location that is cause of load' do
      User.all.to_a
      output = stringio.tap(&:rewind).read
      puts output
      expect(output).to match(/#{File.expand_path(__FILE__)}/)
    end
  end

  context "Unless caused by path that matches `match_paths`" do
    before do
      ActiveRecord::Cause.match_paths = [/hogehoge/]
    end

    it 'Not log SQL with location that is cause of load' do
      User.all.to_a
      output = stringio.tap(&:rewind).read
      puts output
      expect(output).not_to match(/#{File.expand_path(__FILE__)}/)
    end
  end

  context "Use polymorphic association" do
    before do
      ActiveRecord::Cause.match_paths = [/_spec/]
    end

    it 'Log SQL with location that is cause of load' do
      auth_user = AuthUser.create!(name: "twitter")
      User.create!(name: "joker1007", auth_user: auth_user)
      User.first.auth_user_name
      output = stringio.tap(&:rewind).read
      puts output
      expect(output).to match(/#{File.expand_path(__FILE__)}/)
    end
  end
end
