require "os/mac/database/database"

describe Database do
  subject { Database.new("test") }

  describe "#initialize" do
    it "should raise error trying to initialize" do
      expect { Database.new("test") }
        .to raise_error(NotImplementedError)
    end
  end

  describe "#create_tables" do
    it "should be abstract" do
      expect { subject.create_tables }
        .to raise_error(NotImplementedError)
    end
  end
end
